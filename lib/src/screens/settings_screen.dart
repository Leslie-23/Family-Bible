import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/annotation_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  final bool showAppBar;

  const SettingsScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final annotations = ref.watch(annotationProvider).values.toList();
    final noteCount =
        annotations.where((annotation) => annotation.hasNote).length;
    final highlightCount =
        annotations.where((annotation) => annotation.hasHighlight).length;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Settings'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Reading',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Dark'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) {
              _save(
                ref,
                settings.copyWith(themeMode: selection.first),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Palette',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppPalette.values.map((palette) {
              final selected = palette == settings.palette;
              return ChoiceChip(
                label: Text(_paletteLabel(palette)),
                avatar: CircleAvatar(
                  backgroundColor: _paletteColor(palette),
                  radius: 8,
                ),
                selected: selected,
                onSelected: (_) {
                  _save(
                    ref,
                    settings.copyWith(palette: palette),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.format_size_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: settings.fontScale,
                  min: 0.85,
                  max: 1.35,
                  divisions: 10,
                  label: '${(settings.fontScale * 100).round()}%',
                  onChanged: (value) {
                    _save(
                      ref,
                      settings.copyWith(fontScale: value),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${(settings.fontScale * 100).round()}%',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.verseNumbers,
            title: const Text('Show verse numbers'),
            secondary: const Icon(Icons.format_list_numbered_rounded),
            onChanged: (value) {
              _save(
                ref,
                settings.copyWith(verseNumbers: value),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Local Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: const Text('Notes'),
            trailing: Text('$noteCount'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Highlights'),
            trailing: Text('$highlightCount'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
    WidgetRef ref,
    AppSettings settings,
  ) async {
    await ref.read(settingsProvider.notifier).update(settings);
  }

  String _paletteLabel(AppPalette palette) {
    return switch (palette) {
      AppPalette.parchment => 'Warm',
      AppPalette.forest => 'Forest',
      AppPalette.slate => 'Slate',
      AppPalette.ocean => 'Ocean',
      AppPalette.plum => 'Plum',
      AppPalette.ember => 'Ember',
      AppPalette.graphite => 'Graphite',
    };
  }

  Color _paletteColor(AppPalette palette) {
    return switch (palette) {
      AppPalette.parchment => const Color(0xFF8B5E34),
      AppPalette.forest => const Color(0xFF3F6F57),
      AppPalette.slate => const Color(0xFF586F7C),
      AppPalette.ocean => const Color(0xFF1D6F8A),
      AppPalette.plum => const Color(0xFF7B5268),
      AppPalette.ember => const Color(0xFF9A4F2D),
      AppPalette.graphite => const Color(0xFF52565A),
    };
  }
}
