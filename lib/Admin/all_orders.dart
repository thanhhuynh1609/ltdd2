import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'dart:convert';
import 'dart:typed_data';

class AllOrders extends StatefulWidget {
  const AllOrders({Key? key}) : super(key: key);

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String selectedStatus = "Tất cả";

  // Phương pháp an toàn để hiển thị bất kỳ giá trị nào từ Firestore
  String safeString(dynamic value) {
    if (value == null) return "";
    if (value is int || value is double) return value.toString();
    if (value is String) return value;
    return value.toString();
  }

  // Thêm một hàm mới để lấy một phần của chuỗi một cách an toàn
  String safeSubstring(String text, int start, int end) {
    if (text.isEmpty) return "";
    if (text.length <= start) return text;
    if (text.length <= end) return text.substring(start);
    return text.substring(start, end);
  }

  @override
  void initState() {
    getOrders();
    super.initState();
  }

  getOrders() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Orders")
          .orderBy("CreatedAt", descending: true)
          .get();
      
      orders = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
        
        // Thêm ID của document
        orderData['id'] = doc.id;
        
        // Xử lý danh sách sản phẩm để đảm bảo có trường ProductImage
        if (orderData.containsKey('Products') && orderData['Products'] is List) {
          List<dynamic> products = orderData['Products'];
          List<Map<String, dynamic>> updatedProducts = [];
          
          for (var product in products) {
            if (product is Map<String, dynamic>) {
              // Tạo bản sao để tránh thay đổi dữ liệu gốc
              Map<String, dynamic> updatedProduct = Map<String, dynamic>.from(product);
              
              // Đảm bảo có trường ProductImage
              if (!updatedProduct.containsKey('ProductImage') && 
                  updatedProduct.containsKey('Image') && 
                  updatedProduct['Image'] != null) {
                updatedProduct['ProductImage'] = updatedProduct['Image'];
              }
              
              updatedProducts.add(updatedProduct);
            }
          }
          
          // Cập nhật lại danh sách sản phẩm
          orderData['Products'] = updatedProducts;
        }
        
        orders.add(orderData);
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi lấy danh sách đơn hàng: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Lọc đơn hàng theo trạng thái
  List<Map<String, dynamic>> getFilteredOrders() {
    if (selectedStatus == "Tất cả") {
      return orders;
    } else {
      return orders.where((order) => order['Status'] == selectedStatus).toList();
    }
  }

  void showStatusUpdateDialog(Map<String, dynamic> order) {
    String selectedStatus = order['Status'] ?? 'Đang xử lý';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cập nhật trạng thái đơn hàng"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Chọn trạng thái mới:"),
              SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedStatus = newValue;
                  }
                },
                items: [
                  "Đang xử lý",
                  "Đang vận chuyển",
                  "Đã giao hàng",
                  "Đã hủy",
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Cập nhật trạng thái đơn hàng
                  await FirebaseFirestore.instance
                      .collection("Orders")
                      .doc(order['id'])
                      .update({"Status": selectedStatus});
                  
                  // Cập nhật trạng thái trong danh sách local
                  setState(() {
                    int index = orders.indexWhere((o) => o['id'] == order['id']);
                    if (index != -1) {
                      orders[index]['Status'] = selectedStatus;
                    }
                  });
                  
                  Navigator.pop(context);
                  
                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Đã cập nhật trạng thái đơn hàng"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Lỗi: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("Cập nhật"),
            ),
          ],
        );
      },
    );
  }

  // Thêm phương thức xóa đơn hàng
  void deleteOrder(String orderId) async {
    try {
      // Hiển thị dialog xác nhận
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có chắc chắn muốn xóa đơn hàng này?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Xóa", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (!confirmDelete) return;

      // Xóa đơn hàng từ Firestore
      await FirebaseFirestore.instance
          .collection("Orders")
          .doc(orderId)
          .delete();
      
      // Cập nhật danh sách đơn hàng local
      setState(() {
        orders.removeWhere((order) => order['id'] == orderId);
      });
      
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã xóa đơn hàng thành công"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error deleting order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi xóa đơn hàng: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      appBar: AppBar(
        backgroundColor: Color(0xfff2f2f2),
        title: Text(
          'Quản lý đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bộ lọc trạng thái
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        "Lọc theo trạng thái: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: [
                              "Tất cả",
                              "Đang xử lý",
                              "Đang giao hàng",
                              "Đã giao hàng",
                              "Đã hủy"
                            ].map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Nút làm mới
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                      getOrders();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text(""),
                    style: ElevatedButton.styleFrom(
                    
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                ),
                // Danh sách đơn hàng
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: buildOrdersList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildOrdersList() {
    List<Map<String, dynamic>> filteredOrders = getFilteredOrders();
    
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (filteredOrders.isEmpty) {
      return Center(child: Text("Không có đơn hàng nào"));
    }
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> order = filteredOrders[index];
        
        // Sử dụng hàm safeString cho tất cả các giá trị
        String status = safeString(order['Status']);
        String customerName = safeString(order['CustomerName']);
        String customerEmail = safeString(order['CustomerEmail']);
        String totalAmount = safeString(order['TotalAmount']);
        
        // Lấy danh sách sản phẩm
        List<dynamic> products = [];
        if (order['Products'] != null && order['Products'] is List) {
          products = order['Products'] as List<dynamic>;
        }
        
        return GestureDetector(
          onTap: () {
            // Hiển thị dialog cập nhật trạng thái
            showStatusUpdateDialog(order);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.all(15),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần header của đơn hàng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Đơn hàng #${safeSubstring(safeString(order['id']), 0, 8)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: getStatusColor(status),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            status.isEmpty ? "Đang xử lý" : status,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 10),
                    
                    // Thông tin khách hàng
                    Text(
                      "Tên: " + (customerName.isEmpty ? "User" : customerName),
                      style: AppWidget.semiboldTextFeildStyle(),
                    ),
                    Text(
                      "Email: " + (customerEmail.isEmpty ? "leanh@example.com" : customerEmail),
                      style: AppWidget.lightTextFeildStyle(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 15),
                    
                    // Danh sách sản phẩm
                    ...products.map((product) {
                      String productName = safeString(product['Name']);
                      String productPrice = safeString(product['Price']);
                      String productQuantity = safeString(product['Quantity']);
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            // Icon sản phẩm
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.shopping_bag,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 10),
                            // Thông tin sản phẩm
                            Expanded(
                              child: Text(
                                "$productName\n$productQuantity x \$${productPrice}",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    // Đường kẻ phân cách
                    Divider(height: 20, thickness: 1),
                    
                    // Tổng tiền
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
                          "\$${totalAmount.isEmpty ? "0" : totalAmount}",
                          style: TextStyle(
                            color: Color(0xfffd6f3e),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 10),
                    
                    // Các nút hành động
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Nút cập nhật trạng thái
                        GestureDetector(
                          onTap: () {
                            showStatusUpdateDialog(order);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(
                              "Cập nhật",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        // Nút xóa
                        GestureDetector(
                          onTap: () {
                            deleteOrder(order['id']);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(
                              "Xóa",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
