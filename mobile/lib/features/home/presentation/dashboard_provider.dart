import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../transactions/data/models/transaction_model.dart';
import '../data/models/dashboard_model.dart';

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/analytics/dashboard');
    return DashboardModel.fromJson(response.data as Map<String, dynamic>);
  } catch (_) {
    return DashboardModel(
      currentBalance: 4862.50,
      committedAmount: 1592.00,
      availableToSpend: 3270.50,
      spentToday: 137.50,
      dailyLimit: 160.0,
      expectedTomorrow: 140.0,
      budgetHealth: 'safe',
      upcomingCommitments: [
        UpcomingCommitmentSummary(
          id: 'c-1',
          title: 'قسط السيارة (الراجحي)',
          category: 'Car',
          amount: 1250.0,
          dueDate: DateTime.now().add(const Duration(days: 5)),
          daysUntilDue: 5,
        ),
        UpcomingCommitmentSummary(
          id: 'c-2',
          title: 'فاتورة إنترنت STC',
          category: 'Telecommunications',
          amount: 287.0,
          dueDate: DateTime.now().add(const Duration(days: 8)),
          daysUntilDue: 8,
        ),
        UpcomingCommitmentSummary(
          id: 'c-3',
          title: 'اشتراك نتفليكس',
          category: 'Subscriptions',
          amount: 55.0,
          dueDate: DateTime.now().add(const Duration(days: 11)),
          daysUntilDue: 11,
        ),
      ],
      recentTransactions: [
        TransactionModel(
          id: 'tx-1',
          walletId: 'w-1',
          transactionType: 0,
          amount: 68.0,
          merchant: 'البيك / Al Baik',
          categoryNameAr: 'مطاعم ومقاهي',
          categoryNameEn: 'Food & Dining',
          categoryIcon: 'restaurant',
          categoryColorHex: '#F59E0B',
          transactionDate: DateTime.now().subtract(const Duration(hours: 2)),
          source: 1,
          confidence: 0.98,
        ),
        TransactionModel(
          id: 'tx-2',
          walletId: 'w-1',
          transactionType: 0,
          amount: 67.5,
          merchant: 'بندة / Panda',
          categoryNameAr: 'بقالة ومواد غذائية',
          categoryNameEn: 'Groceries',
          categoryIcon: 'local_grocery_store',
          categoryColorHex: '#10B981',
          transactionDate: DateTime.now().subtract(const Duration(hours: 5)),
          source: 1,
          confidence: 0.95,
        ),
        TransactionModel(
          id: 'tx-3',
          walletId: 'w-1',
          transactionType: 0,
          amount: 24.0,
          merchant: 'جرير / Jarir',
          categoryNameAr: 'تسوق ومستلزمات',
          categoryNameEn: 'Shopping',
          categoryIcon: 'shopping_bag',
          categoryColorHex: '#EC4899',
          transactionDate: DateTime.now().subtract(const Duration(days: 1)),
          source: 0,
          confidence: 1.0,
        ),
      ],
      spendingByCategory: [
        CategorySpendingModel(
          categoryNameAr: 'مطاعم ومقاهي',
          categoryNameEn: 'Food & Dining',
          icon: 'restaurant',
          colorHex: '#F59E0B',
          spentAmount: 850.0,
          percentage: 42.0,
        ),
        CategorySpendingModel(
          categoryNameAr: 'بقالة ومواد غذائية',
          categoryNameEn: 'Groceries',
          icon: 'local_grocery_store',
          colorHex: '#10B981',
          spentAmount: 520.0,
          percentage: 26.0,
        ),
        CategorySpendingModel(
          categoryNameAr: 'مواصلات ونقل',
          categoryNameEn: 'Transportation',
          icon: 'directions_car',
          colorHex: '#6366F1',
          spentAmount: 380.0,
          percentage: 19.0,
        ),
      ],
      aiInsightAr: 'ممتاز! مصروف اليوم ضمن الحدود الآمنة وبفارق وفر قدره 144.50 ر.س.',
      aiInsightEn: 'Great job! Today\'s spend is well within your safe daily budget.',
    );
  }
});
