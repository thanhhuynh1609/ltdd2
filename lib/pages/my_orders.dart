import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';

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
        title: Text(
          "Đơn hàng của tôi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userId == null || userId!.isEmpty
              ? Center(child: Text("Vui lòng đăng nhập để xem đơn hàng"))
              : orders.isEmpty
                  ? Center(
                      child: Text(
                        "Bạn chưa có đơn hàng nào",
                        style: AppWidget.semiboldTextFeildStyle(),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        var orderData = orders[index];
                        
                        // Lấy thông tin đơn hàng
                        String status = orderData['Status'] ?? "Đang xử lý";
                        String totalAmount = orderData['TotalAmount'] ?? "0";
                        
                        // Lấy danh sách sản phẩm
                        List<dynamic> products = orderData['Products'] ?? [];
                        
                        // Nếu không có sản phẩm, bỏ qua đơn hàng này
                        if (products.isEmpty) {
                          return SizedBox();
                        }
                        
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
                                      "Đơn hàng #${orderData['id'].toString().substring(0, 8)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Sản phẩm:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Danh sách sản phẩm
                                ...products.map((product) {
                                  String productName = product['Name'] ?? "Sản phẩm";
                                  int quantity = product['Quantity'] ?? 1;
                                  String price = product['Price'] ?? "0";
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        // Sử dụng placeholder thay vì cố gắng hiển thị ảnh
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey[200],
                                          ),
                                          child: Icon(Icons.shopping_bag, color: Colors.grey),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                productName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "$quantity x \$$price",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Tổng tiền:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "\$$totalAmount",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xfffd6f3e),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
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







