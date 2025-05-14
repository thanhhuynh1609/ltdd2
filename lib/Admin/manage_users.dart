import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Admin/edit_user.dart';
import 'package:shopping_app/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({Key? key}) : super(key: key);

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  Stream? usersStream;
  bool isLoading = true;

  @override
  void initState() {
    getUsers();
    super.initState();
  }

  getUsers() async {
    usersStream = await DatabaseMethods().getAllUsers();
    setState(() {
      isLoading = false;
    });
  }

  void deleteUser(String userId, String email) async {
    try {
      setState(() {
        isLoading = true;
      });
      
      // 1. Xóa dữ liệu người dùng từ Firestore
      await DatabaseMethods().deleteUser(userId);
      
      // 2. Đánh dấu tài khoản này là "đã xóa" trong Firestore
      await FirebaseFirestore.instance.collection("deleted_users").doc(userId).set({
        "email": email,
        "deletedAt": FieldValue.serverTimestamp(),
      });
      
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Người dùng đã được xóa khỏi hệ thống"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi khi xóa người dùng: $e"),
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
        title: Text("Quản lý người dùng"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => EditUser())
          ).then((_) => getUsers());
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : Container(
            padding: EdgeInsets.all(16),
            child: usersList(),
          ),
    );
  }

  Widget usersList() {
    return StreamBuilder(
      stream: usersStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.data.docs.length == 0) {
          return Center(child: Text("Không có người dùng nào"));
        }
        
        return ListView.builder(
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            Map<String, dynamic>? data = ds.data() as Map<String, dynamic>?;
            
            if (data == null) {
              return SizedBox();
            }
            
            return UserCard(
              userId: ds.id,
              userData: data,
              onDelete: () {
                deleteUser(ds.id, data["Email"] ?? "");
              },
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditUser(
                      userId: ds.id,
                      userData: data,
                    ),
                  ),
                ).then((_) => getUsers());
              },
            );
          },
        );
      },
    );
  }
}

class UserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const UserCard({
    Key? key,
    required this.userId,
    required this.userData,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? name = userData["Name"] as String?;
    String? email = userData["Email"] as String?;
    String? imageUrl = userData["Image"] as String?;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Hình ảnh người dùng
            CircleAvatar(
              radius: 30,
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : AssetImage("images/boy.jpg") as ImageProvider,
              backgroundColor: Colors.grey[200],
            ),
            SizedBox(width: 16),
            // Thông tin người dùng
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
                    email ?? "Không có email",
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
                        content: Text("Bạn có chắc chắn muốn xóa người dùng này?"),
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

