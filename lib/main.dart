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
    const brandEspresso = Color(0xFF6E4F30);
    const brandEspressoDeep = Color(0xFF5E4226);
    const brandGold = Color(0xFFC59A41);
    const brandTerracotta = Color(0xFFB0613C);
    const lightCanvas = Color(0xFFEFE6D5);
    const lightPaper = Color(0xFFFBF6EC);
    const lightSunken = Color(0xFFF3E9D6);
    const lightBorder = Color(0xFFE4D9C4);
    const lightInk = Color(0xFF2A2420);
    const lightBody = Color(0xFF33302A);
    const lightMuted = Color(0xFF7C715F);
    const darkCanvas = Color(0xFF1F1A15);
    const darkSurface = Color(0xFF2A241D);
    const darkRaised = Color(0xFF342D24);
    const darkBorder = Color(0xFF3B332A);
    const darkInk = Color(0xFFF2E9DA);
    const darkMuted = Color(0xFFA99A82);

    final seed = switch (palette) {
      AppPalette.parchment => brandEspresso,
      AppPalette.forest => const Color(0xFF3F6F57),
      AppPalette.slate => const Color(0xFF586F7C),
      AppPalette.ocean => const Color(0xFF1D6F8A),
      AppPalette.plum => const Color(0xFF7B5268),
      AppPalette.ember => const Color(0xFF9A4F2D),
      AppPalette.graphite => const Color(0xFF52565A),
    };
    final background = switch ((palette, brightness)) {
      (AppPalette.parchment, Brightness.light) => lightCanvas,
      (AppPalette.forest, Brightness.light) => const Color(0xFFF5FAF6),
      (AppPalette.slate, Brightness.light) => const Color(0xFFF5F8FA),
      (AppPalette.ocean, Brightness.light) => const Color(0xFFF2FAFC),
      (AppPalette.plum, Brightness.light) => const Color(0xFFFCF6FA),
      (AppPalette.ember, Brightness.light) => const Color(0xFFFFF7F1),
      (AppPalette.graphite, Brightness.light) => const Color(0xFFF7F7F5),
      (AppPalette.parchment, Brightness.dark) => darkCanvas,
      (_, Brightness.dark) => const Color(0xFF111412),
    };

    final generatedScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final colorScheme = palette == AppPalette.parchment
        ? (brightness == Brightness.light
            ? const ColorScheme.light(
                primary: brandEspresso,
                onPrimary: lightPaper,
                primaryContainer: lightSunken,
                onPrimaryContainer: brandEspressoDeep,
                secondary: brandGold,
                onSecondary: Color(0xFF43301A),
                secondaryContainer: Color(0xFFE9CD8F),
                onSecondaryContainer: Color(0xFF43301A),
                tertiary: brandTerracotta,
                onTertiary: lightPaper,
                tertiaryContainer: Color(0xFFE7C4B2),
                onTertiaryContainer: Color(0xFF4A2417),
                surface: lightPaper,
                onSurface: lightInk,
                surfaceContainerHighest: lightSunken,
                onSurfaceVariant: lightMuted,
                outline: Color(0xFFB3A793),
                outlineVariant: lightBorder,
                error: Color(0xFF9B3D32),
                onError: lightPaper,
              )
            : const ColorScheme.dark(
                primary: Color(0xFFD6AE5C),
                onPrimary: Color(0xFF43301A),
                primaryContainer: darkRaised,
                onPrimaryContainer: darkInk,
                secondary: brandGold,
                onSecondary: Color(0xFF43301A),
                secondaryContainer: Color(0xFF4A4133),
                onSecondaryContainer: Color(0xFFE9CD8F),
                tertiary: Color(0xFFCC8E6A),
                onTertiary: Color(0xFF2A130C),
                tertiaryContainer: Color(0xFF4A2B20),
                onTertiaryContainer: Color(0xFFE7C4B2),
                surface: darkSurface,
                onSurface: darkInk,
                surfaceContainerHighest: darkRaised,
                onSurfaceVariant: darkMuted,
                outline: Color(0xFF6E6353),
                outlineVariant: darkBorder,
                error: Color(0xFFFFB4A9),
                onError: Color(0xFF5F150F),
              ))
        : generatedScheme;
    final baseTheme = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
    );
    final isParchment = palette == AppPalette.parchment;
    final textColor = isParchment
        ? (brightness == Brightness.light ? lightBody : darkInk)
        : colorScheme.onSurface;
    final displayColor = isParchment
        ? (brightness == Brightness.light ? lightInk : darkInk)
        : colorScheme.primary;
    final mutedColor = isParchment
        ? (brightness == Brightness.light ? lightMuted : darkMuted)
        : colorScheme.onSurfaceVariant;
    final sunkenColor = isParchment
        ? (brightness == Brightness.light ? lightSunken : darkRaised)
        : colorScheme.surfaceContainerHighest;
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
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: sunkenColor,
        selectedColor: colorScheme.primary,
        disabledColor: sunkenColor.withOpacity(0.62),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: TextStyle(color: mutedColor),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sunkenColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: mutedColor),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: sunkenColor,
          disabledForegroundColor: mutedColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mutedColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : mutedColor,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? colorScheme.primary : mutedColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
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
