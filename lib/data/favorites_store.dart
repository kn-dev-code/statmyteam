import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown when a preference could not be written to local storage. The
/// in-memory state is left unchanged, so the UI still matches what is saved.
class PreferenceSaveException implements Exception {
  const PreferenceSaveException(this.key);

  final String key;

  @override
  String toString() => 'PreferenceSaveException: could not save "$key"';
}

/// Persists favorite teams, favorite matchups, and hidden teams locally.
///
/// Every change follows the same pattern: copy the set, write the copy,
/// and only commit + notify once the write succeeded. Writes run one at a
/// time, so rapid taps apply in order instead of interleaving.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore(this._prefs);

  static const _key = 'favorite_team_ids';
  static const _matchupKey = 'favorite_matchup_ids';
  static const _hiddenKey = 'hidden_team_ids';

  final SharedPreferences _prefs;

  late Set<String> _ids = _prefs.getStringList(_key)?.toSet() ?? <String>{};

  late Set<String> _matchups =
      _prefs.getStringList(_matchupKey)?.toSet() ?? <String>{};

  late Set<String> _hiddenIds =
      _prefs.getStringList(_hiddenKey)?.toSet() ?? <String>{};

  Future<void> _pending = Future.value();

  Set<String> get ids => Set.unmodifiable(_ids);

  Set<String> get matchupIds => Set.unmodifiable(_matchups);

  Set<String> get hiddenIds => Set.unmodifiable(_hiddenIds);

  bool isFavorite(String teamId) => _ids.contains(teamId);

  bool isHidden(String teamId) => _hiddenIds.contains(teamId);

  /// Same two teams count as one matchup regardless of order.
  static String matchupKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }

  bool isFavoriteMatchup(String a, String b) =>
      _matchups.contains(matchupKey(a, b));

  /// Hides or restores [teamId]. Throws [PreferenceSaveException] if the
  /// change could not be saved.
  Future<void> setHidden(String teamId, bool hidden) => _update(
    _hiddenKey,
    () => _hiddenIds,
    (next) => _hiddenIds = next,
    (set) => hidden ? set.add(teamId) : set.remove(teamId),
  );

  /// Saves or un-saves the matchup between [a] and [b]. Throws
  /// [PreferenceSaveException] if the change could not be saved.
  Future<void> toggleMatchup(String a, String b) {
    if (a == b) return Future.value();
    final key = matchupKey(a, b);
    return _update(
      _matchupKey,
      () => _matchups,
      (next) => _matchups = next,
      (set) => set.remove(key) || set.add(key),
    );
  }

  /// Adds or removes [teamId] from favorites. Throws
  /// [PreferenceSaveException] if the change could not be saved.
  Future<void> toggle(String teamId) => _update(
    _key,
    () => _ids,
    (next) => _ids = next,
    (set) => set.remove(teamId) || set.add(teamId),
  );

  /// Runs one copy → save → commit → notify cycle after any pending one.
  Future<void> _update(
    String key,
    Set<String> Function() read,
    void Function(Set<String> next) commit,
    void Function(Set<String> set) change,
  ) {
    final result = _pending.then((_) async {
      final next = {...read()};
      change(next);
      // Saved in insertion order (oldest first), so lists read the same
      // after a restart as they did when the user built them.
      final saved = await _prefs.setStringList(key, next.toList());
      if (!saved) throw PreferenceSaveException(key);
      commit(next);
      notifyListeners();
    });
    // Keep the queue alive after a failure; the caller still sees the error.
    _pending = result.catchError((Object _) {});
    return result;
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

  static Future<FavoritesStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return FavoritesStore(prefs);
  }
}
