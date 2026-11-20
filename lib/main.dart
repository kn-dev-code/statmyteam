import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/favorites_store.dart';
import 'data/settings_store.dart';
import 'data/stats_repository.dart';
import 'l10n/l10n.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'state/favorites_scope.dart';
import 'state/settings_scope.dart';
import 'state/stats_scope.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorHandlers();
  runApp(const BootstrapApp());
}

/// Receives every uncaught error. [source] says where it came from.
typedef ErrorReporter = void Function(
  Object error,
  StackTrace? stack,
  String source,
);

/// The default [ErrorReporter]: writes to the developer log. This is the one
/// place to plug in a crash-reporting service (Crashlytics, Sentry, ...).
void logError(Object error, StackTrace? stack, String source) {
  developer.log(
    'Uncaught error',
    name: source,
    error: error,
    stackTrace: stack,
  );
}

/// Routes uncaught framework and async errors to [reporter].
///
/// In release builds async errors are marked handled and failed widgets
/// show a calm placeholder instead of the grey error box. In debug and
/// profile builds errors still surface normally (red screen, console) so
/// they are not missed during development.
void installErrorHandlers({
  ErrorReporter reporter = logError,
  bool releaseMode = kReleaseMode,
}) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    reporter(details.exception, details.stack, 'FlutterError');
    previous?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    reporter(error, stack, 'PlatformDispatcher');
    // false lets the engine print it too (debug); true swallows it (release).
    return releaseMode;
  };

  if (releaseMode) {
    ErrorWidget.builder = (_) => const ErrorPlaceholder();
  }
}

/// Shown in place of a widget that failed to build (release builds only).
class ErrorPlaceholder extends StatelessWidget {
  const ErrorPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // This can be built outside the app's Localizations, so fall back to
    // English rather than throwing again.
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 28),
              const SizedBox(height: 8),
              Text(
                l10n?.errorWidgetTitle ?? 'Something went wrong',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                l10n?.errorWidgetBody ??
                    'This part of the screen could not be shown.',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Localization setup shared by every [MaterialApp] in the app.
const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Loads stores and league data, showing a loading screen, then the app; on
/// failure shows a short error with Retry.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({
    super.key,
    this.loadRepository = StatsRepository.live,
    this.openFavorites = FavoritesStore.open,
    this.openSettings = SettingsStore.open,
  });

  /// Source of league data; tests inject a fake.
  final Future<StatsRepository> Function() loadRepository;

  /// Local stores; tests inject fakes (for example one that fails).
  final Future<FavoritesStore> Function() openFavorites;
  final Future<SettingsStore> Function() openSettings;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

typedef _Boot = ({
  StatsRepository repo,
  FavoritesStore favorites,
  SettingsStore settings,
});

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<_Boot> _boot = _load();
  StatsRepository? _repo;
  FavoritesStore? _favorites;
  SettingsStore? _settings;

  /// Bumped on every (re)load so a slow repository from an abandoned
  /// attempt can be recognised and closed.
  int _attempt = 0;

  Future<_Boot> _load() async {
    final attempt = ++_attempt;
    // Release everything the previous attempt created before starting over.
    _release();

    // Keep each resource as soon as it exists, even if another one fails,
    // so it is always released on retry or dispose. A result that arrives
    // after a newer attempt started (or after dispose) is released at once.
    Future<T> track<T extends Object>(
      Future<T> Function() open,
      void Function(T value) keep,
      void Function(T value) release,
    ) =>
        // Future.sync turns a synchronous throw into a failed future.
        Future.sync(open).then((value) {
          if (attempt == _attempt && mounted) {
            keep(value);
          } else {
            release(value);
          }
          return value;
        });

    final favorites = track(
      widget.openFavorites,
      (v) => _favorites = v,
      (v) => v.dispose(),
    );
    final settings = track(
      widget.openSettings,
      (v) => _settings = v,
      (v) => v.dispose(),
    );
    final repo = track(
      widget.loadRepository,
      (v) => _repo = v,
      (v) => v.close(),
    );

    try {
      // eagerError: a fast failure (e.g. local storage) shows the error
      // screen right away instead of waiting for the slow league load.
      await Future.wait<Object>([favorites, settings, repo], eagerError: true);
    } catch (error, stack) {
      developer.log(
        'App startup failed',
        name: 'Bootstrap',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
    return (
      repo: await repo,
      favorites: await favorites,
      settings: await settings,
    );
  }

  /// Closes the repository and disposes the stores this widget created.
  /// Only called when nothing uses them any more: on Retry (shown only on
  /// the error screen) and on dispose (after the app below is torn down).
  void _release() {
    _repo?.close();
    _favorites?.dispose();
    _settings?.dispose();
    _repo = null;
    _favorites = null;
    _settings = null;
  }

  @override
  void dispose() {
    _attempt++; // Anything still loading is released when it arrives.
    _release();
    super.dispose();
  }

  Widget _shell(Widget home) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => context.l10n.appTitle,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: _localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Boot>(
      future: _boot,
      builder: (context, snapshot) {
        // A retried future keeps the previous error until it settles, so
        // check the state first: show the spinner while (re)loading.
        if (snapshot.connectionState != ConnectionState.done) {
          return _shell(const _BootLoading());
        }

        if (snapshot.hasError) {
          return _shell(
            _BootError(
              onRetry: () => setState(() {
                _boot = _load();
              }),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) return _shell(const _BootLoading());

        return StatMyTeamApp(
          repository: data.repo,
          favorites: data.favorites,
          settings: data.settings,
        );
      },
    );
  }
}

class _BootLoading extends StatelessWidget {
  const _BootLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.loadingLiveData),
          ],
        ),
      ),
    );
  }
}

/// Startup failure. Shows a short explanation only; the technical detail
/// was logged in [_BootstrapAppState._load].
class _BootError extends StatelessWidget {
  const _BootError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 16),
              Text(
                l10n.bootFailedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(l10n.bootFailedBody, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
    );
  }
}

class StatMyTeamApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SettingsScope(
      store: settings,
      child: FavoritesScope(
        store: favorites,
        child: StatsScope(
          repository: repository,
          // Only MaterialApp depends on the theme mode; it follows the OS
          // brightness itself when the mode is "system", and widgets read
          // colors through Theme, so nothing else needs rebuilding by hand.
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => MaterialApp(
              onGenerateTitle: (context) => context.l10n.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: settings.themeMode,
              localizationsDelegates: _localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: showLogin ? const LoginScreen() : const MainMenuScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
