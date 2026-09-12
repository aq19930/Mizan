import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/budget_model.dart';

final budgetsProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final res = await dio.get('/budgets');
    final list = res.data as List;
    return list.map((e) => BudgetModel.fromJson(e)).toList();
  } catch (_) {
    return [
      BudgetModel(
        id: 'b-1',
        categoryNameAr: 'مطاعم ومقاهي',
        categoryNameEn: 'Food & Dining',
        categoryIcon: 'restaurant',
        amount: 1500.0,
        spent: 850.0,
        remaining: 650.0,
        percentage: 56.6,
        status: 'Safe',
      ),
      BudgetModel(
        id: 'b-2',
        categoryNameAr: 'بقالة ومستلزمات',
        categoryNameEn: 'Groceries',
        categoryIcon: 'local_grocery_store',
        amount: 1200.0,
        spent: 520.0,
        remaining: 680.0,
        percentage: 43.3,
        status: 'Safe',
      ),
      BudgetModel(
        id: 'b-3',
        categoryNameAr: 'مواصلات وبنزين',
        categoryNameEn: 'Transportation',
        categoryIcon: 'directions_car',
        amount: 600.0,
        spent: 380.0,
        remaining: 220.0,
        percentage: 63.3,
        status: 'Caution',
      ),
      BudgetModel(
        id: 'b-4',
        categoryNameAr: 'تسوق وترفيه',
        categoryNameEn: 'Shopping & Entertainment',
        categoryIcon: 'shopping_bag',
        amount: 1000.0,
        spent: 920.0,
        remaining: 80.0,
        percentage: 92.0,
        status: 'Warning',
      ),
    ];
  }
});
