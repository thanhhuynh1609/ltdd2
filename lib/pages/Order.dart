import 'dart:convert'; // Để sử dụng base64Decode
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? email;

  // Lấy email từ SharedPreferences
  Future<void> getSharedPref() async {
    email = await SharedPreferenceHelper().getUserEmail();
    setState(() {});
  }

  Stream? orderStream;

  // Tải dữ liệu khi khởi tạo
  Future<void> loadOrders() async {
    await getSharedPref();
    if (email != null) {
      orderStream = await DatabaseMethods().getOrders(email!);
    }
    setState(() {});
  }

  @override
  void initState() {
    loadOrders();
    super.initState();
  }

  // Widget hiển thị tất cả các đơn hàng
  Widget allOrders() {
    return StreamBuilder(
      stream: orderStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data.docs.isEmpty) {
          return Center(
            child: Text("No orders found", style: AppWidget.semiboldTextFeildStyle()),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];

            // Giải mã base64 từ Firestore
            String base64Image = ds["ProductImage"];
            Uint8List? imageBytes;

            try {
              imageBytes = base64Decode(base64Image);
            } catch (e) {
              print("Error decoding base64 image: $e");
              imageBytes = null;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hiển thị ảnh từ base64 hoặc placeholder nếu lỗi
                          imageBytes != null
                              ? Image.memory(
                                  imageBytes,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 120,
                                  width: 120,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image_not_supported),
                                ),
                          SizedBox(width: 50),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20,),
                                  Text(
                                    ds["Product"],
                                    style: AppWidget.semiboldTextFeildStyle(),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "\$${ds["Price"]}",
                                    style: TextStyle(
                                      color: Color(0xfffd6f3e),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Status: " + ds["Status"],
                                    style: TextStyle(
                                      color: Color(0xfffd6f3e),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xfff2f2f2),
        title: Center(
          child: Text(
            "Current Orders",
            style: AppWidget.boldTextFeildStyle(),
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Expanded(child: allOrders())
          ],
        ),
      ),
    );
  }
}