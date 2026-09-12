import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../../commitments/presentation/commitments_provider.dart';
import '../../home/presentation/dashboard_provider.dart';
import '../data/models/field_confidence.dart';
import '../data/models/parsed_bank_transaction.dart';
import '../data/models/transaction_direction.dart';
import '../services/commitment_matcher_service.dart';

class ReviewDetectedTransactionScreen extends ConsumerStatefulWidget {
  final ParsedBankTransactionDto? transaction;

  const ReviewDetectedTransactionScreen({
    super.key,
    this.transaction,
  });

  @override
  ConsumerState<ReviewDetectedTransactionScreen> createState() => _ReviewDetectedTransactionScreenState();
}

class _ReviewDetectedTransactionScreenState extends ConsumerState<ReviewDetectedTransactionScreen> {
  late ParsedBankTransactionDto _tx;
  bool _isRawExpanded = false;
  bool _linkWithCommitment = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tx = widget.transaction ?? _sampleDetectedTx;
  }

  static final ParsedBankTransactionDto _sampleDetectedTx = ParsedBankTransactionDto(
    bank: 'AlRajhiBank',
    transactionType: 'PURCHASE',
    amount: 1250.00,
    merchant: 'AL RAJHI BANK LEASING',
    normalizedMerchant: 'AL RAJHI BANK LEASING',
    cardLast4: '4019',
    transactionDate: DateTime.now(),
    reportedBalance: 12845.50,
    referenceNumber: 'TX-984210',
    category: 'Car',
    confidence: const FieldConfidence(
      overall: 0.96,
      amount: 1.0,
      merchant: 0.95,
      date: 0.98,
      transactionType: 0.95,
    ),
    messageHash: 'hash-sample-123',
    rawMessagePreserved:
        'شراء عبر مدى: بمبلغ 1250.00 ر.س من بطاقة مدى *4019 لدى AL RAJHI BANK LEASING في 2026/09/11 09:15. الرصيد: 12845.50 ر.س. الرقم المرجعي: TX-984210.',
  );

  Future<void> _confirmAndSave(CommitmentMatchResult matchResult) async {
    setState(() => _isSaving = true);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    try {
      final dio = ref.read(dioProvider);

      // 1. Post to backend detected transaction endpoint (without raw message body)
      await dio.post('/transactions/detected', data: _tx.toJson(includeLocalRaw: false));

      // 2. If matched with commitment and user confirmed, mark commitment paid
      if (_linkWithCommitment && matchResult.hasMatch && matchResult.matchedCommitment != null) {
        final commitmentId = matchResult.matchedCommitment!.id;
        await ref.read(commitmentsProvider.notifier).markPaid(
              commitmentId,
              occurrenceId: matchResult.suggestedOccurrence?.id,
              actualAmount: _tx.amount,
            );
      }

      // 3. Invalidate dashboard
      ref.invalidate(dashboardProvider);

      if (mounted) {
        final successMsg = _tx.isIncome
            ? (isArabic ? 'تمت إضافة المبلغ إلى رصيد حسابك بنجاح (+)' : 'Added to account balance successfully (+)')
            : (_linkWithCommitment && matchResult.hasMatch
                ? (isArabic ? 'تم حفظ العملية وتحديث حالة الالتزام إلى مسدد!' : 'Saved transaction and marked commitment as paid!')
                : (isArabic ? 'تم تأكيد وحفظ العملية بنجاح' : 'Transaction confirmed and saved'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: AppColors.primaryDeepGreen,
          ),
        );
        context.pop();
      }
    } catch (_) {
      // Offline fallback
      if (mounted) {
        if (_linkWithCommitment && matchResult.hasMatch && matchResult.matchedCommitment != null) {
          ref.read(commitmentsProvider.notifier).markPaid(matchResult.matchedCommitment!.id);
        }
        ref.invalidate(dashboardProvider);
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final commitments = ref.watch(commitmentsProvider).value ?? [];
    final matchResult = CommitmentMatcherService.match(
      transaction: _tx,
      activeCommitments: commitments,
    );

    return Scaffold(
      appBar: MizanAppBar(
        title: isArabic ? 'مراجعة العملية المرصودة' : 'Review Detected Transaction',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Privacy Badge Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryDeepGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 18, color: AppColors.primaryDeepGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.localPrivacyNotice,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bank & Amount Main Card
              MizanCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.account_balance, size: 16, color: AppColors.primaryDeepGreen),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _tx.bank,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.primaryDeepGreen,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Confidence Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(_tx.confidence.overall * 100).toInt()}% ${isArabic ? 'دقة الرصد' : 'Confidence'}',
                            style: const TextStyle(
                              color: AppColors.primaryDeepGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${_tx.isIncome ? '+' : '-'} ${_tx.amount.toStringAsFixed(2)} ${l10n.currencySar}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _tx.isIncome ? AppColors.accentBrightGreen : AppColors.primaryDeepGreen,
                      ),
                    ),
                    if (_tx.isIncome) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isArabic ? 'إيداع — سيتم إضافته إلى رصيد حسابك (+)' : 'Income — will be added to your balance (+)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDeepGreen,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _tx.merchant,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Details grid
                    _buildDetailRow(
                      isArabic ? 'نوع العملية' : 'Transaction Type',
                      _getLocalizedTransactionType(_tx.transactionType, isArabic),
                      _tx.isIncome ? Icons.trending_up : Icons.payment,
                    ),
                    const SizedBox(height: 10),
                    if (_tx.fee > 0) ...[
                      _buildDetailRow(
                        isArabic ? 'المبلغ الأساسي' : 'Principal Amount',
                        '${_tx.amount.toStringAsFixed(2)} ${l10n.currencySar}',
                        Icons.payments_outlined,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        isArabic ? 'رسوم العملية' : 'Fee',
                        '${_tx.fee.toStringAsFixed(2)} ${l10n.currencySar}',
                        Icons.receipt_outlined,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        isArabic ? 'إجمالي الخصم' : 'Total Debit',
                        '${_tx.totalDebit.toStringAsFixed(2)} ${l10n.currencySar}',
                        Icons.calculate_outlined,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_tx.biller != null || _tx.billerCode != null) ...[
                      _buildDetailRow(
                        isArabic ? 'المفوتر' : 'Biller',
                        '${_tx.biller ?? ''} ${_tx.billerCode != null ? "(${_tx.billerCode})" : ""}'.trim(),
                        Icons.business,
                      ),
                      const SizedBox(height: 10),
                      if (_tx.service != null) ...[
                        _buildDetailRow(
                          isArabic ? 'الخدمة' : 'Service',
                          _tx.service!,
                          Icons.miscellaneous_services,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_tx.billNumber != null) ...[
                        _buildDetailRow(
                          isArabic ? 'رقم الفاتورة' : 'Bill Number',
                          _tx.billNumber!,
                          Icons.receipt,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                    if (_tx.recipientName != null) ...[
                      _buildDetailRow(
                        isArabic ? 'المستلم' : 'Recipient',
                        _tx.recipientName!,
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_tx.destinationBank != null) ...[
                      _buildDetailRow(
                        isArabic ? 'البنك المحول إليه' : 'Destination Bank',
                        _tx.destinationBank!,
                        Icons.account_balance,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_tx.cardLast4 != null || _tx.accountSuffix != null) ...[
                      _buildDetailRow(
                        _tx.isIncome
                            ? (isArabic ? 'إلى حساب' : 'To Account')
                            : (isArabic ? 'الحساب / البطاقة' : 'Account / Card'),
                        '•••• ${_tx.accountSuffix ?? _tx.cardLast4}',
                        Icons.credit_card,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildDetailRow(
                      isArabic ? 'التاريخ والوقت' : 'Date & Time',
                      '${_tx.transactionDate.year}-${_tx.transactionDate.month.toString().padLeft(2, '0')}-${_tx.transactionDate.day.toString().padLeft(2, '0')}',
                      Icons.access_time,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      isArabic ? 'مكان العملية' : 'Location',
                      _tx.location?.placeName ?? (isArabic ? 'الموقع غير متوفر لهذه العملية' : 'Location unavailable'),
                      Icons.location_on_outlined,
                    ),
                    if (_tx.reportedBalance != null) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        isArabic ? 'الرصيد بعد العملية' : 'Balance After',
                        '${_tx.reportedBalance!.toStringAsFixed(2)} ${l10n.currencySar}',
                        Icons.account_balance_wallet,
                      ),
                    ],
                    if (_tx.referenceNumber != null) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        isArabic ? 'الرقم المرجعي / المخالفة' : 'Reference Number',
                        _tx.referenceNumber!,
                        Icons.tag,
                      ),
                    ],
                  ],
                ),
              ),
              // Salary Candidate Confirmation Prompt
              if (_tx.salaryCandidate && _tx.transactionType != 'SALARY') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.work_outline, color: Color(0xFFB45309), size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic ? 'اكتشاف راتب محتمل' : 'Potential Salary Detected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic
                            ? 'يبدو أن هذا المبلغ راتبك الشهري. هل تريد اعتباره راتبًا؟'
                            : 'This transaction looks like your monthly salary. Would you like to categorize it as Salary?',
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDeepGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _tx = ParsedBankTransactionDto(
                                    schemaVersion: _tx.schemaVersion,
                                    source: _tx.source,
                                    bank: _tx.bank,
                                    transactionType: 'SALARY',
                                    direction: TransactionDirection.inDir,
                                    amount: _tx.amount,
                                    fee: _tx.fee,
                                    tax: _tx.tax,
                                    cashback: _tx.cashback,
                                    totalDebit: 0.0,
                                    totalCredit: _tx.amount,
                                    currency: _tx.currency,
                                    merchant: 'راتب شهري',
                                    normalizedMerchant: 'SALARY',
                                    cardLast4: _tx.cardLast4,
                                    sourceAccount: _tx.sourceAccount,
                                    destinationAccount: _tx.destinationAccount,
                                    destinationBank: _tx.destinationBank,
                                    recipientName: _tx.recipientName,
                                    billerCode: _tx.billerCode,
                                    biller: _tx.biller,
                                    service: _tx.service,
                                    billNumber: _tx.billNumber,
                                    paymentMethod: _tx.paymentMethod,
                                    salaryCandidate: false,
                                    transactionDate: _tx.transactionDate,
                                    reportedBalance: _tx.reportedBalance,
                                    referenceNumber: _tx.referenceNumber,
                                    category: 'Salary',
                                    subcategory: 'Monthly Salary',
                                    confidence: _tx.confidence,
                                    messageHash: _tx.messageHash,
                                    rawMessagePreserved: _tx.rawMessagePreserved,
                                  );
                                });
                              },
                              child: Text(isArabic ? 'نعم، اعتبره راتبًا' : 'Yes, mark as Salary'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _tx = ParsedBankTransactionDto(
                                    schemaVersion: _tx.schemaVersion,
                                    source: _tx.source,
                                    bank: _tx.bank,
                                    transactionType: _tx.transactionType,
                                    direction: _tx.direction,
                                    amount: _tx.amount,
                                    fee: _tx.fee,
                                    tax: _tx.tax,
                                    cashback: _tx.cashback,
                                    totalDebit: _tx.totalDebit,
                                    totalCredit: _tx.totalCredit,
                                    currency: _tx.currency,
                                    merchant: _tx.merchant,
                                    normalizedMerchant: _tx.normalizedMerchant,
                                    cardLast4: _tx.cardLast4,
                                    sourceAccount: _tx.sourceAccount,
                                    destinationAccount: _tx.destinationAccount,
                                    destinationBank: _tx.destinationBank,
                                    recipientName: _tx.recipientName,
                                    billerCode: _tx.billerCode,
                                    biller: _tx.biller,
                                    service: _tx.service,
                                    billNumber: _tx.billNumber,
                                    paymentMethod: _tx.paymentMethod,
                                    salaryCandidate: false,
                                    transactionDate: _tx.transactionDate,
                                    reportedBalance: _tx.reportedBalance,
                                    referenceNumber: _tx.referenceNumber,
                                    category: _tx.category,
                                    subcategory: _tx.subcategory,
                                    confidence: _tx.confidence,
                                    messageHash: _tx.messageHash,
                                    rawMessagePreserved: _tx.rawMessagePreserved,
                                  );
                                });
                              },
                              child: Text(isArabic ? 'لا' : 'No'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Matched Commitment Card (if detected)
              if (matchResult.hasMatch && matchResult.matchedCommitment != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentBrightGreen.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link, color: AppColors.primaryDeepGreen, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic ? 'مطابقة ذكية مع التزام مسجل!' : 'Smart Commitment Match!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primaryDeepGreen,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDeepGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(matchResult.confidence * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic ? matchResult.promptAr : matchResult.promptEn,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: _linkWithCommitment,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeThumbColor: AppColors.primaryDeepGreen,
                        title: Text(
                          isArabic ? 'تحديث حالة الالتزام إلى "مسدد" فوراً' : 'Mark commitment as paid immediately',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onChanged: (val) => setState(() => _linkWithCommitment = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Collapsible Local Raw SMS Card
              if (_tx.rawMessagePreserved != null) ...[
                MizanCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isRawExpanded = !_isRawExpanded),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.sms_outlined, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isArabic ? 'الرسالة البنكية الأصلية (محلياً)' : 'Original Bank SMS (Local)',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(_isRawExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                          ],
                        ),
                      ),
                      if (_isRawExpanded) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _tx.rawMessagePreserved!,
                            style: const TextStyle(fontSize: 12, height: 1.5, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: MizanButton(
                  text: isArabic ? 'تأكيد وحفظ العملية' : 'Confirm & Save Transaction',
                  isLoading: _isSaving,
                  onPressed: () => _confirmAndSave(matchResult),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: MizanButton(
                  text: l10n.dismiss,
                  isOutlined: true,
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getLocalizedTransactionType(String type, bool isArabic) {
    if (isArabic) {
      switch (type) {
        case 'SALARY':
          return 'راتب شهري (إيداع في الرصيد)';
        case 'TRANSFER_IN':
          return 'حوالة واردة (إيداع في الرصيد)';
        case 'DEPOSIT':
          return 'إيداع نقدي (إضافة للرصيد)';
        case 'REFUND':
          return 'استرداد (إضافة للرصيد)';
        case 'LOCAL_TRANSFER':
          return 'حوالة محلية (خصم)';
        case 'TRANSFER_OUT':
          return 'حوالة صادرة (خصم)';
        case 'BILL_PAYMENT':
          return 'سداد فاتورة (خصم)';
        case 'TRAFFIC_FINE':
          return 'مخالفة مرورية (خصم)';
        case 'GOVERNMENT_PAYMENT':
          return 'مدفوعات حكومية (خصم)';
        case 'POS_PURCHASE':
          return 'شراء عبر نقاط البيع (خصم)';
        case 'ONLINE_PURCHASE':
          return 'شراء إلكتروني (خصم)';
        case 'ATM_WITHDRAWAL':
          return 'سحب نقدي (خصم)';
        case 'SUBSCRIPTION':
          return 'اشتراك دوري (خصم)';
        case 'FEE':
          return 'رسوم بنكية (خصم)';
        default:
          return 'عملية شراء (خصم)';
      }
    } else {
      switch (type) {
        case 'SALARY':
          return 'Salary (Income)';
        case 'TRANSFER_IN':
          return 'Transfer In (Income)';
        case 'DEPOSIT':
          return 'Deposit (Income)';
        case 'REFUND':
          return 'Refund (Income)';
        case 'LOCAL_TRANSFER':
          return 'Local Transfer (Debit)';
        case 'TRAFFIC_FINE':
          return 'Traffic Fine (Debit)';
        case 'BILL_PAYMENT':
          return 'Bill Payment (Debit)';
        case 'POS_PURCHASE':
          return 'POS Purchase (Debit)';
        case 'ONLINE_PURCHASE':
          return 'Online Purchase (Debit)';
        default:
          return type;
      }
    }
  }
}
