import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/chat_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;

  ChatCubit({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial());

  Future<void> sendMessage(String roomId, MessageModel message, String userName) async {
    emit(ChatSending());
    try {
      await _chatRepository.sendMessage(roomId, message, userName);
      emit(ChatMessageSent());
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  // We expose the stream directly for StreamBuilder UI
  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    return _chatRepository.getMessages(roomId);
  }
}
