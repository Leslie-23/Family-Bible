import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user.dart';
import '../services/local_user_service.dart';

class LocalUserState {
  final bool onboardingComplete;
  final LocalUser? user;
  final String? token;
  final bool loading;

  const LocalUserState({
    required this.onboardingComplete,
    required this.user,
    required this.token,
    required this.loading,
  });

  static const initial = LocalUserState(
    onboardingComplete: false,
    user: null,
    token: null,
    loading: true,
  );

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  LocalUserState copyWith({
    bool? onboardingComplete,
    LocalUser? user,
    String? token,
    bool clearUser = false,
    bool? loading,
  }) {
    return LocalUserState(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      user: clearUser ? null : user ?? this.user,
      token: clearUser ? null : token ?? this.token,
      loading: loading ?? this.loading,
    );
  }
}

class LocalUserNotifier extends StateNotifier<LocalUserState> {
  LocalUserNotifier() : super(LocalUserState.initial);

  Future<void> load() async {
    final onboardingComplete = await LocalUserService.isOnboardingComplete();
    final user = await LocalUserService.readUser();
    final token = await LocalUserService.readToken();
    state = LocalUserState(
      onboardingComplete: onboardingComplete,
      user: user,
      token: user?.token ?? token,
      loading: false,
    );
  }

  Future<void> completeOnboarding() async {
    await LocalUserService.completeOnboarding();
    state = state.copyWith(onboardingComplete: true);
  }

  Future<void> saveUser(LocalUser user) async {
    await LocalUserService.saveUser(user);
    await LocalUserService.completeOnboarding();
    state = LocalUserState(
      onboardingComplete: true,
      user: user,
      token: user.token,
      loading: false,
    );
  }

  Future<void> signOut() async {
    await LocalUserService.signOut();
    state = state.copyWith(clearUser: true);
  }
}

final localUserProvider =
    StateNotifierProvider<LocalUserNotifier, LocalUserState>((ref) {
  return LocalUserNotifier();
});
