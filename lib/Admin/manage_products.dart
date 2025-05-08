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
                deleteProduct(ds.id, category);
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

  void deleteProduct(String productId, String? category) async {
    try {
      await DatabaseMethods().deleteProduct(productId);
      if (category != null && category.isNotEmpty) {
        await DatabaseMethods().deleteProductFromCategory(productId, category);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Sản phẩm đã được xóa thành công"),
        backgroundColor: Colors.green,
      ));
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
      appBar: AppBar(
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
    String? base64Image = productData["Image"] as String?;
    String? category = productData["Category"] as String?;
    String? name = productData["Name"] as String?;
    String? price = productData["Price"] as String?;
    
    if (base64Image == null) {
      return Card(
        margin: EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text("Dữ liệu sản phẩm không hợp lệ"),
        ),
      );
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Hình ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(base64Image),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? "Không có tên",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "\$${price ?? '0'}",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Danh mục: ${category ?? 'Không có'}",
                    style: TextStyle(color: Colors.grey[600]),
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
}






