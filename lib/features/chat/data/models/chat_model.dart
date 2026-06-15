import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String roomId;
  final String userId;
  final String userName;
  final String lastMessage;
  final Timestamp? updatedAt;

  ChatRoomModel({
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.lastMessage,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'userId': userId,
      'userName': userName,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoomModel(
      roomId: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final Timestamp? timestamp;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      messageId: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] as Timestamp?,
    );
  }
}
