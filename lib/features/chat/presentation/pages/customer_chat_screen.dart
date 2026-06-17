import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/product_message_bubble.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({Key? key}) : super(key: key);

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ChatCubit>().loadMessages(authState.user.uid);
      context.read<ChatCubit>().markCustomerRead(authState.user.uid);
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ChatCubit>().sendMessage(
        customerId: authState.user.uid,
        customerName: authState.user.fullName,
        customerEmail: authState.user.email,
        text: text,
        senderId: authState.user.uid,
        senderName: authState.user.fullName,
        isAdmin: false,
      );
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Admin'),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChatError) {
                  return Center(child: Text(state.message));
                } else if (state is ChatMessagesLoaded) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }

                  return ListView.builder(
                    reverse: true, // Show latest at the bottom by reversing and ordering descending
                    // Wait, we query by ascending in repository, so we should reverse the list or use scroll controller.
                    // Actually, if repository orders ascending (oldest first), reverse: true shows oldest at bottom.
                    // Let's just use ListView and let it scroll naturally, or reverse the list manually.
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Reverse index to show latest at bottom if using reverse: true
                      final msg = messages[messages.length - 1 - index];
                      final isMe = !msg.isAdmin;
                      
                      String timeStr = '';
                      if (msg.timestamp != null) {
                        timeStr = DateFormat('HH:mm').format(msg.timestamp!.toDate());
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                const Text(
                                  'Admin',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
                                ),
                              Text(
                                msg.text,
                                style: TextStyle(color: isMe ? Colors.white : Colors.black),
                              ),
                              if (msg.productPayload != null)
                                ProductMessageBubble(productPayload: msg.productPayload!, isMe: isMe),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text('Start chatting...'));
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: _sendMessage,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
