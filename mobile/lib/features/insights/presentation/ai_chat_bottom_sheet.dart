import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/ai_models.dart';
import 'ai_providers.dart';

class MizanAiChatBottomSheet extends ConsumerStatefulWidget {
  const MizanAiChatBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MizanAiChatBottomSheet(),
    );
  }

  @override
  ConsumerState<MizanAiChatBottomSheet> createState() => _MizanAiChatBottomSheetState();
}

class _MizanAiChatBottomSheetState extends ConsumerState<MizanAiChatBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'كيف وضعي المالي هذا الشهر؟',
    'كم أقدر أصرف يوميًا؟',
    'ما الالتزامات القادمة؟',
    'لو أخذت قرض، هل راح يضغط ميزانيتي؟',
    'رتب لي ميزانيتي حتى نهاية الشهر.',
    'هل أقدر أشتري جوال بـ 4,500؟',
    'وش أكثر شيء أصرف عليه؟',
    'كيف أخفض مصروفي 10%؟',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F4D3A), Color(0xFF1B6B52)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.accentBrightGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مساعد ميزان',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'مساعدك المالي الذكي المبني على بياناتك المعتمدة',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Suggested chips carousel
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return ActionChip(
                  label: Text(
                    _suggestedPrompts[i],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: isDark ? const Color(0xFF1A332B) : const Color(0xFFE8F2EC),
                  labelStyle: TextStyle(
                    color: isDark ? AppColors.accentBrightGreen : AppColors.primaryDeepGreen,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onPressed: () => _send(_suggestedPrompts[i]),
                );
              },
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chatState.messages.length,
              itemBuilder: (context, i) {
                final msg = chatState.messages[i];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDeepGreen),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ميزان يحلل البيانات المالية...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: 'وش ودك تعرف عن وضعك المالي؟',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2824) : const Color(0xFFF5F2EA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryDeepGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _send(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIChatMessageModel msg, bool isDark) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F4D3A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.accentBrightGreen, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primaryDeepGreen
                        : (isDark ? const Color(0xFF1F2923) : const Color(0xFFF3F0E6)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),

                // Structured Visual Cards (Section 93 & 114)
                if (msg.cards.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final card in msg.cards) _buildVisualCard(card, isDark),
                ],

                // Action Confirmation Button
                if (msg.suggestedActions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final action in msg.suggestedActions)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeepGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(action.labelAr),
                      onPressed: () {
                        _showConfirmationDialog(context, action);
                      },
                    ),
                ],

                // Calculation References
                if (msg.calculationReferences.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final ref in msg.calculationReferences)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📐 $ref',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualCard(StructuredAICardModel card, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26332C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryDeepGreen.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment_outlined, color: AppColors.primaryDeepGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card.titleAr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          for (final entry in card.data.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _translateKey(entry.key),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _translateKey(String key) {
    switch (key) {
      case 'loanAmount': return 'مبلغ التمويل:';
      case 'durationMonths': return 'المدة بالشهور:';
      case 'monthlyInstallment': return 'القسط الشهري:';
      case 'commitmentRatioBefore': return 'نسبة الالتزامات قبل:';
      case 'commitmentRatioAfter': return 'نسبة الالتزامات بعد:';
      case 'ratingAr': return 'التقييم:';
      case 'totalAmount': return 'المبلغ الإجمالي:';
      case 'count': return 'العدد:';
      case 'availableAfter': return 'المتاح للصرف:';
      case 'currentBalance': return 'الرصيد الفعلي:';
      case 'reservedCommitments': return 'الالتزامات المحجوزة:';
      case 'availableToSpend': return 'المتاح للصرف:';
      case 'currentDaily': return 'الصرف اليومي الحالي:';
      case 'optimizedDaily': return 'الصرف اليومي المقترح:';
      case 'savingsIncrease': return 'الزيادة في الادخار:';
      case 'optimizedSavings': return 'المستهدف الشهري:';
      case 'dailyLimit': return 'الحد اليومي:';
      case 'monthlySavings': return 'الادخار الشهري:';
      case 'purchaseAmount': return 'مبلغ الشراء:';
      case 'availableBefore': return 'السيولة قبل:';
      default: return key;
    }
  }

  void _showConfirmationDialog(BuildContext context, AISuggestedActionModel action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action.labelAr),
        content: const Text(
          'بناءً على مبادئ الأمان المالي لميزان، يتطلب تطبيق التعديل موافقتك الصريحة لتحديث خطة الميزانية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeepGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تطبيق الخطة وتحديث أهداف الميزانية بنجاح!'),
                  backgroundColor: AppColors.primaryDeepGreen,
                ),
              );
            },
            child: const Text('تأكيد واعتماد'),
          ),
        ],
      ),
    );
  }
}
