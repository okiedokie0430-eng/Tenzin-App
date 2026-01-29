import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/support_message.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// Support State
class SupportState {
  final List<SupportMessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final Failure? failure;

  const SupportState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.failure,
  });

  SupportState copyWith({
    List<SupportMessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    Failure? failure,
  }) {
    return SupportState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      failure: failure,
    );
  }

  static const initial = SupportState();
}

// Support Notifier
class SupportNotifier extends StateNotifier<SupportState> {
  final Ref _ref;
  bool _isDisposed = false;

  SupportNotifier(this._ref) : super(SupportState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(SupportState Function(SupportState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadMessages(String userId) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(supportRepositoryProvider);
    
    final result = await repository.getMessages(userId);
    
    _safeUpdate((s) => s.copyWith(
      isLoading: false,
      messages: result.messages,
      failure: result.failure,
    ));
  }

  Future<bool> sendMessage(String userId, String content) async {
    if (_isDisposed) return false;
    _safeUpdate((s) => s.copyWith(isSending: true, failure: null));
    final repository = _ref.read(supportRepositoryProvider);
    
    final result = await repository.sendMessage(
      userId: userId,
      messageText: content,
    );
    
    if (result.failure == null && result.message != null) {
      final updated = [...state.messages, result.message!];
      _safeUpdate((s) => s.copyWith(isSending: false, messages: updated));
      return true;
    } else {
      _safeUpdate((s) => s.copyWith(isSending: false, failure: result.failure));
      return false;
    }
  }

  void addIncomingMessage(SupportMessageModel message) {
    if (_isDisposed) return;
    final updated = [...state.messages, message];
    _safeUpdate((s) => s.copyWith(messages: updated));
  }

  Future<void> refresh(String userId) async {
    await loadMessages(userId);
  }
}

// Support Provider
final supportProvider = StateNotifierProvider<SupportNotifier, SupportState>((ref) {
  final notifier = SupportNotifier(ref);
  
  // Auto-load when user changes
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    notifier.loadMessages(user.id);
  }
  
  return notifier;
});

// Convenience providers
final supportMessagesProvider = Provider<List<SupportMessageModel>>((ref) {
  return ref.watch(supportProvider).messages;
});

final unreadSupportCountProvider = Provider<int>((ref) {
  final messages = ref.watch(supportMessagesProvider);
  // Count messages that have admin response but status is still open
  return messages.where((m) => m.adminResponse != null && m.status == SupportMessageStatus.open).length;
});

final hasUnreadSupportProvider = Provider<bool>((ref) {
  return ref.watch(unreadSupportCountProvider) > 0;
});

final isSendingSupportProvider = Provider<bool>((ref) {
  return ref.watch(supportProvider).isSending;
});
