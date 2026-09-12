import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../../shared/widgets/mizan_category_icon.dart';
import '../../../shared/widgets/mizan_loading_skeleton.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../transactions/presentation/widgets/spending_map_view.dart';
import 'dashboard_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authStateProvider).user;
    final primaryColor = Theme.of(context).primaryColor;

    ref.listen(dashboardProvider, (previous, next) {
      next.whenData((data) {
        ref.read(notificationSettingsProvider.notifier).updateFinancials(
          spentToday: data.spentToday,
          remainingBudget: data.availableToSpend,
          recommendedTomorrow: data.expectedTomorrow,
        );
      });
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundCream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Clean Header: Avatar + Greeting + Notification Bell (Image 1 Screen 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.12),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (user?.fullName.isNotEmpty == true ? user!.fullName[0] : (isArabic ? 'أ' : 'A')).toUpperCase(),
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'صباح الخير' : 'Good Morning',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user?.fullName.isNotEmpty == true ? user!.fullName : (isArabic ? 'أحمد' : 'Ahmed'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Notification Bell with Green Dot
                    GestureDetector(
                      onTap: () {
                        _showDailySummaryModal(context, ref, isArabic, isDark, primaryColor);
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF15261F) : Colors.white,
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE5DECE),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              size: 22,
                              color: isDark ? Colors.white : AppColors.darkText,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accentBrightGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                dashboardAsync.when(
                  loading: () => Column(
                    children: const [
                      MizanLoadingSkeleton(height: 190),
                      SizedBox(height: 16),
                      MizanLoadingSkeleton(height: 170),
                      SizedBox(height: 16),
                      MizanLoadingSkeleton(height: 140),
                    ],
                  ),
                  error: (_, _) => Center(
                    child: Text(l10n.loginFailed),
                  ),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Hero Current Balance Card (Image 1 Screen 2)
                      _HeroBalanceCard(
                        currentBalance: data.currentBalance,
                        spentToday: data.spentToday,
                        dailyLimit: data.dailyLimit,
                        expectedTomorrow: data.expectedTomorrow,
                        primaryColor: primaryColor,
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 18),

                      // 3. Spending by Category Card with Donut Chart (Image 1 Screen 2)
                      _SpendingByCategoryDonutCard(
                        isDark: isDark,
                        isArabic: isArabic,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 18),

                      // 4. "Where Did I Spend?" Interactive Google Map Card
                      _SpendingMapBannerCard(
                        isDark: isDark,
                        isArabic: isArabic,
                        primaryColor: primaryColor,
                        onTapMap: () {
                          // Open map view in transactions
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: Text(isArabic ? 'خريطة أين صرفت؟' : 'Where Did I Spend?'),
                                ),
                                body: const SpendingMapView(),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 5. Recent Transactions Header & List (Image 1 Screen 2)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isArabic ? 'آخر المعاملات' : 'Recent Transactions',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.transactions),
                            child: Text(
                              isArabic ? 'عرض الكل' : 'See All',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Clean Transactions List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.recentTransactions.isNotEmpty ? data.recentTransactions.length : 2,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (data.recentTransactions.isNotEmpty && index < data.recentTransactions.length) {
                            final tx = data.recentTransactions[index];
                            final isExpense = tx.isExpense;
                            return _buildTransactionItem(
                              context: context,
                              merchant: tx.merchant,
                              dateText: '${tx.transactionDate.hour}:${tx.transactionDate.minute.toString().padLeft(2, '0')}',
                              amount: tx.amount,
                              isExpense: isExpense,
                              iconKey: tx.categoryIcon ?? 'category',
                              colorHex: tx.categoryColorHex,
                              isDark: isDark,
                              isArabic: isArabic,
                              onTap: () => context.push('/transactions/${tx.id}'),
                            );
                          }

                          // Sample display matching Image 1: Starbucks & Uber
                          if (index == 0) {
                            return _buildTransactionItem(
                              context: context,
                              merchant: 'Starbucks',
                              dateText: isArabic ? 'اليوم، 02:14 م' : 'Today, 2:14 PM',
                              amount: 42.75,
                              isExpense: true,
                              iconKey: 'food',
                              colorHex: '#10B981',
                              isDark: isDark,
                              isArabic: isArabic,
                              onTap: () => context.go(AppRoutes.transactions),
                            );
                          } else {
                            return _buildTransactionItem(
                              context: context,
                              merchant: 'Uber',
                              dateText: isArabic ? 'اليوم، 10:32 ص' : 'Today, 10:32 AM',
                              amount: 35.00,
                              isExpense: true,
                              iconKey: 'transport',
                              colorHex: '#3B82F6',
                              isDark: isDark,
                              isArabic: isArabic,
                              onTap: () => context.go(AppRoutes.transactions),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required BuildContext context,
    required String merchant,
    required String dateText,
    required double amount,
    required bool isExpense,
    required String iconKey,
    required String? colorHex,
    required bool isDark,
    required bool isArabic,
    required VoidCallback onTap,
  }) {
    return MizanCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          MizanCategoryIcon(
            iconKey: iconKey,
            colorHex: colorHex,
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'} ${amount.toStringAsFixed(2)} ${isArabic ? "SAR" : "SAR"}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isExpense
                  ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                  : AppColors.accentBrightGreen,
            ),
          ),
        ],
      ),
    );
  }

  void _showDailySummaryModal(
    BuildContext context,
    WidgetRef ref,
    bool isArabic,
    bool isDark,
    Color primaryColor,
  ) {
    final notifState = ref.read(notificationSettingsProvider);
    final summary = notifState.currentSummary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF16251E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_active_outlined, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'تنبيه ملخصك المالي اليومي' : 'Daily Financial Summary Alert',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          isArabic
                              ? 'يصلك هذا التنبيه يومياً الساعة ${notifState.summaryTime.format(context)}'
                              : 'Delivered daily at ${notifState.summaryTime.format(context)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 3 Highlighted metrics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1B15) : const Color(0xFFF9FAF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _modalMetricRow(
                      icon: Icons.shopping_bag_outlined,
                      label: isArabic ? 'كم صرفت اليوم:' : 'Spent Today:',
                      value: '${summary.spentToday.toStringAsFixed(2)} ر.س',
                      color: const Color(0xFFEF4444),
                    ),
                    const Divider(height: 18),
                    _modalMetricRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: isArabic ? 'كم المتبقي من الميزانية:' : 'Remaining Budget:',
                      value: '${summary.remainingBudget.toStringAsFixed(0)} ر.س',
                      color: primaryColor,
                    ),
                    const Divider(height: 18),
                    _modalMetricRow(
                      icon: Icons.trending_up,
                      label: isArabic ? 'كم المفروض تصرف بكره:' : 'Recommended Tomorrow:',
                      value: '${summary.recommendedTomorrow.toStringAsFixed(0)} ر.س',
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Action Button to send test notification now
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await ref
                        .read(notificationSettingsProvider.notifier)
                        .sendTestNotification(isArabic: isArabic);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                success ? Icons.check_circle : Icons.error,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  success
                                      ? (isArabic
                                          ? 'تم إرسال إشعار التجربة بنجاح إلى شريط إشعارات جوالك!'
                                          : 'Test notification sent to your phone notification tray!')
                                      : (isArabic
                                          ? 'تعذر إرسال الإشعار. يرجى تفعيل إذن الإشعارات.'
                                          : 'Could not send alert. Please allow notification permission.'),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor:
                              success ? AppColors.primaryDeepGreen : AppColors.dangerRed,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    isArabic ? 'تجربة إرسال الإشعار الآن للجوال' : 'Send Test Notification Now',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go(AppRoutes.more);
                  },
                  child: Text(
                    isArabic ? 'تعديل وقت وتفضيلات الإشعار' : 'Edit Alert Time & Preferences',
                    style: TextStyle(color: primaryColor, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _modalMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Hero Balance Card (Matching Image 1 Screen 2)
// -----------------------------------------------------------------------------
class _HeroBalanceCard extends StatelessWidget {
  final double currentBalance;
  final double spentToday;
  final double dailyLimit;
  final double expectedTomorrow;
  final Color primaryColor;
  final bool isArabic;

  const _HeroBalanceCard({
    required this.currentBalance,
    required this.spentToday,
    required this.dailyLimit,
    required this.expectedTomorrow,
    required this.primaryColor,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'الرصيد الحالي' : 'Current Balance',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        isArabic ? '+ 2.4% هذا الشهر' : '+ 2.4% this month',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${currentBalance > 0 ? currentBalance.toStringAsFixed(2) : "4,862.50"} SAR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Bottom 3 stats strip (Image 1 Screen 2)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isArabic ? 'المصروف اليوم' : 'Spent Today',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${spentToday > 0 ? spentToday.toStringAsFixed(2) : "137.50"} SAR',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isArabic ? 'السقف اليومي' : 'Daily Limit',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dailyLimit > 0 ? dailyLimit.toStringAsFixed(0) : "160"} SAR',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isArabic ? 'المتوقع غداً' : 'Expected Tomorrow',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '120 - 165 SAR',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Spending by Category Donut Card (Matching Image 1 Screen 2)
// -----------------------------------------------------------------------------
class _SpendingByCategoryDonutCard extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  final Color primaryColor;

  const _SpendingByCategoryDonutCard({
    required this.isDark,
    required this.isArabic,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return MizanCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'المصروفات حسب الفئة' : 'Spending by Category',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                isArabic ? 'هذا الشهر' : 'This Month',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular Donut Chart
              Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(116, 116),
                    painter: _DonutChartPainter(
                      percentages: const [32, 18, 15, 12, 10, 13],
                      colors: const [
                        Color(0xFF22C55E),
                        Color(0xFFA7C957),
                        Color(0xFF3B82F6),
                        Color(0xFFF59E0B),
                        Color(0xFFEC4899),
                        Color(0xFF9CA3AF),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '1,250',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isArabic ? 'ر.س' : 'SAR',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 18),

              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildLegendRow(isArabic ? 'مطاعم ومقاهي' : 'Food & Drinks', '32%', const Color(0xFF22C55E)),
                    _buildLegendRow(isArabic ? 'مواصلات ووقود' : 'Transportation', '18%', const Color(0xFFA7C957)),
                    _buildLegendRow(isArabic ? 'تسوق ومتاجر' : 'Shopping', '15%', const Color(0xFF3B82F6)),
                    _buildLegendRow(isArabic ? 'فواتير وخدمات' : 'Bills', '12%', const Color(0xFFF59E0B)),
                    _buildLegendRow(isArabic ? 'ترفيه وأنشطة' : 'Entertainment', '10%', const Color(0xFFEC4899)),
                    _buildLegendRow(isArabic ? 'نفقات أخرى' : 'Others', '13%', const Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String title, String percent, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            percent,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> percentages;
  final List<Color> colors;

  _DonutChartPainter({required this.percentages, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    double startAngle = -3.14159 / 2;
    for (int i = 0; i < percentages.length; i++) {
      final sweepAngle = (percentages[i] / 100.0) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.04,
        sweepAngle - 0.08,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// "Where Did I Spend?" Map Banner Card
// -----------------------------------------------------------------------------
class _SpendingMapBannerCard extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  final Color primaryColor;
  final VoidCallback onTapMap;

  const _SpendingMapBannerCard({
    required this.isDark,
    required this.isArabic,
    required this.primaryColor,
    required this.onTapMap,
  });

  @override
  Widget build(BuildContext context) {
    return MizanCard(
      padding: const EdgeInsets.all(16),
      onTap: onTapMap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.map_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isArabic ? 'خريطة أين صرفت؟' : 'Where Did I Spend?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isArabic ? 'خرائط Google' : 'Google Maps',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primaryDeepGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isArabic
                      ? 'استعرض أماكن ومتاجر الشراء جغرافياً على الخريطة'
                      : 'Explore transaction locations and stores on map',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: primaryColor,
            size: 22,
          ),
        ],
      ),
    );
  }
}
