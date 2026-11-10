import 'package:flutter/widgets.dart';

import '../data/favorites_store.dart';

/// Exposes [FavoritesStore] to the widget tree.
class FavoritesScope extends InheritedNotifier<FavoritesStore> {
  const FavoritesScope({
    super.key,
    required FavoritesStore store,
    required super.child,
  }) : super(notifier: store);

  static FavoritesStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<FavoritesScope>();
    assert(scope != null, 'FavoritesScope not found in the widget tree');
    return scope!.notifier!;
  }
}
