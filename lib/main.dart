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
            theme: AppTheme.dark(),
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

class StatMyTeamApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FavoritesScope(
      store: favorites,
      child: StatsScope(
        repository: repository,
        child: MaterialApp(
          title: 'StatMyTeam',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark().copyWith(
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
          home: showLogin ? const LoginScreen() : const MainMenuScreen(),
        ),
      ),
    );
  }
}
