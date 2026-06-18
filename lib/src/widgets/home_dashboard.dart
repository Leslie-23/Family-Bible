import 'package:flutter/material.dart';

import '../config/family_bible_config.dart';
import '../models/verse_model.dart';

class HomeDashboard extends StatelessWidget {
  final List<Verse> verses;
  final int currentIndex;
  final int noteCount;
  final int highlightCount;
  final VoidCallback onSearch;
  final VoidCallback onContinueReading;
  final VoidCallback onOpenNotes;
  final VoidCallback onOpenFamily;
  final ValueChanged<int> onOpenVerse;

  const HomeDashboard({
    super.key,
    required this.verses,
    required this.currentIndex,
    required this.noteCount,
    required this.highlightCount,
    required this.onSearch,
    required this.onContinueReading,
    required this.onOpenNotes,
    required this.onOpenFamily,
    required this.onOpenVerse,
  });

  @override
  Widget build(BuildContext context) {
    final dailyVerse = _dailyVerse;
    final activeVerse = verses.isEmpty
        ? null
        : verses[currentIndex.clamp(0, verses.length - 1)];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          FamilyBibleConfig.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'By ${FamilyBibleConfig.ownerBrand}. Read together, reflect together.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Search scripture'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scripture of the day',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (dailyVerse == null)
                  const LinearProgressIndicator()
                else ...[
                  Text(
                    dailyVerse.text.trim(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${dailyVerse.book} ${dailyVerse.chapter}:'
                    '${dailyVerse.verse}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        final index = verses.indexOf(dailyVerse);
                        if (index != -1) onOpenVerse(index);
                      },
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('Read here'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_added_outlined),
            title: const Text('Continue reading'),
            subtitle: activeVerse == null
                ? const Text('Loading your place')
                : Text('${activeVerse.book} ${activeVerse.chapter}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onContinueReading,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.sticky_note_2_outlined,
                label: 'Notes',
                value: noteCount,
                onTap: onOpenNotes,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.palette_outlined,
                label: 'Highlights',
                value: highlightCount,
                onTap: onOpenNotes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: const Icon(Icons.family_restroom_rounded),
            title: const Text('My Family'),
            subtitle: const Text('Create or join a family group'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenFamily,
          ),
        ),
      ],
    );
  }

  Verse? get _dailyVerse {
    if (verses.isEmpty) return null;

    final inspirational = verses.where((verse) {
      return const {
        'Psalms',
        'Proverbs',
        'Isaiah',
        'Matthew',
        'John',
        'Romans',
        'Philippians',
        'James',
      }.contains(verse.book);
    }).toList();

    final source = inspirational.isEmpty ? verses : inspirational;
    final day = DateTime.now().difference(DateTime(2024)).inDays;
    return source[day % source.length];
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final VoidCallback onTap;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 14),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
