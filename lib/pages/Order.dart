import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'dart:convert';

class Order extends StatefulWidget {
  const Order({Key? key}) : super(key: key);

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? id = "";
  Stream? orderStream;

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  getUserId() async {
    id = await SharedPreferenceHelper().getUserId();
    getOrderData();
  }

  getOrderData() async {
    orderStream = await DatabaseMethods().getOrders(id!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Đơn hàng của tôi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.0),
        child: StreamBuilder(
          stream: orderStream,
          builder: (context, AsyncSnapshot snapshot) {
            return snapshot.hasData
                ? ListView.builder(
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapshot.data.docs[index];
                      
                      // Kiểm tra xem trường Status có tồn tại không
                      String status = ds["Status"] ?? "Đang xử lý";
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 20.0),
                        child: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: 
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Đơn hàng #${ds.id.substring(0, 8)}",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10, 
                                        vertical: 5
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                // Hiển thị danh sách sản phẩm
                                if (ds["Products"] != null)
                                  ...buildProductList(ds["Products"]),
                                SizedBox(height: 10),
                                Divider(),
                                Row(
                                  mainAxisAlignment: 
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Tổng tiền:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "\$${ds["TotalAmount"] ?? "0"}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xfffd6f3e),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  // Hàm tạo danh sách widget hiển thị sản phẩm
  List<Widget> buildProductList(List<dynamic> products) {
    List<Widget> productWidgets = [];
    
    for (var product in products) {
      // Lấy thông tin sản phẩm
      String productName = product['Name'] ?? '';
      String quantity = product['Quantity'] ?? '1';
      String price = product['Price'] ?? '0';
      
      // Lấy hình ảnh sản phẩm
      String? imageData;
      if (product['ProductImage'] != null && product['ProductImage'].toString().isNotEmpty) {
        imageData = product['ProductImage'];
      } else if (product['Image'] != null && product['Image'].toString().isNotEmpty) {
        imageData = product['Image'];
      }
      
      productWidgets.add(
        Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              // Hiển thị hình ảnh sản phẩm
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: imageData != null && imageData.isNotEmpty
                  ? _buildProductImage(imageData)
                  : Icon(Icons.image_not_supported, color: Colors.grey),
              ),
              SizedBox(width: 10),
              // Thông tin sản phẩm
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "$quantity x \$$price",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return productWidgets;
  }

  // Hàm hiển thị hình ảnh sản phẩm
  Widget _buildProductImage(String imageData) {
    try {
      // Kiểm tra xem imageData có phải là URL không
      if (imageData.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageData,
            fit: BoxFit.cover,
            width: 50,
            height: 50,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image_not_supported, color: Colors.grey);
            },
          ),
        );
      } else {
        // Giả định imageData là chuỗi base64
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(imageData),
            fit: BoxFit.cover,
            width: 50,
            height: 50,
            errorBuilder: (context, error, stackTrace) {
              print("Lỗi hiển thị ảnh: $error");
              return Icon(Icons.image_not_supported, color: Colors.grey);
            },
          ),
        );
      }
    } catch (e) {
      print("Lỗi xử lý ảnh: $e");
      return Icon(Icons.image_not_supported, color: Colors.grey);
    }
  }

  // Hàm trả về màu dựa trên trạng thái
  Color getStatusColor(String status) {
    switch (status) {
      case "Đã giao hàng":
        return Colors.green;
      case "Đang giao hàng":
        return Colors.blue;
      case "Đã hủy":
        return Colors.red;
      default:
        return Color(0xfffd6f3e); // Đang xử lý
    }
  }
}
