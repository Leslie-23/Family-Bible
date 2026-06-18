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
}

class FamilyApiException implements Exception {
  final String message;
  final int statusCode;

  const FamilyApiException(this.message, this.statusCode);

  @override
  String toString() => 'FamilyApiException($statusCode): $message';
}
