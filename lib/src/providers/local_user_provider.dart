import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user.dart';
import '../services/local_user_service.dart';

class LocalUserState {
  final bool onboardingComplete;
  final LocalUser? user;
  final bool loading;

  const LocalUserState({
    required this.onboardingComplete,
    required this.user,
    required this.loading,
  });

  static const initial = LocalUserState(
    onboardingComplete: false,
    user: null,
    loading: true,
  );

  LocalUserState copyWith({
    bool? onboardingComplete,
    LocalUser? user,
    bool clearUser = false,
    bool? loading,
  }) {
    return LocalUserState(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      user: clearUser ? null : user ?? this.user,
      loading: loading ?? this.loading,
    );
  }
}

class LocalUserNotifier extends StateNotifier<LocalUserState> {
  LocalUserNotifier() : super(LocalUserState.initial);

  Future<void> load() async {
    final onboardingComplete = await LocalUserService.isOnboardingComplete();
    final user = await LocalUserService.readUser();
    state = LocalUserState(
      onboardingComplete: onboardingComplete,
      user: user,
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
