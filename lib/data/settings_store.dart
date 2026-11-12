import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App preferences persisted locally. Currently just the theme mode.
class SettingsStore extends ChangeNotifier {
  /// [prefs] is optional so tests can use an in-memory store.
  SettingsStore([this._prefs]);

  static const _themeKey = 'theme_mode';

  final SharedPreferences? _prefs;

  late ThemeMode _themeMode = ThemeMode.values.firstWhere(
    (m) => m.name == _prefs?.getString(_themeKey),
    orElse: () => ThemeMode.system,
  );

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_themeKey, mode.name);
  }

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());
}
