import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseMethods {
  // Thêm thông tin người dùng vào Firestore
  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("user") // Lưu ý: Tên collection là "user" (không phải "users")
        .doc(id)
        .set(userInfoMap);
  }

  // Lấy thông tin người dùng từ Firestore dựa trên ID
  Future<Map<String, dynamic>?> getUserDetails(String id) async {
    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection("user").doc(id).get();
      return snapshot.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  // Thêm tất cả sản phẩm vào collection "Products"
  Future addAllProducts(Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .add(userInfoMap);
  }

  // Thêm sản phẩm vào collection theo danh mục
  Future addProduct(Map<String, dynamic> userInfoMap, String categoryname) async {
    return await FirebaseFirestore.instance
        .collection(categoryname)
        .add(userInfoMap);
  }

  // Cập nhật trạng thái đơn hàng
  UpdateStatus(String id) async { // Sửa tên hàm thành "updateStatus" (viết thường chữ "u")
    return await FirebaseFirestore.instance
        .collection("Orders")
        .doc(id)
        .update({"Status": "Delivered"});
  }

  // Lấy danh sách sản phẩm theo danh mục
  Future<Stream<QuerySnapshot>> getProducts(String category) async {
    return FirebaseFirestore.instance.collection(category).snapshots();
  }

  // Lấy tất cả đơn hàng đang "On the way"
  Future<Stream<QuerySnapshot>> allOrders() async {
    return FirebaseFirestore.instance
        .collection("Orders")
        .where("Status", isEqualTo: "On the way")
        .snapshots();
  }

  // Lấy đơn hàng theo email người dùng
  Future<Stream<QuerySnapshot>> getOrders(String email) async {
    return FirebaseFirestore.instance
        .collection("Orders")
        .where("Email", isEqualTo: email)
        .snapshots();
  }

  // Thêm chi tiết đơn hàng
  Future orderDetails(Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("Orders")
        .add(userInfoMap);
  }

  // Tìm kiếm sản phẩm theo tên
  Future<QuerySnapshot> search(String updatename) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .where("SearchKey",
            isEqualTo: updatename.substring(0, 1).toUpperCase())
        .get();
  }
}