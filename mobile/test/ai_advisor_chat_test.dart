import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/insights/data/models/ai_models.dart';
import 'package:mobile/features/insights/presentation/ai_providers.dart';
import 'package:mobile/features/insights/presentation/mizan_ai_chat_screen.dart';
import 'package:mobile/features/insights/presentation/widgets/structured_ai_cards.dart';
import 'package:mobile/features/insights/services/ai_service.dart';
import 'package:mobile/l10n/app_localizations.dart';

class MockMizanAiService extends MizanAiService {
  @override
  Future<List<AIConversationModel>> getConversations() async => [];

  @override
  Future<List<String>> getSuggestedQuestions() async => [
    'حلل وضعي المالي',
    'كم أقدر أصرف؟',
    'وش التزاماتي القادمة؟',
    'رتب لي الراتب',
    'هل أقدر آخذ قرض؟',
    'هل أقدر أشتري سيارة؟',
    'كيف أوفر أكثر؟',
    'توقع رصيدي نهاية الشهر',
  ];
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Mizan AI Advisor Models Tests', () {
    test('AIConversationModel deserializes correctly', () {
      final json = {
        'id': 'conv_123',
        'title': 'استشارة قرض السيارة',
        'createdAt': '2026-09-12T10:00:00Z',
        'updatedAt': '2026-09-12T10:05:00Z',
        'messageCount': 4,
      };

      final model = AIConversationModel.fromJson(json);
      expect(model.id, equals('conv_123'));
      expect(model.title, equals('استشارة قرض السيارة'));
      expect(model.messageCount, equals(4));
    });

    test('AIChatMessageModel deserializes with cards, references, and suggestions', () {
      final json = {
        'id': 'msg_001',
        'role': 'assistant',
        'content': 'تحليل الجدوى المالية مكتمل.',
        'severity': 'normal',
        'cards': [
          {
            'cardType': 'PurchaseScenarioCard',
            'titleAr': 'شراء جوال',
            'titleEn': 'Phone Purchase',
            'data': {
              'purchaseAmount': 4000.0,
              'availableBefore': 8650.0,
              'availableAfter': 4650.0,
            },
          }
        ],
        'calculationReferences': ['PurchaseFeasibilityEngine'],
        'suggestedQuestions': ['هل الأفضل التقسيط؟'],
      };

      final model = AIChatMessageModel.fromJson(json);
      expect(model.id, equals('msg_001'));
      expect(model.role, equals('assistant'));
      expect(model.cards.length, equals(1));
      expect(model.cards.first.cardType, equals('PurchaseScenarioCard'));
      expect(model.calculationReferences.first, equals('PurchaseFeasibilityEngine'));
      expect(model.suggestedQuestions.first, equals('هل الأفضل التقسيط؟'));
    });
  });

  group('Mizan AI Advisor Widget Tests', () {
    testWidgets('StructuredAICardWidget renders PurchaseScenarioCard with contraction details', (tester) async {
      final card = StructuredAICardModel(
        cardType: 'PurchaseScenarioCard',
        titleAr: 'دراسة جدوى شراء (4000 ريال)',
        titleEn: 'Purchase Feasibility',
        data: {
          'itemName': 'آيفون 16',
          'purchaseAmount': 4000.0,
          'availableBefore': 8650.0,
          'availableAfter': 4650.0,
          'currentDailySpend': 288.0,
          'newDailySpend': 155.0,
          'feasibilityRatingAr': 'ممكن مع ترشيد بسيط',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: StructuredAICardWidget(card: card),
          ),
        ),
      );

      expect(find.text('دراسة جدوى شراء (4000 ريال)'), findsOneWidget);
      expect(find.text('آيفون 16'), findsOneWidget);
      expect(find.text('4000.0 ر.س'), findsOneWidget);
      expect(find.text('ممكن مع ترشيد بسيط'), findsOneWidget);
    });

    testWidgets('StructuredAICardWidget renders LoanScenarioCard with DTI information', (tester) async {
      final card = StructuredAICardModel(
        cardType: 'LoanScenarioCard',
        titleAr: 'دراسة تمويل 50,000 ريال',
        titleEn: 'Loan Study',
        data: {
          'loanAmount': 50000.0,
          'durationMonths': 36,
          'monthlyInstallment': 1509.0,
          'commitmentRatioBefore': 30.9,
          'commitmentRatioAfter': 52.5,
          'ratingAr': 'ضغط مالي مرتفع',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: StructuredAICardWidget(card: card),
          ),
        ),
      );

      expect(find.text('دراسة تمويل 50,000 ريال'), findsOneWidget);
      expect(find.text('1509.0 ر.س'), findsOneWidget);
      expect(find.text('ضغط مالي مرتفع'), findsOneWidget);
    });

    testWidgets('MizanAiChatScreen renders top app bar, greeting, and 8 starter chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(MockMizanAiService()),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MizanAiChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('مستشار ميزان المالي'), findsOneWidget);
      expect(find.text('متصل بمحفظتك وبياناتك المالية'), findsOneWidget);

      // Check welcome bubble
      expect(find.textContaining('أنا مستشار ميزان المالي'), findsOneWidget);

      // Check starter chips
      expect(find.text('حلل وضعي المالي'), findsOneWidget);
      expect(find.text('كم أقدر أصرف؟'), findsOneWidget);
      expect(find.text('وش التزاماتي القادمة؟'), findsOneWidget);
      expect(find.text('رتب لي الراتب'), findsOneWidget);
      expect(find.text('هل أقدر آخذ قرض؟'), findsOneWidget);
      expect(find.text('هل أقدر أشتري سيارة؟'), findsOneWidget);
      expect(find.text('كيف أوفر أكثر؟'), findsOneWidget);
      expect(find.text('توقع رصيدي نهاية الشهر'), findsOneWidget);

      // Check input bar [+] button
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });
  });
}
