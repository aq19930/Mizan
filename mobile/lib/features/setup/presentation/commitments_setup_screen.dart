import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../commitments/presentation/commitments_provider.dart';

class _CommitmentDraft {
  final String title;
  final String category;
  double amount;
  bool isSelected;
  final IconData icon;

  _CommitmentDraft({
    required this.title,
    required this.category,
    required this.amount,
    required this.icon,
  }) : isSelected = false;
}

class CommitmentsSetupScreen extends ConsumerStatefulWidget {
  const CommitmentsSetupScreen({super.key});

  @override
  ConsumerState<CommitmentsSetupScreen> createState() => _CommitmentsSetupScreenState();
}

class _CommitmentsSetupScreenState extends ConsumerState<CommitmentsSetupScreen> {
  bool _isLoading = false;

  late final List<_CommitmentDraft> _drafts = [
    _CommitmentDraft(
      title: 'إيجار السكن',
      category: 'Housing',
      amount: 2500.0,
      icon: Icons.home_outlined,
    ),
    _CommitmentDraft(
      title: 'قسط تمويل / سيارة',
      category: 'Car',
      amount: 1250.0,
      icon: Icons.directions_car_outlined,
    ),
    _CommitmentDraft(
      title: 'فاتورة الاتصالات والإنترنت',
      category: 'Telecommunications',
      amount: 290.0,
      icon: Icons.phone_android_outlined,
    ),
    _CommitmentDraft(
      title: 'فواتير الكهرباء والمياه',
      category: 'Utilities',
      amount: 250.0,
      icon: Icons.bolt_outlined,
    ),
    _CommitmentDraft(
      title: 'تقسيط تمارا / تابي',
      category: 'BNPL',
      amount: 350.0,
      icon: Icons.shopping_bag_outlined,
    ),
    _CommitmentDraft(
      title: 'اشتراكات رقمية',
      category: 'Subscriptions',
      amount: 85.0,
      icon: Icons.subscriptions_outlined,
    ),
  ];

  double get _totalCommitted {
    return _drafts
        .where((d) => d.isSelected)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  void _editDraftAmount(_CommitmentDraft draft) {
    final controller = TextEditingController(text: draft.amount.toStringAsFixed(0));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${isArabic ? 'تعديل مبلغ' : 'Edit amount for'} ${draft.title}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: isArabic ? 'المبلغ الشهري' : 'Monthly Amount',
                  suffixText: l10n.currencySar,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: MizanButton(
                  text: l10n.save,
                  onPressed: () {
                    final val = double.tryParse(controller.text.trim());
                    if (val != null && val > 0) {
                      setState(() {
                        draft.amount = val;
                        draft.isSelected = true;
                      });
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveAndProceed() async {
    setState(() => _isLoading = true);

    try {
      final selectedDrafts = _drafts.where((d) => d.isSelected).toList();
      final notifier = ref.read(commitmentsProvider.notifier);

      for (final draft in selectedDrafts) {
        await notifier.addCommitment(
          title: draft.title,
          category: draft.category,
          amount: draft.amount,
          frequency: 'Monthly',
          dueDate: DateTime.now().add(const Duration(days: 15)),
          priority: 'Medium',
        );
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        context.push(AppRoutes.setupBudget);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MizanAppBar(
        title: '${l10n.setupStepCommitments} (3/7)',
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.setupBudget),
            child: Text(
              l10n.skip,
              style: const TextStyle(color: AppColors.primaryDeepGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 3 / 7,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDeepGreen),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'هل لديك التزامات مالية ثابتة؟' : 'Do you have fixed financial obligations?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'حدد التزاماتك الدورية (أقساط، إيجار، فواتير) لنحجزها من الرصيد ونحميك من التورط في مصروفات إضافية.'
                    : 'Select your recurring obligations so we can reserve them from your available spend.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 16),

              // Total Reserved Summary Banner
              if (_totalCommitted > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryDeepGreen.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield, color: AppColors.primaryDeepGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'إجمالي المحجوز للالتزامات:' : 'Total Reserved:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        '${_totalCommitted.toStringAsFixed(0)} ${l10n.currencySar}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryDeepGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Drafts List
              Expanded(
                child: ListView.separated(
                  itemCount: _drafts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    return MizanCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: draft.isSelected
                          ? (isDark
                              ? AppColors.primaryDeepGreen.withValues(alpha: 0.2)
                              : AppColors.primaryDeepGreen.withValues(alpha: 0.05))
                          : null,
                      child: Row(
                        children: [
                          Checkbox(
                            value: draft.isSelected,
                            activeColor: AppColors.primaryDeepGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() => draft.isSelected = val ?? false);
                            },
                          ),
                          Icon(draft.icon, color: AppColors.primaryDeepGreen, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  draft.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Text(
                                  isArabic ? 'شهرياً' : 'Monthly',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _editDraftAmount(draft),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: draft.isSelected ? AppColors.primaryDeepGreen : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${draft.amount.toStringAsFixed(0)} ${l10n.currencySar}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: draft.isSelected ? AppColors.primaryDeepGreen : null,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: MizanButton(
                  text: _totalCommitted > 0
                      ? (isArabic ? 'حفظ ومتابعة' : 'Save & Continue')
                      : (isArabic ? 'متابعة بدون التزامات' : 'Continue without Commitments'),
                  isLoading: _isLoading,
                  onPressed: _saveAndProceed,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
