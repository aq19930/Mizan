import '../data/models/parsed_bank_transaction.dart';
import '../services/message_classifier.dart';
import 'alinma_parser.dart';
import 'alrajhi_parser.dart';
import 'bank_parser_interface.dart';
import 'generic_bank_parser.dart';
import 'riyad_parser.dart';
import 'sab_parser.dart';
import 'saib_parser.dart';
import 'saudi_bank_message_parser.dart';
import 'snb_parser.dart';
import 'stc_bank_parser.dart';

class BankMessageParserFactory {
  static final List<IBankMessageParser> _parsers = [
    SaudiBankMessageParser(),
    AlRajhiParser(),
    SnbParser(),
    RiyadBankParser(),
    AlinmaParser(),
    SabParser(),
    SaibParser(),
    StcBankParser(),
    GenericBankParser(),
  ];

  static List<IBankMessageParser> get registeredParsers => List.unmodifiable(_parsers);

  /// Selects the best matching parser for given message and sender.
  static IBankMessageParser getParser(String message, {String? sender}) {
    // 1. Specific bank match
    for (final parser in _parsers) {
      if (parser is! GenericBankParser && parser is! SaudiBankMessageParser && parser.canParse(message, sender: sender)) {
        return parser;
      }
    }
    // 2. Modular advanced parser
    return _parsers.first;
  }

  /// Parses raw message text if eligible. Returns null if message is OTP, marketing, or malformed.
  static ParsedBankTransactionDto? parse(String message, {String? sender}) {
    // 1. Classification check
    if (!MessageClassifier.isEligibleForParsing(message)) {
      return null;
    }

    // 2. If it contains advanced cues (biller, local transfer fee, traffic violation TRF, POS), use modular parser
    final lower = message.toLowerCase();
    if (lower.contains('مفوتر') ||
        lower.contains('خدمة:') ||
        lower.contains('trf') ||
        lower.contains('نظام المرور') ||
        lower.contains('حوالة محلية') ||
        lower.contains('المصرف') ||
        lower.contains('شراء pos') ||
        lower.contains('مدى سامسونج')) {
      final modular = SaudiBankMessageParser();
      final res = modular.parse(message, sender: sender);
      if (res != null && res.isValid) return res;
    }

    // 3. Specific bank parsers
    for (final parser in _parsers) {
      if (parser is! GenericBankParser && parser is! SaudiBankMessageParser && parser.canParse(message, sender: sender)) {
        final result = parser.parse(message, sender: sender);
        if (result != null && result.isValid) {
          return result;
        }
      }
    }

    // 4. Modular fallback then generic
    final fallbackRes = SaudiBankMessageParser().parse(message, sender: sender);
    if (fallbackRes != null && fallbackRes.isValid) return fallbackRes;

    return _parsers.last.parse(message, sender: sender);
  }
}
