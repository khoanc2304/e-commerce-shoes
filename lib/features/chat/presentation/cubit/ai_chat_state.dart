import 'package:equatable/equatable.dart';
import '../../data/models/chat_message_model.dart';

abstract class AiChatState extends Equatable {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? errorMessage;

  const AiChatState({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [messages, isLoading, errorMessage];
}

class AiChatInitial extends AiChatState {
  const AiChatInitial() : super(messages: const []);
}

class AiChatActive extends AiChatState {
  const AiChatActive({
    required List<ChatMessageModel> messages,
    bool isLoading = false,
    String? errorMessage,
  }) : super(messages: messages, isLoading: isLoading, errorMessage: errorMessage);

  AiChatActive copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AiChatActive(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
