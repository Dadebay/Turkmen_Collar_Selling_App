import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:yaka2/core/network/logged_http.dart' as http;

import '../models/message_model.dart';

void _chatLog(Object? message) {
  if (kDebugMode) {
    debugPrint('$message');
  }
}

class ChatService {
  final String baseUrl;
  final String token;

  ChatService({required this.baseUrl, required this.token}) {
    _chatLog('[ChatService] 🔧 Oluşturuldu');
    _chatLog('[ChatService]   baseUrl: $baseUrl');
  }

  // Send message via REST API
  Future<ChatMessage> sendMessage({
    required int customerId,
    required int? adminId,
    required String message,
    required String senderType,
    List<String>? imageUrls,
    String? voiceData,
    int? duration,
  }) async {
    final messageType = imageUrls?.isNotEmpty == true ? 'image' : 'text';
    final url = '$baseUrl/api/v1/messages';
    final body = {
      'customer_id': customerId,
      'admin_id': adminId,
      'message': message,
      'sender_type': senderType,
      'message_type': messageType,
      'voice_data': voiceData,
      'duration': duration,
      'image_urls': imageUrls,
    };

    _chatLog('[ChatService] 📤 sendMessage çağrıldı');
    _chatLog('[ChatService]   URL: POST $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      _chatLog('[ChatService]   Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        _chatLog('[ChatService] ✅ Mesaj gönderildi, id: ${data['id']}');
        return ChatMessage.fromJson(data);
      } else {
        _chatLog('[ChatService] ❌ Mesaj gönderilemedi: ${response.statusCode}');
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      _chatLog('[ChatService] ❌ sendMessage hata: $e');
      throw Exception('Error sending message: $e');
    }
  }

  Future<List<String>> sendImages({required List<File> imageFiles}) async {
    final url = Uri.parse('$baseUrl/api/v1/messages/upload-images');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    for (final imageFile in imageFiles) {
      final fileName = imageFile.path.split(Platform.pathSeparator).last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'image_files[]',
          imageFile.path,
          filename: fileName,
        ),
      );
    }

    _chatLog('[ChatService] 📤 sendImages çağrıldı');
    _chatLog('[ChatService]   URL: POST $url');
    _chatLog('[ChatService]   Files: ${imageFiles.length}');

    try {
      final streamedResponse = await http.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      _chatLog('[ChatService]   Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final urls = jsonDecode(response.body)['urls'] as List;
        _chatLog('[ChatService] ✅ Images uploaded: ${urls.length}');
        return urls.map((url) => url.toString()).toList();
      } else {
        _chatLog('[ChatService] ❌ Image upload failed: ${response.statusCode}');
        throw Exception('Failed to upload images: ${response.body}');
      }
    } catch (e) {
      _chatLog('[ChatService] ❌ sendImages hata: $e');
      throw Exception('Error uploading images: $e');
    }
  }

  // Get chat history with pagination
  Future<List<ChatMessage>> getChatHistory(
    int customerId, {
    int limit = 20,
    int? beforeId,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (beforeId != null) {
      queryParams['before_id'] = beforeId.toString();
    }

    final uri = Uri.parse('$baseUrl/api/v1/messages/$customerId')
        .replace(queryParameters: queryParams);
    _chatLog('[ChatService] 📜 getChatHistory çağrıldı');
    _chatLog('[ChatService]   URL: GET $uri');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      _chatLog('[ChatService]   Status: ${response.statusCode}');
      _chatLog(
        '[ChatService]   Response length: ${response.body.length} chars',
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final messagesList = jsonBody['messages'] as List;
        _chatLog('[ChatService] ✅ ${messagesList.length} mesaj yüklendi');
        final messages = messagesList
            .map((m) => ChatMessage.fromJson(m))
            .toList();
        return messages;
      } else {
        _chatLog(
          '[ChatService] ❌ Chat geçmişi alınamadı: ${response.statusCode}',
        );
        throw Exception('Failed to get chat history');
      }
    } catch (e) {
      _chatLog('[ChatService] ❌ getChatHistory hata: $e');
      throw Exception('Error fetching messages: $e');
    }
  }

  // Mark message as read
  Future<void> markAsRead(int messageId) async {
    final url = '$baseUrl/api/v1/messages/$messageId/read';
    _chatLog('[ChatService] 👁️ markAsRead çağrıldı');
    _chatLog('[ChatService]   URL: POST $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      _chatLog('[ChatService]   Status: ${response.statusCode}');
      _chatLog('[ChatService] ✅ Mesaj okundu olarak işaretlendi: $messageId');
    } catch (e) {
      _chatLog('[ChatService] ❌ markAsRead hata: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(int customerId) async {
    final url =
        '$baseUrl/api/v1/messages-unread-count?customer_id=$customerId&sender_type=admin';
    _chatLog('[ChatService] 🔢 getUnreadCount çağrıldı');
    _chatLog('[ChatService]   URL: GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      _chatLog('[ChatService]   Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final count = jsonDecode(response.body)['unread_count'] ?? 0;
        _chatLog('[ChatService] ✅ Okunmamış mesaj sayısı: $count');
        return count;
      }
      _chatLog('[ChatService] ⚠️ Unread count alınamadı');
      return 0;
    } catch (e) {
      _chatLog('[ChatService] ❌ getUnreadCount hata: $e');
      return 0;
    }
  }
}
