import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String messageId;
  final String text;
  final String senderId;
  final String senderName;
  final bool isAdmin;
  final Timestamp? timestamp;
  final Map<String, dynamic>? productPayload;

  ChatMessageModel({
    required this.messageId,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.isAdmin,
    this.timestamp,
    this.productPayload,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      messageId: id,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      timestamp: map['timestamp'] as Timestamp?,
      productPayload: map['productPayload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'isAdmin': isAdmin,
      'timestamp': timestamp,
      if (productPayload != null) 'productPayload': productPayload,
    };
  }
}
