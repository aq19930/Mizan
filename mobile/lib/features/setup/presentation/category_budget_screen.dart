import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../../shared/widgets/mizan_category_icon.dart';

class CategoryBudgetScreen extends StatefulWidget {
  const CategoryBudgetScreen({super.key});

  @override
  State<CategoryBudgetScreen> createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends State<CategoryBudgetScreen> {
  final Map<String, double> _allocations = {
    'food': 1800,
    'groceries': 1400,
    'transport': 800,
    'shopping': 1000,
    'bills': 1000,
  };

  final List<_CategoryDef> _categories = const [
    _CategoryDef('food', 'مطاعم ومقاهي', 'Food & Dining', 'restaurant', '#F59E0B'),
    _CategoryDef('groceries', 'بقالة ومواد', 'Groceries', 'local_grocery_store', '#10B981'),
    _CategoryDef('transport', 'مواصلات ونقل', 'Transportation', 'directions_car', '#6366F1'),
    _CategoryDef('shopping', 'تسوق ومستلزمات', 'Shopping', 'shopping_bag', '#EC4899'),
    _CategoryDef('bills', 'فواتير وخدمات', 'Bills & Telecom', 'bolt', '#EAB308'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MizanAppBar(title: '${l10n.setupStepCategories} (5/7)'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 5 / 7,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDeepGreen),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.categoryBudgetTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.categoryBudgetDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final currentVal = _allocations[cat.key] ?? 1000;

                    return MizanCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              MizanCategoryIcon(
                                iconKey: cat.icon,
                                colorHex: cat.colorHex,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cat.nameAr,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                '${currentVal.toStringAsFixed(0)} ${l10n.currencySar}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDeepGreen,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: currentVal,
                            min: 200,
                            max: 5000,
                            divisions: 24,
                            activeColor: AppColors.primaryDeepGreen,
                            onChanged: (val) {
                              setState(() {
                                _allocations[cat.key] = val;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: MizanButton(
                  text: l10n.continueText,
                  onPressed: () {
                    context.push(AppRoutes.setupNotifications);
                  },
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

class _CategoryDef {
  final String key;
  final String nameAr;
  final String nameEn;
  final String icon;
  final String colorHex;

  const _CategoryDef(this.key, this.nameAr, this.nameEn, this.icon, this.colorHex);
}
