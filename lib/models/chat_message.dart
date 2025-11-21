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

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required int conductorId}) {
    final rawSender = json['emisor_id'] ?? json['sender_id'] ?? json['user_id'] ?? json['user'];
    final sender = rawSender is int ? rawSender : int.tryParse(rawSender?.toString() ?? '');
    final message = json['mensaje'] ?? json['contenido'] ?? json['content'] ?? json['message'] ?? '';
    final created = json['creado'] ?? json['created_at'] ?? json['timestamp'] ?? json['fecha'];
    DateTime? parsedDate;
    if (created is String) {
      parsedDate = DateTime.tryParse(created);
    }

    return ChatMessage(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      senderId: sender,
      content: message.toString(),
      createdAt: parsedDate,
      isMine: sender != null && sender == conductorId,
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
