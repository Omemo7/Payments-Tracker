class TransactionModel {
  final int? id;
  final double amount;
  final String? note;
  final int? accountId;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.amount,
    this.note,
    required this.createdAt,
    required this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'accountId': accountId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      note: map['note'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      accountId: map['accountId'],
    );
  }
}
