// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';

class DockItemData {
  final IconData icon;
  final String label;

  const DockItemData({required this.icon, required this.label});
}

class FloatingDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const FloatingDock({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<DockItemData> items = [
    DockItemData(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    DockItemData(icon: Icons.account_balance_wallet_rounded, label: 'CashBook'),
    DockItemData(icon: Icons.inventory_2_rounded, label: 'Inventory'),
    DockItemData(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
      child: GlassmorphicContainer(
        width: 320,
        height: 68,
        borderRadius: 34,
        blur: 20,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withOpacity(0.7),
                  const Color(0xFF0F172A).withOpacity(0.5),
                ]
              : [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.5),
                ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  AppConstants.primaryColor.withOpacity(0.4),
                  Colors.white.withOpacity(0.3),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isSelected = selectedIndex == index;
            final item = items[index];

            return GestureDetector(
              onTap: () => onItemSelected(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected
                          ? AppConstants.primaryAccent
                          : (isDark ? Colors.white60 : Colors.black54),
                      size: isSelected ? 26 : 22,
                    )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                          duration: const Duration(milliseconds: 200),
                        ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppConstants.primaryAccent
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ).animate().fade().scale(),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
