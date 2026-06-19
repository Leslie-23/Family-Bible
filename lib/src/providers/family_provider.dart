import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/verse_annotation.dart';
import '../models/verse_model.dart';
import '../services/family_api_service.dart';
import 'local_user_provider.dart';

class FamilyState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> families;
  final Map<String, dynamic>? selectedFamily;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> activity;
  final Map<String, List<Map<String, dynamic>>> commentsByNote;

  const FamilyState({
    required this.loading,
    required this.error,
    required this.families,
    required this.selectedFamily,
    required this.notes,
    required this.activity,
    required this.commentsByNote,
  });

  static const initial = FamilyState(
    loading: false,
    error: null,
    families: [],
    selectedFamily: null,
    notes: [],
    activity: [],
    commentsByNote: {},
  );

  FamilyState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? families,
    Map<String, dynamic>? selectedFamily,
    List<Map<String, dynamic>>? notes,
    List<Map<String, dynamic>>? activity,
    Map<String, List<Map<String, dynamic>>>? commentsByNote,
  }) {
    return FamilyState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      families: families ?? this.families,
      selectedFamily: selectedFamily ?? this.selectedFamily,
      notes: notes ?? this.notes,
      activity: activity ?? this.activity,
      commentsByNote: commentsByNote ?? this.commentsByNote,
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
        notes: families.isEmpty ? [] : null,
        activity: families.isEmpty ? [] : null,
        commentsByNote: families.isEmpty ? {} : null,
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
        commentsByNote: {},
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> shareAnnotation({
    required Verse verse,
    required String versionTitle,
    required VerseAnnotation annotation,
  }) async {
    final token = _token;
    if (token == null) {
      throw const FamilyActionException('Sign in to share with family.');
    }

    if (state.families.isEmpty) {
      await loadFamilies();
    }

    final family = state.selectedFamily ??
        (state.families.isEmpty ? null : state.families.first);
    final familyId = family?['_id']?.toString();
    if (familyId == null || familyId.isEmpty) {
      throw const FamilyActionException(
        'Create or join a family before sharing notes.',
      );
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      await api.syncNote(
        token: token,
        familyId: familyId,
        verse: verse,
        versionTitle: versionTitle,
        annotation: annotation,
      );
      await loadFamilyDetails(familyId);
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
      rethrow;
    }
  }

  Future<void> loadComments(String noteId) async {
    final token = _token;
    final familyId = state.selectedFamily?['_id']?.toString();
    if (token == null || familyId == null) return;

    try {
      final result = await api.getComments(
        token: token,
        familyId: familyId,
        noteId: noteId,
      );
      state = state.copyWith(
        commentsByNote: {
          ...state.commentsByNote,
          noteId: _list(result['comments']),
        },
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> addComment({
    required String noteId,
    required String body,
  }) async {
    final token = _token;
    final familyId = state.selectedFamily?['_id']?.toString();
    if (token == null || familyId == null) return;

    try {
      await api.addComment(
        token: token,
        familyId: familyId,
        noteId: noteId,
        body: body,
      );
      await loadFamilyDetails(familyId);
      await loadComments(noteId);
    } catch (error) {
      state = state.copyWith(error: error.toString());
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

class FamilyActionException implements Exception {
  final String message;

  const FamilyActionException(this.message);

  @override
  String toString() => message;
}
