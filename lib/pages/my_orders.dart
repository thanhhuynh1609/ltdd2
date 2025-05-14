import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/utils/image_helper.dart';

import 'package:shopping_app/services/shared_pref.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({Key? key}) : super(key: key);

  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  String? userId = "";
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  getUserId() async {
    userId = await SharedPreferenceHelper().getUserId();
    getMyOrders();
  }

  getMyOrders() async {
    if (userId != null && userId!.isNotEmpty) {
      try {
        // Lấy dữ liệu từ Firestore một lần thay vì dùng stream
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection("Orders")
            .where("UserId", isEqualTo: userId)
            .get();

        // Chuyển đổi dữ liệu từ QuerySnapshot sang List<Map>
        orders = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          // Thêm id vào dữ liệu
          data['id'] = doc.id;
          return data;
        }).toList();

        // Sắp xếp theo ID (mới nhất lên đầu)
        orders.sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));

        setState(() {
          isLoading = false;
        });
      } catch (e) {
        print("Error fetching orders: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đơn hàng của tôi"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Orders")  // Đảm bảo tên collection đúng
            .where("Email", isEqualTo: FirebaseAuth.instance.currentUser?.email)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "Bạn chưa có đơn hàng nào",
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var orderData = snapshot.data!.docs[index];
              
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Đơn hàng #${orderData.id.substring(0, 8)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(orderData['Status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              orderData['Status'] ?? "Đang xử lý",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          // Sử dụng ProductImage thay vì Image
                          ImageHelper.buildImage(
                            orderData['ProductImage'],
                            width: 60,
                            height: 60,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderData['Product'] ?? "",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "Giá: \$${orderData['Price']}",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tổng tiền:",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "\$${orderData['Price']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case "Delivered":
      case "Đã giao hàng":
        return Colors.green;
      case "On the way":
      case "Đang giao hàng":
        return Colors.blue;
      case "Cancelled":
      case "Đã hủy":
        return Colors.red;
      case "Processing":
      case "Đang xử lý":
      default:
        return Colors.orange;
    }
  }
}











