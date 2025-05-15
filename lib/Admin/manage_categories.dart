import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/services/database.dart';

class ManageCategories extends StatefulWidget {
  const ManageCategories({Key? key}) : super(key: key);

  @override
  State<ManageCategories> createState() => _ManageCategoriesState();
}

class _ManageCategoriesState extends State<ManageCategories> {
  Stream? categoriesStream;
  bool isLoading = true;
  TextEditingController categoryController = TextEditingController(); // Đặt tên biến thành categoryController
  String? editingCategoryId;

  @override
  void initState() {
    getCategories();
    super.initState();
  }

  getCategories() async {
    categoriesStream = await DatabaseMethods().getAllCategories();
    setState(() {
      isLoading = false;
    });
  }

  void deleteCategory(String categoryId, String categoryName) async {
    try {
      setState(() {
        isLoading = true;
      });
      
      await DatabaseMethods().deleteCategory(categoryId);
      
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Danh mục đã được xóa thành công"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi khi xóa danh mục: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  void addOrUpdateCategory() async {
    if (categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Vui lòng nhập tên danh mục"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (editingCategoryId != null) {
        // Cập nhật danh mục
        await DatabaseMethods().updateCategory(
          editingCategoryId!,
          {"name": categoryController.text.trim()}
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Danh mục đã được cập nhật"),
          backgroundColor: Colors.green,
        ));
      } else {
        // Thêm danh mục mới
        await DatabaseMethods().addCategory(
          {"name": categoryController.text.trim()}
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Danh mục đã được thêm"),
          backgroundColor: Colors.green,
        ));
      }
      
      // Reset form
      categoryController.clear();
      editingCategoryId = null;
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi: $e"),
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
        title: Text("Quản lý danh mục"),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Form thêm/sửa danh mục
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: categoryController,
                        decoration: InputDecoration(
                          labelText: editingCategoryId != null 
                              ? "Sửa danh mục" 
                              : "Thêm danh mục mới",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: addOrUpdateCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        editingCategoryId != null ? "Cập nhật" : "Thêm",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    if (editingCategoryId != null) ...[
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            editingCategoryId = null;
                            categoryController.clear();
                          });
                        },
                      ),
                    ]
                  ],
                ),
              ),
              
              // Danh sách danh mục
              Expanded(
                child: categoriesList(),
              ),
            ],
          ),
    );
  }

  Widget categoriesList() {
    return StreamBuilder(
      stream: categoriesStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.data.docs.length == 0) {
          return Center(child: Text("Không có danh mục nào"));
        }
        
        return ListView.builder(
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            Map<String, dynamic>? data = ds.data() as Map<String, dynamic>?;
            
            if (data == null) {
              return SizedBox();
            }
            
            return ListTile(
              title: Text(
                data["name"] ?? "",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        editingCategoryId = ds.id;
                        categoryController.text = data["name"] ?? "";
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Xác nhận xóa"),
                          content: Text("Bạn có chắc chắn muốn xóa danh mục này?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Hủy"),
                            ),
                            TextButton(
                              onPressed: () {
                                deleteCategory(ds.id, data["name"] ?? "");
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
            );
          },
        );
      },
    );
  }
}