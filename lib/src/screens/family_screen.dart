import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/family_provider.dart';
import '../providers/local_user_provider.dart';
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
                actionLabel: 'Use onboarding sign-in',
                onAction: () {},
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

class _FamilyDetails extends StatelessWidget {
  final Map<String, dynamic> family;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> activity;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _FamilyDetails({
    required this.family,
    required this.notes,
    required this.activity,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final code = family['inviteCode']?.toString() ?? '';
    final members = (family['members'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  family['name']?.toString() ?? 'Family',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                InputChip(
                  avatar: const Icon(Icons.key_rounded),
                  label: Text(code),
                  onPressed: () {
                    Share.share(
                      'Join my family on Family Bible! Use invite code: $code\n\nOr tap: familybible://invite/$code',
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.group_add_rounded),
                      label: const Text('Join'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Members', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...members.map((member) {
          final user = member is Map ? member['userId'] : null;
          final name = user is Map ? user['name']?.toString() : 'Member';
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text(name ?? 'Member'),
            subtitle:
                Text(member is Map ? member['role']?.toString() ?? '' : ''),
          );
        }),
        const SizedBox(height: 16),
        Text('Family Notes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (notes.isEmpty)
          const Text('No shared family notes yet.')
        else
          ...notes.take(6).map((note) => ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title:
                    Text('${note['book']} ${note['chapter']}:${note['verse']}'),
                subtitle: Text(
                  note['note']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        const SizedBox(height: 16),
        Text('Activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (activity.isEmpty)
          const Text('No family reading activity yet.')
        else
          ...activity.take(8).map((item) => ListTile(
                leading: const Icon(Icons.bolt_rounded),
                title: Text(item['event']?.toString() ?? 'activity'),
                subtitle: Text(item['createdAt']?.toString() ?? ''),
              )),
      ],
    );
  }
}
