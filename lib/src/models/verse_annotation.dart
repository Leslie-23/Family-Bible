import 'dart:convert';

import 'verse_model.dart';

enum HighlightColor {
  none,
  honey,
  sage,
  sky,
  rose,
}

class VerseAnnotation {
  final String verseKey;
  final String versionTitle;
  final String book;
  final int chapter;
  final int verse;
  final String note;
  final HighlightColor highlightColor;
  final DateTime updatedAt;

  const VerseAnnotation({
    required this.verseKey,
    required this.versionTitle,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.note,
    required this.highlightColor,
    required this.updatedAt,
  });

  factory VerseAnnotation.empty({
    required Verse verse,
    required String versionTitle,
  }) {
    return VerseAnnotation(
      verseKey: keyFor(verse: verse, versionTitle: versionTitle),
      versionTitle: versionTitle,
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
      note: '',
      highlightColor: HighlightColor.none,
      updatedAt: DateTime.now(),
    );
  }

  static String keyFor({
    required Verse verse,
    required String versionTitle,
  }) {
    return [
      versionTitle.trim().toLowerCase(),
      verse.book.trim().toLowerCase(),
      verse.chapter,
      verse.verse,
    ].join('|');
  }

  bool get hasNote => note.trim().isNotEmpty;

  bool get hasHighlight => highlightColor != HighlightColor.none;

  bool get isEmpty => !hasNote && !hasHighlight;

  VerseAnnotation copyWith({
    String? note,
    HighlightColor? highlightColor,
    DateTime? updatedAt,
  }) {
    return VerseAnnotation(
      verseKey: verseKey,
      versionTitle: versionTitle,
      book: book,
      chapter: chapter,
      verse: verse,
      note: note ?? this.note,
      highlightColor: highlightColor ?? this.highlightColor,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verseKey': verseKey,
      'versionTitle': versionTitle,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'note': note,
      'highlightColor': highlightColor.name,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory VerseAnnotation.fromMap(Map<String, dynamic> map) {
    return VerseAnnotation(
      verseKey: map['verseKey'] as String,
      versionTitle: map['versionTitle'] as String,
      book: map['book'] as String,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      note: map['note'] as String? ?? '',
      highlightColor: HighlightColor.values.firstWhere(
        (color) => color.name == map['highlightColor'],
        orElse: () => HighlightColor.none,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory VerseAnnotation.fromJson(String source) {
    return VerseAnnotation.fromMap(json.decode(source) as Map<String, dynamic>);
  }
}
