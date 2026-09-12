import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../../shared/widgets/mizan_category_icon.dart';
import 'transactions_provider.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailsScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];

    final tx = transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => transactions.isNotEmpty ? transactions.first : throw Exception('Not found'),
    );

    final isExpense = tx.isExpense;

    void delete() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.delete),
          content: Text(l10n.confirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
              onPressed: () {
                Navigator.pop(ctx);
                ref.invalidate(transactionsProvider);
                context.pop();
              },
              child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: MizanAppBar(
        title: l10n.transactionDetails,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.dangerRed),
            onPressed: delete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Hero Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    MizanCategoryIcon(
                      iconKey: tx.categoryIcon ?? 'category',
                      colorHex: tx.categoryColorHex,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${isExpense ? '-' : '+'} ${tx.amount.toStringAsFixed(2)} ${l10n.currencySar}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isExpense ? AppColors.dangerRed : AppColors.accentBrightGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tx.merchant,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Detail Cards
              MizanCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: l10n.category, value: tx.categoryNameAr ?? '???'),
                    const Divider(height: 24),
                    _DetailRow(
                      label: l10n.transactionDate,
                      value: '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}-${tx.transactionDate.day.toString().padLeft(2, '0')}',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      label: l10n.source,
                      valueWidget: Row(
                        children: [
                          Icon(
                            tx.source == 1 ? Icons.sms_outlined : Icons.edit_outlined,
                            size: 16,
                            color: AppColors.primaryDeepGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tx.source == 1 ? l10n.sourceAuto : l10n.sourceManual,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (tx.source == 1) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        label: l10n.confidenceScore,
                        value: '${(tx.confidence * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                    if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _DetailRow(label: l10n.notes, value: tx.notes!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: MizanButton(
                  text: l10n.delete,
                  backgroundColor: AppColors.dangerRed,
                  onPressed: delete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
      ],
    );
  }
}
