import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _adminChatsSubscription;
  StreamSubscription? _messagesSubscription;

  ChatCubit({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial());

  void loadAdminChats() {
    emit(ChatLoading());
    _adminChatsSubscription?.cancel();
    _adminChatsSubscription = _chatRepository.getAdminChatsStream().listen(
      (chats) {
        emit(AdminChatsLoaded(chats));
      },
      onError: (error) {
        emit(ChatError(error.toString()));
      },
    );
  }

  void loadMessages(String customerId) {
    emit(ChatLoading());
    _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository.getMessagesStream(customerId).listen(
      (messages) {
        emit(ChatMessagesLoaded(messages));
      },
      onError: (error) {
        emit(ChatError(error.toString()));
      },
    );
  }

  Future<void> sendMessage({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String text,
    required String senderId,
    required String senderName,
    required bool isAdmin,
  }) async {
    try {
      await _chatRepository.sendMessage(
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        text: text,
        senderId: senderId,
        senderName: senderName,
        isAdmin: isAdmin,
      );
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> markAdminRead(String customerId) async {
    try {
      await _chatRepository.markAdminRead(customerId);
    } catch (e) {
      // Background operation, no need to emit error to UI unless necessary
    }
  }

  Future<void> markCustomerRead(String customerId) async {
    try {
      await _chatRepository.markCustomerRead(customerId);
    } catch (e) {
      // Background operation
    }
  }

  @override
  Future<void> close() {
    _adminChatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
