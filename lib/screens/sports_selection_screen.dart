
import 'package:flutter/material.dart';

import 'team_select_screen.dart';

class SportsSelectionScreen extends StatelessWidget {
  const SportsSelectionScreen({
    super.key,
    required this.mode,
  });

  final TeamSelectMode mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Sport'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose a sport',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a sport to continue to team selection.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sports_football),
              title: const Text('American Football'),
              subtitle: const Text('NFL and available college teams'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TeamSelectScreen(
                      mode: mode,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.sports_basketball),
              title: Text('Basketball'),
              subtitle: Text('Coming soon'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.sports_soccer),
              title: Text('Soccer'),
              subtitle: Text('Coming soon'),
            ),
          ),
        ],
      ),
    );
  }
}
