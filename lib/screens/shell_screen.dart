import 'package:flutter/material.dart';

import '../widgets/sidebar.dart';
import 'dashboard_screen.dart';
import 'keyboard_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'words_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(selectedIndex: _index, onSelect: (i) => setState(() => _index = i)),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                DashboardScreen(),
                WordsScreen(),
                KeyboardScreen(),
                StatsScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
