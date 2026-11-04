import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'screens/home_screen.dart';
import 'state/betting_controller.dart';
import 'state/betting_scope.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RendererBinding.instance.ensureSemantics();
  runApp(StatMyTeamApp(controller: BettingController.demo()));
}

class StatMyTeamApp extends StatelessWidget {
  const StatMyTeamApp({super.key, required this.controller});

  final BettingController controller;

  @override
  Widget build(BuildContext context) {
    return BettingScope(
      controller: controller,
      child: MaterialApp(
        title: 'StatMyTeam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
