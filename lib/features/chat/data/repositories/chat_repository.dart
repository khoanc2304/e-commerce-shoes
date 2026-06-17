import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ChatModel>> getAdminChatsStream() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data()))
            .toList());
  }

  Stream<int> getUnreadAdminChatsCountStream() {
    return _firestore
        .collection('chats')
        .where('unreadAdminCount', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getUnreadCustomerMessagesCountStream(String customerId) {
    return _firestore
        .collection('chats')
        .doc(customerId)
        .snapshots()
        .map((doc) => doc.exists ? ((doc.data() as Map<String, dynamic>)['unreadCustomerCount'] as int? ?? 0) : 0);
  }

  Stream<List<ChatMessageModel>> getMessagesStream(String customerId) {
    return _firestore
        .collection('chats')
        .doc(customerId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String text,
    required String senderId,
    required String senderName,
    required bool isAdmin,
    Map<String, dynamic>? productPayload,
  }) async {
    final chatRef = _firestore.collection('chats').doc(customerId);
    final messageRef = chatRef.collection('messages').doc();

    final messageData = {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'isAdmin': isAdmin,
      'timestamp': FieldValue.serverTimestamp(),
      if (productPayload != null) 'productPayload': productPayload,
    };

    await _firestore.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatRef);

      transaction.set(messageRef, messageData);

      if (chatSnapshot.exists) {
        final currentData = chatSnapshot.data()!;
        final currentUnreadAdmin = currentData['unreadAdminCount'] ?? 0;
        final currentUnreadCustomer = currentData['unreadCustomerCount'] ?? 0;

        transaction.update(chatRef, {
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastSenderId': senderId,
          'lastSenderIsAdmin': isAdmin,
          'unreadAdminCount': isAdmin ? currentUnreadAdmin : currentUnreadAdmin + 1,
          'unreadCustomerCount': isAdmin ? currentUnreadCustomer + 1 : currentUnreadCustomer,
        });
      } else {
        final newChat = ChatModel(
          customerId: customerId,
          customerName: customerName,
          customerEmail: customerEmail,
          lastMessage: text,
          lastSenderId: senderId,
          lastSenderIsAdmin: isAdmin,
          unreadAdminCount: isAdmin ? 0 : 1,
          unreadCustomerCount: isAdmin ? 1 : 0,
        );

        final chatData = newChat.toMap();
        chatData['createdAt'] = FieldValue.serverTimestamp();
        chatData['updatedAt'] = FieldValue.serverTimestamp();
        chatData['lastMessageAt'] = FieldValue.serverTimestamp();

        transaction.set(chatRef, chatData);
      }
    });
  }

  Future<void> markAdminRead(String customerId) async {
    await _firestore.collection('chats').doc(customerId).update({
      'unreadAdminCount': 0,
    });
  }

  Future<void> markCustomerRead(String customerId) async {
    await _firestore.collection('chats').doc(customerId).update({
      'unreadCustomerCount': 0,
    });
  }
}
