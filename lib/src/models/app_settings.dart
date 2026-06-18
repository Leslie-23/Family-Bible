import 'dart:convert';

import 'package:flutter/material.dart';

enum AppPalette {
  parchment,
  forest,
  slate,
  ocean,
  plum,
  ember,
  graphite,
}

class AppSettings {
  final ThemeMode themeMode;
  final AppPalette palette;
  final double fontScale;
  final bool verseNumbers;

  const AppSettings({
    required this.themeMode,
    required this.palette,
    required this.fontScale,
    required this.verseNumbers,
  });

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    palette: AppPalette.parchment,
    fontScale: 1,
    verseNumbers: true,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppPalette? palette,
    double? fontScale,
    bool? verseNumbers,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      fontScale: fontScale ?? this.fontScale,
      verseNumbers: verseNumbers ?? this.verseNumbers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'palette': palette.name,
      'fontScale': fontScale,
      'verseNumbers': verseNumbers,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == map['themeMode'],
        orElse: () => AppSettings.defaults.themeMode,
      ),
      palette: AppPalette.values.firstWhere(
        (palette) => palette.name == map['palette'],
        orElse: () => AppSettings.defaults.palette,
      ),
      fontScale: (map['fontScale'] as num?)?.toDouble() ??
          AppSettings.defaults.fontScale,
      verseNumbers:
          map['verseNumbers'] as bool? ?? AppSettings.defaults.verseNumbers,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) {
    return AppSettings.fromMap(json.decode(source) as Map<String, dynamic>);
  }
}
