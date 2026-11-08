import '../../../../core/utils/safe_parser.dart';

class ChatMessage {
  final int? id;
  final int customerId;
  final int? adminId;
  final String message;
  final String senderType; // 'customer' or 'admin'
  final String? messageType; // 'text' or 'voice'
  final String? voiceData;
  final List<String>? imageUrls;
  final int? duration; // in seconds
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.customerId,
    required this.message,
    required this.senderType,
    required this.createdAt,
    this.id,
    this.adminId,
    this.messageType = 'text',
    this.voiceData,
    this.imageUrls,
    this.duration,
    this.isRead = false,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sId = json['sender_id'];
    final rId = json['recipient_id'];
    final sType = SafeParser.asString(
      json['sender_type'],
      fallback: 'customer',
    );

    String? vData = SafeParser.asStringOrNull(
      json['voice_data'] ??
          json['voice'] ??
          json['audio'] ??
          json['file'] ??
          json['voice_url'] ??
          json['audio_url'] ??
          json['voice_path'] ??
          json['file_path'],
    );

    String mType = SafeParser.asString(
      json['message_type'],
      fallback: vData != null ? 'voice' : 'text',
    );

    final msgText = SafeParser.asString(json['message']);
    if (vData == null) {
      if (msgText.endsWith('.mp3') ||
          msgText.endsWith('.wav') ||
          msgText.endsWith('.ogg') ||
          msgText.endsWith('.webm') ||
          msgText.endsWith('.m4a') ||
          msgText.startsWith('http')) {
        if (msgText.startsWith('http')) {
          vData = msgText;
          mType = 'voice';
        }
      } else if (msgText == '[Голосовое сообщение]' ||
          msgText == '[Voice Message]') {
        mType = 'voice';
      }
    }

    final rawImages = json['image_urls'] ?? json['images'];
    final imageList = SafeParser.asStringList(rawImages);
    final parsedImageUrls = imageList.isEmpty ? null : imageList;

    int cid = 0;
    if (json['customer_id'] != null) {
      cid = SafeParser.asInt(json['customer_id']);
    } else if (sType == 'admin' && rId != null) {
      cid = SafeParser.asInt(rId);
    } else if (sId != null) {
      cid = SafeParser.asInt(sId);
    }

    int? aid;
    if (json['admin_id'] != null) {
      aid = SafeParser.asIntOrNull(json['admin_id']);
    } else if (sType == 'admin' && sId != null) {
      aid = SafeParser.asIntOrNull(sId);
    } else if (rId != null) {
      aid = SafeParser.asIntOrNull(rId);
    }

    return ChatMessage(
      id: SafeParser.asIntOrNull(json['id']),
      customerId: cid,
      adminId: aid,
      message: msgText,
      senderType: sType,
      messageType: mType,
      voiceData: vData,
      imageUrls: parsedImageUrls,
      duration: SafeParser.asIntOrNull(json['duration']),
      isRead: SafeParser.asBool(json['is_read'] ?? json['read']),
      readAt: SafeParser.asDateTimeOrNull(json['read_at']),
      createdAt: SafeParser.asDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'admin_id': adminId,
      'message': message,
      'sender_type': senderType,
      'message_type': messageType,
      'voice_data': voiceData,
      'image_urls': imageUrls,
      'duration': duration,
    };
  }
}
