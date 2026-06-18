import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'src/config/family_bible_config.dart';
import 'src/models/app_settings.dart';
import 'src/providers/annotation_provider.dart';
import 'src/providers/local_user_provider.dart';
import 'src/providers/settings_provider.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Mobile Ads SDK
  // await MobileAds.instance.initialize();
  // Request notification permissions and initialize notification service
  await NotificationService.requestPermissions();
  // Run the app with Riverpod ProviderScope
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppBootstrap();
  }
}

class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(settingsProvider.notifier).load();
      await ref.read(annotationProvider.notifier).load();
      await ref.read(localUserProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final localUserState = ref.watch(localUserProvider);

    return MaterialApp(
      title: FamilyBibleConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _buildTheme(settings.palette, Brightness.light),
      darkTheme: _buildTheme(settings.palette, Brightness.dark),
      home: localUserState.loading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(strokeCap: StrokeCap.round),
              ),
            )
          : localUserState.onboardingComplete
              ? const HomeScreen()
              : const OnboardingScreen(),
    );
  }

  ThemeData _buildTheme(AppPalette palette, Brightness brightness) {
    final seed = switch (palette) {
      AppPalette.parchment => const Color(0xFF8B5E34),
      AppPalette.forest => const Color(0xFF3F6F57),
      AppPalette.slate => const Color(0xFF586F7C),
      AppPalette.ocean => const Color(0xFF1D6F8A),
      AppPalette.plum => const Color(0xFF7B5268),
      AppPalette.ember => const Color(0xFF9A4F2D),
      AppPalette.graphite => const Color(0xFF52565A),
    };
    final background = switch ((palette, brightness)) {
      (AppPalette.parchment, Brightness.light) => const Color(0xFFFBF8F1),
      (AppPalette.forest, Brightness.light) => const Color(0xFFF5FAF6),
      (AppPalette.slate, Brightness.light) => const Color(0xFFF5F8FA),
      (AppPalette.ocean, Brightness.light) => const Color(0xFFF2FAFC),
      (AppPalette.plum, Brightness.light) => const Color(0xFFFCF6FA),
      (AppPalette.ember, Brightness.light) => const Color(0xFFFFF7F1),
      (AppPalette.graphite, Brightness.light) => const Color(0xFFF7F7F5),
      (_, Brightness.dark) => const Color(0xFF111412),
    };

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      scaffoldBackgroundColor: background,
      fontFamily: 'serif',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
