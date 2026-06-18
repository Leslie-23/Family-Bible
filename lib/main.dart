import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'src/config/family_bible_config.dart';
import 'src/models/app_settings.dart';
import 'src/providers/annotation_provider.dart';
import 'src/providers/local_user_provider.dart';
import 'src/providers/settings_provider.dart';
import 'src/screens/family_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(settingsProvider.notifier).load();
      await ref.read(annotationProvider.notifier).load();
      await ref.read(localUserProvider.notifier).load();
    });
    _listenForInviteLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final localUserState = ref.watch(localUserProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
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

  void _listenForInviteLinks() {
    final links = AppLinks();
    _linkSubscription = links.uriLinkStream.listen(_openInviteLink);
    links.getInitialLink().then((uri) {
      if (uri != null) _openInviteLink(uri);
    });
  }

  void _openInviteLink(Uri uri) {
    if (uri.scheme != 'familybible' || uri.host != 'invite') return;
    final code = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    if (code == null || code.isEmpty) return;

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => FamilyScreen(initialInviteCode: code),
      ),
    );
  }

  ThemeData _buildTheme(AppPalette palette, Brightness brightness) {
    final seed = switch (palette) {
      AppPalette.parchment => const Color(0xFF6E4F30),
      AppPalette.forest => const Color(0xFF3F6F57),
      AppPalette.slate => const Color(0xFF586F7C),
      AppPalette.ocean => const Color(0xFF1D6F8A),
      AppPalette.plum => const Color(0xFF7B5268),
      AppPalette.ember => const Color(0xFF9A4F2D),
      AppPalette.graphite => const Color(0xFF52565A),
    };
    final background = switch ((palette, brightness)) {
      (AppPalette.parchment, Brightness.light) => const Color(0xFFF5F0E8),
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
    final baseTheme = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
    );
    final textColor = brightness == Brightness.light
        ? const Color(0xFF3B2F2F)
        : colorScheme.onSurface;
    final displayColor = brightness == Brightness.light
        ? const Color(0xFF5C4033)
        : colorScheme.primary;
    final textTheme = _buildTextTheme(
      baseTheme.textTheme,
      textColor: textColor,
      displayColor: displayColor,
    );

    return baseTheme.copyWith(
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      scaffoldBackgroundColor: background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
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

  TextTheme _buildTextTheme(
    TextTheme base, {
    required Color textColor,
    required Color displayColor,
  }) {
    TextStyle heading(TextStyle? style) {
      return (style ?? const TextStyle()).copyWith(
        fontFamily: 'Lora',
        color: displayColor,
        letterSpacing: 0,
      );
    }

    TextStyle body(TextStyle? style) {
      return (style ?? const TextStyle()).copyWith(
        fontFamily: 'SourceSerif4',
        color: textColor,
        letterSpacing: 0,
      );
    }

    return base.copyWith(
      displayLarge: heading(base.displayLarge),
      displayMedium: heading(base.displayMedium),
      displaySmall: heading(base.displaySmall),
      headlineLarge: heading(base.headlineLarge),
      headlineMedium: heading(base.headlineMedium),
      headlineSmall: heading(base.headlineSmall),
      titleLarge: heading(base.titleLarge),
      titleMedium: heading(base.titleMedium),
      titleSmall: heading(base.titleSmall),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      labelLarge: body(base.labelLarge),
      labelMedium: body(base.labelMedium),
      labelSmall: body(base.labelSmall),
    );
  }
}
