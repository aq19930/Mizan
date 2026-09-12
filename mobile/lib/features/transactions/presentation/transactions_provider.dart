import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/transaction_model.dart';

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/transactions');
    final data = response.data as List<dynamic>;
    return data.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
  } catch (_) {
    return [
      TransactionModel(
        id: 't-1',
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
        notes: 'غداء عمل',
      ),
      TransactionModel(
        id: 't-2',
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
        id: 't-3',
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
      TransactionModel(
        id: 't-4',
        walletId: 'w-1',
        transactionType: 1,
        amount: 15000.0,
        merchant: 'تحويل راتب / Salary',
        categoryNameAr: 'دخل',
        categoryNameEn: 'Income',
        categoryIcon: 'trending_up',
        categoryColorHex: '#0F4D3A',
        transactionDate: DateTime.now().subtract(const Duration(days: 5)),
        source: 0,
        confidence: 1.0,
      ),
    ];
  }
});
