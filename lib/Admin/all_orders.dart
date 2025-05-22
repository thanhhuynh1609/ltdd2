import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/notification_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shopping_app/utils/image_helper.dart';

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

  // Thêm hàm hiển thị hình ảnh sản phẩm
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
                  
                  // Gửi thông báo cho người dùng về thay đổi trạng thái
                  String userId = order['UserId'] ?? "";
                  String orderId = order['id'] ?? "";
                  String orderNumber = order['OrderId'] ?? "";
                  
                  if (userId.isNotEmpty) {
                    String title = "Cập nhật đơn hàng";
                    String message = "";
                    String type = "order_status";
                    
                    switch (selectedStatus) {
                      case "Đang vận chuyển":
                        message = "Đơn hàng #$orderNumber của bạn đang được vận chuyển.";
                        break;
                      case "Đã giao hàng":
                        message = "Đơn hàng #$orderNumber của bạn đã được giao thành công.";
                        break;
                      case "Đã hủy":
                        message = "Đơn hàng #$orderNumber của bạn đã bị hủy.";
                        break;
                      default:
                        message = "Đơn hàng #$orderNumber của bạn đang được xử lý.";
                    }
                    
                    await NotificationService.createNotification(
                      userId: userId,
                      title: title,
                      message: message,
                      type: type,
                      orderId: orderId,
                    );
                  }
                  
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
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin đơn hàng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Đơn hàng #${order['OrderId'] ?? 'N/A'}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Thông tin khách hàng
                Text(
                  "Khách hàng: $customerName",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  "Email: $customerEmail",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 12),
                
                // Danh sách sản phẩm
                if (products.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sản phẩm:",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      ...products.map((product) {
                        // Lấy thông tin sản phẩm
                        String productName = product['Name'] ?? 'Sản phẩm';
                        String quantity = product['Quantity'] ?? '1';
                        String price = product['Price'] ?? '0';
                        
                        // Lấy hình ảnh sản phẩm
                        String? imageData;
                        if (product['ProductImage'] != null && product['ProductImage'].toString().isNotEmpty) {
                          imageData = product['ProductImage'];
                        } else if (product['Image'] != null && product['Image'].toString().isNotEmpty) {
                          imageData = product['Image'];
                        }
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              // Hiển thị hình ảnh sản phẩm
                              Container(
                                width: 50,
                                height: 50,
                                child: imageData != null && imageData.isNotEmpty
                                  ? ImageHelper.buildImage(imageData, width: 50, height: 50)
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
                        );
                      }).toList(),
                    ],
                  ),
                
                SizedBox(height: 12),
                // Tổng tiền
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Tổng tiền: ",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "\$$totalAmount",
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
  }

  // Hàm trả về màu dựa trên trạng thái
  Color _getStatusColor(String status) {
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
