import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/verse_annotation.dart';
import '../models/verse_model.dart';
import '../providers/annotation_provider.dart';
import '../providers/scroll_controller_provider.dart';
import '../providers/version_provider.dart';
import '../utils/highlight_color_util.dart';
import '../widgets/ux_states.dart';
import '../widgets/verse_action_sheet.dart';

class NotesScreen extends ConsumerWidget {
  final List<Verse> verses;
  final bool showAppBar;

  const NotesScreen({
    super.key,
    required this.verses,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(versionProvider);
    final annotations = ref
        .watch(annotationProvider)
        .values
        .where((annotation) =>
            annotation.versionTitle == version.title && !annotation.isEmpty)
        .toList()
      ..sort((a, b) {
        final first = _indexOf(a);
        final second = _indexOf(b);
        return first.compareTo(second);
      });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: const Text('Notes'),
                actions: [
                  if (annotations.isNotEmpty)
                    IconButton(
                      tooltip: 'Share all',
                      onPressed: () {
                        Share.share(_exportText(annotations));
                      },
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Notes'),
                    Tab(text: 'Highlights'),
                  ],
                ),
              )
            : null,
        body: Column(
          children: [
            if (!showAppBar)
              const TabBar(
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Notes'),
                  Tab(text: 'Highlights'),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _AnnotationList(
                    annotations: annotations,
                    verses: verses,
                  ),
                  _AnnotationList(
                    annotations: annotations
                        .where((annotation) => annotation.hasNote)
                        .toList(),
                    verses: verses,
                  ),
                  _AnnotationList(
                    annotations: annotations
                        .where((annotation) => annotation.hasHighlight)
                        .toList(),
                    verses: verses,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _indexOf(VerseAnnotation annotation) {
    final index = verses.indexWhere(
      (verse) =>
          verse.book == annotation.book &&
          verse.chapter == annotation.chapter &&
          verse.verse == annotation.verse,
    );
    return index == -1 ? 999999 : index;
  }

  String _exportText(List<VerseAnnotation> annotations) {
    return annotations.map((annotation) {
      final verse = _verseFor(annotation);
      final reference =
          '${annotation.book} ${annotation.chapter}:${annotation.verse}';
      final note = annotation.hasNote ? '\nNote: ${annotation.note}' : '';
      final highlight = annotation.hasHighlight
          ? '\nHighlight: ${annotation.highlightColor.name}'
          : '';
      final text = verse == null ? '' : '\n${verse.text.trim()}';

      return '$reference$text$note$highlight';
    }).join('\n\n');
  }

  Verse? _verseFor(VerseAnnotation annotation) {
    for (final verse in verses) {
      if (verse.book == annotation.book &&
          verse.chapter == annotation.chapter &&
          verse.verse == annotation.verse) {
        return verse;
      }
    }

    return null;
  }
}

class _AnnotationList extends ConsumerWidget {
  final List<VerseAnnotation> annotations;
  final List<Verse> verses;

  const _AnnotationList({
    required this.annotations,
    required this.verses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (annotations.isEmpty) {
      return const EmptyStateView(
        icon: Icons.sticky_note_2_outlined,
        title: 'No notes yet',
        body:
            'Tap any verse to add a note or highlight. Your family reflections will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: annotations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final annotation = annotations[index];
        final verse = _verseFor(annotation);

        return Card(
          child: InkWell(
            onTap: verse == null
                ? null
                : () {
                    final verseIndex = verses.indexOf(verse);
                    ScrollControllerProvider.jumpTo(
                      ref: ref,
                      index: verseIndex,
                    );
                    Navigator.pop(context);
                  },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${annotation.book} '
                          '${annotation.chapter}:${annotation.verse}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      if (annotation.hasHighlight)
                        _HighlightDot(color: annotation.highlightColor),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: verse == null
                            ? null
                            : () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  builder: (_) =>
                                      VerseActionSheet(verse: verse),
                                );
                              },
                        icon: const Icon(Icons.edit_note_rounded),
                      ),
                    ],
                  ),
                  if (verse != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      verse.text.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (annotation.hasNote) ...[
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(annotation.note),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Share.share(_shareText(annotation, verse));
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Verse? _verseFor(VerseAnnotation annotation) {
    for (final verse in verses) {
      if (verse.book == annotation.book &&
          verse.chapter == annotation.chapter &&
          verse.verse == annotation.verse) {
        return verse;
      }
    }

    return null;
  }

  String _shareText(VerseAnnotation annotation, Verse? verse) {
    final reference =
        '${annotation.book} ${annotation.chapter}:${annotation.verse}';
    final text = verse == null ? '' : '\n${verse.text.trim()}';
    final note = annotation.hasNote ? '\n\nNote: ${annotation.note}' : '';

    return '$reference$text$note';
  }
}

class _HighlightDot extends StatelessWidget {
  final HighlightColor color;

  const _HighlightDot({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: HighlightColorUtil.swatch(color),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const SizedBox.square(dimension: 18),
      ),
    );
  }
}
