// lib/models/discount_code.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountCode {
  String id;
  String code;
  double discountAmount;
  bool isActive;
  DateTime createdAt;
  DateTime? startDate; // Thêm thuộc tính ngày bắt đầu
  DateTime? expiryDate;
  double? minOrderAmount;
  int? usageCount;

  DiscountCode({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.isActive,
    required this.createdAt,
    this.startDate,
    this.expiryDate,
    this.minOrderAmount,
    this.usageCount,
  });

  factory DiscountCode.fromJson(Map<String, dynamic> json, String id) {
    return DiscountCode(
      id: id,
      code: json['code'],
      discountAmount: json['discountAmount'].toDouble(),
      isActive: json['isActive'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      startDate: json['startDate'] != null ? (json['startDate'] as Timestamp).toDate() : null,
      expiryDate: json['expiryDate'] != null ? (json['expiryDate'] as Timestamp).toDate() : null,
      minOrderAmount: json['minOrderAmount']?.toDouble(),
      usageCount: json['usageCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discountAmount': discountAmount,
      'isActive': isActive,
      'createdAt': createdAt,
      'startDate': startDate,
      'expiryDate': expiryDate,
      'minOrderAmount': minOrderAmount,
      'usageCount': usageCount,
    };
  }
}