import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopping_app/services/database.dart';

class EditUser extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? userData;

  const EditUser({
    Key? key,
    this.userId,
    this.userData,
  }) : super(key: key);

  @override
  State<EditUser> createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? existingImageUrl;
  bool isLoading = false;
  bool isNewUser = true;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null && widget.userId != null) {
      isNewUser = false;
      nameController.text = widget.userData!["Name"] ?? "";
      emailController.text = widget.userData!["Email"] ?? "";
      existingImageUrl = widget.userData!["Image"];
    }
  }

  Future getImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<String?> uploadImageToStorage(String userId) async {
    try {
      if (selectedImage == null) return existingImageUrl;
      
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("user_images")
          .child("$userId.jpg");
      
      await storageRef.putFile(selectedImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> saveUser() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Vui lòng nhập tên và email"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (isNewUser && passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Vui lòng nhập mật khẩu cho người dùng mới"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String userId = widget.userId ?? "";
      
      // Nếu là người dùng mới, tạo tài khoản Firebase Auth
      if (isNewUser) {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );
        userId = userCredential.user!.uid;
      }
      
      // Upload ảnh lên Firebase Storage
      String? imageUrl = await uploadImageToStorage(userId);
      
      // Chuẩn bị dữ liệu người dùng
      Map<String, dynamic> userData = {
        "Name": nameController.text.trim(),
        "Email": emailController.text.trim(),
        "Id": userId,
        "Image": imageUrl ?? "https://firebasestorage.googleapis.com/v0/b/barberapp-ebcc1.appspot.com/o/icon1.png?alt=media&token=0fad24a5-a01b-4d67-b4a0-676fbc75b34a",
      };
      
      // Lưu dữ liệu người dùng vào Firestore
      await DatabaseMethods().addUserDetails(userData, userId);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isNewUser ? "Đã tạo người dùng mới" : "Đã cập nhật thông tin người dùng"),
        backgroundColor: Colors.green,
      ));
      
      Navigator.pop(context);
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
        title: Text(isNewUser ? "Thêm người dùng mới" : "Chỉnh sửa người dùng"),
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
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          image: _buildProfileImage(),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: selectedImage == null && existingImageUrl == null
                            ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Tên người dùng
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Tên người dùng",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Email
                  TextField(
                    controller: emailController,
                    enabled: isNewUser, // Chỉ cho phép sửa email nếu là người dùng mới
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Mật khẩu (chỉ hiển thị khi tạo người dùng mới)
                  if (isNewUser)
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  SizedBox(height: 24),
                  
                  // Nút lưu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isNewUser ? "Tạo người dùng" : "Cập nhật",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  DecorationImage? _buildProfileImage() {
    if (selectedImage != null) {
      return DecorationImage(
        image: FileImage(selectedImage!),
        fit: BoxFit.cover,
      );
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(existingImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}