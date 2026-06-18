import 'package:shared_preferences/shared_preferences.dart';

import '../models/verse_annotation.dart';

class AnnotationService {
  static const _annotationsKey = 'verse_annotations';

  static Future<Map<String, VerseAnnotation>> readAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_annotationsKey) ?? [];

    final annotations = <String, VerseAnnotation>{};
    for (final value in raw) {
      final annotation = VerseAnnotation.fromJson(value);
      annotations[annotation.verseKey] = annotation;
    }

    return annotations;
  }

  static Future<void> saveAll(Map<String, VerseAnnotation> annotations) async {
    final preferences = await SharedPreferences.getInstance();
    final values = annotations.values
        .where((annotation) => !annotation.isEmpty)
        .map((annotation) => annotation.toJson())
        .toList();

    await preferences.setStringList(_annotationsKey, values);
  }
}
