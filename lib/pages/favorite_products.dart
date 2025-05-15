import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'dart:convert';
import 'dart:typed_data';

class FavoriteProducts extends StatefulWidget {
  const FavoriteProducts({Key? key}) : super(key: key);

  @override
  State<FavoriteProducts> createState() => _FavoriteProductsState();
}

class _FavoriteProductsState extends State<FavoriteProducts> {
  String? userId;
  bool isLoading = true;
  List<Map<String, dynamic>> favoriteProducts = [];

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  getUserId() async {
    userId = await SharedPreferenceHelper().getUserId();
    if (userId != null) {
      await loadFavoriteProducts();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadFavoriteProducts() async {
    try {
      // Lấy danh sách ID sản phẩm yêu thích
      QuerySnapshot favoritesSnapshot = await FirebaseFirestore.instance
          .collection("user")
          .doc(userId)
          .collection("favorites")
          .get();
      
      // Lấy thông tin chi tiết của từng sản phẩm
      favoriteProducts = [];
      for (var doc in favoritesSnapshot.docs) {
        String productId = doc.id;
        
        DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
            .collection("Products")
            .doc(productId)
            .get();
        
        if (productSnapshot.exists) {
          Map<String, dynamic> productData = 
              productSnapshot.data() as Map<String, dynamic>;
          
          // Thêm productId vào dữ liệu
          productData['productId'] = productId;
          
          favoriteProducts.add(productData);
        }
      }
      
      setState(() {});
    } catch (e) {
      print("Error loading favorite products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorite Products"),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userId == null
              ? Center(child: Text("Please login to view favorites"))
              : favoriteProducts.isEmpty
                  ? Center(child: Text("No favorite products yet"))
                  : ListView.builder(
                      itemCount: favoriteProducts.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> product = favoriteProducts[index];
                        String productId = product['productId'] ?? '';
                        
                        // Giải mã base64 từ Firestore nếu có
                        Widget productImage;
                        if (product["Image"] != null) {
                          try {
                            Uint8List bytes = base64Decode(product["Image"]);
                            productImage = Image.memory(
                              bytes,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            );
                          } catch (e) {
                            print("Error decoding image: $e");
                            productImage = Icon(Icons.image, size: 50);
                          }
                        } else {
                          productImage = Icon(Icons.image, size: 50);
                        }
                        
                        return Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: productImage,
                            title: Text(product["Name"] ?? "Unknown"),
                            subtitle: Text("\$${product["Price"] ?? "0.00"}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("user")
                                    .doc(userId)
                                    .collection("favorites")
                                    .doc(productId)
                                    .delete();
                                
                                // Cập nhật UI sau khi xóa
                                await loadFavoriteProducts();
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetail(
                                    detail: product["Detail"] ?? "",
                                    image: product["Image"] ?? "",
                                    name: product["Name"] ?? "",
                                    price: product["Price"] ?? "",
                                    productId: productId,
                                    votes: product["votes"] ?? 0,
                                  ),
                                ),
                              ).then((_) => loadFavoriteProducts());
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}





