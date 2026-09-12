import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/commitment_model.dart';

class CommitmentsNotifier extends StateNotifier<AsyncValue<List<CommitmentModel>>> {
  final Ref _ref;

  CommitmentsNotifier(this._ref) : super(AsyncValue.data(_defaultSampleCommitments)) {
    loadCommitments();
  }

  Future<void> loadCommitments() async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/commitments');
      final list = (response.data as List<dynamic>)
          .map((e) => CommitmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (_) {
      // Fallback sample data for offline & demo mode
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncValue.data(_defaultSampleCommitments);
      }
    }
  }

  Future<bool> addCommitment({
    required String title,
    String? description,
    required String category,
    required double amount,
    String currency = 'SAR',
    required String frequency,
    required DateTime dueDate,
    String priority = 'Medium',
    String? merchant,
    String? notes,
  }) async {
    final newCommitment = CommitmentModel(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'u-1',
      title: title,
      description: description ?? notes,
      category: category,
      categoryNameAr: _getCategoryNameAr(category),
      categoryNameEn: category,
      amount: amount,
      currency: currency,
      frequency: frequency,
      startDate: DateTime.now(),
      dueDate: dueDate,
      nextDueDate: dueDate,
      priority: priority,
      merchant: merchant,
      status: 'Active',
      createdAt: DateTime.now(),
      occurrences: [
        CommitmentOccurrenceModel(
          id: 'occ-${DateTime.now().millisecondsSinceEpoch}',
          commitmentId: 'c-${DateTime.now().millisecondsSinceEpoch}',
          expectedDate: dueDate,
          expectedAmount: amount,
          status: 'Pending',
        ),
      ],
    );

    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/commitments', data: {
        'title': title,
        'description': description ?? notes,
        'category': category,
        'amount': amount,
        'currency': currency,
        'frequency': frequency,
        'startDate': DateTime.now().toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'priority': priority,
        'merchant': merchant,
      });
    } catch (_) {
      // Offline fallback
    }

    final currentList = state.value ?? [];
    state = AsyncValue.data([...currentList, newCommitment]);
    return true;
  }

  Future<void> markPaid(String commitmentId, {String? occurrenceId, double? actualAmount}) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/commitments/$commitmentId/mark-paid', data: {
        'occurrenceId': occurrenceId,
        'actualAmount': actualAmount,
      });
    } catch (_) {
      // Offline fallback
    }

    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.map((c) {
      if (c.id == commitmentId) {
        return CommitmentModel(
          id: c.id,
          userId: c.userId,
          title: c.title,
          description: c.description,
          category: c.category,
          categoryNameAr: c.categoryNameAr,
          categoryNameEn: c.categoryNameEn,
          amount: c.amount,
          currency: c.currency,
          frequency: c.frequency,
          startDate: c.startDate,
          dueDate: c.dueDate,
          nextDueDate: c.nextDueDate.add(const Duration(days: 30)),
          priority: c.priority,
          merchant: c.merchant,
          status: 'Paid',
          isPaid: true,
          createdAt: c.createdAt,
          occurrences: c.occurrences,
        );
      }
      return c;
    }).toList());
  }

  Future<void> deleteCommitment(String commitmentId) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete('/commitments/$commitmentId');
    } catch (_) {
      // Offline fallback
    }

    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((c) => c.id != commitmentId).toList());
  }

  static String _getCategoryNameAr(String cat) {
    switch (cat.toLowerCase()) {
      case 'housing':
        return 'سكن';
      case 'car':
        return 'سيارة';
      case 'loan':
        return 'قرض';
      case 'creditcard':
        return 'بطاقة ائتمانية';
      case 'utilities':
        return 'فواتير خدمات';
      case 'telecommunications':
      case 'telecom':
        return 'اتصالات';
      case 'insurance':
        return 'تأمين';
      case 'subscriptions':
        return 'اشتراكات';
      case 'education':
        return 'تعليم';
      case 'family':
        return 'التزامات عائلية';
      case 'bnpl':
        return 'تقسيط / تمارا وتابي';
      case 'governmentfees':
        return 'رسوم حكومية';
      case 'healthcare':
        return 'صحة';
      default:
        return 'أخرى';
    }
  }

  static final List<CommitmentModel> _defaultSampleCommitments = [
    CommitmentModel(
      id: 'c-1',
      userId: 'u-1',
      title: 'قسط السيارة (الراجحي)',
      category: 'Car',
      categoryNameAr: 'سيارة',
      categoryNameEn: 'Car Installment',
      amount: 1250.0,
      frequency: 'Monthly',
      startDate: DateTime.now().subtract(const Duration(days: 120)),
      dueDate: DateTime.now().add(const Duration(days: 5)),
      nextDueDate: DateTime.now().add(const Duration(days: 5)),
      priority: 'High',
      merchant: 'Al Rajhi Bank',
      status: 'Active',
      isPaid: false,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    CommitmentModel(
      id: 'c-2',
      userId: 'u-1',
      title: 'فاتورة إنترنت وموبايل STC',
      category: 'Telecommunications',
      categoryNameAr: 'اتصالات',
      categoryNameEn: 'Telecom',
      amount: 287.0,
      frequency: 'Monthly',
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      dueDate: DateTime.now().add(const Duration(days: 8)),
      nextDueDate: DateTime.now().add(const Duration(days: 8)),
      priority: 'Medium',
      merchant: 'STC',
      status: 'Active',
      isPaid: false,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    CommitmentModel(
      id: 'c-3',
      userId: 'u-1',
      title: 'اشتراك نتفليكس (Netflix)',
      category: 'Subscriptions',
      categoryNameAr: 'اشتراكات',
      categoryNameEn: 'Subscriptions',
      amount: 55.0,
      frequency: 'Monthly',
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      dueDate: DateTime.now().add(const Duration(days: 11)),
      nextDueDate: DateTime.now().add(const Duration(days: 11)),
      priority: 'Low',
      merchant: 'NETFLIX.COM',
      status: 'Active',
      isPaid: false,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
  ];
}

final commitmentsProvider = StateNotifierProvider<CommitmentsNotifier, AsyncValue<List<CommitmentModel>>>((ref) {
  return CommitmentsNotifier(ref);
});
