import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/verse_annotation.dart';
import '../models/verse_model.dart';
import '../providers/annotation_provider.dart';
import '../providers/version_provider.dart';
import '../utils/highlight_color_util.dart';

class VerseActionSheet extends ConsumerStatefulWidget {
  final Verse verse;

  const VerseActionSheet({
    super.key,
    required this.verse,
  });

  @override
  ConsumerState<VerseActionSheet> createState() => _VerseActionSheetState();
}

class _VerseActionSheetState extends ConsumerState<VerseActionSheet> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final annotation = ref.read(verseAnnotationProvider(widget.verse));
    _noteController = TextEditingController(text: annotation.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(versionProvider);
    final annotation = ref.watch(verseAnnotationProvider(widget.verse));
    final title = '${widget.verse.book} '
        '${widget.verse.chapter}:${widget.verse.verse}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.verse.text.trim(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.42,
                    ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _noteController,
                minLines: 4,
                maxLines: 8,
                autofocus: !annotation.hasNote,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Your note',
                  hintText: 'Write a thought, prayer, question, or reminder',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (annotation.hasNote)
                    TextButton.icon(
                      onPressed: () {
                        _noteController.clear();
                        ref.read(annotationProvider.notifier).save(
                              annotation.copyWith(note: ''),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note cleared')),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Clear'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(annotationProvider.notifier).save(
                            annotation.copyWith(
                              note: _noteController.text.trim(),
                            ),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note saved')),
                      );
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save note'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Highlight',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: HighlightColor.values.map((highlight) {
                  final selected = annotation.highlightColor == highlight;

                  return ChoiceChip(
                    label: Text(_highlightLabel(highlight)),
                    selected: selected,
                    avatar: CircleAvatar(
                      backgroundColor: HighlightColorUtil.swatch(highlight),
                      radius: 8,
                      child: highlight == HighlightColor.none
                          ? const Icon(Icons.close_rounded, size: 12)
                          : null,
                    ),
                    onSelected: (_) {
                      ref.read(annotationProvider.notifier).save(
                            annotation.copyWith(
                              highlightColor: highlight,
                            ),
                          );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy verse'),
                    onPressed: () {
                      final text = _verseText(version.title);
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verse copied')),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share verse'),
                    onPressed: () async {
                      await Share.share(_shareText(version.title, annotation));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _verseText(String versionTitle) {
    return '[${widget.verse.book} ${widget.verse.chapter}:'
        '${widget.verse.verse}] ${widget.verse.text.trim()} [$versionTitle]';
  }

  String _shareText(String versionTitle, VerseAnnotation annotation) {
    final note =
        annotation.hasNote ? '\n\nNote: ${annotation.note.trim()}' : '';
    return '${_verseText(versionTitle)}$note';
  }

  String _highlightLabel(HighlightColor highlight) {
    return switch (highlight) {
      HighlightColor.none => 'None',
      HighlightColor.honey => 'Honey',
      HighlightColor.sage => 'Sage',
      HighlightColor.sky => 'Sky',
      HighlightColor.rose => 'Rose',
    };
  }
}
