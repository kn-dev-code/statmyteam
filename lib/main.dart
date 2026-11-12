import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'data/favorites_store.dart';
import 'data/stats_repository.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'state/favorites_scope.dart';
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

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<({StatsRepository repo, FavoritesStore favorites})> _boot =
      _load();

  Future<({StatsRepository repo, FavoritesStore favorites})> _load() async {
    final favorites = FavoritesStore.open();
    final repo = StatsRepository.liveFootball();
    return (repo: await repo, favorites: await favorites);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({StatsRepository repo, FavoritesStore favorites})>(
      future: _boot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
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
        );
      },
    );
  }
}

class StatMyTeamApp extends StatefulWidget {
  const StatMyTeamApp({
    super.key,
    required this.repository,
    required this.favorites,
    this.showLogin = true,
  });

  final StatsRepository repository;
  final FavoritesStore favorites;

  /// Widget tests skip auth and land on the main menu.
  final bool showLogin;

@override
State<StatMyTeamApp> createState() => _StatMyTeamAppState();
}

class _StatMyTeamAppState extends State<StatMyTeamApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
  setState(() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  });

  debugPrint('Theme changed to: $_themeMode');
}

  @override
  Widget build(BuildContext context) {
    return FavoritesScope(
      store: widget.favorites,
      child: StatsScope(
        repository: widget.repository,
        child: MaterialApp(
          title: 'StatMyTeam',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
darkTheme: AppTheme.dark().copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          themeMode: _themeMode,
          home: widget.showLogin
    ? LoginScreen(
        onToggleTheme: toggleTheme,
      )
    : MainMenuScreen(
        onToggleTheme: toggleTheme,
      ),
        ),
      ),
    );
  }
}
