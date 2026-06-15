import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../chat/data/models/chat_model.dart';
import '../../../chat/presentation/pages/chat_screen.dart';

class AdminChatHub extends StatelessWidget {
  const AdminChatHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Support Hub')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No active customer chats.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final room = ChatRoomModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
              
              final lastMsgDate = room.updatedAt != null 
                  ? DateFormat('hh:mm a, dd MMM').format(room.updatedAt!.toDate())
                  : '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(room.userName.isNotEmpty ? room.userName.substring(0, 1).toUpperCase() : 'U'),
                ),
                title: Text(room.userName.isNotEmpty ? room.userName : 'User ${room.roomId.substring(0, 5)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(room.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(lastMsgDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  // Admin clicks room, goes to ChatScreen but we pass admin UID
                  // so the messages are correctly assigned to "admin" vs "customer"
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        currentUserId: "admin", // Identifier for admin replies
                        currentUserName: "Support",
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
