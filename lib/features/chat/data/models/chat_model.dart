import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String lastMessage;
  final Timestamp? lastMessageAt;
  final String lastSenderId;
  final bool lastSenderIsAdmin;
  final int unreadAdminCount;
  final int unreadCustomerCount;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ChatModel({
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.lastMessage,
    this.lastMessageAt,
    required this.lastSenderId,
    required this.lastSenderIsAdmin,
    required this.unreadAdminCount,
    required this.unreadCustomerCount,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: map['lastMessageAt'] as Timestamp?,
      lastSenderId: map['lastSenderId'] ?? '',
      lastSenderIsAdmin: map['lastSenderIsAdmin'] ?? false,
      unreadAdminCount: map['unreadAdminCount'] ?? 0,
      unreadCustomerCount: map['unreadCustomerCount'] ?? 0,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'lastSenderId': lastSenderId,
      'lastSenderIsAdmin': lastSenderIsAdmin,
      'unreadAdminCount': unreadAdminCount,
      'unreadCustomerCount': unreadCustomerCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
