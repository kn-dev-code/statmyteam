import 'package:flutter/material.dart';

/// One complete set of UI colors, carried on [ThemeData] as an extension so
/// widgets read it through `context.colors` and rebuild only when it changes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
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

  bool get isDark => brightness == Brightness.dark;

  /// Light mode palette.
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

  /// Dark mode palette.
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

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? border,
    Color? muted,
    Color? text,
    Color? ink,
    Color? onInk,
    Color? accent,
    Color? onAccent,
    Color? gold,
    Color? danger,
    Color? pending,
    Color? nav,
    Color? navItem,
    Color? navSelected,
    Color? navSelectedFg,
    Color? shadow,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      text: text ?? this.text,
      ink: ink ?? this.ink,
      onInk: onInk ?? this.onInk,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      gold: gold ?? this.gold,
      danger: danger ?? this.danger,
      pending: pending ?? this.pending,
      nav: nav ?? this.nav,
      navItem: navItem ?? this.navItem,
      navSelected: navSelected ?? this.navSelected,
      navSelectedFg: navSelectedFg ?? this.navSelectedFg,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      border: c(border, other.border),
      muted: c(muted, other.muted),
      text: c(text, other.text),
      ink: c(ink, other.ink),
      onInk: c(onInk, other.onInk),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      gold: c(gold, other.gold),
      danger: c(danger, other.danger),
      pending: c(pending, other.pending),
      nav: c(nav, other.nav),
      navItem: c(navItem, other.navItem),
      navSelected: c(navSelected, other.navSelected),
      navSelectedFg: c(navSelectedFg, other.navSelectedFg),
      shadow: c(shadow, other.shadow),
    );
  }
}

/// `context.colors` reads the active [AppPalette] from the theme.
extension AppColorsContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// Brand colors that do not change between light and dark mode.
abstract final class AppColors {
  static const orange = Color(0xFFF8A41C);
  static const black = Color(0xFF121212);

  static const heroStart = Color(0xFF0E7A42);
  static const heroEnd = Color(0xFF3FA14A);
}

/// Application theme configuration.
abstract final class AppTheme {
  static const double radius = 28;

  static final ThemeData _light = build(AppPalette.light);
  static final ThemeData _dark = build(AppPalette.dark);

  /// The light theme (built once and reused).
  static ThemeData light() => _light;

  /// The dark theme (built once and reused).
  static ThemeData dark() => _dark;

  /// Builds a full theme from [p].
  static ThemeData build(AppPalette p) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: p.brightness,
        ).copyWith(
          primary: p.ink,
          onPrimary: p.onInk,
          secondary: AppColors.orange,
          onSecondary: AppColors.black,
          surface: p.surface,
          onSurface: p.text,
          surfaceContainerHighest: p.surfaceHigh,
          error: p.danger,
          outline: p.border,
          outlineVariant: p.border,
        );

    const stadium = StadiumBorder();
    const bold = TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700);

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      extensions: [p],
      scaffoldBackgroundColor: p.background,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme().apply(
        bodyColor: p.text,
        displayColor: p.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.onInk,
          disabledBackgroundColor: p.ink.withValues(alpha: 0.18),
          disabledForegroundColor: p.ink.withValues(alpha: 0.45),
          minimumSize: const Size.fromHeight(56),
          shape: stadium,
          textStyle: bold.copyWith(fontSize: 17),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          backgroundColor: p.surface,
          minimumSize: const Size.fromHeight(52),
          shape: stadium,
          side: BorderSide(color: p.border),
          textStyle: bold.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.ink, textStyle: bold),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(stadium),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? p.ink : p.surfaceHigh,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? p.onInk : p.text,
          ),
          textStyle: const WidgetStatePropertyAll(bold),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: stadium,
        side: BorderSide(color: p.border),
        backgroundColor: p.surface,
        selectedColor: p.ink,
        showCheckmark: false,
        secondarySelectedColor: p.ink,
        labelStyle: bold.copyWith(color: p.text),
        secondaryLabelStyle: bold.copyWith(color: p.onInk),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: p.muted, textColor: p.text),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.onInk),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: p.border, space: 1),
      dividerColor: p.border,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.ink),
    );
  }
}
