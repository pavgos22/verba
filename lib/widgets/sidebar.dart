import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';
import '../theme/app_colors.dart';

class SidebarItem {
  const SidebarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const sidebarItems = [
  SidebarItem(icon: Icons.home_outlined, label: 'Start'),
  SidebarItem(icon: Icons.menu_book_outlined, label: 'Słówka'),
  SidebarItem(icon: Icons.keyboard_outlined, label: 'Klawiatura'),
  SidebarItem(icon: Icons.bar_chart_outlined, label: 'Statystyki'),
  SidebarItem(icon: Icons.settings_outlined, label: 'Ustawienia'),
];

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.c.sidebar,
        border: Border(right: BorderSide(color: context.c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.translate, size: 20, color: context.c.foreground),
                const SizedBox(width: 8),
                Text(
                  'Verba',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.c.foreground),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < sidebarItems.length; i++)
            _NavTile(
              item: sidebarItems[i],
              active: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          _NavTile(
            item: SidebarItem(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label: isDark ? 'Jasny motyw' : 'Ciemny motyw',
            ),
            active: false,
            onTap: () {
              ref.read(settingsProvider.notifier).setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active, required this.onTap});

  final SidebarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? context.c.foreground : context.c.mutedForeground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? context.c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          mouseCursor: SystemMouseCursors.click,
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
