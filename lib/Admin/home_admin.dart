import 'package:flutter/material.dart';
import 'package:shopping_app/Admin/add_product.dart';
import 'package:shopping_app/Admin/all_orders.dart';
import 'package:shopping_app/Admin/manage_products.dart';
import 'package:shopping_app/Admin/manage_users.dart';
import 'package:shopping_app/Admin/refund_requests.dart';
import 'package:shopping_app/Admin/admin_chat_list.dart';
import 'package:shopping_app/Admin/manage_discount_codes.dart'; // Thêm import
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset("images/logook.png", width: 170),
            SizedBox(height: 30),
            Text(
              "Admin Home",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            _buildAdminButton(
              icon: Icons.add_circle_outline,
              title: "Thêm sản phẩm mới",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddProduct()));
              },
            ),
            SizedBox(height: 20.0),
            _buildAdminButton(
              icon: Icons.inventory,
              title: "Quản lý sản phẩm",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManageProducts()));
              },
            ),
            SizedBox(height: 20.0),
            _buildAdminButton(
              icon: Icons.shopping_cart,
              title: "Quản lý đơn hàng",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AllOrders()));
              },
            ),
            SizedBox(height: 20.0),
            _buildAdminButton(
              icon: Icons.people,
              title: "Quản lý người dùng",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUsers()));
              },
            ),
            SizedBox(height: 20.0),
            _buildAdminButton(
              icon: Icons.discount,
              title: "Quản lý mã giảm giá",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManageDiscountCodes()));
              },
            ),
            SizedBox(height: 20.0),
            _buildAdminButton(
              icon: Icons.money_off,
              title: "Khiếu nại/ Trả hàng",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RefundRequestsPage()));
              },
            ),
            SizedBox(height: 20.0),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('unreadAdminCount', isGreaterThan: 0)
                  .snapshots(),
              builder: (context, snapshot) {
                int totalUnread = 0;

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    totalUnread += (data['unreadAdminCount'] ?? 0) as int;
                  }
                }

                return Stack(
                  children: [
                    _buildAdminButton(
                      icon: Icons.chat,
                      title: "Tin nhắn",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminChatList()));
                      },
                    ),
                    if (totalUnread > 0)
                      Positioned(
                        right: 20,
                        top: 15,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            totalUnread.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 20.0),
            Icon(
              icon,
              size: 30.0,
              color: Color(0xff4b69fe),
            ),
            SizedBox(width: 20.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}