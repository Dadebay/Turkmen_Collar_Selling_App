// ignore_for_file: always_put_control_body_on_new_line, unawaited_futures

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:go_router/go_router.dart';
import 'package:yaka2/core/network/logged_http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/message_model.dart';
import '../../data/datasources/chat_service.dart';
import '../../data/datasources/chat_socket_service.dart';
import '../../data/services/voice_player.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/no_image.dart';
import '../../../../core/icons/app_icon.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late ChatService _chatService;
  late ChatSocketService _socketService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isAdminTyping = false;
  final List<File> _selectedImages = [];
  bool _isSendingImage = false;

  final VoicePlayer _voicePlayer = VoicePlayer();
  ChatMessage? _currentlyPlayingMessage;
  VoicePlayerStatus _playerState = VoicePlayerStatus.stopped;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  String? _token;
  int _customerId = 1;
  final Map<int, String> _voiceCache = {};
  final Set<int> _voiceDownloading = {};
  final Map<int, double> _voiceDownloadProgress = {};
  int? _pendingPlayVoiceId;
  final Set<int> _loadingMessageIds = {};
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _scrollController.addListener(_onScroll);
    _initializeServices();
  }

  void _initAudioPlayer() {
    _voicePlayer.statusStream.listen((s) {
      if (!mounted) return;
      setState(() {
        // Completion resets the UI to the idle (stopped) state.
        _playerState = s == VoicePlayerStatus.completed
            ? VoicePlayerStatus.stopped
            : s;
      });
    });
    _voicePlayer.durationStream.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    _voicePlayer.positionStream.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
  }

  Future<void> _initializeServices() async {
    final storage = LocalStorage();
    _token = storage.token;
    _customerId = storage.customerId ?? 1;

    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    _chatService = ChatService(baseUrl: ApiConstants.baseUrl, token: _token!);
    _socketService = ChatSocketService();
    _socketService.onMessageReceived(_onMessageReceived);
    _socketService.onTyping(_onTyping);

    if (!_socketService.isConnected) {
      _socketService.initSocket(
        ApiConstants.baseUrl,
        _customerId.toString(),
        token: _token,
      );
    }

    await _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    try {
      final history = await _chatService.getChatHistory(
        _customerId,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history.reversed);
        _isLoading = false;
        _hasMoreMessages = history.length >= _pageSize;
      });
      _voiceCache.addAll(_socketService.voiceCache);
      await _markAdminMessagesAsRead(history);
      if (history.isNotEmpty) {
        final maxId = history
            .map((m) => m.id ?? 0)
            .reduce((a, b) => a > b ? a : b);
        if (maxId > 0) {
          await LocalStorage().saveLastSeenMessageId(maxId);
        }
      }
      for (var msg in history) {
        if (msg.messageType == 'voice' || msg.voiceData != null) {
          await _preloadVoice(msg);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAdminMessagesAsRead(List<ChatMessage> messages) async {
    final ids = messages
        .where((m) => m.id != null && m.senderType == 'admin' && !m.isRead)
        .map((m) => m.id!)
        .toSet()
        .toList();
    await Future.wait(ids.map((id) => _chatService.markAsRead(id)));
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_messages.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      final oldestId = _messages.last.id;
      if (oldestId == null) return;
      final older = await _chatService.getChatHistory(
        _customerId,
        limit: _pageSize,
        beforeId: oldestId,
      );
      if (!mounted) return;
      setState(() {
        if (older.isEmpty) {
          _hasMoreMessages = false;
        } else {
          final startIndex = _messages.length;
          _messages.addAll(older.reversed);
          for (var i = 0; i < older.length; i++) {
            _listKey.currentState?.insertItem(
              startIndex + i,
              duration: const Duration(milliseconds: 200),
            );
          }
          _hasMoreMessages = older.length >= _pageSize;
        }
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _preloadVoice(ChatMessage msg) async {
    if (msg.id == null || _voiceCache.containsKey(msg.id)) return;
    if (_voiceDownloading.contains(msg.id)) return;
    final voiceData = msg.voiceData;
    if (voiceData == null) return;
    if (mounted) {
      setState(() {
        _voiceDownloading.add(msg.id!);
        _voiceDownloadProgress[msg.id!] = 0.0;
      });
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/voice_${msg.id}_${DateTime.now().millisecondsSinceEpoch}.ogg',
      );
      if (voiceData.startsWith('data:audio/')) {
        final b64 = voiceData.contains(',')
            ? voiceData.split(',').last
            : voiceData;
        await file.writeAsBytes(base64Decode(b64));
      } else {
        final url = _resolveUrl(voiceData);
        final req = http.Request('GET', Uri.parse(url));
        final streamed = await http.send(req);
        final total = streamed.contentLength ?? 0;
        final bytes = <int>[];
        int received = 0;
        await for (final chunk in streamed.stream) {
          bytes.addAll(chunk);
          received += chunk.length;
          if (total > 0 && mounted) {
            setState(() => _voiceDownloadProgress[msg.id!] = received / total);
          }
        }
        if (streamed.statusCode == 200) {
          await file.writeAsBytes(bytes);
        } else {
          return;
        }
      }
      if (mounted) {
        setState(() {
          _voiceCache[msg.id!] = file.path;
          _voiceDownloading.remove(msg.id);
          _voiceDownloadProgress.remove(msg.id);
        });
        if (_pendingPlayVoiceId == msg.id) {
          _pendingPlayVoiceId = null;
          _playVoice(msg);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _voiceDownloading.remove(msg.id);
          _voiceDownloadProgress.remove(msg.id);
        });
      }
    }
  }

  void _onTyping(Map<String, dynamic> data) {
    if (!mounted) return;
    if (data['sender_id'].toString() != _customerId.toString()) {
      setState(() => _isAdminTyping = data['is_typing'] ?? false);
    }
  }

  void _onMessageReceived(ChatMessage message) {
    if (!mounted) return;
    if (_messages.any((m) => m.id == message.id)) return;
    if (message.senderType == 'admin' && message.id != null) {
      unawaited(_chatService.markAsRead(message.id!));
      LocalStorage().saveLastSeenMessageId(message.id!);
    }
    _insertMessage(message);
    if (message.id != null) _fetchFullMessage(message);
  }

  Future<void> _fetchFullMessage(ChatMessage socketMsg) async {
    if (socketMsg.id == null) return;
    setState(() => _loadingMessageIds.add(socketMsg.id!));
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final recent = await _chatService.getChatHistory(_customerId, limit: 5);
      if (!mounted) return;
      final full = recent.cast<ChatMessage?>().firstWhere(
        (m) => m!.id == socketMsg.id,
        orElse: () => null,
      );
      if (full != null) {
        final idx = _messages.indexWhere((m) => m.id == socketMsg.id);
        if (idx != -1) {
          setState(() {
            _messages[idx] = full;
            _loadingMessageIds.remove(socketMsg.id);
          });
          if (full.messageType == 'voice' || full.voiceData != null) {
            _preloadVoice(full);
          }
        }
      } else {
        if (mounted) setState(() => _loadingMessageIds.remove(socketMsg.id!));
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMessageIds.remove(socketMsg.id!));
    }
  }

  void _insertMessage(ChatMessage msg) {
    if (!mounted) return;
    _messages.insert(0, msg);
    _listKey.currentState?.insertItem(
      0,
      duration: const Duration(milliseconds: 400),
    );
    if (msg.messageType == 'voice' || msg.voiceData != null) {
      _preloadVoice(msg);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedImages.isNotEmpty) return _sendWithImages();
    if (_messageController.text.isEmpty) return;
    final text = _messageController.text;
    _messageController.clear();
    try {
      final msg = await _chatService.sendMessage(
        customerId: _customerId,
        adminId: 1,
        message: text,
        senderType: 'customer',
      );
      _messages.insert(0, msg);
      _listKey.currentState?.insertItem(
        0,
        duration: const Duration(milliseconds: 400),
      );
      _scrollToBottom();
      _socketService.sendMessage(
        senderId: _customerId.toString(),
        recipientId: '1',
        message: text,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('messageSendFailed'.tr)));
      }
    }
  }

  static const int _maxImageBytes = 3 * 1024 * 1024; // 3 MB

  bool _checkImageSize(File file) {
    if (file.lengthSync() > _maxImageBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('image_max_size'.tr)));
      }
      return false;
    }
    return true;
  }

  void _warnMaxImages() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('image_max_count'.tr)));
  }

  Future<void> _sendWithImages() async {
    if (_isSendingImage) {
      return;
    }
    final text = _messageController.text;
    setState(() => _isSendingImage = true);
    try {
      _messageController.clear();
      final urls = await _chatService.sendImages(
        imageFiles: List<File>.from(_selectedImages),
      );
      final msg = await _chatService.sendMessage(
        customerId: _customerId,
        adminId: 1,
        message: text,
        senderType: 'customer',
        imageUrls: urls,
      );
      setState(() {
        _selectedImages.clear();
        _messages.insert(0, msg);
      });
      _listKey.currentState?.insertItem(
        0,
        duration: const Duration(milliseconds: 400),
      );
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('sendFailed'.tr)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingImage = false);
      }
    }
  }

  Future<void> _pickGallery() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) {
      return;
    }
    if ((_selectedImages.length + picked.length) > 3) {
      _warnMaxImages();
      return;
    }
    final files = picked
        .map((f) => File(f.path))
        .where(_checkImageSize)
        .toList();
    if (files.isNotEmpty) {
      setState(() => _selectedImages.addAll(files));
    }
  }

  Future<void> _pickCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) {
      return;
    }
    if (_selectedImages.length >= 3) {
      _warnMaxImages();
      return;
    }
    final file = File(picked.path);
    if (_checkImageSize(file)) {
      setState(() => _selectedImages.add(file));
    }
  }

  Future<void> _playVoice(ChatMessage msg) async {
    if (_currentlyPlayingMessage?.id == msg.id &&
        _playerState == VoicePlayerStatus.playing) {
      await _voicePlayer.pause();
      return;
    }
    if (_currentlyPlayingMessage?.id == msg.id &&
        _playerState == VoicePlayerStatus.paused) {
      await _voicePlayer.resume();
      return;
    }
    if (msg.id != null && _voiceDownloading.contains(msg.id)) {
      setState(() {
        _pendingPlayVoiceId = msg.id;
        _currentlyPlayingMessage = msg;
        _audioPosition = Duration.zero;
        _audioDuration = Duration(seconds: msg.duration ?? 0);
      });
      return;
    }
    setState(() {
      _pendingPlayVoiceId = null;
      _currentlyPlayingMessage = msg;
      _audioPosition = Duration.zero;
      _audioDuration = Duration(seconds: msg.duration ?? 0);
    });
    try {
      final cached = _voiceCache[msg.id] ?? _socketService.voiceCache[msg.id];
      if (cached != null) {
        await _voicePlayer.playFile(cached);
      } else {
        final vd = msg.voiceData;
        if (vd != null && vd.startsWith('data:audio/')) {
          final b64 = vd.contains(',') ? vd.split(',').last : vd;
          final bytes = base64Decode(b64);
          final dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}/voice_play_${msg.id ?? DateTime.now().millisecondsSinceEpoch}.webm',
          );
          if (!file.existsSync()) {
            await file.writeAsBytes(bytes);
          }
          await _voicePlayer.playFile(file.path);
        } else {
          await _voicePlayer.playUrl(_resolveUrl(msg.voiceData ?? ''));
        }
      }
    } catch (e, s) {
      debugPrint('🎙️ voice play failed: $e\n$s');
    }
  }

  String _resolveUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    if (path.startsWith('data:')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '${ApiConstants.baseUrl}$path';
    }
    return '${ApiConstants.baseUrl}/$path';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _socketService.removeMessageListener(_onMessageReceived);
    _socketService.removeTypingListener(_onTyping);
    _voicePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'ai_chat',
        showBackButton: true,
        actionButton: GestureDetector(
          onTap: () => context.push(AppRoutes.searchByImage),
          child: Container(
            width: 70,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: appBarForeground),
              boxShadow: [
                BoxShadow(
                  color: appBarForeground.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'search_by_image'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: appBarForeground,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_currentlyPlayingMessage != null) _buildMiniPlayer(),
          if (!_isLoading && _messages.isNotEmpty) _buildActionButtons(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : AnimatedList(
                    key: _listKey,
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    initialItemCount: _messages.length,
                    itemBuilder: (ctx, i, anim) {
                      if (i == _messages.length - 1 && _isLoadingMore) {
                        return Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            _buildAnimatedItem(_messages[i], anim),
                          ],
                        );
                      }
                      return _buildAnimatedItem(_messages[i], anim);
                    },
                  ),
          ),
          if (_isAdminTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        _actionButton(
          icon: Icons.play_circle_outline,
          label: 'video_tabbar'.tr,
          onTap: _openVideoInstruction,
        ),
        const SizedBox(height: 12),
        _actionButton(
          icon: Icons.image_outlined,
          label: 'image_tabbar'.tr,
          onTap: _openPhotoInstruction,
        ),
        const SizedBox(height: 12),
        _actionButton(
          icon: Icons.help_outline,
          label: 'questions'.tr,
          onTap: _openFaq,
        ),
        const Spacer(),
        Text(
          'chat_help_hint'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppPalette.of(context).muted),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  void _openVideoInstruction() =>
      context.push(AppRoutes.instruction, extra: {'initialTab': 0});

  void _openPhotoInstruction() =>
      context.push(AppRoutes.instruction, extra: {'initialTab': 1});

  void _openFaq() => context.push(AppRoutes.faq);

  Widget _buildActionButtons() => Container(
    color: Theme.of(context).scaffoldBackgroundColor,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.play_circle_outline,
            label: 'video_tabbar'.tr,
            onTap: _openVideoInstruction,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            icon: Icons.image_outlined,
            label: 'image_tabbar'.tr,
            onTap: _openPhotoInstruction,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            icon: Icons.help_outline,
            label: 'questions'.tr,
            onTap: _openFaq,
            compact: true,
          ),
        ),
      ],
    ),
  );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool compact = false,
  }) => Material(
    color: AppPalette.of(context).surface,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 14,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.primaryColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, color: ColorConstants.primaryColor, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ColorConstants.primaryColor,
                  fontSize: compact ? 10 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildTypingIndicator() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorConstants.primaryColor.withOpacity(.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Admin ýazýar...',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppPalette.of(context).muted,
          ),
        ),
      ],
    ),
  );

  Widget _buildAnimatedItem(ChatMessage msg, Animation<double> anim) {
    final isAdmin = msg.senderType == 'admin';
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isAdmin ? -0.2 : 0.2, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: _buildBubble(msg, isAdmin),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isAdmin) {
    final isLoading = msg.id != null && _loadingMessageIds.contains(msg.id);
    if (isLoading &&
        msg.message.isEmpty &&
        (msg.imageUrls == null || msg.imageUrls!.isEmpty) &&
        msg.voiceData == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAdmin
              ? AppPalette.of(context).surfaceAlt
              : ColorConstants.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAdmin ? 4 : 20),
            bottomRight: Radius.circular(isAdmin ? 20 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: msg.imageUrls!.map((url) {
                    final full = _resolveUrl(url);
                    return GestureDetector(
                      onTap: () => _openImageViewer(
                        context,
                        msg.imageUrls!.map(_resolveUrl).toList(),
                        msg.imageUrls!.indexOf(url),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: full,
                          width: MediaQuery.sizeOf(context).width * 0.5,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: AppPalette.of(context).border,
                            child: const NoImage(),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (msg.messageType == 'voice' || msg.voiceData != null)
              _buildVoiceContent(msg, isAdmin),
            if (msg.message.isNotEmpty)
              Text(
                msg.message,
                style: TextStyle(
                  color: isAdmin ? AppPalette.of(context).text : Colors.white,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isAdmin
                        ? AppPalette.of(context).muted
                        : Colors.white70,
                  ),
                ),
                if (!isAdmin) ...[
                  const SizedBox(width: 4),
                  AppIcon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceContent(ChatMessage msg, bool isAdmin) {
    final fg = isAdmin ? AppPalette.of(context).text : Colors.white;
    final isCurrent = _currentlyPlayingMessage?.id == msg.id && msg.id != null;
    final isPlaying = isCurrent && _playerState == VoicePlayerStatus.playing;
    final isDownloading = msg.id != null && _voiceDownloading.contains(msg.id);
    final progress = msg.id != null ? _voiceDownloadProgress[msg.id] : null;

    // Prefer the player-reported duration, but fall back to the duration the
    // server sent (the player can report 0 for .ogg while still emitting
    // position events, which would otherwise freeze the bar at 0).
    final totalSeconds = msg.duration ?? 0;
    final effectiveDurationMs = (isCurrent && _audioDuration.inMilliseconds > 0)
        ? _audioDuration.inMilliseconds
        : totalSeconds * 1000;
    final positionSeconds = isCurrent ? _audioPosition.inSeconds : 0;
    final trackProgress = (isCurrent && effectiveDurationMs > 0)
        ? _audioPosition.inMilliseconds / effectiveDurationMs
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _playVoice(msg),
            child: SizedBox(
              width: 36,
              height: 36,
              child: isDownloading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: (progress != null && progress > 0)
                                ? progress
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(fg),
                          ),
                        ),
                      ],
                    )
                  : AppIcon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: fg,
                      size: 36,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    value: trackProgress.clamp(0.0, 1.0),
                    backgroundColor: fg.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isCurrent && positionSeconds > 0
                    ? '${_fmt(_audioPosition)} / ${_fmt(Duration(seconds: totalSeconds))}'
                    : _fmt(Duration(seconds: totalSeconds)),
                style: TextStyle(color: fg.withOpacity(0.8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openImageViewer(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, anim, _) =>
            _ImageViewer(imageUrls: urls, initialIndex: initialIndex),
        transitionsBuilder: (context, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        border: Border(
          bottom: BorderSide(color: AppPalette.of(context).border),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_playerState == VoicePlayerStatus.playing) {
                await _voicePlayer.pause();
              } else {
                await _voicePlayer.resume();
              }
            },
            child: AppIcon(
              _playerState == VoicePlayerStatus.playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: ColorConstants.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_fmt(_audioPosition)} / ${_fmt(_audioDuration)}',
              style: TextStyle(
                color: AppPalette.of(context).muted,
                fontSize: 11,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _voicePlayer.stop();
              setState(() => _currentlyPlayingMessage = null);
            },
            icon: AppIcon(
              Icons.close_rounded,
              color: AppPalette.of(context).muted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  Widget _buildInputArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedImages.isNotEmpty) _buildImagePreview(),
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: MediaQuery.paddingOf(context).bottom + 8,
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppPalette.of(context).surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.of(context).border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 5,
                    minLines: 1,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'how_can_i_help'.tr,
                      hintStyle: TextStyle(
                        color: AppPalette.of(context).muted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: AppIcon(
                    Icons.image_outlined,
                    color: AppPalette.of(context).muted,
                  ),
                  onPressed: _pickGallery,
                ),
                IconButton(
                  icon: AppIcon(
                    Icons.camera_alt_outlined,
                    color: AppPalette.of(context).muted,
                  ),
                  onPressed: _pickCamera,
                ),
                GestureDetector(
                  onTap: _isSendingImage ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isSendingImage
                          ? AppPalette.of(context).border
                          : ColorConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isSendingImage
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Transform.translate(
                            offset: const Offset(-1, 1),
                            child: const SizedBox.square(
                              dimension: 20,
                              child: AppIcon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() => SizedBox(
    height: 100,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _selectedImages.length,
      itemBuilder: (context, i) => Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_selectedImages[i]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 0,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImages.removeAt(i)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.imageUrls, required this.initialIndex});
  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[i],
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const NoImage(),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
