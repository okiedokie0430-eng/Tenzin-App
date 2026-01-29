import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenzin/presentation/providers/auth_provider.dart';

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(super.ref) : super(autoCheck: false);

  @override
  void refreshUser() {
    // Avoid network calls in widget tests.
    state = state.copyWith(isLoading: true);
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: false,
      user: null,
      failure: null,
    );
  }
}

List<Override> testOverrides() {
  return [
    authProvider.overrideWith((ref) => TestAuthNotifier(ref)),
  ];
}
