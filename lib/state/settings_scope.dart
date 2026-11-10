import 'package:flutter/widgets.dart';

import '../data/settings_store.dart';

/// Exposes [SettingsStore] to the widget tree.
class SettingsScope extends InheritedNotifier<SettingsStore> {
  const SettingsScope({
    super.key,
    required SettingsStore store,
    required super.child,
  }) : super(notifier: store);

  static SettingsStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope not found in the widget tree');
    return scope!.notifier!;
  }
}
