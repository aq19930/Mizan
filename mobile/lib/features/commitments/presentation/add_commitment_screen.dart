import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import 'commitments_provider.dart';

class AddCommitmentScreen extends ConsumerStatefulWidget {
  const AddCommitmentScreen({super.key});

  @override
  ConsumerState<AddCommitmentScreen> createState() => _AddCommitmentScreenState();
}

class _AddCommitmentScreenState extends ConsumerState<AddCommitmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Housing';
  String _selectedFrequency = 'Monthly';
  String _selectedPriority = 'Medium';
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'id': 'Housing', 'nameAr': 'سكن وإيجار', 'nameEn': 'Housing / Rent', 'icon': 'home'},
    {'id': 'Car', 'nameAr': 'قسط سيارة', 'nameEn': 'Car Installment', 'icon': 'directions_car'},
    {'id': 'Loan', 'nameAr': 'تمويل / قرض', 'nameEn': 'Personal Loan', 'icon': 'account_balance'},
    {'id': 'CreditCard', 'nameAr': 'بطاقة ائتمانية', 'nameEn': 'Credit Card', 'icon': 'credit_card'},
    {'id': 'Utilities', 'nameAr': 'كهرباء ومياه', 'nameEn': 'Utilities', 'icon': 'bolt'},
    {'id': 'Telecommunications', 'nameAr': 'اتصالات وإنترنت', 'nameEn': 'Telecom & Internet', 'icon': 'phone_android'},
    {'id': 'Insurance', 'nameAr': 'تأمين', 'nameEn': 'Insurance', 'icon': 'verified_user'},
    {'id': 'Subscriptions', 'nameAr': 'اشتراكات دورية', 'nameEn': 'Subscriptions', 'icon': 'subscriptions'},
    {'id': 'Education', 'nameAr': 'تعليم ودراسة', 'nameEn': 'Education', 'icon': 'school'},
    {'id': 'Family', 'nameAr': 'التزامات عائلية', 'nameEn': 'Family Support', 'icon': 'family_restroom'},
    {'id': 'BNPL', 'nameAr': 'تقسيط (تمارا / تابي)', 'nameEn': 'BNPL (Tamara/Tabby)', 'icon': 'shopping_bag'},
    {'id': 'GovernmentFees', 'nameAr': 'رسوم حكومية', 'nameEn': 'Government Fees', 'icon': 'receipt_long'},
    {'id': 'Healthcare', 'nameAr': 'رعاية صحية', 'nameEn': 'Healthcare', 'icon': 'medical_services'},
    {'id': 'Other', 'nameAr': 'أخرى', 'nameEn': 'Other', 'icon': 'more_horiz'},
  ];

  final List<Map<String, String>> _frequencies = [
    {'id': 'Monthly', 'nameAr': 'شهرياً', 'nameEn': 'Monthly'},
    {'id': 'Weekly', 'nameAr': 'أسبوعياً', 'nameEn': 'Weekly'},
    {'id': 'Quarterly', 'nameAr': 'ربع سنوي (كل 3 أشهر)', 'nameEn': 'Quarterly'},
    {'id': 'SemiAnnual', 'nameAr': 'نصف سنوي', 'nameEn': 'Semi-Annual'},
    {'id': 'Annual', 'nameAr': 'سنوياً', 'nameEn': 'Annual'},
    {'id': 'OneTime', 'nameAr': 'مرة واحدة', 'nameEn': 'One-Time'},
  ];

  final List<Map<String, String>> _priorities = [
    {'id': 'Low', 'nameAr': 'منخفضة', 'nameEn': 'Low'},
    {'id': 'Medium', 'nameAr': 'متوسطة', 'nameEn': 'Medium'},
    {'id': 'High', 'nameAr': 'عالية', 'nameEn': 'High'},
    {'id': 'Critical', 'nameAr': 'حرجة جداً', 'nameEn': 'Critical'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDeepGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.darkTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبلغ صحيح أكبر من الصفر'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(commitmentsProvider.notifier).addCommitment(
            title: _titleController.text.trim(),
            category: _selectedCategory,
            amount: amount,
            frequency: _selectedFrequency,
            dueDate: _selectedDueDate,
            priority: _selectedPriority,
            merchant: _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );

      if (mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تمت إضافة الالتزام بنجاح' : 'Commitment added successfully'),
            backgroundColor: AppColors.primaryDeepGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: isArabic ? 'إضافة التزام مالي' : 'Add Commitment',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryDeepGreen.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primaryDeepGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'الالتزامات تحجز مبالغها من المتاح للصرف، ولا تخصم كنفقة فعلية حتى يتم رصد الحوالة أو السداد.'
                              : 'Commitments are reserved from Available Spend and recorded as expenses only upon actual payment.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title Input
                Text(
                  isArabic ? 'عنوان الالتزام *' : 'Commitment Title *',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'مثال: قسط السيارة، إيجار الشقة، فاتورة STC' : 'e.g. Car Installment, Rent, Internet Bill',
                    prefixIcon: const Icon(Icons.edit_note, color: AppColors.primaryDeepGreen),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isArabic ? 'يرجى إدخال عنوان الالتزام' : 'Please enter title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Amount & Due Date row
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'المبلغ المستحق *' : 'Amount *',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              hintText: '0.00',
                              suffixText: l10n.currencySar,
                              prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primaryDeepGreen),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return isArabic ? 'أدخل المبلغ' : 'Enter amount';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'تاريخ الاستحقاق *' : 'Due Date *',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDueDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: AppColors.primaryDeepGreen, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Category Selection
                Text(
                  isArabic ? 'تصنيف الالتزام *' : 'Category *',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined, color: AppColors.primaryDeepGreen),
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(isArabic ? c['nameAr']! : c['nameEn']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 18),

                // Frequency & Priority row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'دورية السداد' : 'Frequency',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedFrequency,
                            items: _frequencies.map((f) {
                              return DropdownMenuItem<String>(
                                value: f['id'],
                                child: Text(isArabic ? f['nameAr']! : f['nameEn']!),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedFrequency = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'الأولوية' : 'Priority',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedPriority,
                            items: _priorities.map((p) {
                              return DropdownMenuItem<String>(
                                value: p['id'],
                                child: Text(isArabic ? p['nameAr']! : p['nameEn']!),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPriority = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Merchant / Payee
                Text(
                  isArabic ? 'الجهة المستفيدة / المتجر (اختياري)' : 'Merchant / Payee (Optional)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'مثال: بنك الراجحي، STC، تمارا، شركة الكهرباء' : 'e.g. Al Rajhi Bank, STC, Tamara',
                    prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.primaryDeepGreen),
                  ),
                ),
                const SizedBox(height: 18),

                // Notes
                Text(
                  isArabic ? 'ملاحظات إضافية (اختياري)' : 'Notes (Optional)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'رقم العقد، تفاصيل الحساب، إلخ...' : 'Contract number, reference, notes...',
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: MizanButton(
                    text: isArabic ? 'حفظ الالتزام المالي' : 'Save Commitment',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
