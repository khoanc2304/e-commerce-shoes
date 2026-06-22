import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/ai_chat_service.dart';
import 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatState> {
  final AiChatService _aiChatService;
  final _uuid = const Uuid();

  AiChatCubit({AiChatService? aiChatService})
      : _aiChatService = aiChatService ?? AiChatService(),
        super(const AiChatInitial());

  void initializeChat(String userName) {
    if (state is AiChatInitial) {
      // Seed API key to Firestore config collection asynchronously
      _aiChatService.seedApiKeyToDatabase();

      final welcomeMessage = ChatMessageModel(
        messageId: _uuid.v4(),
        text: "Xin chào $userName! Tôi là trợ lý ảo của Shoes X. Tôi có thể hỗ trợ gì cho bạn hôm nay? "
             "Bạn có thể hỏi tôi về các mẫu giày, kích cỡ có sẵn, màu sắc, giá cả hoặc địa chỉ các chi nhánh cửa hàng.",
        senderId: 'ai_assistant',
        senderName: 'Trợ lý Shoes X',
        isAdmin: true,
        timestamp: Timestamp.now(),
      );
      emit(AiChatActive(messages: [welcomeMessage], isLoading: false));
    }
  }

  Future<void> sendMessage({
    required String customerId,
    required String customerName,
    required String text,
  }) async {
    final currentMessages = List<ChatMessageModel>.from(state.messages);

    // 1. Add user message to UI
    final userMessage = ChatMessageModel(
      messageId: _uuid.v4(),
      text: text,
      senderId: customerId,
      senderName: customerName,
      isAdmin: false,
      timestamp: Timestamp.now(),
    );

    final updatedMessages = List<ChatMessageModel>.from(currentMessages)..add(userMessage);
    emit(AiChatActive(messages: updatedMessages, isLoading: true));

    // 2. Fetch AI response
    try {
      final replyText = await _aiChatService.getAiResponse(updatedMessages);

      final aiMessage = ChatMessageModel(
        messageId: _uuid.v4(),
        text: replyText,
        senderId: 'ai_assistant',
        senderName: 'Trợ lý Shoes X',
        isAdmin: true,
        timestamp: Timestamp.now(),
      );

      final finalMessages = List<ChatMessageModel>.from(updatedMessages)..add(aiMessage);
      emit(AiChatActive(messages: finalMessages, isLoading: false));
    } catch (e) {
      emit(AiChatActive(
        messages: updatedMessages,
        isLoading: false,
        errorMessage: "Không thể nhận phản hồi từ AI: $e",
      ));
    }
  }

  void clearChat(String userName) {
    emit(const AiChatInitial());
    initializeChat(userName);
  }
}
