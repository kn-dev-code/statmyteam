import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Runs a preference write such as toggling a favorite, and tells the user
/// with a SnackBar if it fails (the store keeps its previous state).
/// Returns whether the write succeeded. Only [Exception]s are handled;
/// programming errors still propagate.
Future<bool> saveWithFeedback(
  BuildContext context,
  Future<void> Function() save, {
  String? failureMessage,
}) async {
  // Read everything from context up front: it may be unmounted after await.
  final messenger = ScaffoldMessenger.of(context);
  final message = failureMessage ?? context.l10n.saveFailed;
  try {
    await save();
    return true;
  } on Exception catch (error, stack) {
    developer.log(
      'Preference save failed',
      name: 'Preferences',
      error: error,
      stackTrace: stack,
    );
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return false;
  }
}

/// Pill-style top bar: a title (or back + title) pill on the left, and an
/// optional info pill plus round action buttons on the right.
class PillAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PillAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.info,
    this.actions = const [],
    this.showBack,
  });

  /// Plain title text shown in the left pill.
  final String? title;

  /// Custom left-pill content, e.g. the app wordmark.
  final Widget? titleWidget;

  /// Right-hand pill content, e.g. a context label plus an orange action.
  final Widget? info;

  /// Round white buttons after the info pill.
  final List<Widget> actions;

  /// Defaults to whether the route can pop.
  final bool? showBack;

  static const double height = 76;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? Navigator.of(context).canPop();

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Flexible(
                    child: _Pill(
                      padding: EdgeInsets.only(
                        left: canPop ? 4 : 20,
                        right: 20,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canPop)
                            IconButton(
                              tooltip: context.l10n.back,
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.chevron_left, size: 28),
                            ),
                          Flexible(
                            child:
                                titleWidget ??
                                Text(
                                  title ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (info != null) ...[
                    _Pill(
                      padding: const EdgeInsets.only(left: 18, right: 4),
                      child: info!,
                    ),
                    if (actions.isNotEmpty) const SizedBox(width: 8),
                  ],
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: padding,
      decoration: ShapeDecoration(
        color: context.colors.surface,
        shape: const StadiumBorder(),
      ),
      child: Align(widthFactor: 1, child: child),
    );
  }
}

/// White (or orange) circular icon button used in headers and cards.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 56,
    this.color,
    this.iconColor,
    this.outlined = false,
  });

  /// Orange filled variant, like the "+" action in the header pill.
  const RoundIconButton.accent({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 46,
  }) : color = AppColors.orange,
       iconColor = Colors.white,
       outlined = false;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  /// Defaults to [context.colors.surface].
  final Color? color;

  /// Defaults to [context.colors.ink].
  final Color? iconColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: size * 0.46),
      style: IconButton.styleFrom(
        backgroundColor: color ?? context.colors.surface,
        foregroundColor: iconColor ?? context.colors.ink,
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        shape: CircleBorder(
          side: outlined
              ? BorderSide(color: context.colors.border)
              : BorderSide.none,
        ),
      ),
    );
  }
}

/// One destination in [FloatingNavBar].
class FloatingNavItem {
  const FloatingNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Floating black pill navigation. The selected item expands into a white
/// pill with its label; the rest are round icon buttons.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
  });

  final List<FloatingNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  /// Height plus margin that scroll views should leave clear.
  static const double clearance = 104;

  @override
  Widget build(BuildContext context) {
    // The pills have a fixed height, so cap very large text there; the
    // selected label also shrinks with an ellipsis rather than overflowing
    // a narrow screen.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.6,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: ShapeDecoration(
          color: context.colors.nav,
          shape: const StadiumBorder(),
          shadows: [
            BoxShadow(
              color: context.colors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              if (i == index)
                Flexible(
                  child: _NavButton(
                    item: items[i],
                    selected: true,
                    onTap: () => onSelect(i),
                  ),
                )
              else
                _NavButton(
                  item: items[i],
                  selected: false,
                  onTap: () => onSelect(i),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: selected ? '' : item.label,
        child: Material(
          color: selected ? context.colors.navSelected : context.colors.navItem,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                height: 54,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: selected ? 20 : 15),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: selected
                            ? context.colors.navSelectedFg
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              color: context.colors.navSelectedFg,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
