import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../../shared/widgets/mizan_category_icon.dart';
import '../../../shared/widgets/mizan_empty_state.dart';
import '../../../shared/widgets/mizan_loading_skeleton.dart';
import '../../../shared/widgets/mizan_text_field.dart';
import 'transactions_provider.dart';

import 'widgets/spending_map_view.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final int initialViewMode; // 0 = List, 1 = Map

  const TransactionsScreen({super.key, this.initialViewMode = 0});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Expense, 2 = Income
  String _searchQuery = '';
  late int _viewMode; // 0 = List, 1 = Map

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialViewMode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final transactionsAsync = ref.watch(transactionsProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewMode == 1 ? (isArabic ? 'خريطة الصرف (أين صرفت؟)' : 'Spending Map') : l10n.transactions,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.creamBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_viewMode == 0 ? Icons.map_outlined : Icons.format_list_bulleted_rounded),
            tooltip: _viewMode == 0 ? (isArabic ? 'عرض الخريطة' : 'Map View') : (isArabic ? 'عرض القائمة' : 'List View'),
            color: primaryColor,
            onPressed: () => setState(() => _viewMode = _viewMode == 0 ? 1 : 0),
          ),
        ],
      ),
      body: SafeArea(
        child: _viewMode == 1
            ? SpendingMapView(onBackToList: () => setState(() => _viewMode = 0))
            : Column(
                children: [
            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  MizanTextField(
                    hint: l10n.searchTransactions,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.toLowerCase().trim());
                    },
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  Row(
                    children: [
                      _FilterChip(
                        label: l10n.allFilter,
                        isSelected: _selectedFilter == 0,
                        onTap: () => setState(() => _selectedFilter = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.expensesFilter,
                        isSelected: _selectedFilter == 1,
                        onTap: () => setState(() => _selectedFilter = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.incomesFilter,
                        isSelected: _selectedFilter == 2,
                        onTap: () => setState(() => _selectedFilter = 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Transactions List
            Expanded(
              child: transactionsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 5,
                  itemBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: MizanLoadingSkeleton(height: 72),
                  ),
                ),
                error: (_, _) => MizanEmptyState(
                  icon: Icons.error_outline,
                  title: l10n.loginFailed,
                  description: '',
                ),
                data: (transactions) {
                  final filtered = transactions.where((t) {
                    if (_selectedFilter == 1 && !t.isExpense) return false;
                    if (_selectedFilter == 2 && !t.isIncome) return false;
                    if (_searchQuery.isNotEmpty) {
                      final matchMerchant = t.merchant.toLowerCase().contains(_searchQuery);
                      final matchCat = (t.categoryNameAr ?? '').toLowerCase().contains(_searchQuery);
                      final matchNotes = (t.notes ?? '').toLowerCase().contains(_searchQuery);
                      if (!matchMerchant && !matchCat && !matchNotes) return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return MizanEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.noTransactions,
                      description: l10n.noTransactionsDesc,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      final isExpense = tx.isExpense;

                      return MizanCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        onTap: () => context.push('/transactions/${tx.id}'),
                        child: Row(
                          children: [
                            MizanCategoryIcon(
                              iconKey: tx.categoryIcon ?? 'category',
                              colorHex: tx.categoryColorHex,
                              size: 44,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.merchant,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        tx.categoryNameAr ?? '???',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      if (tx.source == 1) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'SMS',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryDeepGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isExpense ? '-' : '+'} ${tx.amount.toStringAsFixed(2)} ${l10n.currencySar}',
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDeepGreen
              : (isDark ? AppColors.darkSurface : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.lightTextPrimary),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
