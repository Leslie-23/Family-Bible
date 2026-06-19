import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/verse_annotation.dart';
import '../models/verse_model.dart';
import '../providers/annotation_provider.dart';
import '../providers/family_provider.dart';
import '../providers/local_user_provider.dart';
import '../providers/version_provider.dart';
import '../utils/highlight_color_util.dart';
import 'ux_states.dart';

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
  bool _sharingWithFamily = false;

  @override
  void initState() {
    super.initState();
    final annotation = ref.read(verseAnnotationProvider(widget.verse));
    _noteController = TextEditingController(text: annotation.note);
    Future.microtask(() {
      if (ref.read(localUserProvider).isAuthenticated) {
        ref.read(familyProvider.notifier).loadFamilies();
      }
    });
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
    final localUser = ref.watch(localUserProvider);
    final family = ref.watch(familyProvider);
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
                        ThemedSnackBar.success(context, 'Note cleared');
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
                      ThemedSnackBar.success(context, 'Note saved');
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
                      ThemedSnackBar.success(context, 'Verse copied');
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
              const SizedBox(height: 18),
              _FamilySharePanel(
                authenticated: localUser.isAuthenticated,
                hasFamily: family.families.isNotEmpty ||
                    family.selectedFamily != null,
                loading: _sharingWithFamily || family.loading,
                onShare: () => _shareWithFamily(
                  versionTitle: version.title,
                  annotation: annotation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareWithFamily({
    required String versionTitle,
    required VerseAnnotation annotation,
  }) async {
    final updated = annotation.copyWith(note: _noteController.text.trim());
    if (updated.isEmpty) {
      ThemedSnackBar.success(
        context,
        'Add a note or highlight before sharing',
      );
      return;
    }

    setState(() => _sharingWithFamily = true);
    try {
      await ref.read(annotationProvider.notifier).save(updated);
      await ref.read(familyProvider.notifier).shareAnnotation(
            verse: widget.verse,
            versionTitle: versionTitle,
            annotation: updated,
          );
      if (!mounted) return;
      ThemedSnackBar.success(context, 'Shared with your family');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sharingWithFamily = false);
    }
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

class _FamilySharePanel extends StatelessWidget {
  final bool authenticated;
  final bool hasFamily;
  final bool loading;
  final VoidCallback onShare;

  const _FamilySharePanel({
    required this.authenticated,
    required this.hasFamily,
    required this.loading,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = !authenticated
        ? 'Family sharing needs sign-in'
        : !hasFamily
            ? 'Create or join a family first'
            : 'Share this reflection with family';
    final body = !authenticated
        ? 'Your local note stays on this device until you sign in.'
        : !hasFamily
            ? 'Open the Family tab to create a group or enter an invite code.'
            : 'Family members will see the verse, note, highlight, and can comment.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body),
            if (authenticated && hasFamily) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: loading ? null : onShare,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(loading ? 'Sharing...' : 'Share with family'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
