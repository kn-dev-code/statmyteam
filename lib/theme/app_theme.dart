import 'package:flutter/material.dart';

/// One complete set of UI colors. [AppColors] reads from whichever
/// palette is active, so every screen switches with the app's theme mode.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.muted,
    required this.text,
    required this.ink,
    required this.onInk,
    required this.accent,
    required this.onAccent,
    required this.gold,
    required this.danger,
    required this.pending,
    required this.nav,
    required this.navItem,
    required this.navSelected,
    required this.navSelectedFg,
    required this.shadow,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color muted;
  final Color text;
  final Color ink;
  final Color onInk;
  final Color accent;
  final Color onAccent;
  final Color gold;
  final Color danger;
  final Color pending;
  final Color nav;
  final Color navItem;
  final Color navSelected;
  final Color navSelectedFg;
  final Color shadow;

  /// Warm grey canvas, white cards, black pill actions.
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFE7E4DD),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF1EFEB),
    border: Color(0xFFE2DFD8),
    muted: Color(0xFF9B988F),
    text: Color(0xFF121212),
    ink: Color(0xFF121212),
    onInk: Color(0xFFFFFFFF),
    accent: Color(0xFF0D6B3C),
    onAccent: Color(0xFFFFFFFF),
    gold: Color(0xFFD27A00),
    danger: Color(0xFFD7261E),
    pending: Color(0xFF2F6FD6),
    nav: Color(0xFF121212),
    navItem: Color(0xFF2B2B2B),
    navSelected: Color(0xFFFFFFFF),
    navSelectedFg: Color(0xFF121212),
    shadow: Color(0x1F000000),
  );

  /// Near-black canvas, charcoal cards, light pill actions. Greens and
  /// reds are brightened so values stay legible on dark surfaces.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0D0E10),
    surface: Color(0xFF1A1C1F),
    surfaceHigh: Color(0xFF26292D),
    border: Color(0xFF2F3237),
    muted: Color(0xFF8D9198),
    text: Color(0xFFF2F1EE),
    ink: Color(0xFFF2F1EE),
    onInk: Color(0xFF121212),
    accent: Color(0xFF3DD68C),
    onAccent: Color(0xFF062414),
    gold: Color(0xFFF5B342),
    danger: Color(0xFFFF5B52),
    pending: Color(0xFF6EA8FF),
    nav: Color(0xFF26292D),
    navItem: Color(0xFF34383D),
    navSelected: Color(0xFFF2F1EE),
    navSelectedFg: Color(0xFF121212),
    shadow: Color(0x66000000),
  );
}

/// Card-first palette: canvas, cards, pill actions, an orange action
/// accent, and green for "better" values. Values come from the active
/// [AppPalette]; see [AppColors.use].
class AppColors {
  static AppPalette _p = AppPalette.light;

  static AppPalette get palette => _p;
  static Brightness get brightness => _p.brightness;
  static bool get isDark => _p.brightness == Brightness.dark;

  /// Switches the active palette. Callers must rebuild the tree afterwards.
  static void use(Brightness brightness) =>
      _p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;

  /// Canvas behind every card.
  static Color get background => _p.background;

  /// Cards and header pills.
  static Color get surface => _p.surface;

  /// Soft pills inside cards (metric chips, labels).
  static Color get surfaceHigh => _p.surfaceHigh;

  static Color get border => _p.border;
  static Color get muted => _p.muted;
  static Color get text => _p.text;

  /// Primary pill buttons and selected chips (black in light, off-white
  /// in dark), with [onInk] for their content.
  static Color get ink => _p.ink;
  static Color get onInk => _p.onInk;

  /// "Better" / positive values and wins, with [onAccent] for content.
  static Color get accent => _p.accent;
  static Color get onAccent => _p.onAccent;

  static Color get gold => _p.gold;
  static Color get danger => _p.danger;
  static Color get pending => _p.pending;

  /// Floating nav bar.
  static Color get nav => _p.nav;
  static Color get navItem => _p.navItem;
  static Color get navSelected => _p.navSelected;
  static Color get navSelectedFg => _p.navSelectedFg;

  static Color get shadow => _p.shadow;

  /// Bright action color for the round "+" button and hero pills. Same in
  /// both modes.
  static const orange = Color(0xFFF8A41C);

  /// Fixed near-black for text on [orange] and on white hero pills.
  static const black = Color(0xFF121212);

  /// Hero banner gradient (same in both modes).
  static const heroStart = Color(0xFF0E7A42);
  static const heroEnd = Color(0xFF3FA14A);
}

class AppTheme {
  static const double radius = 28;

  /// Theme for the active [AppColors] palette.
  static ThemeData current() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: AppColors.brightness,
        ).copyWith(
          primary: AppColors.ink,
          onPrimary: AppColors.onInk,
          secondary: AppColors.orange,
          onSecondary: AppColors.black,
          surface: AppColors.surface,
          onSurface: AppColors.text,
          surfaceContainerHighest: AppColors.surfaceHigh,
          error: AppColors.danger,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
        );

    const stadium = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: AppColors.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.onInk,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.18),
          disabledForegroundColor: AppColors.ink.withValues(alpha: 0.45),
          minimumSize: const Size.fromHeight(56),
          shape: stadium,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(52),
          shape: stadium,
          side: BorderSide(color: AppColors.border),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(stadium),
          side: WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.surfaceHigh,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.onInk
                : AppColors.text,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          ),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: stadium,
        side: BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.ink,
        showCheckmark: false,
        secondarySelectedColor: AppColors.ink,
        // ChoiceChip uses labelStyle when unselected, secondaryLabelStyle
        // when selected.
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          color: AppColors.onInk,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.ink, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.muted,
        textColor: AppColors.text,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: AppColors.onInk),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, space: 1),
      dividerColor: AppColors.border,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.ink),
    );
  }

  static ThemeData light() {
    AppColors.use(Brightness.light);
    return current();
  }

  static ThemeData dark() {
    AppColors.use(Brightness.dark);
    return current();
  }
}
