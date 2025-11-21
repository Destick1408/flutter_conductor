import 'package:meta/meta.dart';

@immutable
class ChatMessage {
  final int? id;
  final int? senderId;
  final String content;
  final DateTime? createdAt;
  final bool isMine;

  const ChatMessage({
    this.id,
    this.senderId,
    required this.content,
    this.createdAt,
    this.isMine = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required int userId}) {
    final sender = json['sender'];
    int? senderId;

    if (sender is Map<String, dynamic>) {
      senderId = sender['id'] is int
          ? sender['id'] as int
          : int.tryParse(sender['id']?.toString() ?? '');
    } else if (json['sender_id'] is int) {
      senderId = json['sender_id'] as int;
    } else if (json['sender_id'] is String) {
      senderId = int.tryParse(json['sender_id'] as String);
    }

    if (senderId == null) {
      final rawSender = json['emisor_id'] ?? json['user_id'] ?? json['user'];
      senderId = rawSender is int ? rawSender : int.tryParse(rawSender?.toString() ?? '');
    }

    final bool isMine = senderId != null && senderId == userId;
    final message = json['mensaje'] ??
        json['contenido'] ??
        json['content'] ??
        json['message'] ??
        json['text'] ??
        '';
    final created =
        json['timestamp'] ?? json['created_at'] ?? json['creado'] ?? json['fecha'];
    DateTime? parsedDate;
    if (created is String) {
      parsedDate = DateTime.tryParse(created);
    }

    return ChatMessage(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      senderId: senderId,
      content: message.toString(),
      createdAt: parsedDate,
      isMine: isMine,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'contenido': content,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
