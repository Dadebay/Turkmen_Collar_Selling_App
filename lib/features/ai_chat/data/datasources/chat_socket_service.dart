import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:yaka2/core/network/logged_http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/message_model.dart';
import 'chat_service.dart';

void _chatLog(Object? message) {
  if (kDebugMode) {
    debugPrint('$message');
  }
}

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  late IO.Socket socket;

  bool _isInitialized = false;
  ChatService? _chatService;
  // ignore: prefer_final_fields
  String _serverUrl = '';

  // Global Message Cache
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // Listeners for different events
  final List<Function(ChatMessage)> _messageListeners = [];
  final List<Function(Map<String, dynamic>)> _typingListeners = [];
  final List<Function(bool)> _connectionListeners = [];

  // Cache for voice message file paths
  final Map<int, String> _voiceCache = {};
  Map<int, String> get voiceCache => _voiceCache;

  // Global Audio Player for notifications
  final AudioPlayer _notificationPlayer = AudioPlayer();
  // To prevent multiple sounds for duplicated socket events
  final Set<int> _processedMessageIds = {};

  factory ChatSocketService() {
    return _instance;
  }

  ChatSocketService._internal();

  void initSocket(String serverUrl, String userId, {String? token}) {
    if (_isInitialized) {
      _chatLog('[ChatSocket] ⚠️ Zaten başlatıldı, yeniden bağlanılıyor...');
      if (!socket.connected) {
        socket.connect();
      }
      return;
    }

    _chatLog('[ChatSocket] 🔧 Başlatılıyor: $serverUrl, userId: $userId');
    _serverUrl = serverUrl;

    if (token != null) {
      _chatService = ChatService(baseUrl: serverUrl, token: token);
      fetchInitialHistory(int.parse(userId), token);
    }

    // Подключиться к серверу
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'query': {'token': token, 'userId': userId},
      'extraHeaders': token != null ? {'Authorization': 'Bearer $token'} : null,
    });

    // Подключиться
    socket.connect();

    // Когда подключено, зарегистрировать пользователя
    socket.onConnect((_) {
      _chatLog('✅ Podklýuçeno k serweru (SocketID: ${socket.id})');
      socket.emit('connect_user', {
        'userId': userId,
        'userType': 'customer', // или 'admin'
      });
      _notifyConnectionListeners(true);
    });

    socket.onDisconnect((_) {
      _chatLog('🔌 Serwerden üzüldi');
      _notifyConnectionListeners(false);
    });

    socket.onError((error) {
      _chatLog('❌ Soket hatasy: $error');
    });

    // ⚠️ ВАЖНО: Добавить все слушатели здесь
    setupListeners();
    _isInitialized = true;
  }

  void setupListeners() {
    // 🔴 САМОЕ ВАЖНОЕ: Слушать входящие сообщения
    socket.on('receive_message', (data) {
      _chatLog('📨 Habar alyndy (receive_message): $data');
      try {
        final message = ChatMessage.fromJson(data);
        _notifyMessageListeners(message);
      } catch (e) {
        _chatLog('❌ Habary okamakda hata: $e');
      }
    });

    // Also listen to secondary event names for compatibility
    socket.on('new_message', (data) {
      _chatLog('📨 Habar alyndy (new_message): $data');
      try {
        final message = ChatMessage.fromJson(data);
        _notifyMessageListeners(message);
      } catch (e) {
        _chatLog('❌ Habary okamakda hata (new_message): $e');
      }
    });

    // Слушать подтверждение отправки сообщения
    socket.on('message_sent', (data) {
      _chatLog('✅ Habar iberildi: ${data['id']}');
    });

    // Слушать когда пользователь печатает
    socket.on('user_typing', (data) {
      _chatLog('⌨️ ${data['sender_id']} ýazýar: ${data['is_typing']}');
      _notifyTypingListeners(data);
    });

    // Слушать статус прочитанного сообщения
    socket.on('message_read', (data) {
      _chatLog('📖 Habar okaldy: ${data['message_id']}');
    });

    // Слушать статус пользователя онлайн
    socket.on('user_online_updated', (data) {
      _chatLog('🟢 ${data['userId']} onlaýn');
    });

    // Слушать статус пользователя оффлайн
    socket.on('user_offline_updated', (data) {
      _chatLog('🔴 ${data['userId']} offlaýn');
    });

    // Ana olay dinleyicisi (GELEN HER ŞEYİ LOGLA)
    socket.onAny((event, data) {
      _chatLog('[ChatSocket] 📡 EVENT: "$event" | Data: $data');
    });
  }

  // Функция отправки сообщения
  void sendMessage({
    required String senderId,
    required String recipientId,
    required String message,
    String senderType = 'customer',
    String recipientType = 'admin',
    String messageType = 'text',
  }) {
    final payload = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender_id': senderId,
      'sender_type': senderType,
      'recipient_id': recipientId,
      'recipient_type': recipientType,
      'message': message,
      'message_type': messageType,
    };
    _chatLog('[ChatSocket] 📤 Emit (send_message): $payload');
    socket.emit('send_message', payload);
  }

  // Listeniing support
  void onMessageReceived(Function(ChatMessage) callback) {
    _messageListeners.add(callback);
  }

  void removeMessageListener(Function(ChatMessage) callback) {
    _messageListeners.remove(callback);
  }

  void onTyping(Function(Map<String, dynamic>) callback) {
    _typingListeners.add(callback);
  }

  void removeTypingListener(Function(Map<String, dynamic>) callback) {
    _typingListeners.remove(callback);
  }

  void onConnectionChanged(Function(bool) callback) {
    _connectionListeners.add(callback);
  }

  void _notifyMessageListeners(ChatMessage message) {
    // Add to global cache if new
    if (message.id != null && !_processedMessageIds.contains(message.id)) {
      _messages.add(message);
      _processedMessageIds.add(message.id!);

      // Play global notification sound if from admin
      if (message.senderType == 'admin') {
        _playGlobalNotificationSound();
      }

      // Preload voice if needed
      if (message.messageType == 'voice' || message.voiceData != null) {
        _preloadVoiceMessage(message);
      }
    }

    for (var listener in _messageListeners) {
      listener(message);
    }
  }

  Future<void> fetchInitialHistory(int customerId, String token) async {
    _chatService ??= ChatService(baseUrl: _serverUrl, token: token);
    try {
      final history = await _chatService!.getChatHistory(customerId);
      _messages.clear();
      _messages.addAll(history);
      for (var msg in history) {
        if (msg.id != null) {
          _processedMessageIds.add(msg.id!);
        }
        // Preload voice if needed
        if (msg.messageType == 'voice' || msg.voiceData != null) {
          await _preloadVoiceMessage(msg);
        }
      }
      _chatLog(
        '[ChatSocket] ✅ Geçmiş mesajlar hafızaya alındı: ${_messages.length}',
      );
    } catch (e) {
      _chatLog('[ChatSocket] ❌ Geçmiş mesajlar çekilemedi: $e');
    }
  }

  Future<void> _preloadVoiceMessage(ChatMessage message) async {
    if (message.id == null || _voiceCache.containsKey(message.id)) {
      return;
    }

    try {
      final voiceData = message.voiceData;
      if (voiceData == null) {
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'voice_${message.id}_${DateTime.now().millisecondsSinceEpoch}.webm';
      final file = File('${tempDir.path}/$fileName');

      if (voiceData.startsWith('data:audio/')) {
        final base64String = voiceData.contains(',')
            ? voiceData.split(',').last
            : voiceData;
        final bytes = base64Decode(base64String);
        await file.writeAsBytes(bytes);
        _voiceCache[message.id!] = file.path;
      } else {
        final url = message.voiceData!.startsWith('http')
            ? message.voiceData!
            : '$_serverUrl/storage/${message.voiceData}';

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          _voiceCache[message.id!] = file.path;
        }
      }
    } catch (e) {
      _chatLog('[ChatSocket] ❌ Ses ön yükleme hatası: $e');
    }
  }

  Future<void> _playGlobalNotificationSound() async {
    try {
      await _notificationPlayer.play(AssetSource('audio/sms.wav'));
    } catch (e) {
      _chatLog('[ChatSocket] ❌ Bildirim sesi çalınamadı: $e');
    }
  }

  void _notifyTypingListeners(Map<String, dynamic> data) {
    for (var listener in _typingListeners) {
      listener(data);
    }
  }

  void _notifyConnectionListeners(bool isConnected) {
    for (var listener in _connectionListeners) {
      listener(isConnected);
    }
  }

  bool get isConnected => _isInitialized && socket.connected;

  void disconnect() {
    if (_isInitialized) {
      socket.dispose();
      _isInitialized = false;
    }
    _chatService = null;
    _serverUrl = '';
    _messages.clear();
    _processedMessageIds.clear();
    _voiceCache.clear();
    _messageListeners.clear();
    _typingListeners.clear();
    _connectionListeners.clear();
  }
}
