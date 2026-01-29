import '../../data/models/support_message.dart';
import '../../data/repositories/support_repository.dart';
import '../../core/error/failures.dart';

class GetSupportMessagesUseCase {
  final SupportRepository _repository;

  GetSupportMessagesUseCase(this._repository);

  Future<({List<SupportMessageModel> messages, Failure? failure})> call(
    String userId,
  ) {
    return _repository.getMessages(userId);
  }
}

class SendSupportMessageUseCase {
  final SupportRepository _repository;

  SendSupportMessageUseCase(this._repository);

  Future<({SupportMessageModel? message, Failure? failure})> call({
    required String userId,
    required String messageText,
  }) {
    return _repository.sendMessage(
      userId: userId,
      messageText: messageText,
    );
  }
}

class GetSupportUnrespondedCountUseCase {
  final SupportRepository _repository;

  GetSupportUnrespondedCountUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getUnrespondedCount(userId);
  }
}
