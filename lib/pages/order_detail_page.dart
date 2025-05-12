import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  final DocumentSnapshot orderData;

  const OrderDetailPage({
    Key? key,
    required this.orderId,
    required this.orderData,
  }) : super(key: key);

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  Widget build(BuildContext context) {
    // Lấy thông tin chung từ đơn hàng
    Timestamp createdAt = widget.orderData['CreatedAt'] ?? Timestamp.now();
    String orderDate = DateFormat('dd MMM yyyy').format(createdAt.toDate());
    
    // Tính ngày giao hàng dự kiến (5 ngày sau ngày đặt)
    DateTime estimatedDelivery = createdAt.toDate().add(Duration(days: 5));
    String deliveryDate = DateFormat('dd MMM yyyy').format(estimatedDelivery);
    
    String status = widget.orderData['Status'] ?? "Đang xử lý";
    String customerName = widget.orderData['CustomerName'] ?? "Khách hàng";
    String customerEmail = widget.orderData['CustomerEmail'] ?? "";
    String shippingAddress = widget.orderData['ShippingAddress'] ?? "Chưa có địa chỉ";
    String phoneNumber = widget.orderData['PhoneNumber'] ?? "Chưa có số điện thoại";
    String orderCode = "CWT" + widget.orderId.substring(0, 4).toUpperCase();
    
    // Lấy danh sách sản phẩm
    List<dynamic> products = widget.orderData['Products'] ?? [];
    
    // Tính tổng giá trị đơn hàng
    double totalAmount = double.tryParse(widget.orderData['TotalAmount'] ?? "0") ?? 0;

    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      appBar: AppBar(
        backgroundColor: Color(0xfff2f2f2),
        title: Text(
          "Chi tiết đơn hàng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thông tin trạng thái đơn hàng
            buildOrderStatusCard(status, orderDate, orderCode, deliveryDate),
            
            SizedBox(height: 16),
            
            // Thông tin sản phẩm
            buildProductsCard(products),
            
            SizedBox(height: 16),
            
            // Thông tin giao hàng
            buildShippingInfoCard(customerName, phoneNumber, shippingAddress),
            
            SizedBox(height: 16),
            
            // Thông tin thanh toán
            buildPaymentSummaryCard(totalAmount),
          ],
        ),
      ),
    );
  }

  Widget buildOrderStatusCard(
    String status,
    String orderDate,
    String orderCode,
    String deliveryDate,
  ) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header với trạng thái
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  getStatusIcon(status),
                  color: getStatusColor(status),
                  size: 24,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getStatusText(status),
                      style: TextStyle(
                        color: getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Order placed on $orderDate",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Thông tin đơn hàng
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                buildInfoRow(
                  "Order Number",
                  orderCode,
                  Icons.receipt_outlined,
                ),
                SizedBox(height: 16),
                buildInfoRow(
                  "Expected Delivery",
                  deliveryDate,
                  Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductsCard(List<dynamic> products) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Sản phẩm đã đặt",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              var product = products[index];
              String productName = product['Name'] ?? "Sản phẩm";
              double price = double.parse(product['Price'] ?? "0");
              int quantity = product['Quantity'] ?? 1;
              String brand = product['Brand'] ?? "";
              
              // Giải mã base64 từ Firestore
              String base64Image = product["Image"] ?? "";
              Uint8List? imageBytes;

              try {
                imageBytes = base64Decode(base64Image);
              } catch (e) {
                print("Error decoding base64 image: $e");
                imageBytes = null;
              }

              return Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Hình ảnh sản phẩm
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageBytes != null
                            ? Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Thông tin sản phẩm
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (brand.isNotEmpty)
                            Row(
                              children: [
                                Text(
                                  brand,
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.verified, color: Colors.blue, size: 14),
                              ],
                            ),
                          if (brand.isNotEmpty)
                            SizedBox(height: 4),
                          Text(
                            productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Số lượng: $quantity",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "\$${price.toStringAsFixed(1)}",
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildShippingInfoCard(
    String name,
    String phone,
    String address,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Shipping Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        phone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
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

  Widget buildPaymentSummaryCard(double subtotal) {
    // Phí vận chuyển cố định
    final double shippingFee = 5.0;
    
    // Tính thuế (10% tổng tiền hàng)
    final double taxFee = subtotal * 0.1;
    
    // Tính tổng đơn hàng
    final double orderTotal = subtotal + shippingFee + taxFee;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            buildSummaryRow("Subtotal", "\$${subtotal.toStringAsFixed(1)}"),
            SizedBox(height: 8),
            buildSummaryRow("Shipping Fee", "\$${shippingFee.toStringAsFixed(1)}"),
            SizedBox(height: 8),
            buildSummaryRow("Tax", "\$${taxFee.toStringAsFixed(1)}"),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            buildSummaryRow(
              "Total",
              "\$${orderTotal.toStringAsFixed(1)}",
              isBold: true,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payment,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Payment Method: ",
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "Paypal",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.black : Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isBold ? Colors.blue[700] : Colors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }

  // Màu sắc dựa trên trạng thái đơn hàng
  Color getStatusColor(String status) {
    switch (status) {
      case "Đang xử lý":
        return Colors.blue;
      case "Đang giao hàng":
      case "On the way":
        return Colors.orange;
      case "Đã giao hàng":
      case "Delivered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Icon dựa trên trạng thái đơn hàng
  IconData getStatusIcon(String status) {
    switch (status) {
      case "Đang xử lý":
        return Icons.pending_actions;
      case "Đang giao hàng":
      case "On the way":
        return Icons.local_shipping;
      case "Đã giao hàng":
      case "Delivered":
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  // Text hiển thị dựa trên trạng thái đơn hàng
  String getStatusText(String status) {
    switch (status) {
      case "Đang xử lý":
        return "Processing";
      case "Đang giao hàng":
      case "On the way":
        return "Shipment on the way";
      case "Đã giao hàng":
      case "Delivered":
        return "Delivered";
      default:
        return status;
    }
  }
  
  DateFormat(String s) {}
}



