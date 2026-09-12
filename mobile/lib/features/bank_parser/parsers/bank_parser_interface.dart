import '../data/models/parsed_bank_transaction.dart';

abstract class IBankMessageParser {
  String get bankIdentifier;
  String get bankDisplayNameAr;
  String get bankDisplayNameEn;

  bool canParse(String message, {String? sender});
  ParsedBankTransactionDto? parse(String message, {String? sender});

  String detectBank(String message, {String? sender});
  String extractTransactionType(String message);
  double? extractAmount(String message);
  String extractCurrency(String message);
  String extractMerchant(String message);
  DateTime? extractDate(String message);
  String? extractReference(String message);
  String? extractCardSuffix(String message);
  double? extractReportedBalance(String message);
  String inferCategory(String merchant, String transactionType);
}
