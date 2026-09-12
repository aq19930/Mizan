import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../insights/presentation/widgets/floating_ai_button.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budget')) return 2;
    if (location.startsWith('/insights')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.transactions);
        break;
      case 2:
        context.go(AppRoutes.budget);
        break;
      case 3:
        context.go(AppRoutes.insights);
        break;
      case 4:
        context.go(AppRoutes.more);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: child,
      floatingActionButton: const FloatingMizanAiButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEFEAE1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  currentIndex: selectedIndex,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: l10n.home,
                  activeColor: primaryColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  currentIndex: selectedIndex,
                  icon: Icons.sync_alt_rounded,
                  activeIcon: Icons.sync_alt_rounded,
                  label: l10n.transactions,
                  activeColor: primaryColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  currentIndex: selectedIndex,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: l10n.budget,
                  activeColor: primaryColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  currentIndex: selectedIndex,
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                  label: l10n.insights,
                  activeColor: primaryColor,
                  isDark: isDark,
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  currentIndex: selectedIndex,
                  icon: Icons.more_horiz_rounded,
                  activeIcon: Icons.more_horiz_rounded,
                  label: l10n.more,
                  activeColor: primaryColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected ? activeColor : (isDark ? Colors.white54 : const Color(0xFF8E8E93));

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
