import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ai_models.dart';

class StructuredAICardWidget extends StatelessWidget {
  final StructuredAICardModel card;
  final Function(String query)? onQuickQuery;

  const StructuredAICardWidget({
    super.key,
    required this.card,
    this.onQuickQuery,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    switch (card.cardType) {
      case 'LoanScenarioCard':
        return _buildLoanScenarioCard(context, isDark, isArabic);
      case 'PurchaseScenarioCard':
        return _buildPurchaseScenarioCard(context, isDark, isArabic);
      case 'CommitmentCard':
        return _buildCommitmentCard(context, isDark, isArabic);
      case 'BudgetPlanCard':
      case 'SuggestedPlanCard':
      case 'BudgetComparisonCard':
        return _buildBudgetPlanCard(context, isDark, isArabic);
      case 'ForecastCard':
        return _buildForecastCard(context, isDark, isArabic);
      case 'RiskCard':
        return _buildRiskCard(context, isDark, isArabic);
      case 'MoneySummaryCard':
      default:
        return _buildMoneySummaryCard(context, isDark, isArabic);
    }
  }

  Widget _buildCardContainer({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget content,
    List<Widget>? actions,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23322A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.primaryDeepGreen.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryDeepGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          content,
          if (actions != null && actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoanScenarioCard(BuildContext context, bool isDark, bool isArabic) {
    final loanAmt = card.data['loanAmount'] ?? 50000;
    final installment = card.data['monthlyInstallment'] ?? 1450;
    final existingCommitments = card.data['existingCommitments'] ?? 2000;
    final newTotalCommitments = card.data['newTotalCommitments'] ?? 3450;
    final dti = card.data['commitmentRatioAfter'] ?? 49.6;
    final rating = isArabic ? (card.data['ratingAr'] ?? 'ضغط مالي مرتفع') : (card.data['ratingEn'] ?? 'High Pressure');

    return _buildCardContainer(
      context: context,
      isDark: isDark,
      icon: Icons.account_balance,
      title: isArabic ? card.titleAr : card.titleEn,
      borderColor: Colors.amber.shade700.withValues(alpha: 0.4),
      content: Column(
        children: [
          _rowItem(isArabic ? 'مبلغ التمويل' : 'Loan Amount', '$loanAmt ر.س', isDark),
          _rowItem(isArabic ? 'القسط الشهري' : 'Monthly Installment', '$installment ر.س', isDark, isHighlight: true),
          _rowItem(isArabic ? 'الالتزامات الحالية' : 'Current Commitments', '$existingCommitments ر.س', isDark),
          _rowItem(isArabic ? 'بعد إضافة القرض' : 'After Loan', '$newTotalCommitments ر.س', isDark),
          _rowItem(isArabic ? 'نسبة الالتزامات (DTI)' : 'Commitment Ratio', '$dti%', isDark),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'التقييم المالي للأثر:' : 'Impact Rating:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                ),
                child: Text(
                  '$rating',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDeepGreen,
            side: const BorderSide(color: AppColors.primaryDeepGreen),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            context.push(AppRoutes.commitments);
          },
          child: Text(isArabic ? 'دراسة تفصيلية' : 'Detailed Study', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDeepGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            onQuickQuery?.call(isArabic ? 'طيب لو كان القسط 1000 ريال؟' : 'What if installment is 1000 SAR?');
          },
          child: Text(isArabic ? 'مقارنة قسط آخر' : 'Compare Another', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPurchaseScenarioCard(BuildContext context, bool isDark, bool isArabic) {
    final item = card.data['itemName'] ?? (isArabic ? 'السلعة' : 'Item');
    final amount = card.data['purchaseAmount'] ?? 5000;
    final availBefore = card.data['availableBefore'] ?? 6000;
    final availAfter = card.data['availableAfter'] ?? 1000;
    final currDaily = card.data['currentDailySpend'] ?? 170;
    final newDaily = card.data['newDailySpend'] ?? 82;
    final rating = isArabic ? (card.data['feasibilityRatingAr'] ?? 'قابل للإدارة') : (card.data['feasibilityRatingEn'] ?? 'Manageable');

    return _buildCardContainer(
      context: context,
      isDark: isDark,
      icon: Icons.shopping_bag_outlined,
      title: isArabic ? card.titleAr : card.titleEn,
      content: Column(
        children: [
          _rowItem(isArabic ? 'السلعة / الغرض' : 'Item / Purpose', item.toString(), isDark),
          _rowItem(isArabic ? 'قيمة الشراء' : 'Purchase Price', '$amount ر.س', isDark),
          _rowItem(isArabic ? 'المتاح قبل الشراء' : 'Available Before', '$availBefore ر.س', isDark),
          _rowItem(isArabic ? 'المتاح بعد الشراء' : 'Available After', '$availAfter ر.س', isDark, isHighlight: true),
          _rowItem(isArabic ? 'سقف الصرف اليومي الحالي' : 'Current Daily Pace', '$currDaily ر.س/يوم', isDark),
          _rowItem(isArabic ? 'سقف الصرف اليومي الجديد' : 'New Daily Pace', '$newDaily ر.س/يوم', isDark),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'تقييم إمكانية الشراء:' : 'Feasibility Rating:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryDeepGreen, width: 1),
                ),
                child: Text(
                  '$rating',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDeepGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDeepGreen,
            side: const BorderSide(color: AppColors.primaryDeepGreen),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            onQuickQuery?.call(isArabic ? 'هل الأفضل أقسط المبلغ؟' : 'Is it better to pay in installments?');
          },
          child: Text(isArabic ? 'هل أقسطه؟' : 'Installment Option?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCommitmentCard(BuildContext context, bool isDark, bool isArabic) {
    final total = card.data['totalAmount'] ?? 1726;
    final count = card.data['count'] ?? 3;
    final avail = card.data['availableAfter'] ?? 3500;

    return _buildCardContainer(
      context: context,
      isDark: isDark,
      icon: Icons.assignment_outlined,
      title: isArabic ? card.titleAr : card.titleEn,
      content: Column(
        children: [
          _rowItem(isArabic ? 'عدد الالتزامات المتبقية' : 'Remaining Count', '$count', isDark),
          _rowItem(isArabic ? 'إجمالي المبالغ المستحقة' : 'Total Obligations', '$total ر.س', isDark, isHighlight: true),
          _rowItem(isArabic ? 'السيولة المتاحة بعد الحجز' : 'Liquidity After', '$avail ر.س', isDark),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDeepGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => context.push(AppRoutes.commitments),
          child: Text(isArabic ? 'عرض جدول الالتزامات' : 'View Commitments', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildBudgetPlanCard(BuildContext context, bool isDark, bool isArabic) {
    final income = card.data['income'] ?? 6960;
    final commitments = card.data['commitments'] ?? 1671;
    final savings = card.data['savings'] ?? card.data['monthlySavings'] ?? 1000;
    final emergency = card.data['emergency'] ?? card.data['reserveBuffer'] ?? 500;
    final avail = card.data['availableToSpend'] ?? 3789;
    final daily = card.data['safeDailySpend'] ?? card.data['dailyLimit'] ?? 126;

    return _buildCardContainer(
      context: context,
      isDark: isDark,
      icon: Icons.calendar_today_outlined,
      title: isArabic ? card.titleAr : card.titleEn,
      content: Column(
        children: [
          _rowItem(isArabic ? 'الدخل الشهري' : 'Monthly Income', '$income ر.س', isDark),
          _rowItem(isArabic ? 'حجز الالتزامات' : 'Ring-fenced Commitments', '$commitments ر.س', isDark),
          _rowItem(isArabic ? 'ادخار شهري مستهدف' : 'Target Savings', '$savings ر.س', isDark),
          _rowItem(isArabic ? 'صندوق الطوارئ' : 'Emergency Buffer', '$emergency ر.س', isDark),
          _rowItem(isArabic ? 'المتاح للصرف' : 'Available to Spend', '$avail ر.س', isDark, isHighlight: true),
          _rowItem(isArabic ? 'سقف الصرف اليومي الآمن' : 'Safe Daily Pace', '$daily ر.س/يومي', isDark),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDeepGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArabic ? 'تم اعتماد وتطبيق الخطة المالية بنجاح!' : 'Financial plan applied successfully!'),
                backgroundColor: AppColors.primaryDeepGreen,
              ),
            );
          },
          child: Text(isArabic ? 'اعتماد الخطة' : 'Apply Plan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildForecastCard(BuildContext context, bool isDark, bool isArabic) {
    final low = card.data['low'] ?? 3200;
    final exp = card.data['expected'] ?? 3650;
    final high = card.data['high'] ?? 4050;
    final conf = card.data['confidence'] ?? 78;

    return _buildCardContainer(
      context: context,
      isDark: isDark,
      icon: Icons.trending_up,
      title: isArabic ? card.titleAr : card.titleEn,
      content: Column(
        children: [
          _rowItem(isArabic ? 'الحد الأدنى' : 'Low Bound', '$low ر.س', isDark),
          _rowItem(isArabic ? 'الرصيد المتوقع' : 'Expected Balance', '$exp ر.س', isDark, isHighlight: true),
          _rowItem(isArabic ? 'الحد الأعلى' : 'High Bound', '$high ر.س', isDark),
          _rowItem(isArabic ? 'نسبة الثقة' : 'Confidence Level', '$conf%', isDark),
        ],
      ),
    );
  }

  Widget _buildRiskCard(BuildContext context, bool isDark, bool isArabic) {
    final dti = card.data['newDti'] ?? '49.6%';
    final safe = card.data['safeThreshold'] ?? '33%';
    final rating = card.data['riskLevel'] ?? card.data['rating'] ?? (isArabic ? 'ضغط مرتفع' : 'High Pressure');

    return _buildCardContainer(
      context: context,
      isDark: isDark,
      icon: Icons.shield_outlined,
      title: isArabic ? card.titleAr : card.titleEn,
      borderColor: Colors.orange.shade700.withValues(alpha: 0.35),
      content: Column(
        children: [
          _rowItem(isArabic ? 'نسبة الالتزامات' : 'Commitment Ratio', '$dti', isDark),
          _rowItem(isArabic ? 'الحد الآمن الموصى به' : 'Safe Benchmark', '$safe', isDark),
          _rowItem(isArabic ? 'مستوى الضغط المالي' : 'Pressure Rating', '$rating', isDark, isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildMoneySummaryCard(BuildContext context, bool isDark, bool isArabic) {
    final balance = card.data['currentBalance'] ?? 5000;
    final available = card.data['availableToSpend'] ?? 2700;
    final commitments = card.data['commitments'] ?? card.data['reservedCommitments'] ?? 1800;

    return _buildCardContainer(
      context: context,
      isDark: isDark,
      icon: Icons.account_balance_wallet_outlined,
      title: isArabic ? card.titleAr : card.titleEn,
      content: Column(
        children: [
          _rowItem(isArabic ? 'الرصيد الحالي' : 'Current Balance', '$balance ر.س', isDark),
          _rowItem(isArabic ? 'الالتزامات المحجوزة' : 'Reserved Commitments', '$commitments ر.س', isDark),
          _rowItem(isArabic ? 'المتاح للصرف' : 'Available to Spend', '$available ر.س', isDark, isHighlight: true),
        ],
      ),
    );
  }

  Widget _rowItem(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? AppColors.primaryDeepGreen
                  : (isDark ? Colors.white : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
