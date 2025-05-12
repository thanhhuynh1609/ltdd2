import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/cart_page.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/cart_service.dart';

class CategoryProduct extends StatefulWidget {
  final String category;
  const CategoryProduct({super.key, required this.category});

  @override
  State<CategoryProduct> createState() => _CategoryProductState();
}

class _CategoryProductState extends State<CategoryProduct> {
  Stream? CategoryStream;

  @override
  void initState() {
    getCategoryProducts();
    super.initState();
  }

  getCategoryProducts() async {
    CategoryStream = FirebaseFirestore.instance
        .collection(widget.category)
        .snapshots();
    setState(() {});
  }

  // Hàm thêm sản phẩm vào giỏ hàng
  void addToCart(String name, String price, String imageBase64, String detail) {
    // Chuyển đổi giá từ String sang double
    double priceValue = double.tryParse(price) ?? 0.0;
    
    // Tạo đối tượng CartItem
    CartItem item = CartItem(
      brand: widget.category,
      name: name,
      color: "",
      size: "",
      price: priceValue,
      quantity: 1,
      image: imageBase64,
      detail: detail,
    );
    
    // Thêm vào giỏ hàng
    CartService.addToCart(item);
  }

  // Hàm hiển thị sản phẩm từ Firestore
  Widget allProducts() {
    return StreamBuilder(
      stream: CategoryStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];

                  // Giải mã base64 từ Firestore
                  String base64Image = ds["Image"];
                  Uint8List bytes = base64Decode(base64Image);

                  return Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Khi nhấn vào hình ảnh sẽ chuyển đến trang chi tiết
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => ProductDetail(
                                  detail: ds["Detail"], 
                                  image: ds["Image"], 
                                  name: ds["Name"], 
                                  price: ds["Price"]
                                )
                              )
                            );
                          },
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                              child: Image.memory(
                                bytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ds["Name"],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 5),
                              Text(
                                ds["Detail"],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${ds["Price"]}đ",
                                    style: TextStyle(
                                      color: Color(0xfffd6f3e),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // Thêm sản phẩm vào giỏ hàng
                                      addToCart(ds["Name"], ds["Price"], ds["Image"], ds["Detail"]);
                                      
                                      // Hiển thị thông báo
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Đã thêm sản phẩm vào giỏ hàng"),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Color(0xfffd6f3e),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: AppWidget.boldTextFeildStyle(),
        ),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: allProducts(),
      ),
    );
  }
}

