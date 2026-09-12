import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_category_icon.dart';
import '../../../shared/widgets/mizan_text_field.dart';
import 'transactions_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  int _transactionType = 0; // 0 = Expense, 1 = Income
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'food';
  bool _isLoading = false;

  final List<Map<String, String>> _categories = const [
    {'key': 'food', 'name': 'مطاعم ومقاهي', 'icon': 'restaurant', 'color': '#F59E0B'},
    {'key': 'groceries', 'name': 'بقالة ومواد', 'icon': 'local_grocery_store', 'color': '#10B981'},
    {'key': 'transport', 'name': 'مواصلات ونقل', 'icon': 'directions_car', 'color': '#6366F1'},
    {'key': 'shopping', 'name': 'تسوق ومستلزمات', 'icon': 'shopping_bag', 'color': '#EC4899'},
    {'key': 'bills', 'name': 'فواتير وخدمات', 'icon': 'bolt', 'color': '#EAB308'},
    {'key': 'health', 'name': 'صحة وصيدليات', 'icon': 'medical_services', 'color': '#EF4444'},
    {'key': 'entertainment', 'name': 'ترفيه وأنشطة', 'icon': 'movie', 'color': '#8B5CF6'},
    {'key': 'other', 'name': 'أخرى', 'icon': 'more_horiz', 'color': '#6B7280'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;
    if (_merchantController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
      ref.invalidate(transactionsProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MizanAppBar(title: l10n.addTransaction),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Type Selector
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: l10n.expense,
                      isSelected: _transactionType == 0,
                      activeColor: AppColors.dangerRed,
                      onTap: () => setState(() => _transactionType = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      label: l10n.income,
                      isSelected: _transactionType == 1,
                      activeColor: AppColors.accentBrightGreen,
                      onTap: () => setState(() => _transactionType = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Large Numeric Amount Input
              Center(
                child: Column(
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: _transactionType == 0 ? AppColors.dangerRed : AppColors.accentBrightGreen,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.currencySar,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Merchant Field
              MizanTextField(
                controller: _merchantController,
                label: l10n.merchant,
                hint: 'البيك، جرير، أوبر...',
                prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
              ),
              const SizedBox(height: 20),

              // Category Picker Header
              Text(
                l10n.category,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // Categories Grid/Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['key'];
                  return ChoiceChip(
                    avatar: MizanCategoryIcon(
                      iconKey: cat['icon'],
                      colorHex: cat['color'],
                      size: 24,
                    ),
                    label: Text(cat['name']!),
                    selected: isSelected,
                    selectedColor: AppColors.primaryDeepGreen.withValues(alpha: 0.18),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat['key']!);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Notes Field
              MizanTextField(
                controller: _notesController,
                label: l10n.notes,
                hint: l10n.optional,
                prefixIcon: const Icon(Icons.edit_note_outlined, size: 20),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: MizanButton(
                  text: l10n.save,
                  isLoading: _isLoading,
                  onPressed: _save,
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

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
