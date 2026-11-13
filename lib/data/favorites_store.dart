import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorite teams, favorite matchups, and hidden teams locally.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore(this._prefs);

  static const _key = 'favorite_team_ids';
  static const _matchupKey = 'favorite_matchup_ids';
  static const _hiddenKey = 'hidden_team_ids';

  final SharedPreferences _prefs;

  late final Set<String> _ids =
      _prefs.getStringList(_key)?.toSet() ?? <String>{};

  late final Set<String> _matchups =
      _prefs.getStringList(_matchupKey)?.toSet() ?? <String>{};

  late Set<String> _hiddenIds =
      _prefs.getStringList(_hiddenKey)?.toSet() ?? <String>{};

  Set<String> get ids => Set.unmodifiable(_ids);

  Set<String> get matchupIds => Set.unmodifiable(_matchups);

  Set<String> get hiddenIds => Set.unmodifiable(_hiddenIds);

  bool isFavorite(String teamId) => _ids.contains(teamId);

  bool isHidden(String teamId) => _hiddenIds.contains(teamId);

  /// Update the UI only after the preference has been saved.
  Future<void> setHidden(String teamId, bool hidden) async {
    final next = {..._hiddenIds};

    if (hidden) {
      next.add(teamId);
    } else {
      next.remove(teamId);
    }

    final saved = await _prefs.setStringList(
      _hiddenKey,
      next.toList()..sort(),
    );

    if (!saved) {
      throw StateError('Could not save hidden teams');
    }

    _hiddenIds = next;
    notifyListeners();
  }

  /// Same two teams count as one matchup regardless of order.
  static String matchupKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }

  bool isFavoriteMatchup(String a, String b) =>
      _matchups.contains(matchupKey(a, b));

  Future<void> toggleMatchup(String a, String b) async {
    if (a == b) return;

    final key = matchupKey(a, b);

    if (!_matchups.remove(key)) {
      _matchups.add(key);
    }

    await _prefs.setStringList(
      _matchupKey,
      _matchups.toList()..sort(),
    );

    notifyListeners();
  }

  Future<void> toggle(String teamId) async {
    if (_ids.contains(teamId)) {
      _ids.remove(teamId);
    } else {
      _ids.add(teamId);
    }

    await _prefs.setStringList(
      _key,
      _ids.toList()..sort(),
    );

    notifyListeners();
  }

  static Future<FavoritesStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return FavoritesStore(prefs);
  }
}
