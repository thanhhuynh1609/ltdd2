import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? selectedImageBytes; // Dùng cho Flutter Web
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  bool isLoading = false;
  
  // Danh sách danh mục từ Firestore
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;
  
  // Khai báo biến selectedCategoryId rõ ràng
  String? selectedCategoryId;
  
  @override
  void initState() {
    super.initState();
    loadCategories();
  }
  
  // Tải danh sách danh mục từ Firestore
  Future<void> loadCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    
    try {
      final categoriesStream = await DatabaseMethods().getAllCategories();
      categoriesStream.listen((snapshot) {
        List<Map<String, dynamic>> loadedCategories = [];
        
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            // Đảm bảo document có trường 'name'
            if (data.containsKey('name')) {
              data['id'] = doc.id; // Lưu ID của document
              loadedCategories.add(data);
            }
          } catch (e) {
            print("Error processing category document: $e");
          }
        }
        
        setState(() {
          categories = loadedCategories;
          isLoadingCategories = false;
        });
      });
    } catch (e) {
      print("Error loading categories: $e");
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  // Chọn ảnh từ thư viện
  Future<void> getImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // Dành cho Web
          selectedImageBytes = await image.readAsBytes();
        } else {
          // Dành cho Mobile
          selectedImage = File(image.path);
        }
        setState(() {});
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // Upload sản phẩm
  Future<void> uploadItem() async {
    if ((selectedImage != null || selectedImageBytes != null) &&
        nameController.text.isNotEmpty &&
        selectedCategoryId != null) {  // Sử dụng selectedCategoryId thay vì value
      
      // Hiển thị loading
      setState(() {
        isLoading = true;
      });

      try {
        // Chuyển đổi ảnh thành Base64
        String? base64Image;
        if (kIsWeb && selectedImageBytes != null) {
          base64Image = base64Encode(selectedImageBytes!);
        } else if (selectedImage != null) {
          base64Image = base64Encode(await selectedImage!.readAsBytes());
        }

        if (base64Image == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Error converting image to Base64.",
              style: TextStyle(fontSize: 18),
            ),
          ));
          return;
        }
        
        String firstletter = nameController.text.isNotEmpty 
            ? nameController.text.substring(0, 1).toUpperCase() 
            : "A";
        
        // Tìm tên danh mục từ ID
        String categoryName = "";
        for (var category in categories) {
          if (category['id'] == selectedCategoryId) {
            categoryName = category['name'] as String;
            break;
          }
        }
        
        // Thêm sản phẩm vào cơ sở dữ liệu
        Map<String, dynamic> addProduct = {
          "Name": nameController.text,
          "Image": base64Image,
          "SearchKey": firstletter,
          "UpdateName": nameController.text.toUpperCase(),
          "Price": priceController.text,
          "Detail": detailController.text,
          "Category": categoryName,
          "CategoryId": selectedCategoryId,
        };

        // Thêm vào collection danh mục
        await DatabaseMethods().addProduct(addProduct, categoryName);
        
        // Thêm vào collection Products
        await DatabaseMethods().addAllProducts(addProduct);
        
        // Reset form
        setState(() {
          selectedImage = null;
          selectedImageBytes = null;
          nameController.clear();
          priceController.clear();
          detailController.clear();
          // Không reset selectedCategoryId để người dùng có thể tiếp tục thêm sản phẩm cùng danh mục
        });
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Product has been uploaded successfully!",
            style: TextStyle(fontSize: 20),
          ),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Error uploading product: $e",
            style: TextStyle(fontSize: 18),
          ),
        ));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Please fill all fields, select an image, and choose a category.",
          style: TextStyle(fontSize: 18),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios_new_outlined),
        ),
        title: Text(
          "Add Product",
          style: AppWidget.semiboldTextFeildStyle(),
        ),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Upload the Product Image",
                style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            GestureDetector(
              onTap: getImage,
              child: Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: selectedImage == null && selectedImageBytes == null
                      ? Icon(Icons.camera_alt_outlined)
                      : kIsWeb
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(selectedImageBytes!,
                                  fit: BoxFit.cover),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child:
                                  Image.file(selectedImage!, fit: BoxFit.cover),
                            ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text("Product Name", style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xffececf8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            SizedBox(height: 20),
            Text("Product Price", style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xffececf8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            SizedBox(height: 20),
            Text("Product Detail", style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xffececf8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                maxLines: 6,
                controller: detailController,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            
            SizedBox(height: 20),
            Text("Product Category", style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            isLoadingCategories
              ? Center(child: CircularProgressIndicator())
              : categories.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Text("No categories found. Please add categories first."),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: loadCategories,
                          child: Text("Refresh Categories"),
                        ),
                      ],
                    ),
                  )
                : Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Color(0xffececf8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      items: categories.map((category) {
                        // Đảm bảo category['id'] và category['name'] không null
                        String id = category['id'] as String;
                        String name = category['name'] as String;
                        
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            name,
                            style: AppWidget.semiboldTextFeildStyle(),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedCategoryId = newValue;
                        });
                      },
                      dropdownColor: Colors.white,
                      hint: Text("Select Category"),
                      iconSize: 36,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                      value: selectedCategoryId,
                      isExpanded: true,
                    ),
                  ),
                ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: uploadItem,
                child: Text("Add Product", style: TextStyle(fontSize: 22)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}