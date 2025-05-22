import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopping_app/pages/order_detail_page.dart';
import 'package:shopping_app/services/notification_service.dart';
import 'package:shopping_app/services/shared_pref.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String userId = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    userId = await SharedPreferenceHelper().getUserId() ?? "";
    if (userId.isNotEmpty) {
      setState(() {
        isLoading = false;
      });
      
      // Tự động làm mới danh sách thông báo
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {});
    }
  }

  // Xử lý khi nhấn vào thông báo
  void _handleNotificationTap(Map<String, dynamic> notification) async {
    // Đánh dấu thông báo đã đọc
    await NotificationService.markAsRead(notification['id']);

    // Điều hướng dựa trên loại thông báo
    if ((notification['type'] == 'order' || notification['type'] == 'order_status') && notification['orderId'] != null) {
      // Lấy thông tin đơn hàng
      DocumentSnapshot orderDoc = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(notification['orderId'])
          .get();
      
      if (orderDoc.exists) {
        Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
        orderData['id'] = orderDoc.id;
        
        // Chuyển đến trang chi tiết đơn hàng
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(orderData: orderData),
          ),
        );
      }
    } else if ((notification['type'] == 'wallet_topup' || notification['type'] == 'wallet_transaction') && notification['transactionId'] != null) {
      // Có thể chuyển đến trang lịch sử giao dịch ví
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => WalletHistoryPage(),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Thông báo",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.blue),
            onPressed: () async {
              await NotificationService.markAllAsRead(userId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Đã đánh dấu tất cả là đã đọc"),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: NotificationService.getNotifications(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Bạn chưa có thông báo nào",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> notification = doc.data() as Map<String, dynamic>;
                    notification['id'] = doc.id;
                    
                    // Format thời gian
                    String formattedTime = "";
                    if (notification['createdAt'] != null) {
                      DateTime createdAt = (notification['createdAt'] as Timestamp).toDate();
                      formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
                    }
                    
                    // Chọn icon dựa trên loại thông báo
                    IconData notificationIcon = Icons.notifications;
                    Color iconColor = Colors.blue;

                    switch (notification['type']) {
                      case 'topup':
                      case 'wallet_topup':
                      case 'wallet_transaction':
                        notificationIcon = Icons.account_balance_wallet;
                        iconColor = Colors.green;
                        break;
                      case 'order':
                      case 'order_status':
                        notificationIcon = Icons.shopping_bag;
                        iconColor = Colors.orange;
                        break;
                      case 'refund':
                      case 'refund_approved':
                      case 'refund_rejected':
                        notificationIcon = Icons.money;
                        iconColor = Colors.purple;
                        break;
                      default:
                        notificationIcon = Icons.notifications;
                        iconColor = Colors.blue;
                    }
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.2),
                          child: Icon(notificationIcon, color: iconColor),
                        ),
                        title: Text(
                          notification['title'] ?? "",
                          style: TextStyle(
                            fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(notification['message'] ?? ""),
                            SizedBox(height: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: notification['isRead']
                            ? null
                            : Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () => _handleNotificationTap(notification),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}


