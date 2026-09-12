import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import 'ai_providers.dart';
import 'widgets/structured_ai_cards.dart';

class MizanAiChatScreen extends ConsumerStatefulWidget {
  const MizanAiChatScreen({super.key});

  @override
  ConsumerState<MizanAiChatScreen> createState() => _MizanAiChatScreenState();
}

class _MizanAiChatScreenState extends ConsumerState<MizanAiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text;
    if (text.trim().isEmpty) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ref.read(aiChatProvider.notifier).sendMessage(text.trim(), language: isArabic ? 'ar' : 'en');
    _textController.clear();
    _scrollToBottom();
  }

  void _showQuickActionsSheet(BuildContext context, bool isArabic, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'إجراءات سريعة مع المستشار' : 'Quick Financial Actions',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 14),
                _buildQuickActionTile(
                  icon: Icons.calculate_outlined,
                  title: isArabic ? 'محاكاة قرض جديد' : 'Simulate New Loan',
                  subtitle: isArabic ? 'حساب القسط الشهري ونسبة عبء الدين (DTI)' : 'Estimate installment and DTI impact',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showLoanInputDialog(isArabic);
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.shopping_bag_outlined,
                  title: isArabic ? 'اختبار شراء سلعة' : 'Test Purchase Feasibility',
                  subtitle: isArabic ? 'فحص تقلص وتيرة الصرف اليومي والسيولة' : 'Evaluate daily spend pace contraction',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPurchaseInputDialog(isArabic);
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.pie_chart_outline_rounded,
                  title: isArabic ? 'تنظيم الراتب والادخار' : 'Organize Salary & Savings',
                  subtitle: isArabic ? 'خطة ادخار 15% مع حجز الالتزامات مسبقاً' : '15% savings plan reserving commitments',
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendMessage(isArabic ? 'كيف ارتب راتبي بحيث اوفر 15%؟' : 'How can I organize my salary to save 15%?');
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.calendar_today_outlined,
                  title: isArabic ? 'مراجعة الالتزامات القادمة' : 'Review Upcoming Commitments',
                  subtitle: isArabic ? 'عرض الفواتير والأقساط ومواعيدها' : 'View pending bills and installments',
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendMessage(isArabic ? 'كم باقي علي التزامات هالشهر؟' : 'What commitments are remaining this month?');
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: isArabic ? 'ملخص الرصيد المتاح' : 'Available Cash Summary',
                  subtitle: isArabic ? 'الرصيد الحقيقي بعد حجز الالتزامات' : 'Real balance after commitments',
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendMessage(isArabic ? 'كم المتاح الفعلي للصرف عندي اليوم؟' : 'What is my actual available spend today?');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryDeepGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryDeepGreen, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLoanInputDialog(bool isArabic) {
    final amountController = TextEditingController(text: '50000');
    final yearsController = TextEditingController(text: '3');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'محاكاة قرض جديد' : 'Simulate Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isArabic ? 'مبلغ التمويل (ريال)' : 'Financing Amount (SAR)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isArabic ? 'المدة (بالسنوات)' : 'Duration (Years)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDeepGreen),
            onPressed: () {
              Navigator.pop(ctx);
              final amt = amountController.text.trim();
              final yrs = yearsController.text.trim();
              if (isArabic) {
                _sendMessage('عطني حسبة قرض $amt على $yrs سنوات');
              } else {
                _sendMessage('Calculate a loan of $amt SAR over $yrs years');
              }
            },
            child: Text(isArabic ? 'احسب' : 'Calculate', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPurchaseInputDialog(bool isArabic) {
    final itemController = TextEditingController(text: isArabic ? 'جوال' : 'Phone');
    final priceController = TextEditingController(text: '4000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'اختبار شراء سلعة' : 'Test Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: itemController,
              decoration: InputDecoration(
                labelText: isArabic ? 'السلعة / الغرض' : 'Item / Purpose',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isArabic ? 'السعر التقديري (ريال)' : 'Estimated Price (SAR)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDeepGreen),
            onPressed: () {
              Navigator.pop(ctx);
              final item = itemController.text.trim();
              final price = priceController.text.trim();
              if (isArabic) {
                _sendMessage('اقدر اشتري $item بـ $price ريال الحين؟');
              } else {
                _sendMessage('Can I buy a $item for $price SAR right now?');
              }
            },
            child: Text(isArabic ? 'فحص الجدوى' : 'Check Feasibility', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showConversationsHistorySheet(BuildContext context, AIChatState state, bool isArabic, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'سجل المحادثات السابقة' : 'Consultation History',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(isArabic ? 'محادثة جديدة' : 'New Chat'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(aiChatProvider.notifier).startNewConversation();
                    },
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: state.conversations.isEmpty
                    ? Center(
                        child: Text(
                          isArabic ? 'لا توجد محادثات سابقة محفوظة' : 'No previous consultations',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.conversations.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final conv = state.conversations[index];
                          final isSelected = conv.id == state.conversationId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryDeepGreen
                                    : AppColors.primaryDeepGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.chat_outlined,
                                size: 18,
                                color: isSelected ? Colors.white : AppColors.primaryDeepGreen,
                              ),
                            ),
                            title: Text(
                              conv.title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${conv.createdAt.year}-${conv.createdAt.month.toString().padLeft(2, '0')}-${conv.createdAt.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: AppColors.primaryDeepGreen, size: 20)
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              ref.read(aiChatProvider.notifier).selectConversation(conv);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9F7F2),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4D3A), Color(0xFF1B6B52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.accentBrightGreen, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiAdvisorTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isArabic ? 'متصل بمحفظتك وبياناتك المالية' : 'Connected to your financial data',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: isArabic ? 'سجل المحادثات' : 'History',
            onPressed: () => _showConversationsHistorySheet(context, chatState, isArabic, isDark),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: isArabic ? 'محادثة جديدة' : 'New Chat',
            onPressed: () => ref.read(aiChatProvider.notifier).startNewConversation(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // If loading indicator item at bottom
                  if (index == chatState.messages.length) {
                    return _buildContextualLoadingBubble(chatState.currentLoadingStep, isDark, isArabic);
                  }

                  final msg = chatState.messages[index];
                  final isUser = msg.role == 'user';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:
                              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.primaryDeepGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppColors.primaryDeepGreen
                                      : (isDark ? AppColors.darkSurface : Colors.white),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: isUser
                                        ? const Radius.circular(18)
                                        : const Radius.circular(4),
                                    bottomRight: isUser
                                        ? const Radius.circular(4)
                                        : const Radius.circular(18),
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(
                                          color: isDark ? AppColors.darkBorder : const Color(0xFFE8E4DC),
                                          width: 1,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: isUser
                                        ? Colors.white
                                        : (isDark ? Colors.white : const Color(0xFF1E2421)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Render structured cards if present
                        if (!isUser && msg.cards.isNotEmpty) ...[
                          for (final card in msg.cards)
                            Padding(
                              padding: const EdgeInsets.only(top: 10, right: 28, left: 4),
                              child: StructuredAICardWidget(
                                card: card,
                                onQuickQuery: (q) => _sendMessage(q),
                              ),
                            ),
                        ],

                        // Calculation references badge
                        if (!isUser && msg.calculationReferences.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 30, left: 4),
                            child: Row(
                              children: [
                                Icon(Icons.verified_outlined, size: 13, color: AppColors.primaryDeepGreen.withValues(alpha: 0.8)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'محسوبة بواسطة: ${msg.calculationReferences.first}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Render starter chips on initial welcome message
                        if (index == 0 && !isUser && chatState.messages.length == 1) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              isArabic ? 'أسئلة مقترحة للبدء:' : 'Suggested questions to start:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: chatState.quickStarterQuestions.map((q) {
                              return ActionChip(
                                label: Text(q),
                                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                backgroundColor: isDark ? const Color(0xFF1F2F27) : const Color(0xFFEBF4EE),
                                side: BorderSide(
                                  color: AppColors.primaryDeepGreen.withValues(alpha: 0.25),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onPressed: () => _sendMessage(q),
                              );
                            }).toList(),
                          ),
                        ],

                        // Render suggested follow-up chips if message has them
                        if (!isUser && msg.suggestedQuestions.isNotEmpty && index == chatState.messages.length - 1) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(right: 28, left: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: msg.suggestedQuestions.map((sq) {
                                return ActionChip(
                                  avatar: const Icon(Icons.subdirectory_arrow_left_rounded, size: 14),
                                  label: Text(sq),
                                  labelStyle: const TextStyle(fontSize: 11.5),
                                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                  side: BorderSide(
                                    color: AppColors.primaryDeepGreen.withValues(alpha: 0.25),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  onPressed: () => _sendMessage(sq),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEBE6DC),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // [+] Quick Actions Sheet
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeepGreen.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primaryDeepGreen, size: 22),
                      tooltip: isArabic ? 'إجراءات سريعة' : 'Quick Actions',
                      onPressed: () => _showQuickActionsSheet(context, isArabic, isDark),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF3EFE7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFDFD9CD),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 3,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (val) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: isArabic
                                    ? 'اسأل مستشار ميزان المالي...'
                                    : 'Ask Mizan Financial Advisor...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          // Voice button
                          IconButton(
                            icon: const Icon(Icons.mic_none_rounded, size: 20, color: Colors.grey),
                            tooltip: isArabic ? 'التسجيل الصوتي' : 'Voice Input',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isArabic
                                        ? 'مستشار ميزان جاهز صوتياً — جاري ربط التعرف الصوتي.'
                                        : 'Mizan Advisor voice engine ready.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F4D3A), Color(0xFF1B6B52)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      tooltip: isArabic ? 'إرسال' : 'Send',
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualLoadingBubble(String? step, bool isDark, bool isArabic) {
    final text = step ?? (isArabic ? 'جاري فحص بياناتك المالية ومحاكاة الأثر...' : 'Analyzing financial context...');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryDeepGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primaryDeepGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentBrightGreen.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDeepGreen),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : AppColors.primaryDeepGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
