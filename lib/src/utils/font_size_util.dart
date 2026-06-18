import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class FontSizeUtil {
  static TextScaler _scale(BuildContext context) =>
      MediaQuery.of(context).textScaler;

  static double _withSettings(
    BuildContext context,
    WidgetRef ref,
    double size,
  ) {
    final settings = ref.watch(settingsProvider);
    return _scale(context).scale(size * settings.fontScale);
  }

  static double font1(BuildContext context, WidgetRef ref) =>
      _withSettings(context, ref, 36);

  static double font2(BuildContext context, WidgetRef ref) =>
      _withSettings(context, ref, 30);

  static double font3(BuildContext context, WidgetRef ref) =>
      _withSettings(context, ref, 24);

  static double font4(BuildContext context, WidgetRef ref) =>
      _withSettings(context, ref, 18);

  static double font5(BuildContext context, WidgetRef ref) =>
      _withSettings(context, ref, 12);
}
