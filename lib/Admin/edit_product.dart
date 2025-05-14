import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_app/services/database.dart';

class EditProduct extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProduct({
    Key? key,
    required this.productId,
    required this.productData,
  }) : super(key: key);

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? selectedImageBytes;
  String? existingImage;
  
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  String selectedCategory = "Watch";
  
  List<String> categories = ["Watch", "Laptop", "TV", "Headphones"];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadProductData();
  }

  void loadProductData() {
    nameController.text = widget.productData["Name"] ?? "";
    priceController.text = widget.productData["Price"] ?? "";
    detailController.text = widget.productData["Detail"] ?? "";
    selectedCategory = widget.productData["Category"] ?? "Watch";
    existingImage = widget.productData["Image"];
  }

  Future getImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (kIsWeb) {
        selectedImageBytes = await image.readAsBytes();
      } else {
        selectedImage = File(image.path);
      }
      setState(() {});
    }
  }

  Future updateProduct() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Vui lòng điền đầy đủ thông tin sản phẩm"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Xử lý ảnh
      String imageBase64;
      if (selectedImage != null) {
        Uint8List imageBytes = await selectedImage!.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      } else if (selectedImageBytes != null) {
        imageBase64 = base64Encode(selectedImageBytes!);
      } else {
        imageBase64 = existingImage!;
      }

      // Chuẩn bị dữ liệu cập nhật
      Map<String, dynamic> productData = {
        "Name": nameController.text,
        "Price": priceController.text,
        "Detail": detailController.text,
        "Category": selectedCategory,
        "Image": imageBase64,
        "SearchKey": nameController.text.substring(0, 1).toUpperCase(),
        "UpdateName": nameController.text.toUpperCase(),
      };

      // Cập nhật sản phẩm trong collection Products
      await DatabaseMethods().updateProduct(widget.productId, productData);

      // Nếu thay đổi danh mục
      if (widget.productData["Category"] != selectedCategory) {
        // Xóa từ danh mục cũ
        if (widget.productData["Category"] != null && widget.productData["CategoryDocId"] != null) {
          await FirebaseFirestore.instance
            .collection(widget.productData["Category"])
            .doc(widget.productData["CategoryDocId"])
            .delete();
        }
        
        // Thêm vào danh mục mới
        String newCategoryDocId = await DatabaseMethods().addProduct(productData, selectedCategory);
        
        // Cập nhật ID mới trong Products
        productData["CategoryDocId"] = newCategoryDocId;
        await DatabaseMethods().updateProduct(widget.productId, {"CategoryDocId": newCategoryDocId});
      } else {
        // Cập nhật trong cùng danh mục
        if (widget.productData["CategoryDocId"] != null) {
          await FirebaseFirestore.instance
            .collection(selectedCategory)
            .doc(widget.productData["CategoryDocId"])
            .update(productData);
        } else {
          // Nếu không có CategoryDocId, thêm mới và cập nhật ID
          String newCategoryDocId = await DatabaseMethods().addProduct(productData, selectedCategory);
          await DatabaseMethods().updateProduct(widget.productId, {"CategoryDocId": newCategoryDocId});
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Sản phẩm đã được cập nhật thành công"),
        backgroundColor: Colors.green,
      ));
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi khi cập nhật sản phẩm: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chỉnh sửa sản phẩm"),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phần chọn ảnh
                Center(
                  child: GestureDetector(
                    onTap: getImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildImageWidget(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Tên sản phẩm
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Tên sản phẩm",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                
                // Giá sản phẩm
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Giá sản phẩm",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                
                // Chi tiết sản phẩm
                TextField(
                  controller: detailController,
                  decoration: InputDecoration(
                    labelText: "Chi tiết sản phẩm",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                SizedBox(height: 16),
                
                // Danh mục sản phẩm
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: "Danh mục",
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 24),
                
                // Nút cập nhật
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      "Cập nhật sản phẩm",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildImageWidget() {
    if (selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(selectedImage!, fit: BoxFit.cover),
      );
    } else if (selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(selectedImageBytes!, fit: BoxFit.cover),
      );
    } else if (existingImage != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(base64Decode(existingImage!), fit: BoxFit.cover),
        );
      } catch (e) {
        return Icon(Icons.image_not_supported, size: 50);
      }
    } else {
      return Icon(Icons.add_photo_alternate, size: 50);
    }
  }
}



