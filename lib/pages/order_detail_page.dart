import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'package:shopping_app/utils/image_helper.dart';
import 'package:shopping_app/services/notification_service.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  
  OrderDetailPage({required this.orderData});
  
  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool isLoading = false;
  bool canRequestRefund = false;
  String refundStatus = "";
  TextEditingController reasonController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    checkRefundEligibility();
  }
  
  // Kiểm tra xem đơn hàng có đủ điều kiện để yêu cầu hoàn tiền không
  void checkRefundEligibility() {
    // Lấy thời gian đặt hàng
    if (widget.orderData['CreatedAt'] != null) {
      Timestamp orderTimestamp = widget.orderData['CreatedAt'] as Timestamp;
      DateTime orderDate = orderTimestamp.toDate();
      DateTime now = DateTime.now();
      
      // Tính số ngày từ khi đặt hàng
      int daysSinceOrder = now.difference(orderDate).inDays;
      
      // Kiểm tra trạng thái đơn hàng và thời gian
      String orderStatus = widget.orderData['Status'] ?? '';
      refundStatus = widget.orderData['RefundStatus'] ?? '';
      
      // Chỉ cho phép hoàn tiền nếu:
      // 1. Đơn hàng đã được giao hoặc đang xử lý
      // 2. Trong vòng 7 ngày kể từ khi đặt hàng
      // 3. Chưa có yêu cầu hoàn tiền trước đó
      setState(() {
        canRequestRefund = (orderStatus == 'Đã giao hàng' || orderStatus == 'Đang xử lý') && 
                          daysSinceOrder <= 7 && 
                          refundStatus.isEmpty;
      });
    }
  }
  
  // Hiển thị dialog yêu cầu hoàn tiền
  void showRefundRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Yêu cầu hoàn tiền"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Vui lòng cho biết lý do hoàn tiền:"),
            SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Nhập lý do hoàn tiền",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                submitRefundRequest();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Vui lòng nhập lý do hoàn tiền")),
                );
              }
            },
            child: Text("Gửi yêu cầu"),
          ),
        ],
      ),
    );
  }
  
  // Gửi yêu cầu hoàn tiền
  Future<void> submitRefundRequest() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      String userId = await SharedPreferenceHelper().getUserId() ?? "";
      double amount = double.tryParse(widget.orderData['TotalAmount'] ?? "0") ?? 0.0;
      
      Map<String, dynamic> refundData = {
        'orderId': widget.orderData['id'],
        'userId': userId,
        'reason': reasonController.text.trim(),
        'status': 'pending',
        'amount': amount,
        'requestDate': FieldValue.serverTimestamp(),
        'processDate': null,
        'orderDetails': {
          'orderNumber': widget.orderData['OrderId'],
          'totalAmount': amount,
          'orderDate': widget.orderData['CreatedAt'],
        }
      };
      
      await DatabaseMethods().createRefundRequest(refundData);

      // Tạo thông báo
      await NotificationService.createNotification(
        userId: userId,
        title: "Yêu cầu hoàn tiền",
        message: "Yêu cầu hoàn tiền cho đơn hàng #${widget.orderData['OrderId']} đã được gửi.",
        type: "refund",
        orderId: widget.orderData['id'],
      );

      setState(() {
        isLoading = false;
        refundStatus = 'pending';
        canRequestRefund = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Yêu cầu hoàn tiền đã được gửi"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Hiển thị trạng thái hoàn tiền
  Widget buildRefundStatus() {
    if (refundStatus.isEmpty) {
      return SizedBox.shrink();
    }
    
    Color statusColor;
    String statusText;
    
    switch (refundStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = "Đang chờ xử lý hoàn tiền";
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = "Yêu cầu hoàn tiền đã được chấp nhận";
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = "Yêu cầu hoàn tiền đã bị từ chối";
        break;
      default:
        statusColor = Colors.grey;
        statusText = "Không xác định";
    }
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: statusColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Lấy thông tin đơn hàng
    String orderStatus = widget.orderData['Status'] ?? 'Đang xử lý';
    String orderDate = "N/A";
    if (widget.orderData['CreatedAt'] != null) {
      Timestamp timestamp = widget.orderData['CreatedAt'] as Timestamp;
      orderDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    }
    
    // Lấy danh sách sản phẩm
    List<dynamic> products = widget.orderData['Products'] ?? [];
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn hàng"),
        backgroundColor: Color(0xFF4A5CFF),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin đơn hàng
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Thông tin đơn hàng",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Divider(),
                        buildInfoRow("Mã đơn hàng", widget.orderData['OrderId'] ?? ""),
                        buildInfoRow("Ngày đặt", orderDate),
                        buildInfoRow("Trạng thái", orderStatus),
                        buildInfoRow("Phương thức thanh toán", widget.orderData['PaymentMethod'] ?? ""),
                        buildInfoRow("Tổng tiền", "\$${widget.orderData['TotalAmount'] ?? '0'}"),
                        
                        // Hiển thị trạng thái hoàn tiền nếu có
                        buildRefundStatus(),
                        
                        // Nút yêu cầu hoàn tiền
                        if (canRequestRefund)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              onPressed: showRefundRequestDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                "Yêu cầu hoàn tiền",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Danh sách sản phẩm
                Text(
                  "Sản phẩm đã mua",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> product = products[index];
                    
                    // Lấy hình ảnh sản phẩm
                    String? imageData;
                    if (product['ProductImage'] != null && product['ProductImage'].toString().isNotEmpty) {
                      imageData = product['ProductImage'];
                    } else if (product['Image'] != null && product['Image'].toString().isNotEmpty) {
                      imageData = product['Image'];
                    }
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        leading: Container(
                          width: 60,
                          height: 60,
                          child: imageData != null && imageData.isNotEmpty
                            ? _buildProductImage(imageData)
                            : Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                        title: Text(
                          product['Name'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Số lượng: ${product['Quantity'] ?? '1'}"),
                            Text("Giá: \$${product['Price'] ?? '0'}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
            width: 60,
            height: 60,
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
            width: 60,
            height: 60,
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
}


