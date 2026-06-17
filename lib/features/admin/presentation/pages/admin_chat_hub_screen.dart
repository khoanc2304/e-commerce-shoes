import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../features/chat/data/repositories/chat_repository.dart';
import '../../../../features/chat/data/models/chat_model.dart';

class AdminChatHubScreen extends StatefulWidget {
  const AdminChatHubScreen({Key? key}) : super(key: key);

  @override
  State<AdminChatHubScreen> createState() => _AdminChatHubScreenState();
}

class _AdminChatHubScreenState extends State<AdminChatHubScreen> {
  final _chatRepository = ChatRepository();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Chats'),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatRepository.getAdminChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No active chats.'));
          }
          final chats = snapshot.data!;
          return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                
                String timeStr = '';
                if (chat.lastMessageAt != null) {
                  timeStr = DateFormat('dd/MM HH:mm').format(chat.lastMessageAt!.toDate());
                }

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(chat.customerName.isNotEmpty ? chat.customerName[0].toUpperCase() : '?'),
                  ),
                  title: Text(chat.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    chat.lastSenderIsAdmin ? 'You: ${chat.lastMessage}' : chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(timeStr, style: const TextStyle(fontSize: 12)),
                      if (chat.unreadAdminCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unreadAdminCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    context.push('/admin/chats/${chat.customerId}', extra: chat.customerName);
                  },
                );
              },
            );
        },
      ),
    );
  }
}
