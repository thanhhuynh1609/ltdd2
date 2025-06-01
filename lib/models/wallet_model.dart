import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String userId;
  final double balance;
  final DateTime lastUpdated;

  WalletModel({
    required this.userId,
    required this.balance,
    required this.lastUpdated,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      userId: map['userId'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'deposit', 'refund', 'payment'
  final String description;
  final String? paymentId; // ID thanh toán Stripe (nếu có)
  final String? orderId; // ID đơn hàng (nếu có)
  final DateTime timestamp;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    this.paymentId,
    this.orderId,
    required this.timestamp,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map, String id) {
    return WalletTransaction(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      paymentId: map['paymentId'],
      orderId: map['orderId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'paymentId': paymentId,
      'orderId': orderId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}