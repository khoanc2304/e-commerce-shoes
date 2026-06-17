import 'package:equatable/equatable.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/chat_message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// For Admin Chat Hub
class AdminChatsLoaded extends ChatState {
  final List<ChatModel> chats;

  const AdminChatsLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

// For Customer/Admin Chat Screen (Messages)
class ChatMessagesLoaded extends ChatState {
  final List<ChatMessageModel> messages;

  const ChatMessagesLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}
