// lib/models/receipt_model.dart

enum ReceiptStatus {
  generated,
  sent,
  downloaded,
  archived;

  String get displayName {
    switch (this) {
      case ReceiptStatus.generated:
        return 'Dibuat';
      case ReceiptStatus.sent:
        return 'Dikirim';
      case ReceiptStatus.downloaded:
        return 'Diunduh';
      case ReceiptStatus.archived:
        return 'Diarsipkan';
    }
  }
}

