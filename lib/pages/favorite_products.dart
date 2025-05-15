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
    setState(() {
      isLoading = true;
    });
    
    try {
      print("Loading favorites for user: $userId");
      
      // Lấy danh sách sản phẩm yêu thích
      QuerySnapshot favoritesSnapshot = await FirebaseFirestore.instance
          .collection("user")
          .doc(userId)
          .collection("favorites")
          .get();
      
      print("Found ${favoritesSnapshot.docs.length} favorites");
      
      // Lấy thông tin chi tiết của từng sản phẩm
      List<Map<String, dynamic>> products = [];
      for (var doc in favoritesSnapshot.docs) {
        String productId = doc.id;
        print("Processing favorite product: $productId");
        
        // Lấy dữ liệu từ document yêu thích
        Map<String, dynamic> favoriteData = doc.data() as Map<String, dynamic>;
        
        // Kiểm tra xem dữ liệu sản phẩm đã được lưu trong document yêu thích chưa
        if (favoriteData.containsKey("Name") && 
            favoriteData.containsKey("Price") && 
            favoriteData.containsKey("Image")) {
          // Sử dụng dữ liệu từ document yêu thích
          print("Using embedded product data for: $productId");
          favoriteData['productId'] = productId;
          products.add(favoriteData);
        } else {
          // Nếu không có dữ liệu đầy đủ, lấy từ collection Products
          print("Fetching product data from Products collection for: $productId");
          DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
              .collection("Products")
              .doc(productId)
              .get();
          
          if (productSnapshot.exists) {
            print("Product exists: ${productSnapshot.id}");
            Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
            productData['productId'] = productId;
            products.add(productData);
            
            // Cập nhật lại document yêu thích với dữ liệu đầy đủ
            await FirebaseFirestore.instance
                .collection("user")
                .doc(userId)
                .collection("favorites")
                .doc(productId)
                .set({
                  "timestamp": FieldValue.serverTimestamp(),
                  "Name": productData["Name"] ?? "Unknown",
                  "Price": productData["Price"] ?? "0.00",
                  "Image": productData["Image"] ?? "",
                  "Detail": productData["Detail"] ?? "",
                  "Category": productData["Category"] ?? "",
                  "votes": productData["votes"] ?? 0,
                });
          } else {
            print("Product does not exist: $productId");
          }
        }
      }
      
      setState(() {
        favoriteProducts = products;
        isLoading = false;
      });
      
      print("Loaded ${favoriteProducts.length} favorite products");
    } catch (e) {
      print("Error loading favorite products: $e");
      setState(() {
        isLoading = false;
      });
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
                        
                        print("Rendering product: $productId");
                        print("Product data: $product");
                        
                        // Giải mã base64 từ Firestore nếu có
                        Widget productImage;
                        if (product.containsKey("Image") && product["Image"] != null && product["Image"].toString().isNotEmpty) {
                          try {
                            print("Decoding image for product: $productId");
                            Uint8List bytes = base64Decode(product["Image"]);
                            productImage = Image.memory(
                              bytes,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print("Error displaying image: $error");
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                                );
                              },
                            );
                          } catch (e) {
                            print("Error decoding image: $e");
                            productImage = Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                            );
                          }
                        } else {
                          print("No image data for product: $productId");
                          productImage = Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                          );
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
                                try {
                                  await FirebaseFirestore.instance
                                      .collection("user")
                                      .doc(userId)
                                      .collection("favorites")
                                      .doc(productId)
                                      .delete();
                                  
                                  // Cập nhật UI sau khi xóa
                                  await loadFavoriteProducts();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Đã xóa khỏi danh sách yêu thích"))
                                  );
                                } catch (e) {
                                  print("Error removing favorite: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Lỗi khi xóa: $e"))
                                  );
                                }
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
                                    votes: product["votes"] is int ? product["votes"] : 0,
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










