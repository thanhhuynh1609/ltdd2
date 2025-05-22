import 'package:cloud_firestore/cloud_firestore.dart';

class RefundRequest {
  final String id;
  final String orderId;
  final String userId;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final double amount;
  final DateTime requestDate;
  final DateTime? processDate;

  RefundRequest({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.reason,
    required this.status,
    required this.amount,
    required this.requestDate,
    this.processDate,
  });

  factory RefundRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RefundRequest(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending',
      amount: (data['amount'] ?? 0.0).toDouble(),
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      processDate: data['processDate'] != null 
          ? (data['processDate'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'reason': reason,
      'status': status,
      'amount': amount,
      'requestDate': Timestamp.fromDate(requestDate),
      'processDate': processDate != null ? Timestamp.fromDate(processDate!) : null,
    };
  }
}