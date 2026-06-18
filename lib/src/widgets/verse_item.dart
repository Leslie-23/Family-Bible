import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/verse_model.dart';
import '../providers/annotation_provider.dart';
import '../providers/selected_verses_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/font_size_util.dart';
import '../utils/highlight_color_util.dart';
import 'verse_action_sheet.dart';

class VerseItem extends ConsumerWidget {
  final Verse verse;
  const VerseItem({super.key, required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedVersesProvider);
    final annotation = ref.watch(verseAnnotationProvider(verse));
    final settings = ref.watch(settingsProvider);

    bool isSelected =
        selected.any((test) => test.toString() == verse.toString());
    final highlightColor = HighlightColorUtil.background(
      annotation.highlightColor,
      Theme.of(context).brightness,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (verse.chapter == 1 && verse.verse == 1)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 75),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  verse.book,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : highlightColor,
          ),
          child: InkWell(
            onLongPress: () {
              if (isSelected) {
                ref.read(selectedVersesProvider.notifier).remove(verse);
              } else {
                ref.read(selectedVersesProvider.notifier).add(verse);
              }
            },
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => VerseActionSheet(verse: verse),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <InlineSpan>[
                    if (settings.verseNumbers)
                      TextSpan(
                        text: verse.verse == 1
                            ? "${verse.chapter.toString()}  "
                            : "${verse.verse.toString()}  ",
                        style: TextStyle(
                          fontSize: verse.verse == 1
                              ? FontSizeUtil.font1(context, ref)
                              : FontSizeUtil.font5(context, ref),
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: verse.verse == 1 ? FontWeight.bold : null,
                        ),
                      ),
                    TextSpan(
                      text: verse.text.trim(),
                      style: TextStyle(
                        fontSize: FontSizeUtil.font4(context, ref),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        decorationColor: Theme.of(context).colorScheme.primary,
                        decorationStyle: TextDecorationStyle.wavy,
                        decoration:
                            isSelected ? TextDecoration.underline : null,
                      ),
                    ),
                    if (annotation.hasNote)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.sticky_note_2_outlined,
                            size: FontSizeUtil.font5(context, ref) + 4,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
