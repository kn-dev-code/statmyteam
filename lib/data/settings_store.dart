import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_store.dart' show PreferenceSaveException;

/// App preferences persisted locally. Currently just the theme mode.
class SettingsStore extends ChangeNotifier {
  /// [prefs] is optional so tests can use an in-memory store.
  SettingsStore([this._prefs]);

  static const _themeKey = 'theme_mode';

  final SharedPreferences? _prefs;

  /// The last mode known to be on disk; failed saves roll back to this,
  /// not to whatever was on screen when they started.
  late ThemeMode _persisted = ThemeMode.values.firstWhere(
    (m) => m.name == _prefs?.getString(_themeKey),
    orElse: () => ThemeMode.system,
  );

  // Initialized from [_persisted] on first read, which happens before any
  // change (setThemeMode compares against it first).
  late ThemeMode _themeMode = _persisted;

  ThemeMode get themeMode => _themeMode;

  /// Applies [mode] right away so the switch feels instant, then saves it.
  /// If the save fails the last saved mode is restored (unless the user has
  /// already picked another one) and a [PreferenceSaveException] is thrown.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = _prefs;
    if (prefs == null) {
      _persisted = mode;
      return;
    }
    var saved = false;
    try {
      saved = await prefs.setString(_themeKey, mode.name);
    } finally {
      if (saved) {
        _persisted = mode;
      } else if (_themeMode == mode) {
        _themeMode = _persisted;
        notifyListeners();
      }
    }
    if (!saved) throw const PreferenceSaveException(_themeKey);
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// A save can finish after the app is torn down; skip listeners then.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());
}
