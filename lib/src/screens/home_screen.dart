import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/bible_version_model.dart';
import '../models/verse_model.dart';
import '../providers/last_index_provider.dart';
import '../providers/annotation_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/scroll_controller_provider.dart';
import '../providers/selected_verses_provider.dart';
import '../providers/verse_provider.dart';
import '../providers/version_provider.dart';
import '../services/cache_services.dart';
import '../services/fetch_bible_version_data.dart';
import '../services/fetch_cached_data.dart';
import '../services/notification_service.dart';
import '../services/show_versions.dart';
import '../services/user_action_services.dart';
import '../services/verse_services.dart';
// import '../widgets/ad_banner_view.dart';
import '../widgets/bible_view.dart';
import '../widgets/home_dashboard.dart';
import '../widgets/ux_states.dart';
import 'family_screen.dart';
import 'notes_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0;

  Future<void> _init() async {
    await fetchCachedData(ref: ref);

    final BibleVersion version = ref.read(versionProvider);

    await fetchBibleVersionData(ref: ref, version: version).then(
      (_) {
        ref
            .read(ScrollControllerProvider.itemPositionsListenerProvider)
            .itemPositions
            .addListener(
          () {
            final positions = ref
                .read(ScrollControllerProvider.itemPositionsListenerProvider)
                .itemPositions
                .value
                .toList();

            if (positions.isEmpty) return;

            final visiblePositions = positions
                .where((ItemPosition position) => position.itemTrailingEdge > 0)
                .toList();

            if (visiblePositions.isEmpty) return;

            final first = visiblePositions
                .reduce((ItemPosition min, ItemPosition position) =>
                    position.itemTrailingEdge < min.itemTrailingEdge
                        ? position
                        : min)
                .index;

            final firstIndex = first;

            CacheServices.saveVerseIndex(firstIndex);

            final versesState = ref.read(versesProvider);

            final verses = versesState.asData?.value ?? [];

            final firstVerseInViewPort = verses[firstIndex];

            final previousActiveVerse = _activeVerse ?? verses.first;

            if (firstVerseInViewPort.book != previousActiveVerse.book ||
                firstVerseInViewPort.chapter != previousActiveVerse.chapter) {
              if (!ref.read(versionChangedProvider)) {
                ref.read(lastIndexProvider.notifier).state = firstIndex;
              } else {
                ref.read(versionChangedProvider.notifier).state = false;
              }
              _activeVerse = firstVerseInViewPort;
            }
          },
        );
      },
    );

    NotificationService.scheduleDailyNotifications(version);
  }

  Verse? _activeVerse;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    VerseServices verseServices = VerseServices(ref);

    final versesState = ref.watch(versesProvider);

    final verses = versesState.asData?.value ?? [];

    bool versesLoaded = verses.isNotEmpty;

    final selected = ref.watch(selectedVersesProvider);

    final isVerseSelected = selected.isNotEmpty;

    final bibleVersion = ref.watch(versionProvider);
    final annotations = ref.watch(annotationProvider).values.toList();
    final isOnline = ref.watch(connectivityProvider).value ?? true;
    final noteCount =
        annotations.where((annotation) => annotation.hasNote).length;
    final highlightCount =
        annotations.where((annotation) => annotation.hasHighlight).length;
    final lastIndex = ref.watch(lastIndexProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: _selectedTab != 1 || versesLoaded == false
              ? Text(_appBarTitle)
              : Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24.0),
                    onTap: () async {
                      await showVersions(context: context, ref: ref);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              bibleVersion.title,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 4.0,
                              right: 8.0,
                            ),
                            child: Icon(Icons.arrow_drop_down_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          actions: [
            if (_selectedTab == 1 && isVerseSelected && versesLoaded)
              IconButton(
                onPressed: () {
                  verseServices.copy(selected);
                },
                icon: const Icon(
                  Icons.copy_rounded,
                ),
              ),
            if (_selectedTab == 1 && isVerseSelected && versesLoaded)
              IconButton(
                onPressed: () {
                  verseServices.share(selected);
                },
                icon: const Icon(
                  Icons.share_rounded,
                ),
              ),
            if (_selectedTab == 1 && !isVerseSelected && versesLoaded)
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return SearchScreen(verses);
                      },
                    ),
                  );
                },
                icon: const Icon(
                  Icons.search_rounded,
                ),
              ),
            if (_selectedTab == 1 && !isVerseSelected && versesLoaded)
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotesScreen(verses: verses),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.sticky_note_2_outlined,
                ),
              ),
            if (_selectedTab == 1 && !isVerseSelected && versesLoaded)
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.tune_rounded,
                ),
              ),
            if (_selectedTab == 1 && !isVerseSelected && versesLoaded)
              PopupMenuButton(
                menuPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      onTap: () {
                        UserActionServices.inviteFriend();
                      },
                      child: Text("Invite a friend"),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        UserActionServices.contactUs();
                      },
                      child: Text("Contact us"),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        UserActionServices.privacyPolicy();
                      },
                      child: Text("Privacy policy"),
                    ),
                  ];
                },
              ),
          ],
        ),
        body: Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: versesState.when(
                  data: (data) => _buildSelectedTab(
                    verses: data,
                    lastIndex: lastIndex,
                    noteCount: noteCount,
                    highlightCount: highlightCount,
                  ),
                  error: (error, stackTrace) => ErrorStateView(
                    error: error,
                    onRetry: _init,
                  ),
                  loading: () => const VerseShimmerList(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Read',
            ),
            NavigationDestination(
              icon: Icon(Icons.sticky_note_2_outlined),
              selectedIcon: Icon(Icons.sticky_note_2_rounded),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Settings',
            ),
            NavigationDestination(
              icon: Icon(Icons.family_restroom_outlined),
              selectedIcon: Icon(Icons.family_restroom_rounded),
              label: 'Family',
            ),
          ],
        ),
      ),
    );
  }

  String get _appBarTitle {
    return switch (_selectedTab) {
      0 => 'Home',
      2 => 'Notes',
      3 => 'Settings',
      4 => 'Family',
      _ => '',
    };
  }

  Widget _buildSelectedTab({
    required List<Verse> verses,
    required int lastIndex,
    required int noteCount,
    required int highlightCount,
  }) {
    return switch (_selectedTab) {
      0 => HomeDashboard(
          verses: verses,
          currentIndex: lastIndex,
          noteCount: noteCount,
          highlightCount: highlightCount,
          onSearch: () => _openSearch(verses),
          onContinueReading: () {
            setState(() => _selectedTab = 1);
          },
          onOpenNotes: () {
            setState(() => _selectedTab = 2);
          },
          onOpenFamily: () {
            setState(() => _selectedTab = 4);
          },
          onOpenVerse: (index) {
            ref.read(lastIndexProvider.notifier).state = index;
            setState(() => _selectedTab = 1);
            Future.delayed(const Duration(milliseconds: 80), () {
              ScrollControllerProvider.jumpTo(ref: ref, index: index);
            });
          },
        ),
      1 => BibleView(verses),
      2 => NotesScreen(verses: verses, showAppBar: false),
      3 => const SettingsScreen(showAppBar: false),
      4 => const FamilyScreen(showAppBar: false),
      _ => BibleView(verses),
    };
  }

  void _openSearch(List<Verse> verses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SearchScreen(verses);
        },
      ),
    );
  }
}
