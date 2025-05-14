import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopping_app/utils/image_helper.dart';

class OrderDetails extends StatefulWidget {
  final String orderId;
  
  const OrderDetails({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  bool isLoading = true;
  Map<String, dynamic>? orderData;
  
  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }
  
  Future<void> _fetchOrderDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Orders")
          .doc(widget.orderId)
          .get();
          
      if (doc.exists) {
        setState(() {
          orderData = doc.data() as Map<String, dynamic>?;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi khi lấy chi tiết đơn hàng: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn hàng"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orderData == null
              ? Center(child: Text("Không tìm thấy thông tin đơn hàng"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderHeader(),
                      SizedBox(height: 20),
                      _buildProductDetails(),
                      SizedBox(height: 20),
                      _buildOrderStatus(),
                      SizedBox(height: 20),
                      _buildPriceDetails(),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildOrderHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Đơn hàng #${widget.orderId.substring(0, 8)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Ngày đặt: ${_formatDate(orderData?['OrderDate'])}",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chi tiết sản phẩm",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                ImageHelper.buildImage(
                  orderData?['ProductImage'],
                  width: 80,
                  height: 80,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderData?['Product'] ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Giá: \$${orderData?['Price'] ?? '0'}",
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderStatus() {
    String status = orderData?['Status'] ?? "Đang xử lý";
    Color statusColor = _getStatusColor(status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Trạng thái đơn hàng",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chi tiết thanh toán",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Giá sản phẩm"),
                Text("\$${orderData?['Price'] ?? '0'}"),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tổng cộng",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "\$${orderData?['Price'] ?? '0'}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return "N/A";
    
    try {
      if (date is Timestamp) {
        DateTime dateTime = date.toDate();
        return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
      } else if (date is DateTime) {
        return "${date.day}/${date.month}/${date.year}";
      } else if (date is String) {
        // Thử parse chuỗi ngày tháng
        DateTime? dateTime = DateTime.tryParse(date);
        if (dateTime != null) {
          return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
        }
      }
    } catch (e) {
      print("Lỗi khi format ngày: $e");
    }
    
    return "N/A";
  }
  
  Color _getStatusColor(String status) {
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