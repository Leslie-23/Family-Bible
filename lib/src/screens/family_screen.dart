import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/family_provider.dart';
import '../providers/local_user_provider.dart';
import 'onboarding_screen.dart';
import '../widgets/ux_states.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final String? initialInviteCode;

  const FamilyScreen({
    super.key,
    this.showAppBar = true,
    this.initialInviteCode,
  });

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (widget.initialInviteCode != null) {
        await ref
            .read(familyProvider.notifier)
            .joinFamily(widget.initialInviteCode!);
      } else {
        await ref.read(familyProvider.notifier).loadFamilies();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localUser = ref.watch(localUserProvider);
    final family = ref.watch(familyProvider);

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Family')) : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(familyProvider.notifier).loadFamilies(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (!localUser.isAuthenticated)
              EmptyStateView(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to use Family',
                body:
                    'Family notes, comments, invites, and reading check-ins need an account.',
                actionLabel: 'Sign in or create account',
                onAction: _openSignIn,
              )
            else if (family.loading && family.families.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (family.families.isEmpty)
              EmptyStateView(
                icon: Icons.family_restroom_rounded,
                title: 'Create or join a family',
                body:
                    'Start a private family group so everyone can read together.',
                actionLabel: 'Create family',
                onAction: _createFamily,
              )
            else
              _FamilyDetails(
                family: family.selectedFamily ?? family.families.first,
                notes: family.notes,
                activity: family.activity,
                commentsByNote: family.commentsByNote,
                onCreate: _createFamily,
                onJoin: _joinFamily,
              ),
            if (localUser.isAuthenticated && family.families.isEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _joinFamily,
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Join with invite code'),
              ),
            ],
            if (family.error != null) ...[
              const SizedBox(height: 12),
              Text(
                family.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createFamily() async {
    final name = await _inputDialog(
      title: 'Create family',
      label: 'Family name',
      initialValue: 'My Family',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(familyProvider.notifier).createFamily(name.trim());
  }

  Future<void> _joinFamily() async {
    final code = await _inputDialog(
      title: 'Join family',
      label: 'Invite code',
      textCapitalization: TextCapitalization.characters,
    );
    if (code == null || code.trim().isEmpty) return;
    await ref.read(familyProvider.notifier).joinFamily(code.trim());
  }

  Future<void> _openSignIn() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(
          initialPage: 2,
          popOnComplete: true,
        ),
      ),
    );

    if (!mounted) return;
    if (ref.read(localUserProvider).isAuthenticated) {
      await ref.read(familyProvider.notifier).loadFamilies();
    }
  }

  Future<String?> _inputDialog({
    required String title,
    required String label,
    String initialValue = '',
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}

class _FamilyDetails extends ConsumerWidget {
  final Map<String, dynamic> family;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> activity;
  final Map<String, List<Map<String, dynamic>>> commentsByNote;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _FamilyDetails({
    required this.family,
    required this.notes,
    required this.activity,
    required this.commentsByNote,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = family['inviteCode']?.toString() ?? '';
    final members = (family['members'] as List? ?? []);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: colorScheme.onPrimary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family['name']?.toString() ?? 'Family',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${members.length} member${members.length == 1 ? '' : 's'} reading together',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.onPrimary.withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.key_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite code',
                                  style: TextStyle(
                                    color:
                                        colorScheme.onPrimary.withOpacity(0.72),
                                  ),
                                ),
                                SelectableText(
                                  code,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Share invite',
                            onPressed: () {
                              Share.share(
                                'Join my family on Family Bible! Use invite code: $code\n\nOr tap: familybible://invite/$code',
                              );
                            },
                            icon: const Icon(Icons.ios_share_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: onJoin,
                          icon: const Icon(Icons.group_add_rounded),
                          label: const Text('Join another'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: onCreate,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New family'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.people_alt_rounded,
                value: members.length.toString(),
                label: 'Members',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.sticky_note_2_rounded,
                value: notes.length.toString(),
                label: 'Shared notes',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Members', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: members.map((member) {
              final user = member is Map ? member['userId'] : null;
              final name = user is Map ? user['name']?.toString() : 'Member';
              final email = user is Map ? user['email']?.toString() : null;
              final role = member is Map ? member['role']?.toString() : '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    (name == null || name.isEmpty ? 'M' : name[0])
                        .toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                title: Text(name ?? 'Member'),
                subtitle: Text([
                  if (role != null && role.isNotEmpty) role,
                  if (email != null && email.isNotEmpty) email,
                ].join(' · ')),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Text('Shared Family Notes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (notes.isEmpty)
          const EmptyStateView(
            icon: Icons.forum_outlined,
            title: 'No shared notes yet',
            body:
                'Open a verse, write a note or highlight it, then tap Share with family.',
          )
        else
          ...notes.map(
            (note) {
              final noteId = note['_id']?.toString() ?? '';
              return _SharedNoteCard(
                note: note,
                comments: commentsByNote[noteId] ?? const [],
              );
            },
          ),
        const SizedBox(height: 20),
        Text('Recent Activity', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (activity.isEmpty)
          const EmptyStateView(
            icon: Icons.bolt_outlined,
            title: 'No reading activity yet',
            body:
                'Reading check-ins and shared notes will appear here once your family starts using the app.',
          )
        else
          Card(
            child: Column(
              children: activity.take(8).map((item) {
                final user = item['userId'];
                final name = user is Map ? user['name']?.toString() : null;
                final event = item['event']?.toString() ?? 'activity';
                final createdAt = _friendlyDate(item['createdAt']?.toString());
                return ListTile(
                  leading: Icon(_activityIcon(event)),
                  title: Text(_activityTitle(event, name)),
                  subtitle: Text(createdAt),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  IconData _activityIcon(String event) {
    return switch (event) {
      'read' => Icons.menu_book_rounded,
      'note' => Icons.sticky_note_2_rounded,
      'comment' => Icons.chat_bubble_rounded,
      'highlight' => Icons.format_color_fill_rounded,
      _ => Icons.bolt_rounded,
    };
  }

  String _activityTitle(String event, String? name) {
    final who = name == null || name.isEmpty ? 'Someone' : name;
    return switch (event) {
      'read' => '$who checked in',
      'note' => '$who shared a note',
      'comment' => '$who commented',
      'highlight' => '$who shared a highlight',
      _ => '$who had activity',
    };
  }

  String _friendlyDate(String? value) {
    if (value == null || value.isEmpty) return '';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedNoteCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> note;
  final List<Map<String, dynamic>> comments;

  const _SharedNoteCard({
    required this.note,
    required this.comments,
  });

  @override
  ConsumerState<_SharedNoteCard> createState() => _SharedNoteCardState();
}

class _SharedNoteCardState extends ConsumerState<_SharedNoteCard> {
  final TextEditingController _commentController = TextEditingController();
  bool _expanded = false;
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final author = note['authorId'];
    final authorName = author is Map ? author['name']?.toString() : null;
    final noteId = note['_id']?.toString() ?? '';
    final reference = '${note['book']} ${note['chapter']}:${note['verse']}';
    final body = note['note']?.toString() ?? '';
    final verseText = note['verseText']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reference,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(authorName == null ? 'Shared' : 'by $authorName'),
              ],
            ),
            if (verseText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                verseText,
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? null : TextOverflow.ellipsis,
              ),
            ],
            if (body.isNotEmpty) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(body),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    setState(() => _expanded = !_expanded);
                    if (!_expanded || widget.comments.isNotEmpty) return;
                    await ref.read(familyProvider.notifier).loadComments(noteId);
                  },
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.mode_comment_outlined,
                  ),
                  label: Text(
                    _expanded
                        ? 'Hide comments'
                        : '${widget.comments.length} comments',
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const Divider(),
              if (widget.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No comments yet. Start the conversation.'),
                )
              else
                ...widget.comments.map((comment) {
                  final commentAuthor = comment['authorId'];
                  final commentName = commentAuthor is Map
                      ? commentAuthor['name']?.toString()
                      : 'Member';
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person_rounded, size: 16),
                    ),
                    title: Text(commentName ?? 'Member'),
                    subtitle: Text(comment['body']?.toString() ?? ''),
                  );
                }),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add a family comment',
                  suffixIcon: IconButton(
                    onPressed: _sending ? null : () => _sendComment(noteId),
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendComment(String noteId) async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    await ref.read(familyProvider.notifier).addComment(
          noteId: noteId,
          body: body,
        );
    _commentController.clear();
    if (mounted) setState(() => _sending = false);
  }
}
