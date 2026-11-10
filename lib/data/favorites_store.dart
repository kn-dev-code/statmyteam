import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorite team ids locally.
class FavoritesStore extends ChangeNotifier {
  FavoritesStore(this._prefs);

  static const _key = 'favorite_team_ids';

  final SharedPreferences _prefs;
  late final Set<String> _ids =
      _prefs.getStringList(_key)?.toSet() ?? <String>{};

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isFavorite(String teamId) => _ids.contains(teamId);

  Future<void> toggle(String teamId) async {
    if (_ids.contains(teamId)) {
      _ids.remove(teamId);
    } else {
      _ids.add(teamId);
    }
    await _prefs.setStringList(_key, _ids.toList()..sort());
    notifyListeners();
  }

  static Future<FavoritesStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return FavoritesStore(prefs);
  }
}
