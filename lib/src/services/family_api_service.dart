import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/family_bible_config.dart';
import '../models/verse_annotation.dart';
import '../models/verse_model.dart';

class FamilyApiService {
  final http.Client _client;
  final String baseUrl;

  FamilyApiService({
    http.Client? client,
    this.baseUrl = FamilyBibleConfig.apiBaseUrl,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _post('/api/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> createFamily({
    required String token,
    required String name,
  }) {
    return _post('/api/families', {'name': name}, token: token);
  }

  Future<Map<String, dynamic>> getMe({required String token}) {
    return _get('/api/me', token: token);
  }

  Future<Map<String, dynamic>> listFamilies({required String token}) {
    return _get('/api/families', token: token);
  }

  Future<Map<String, dynamic>> getFamily({
    required String token,
    required String familyId,
  }) {
    return _get('/api/families/$familyId', token: token);
  }

  Future<Map<String, dynamic>> getFamilyNotes({
    required String token,
    required String familyId,
  }) {
    return _get('/api/families/$familyId/notes', token: token);
  }

  Future<Map<String, dynamic>> getComments({
    required String token,
    required String familyId,
    required String noteId,
  }) {
    return _get('/api/families/$familyId/notes/$noteId/comments', token: token);
  }

  Future<Map<String, dynamic>> addComment({
    required String token,
    required String familyId,
    required String noteId,
    required String body,
  }) {
    return _post(
      '/api/families/$familyId/notes/$noteId/comments',
      {'body': body},
      token: token,
    );
  }

  Future<Map<String, dynamic>> getFamilyActivity({
    required String token,
    required String familyId,
  }) {
    return _get('/api/families/$familyId/activity', token: token);
  }

  Future<Map<String, dynamic>> registerDevice({
    required String token,
    required String platform,
    required String pushToken,
  }) {
    return _post(
      '/api/devices',
      {'platform': platform, 'pushToken': pushToken},
      token: token,
    );
  }

  Future<Map<String, dynamic>> joinFamily({
    required String token,
    required String inviteCode,
  }) {
    return _post(
        '/api/families/join',
        {
          'inviteCode': inviteCode,
        },
        token: token);
  }

  Future<Map<String, dynamic>> syncNote({
    required String token,
    required String familyId,
    required Verse verse,
    required String versionTitle,
    required VerseAnnotation annotation,
  }) {
    return _post(
        '/api/families/$familyId/notes',
        {
          'verseKey': annotation.verseKey,
          'versionTitle': versionTitle,
          'book': verse.book,
          'chapter': verse.chapter,
          'verse': verse.verse,
          'verseText': verse.text.trim(),
          'note': annotation.note,
          'highlightColor': annotation.highlightColor.name,
          'visibility': 'family',
        },
        token: token);
  }

  Future<Map<String, dynamic>> recordRead({
    required String token,
    required String familyId,
    required Verse verse,
    required String versionTitle,
  }) {
    return _post(
        '/api/families/$familyId/activity/read',
        {
          'verseKey': VerseAnnotation.keyFor(
            verse: verse,
            versionTitle: versionTitle,
          ),
          'versionTitle': versionTitle,
          'book': verse.book,
          'chapter': verse.chapter,
          'verse': verse.verse,
        },
        token: token);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw FamilyApiException(
        decoded['error']?.toString() ?? 'Request failed',
        response.statusCode,
      );
    }

    return decoded;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw FamilyApiException(
        decoded['error']?.toString() ?? 'Request failed',
        response.statusCode,
      );
    }

    return decoded;
  }
}

class FamilyApiException implements Exception {
  final String message;
  final int statusCode;

  const FamilyApiException(this.message, this.statusCode);

  @override
  String toString() => 'FamilyApiException($statusCode): $message';
}
