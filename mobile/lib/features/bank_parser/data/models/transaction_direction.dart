enum TransactionDirection {
  inDir,
  outDir,
  neutral;

  String get code {
    switch (this) {
      case TransactionDirection.inDir:
        return 'IN';
      case TransactionDirection.outDir:
        return 'OUT';
      case TransactionDirection.neutral:
        return 'NEUTRAL';
    }
  }

  static TransactionDirection fromCode(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'IN':
        return TransactionDirection.inDir;
      case 'OUT':
        return TransactionDirection.outDir;
      default:
        return TransactionDirection.neutral;
    }
  }
}