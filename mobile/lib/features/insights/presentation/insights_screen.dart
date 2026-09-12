import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../data/models/ai_models.dart';
import 'ai_providers.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _timelineSelectedMonths = 6;
  String _selectedWhatIfType = 'MajorPurchase';
  final double _whatIfAmount = 4500;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final summaryAsync = ref.watch(analysisSummaryProvider);
    final loanState = ref.watch(loanScenarioProvider);
    final whatIfState = ref.watch(whatIfProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.creamBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accentBrightGreen, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isArabic ? 'التحليل المالي الذكي' : 'AI Insights',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.creamBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5DECE)),
                    ),
                    child: Icon(Icons.notifications_none_rounded, size: 20, color: isDark ? Colors.white : AppColors.darkText),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.accentBrightGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDeepGreen),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                Text(
                  isArabic ? 'تعذر تحميل التحليل المالي' : 'Failed to load analysis',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDeepGreen),
                  onPressed: () => ref.refresh(analysisSummaryProvider),
                  child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (summary) {
          return RefreshIndicator(
            color: AppColors.primaryDeepGreen,
            onRefresh: () async => ref.refresh(analysisSummaryProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reference Card 1 (Image 1 Screen 3): "أنت تحت السيطرة" + 7-Day Bar Chart
                  _buildUnderControlCard(isDark, isArabic, primaryColor),
                  const SizedBox(height: 14),

                  // Reference Card 2 (Image 1 Screen 3): Tomorrow's Forecast with Confidence Badge
                  _buildTomorrowForecastCard(isDark, isArabic),
                  const SizedBox(height: 14),

                  // Reference Card 3 (Image 1 Screen 3): Smart Tips Lightbulb Card
                  _buildSmartTipsCard(isDark, isArabic),
                  const SizedBox(height: 14),

                  // 1. Financial Health Score (Section 96)
                  _buildHealthScoreSection(summary.health, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 2. AI Summary (Section 97)
                  _buildAiSummarySection(summary, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 3. Available to Spend & Liquidity (Section 88 & 118)
                  _buildAvailableToSpendSection(summary.forecast, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 4. Month-End Forecast (Section 99)
                  _buildForecastSection(summary.forecast, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 5. Income vs Spending (Section 118)
                  _buildIncomeVsSpendingSection(summary.forecast, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 6. Commitment Schedule Table (Section 100)
                  _buildCommitmentScheduleSection(summary.commitments, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 7. Commitment Timeline & Upcoming Pressure (Section 101 & 102)
                  _buildTimelineSection(summary.commitments, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 8. AI Budget Recommendation & Rescheduling (Section 103, 104, 128)
                  _buildBudgetOptimizationSection(summary.safeDailySpending, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 9. Loan Scenario Analyzer (Section 105 - 110)
                  _buildLoanAnalyzerSection(loanState, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 10. What-If Lab (Section 112)
                  _buildWhatIfLabSection(whatIfState, isDark, isArabic),
                  const SizedBox(height: 14),

                  // 11. Historical Trends & Regulatory Financial Disclaimer (Section 111)
                  _buildDisclaimerSection(isDark, isArabic),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 1. Health Score Section
  Widget _buildHealthScoreSection(FinancialHealthModel health, bool isDark, bool isArabic) {
    return MizanCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'مؤشر الصحة المالية' : 'Financial Health Score',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentBrightGreen.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic ? health.statusAr : health.statusEn,
                  style: const TextStyle(
                    color: AppColors.primaryDeepGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: health.score / 100.0,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: health.score >= 80 ? AppColors.accentBrightGreen : AppColors.primaryDeepGreen,
                    ),
                  ),
                  Text(
                    '${health.score}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  isArabic ? health.summaryAr : health.summaryEn,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),
          for (final factor in health.factors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isArabic ? factor.nameAr : factor.nameEn,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${factor.score.toInt()}% (${isArabic ? factor.statusAr : factor.statusEn})',
                        style: const TextStyle(fontSize: 11, color: AppColors.primaryDeepGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: factor.score / 100,
                      minHeight: 5,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      color: AppColors.primaryDeepGreen,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 2. AI Summary Section
  Widget _buildAiSummarySection(AnalysisSummaryModel summary, bool isDark, bool isArabic) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(summary.lastUpdated);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4D3A), Color(0xFF1B6B52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeepGreen.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accentBrightGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'التحليل المالي الذكي' : 'AI Financial Summary',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? summary.aiAnalysisTextAr : summary.aiAnalysisTextEn,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }

  // 3. Available to Spend & Liquidity
  Widget _buildAvailableToSpendSection(FinancialForecastModel forecast, bool isDark, bool isArabic) {
    final available = forecast.currentBalance - forecast.upcomingCommitments - 1500;

    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'السيولة المتاحة بعد حجز الالتزامات' : 'Available After Commitments',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricCol(
                  isArabic ? 'الرصيد الفعلي' : 'Current Balance',
                  '${forecast.currentBalance.toStringAsFixed(0)} ر.س',
                  Colors.grey.shade700,
                ),
              ),
              const Text(' - ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildMetricCol(
                  isArabic ? 'التزامات قادمة' : 'Commitments',
                  '${forecast.upcomingCommitments.toStringAsFixed(0)} ر.س',
                  Colors.orange.shade700,
                ),
              ),
              const Text(' = ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildMetricCol(
                  isArabic ? 'المتاح للصرف' : 'Available',
                  '${available.toStringAsFixed(0)} ر.س',
                  AppColors.primaryDeepGreen,
                  isBold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 4. Month-End Forecast
  Widget _buildForecastSection(FinancialForecastModel forecast, bool isDark, bool isArabic) {
    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'توقع الرصيد بنهاية الشهر' : 'Month-End Balance Forecast',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isArabic ? forecast.confidenceLevelAr : forecast.confidenceLevelEn,
                  style: const TextStyle(fontSize: 10, color: AppColors.primaryDeepGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildForecastBoundsItem(isArabic ? 'الحد الأدنى' : 'Low', forecast.monthEndBalance.low)),
              Expanded(child: _buildForecastBoundsItem(isArabic ? 'المتوقع' : 'Expected', forecast.monthEndBalance.expected, isPrimary: true)),
              Expanded(child: _buildForecastBoundsItem(isArabic ? 'الحد الأعلى' : 'High', forecast.monthEndBalance.high)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isArabic ? forecast.explanationAr : forecast.explanationEn,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastBoundsItem(String label, double val, {bool isPrimary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${val.toStringAsFixed(0)} ر.س',
          style: TextStyle(
            fontSize: isPrimary ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isPrimary ? AppColors.primaryDeepGreen : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // 5. Income vs Spending
  Widget _buildIncomeVsSpendingSection(FinancialForecastModel forecast, bool isDark, bool isArabic) {
    const income = 6960.45;
    const spending = 3850.0;
    const surplus = income - spending;

    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'مقارنة الدخل بالمصروفات' : 'Income vs Spending',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'الدخل الشهري: 6,960.45 ر.س' : 'Income: 6,960.45 SAR',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(isArabic ? 'المصروف: 3,850 ر.س' : 'Spent: 3,850 SAR', style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: spending / income,
              minHeight: 8,
              backgroundColor: Color(0xFFE8F2EC),
              color: AppColors.primaryDeepGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'فائض السيولة المقدر لهذا الشهر: +${surplus.toStringAsFixed(0)} ر.س' : 'Estimated Surplus: +${surplus.toStringAsFixed(0)} SAR',
            style: const TextStyle(fontSize: 11, color: AppColors.accentBrightGreen, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 6. Commitment Schedule Table
  Widget _buildCommitmentScheduleSection(CommitmentScheduleModel commitments, bool isDark, bool isArabic) {
    final currentGroup = commitments.months.isNotEmpty ? commitments.months.first : null;

    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'جدول الالتزامات المجدولة' : 'Commitment Schedule',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${currentGroup?.totalAmount.toStringAsFixed(0) ?? 0} ر.س',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDeepGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentGroup != null && currentGroup.commitments.isNotEmpty)
            for (final item in currentGroup.commitments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeepGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long, size: 16, color: AppColors.primaryDeepGreen),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? item.nameAr : item.nameEn,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${DateFormat('dd MMM').format(item.dueDate)} • ${item.frequency}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.amount.toStringAsFixed(2)} ر.س',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              )
          else
            Text(isArabic ? 'لا توجد التزامات مسجلة' : 'No commitments recorded', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // 7. Timeline & Pressure
  Widget _buildTimelineSection(CommitmentScheduleModel commitments, bool isDark, bool isArabic) {
    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'الجدول الزمني للالتزامات' : 'Commitments Timeline',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [3, 6, 12].map((m) {
                  final isSel = _timelineSelectedMonths == m;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      label: Text('$m${isArabic ? "ش" : "M"}', style: TextStyle(fontSize: 10, color: isSel ? Colors.white : null)),
                      selected: isSel,
                      selectedColor: AppColors.primaryDeepGreen,
                      onSelected: (_) => setState(() => _timelineSelectedMonths = m),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Months list
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: commitments.months.take(_timelineSelectedMonths).length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final grp = commitments.months[idx];
                return Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: grp.isHeavyMonth
                        ? Colors.red.withValues(alpha: 0.12)
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: grp.isHeavyMonth ? Border.all(color: Colors.red.shade400, width: 1.5) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isArabic ? grp.monthLabelAr.split(' ')[0] : grp.monthLabelEn.split(' ')[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(grp.totalAmount.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: grp.isHeavyMonth ? Colors.red.shade700 : null)),
                      Text(isArabic ? 'ر.س' : 'SAR', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      if (grp.isHeavyMonth)
                        Text(isArabic ? 'ذروة التزام' : 'Peak', style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic ? commitments.aiAnalysisAr : commitments.aiAnalysisEn,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. AI Budget Recommendation & Rescheduling
  Widget _buildBudgetOptimizationSection(double safeDaily, bool isDark, bool isArabic) {
    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'سقف الصرف اليومي الآمن' : 'Safe Daily Spending Cap',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${safeDaily.toStringAsFixed(0)} ${isArabic ? "ر.س/يومي" : "SAR/day"}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDeepGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'الحفاظ على هذا السقف يضمن لك تغطية الالتزامات وبلوغ نهاية الشهر بأمان.'
                : 'Staying under this daily cap ensures covering commitments and finishing the month securely.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDeepGreen,
                side: const BorderSide(color: AppColors.primaryDeepGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(isArabic ? 'إعادة جدولة الميزانية (Optimize)' : 'Optimize My Budget'),
              onPressed: () => _showOptimizeDialog(context, isArabic),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptimizeDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'إعادة جدولة الميزانية' : 'Optimize Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'اختر الهدف التخطيطي ليقوم ميزان بإعادة احتساب توزيع السيولة:'
                  : 'Select an objective for Mizan to recalculate liquidity distribution:',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ListTile(
              dense: true,
              leading: const Icon(Icons.balance, color: AppColors.primaryDeepGreen),
              title: Text(isArabic ? 'متوازن (موصى به)' : 'Balanced (Recommended)'),
              subtitle: Text(isArabic ? 'صرف يومي 125 ر.س • ادخار 800 ر.س' : 'Daily 125 SAR • Savings 800 SAR'),
              onTap: () {
                Navigator.pop(ctx);
                _applyPlanFeedback(context, isArabic);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.savings, color: Colors.amber),
              title: Text(isArabic ? 'زيادة الادخار' : 'Save More'),
              subtitle: Text(isArabic ? 'صرف يومي 110 ر.س • ادخار 1,200 ر.س' : 'Daily 110 SAR • Savings 1,200 SAR'),
              onTap: () {
                Navigator.pop(ctx);
                _applyPlanFeedback(context, isArabic);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _applyPlanFeedback(BuildContext context, bool isArabic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'تم تحديث خطة الميزانية بنجاح!' : 'Budget plan updated successfully!'),
        backgroundColor: AppColors.primaryDeepGreen,
      ),
    );
  }

  // 9. Loan Scenario Analyzer
  Widget _buildLoanAnalyzerSection(LoanScenarioState state, bool isDark, bool isArabic) {
    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'محلل القروض والتمويل' : 'Loan Scenario Analyzer',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (state.result?.commitmentRatioAfter ?? 0) > 0.40
                      ? Colors.orange.withValues(alpha: 0.2)
                      : AppColors.accentBrightGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.result != null ? (isArabic ? state.result!.ratingAr : state.result!.ratingEn) : '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isArabic ? 'مبلغ التمويل:' : 'Amount:', style: const TextStyle(fontSize: 12)),
              Text('${state.loanAmount.toStringAsFixed(0)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: state.loanAmount,
            min: 10000,
            max: 200000,
            divisions: 19,
            activeColor: AppColors.primaryDeepGreen,
            onChanged: (v) {
              ref.read(loanScenarioProvider.notifier).calculate(amount: v);
            },
          ),
          if (state.result != null) ...[
            Row(
              children: [
                Expanded(child: _buildLoanStat(isArabic ? 'القسط المقدر' : 'Installment', '${state.result!.monthlyInstallment.toStringAsFixed(0)} ر.س')),
                Expanded(child: _buildLoanStat(isArabic ? 'نسبة الالتزامات' : 'DTI After', '${(state.result!.commitmentRatioAfter * 100).toStringAsFixed(1)}%')),
                Expanded(child: _buildLoanStat(isArabic ? 'المتبقي شهرياً' : 'Cash Margin', '${state.result!.monthlyAvailableCashAfter.toStringAsFixed(0)} ر.س')),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isArabic ? state.result!.explanationAr : state.result!.explanationEn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoanStat(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDeepGreen)),
      ],
    );
  }

  // 10. What-If Lab
  Widget _buildWhatIfLabSection(WhatIfState state, bool isDark, bool isArabic) {
    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'مختبر "ماذا لو؟" التفاعلي' : 'What-If Scenario Lab',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedWhatIfType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: [
              DropdownMenuItem(value: 'MajorPurchase', child: Text(isArabic ? 'شراء سلعة كبرى' : 'Major Purchase')),
              DropdownMenuItem(value: 'SalaryRaise', child: Text(isArabic ? 'زيادة في الراتب' : 'Salary Raise')),
              DropdownMenuItem(value: 'ExpenseReduction', child: Text(isArabic ? 'خفض المصروفات 15%' : 'Expense Cut 15%')),
              DropdownMenuItem(value: 'ExtraCommitment', child: Text(isArabic ? 'إضافة التزام شهري' : 'New Monthly Commitment')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedWhatIfType = v);
                ref.read(whatIfProvider.notifier).simulate(type: v, amount: _whatIfAmount);
              }
            },
          ),
          const SizedBox(height: 10),
          if (state.result != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isArabic ? state.result!.titleAr : state.result!.titleEn,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? state.result!.feasibilityRatingAr : state.result!.feasibilityRatingEn,
                        style: const TextStyle(color: AppColors.primaryDeepGreen, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(isArabic ? state.result!.explanationAr : state.result!.explanationEn, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Reference Card 1 (Image 1 Screen 3): Under Control & Weekly Bar Chart
  Widget _buildUnderControlCard(bool isDark, bool isArabic, Color primaryColor) {
    final daysAr = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
    final daysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final amounts = [110.0, 145.0, 95.0, 180.0, 137.5, 210.0, 125.0];
    const maxVal = 220.0;

    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.accentBrightGreen, size: 14),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isArabic ? 'أنت تحت السيطرة' : 'You are in control',
                          style: const TextStyle(
                            color: AppColors.accentBrightGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'المعدل: 142 ر.س' : 'Avg: 142 SAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isArabic ? 'المصروفات الأسبوعية' : 'Weekly Spending',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final ratio = (amounts[index] / maxVal).clamp(0.1, 1.0);
                final isToday = index == 4; // Thursday highlight
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${amounts[index].toInt()}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 14,
                        height: 64 * ratio,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.accentBrightGreen
                              : (isDark ? primaryColor.withValues(alpha: 0.5) : primaryColor.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isArabic ? daysAr[index] : daysEn[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                          color: isToday ? AppColors.accentBrightGreen : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Reference Card 2 (Image 1 Screen 3): Tomorrow's Forecast Card
  Widget _buildTomorrowForecastCard(bool isDark, bool isArabic) {
    return MizanCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.accentBrightGreen, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'توقع المصروفات لغداً' : "Tomorrow's Forecast",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic ? '120 - 165 ر.س' : '120 - 165 SAR',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isArabic ? 'دقة 89%' : '89% Conf.',
              style: const TextStyle(
                color: AppColors.accentBrightGreen,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reference Card 3 (Image 1 Screen 3): Smart Tips Lightbulb Card
  Widget _buildSmartTipsCard(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentBrightGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentBrightGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'نصيحة ميزان الذكية' : 'Smart Financial Tip',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'تقليل مشتريات القهوة والمطاعم بنسبة 15% يوفر لك قرابة 420 ر.س بنهاية الشهر.'
                      : 'Reducing outside coffee and dining by 15% could save you ~420 SAR by month end.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 11. Disclaimer
  Widget _buildDisclaimerSection(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isArabic
                  ? 'إخلاء مسؤولية: ميزان يقدم دراسات وتحليلات تخطيط مالي تقديرية ولا يُعد جهة تمويل أو وساطة أو استشارة مالية مرخصة.'
                  : 'Disclaimer: Mizan provides financial planning estimates and is not a licensed lender or financial advisory institution.',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
