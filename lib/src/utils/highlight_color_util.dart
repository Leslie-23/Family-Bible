import 'package:flutter/material.dart';

import '../models/verse_annotation.dart';

class HighlightColorUtil {
  static Color? background(
    HighlightColor highlight,
    Brightness brightness,
  ) {
    final opacity = brightness == Brightness.dark ? 0.26 : 0.42;

    return switch (highlight) {
      HighlightColor.none => null,
      HighlightColor.honey => const Color(0xFFE4B84D).withOpacity(opacity),
      HighlightColor.sage => const Color(0xFF8CB369).withOpacity(opacity),
      HighlightColor.sky => const Color(0xFF73A8D4).withOpacity(opacity),
      HighlightColor.rose => const Color(0xFFD9828B).withOpacity(opacity),
    };
  }

  static Color swatch(HighlightColor highlight) {
    return switch (highlight) {
      HighlightColor.none => Colors.transparent,
      HighlightColor.honey => const Color(0xFFE4B84D),
      HighlightColor.sage => const Color(0xFF8CB369),
      HighlightColor.sky => const Color(0xFF73A8D4),
      HighlightColor.rose => const Color(0xFFD9828B),
    };
  }
}
