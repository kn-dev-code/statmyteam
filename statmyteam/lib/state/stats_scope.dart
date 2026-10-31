import 'package:flutter/widgets.dart';

import '../data/stats_repository.dart';

/// Makes the [StatsRepository] available to the stats screens.
class StatsScope extends InheritedWidget {
  const StatsScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final StatsRepository repository;

  static StatsRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StatsScope>();
    assert(scope != null, 'StatsScope not found in the widget tree');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(StatsScope oldWidget) =>
      repository != oldWidget.repository;
}
