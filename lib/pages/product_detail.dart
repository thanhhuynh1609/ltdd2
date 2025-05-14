import 'dart:convert'; // Để sử dụng base64Decode
import 'dart:typed_data'; // Để sử dụng Uint8List

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/cart_page.dart';
import 'package:shopping_app/pages/checkout_page.dart';
import 'package:shopping_app/pages/login.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/cart_service.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';

class ProductDetail extends StatefulWidget {
  String image, name, detail, price;
  ProductDetail(
      {required this.detail,
      required this.image,
      required this.name,
      required this.price});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  int quantity = 1; // Thêm biến số lượng
  String? name;
  String? mail;
  String? image;

  @override
  void initState() {
    super.initState();
    getthesharedpref();
  }

  getthesharedpref() async {
    name = await SharedPreferenceHelper().getUserName();
    mail = await SharedPreferenceHelper().getUserEmail();
    image = await SharedPreferenceHelper().getUserProfile();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Giải mã base64 từ chuỗi
    Uint8List imageBytes = base64Decode(widget.image);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần hình ảnh sản phẩm chính
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: double.infinity,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
              
              // Phần thumbnail ảnh
              Container(
                height: 80,
                child: Row(
                  children: [
                    // Thumbnail đầu tiên (ảnh hiện tại)
                    Container(
                      width: 70,
                      height: 70,
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Thêm các thumbnail giả
                    for (int i = 0; i < 3; i++)
                      Container(
                        width: 70,
                        height: 70,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Đánh giá và chia sẻ
              Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(
                        " 5.0 (199)",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Icon(Icons.share, color: Colors.grey.shade700),
                ],
              ),
              
              SizedBox(height: 10),
              
              // Giá và giảm giá
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "-78%",
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "\$${widget.price} - \$334.0",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
              
              // Tên sản phẩm
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(height: 10),
              
              // Tình trạng kho
              Row(
                children: [
                  Text(
                    "Stock: ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    "In Stock",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
              
              // Thương hiệu
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey.shade700),
                  SizedBox(width: 5),
                  Text(
                    "Nike",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.verified, size: 14, color: Colors.blue),
                ],
              ),
              
              SizedBox(height: 15),
              
              // Phần variation
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Variation:",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Price: \$234.0",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Stock: Out of Stock",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Phần chọn màu
              Text(
                "Color",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              
              SizedBox(height: 10),
              
              // Các màu sắc
              Row(
                children: [
                  buildColorOption(Colors.green, true),
                  SizedBox(width: 15),
                  buildColorOption(Colors.red, false),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Phần chọn kích thước
              Text(
                "Size",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              
              SizedBox(height: 10),
              
              // Các kích thước
              Row(
                children: [
                  buildSizeOption("EU 30", false),
                  SizedBox(width: 10),
                  buildSizeOption("EU 32", false),
                  SizedBox(width: 10),
                  buildSizeOption("EU 34", true),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Nút thanh toán
              ElevatedButton(
                onPressed: () {
                  // Tạo danh sách chỉ chứa sản phẩm này
                  double priceValue = double.tryParse(widget.price) ?? 0.0;
                  CartItem item = CartItem(
                    brand: "Nike",
                    name: widget.name,
                    color: "Green",
                    size: "EU 34",
                    price: priceValue,
                    quantity: quantity,
                    image: widget.image,
                    detail: widget.detail,
                  );
                  
                  // Chuyển đến trang thanh toán với chỉ sản phẩm này
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        buyNowItems: [item],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Checkout",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Phần mô tả
              Text(
                "Description",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              
              SizedBox(height: 8),
              
              Text(
                widget.detail.isNotEmpty 
                    ? widget.detail 
                    : "Nike Air Jordan Shoes for running. Quality product. Long Lasting.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              
              SizedBox(height: 16),
              
              // Phần đánh giá
              Divider(height: 1, color: Colors.grey.shade300),
              
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Reviews (199)",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
              
              SizedBox(height: 80), // Thêm khoảng trống cho bottom bar
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Phần điều chỉnh số lượng
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Nút giảm
                  IconButton(
                    icon: Icon(Icons.remove, size: 18),
                    onPressed: () {
                      setState(() {
                        if (quantity > 1) quantity--;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                  
                  // Hiển thị số lượng
                  Container(
                    width: 30,
                    alignment: Alignment.center,
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Nút tăng
                  IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: () {
                      setState(() {
                        quantity++;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 16),
            
            // Nút thêm vào giỏ hàng
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Thêm sản phẩm vào giỏ hàng
                  double priceValue = double.tryParse(widget.price) ?? 0.0;
                  CartItem item = CartItem(
                    brand: "Nike",
                    name: widget.name,
                    color: "Green",
                    size: "EU 34",
                    price: priceValue,
                    quantity: quantity,
                    image: widget.image,
                    detail: widget.detail,
                  );
                  CartService.addToCart(item);
                  
                  // Gọi phương thức addToCart với context
                  addToCart(widget, context);
                },
                icon: Icon(Icons.shopping_bag_outlined, color: Colors.white),
                label: Text(
                  "Add to Bag",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget tùy chỉnh cho lựa chọn màu sắc
  Widget buildColorOption(Color color, bool isSelected) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.black : Colors.transparent,
          width: 2,
        ),
      ),
      child: isSelected 
          ? Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            )
          : null,
    );
  }

  // Widget tùy chỉnh cho lựa chọn kích thước
  Widget buildSizeOption(String size, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: Text(
        size,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Khi thêm sản phẩm vào giỏ hàng, lưu cả ProductImage
Future<void> addToCart(dynamic widget, BuildContext context) async {
  if (FirebaseAuth.instance.currentUser == null) {
    // Chuyển hướng đến trang đăng nhập
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
    return;
  }

  try {
    // Lấy thông tin người dùng
    String? userEmail = FirebaseAuth.instance.currentUser!.email;
    String? userName = await SharedPreferenceHelper().getUserName();
    String? userImage = await SharedPreferenceHelper().getUserProfile();
    
    // Lấy thông tin sản phẩm
    Map<String, dynamic> productData = {
      "Email": userEmail,
      "Image": userImage ?? "",
      "Name": userName ?? "",
      "Price": widget.price,
      "Product": widget.name,
      "ProductImage": widget.image,
      "Status": "Processing"
    };
    
    // Thêm vào giỏ hàng
    await DatabaseMethods().addToCart(productData);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đã thêm vào giỏ hàng"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print("Lỗi khi thêm vào giỏ hàng: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Lỗi: Không thể thêm vào giỏ hàng"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
