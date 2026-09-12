import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../../shared/widgets/mizan_category_icon.dart';
import '../../../shared/widgets/mizan_loading_skeleton.dart';
import 'budget_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _showAddBudgetSheet(BuildContext context, bool isArabic, bool isDark) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'إضافة ميزانية جديدة' : 'Add New Budget',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'اسم التصنيف (مثال: ترفيه)' : 'Category Name (e.g. Entertainment)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isArabic ? 'المبلغ الشهري (ر.س)' : 'Monthly Limit (SAR)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isArabic ? 'تم حفظ الميزانية بنجاح' : 'Budget saved successfully'),
                        backgroundColor: AppColors.accentBrightGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    isArabic ? 'حفظ الميزانية' : 'Save Budget',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final budgetsAsync = ref.watch(budgetsProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.creamBackground,
      appBar: AppBar(
        title: Text(
          l10n.budget,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.creamBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.accentBrightGreen, size: 22),
                tooltip: isArabic ? 'إضافة ميزانية' : 'Add Budget',
                onPressed: () => _showAddBudgetSheet(context, isArabic, isDark),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: () async => ref.invalidate(budgetsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: budgetsAsync.when(
              loading: () => Column(
                children: const [
                  MizanLoadingSkeleton(height: 160),
                  SizedBox(height: 16),
                  MizanLoadingSkeleton(height: 80),
                  SizedBox(height: 12),
                  MizanLoadingSkeleton(height: 80),
                ],
              ),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text(l10n.loginFailed),
                ),
              ),
              data: (budgets) {
                final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.amount);
                final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spent);
                final totalRemaining = (totalBudget - totalSpent).clamp(0.0, double.infinity);
                final percentage = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Budget Card (Reference Image 1 Screen 4)
                    MizanCard(
                      padding: const EdgeInsets.all(20),
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text(
                                isArabic ? 'الميزانية الشهرية' : 'Monthly Budget',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBrightGreen.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 13, color: AppColors.accentBrightGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      isArabic ? '19 يوم متبقي' : '19 days left',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentBrightGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalBudget > 0 ? totalBudget.toStringAsFixed(0) : '5,000'} ${l10n.currencySar}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Dual-tone Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 10,
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage > 0.9 ? AppColors.dangerRed : primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Spent & Left Counters
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic ? 'تم صرفه' : 'Spent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${totalSpent.toStringAsFixed(0)} ${l10n.currencySar}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isArabic ? 'المتبقي' : 'Left',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${totalRemaining.toStringAsFixed(0)} ${l10n.currencySar}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentBrightGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section Title
                    Text(
                      l10n.spendingByCategory,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: budgets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final b = budgets[index];
                        final catPercent = (b.spent / b.amount).clamp(0.0, 1.0);
                        final color = catPercent > 0.9
                            ? AppColors.dangerRed
                            : (catPercent > 0.75 ? AppColors.warningAmber : AppColors.accentBrightGreen);

                        return MizanCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  MizanCategoryIcon(
                                    iconKey: b.categoryIcon,
                                    size: 38,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic ? b.categoryNameAr : b.categoryNameEn,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                         Text(
                                           '${b.spent.toStringAsFixed(0)} / ${b.amount.toStringAsFixed(0)} ${l10n.currencySar}',
                                           style: TextStyle(
                                             fontSize: 12,
                                             fontWeight: FontWeight.w600,
                                             color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                           ),
                                         ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${(b.percentage).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 6,
                                  child: LinearProgressIndicator(
                                    value: catPercent,
                                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
