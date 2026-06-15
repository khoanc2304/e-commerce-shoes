import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<MessageModel>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> sendMessage(String roomId, MessageModel message, String userName) async {
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    final messagesRef = roomRef.collection('messages').doc(message.messageId);

    try {
      await _firestore.runTransaction((transaction) async {
        final roomDoc = await transaction.get(roomRef);

        // If the room doesn't exist, create it (User's first message)
        if (!roomDoc.exists) {
          final newRoom = ChatRoomModel(
            roomId: roomId,
            userId: roomId, // roomId is userUID
            userName: userName,
            lastMessage: message.text,
            updatedAt: Timestamp.now(),
          );
          transaction.set(roomRef, newRoom.toMap());
        } else {
          // Update last message
          transaction.update(roomRef, {
            'lastMessage': message.text,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Add the message
        transaction.set(messagesRef, message.toMap());
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
