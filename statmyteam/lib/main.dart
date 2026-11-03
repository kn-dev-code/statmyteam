import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'data/stats_repository.dart';
import 'screens/main_menu_screen.dart';
import 'state/betting_controller.dart';
import 'state/betting_scope.dart';
import 'state/stats_scope.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RendererBinding.instance.ensureSemantics();
  runApp(StatMyTeamApp(
    controller: BettingController.demo(),
    repository: StatsRepository.sampleFootball(),
  ));
}

class StatMyTeamApp extends StatelessWidget {
  const StatMyTeamApp({
    super.key,
    required this.controller,
    required this.repository,
  });

  final BettingController controller;
  final StatsRepository repository;

  @override
  Widget build(BuildContext context) {
    return StatsScope(
      repository: repository,
      child: BettingScope(
        controller: controller,
        child: MaterialApp(
          title: 'StatMyTeam',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const MainMenuScreen(),
        ),
      ),
    );
  }
}
