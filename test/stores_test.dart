import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statmyteam/data/favorites_store.dart';
import 'package:statmyteam/data/settings_store.dart';

/// In-memory SharedPreferences whose next [failures] writes report failure.
class FlakyPrefs implements SharedPreferences {
  FlakyPrefs({this.failures = 1 << 30});

  int failures;
  final Map<String, Object> _data = {};

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  String? getString(String key) => _data[key] as String?;

  Future<bool> _write(String key, Object value) async {
    if (failures > 0) {
      failures--;
      return false;
    }
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _write(key, value);

  @override
  Future<bool> setString(String key, String value) => _write(key, value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('FavoritesStore', () {
    test('toggle adds and removes a favorite and persists it', () async {
      final store = await FavoritesStore.open();
      var notified = 0;
      store.addListener(() => notified++);

      await store.toggle('aus');
      expect(store.isFavorite('aus'), isTrue);
      expect((await FavoritesStore.open()).ids, {'aus'});

      await store.toggle('aus');
      expect(store.isFavorite('aus'), isFalse);
      expect((await FavoritesStore.open()).ids, isEmpty);
      expect(notified, 2);
    });

    test('toggleMatchup is order-independent and persists', () async {
      final store = await FavoritesStore.open();

      await store.toggleMatchup('aus', 'por');
      expect(store.isFavoriteMatchup('por', 'aus'), isTrue);
      expect((await FavoritesStore.open()).matchupIds, {'aus|por'});

      await store.toggleMatchup('por', 'aus');
      expect(store.matchupIds, isEmpty);
    });

    test('a team cannot be matched against itself', () async {
      final store = await FavoritesStore.open();
      await store.toggleMatchup('aus', 'aus');
      expect(store.matchupIds, isEmpty);
    });

    test('rapid toggles apply in order instead of interleaving', () async {
      final store = await FavoritesStore.open();
      // Not awaited between calls, like a triple tap.
      await Future.wait([
        store.toggle('aus'),
        store.toggle('aus'),
        store.toggle('aus'),
      ]);

      expect(store.isFavorite('aus'), isTrue);
      expect((await FavoritesStore.open()).ids, {'aus'});
    });

    test(
      'a failed save throws and leaves state and listeners untouched',
      () async {
        final store = FavoritesStore(FlakyPrefs());
        var notified = 0;
        store.addListener(() => notified++);

        await expectLater(
          store.toggle('aus'),
          throwsA(isA<PreferenceSaveException>()),
        );
        await expectLater(
          store.toggleMatchup('aus', 'por'),
          throwsA(isA<PreferenceSaveException>()),
        );
        await expectLater(
          store.setHidden('aus', true),
          throwsA(isA<PreferenceSaveException>()),
        );

        expect(store.ids, isEmpty);
        expect(store.matchupIds, isEmpty);
        expect(store.hiddenIds, isEmpty);
        expect(notified, 0);
      },
    );

    test('a failed write does not block the next one', () async {
      final store = FavoritesStore(FlakyPrefs(failures: 1));

      final failed = store.toggle('aus');
      final next = store.toggle('por');
      await expectLater(failed, throwsA(isA<PreferenceSaveException>()));
      await next;

      expect(store.ids, {'por'});
    });
  });

  group('SettingsStore', () {
    test('defaults to system and persists a chosen mode', () async {
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsStore(prefs);
      expect(settings.themeMode, ThemeMode.system);

      await settings.setThemeMode(ThemeMode.dark);
      expect(settings.themeMode, ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');
      expect(SettingsStore(prefs).themeMode, ThemeMode.dark);
    });

    test('an unknown saved value falls back to system', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
      final settings = await SettingsStore.open();
      expect(settings.themeMode, ThemeMode.system);
    });

    test('a failed save restores the previous mode and throws', () async {
      final settings = SettingsStore(FlakyPrefs());
      final seen = <ThemeMode>[];
      settings.addListener(() => seen.add(settings.themeMode));

      await expectLater(
        settings.setThemeMode(ThemeMode.dark),
        throwsA(isA<PreferenceSaveException>()),
      );
      expect(settings.themeMode, ThemeMode.system);
      // Applied immediately, then rolled back.
      expect(seen, [ThemeMode.dark, ThemeMode.system]);
    });

    test('without preferences the mode still changes in memory', () async {
      final settings = SettingsStore();
      await settings.setThemeMode(ThemeMode.light);
      expect(settings.themeMode, ThemeMode.light);
    });
  });
}
