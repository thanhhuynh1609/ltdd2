import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/cart_page.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/cart_service.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem>? buyNowItems; // Thêm tham số cho chức năng mua ngay
  
  const CheckoutPage({Key? key, this.buyNowItems}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? name;
  String? email;
  String? profileImage;
  String shippingAddress = "8281 Jimmy Coves, South Liana, Maine";
  String phoneNumber = "+923378095628";
  String paymentMethod = "Paypal";
  String promoCode = "";
  TextEditingController promoController = TextEditingController();
  
  // Danh sách sản phẩm thanh toán
  List<CartItem> get checkoutItems => widget.buyNowItems ?? CartService.cartItems;

  // Phí vận chuyển cố định
  final double shippingFee = 5.0;
  
  // Tính tổng tiền hàng
  double get subtotal {
    if (widget.buyNowItems != null) {
      return widget.buyNowItems!.fold(0, (sum, item) => sum + (item.price * item.quantity));
    } else {
      return CartService.getTotalAmount();
    }
  }
  
  // Tính thuế (10% tổng tiền hàng)
  double get taxFee => subtotal * 0.1;
  
  // Tính tổng đơn hàng
  double get orderTotal => subtotal + shippingFee + taxFee;

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  getUserInfo() async {
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    profileImage = await SharedPreferenceHelper().getUserProfile();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị tiêu đề khác nhau tùy theo nguồn
    String pageTitle = widget.buyNowItems != null ? "Mua ngay" : "Thanh toán";
    
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      appBar: AppBar(
        backgroundColor: Color(0xfff2f2f2),
        title: Text(
          pageTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh sách sản phẩm
                  buildOrderItems(),
                  
                  // Mã khuyến mãi
                  SizedBox(height: 20),
                  buildPromoCodeSection(),
                  
                  // Thông tin thanh toán
                  SizedBox(height: 20),
                  buildOrderSummary(),
                  
                  // Phương thức thanh toán
                  SizedBox(height: 20),
                  buildPaymentMethod(),
                  
                  // Địa chỉ giao hàng
                  SizedBox(height: 20),
                  buildShippingAddress(),
                ],
              ),
            ),
          ),
          
          // Nút thanh toán
          buildCheckoutButton(),
        ],
      ),
    );
  }

  Widget buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sản phẩm",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: checkoutItems.length,
          itemBuilder: (context, index) {
            CartItem item = checkoutItems[index];
            return Container(
              margin: EdgeInsets.only(bottom: 15),
              child: Row(
                children: [
                  // Hình ảnh sản phẩm
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(item.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  
                  // Thông tin sản phẩm
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.brand,
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
                        SizedBox(height: 4),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Số lượng: ${item.quantity} x \$${item.price}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Giá
                  Text(
                    "\$${(item.price * item.quantity).toStringAsFixed(1)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildPromoCodeSection() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: promoController,
              decoration: InputDecoration(
                hintText: "Bạn có mã khuyến mãi? Nhập tại đây",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Xử lý mã khuyến mãi
              setState(() {
                promoCode = promoController.text;
              });
            },
            child: Text("Áp dụng"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tổng đơn hàng",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        buildSummaryRow("Tạm tính", "\$${subtotal.toStringAsFixed(1)}"),
        buildSummaryRow("Phí vận chuyển", "\$${shippingFee.toStringAsFixed(1)}"),
        buildSummaryRow("Thuế", "\$${taxFee.toStringAsFixed(1)}"),
        Divider(height: 30),
        buildSummaryRow(
          "Tổng cộng", 
          "\$${orderTotal.toStringAsFixed(1)}", 
          isBold: true
        ),
      ],
    );
  }

  Widget buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
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
              color: Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Phương thức thanh toán",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Mở dialog chọn phương thức thanh toán
              },
              child: Text(
                "Thay đổi",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.paypal, color: Colors.white),
            ),
            SizedBox(width: 15),
            Text(
              paymentMethod,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildShippingAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Địa chỉ giao hàng",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Mở dialog thay đổi địa chỉ
              },
              child: Text(
                "Thay đổi",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "Coding with T",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.phone, size: 16, color: Colors.grey),
            SizedBox(width: 5),
            Text(
              phoneNumber,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey),
            SizedBox(width: 5),
            Expanded(
              child: Text(
                shippingAddress,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildCheckoutButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () async {
          // Lưu đơn hàng vào cơ sở dữ liệu
          try {
            // Tạo ID đơn hàng duy nhất
            String orderId = DateTime.now().millisecondsSinceEpoch.toString();
            
            // Lấy danh sách sản phẩm cần thanh toán
            List<CartItem> itemsToCheckout = checkoutItems;
            
            // Tạo một document đơn hàng chính
            Map<String, dynamic> orderMap = {
              "OrderId": orderId,
              "CustomerName": name ?? "",
              "CustomerEmail": email ?? "",
              "CustomerImage": profileImage ?? "",
              "ShippingAddress": shippingAddress,
              "PhoneNumber": phoneNumber,
              "PaymentMethod": paymentMethod,
              "TotalAmount": orderTotal.toString(),
              "Status": "Đang xử lý",
              "UserId": await SharedPreferenceHelper().getUserId(),
              "CreatedAt": FieldValue.serverTimestamp(), // Thêm thời gian tạo đơn hàng
              "Products": itemsToCheckout.map((item) => {
                "Name": item.name,
                "Price": item.price.toString(),
                "Quantity": item.quantity,
                "Brand": item.brand,
                "Detail": item.detail,
                // Lưu trữ tham chiếu đến hình ảnh thay vì base64
                "ImageRef": "products/${item.brand}_${item.name.replaceAll(' ', '_')}", 
              }).toList(),
            };

            await DatabaseMethods().createOrder(orderMap);

            // Nếu thanh toán từ giỏ hàng, xóa giỏ hàng
            if (widget.buyNowItems == null) {
              CartService.clearCart();
            }

            // Lưu biến mounted để kiểm tra trạng thái widget
            final isMounted = mounted;
            
            // Hiển thị thông báo thành công nếu widget vẫn mounted
            if (isMounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Đặt hàng thành công!"),
                  backgroundColor: Colors.green,
                ),
              );

              // Quay về trang chủ
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } catch (e) {
            print("Lỗi khi đặt hàng: $e");
            // Kiểm tra mounted trước khi sử dụng context
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Đặt hàng thất bại. Vui lòng thử lại."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          "Thanh toán",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}





