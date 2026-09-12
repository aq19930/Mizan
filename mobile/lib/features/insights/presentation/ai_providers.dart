import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/ai_models.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<MizanAiService>((ref) {
  return MizanAiService();
});

final analysisSummaryProvider = FutureProvider<AnalysisSummaryModel>((ref) async {
  final service = ref.watch(aiServiceProvider);
  return service.getAnalysisSummary();
});

// -----------------------------------------------------------------------------
// AI Chat State & Notifier
// -----------------------------------------------------------------------------
class AIChatState {
  final List<AIChatMessageModel> messages;
  final bool isLoading;
  final String? currentLoadingStep;
  final String? errorMessage;
  final String? conversationId;
  final List<AIConversationModel> conversations;
  final bool isLoadingConversations;
  final List<String> quickStarterQuestions;

  AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.currentLoadingStep,
    this.errorMessage,
    this.conversationId,
    this.conversations = const [],
    this.isLoadingConversations = false,
    this.quickStarterQuestions = const [
      'حلل وضعي المالي',
      'كم أقدر أصرف؟',
      'وش التزاماتي القادمة؟',
      'رتب لي الراتب',
      'هل أقدر آخذ قرض؟',
      'هل أقدر أشتري سيارة؟',
      'كيف أوفر أكثر؟',
      'توقع رصيدي نهاية الشهر',
    ],
  });

  AIChatState copyWith({
    List<AIChatMessageModel>? messages,
    bool? isLoading,
    String? currentLoadingStep,
    String? errorMessage,
    String? conversationId,
    List<AIConversationModel>? conversations,
    bool? isLoadingConversations,
    List<String>? quickStarterQuestions,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      currentLoadingStep: currentLoadingStep ?? this.currentLoadingStep,
      errorMessage: errorMessage,
      conversationId: conversationId ?? this.conversationId,
      conversations: conversations ?? this.conversations,
      isLoadingConversations: isLoadingConversations ?? this.isLoadingConversations,
      quickStarterQuestions: quickStarterQuestions ?? this.quickStarterQuestions,
    );
  }
}

class AIChatNotifier extends StateNotifier<AIChatState> {
  final MizanAiService _service;

  static final AIChatMessageModel _initialGreeting = AIChatMessageModel(
    id: 'welcome_1',
    role: 'assistant',
    content: 'مرحبًا 👋\n'
        'أنا مستشار ميزان المالي.\n\n'
        'أقدر أساعدك في فهم مصروفاتك، التزاماتك، ميزانيتك، والتخطيط للقرارات المالية بناءً على بياناتك في ميزان.\n\n'
        'وش حاب تعرف؟',
    cards: [
      StructuredAICardModel(
        cardType: 'MoneySummaryCard',
        titleAr: 'موجز حساباتك الحية',
        titleEn: 'Live Accounts Brief',
        data: {
          'currentBalance': 14500.0,
          'availableToSpend': 8650.0,
          'commitments': 2150.0,
        },
      ),
    ],
    calculationReferences: [
      'محرك الحسابات المالية (Mizan Financial Calculation Engine)',
    ],
    createdAt: DateTime.now(),
  );

  AIChatNotifier(this._service) : super(AIChatState()) {
    state = state.copyWith(messages: [_initialGreeting]);
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoadingConversations: true);
    try {
      final convs = await _service.getConversations();
      final questions = await _service.getSuggestedQuestions();
      state = state.copyWith(
        conversations: convs,
        quickStarterQuestions: questions.isNotEmpty ? questions : state.quickStarterQuestions,
        isLoadingConversations: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingConversations: false);
    }
  }

  Future<void> startNewConversation({String? titleAr, String? titleEn}) async {
    try {
      final conv = await _service.createConversation(titleAr: titleAr, titleEn: titleEn);
      state = state.copyWith(
        conversationId: conv.id,
        messages: [_initialGreeting],
        errorMessage: null,
      );
      await loadConversations();
    } catch (_) {
      state = state.copyWith(
        conversationId: DateTime.now().millisecondsSinceEpoch.toString(),
        messages: [_initialGreeting],
        errorMessage: null,
      );
    }
  }

  void selectConversation(AIConversationModel conversation) {
    state = state.copyWith(
      conversationId: conversation.id,
      messages: [_initialGreeting],
      errorMessage: null,
    );
  }

  Future<void> sendMessage(String text, {String language = 'ar'}) async {
    if (text.trim().isEmpty) return;

    final userMsg = AIChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    String loadingStep = 'جاري فحص ميزانيتك وبياناتك المالية...';
    final lower = text.toLowerCase();
    if (lower.contains('قرض') || lower.contains('تمويل') || lower.contains('loan')) {
      loadingStep = 'أستشير محرك حساب القروض ومطابقة معايير البنك المركزي (SAMA)...';
    } else if (lower.contains('اشتري') || lower.contains('شراء') || lower.contains('جوال') || lower.contains('buy')) {
      loadingStep = 'أختبر سيناريو الشراء وتأثيره على وتيرة الصرف اليومي...';
    } else if (lower.contains('التزام') || lower.contains('فواتير') || lower.contains('قسط')) {
      loadingStep = 'أفحص جدول الالتزامات والسيولة المحجوزة...';
    } else if (lower.contains('رتب') || lower.contains('راتبي') || lower.contains('ادخار')) {
      loadingStep = 'أعد جدولة بنود الميزانية وتوزيع الفائض والادخار...';
    } else if (lower.contains('توقع') || lower.contains('forecast')) {
      loadingStep = 'أشغل محرك التوقعات المالية ومحاكاة نهاية الشهر...';
    }

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      currentLoadingStep: loadingStep,
      errorMessage: null,
    );

    try {
      final reply = await _service.sendChatMessage(
        text.trim(),
        conversationId: state.conversationId,
        language: language,
      );
      state = state.copyWith(
        messages: [...state.messages, reply],
        isLoading: false,
        currentLoadingStep: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        currentLoadingStep: null,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = state.copyWith(
      messages: [_initialGreeting],
      conversationId: null,
      errorMessage: null,
      currentLoadingStep: null,
    );
  }
}

final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  final service = ref.watch(aiServiceProvider);
  return AIChatNotifier(service);
});

// -----------------------------------------------------------------------------
// Loan Scenario State & Notifier
// -----------------------------------------------------------------------------
class LoanScenarioState {
  final double loanAmount;
  final double annualRate;
  final int durationMonths;
  final LoanScenarioResultModel? result;
  final bool isLoading;

  LoanScenarioState({
    this.loanAmount = 50000.0,
    this.annualRate = 5.5,
    this.durationMonths = 36,
    this.result,
    this.isLoading = false,
  });

  LoanScenarioState copyWith({
    double? loanAmount,
    double? annualRate,
    int? durationMonths,
    LoanScenarioResultModel? result,
    bool? isLoading,
  }) {
    return LoanScenarioState(
      loanAmount: loanAmount ?? this.loanAmount,
      annualRate: annualRate ?? this.annualRate,
      durationMonths: durationMonths ?? this.durationMonths,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoanScenarioNotifier extends StateNotifier<LoanScenarioState> {
  final MizanAiService _service;

  LoanScenarioNotifier(this._service) : super(LoanScenarioState()) {
    calculate();
  }

  Future<void> calculate({double? amount, double? rate, int? duration}) async {
    final curAmount = amount ?? state.loanAmount;
    final curRate = rate ?? state.annualRate;
    final curDuration = duration ?? state.durationMonths;

    state = state.copyWith(
      loanAmount: curAmount,
      annualRate: curRate,
      durationMonths: curDuration,
      isLoading: true,
    );

    try {
      final res = await _service.calculateLoanScenario(
        loanAmount: curAmount,
        annualRate: curRate,
        durationMonths: curDuration,
      );
      state = state.copyWith(result: res, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final loanScenarioProvider = StateNotifierProvider<LoanScenarioNotifier, LoanScenarioState>((ref) {
  final service = ref.watch(aiServiceProvider);
  return LoanScenarioNotifier(service);
});

// -----------------------------------------------------------------------------
// What-If State & Notifier
// -----------------------------------------------------------------------------
class WhatIfState {
  final String scenarioType;
  final double amount;
  final WhatIfResultModel? result;
  final bool isLoading;

  WhatIfState({
    this.scenarioType = 'MajorPurchase',
    this.amount = 4500.0,
    this.result,
    this.isLoading = false,
  });

  WhatIfState copyWith({
    String? scenarioType,
    double? amount,
    WhatIfResultModel? result,
    bool? isLoading,
  }) {
    return WhatIfState(
      scenarioType: scenarioType ?? this.scenarioType,
      amount: amount ?? this.amount,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WhatIfNotifier extends StateNotifier<WhatIfState> {
  final MizanAiService _service;

  WhatIfNotifier(this._service) : super(WhatIfState()) {
    simulate();
  }

  Future<void> simulate({String? type, double? amount}) async {
    final curType = type ?? state.scenarioType;
    final curAmount = amount ?? state.amount;

    state = state.copyWith(scenarioType: curType, amount: curAmount, isLoading: true);
    try {
      final res = await _service.simulateWhatIf(curType, curAmount);
      state = state.copyWith(result: res, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final whatIfProvider = StateNotifierProvider<WhatIfNotifier, WhatIfState>((ref) {
  final service = ref.watch(aiServiceProvider);
  return WhatIfNotifier(service);
});
