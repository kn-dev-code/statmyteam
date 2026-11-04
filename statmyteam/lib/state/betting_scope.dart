import 'package:flutter/widgets.dart';

import 'betting_controller.dart';

class BettingScope extends InheritedNotifier<BettingController> {
  const BettingScope({
    super.key,
    required BettingController controller,
    required super.child,
  }) : super(notifier: controller);

  static BettingController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BettingScope>();
    assert(scope != null, 'BettingScope not found in the widget tree');
    return scope!.notifier!;
  }
}
