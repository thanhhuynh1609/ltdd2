import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/cart_service.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'package:shopping_app/pages/login.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Stream<QuerySnapshot>? favoritesStream;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  void loadFavorites() async {
    if (FirebaseAuth.instance.currentUser != null) {
      favoritesStream = await DatabaseMethods()
          .getFavorites(FirebaseAuth.instance.currentUser!.email!);
      setState(() {
        isLoading = false;
      });
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
        title: Text("Sản phẩm yêu thích"),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : FirebaseAuth.instance.currentUser == null
              ? Center(
                  child: Text(
                    "Vui lòng đăng nhập để xem sản phẩm yêu thích",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: favoritesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Bạn chưa có sản phẩm yêu thích nào",
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot doc = snapshot.data!.docs[index];
                        Map<String, dynamic> data = 
                            doc.data() as Map<String, dynamic>;
                        
                        // Giải mã base64 từ Firestore
                        String base64Image = data["ProductImage"] ?? "";
                        Uint8List bytes = base64Decode(base64Image);
                        
                        return Card(
                          elevation: 3,
                          margin: EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetail(
                                    detail: data["ProductDetail"] ?? "",
                                    image: data["ProductImage"] ?? "",
                                    name: data["ProductName"] ?? "",
                                    price: data["ProductPrice"] ?? "0",
                                  ),
                                ),
                              ).then((_) {
                                // Refresh khi quay lại
                                setState(() {});
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hình ảnh sản phẩm
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        bytes,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Thông tin sản phẩm
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: 
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data["ProductName"] ?? "",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "${data["ProductPrice"] ?? "0"}đ",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          children: [
                                            // Nút thêm vào giỏ hàng
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // Sử dụng phương thức mới
                                                  addToCart(data, context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                ),
                                                child: Text("Thêm vào giỏ"),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            // Nút xóa khỏi yêu thích
                                            IconButton(
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection("Favorites")
                                                    .doc(doc.id)
                                                    .delete();
                                                
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        "Đã xóa khỏi danh sách yêu thích"),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              },
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  Future<void> addToCart(Map<String, dynamic> data, BuildContext context) async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng đăng nhập để thêm vào giỏ hàng"),
          backgroundColor: Colors.red,
        ),
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
        "Price": data["ProductPrice"] ?? "0",
        "Product": data["ProductName"] ?? "",
        "ProductImage": data["ProductImage"] ?? "",
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
}




