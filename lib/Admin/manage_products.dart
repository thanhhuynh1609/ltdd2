import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Admin/edit_product.dart';
import 'package:shopping_app/services/database.dart';

class ManageProducts extends StatefulWidget {
  const ManageProducts({Key? key}) : super(key: key);

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  Stream? productsStream;

  @override
  void initState() {
    getProducts();
    super.initState();
  }

  getProducts() async {
    productsStream = await DatabaseMethods().getAllProducts();
    setState(() {});
  }

  Widget productsList() {
    return StreamBuilder(
      stream: productsStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        return ListView.builder(
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            Map<String, dynamic>? data = ds.data() as Map<String, dynamic>?;
            String? category = data != null ? data["Category"] : null;
            
            return ProductCard(
              productId: ds.id,
              productData: data ?? {},
              onDelete: () {
                deleteProduct(ds.id, data ?? {});
              },
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProduct(
                      productId: ds.id,
                      productData: data ?? {},
                    ),
                  ),
                ).then((_) => getProducts());
              },
            );
          },
        );
      },
    );
  }

  void deleteProduct(String productId, Map<String, dynamic> productData) async {
    try {
      // Lấy thông tin danh mục và ID của document trong collection danh mục
      String? category = productData["Category"];
      String? categoryDocId = productData["CategoryDocId"];
      
      // Xóa sản phẩm từ collection Products
      await DatabaseMethods().deleteProduct(productId);
      
      // Xóa sản phẩm từ collection danh mục nếu có thông tin
      if (category != null && categoryDocId != null) {
        await FirebaseFirestore.instance
            .collection(category)
            .doc(categoryDocId)
            .delete();
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Sản phẩm đã được xóa thành công"),
          backgroundColor: Colors.green,
        ));
      } else {
        // Nếu không có CategoryDocId, thử tìm sản phẩm trong collection danh mục dựa trên tên
        if (category != null && productData["Name"] != null) {
          String productName = productData["Name"];
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection(category)
              .where("Name", isEqualTo: productName)
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection(category)
                .doc(querySnapshot.docs[0].id)
                .delete();
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Sản phẩm đã được xóa thành công"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi khi xóa sản phẩm: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Quản lý sản phẩm"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: productsList(),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> productData;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ProductCard({
    Key? key,
    required this.productId,
    required this.productData,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Hình ảnh sản phẩm
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: _buildProductImage(),
            ),
            SizedBox(width: 16),
            
            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productData["Name"] ?? "Không có tên",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Giá: ${productData["Price"] ?? "N/A"}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Danh mục: ${productData["Category"] ?? "N/A"}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            // Các nút hành động
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Xác nhận xóa"),
                        content: Text("Bạn có chắc chắn muốn xóa sản phẩm này?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Hủy"),
                          ),
                          TextButton(
                            onPressed: () {
                              onDelete();
                              Navigator.pop(context);
                            },
                            child: Text("Xóa", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    try {
      if (productData["Image"] != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(productData["Image"]),
            fit: BoxFit.cover,
          ),
        );
      }
    } catch (e) {
      print("Lỗi khi hiển thị ảnh: $e");
    }
    return Icon(Icons.image_not_supported);
  }
}




