import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/verse_annotation.dart';
import '../models/verse_model.dart';
import '../services/annotation_service.dart';
import 'version_provider.dart';

class AnnotationNotifier extends StateNotifier<Map<String, VerseAnnotation>> {
  AnnotationNotifier() : super({});

  Future<void> load() async {
    state = await AnnotationService.readAll();
  }

  VerseAnnotation forVerse({
    required Verse verse,
    required String versionTitle,
  }) {
    final key = VerseAnnotation.keyFor(
      verse: verse,
      versionTitle: versionTitle,
    );

    return state[key] ??
        VerseAnnotation.empty(
          verse: verse,
          versionTitle: versionTitle,
        );
  }

  Future<void> save(VerseAnnotation annotation) async {
    final updated = {...state};
    if (annotation.isEmpty) {
      updated.remove(annotation.verseKey);
    } else {
      updated[annotation.verseKey] = annotation.copyWith(
        updatedAt: DateTime.now(),
      );
    }

    state = updated;
    await AnnotationService.saveAll(state);
  }
}

final annotationProvider =
    StateNotifierProvider<AnnotationNotifier, Map<String, VerseAnnotation>>(
        (ref) {
  return AnnotationNotifier();
});

final verseAnnotationProvider =
    Provider.family<VerseAnnotation, Verse>((ref, verse) {
  ref.watch(annotationProvider);
  final version = ref.watch(versionProvider);

  return ref.read(annotationProvider.notifier).forVerse(
        verse: verse,
        versionTitle: version.title,
      );
});
