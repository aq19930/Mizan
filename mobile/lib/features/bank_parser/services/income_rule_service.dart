class IncomeRuleDefinition {
  final String id;
  final String sourcePattern;
  final double minAmount;
  final double maxAmount;
  final int expectedDayStart;
  final int expectedDayEnd;
  final String? destinationAccountSuffix;
  final bool autoClassify;
  final double confidence;

  IncomeRuleDefinition({
    required this.id,
    required this.sourcePattern,
    required this.minAmount,
    required this.maxAmount,
    this.expectedDayStart = 25,
    this.expectedDayEnd = 28,
    this.destinationAccountSuffix,
    this.autoClassify = true,
    this.confidence = 0.92,
  });
}

class IncomeRuleService {
  static final List<IncomeRuleDefinition> _rules = [
    IncomeRuleDefinition(
      id: 'default-salary-rule',
      sourcePattern: 'راتب',
      minAmount: 6000.0,
      maxAmount: 80000.0,
      expectedDayStart: 25,
      expectedDayEnd: 28,
      destinationAccountSuffix: '2001',
    ),
  ];

  static List<IncomeRuleDefinition> get rules => List.unmodifiable(_rules);

  static void addRule(IncomeRuleDefinition rule) {
    _rules.add(rule);
  }

  /// Evaluates an incoming transaction against user-defined salary/income rules
  static IncomeRuleDefinition? evaluate(double amount, DateTime date, String? accountSuffix) {
    for (final rule in _rules) {
      final amountMatches = amount >= rule.minAmount && amount <= rule.maxAmount;
      final dayMatches = date.day >= rule.expectedDayStart && date.day <= rule.expectedDayEnd;
      final accountMatches = rule.destinationAccountSuffix == null ||
          accountSuffix == null ||
          rule.destinationAccountSuffix == accountSuffix;

      if (amountMatches && (dayMatches || accountMatches)) {
        return rule;
      }
    }
    return null;
  }
}