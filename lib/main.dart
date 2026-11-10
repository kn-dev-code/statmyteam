import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'data/favorites_store.dart';
import 'data/settings_store.dart';
import 'data/stats_repository.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'state/favorites_scope.dart';
import 'state/settings_scope.dart';
import 'state/stats_scope.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RendererBinding.instance.ensureSemantics();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

typedef _Boot = ({
  StatsRepository repo,
  FavoritesStore favorites,
  SettingsStore settings,
});

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<_Boot> _boot = _load();

  Future<_Boot> _load() async {
    final favorites = FavoritesStore.open();
    final settings = SettingsStore.open();
    final repo = StatsRepository.liveFootball();
    return (
      repo: await repo,
      favorites: await favorites,
      settings: await settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Boot>(
      future: _boot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Saved preference is not loaded yet; follow the system.
          AppColors.use(
            WidgetsBinding.instance.platformDispatcher.platformBrightness,
          );
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.current(),
            home: const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading NFL data…'),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return StatMyTeamApp(
          repository: data.repo,
          favorites: data.favorites,
          settings: data.settings,
        );
      },
    );
  }
}

class StatMyTeamApp extends StatefulWidget {
  StatMyTeamApp({
    super.key,
    required this.repository,
    required this.favorites,
    SettingsStore? settings,
    this.showLogin = true,
  }) : settings = settings ?? SettingsStore();

  final StatsRepository repository;
  final FavoritesStore favorites;
  final SettingsStore settings;

  /// Widget tests skip auth and land on the main menu.
  final bool showLogin;

  @override
  State<StatMyTeamApp> createState() => _StatMyTeamAppState();
}

/// Resolves light/dark from the saved mode and the system setting, swaps
/// the [AppColors] palette, and rebuilds the tree in place so open routes
/// keep their state.
class _StatMyTeamAppState extends State<StatMyTeamApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_applyBrightness);
    AppColors.use(_resolveBrightness());
  }

  @override
  void dispose() {
    widget.settings.removeListener(_applyBrightness);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _applyBrightness();

  Brightness _resolveBrightness() => switch (widget.settings.themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };

  void _applyBrightness() {
    final next = _resolveBrightness();
    if (next == AppColors.brightness) return;
    AppColors.use(next);
    // Many widgets read AppColors directly rather than through Theme, so
    // mark every element dirty; state (including the route stack) is kept.
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      store: widget.settings,
      child: FavoritesScope(
        store: widget.favorites,
        child: StatsScope(
          repository: widget.repository,
          child: MaterialApp(
            title: 'StatMyTeam',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.current(),
            // Palette-driven widgets switch instantly; match that.
            themeAnimationDuration: Duration.zero,
            home: widget.showLogin
                ? const LoginScreen()
                : const MainMenuScreen(),
          ),
        ),
      ),
    );
  }
}
