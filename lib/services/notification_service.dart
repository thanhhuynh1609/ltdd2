import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Tạo thông báo mới
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'topup', 'order', 'refund', etc.
    String? orderId,
    String? transactionId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'orderId': orderId,
        'transactionId': transactionId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi khi tạo thông báo: $e');
    }
  }

  // Lấy danh sách thông báo của người dùng
  static Stream<QuerySnapshot> getNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Đánh dấu thông báo đã đọc
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Lỗi khi đánh dấu thông báo đã đọc: $e');
    }
  }

  // Đánh dấu tất cả thông báo đã đọc
  static Future<void> markAllAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Lỗi khi đánh dấu tất cả thông báo đã đọc: $e');
    }
  }

  // Đếm số thông báo chưa đọc
  static Stream<int> getUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
