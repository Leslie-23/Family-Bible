import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/family_api_service.dart';
import 'local_user_provider.dart';

class FamilyState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> families;
  final Map<String, dynamic>? selectedFamily;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> activity;

  const FamilyState({
    required this.loading,
    required this.error,
    required this.families,
    required this.selectedFamily,
    required this.notes,
    required this.activity,
  });

  static const initial = FamilyState(
    loading: false,
    error: null,
    families: [],
    selectedFamily: null,
    notes: [],
    activity: [],
  );

  FamilyState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? families,
    Map<String, dynamic>? selectedFamily,
    List<Map<String, dynamic>>? notes,
    List<Map<String, dynamic>>? activity,
  }) {
    return FamilyState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      families: families ?? this.families,
      selectedFamily: selectedFamily ?? this.selectedFamily,
      notes: notes ?? this.notes,
      activity: activity ?? this.activity,
    );
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  final Ref ref;
  final FamilyApiService api;

  FamilyNotifier(this.ref, this.api) : super(FamilyState.initial);

  String? get _token => ref.read(localUserProvider).token;

  Future<void> loadFamilies() async {
    final token = _token;
    if (token == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final result = await api.listFamilies(token: token);
      final families = _list(result['families']);
      state = state.copyWith(
        loading: false,
        families: families,
        selectedFamily: families.isEmpty ? null : families.first,
      );
      if (families.isNotEmpty) {
        await loadFamilyDetails(families.first['_id'].toString());
      }
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> createFamily(String name) async {
    final token = _token;
    if (token == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await api.createFamily(token: token, name: name);
      await loadFamilies();
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> joinFamily(String inviteCode) async {
    final token = _token;
    if (token == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await api.joinFamily(token: token, inviteCode: inviteCode);
      await loadFamilies();
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> loadFamilyDetails(String familyId) async {
    final token = _token;
    if (token == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final detail = await api.getFamily(token: token, familyId: familyId);
      final notes = await api.getFamilyNotes(token: token, familyId: familyId);
      final activity =
          await api.getFamilyActivity(token: token, familyId: familyId);
      state = state.copyWith(
        loading: false,
        selectedFamily: detail['family'] as Map<String, dynamic>?,
        notes: _list(notes['notes']),
        activity: _list(activity['activity']),
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  List<Map<String, dynamic>> _list(Object? value) {
    return (value as List? ?? [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}

final familyProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  return FamilyNotifier(ref, FamilyApiService());
});
