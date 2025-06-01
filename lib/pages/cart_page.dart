import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/checkout_page.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> get cartItems => CartService.cartItems;
  double get totalAmount => CartService.getTotalAmount();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      appBar: AppBar(
        backgroundColor: Color(0xfff2f2f2),
        title: Text(
          'Giỏ hàng',
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
            child: cartItems.isEmpty 
                ? _buildEmptyCart() 
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return buildCartItem(cartItems[index]);
                    },
                  ),
          ),
          if (cartItems.isNotEmpty) buildCheckoutButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            "Giỏ hàng của bạn đang trống",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Hãy thêm sản phẩm vào giỏ hàng",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Quay lại trang trước đó để mua sắm
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Tiếp tục mua sắm",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCartItem(CartItem item) {
    // Giải mã base64 từ chuỗi
    Uint8List imageBytes = base64Decode(item.image);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
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
                imageBytes,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 15),
          // Chi tiết sản phẩm
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
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.verified, color: Colors.blue, size: 14),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.color.isNotEmpty || item.size.isNotEmpty)
                  SizedBox(height: 4),
                if (item.color.isNotEmpty || item.size.isNotEmpty)
                  Text(
                    "Màu: ${item.color}${item.size.isNotEmpty ? ' Kích thước: ${item.size}' : ''}",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          // Điều khiển số lượng
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.remove, size: 18),
                      onPressed: () {
                        setState(() {
                          if (item.quantity > 1) {
                            CartService.updateQuantity(item, item.quantity - 1);
                          } else {
                            CartService.removeFromCart(item);
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    item.quantity.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.add, size: 18, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          CartService.updateQuantity(item, item.quantity + 1);
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                "${(item.price * item.quantity).toStringAsFixed(1)}đ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCheckoutButton() {
    return Container(
      margin: EdgeInsets.all(15),
      child: ElevatedButton(
        onPressed: () {
          // Chuyển đến trang thanh toán
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutPage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Thanh toán ${totalAmount.toStringAsFixed(1)}đ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItem {
  final String brand;
  final String name;
  final String color;
  final String size;
  final double price;
  int quantity;
  final String image;
  final String detail;

  CartItem({
    required this.brand,
    required this.name,
    required this.color,
    required this.size,
    required this.price,
    required this.quantity,
    required this.image,
    this.detail = "",
  });
}


