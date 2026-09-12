import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/mizan_app_bar.dart';
import '../../../shared/widgets/mizan_button.dart';
import '../../../shared/widgets/mizan_card.dart';
import '../data/models/parsed_bank_transaction.dart';
import '../parsers/bank_parser_factory.dart';
import '../services/message_classifier.dart';
import 'review_detected_transaction_screen.dart';

class ParserDebugScreen extends StatefulWidget {
  const ParserDebugScreen({super.key});

  @override
  State<ParserDebugScreen> createState() => _ParserDebugScreenState();
}

class _ParserDebugScreenState extends State<ParserDebugScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _senderController = TextEditingController();

  ParsedBankTransactionDto? _parsedResult;
  MessageClassification _classification = MessageClassification.other;
  String _usedParserName = 'None';
  bool _hasAnalyzed = false;

  final List<Map<String, String>> _samplePresets = [
    {
      'label': '1. إيداع راتب / دخل (6,960.45 SAR)',
      'sender': 'SAIB',
      'text': 'مبلغ: SAR 6,960.45\nالى: XXX2001\nفي: 08-25 09:22',
    },
    {
      'label': '2. سداد فاتورة زين (171.35 SAR)',
      'sender': 'SADAD',
      'text': 'سداد فاتورة\nمن: XXX2001\nالمبلغ: SAR 171.35\nمفوتر: 044 زين\nخدمة:الاتصالات والانترنت\nرقم الفاتورة: 831032470841\nفي: 08-26 00:34',
    },
    {
      'label': '3. مخالفة مرورية (100 SAR - TRF)',
      'sender': 'MOI-Traffic',
      'text': 'حوالة صادرة: محلية\nمن: XXX2001\nمبلغ: SAR 100\nرسوم: SAR 0\nفي: 09-01 20:21\nبناء على المادة رقم (75) من نظام المرور للمخالفة TRF 48100009799845',
    },
    {
      'label': '4. تحويل محلي مع رسوم (15.58 SAR)',
      'sender': 'AlRajhiBank',
      'text': 'حوالة محلية\nالمصرف RJHI\nالمبلغ SAR 15\nمن X2001\nالى: عبدالعزيز محمد القحط\nالى X6980\nالرسوم SAR 0.58\nفي 09-08 21:20',
    },
    {
      'label': '5. شراء POS مذاق (11.05 SAR)',
      'sender': 'Alinma',
      'text': 'شراء POS\nبSAR 11.05\nمن MATHAQ A\nمدى سامسونج X3232',
    },
    {
      'label': 'الراجحي - شراء مدى',
      'sender': 'AlRajhiBank',
      'text': 'شراء عبر مدى: بمبلغ 1250.00 ر.س من بطاقة مدى *4019 لدى AL RAJHI BANK LEASING في 2026/09/11 09:15. الرصيد: 12845.50 ر.س. الرقم المرجعي: TX-984210.',
    },
    {
      'label': 'الأهلي SNB - شراء',
      'sender': 'SNB',
      'text': 'عملية شراء بمبلغ 145.25 ر.س من بطاقتك مدى المنتهية بـ 8831 لدى PANDA STORES بتاريخ 10/09/2026 18:20. رصيدك الحالي: 5430.00 ر.س.',
    },
    {
      'label': 'بنك الرياض - سداد',
      'sender': 'RiyadBank',
      'text': 'تم سداد فاتورة سداد بمبلغ 290.00 ر.س من حسابك الجاري لدى STC Telecom بتاريخ 08/09/2026. الرصيد: 8910.00 ر.س.',
    },
    {
      'label': 'مصرف الإنماء - سحب',
      'sender': 'Alinma',
      'text': 'سحب نقدي من صراف آلي بمبلغ 500.00 ر.س باستخدام بطاقة مدى *6102 بتاريخ 2026/09/09 14:00. رصيدك المتاح: 3200.00 ر.س.',
    },
    {
      'label': 'البنك الأول SAB',
      'sender': 'SAB',
      'text': 'Purchase of SAR 85.50 with SAB credit card ending 1204 at JARIR BOOKSTORE on 11/09/2026. Avail Limit: SAR 15400.00.',
    },
    {
      'label': 'الاستثمار SAIB',
      'sender': 'SAIB',
      'text': 'تمت عملية شراء عبر بطاقة الاستثمار مدى *9942 بمبلغ 320.00 ر.س لدى EXTRA STORES في 11/09/2026 12:40. الرصيد: 9800.00 ر.س.',
    },
    {
      'label': 'STC Bank',
      'sender': 'STCBank',
      'text': 'عملية دفع ناجحة عبر بطاقة STC Bank رقم *5512 بمبلغ 68.00 ر.س لدى BARN\'S COFFEE بتاريخ 11/09/2026. الرصيد: 1420.50 ر.س.',
    },
    {
      'label': 'بنك عام Generic',
      'sender': 'BankAlert',
      'text': 'تم تنفيذ عملية شراء بمبلغ 210.00 ريال لدى متجر نون للتجارة بتاريخ 2026/09/10.',
    },
    {
      'label': 'رسالة أمان OTP (مرفوضة)',
      'sender': 'AlRajhiBank',
      'text': 'رمز التحقق لمرة واحدة (OTP) لتسجيل الدخول إلى المباشر للأفراد هو: 984120. لا تشارك هذا الرمز مع أي شخص حتى موظفي البنك.',
    },
    {
      'label': 'رسالة تسويقية (مرفوضة)',
      'sender': 'PromoBank',
      'text': 'عرض حصري! احصل على تمويل شخصي بهامش ربح يبدأ من 1.99% مع إمكانية تأجيل القسط الأول. للتقديم أرسل 1 إلى 50505.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPreset(_samplePresets.first);
  }

  void _loadPreset(Map<String, String> preset) {
    setState(() {
      _textController.text = preset['text']!;
      _senderController.text = preset['sender']!;
      _hasAnalyzed = false;
      _parsedResult = null;
    });
  }

  void _analyzeMessage() {
    final text = _textController.text.trim();
    final sender = _senderController.text.trim();

    if (text.isEmpty) return;

    final classification = MessageClassifier.classify(text);
    final parser = BankMessageParserFactory.getParser(text, sender: sender);
    final result = BankMessageParserFactory.parse(text, sender: sender);

    setState(() {
      _hasAnalyzed = true;
      _classification = classification;
      _usedParserName = parser.bankDisplayNameAr;
      _parsedResult = result;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MizanAppBar(
        title: isArabic ? 'مختبر معالجة الرسائل البنكية' : 'Bank Parser Playground',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Presets selector
              Text(
                isArabic ? 'نماذج رسائل بنكية جاهزة للاختبار:' : 'Sample Bank SMS Presets:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _samplePresets.map((p) {
                    final isSelected = _textController.text == p['text'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(p['label']!),
                        selected: isSelected,
                        selectedColor: AppColors.primaryDeepGreen.withValues(alpha: 0.18),
                        checkmarkColor: AppColors.primaryDeepGreen,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryDeepGreen : null,
                        ),
                        onSelected: (_) => _loadPreset(p),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Sender input
              Text(
                isArabic ? 'اسم المرسل (Sender ID):' : 'Sender ID:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _senderController,
                decoration: const InputDecoration(
                  hintText: 'e.g. AlRajhiBank, SNB, RiyadBank, SAIB, STCBank...',
                  prefixIcon: Icon(Icons.send_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 14),

              // SMS Text Input
              Text(
                isArabic ? 'نص الرسالة البنكية:' : 'Bank SMS Body:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isArabic ? 'ألصق أو اكتب أي رسالة بنكية هنا...' : 'Paste or type any bank SMS here...',
                ),
              ),
              const SizedBox(height: 16),

              // Analyze Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: MizanButton(
                  text: isArabic ? 'تحليل الرسالة ومطابقتها' : 'Analyze & Parse Message',
                  icon: const Icon(Icons.psychology, size: 20, color: Colors.white),
                  onPressed: _analyzeMessage,
                ),
              ),
              const SizedBox(height: 20),

              // Results Section
              if (_hasAnalyzed) ...[
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  isArabic ? 'نتائج الفحص والتحليل:' : 'Analysis Results:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),

                // Status Chips Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildClassificationBadge(_classification, isArabic),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'المعالج: $_usedParserName',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDeepGreen,
                        ),
                      ),
                    ),
                    if (_parsedResult != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentBrightGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'الدقة الإجمالية: ${(_parsedResult!.confidence.overall * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDeepGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_parsedResult != null) ...[
                  // Parsed Card Preview
                  MizanCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _parsedResult!.bank,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${_parsedResult!.amount.toStringAsFixed(2)} ${_parsedResult!.currency}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDeepGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${isArabic ? 'المتجر:' : 'Merchant:'} ${_parsedResult!.merchant}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isArabic ? 'النوع:' : 'Type:'} ${_parsedResult!.transactionType}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (_parsedResult!.cardLast4 != null)
                          Text(
                            '${isArabic ? 'البطاقة:' : 'Card:'} **** ${_parsedResult!.cardLast4}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        if (_parsedResult!.reportedBalance != null)
                          Text(
                            '${isArabic ? 'الرصيد المبلغ:' : 'Balance:'} ${_parsedResult!.reportedBalance!.toStringAsFixed(2)} SAR',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // JSON Tree Output
                  MizanCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'JSON Output (Schema 1.0):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                            ),
                            Text(
                              isArabic ? 'محلي 100%' : '100% Local',
                              style: const TextStyle(fontSize: 11, color: AppColors.primaryDeepGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            const JsonEncoder.withIndent('  ').convert(_parsedResult!.toStructuredJson()),
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              fontFamily: 'monospace',
                              color: Color(0xFF22C55E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Button to preview full review screen
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: MizanButton(
                      text: isArabic ? 'فتح تجربة شاشة المراجعة' : 'Open Review Screen',
                      isOutlined: true,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReviewDetectedTransactionScreen(transaction: _parsedResult),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Rejection Notice Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _classification == MessageClassification.otp
                          ? Colors.amber.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _classification == MessageClassification.otp
                            ? Colors.amber.shade300
                            : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _classification == MessageClassification.otp
                              ? Icons.security
                              : Icons.block,
                          color: _classification == MessageClassification.otp
                              ? Colors.amber.shade800
                              : Colors.red.shade800,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _classification == MessageClassification.otp
                              ? (isArabic
                                  ? 'تم استبعاد الرسالة تلقائياً لأنها رمز تحقق أمني (OTP) ولا تعتبر معاملة مالية.'
                                  : 'Message rejected: Classified as security OTP, not a financial transaction.')
                              : (isArabic
                                  ? 'تم استبعاد الرسالة لأنها إعلان تسويقي أو غير صالحة كمعاملة مالية.'
                                  : 'Message rejected: Classified as marketing promotion or ineligible.'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _classification == MessageClassification.otp
                                  ? Colors.amber.shade900
                                  : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassificationBadge(MessageClassification cls, bool isArabic) {
    Color bg;
    Color text;
    String label;

    switch (cls) {
      case MessageClassification.financialTransaction:
        bg = Colors.green.shade100;
        text = Colors.green.shade800;
        label = isArabic ? 'عملية مالية مؤكدة' : 'Transaction';
        break;
      case MessageClassification.otp:
        bg = Colors.amber.shade100;
        text = Colors.amber.shade900;
        label = isArabic ? 'رمز أمان OTP (مستبعد)' : 'Security OTP';
        break;
      case MessageClassification.securityAlert:
        bg = Colors.amber.shade100;
        text = Colors.amber.shade900;
        label = isArabic ? 'تنبيه أمني (مستبعد)' : 'Security Alert';
        break;
      case MessageClassification.marketing:
        bg = Colors.red.shade100;
        text = Colors.red.shade900;
        label = isArabic ? 'رسالة تسويقية (مستبعد)' : 'Marketing';
        break;
      case MessageClassification.failedTransaction:
        bg = Colors.red.shade100;
        text = Colors.red.shade900;
        label = isArabic ? 'عملية مرفوضة / فاشلة' : 'Failed Transaction';
        break;
      case MessageClassification.balanceInformation:
        bg = Colors.blue.shade100;
        text = Colors.blue.shade900;
        label = isArabic ? 'استعلام رصيد فقط' : 'Balance Inquiry';
        break;
      default:
        bg = Colors.grey.shade200;
        text = Colors.black87;
        label = isArabic ? 'غير محدد' : 'Other';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
