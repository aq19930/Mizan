import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';

class InitialBalanceScreen extends ConsumerStatefulWidget {
  const InitialBalanceScreen({super.key});

  @override
  ConsumerState<InitialBalanceScreen> createState() => _InitialBalanceScreenState();
}

class _InitialBalanceScreenState extends ConsumerState<InitialBalanceScreen> {
  final TextEditingController _balanceController = TextEditingController(text: '12500');
  bool _isLoading = false;

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  void _showConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_balanceController.text.replaceAll(',', '')) ?? 0.0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, size: 28, color: AppColors.primaryDeepGreen),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.balanceConfirmQuestion,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${amount.toStringAsFixed(0)} ${l10n.currencySar}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDeepGreen),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.balanceConfirmPrompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: MizanButton(
                      text: l10n.edit,
                      isOutlined: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MizanButton(
                      text: l10n.yesConfirm,
                      onPressed: () {
                        Navigator.pop(context);
                        _saveAndProceed(amount);
                      },
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

  Future<void> _saveAndProceed(double amount) async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/wallets', data: {
        'name': 'المحفظة الرئيسية',
        'initialBalance': amount,
        'currency': 'SAR',
      });
    } catch (_) {
      // Ignored for standalone demo
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        context.push(AppRoutes.setupCommitments);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MizanAppBar(title: '${l10n.setupStepBalance} (2/7)'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 2 / 7,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDeepGreen),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.balanceSetupTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.balanceSetupDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 48),
              // Large Balance Input
              Center(
                child: Column(
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDeepGreen,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.currencySar,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDeepGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Quick suggestions
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _QuickAmountChip(label: '5,000', onTap: () => _balanceController.text = '5000'),
                    _QuickAmountChip(label: '10,000', onTap: () => _balanceController.text = '10000'),
                    _QuickAmountChip(label: '15,000', onTap: () => _balanceController.text = '15000'),
                    _QuickAmountChip(label: '25,000', onTap: () => _balanceController.text = '25000'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: MizanButton(
                  text: l10n.continueText,
                  isLoading: _isLoading,
                  onPressed: _showConfirmation,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
