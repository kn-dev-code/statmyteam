import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// A team color that stays readable on the current card surface: not too
/// light on white cards, not too dark on charcoal ones. White text on it
/// (badges, jersey discs) stays legible in both modes.
Color teamColor(Team team) {
  final primary = Color(team.primaryColor);
  final secondary = Color(team.secondaryColor);
  bool tooLight(Color c) => c.computeLuminance() >= 0.5;
  bool tooDark(Color c) => c.computeLuminance() < 0.035;

  final Color base;
  if (!tooLight(primary)) {
    base = primary;
  } else if (!tooLight(secondary)) {
    base = secondary;
  } else {
    base = Color.lerp(primary, Colors.black, 0.45)!;
  }
  if (AppColors.isDark && tooDark(base)) {
    if (!tooDark(secondary) && !tooLight(secondary)) return secondary;
    return Color.lerp(base, Colors.white, 0.3)!;
  }
  return base;
}

/// Crest-style badge: a white ring around a team-color disc with the
/// abbreviation, echoing a club logo in a frame.
class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.team, this.size = 44});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = teamColor(team);
    final ring = size >= 56 ? 6.0 : (size >= 36 ? 3.5 : 2.0);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: size >= 56
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.18)!, color],
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                team.abbreviation,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.26,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded white card used across the stats screens.
