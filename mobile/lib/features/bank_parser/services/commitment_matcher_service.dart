import '../../commitments/data/models/commitment_model.dart';
import '../data/models/parsed_bank_transaction.dart';

class CommitmentMatchResult {
  final bool hasMatch;
  final CommitmentModel? matchedCommitment;
  final double confidence;
  final bool isExact;
  final CommitmentOccurrenceModel? suggestedOccurrence;
  final String promptAr;
  final String promptEn;

  const CommitmentMatchResult({
    required this.hasMatch,
    this.matchedCommitment,
    this.confidence = 0.0,
    this.isExact = false,
    this.suggestedOccurrence,
    this.promptAr = '',
    this.promptEn = '',
  });
}

class CommitmentMatcherService {
  /// Matches a parsed bank transaction against a list of active commitments.
  static CommitmentMatchResult match({
    required ParsedBankTransactionDto transaction,
    required List<CommitmentModel> activeCommitments,
  }) {
    if (activeCommitments.isEmpty || transaction.amount <= 0) {
      return const CommitmentMatchResult(hasMatch: false);
    }

    CommitmentModel? bestCommitment;
    double highestScore = 0.0;

    for (final commitment in activeCommitments) {
      if (commitment.isPaid) continue;

      double score = 0.0;

      // 1. Amount Proximity
      final diff = (commitment.amount - transaction.amount).abs();
      if (diff < 0.01) {
        score += 0.50; // Exact amount match
      } else if (commitment.amount > 0 && diff / commitment.amount <= 0.08) {
        score += 0.25; // Close amount match (within 8%)
      }

      // 2. Merchant Name Proximity
      final tMerchant = transaction.merchant.toLowerCase();
      final cTitle = commitment.title.toLowerCase();
      final cMerchant = (commitment.merchant ?? '').toLowerCase();

      if (tMerchant.contains(cTitle) || cTitle.contains(tMerchant)) {
        score += 0.35;
      } else if (cMerchant.isNotEmpty && (tMerchant.contains(cMerchant) || cMerchant.contains(tMerchant))) {
        score += 0.35;
      }

      // 3. Due Date Proximity
      final dayDiff = commitment.nextDueDate.difference(transaction.transactionDate).inDays.abs();
      if (dayDiff <= 3) {
        score += 0.15;
      } else if (dayDiff <= 7) {
        score += 0.10;
      }

      if (score > highestScore) {
        highestScore = score;
        bestCommitment = commitment;
      }
    }

    if (bestCommitment != null && highestScore >= 0.65) {
      CommitmentOccurrenceModel? occurrence;
      if (bestCommitment.occurrences.isNotEmpty) {
        occurrence = bestCommitment.occurrences.firstWhere(
          (o) => o.status == 'Pending' || o.status == 'Upcoming',
          orElse: () => bestCommitment!.occurrences.first,
        );
      }

      return CommitmentMatchResult(
        hasMatch: true,
        matchedCommitment: bestCommitment,
        confidence: double.parse(highestScore.toStringAsFixed(2)),
        isExact: highestScore >= 0.90,
        suggestedOccurrence: occurrence,
        promptAr: 'هذا يبدو أنه سداد التزام ${bestCommitment.title}.',
        promptEn: 'This appears to be payment for commitment: ${bestCommitment.title}.',
      );
    }

    return const CommitmentMatchResult(hasMatch: false);
  }
}
