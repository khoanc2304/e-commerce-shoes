import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';
import '../../../../features/chat/presentation/cubit/chat_cubit.dart';
import '../../../../features/chat/presentation/cubit/chat_state.dart';
import '../../../../features/chat/presentation/widgets/product_message_bubble.dart';

class AdminChatScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const AdminChatScreen({Key? key, required this.customerId, required this.customerName}) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadMessages(widget.customerId);
    context.read<ChatCubit>().markAdminRead(widget.customerId);
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ChatCubit>().sendMessage(
        customerId: widget.customerId,
        customerName: widget.customerName,
        customerEmail: '', // Optional/mock
        text: text,
        senderId: authState.user.uid,
        senderName: authState.user.fullName,
        isAdmin: true,
      );
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat: ${widget.customerName}'),
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
                    reverse: true, 
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isMe = msg.isAdmin; // Admin view: "Me" is any admin
                      
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
                            color: isMe ? Colors.teal : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // For admin view, we want to see the specific sender name, even if it's an admin
                              Text(
                                msg.senderName.isEmpty ? (isMe ? 'Admin' : widget.customerName) : msg.senderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12, 
                                  color: isMe ? Colors.white70 : Colors.black54
                                ),
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
                return const Center(child: Text('Loading...'));
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
                        hintText: 'Type a reply...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.teal,
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
