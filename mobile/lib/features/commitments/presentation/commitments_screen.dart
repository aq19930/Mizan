import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../../shared/widgets/mizan_category_icon.dart';
import '../../../shared/widgets/mizan_empty_state.dart';
import '../../../shared/widgets/mizan_loading_skeleton.dart';
import '../data/models/commitment_model.dart';
import 'commitments_provider.dart';

class CommitmentsScreen extends ConsumerStatefulWidget {
  const CommitmentsScreen({super.key});

  @override
  ConsumerState<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends ConsumerState<CommitmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final commitmentsAsync = ref.watch(commitmentsProvider);

    return Scaffold(
      appBar: MizanAppBar(
        title: isArabic ? 'الالتزامات المالية' : 'Financial Commitments',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryDeepGreen),
            tooltip: isArabic ? 'إضافة التزام' : 'Add Commitment',
            onPressed: () => context.push(AppRoutes.addCommitment),
          ),
        ],
      ),
      body: SafeArea(
        child: commitmentsAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: const [
                MizanLoadingSkeleton(height: 120),
                SizedBox(height: 20),
                MizanLoadingSkeleton(height: 80),
                SizedBox(height: 12),
                MizanLoadingSkeleton(height: 80),
              ],
            ),
          ),
          error: (_, _) => Center(
            child: MizanEmptyState(
              icon: Icons.error_outline,
              title: isArabic ? 'حدث خطأ في تحميل الالتزامات' : 'Failed to load commitments',
              description: isArabic ? 'يرجى التحقق من الاتصال والمحاولة لاحقاً' : 'Please check connection and try again',
              buttonText: isArabic ? 'إعادة المحاولة' : 'Retry',
              onButtonPressed: () => ref.read(commitmentsProvider.notifier).loadCommitments(),
            ),
          ),
          data: (commitments) {
            final now = DateTime.now();
            final totalMonthly = commitments
                .where((c) => c.status == 'Active' && c.frequency == 'Monthly')
                .fold<double>(0.0, (sum, c) => sum + c.amount);

            final upcoming = commitments.where((c) => !c.isPaid && c.nextDueDate.isAfter(now.subtract(const Duration(days: 1)))).toList();
            final dueSoon = commitments.where((c) => c.isDueSoon).toList();
            final overdue = commitments.where((c) => c.isOverdue).toList();
            final paid = commitments.where((c) => c.isPaid).toList();

            return Column(
              children: [
                // Top Summary Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F4D3A), Color(0xFF1B6B52)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDeepGreen.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'إجمالي الالتزامات الشهرية' : 'Monthly Commitments',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  '${totalMonthly.toStringAsFixed(2)} ${l10n.currencySar}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isArabic ? '${commitments.length} التزامات' : '${commitments.length} items',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isArabic
                              ? 'المبالغ محجوزة كتقدير ولا تخصم من الرصيد إلا بعد السداد الفعلي.'
                              : 'Amounts are reserved and only deducted upon actual transaction.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primaryDeepGreen,
                  unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  indicatorColor: AppColors.primaryDeepGreen,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: isArabic ? 'القادمة (${upcoming.length})' : 'Upcoming (${upcoming.length})'),
                    Tab(text: isArabic ? 'قريباً (${dueSoon.length})' : 'Due Soon (${dueSoon.length})'),
                    Tab(text: isArabic ? 'متأخرة (${overdue.length})' : 'Overdue (${overdue.length})'),
                    Tab(text: isArabic ? 'مسددة (${paid.length})' : 'Paid (${paid.length})'),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _CommitmentsList(items: upcoming, isArabic: isArabic),
                      _CommitmentsList(items: dueSoon, isArabic: isArabic),
                      _CommitmentsList(items: overdue, isArabic: isArabic),
                      _CommitmentsList(items: paid, isArabic: isArabic),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryDeepGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => context.push(AppRoutes.addCommitment),
      ),
    );
  }
}

class _CommitmentsList extends ConsumerWidget {
  final List<CommitmentModel> items;
  final bool isArabic;

  const _CommitmentsList({required this.items, required this.isArabic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return Center(
        child: MizanEmptyState(
          icon: Icons.assignment_turned_in_outlined,
          title: isArabic ? 'لا توجد التزامات في هذا القسم' : 'No commitments in this section',
          description: isArabic ? 'جميع التزاماتك المالية منظمة وفي وضع سليم.' : 'Your financial obligations are all set.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = items[index];
        final days = c.daysUntilDue;

        String dueText;
        if (c.isPaid) {
          dueText = isArabic ? 'تم السداد' : 'Paid';
        } else if (days < 0) {
          dueText = isArabic ? 'متأخرة منذ ${days.abs()} يوم' : 'Overdue by ${days.abs()} days';
        } else if (days == 0) {
          dueText = isArabic ? 'مستحقة اليوم' : 'Due Today';
        } else {
          dueText = isArabic ? 'مستحق خلال $days أيام' : 'Due in $days days';
        }

        return MizanCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              MizanCategoryIcon(
                iconKey: _getCategoryIcon(c.category),
                colorHex: _getCategoryColor(c.category),
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          dueText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.isPaid
                                ? AppColors.accentBrightGreen
                                : (c.isOverdue ? AppColors.dangerRed : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                          ),
                        ),
                        if (c.merchant != null && c.merchant!.isNotEmpty) ...[
                          Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                          Text(
                            c.merchant!,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${c.amount.toStringAsFixed(2)} ${l10n.currencySar}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  if (!c.isPaid)
                    InkWell(
                      onTap: () {
                        ref.read(commitmentsProvider.notifier).markPaid(c.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic ? 'تم تحديث حالة الالتزام إلى مسدد' : 'Marked as paid'),
                            backgroundColor: AppColors.primaryDeepGreen,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isArabic ? 'تسديد' : 'Mark Paid',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDeepGreen),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'housing':
        return 'home';
      case 'car':
        return 'directions_car';
      case 'loan':
      case 'creditcard':
        return 'credit_card';
      case 'utilities':
        return 'bolt';
      case 'telecommunications':
      case 'telecom':
        return 'phone_android';
      case 'insurance':
        return 'verified_user';
      case 'subscriptions':
        return 'subscriptions';
      case 'education':
        return 'school';
      case 'family':
        return 'family_restroom';
      case 'bnpl':
        return 'shopping_bag';
      case 'healthcare':
        return 'medical_services';
      default:
        return 'assignment';
    }
  }

  String _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'housing':
        return '#64748B';
      case 'car':
        return '#6366F1';
      case 'loan':
      case 'creditcard':
        return '#EF4444';
      case 'utilities':
        return '#EAB308';
      case 'telecommunications':
      case 'telecom':
        return '#06B6D4';
      case 'subscriptions':
        return '#8B5CF6';
      case 'education':
        return '#14B8A6';
      case 'bnpl':
        return '#EC4899';
      default:
        return '#0F4D3A';
    }
  }
}
