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

  // Lấy đơn hàng của người dùng
  Future<Stream<QuerySnapshot>> getOrders(String userId) async {
    return FirebaseFirestore.instance
        .collection("Orders")
        .where("UserId", isEqualTo: userId)
        .snapshots();
  }

  // Thêm chi tiết đơn hàng
  Future orderDetails(Map<String, dynamic> userInfoMap) async {
    // Đảm bảo OrderId luôn tồn tại trong userInfoMap
    if (!userInfoMap.containsKey("OrderId")) {
      userInfoMap["OrderId"] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    
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

  // Lấy tất cả sản phẩm
  Future<Stream<QuerySnapshot>> getAllProducts() async {
    return FirebaseFirestore.instance.collection("Products").snapshots();
  }

  // Cập nhật sản phẩm
  Future updateProduct(String productId, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .doc(productId)
        .update(updateInfo);
  }

  // Xóa sản phẩm
  Future deleteProduct(String productId) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .doc(productId)
        .delete();
  }

  // Xóa sản phẩm trong collection danh mục
  Future deleteProductFromCategory(String productId, String category) async {
    return await FirebaseFirestore.instance
        .collection(category)
        .doc(productId)
        .delete();
  }

  // Cập nhật sản phẩm trong collection danh mục
  Future updateProductInCategory(String productId, String category, Map<String, dynamic> updateInfo) async {
    try {
      // Kiểm tra xem document có tồn tại không
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection(category)
          .doc(productId)
          .get();
      
      if (docSnapshot.exists) {
        // Nếu tồn tại thì cập nhật
        return await FirebaseFirestore.instance
            .collection(category)
            .doc(productId)
            .update(updateInfo);
      } else {
        // Nếu không tồn tại thì thêm mới
        return await FirebaseFirestore.instance
            .collection(category)
            .doc(productId)
            .set(updateInfo);
      }
    } catch (e) {
      print("Lỗi khi cập nhật sản phẩm trong danh mục: $e");
      return null;
    }
  }

  // Lấy tất cả người dùng
  Future<Stream<QuerySnapshot>> getAllUsers() async {
    return FirebaseFirestore.instance.collection("user").snapshots();
  }

  // Xóa người dùng
  Future deleteUser(String userId) async {
    return await FirebaseFirestore.instance
        .collection("user")
        .doc(userId)
        .delete();
  }

  // Tạo đơn hàng mới với cấu trúc gộp sản phẩm
  Future createOrder(Map<String, dynamic> orderMap) async {
    try {
      // Đảm bảo các trường số được lưu dưới dạng chuỗi
      if (orderMap.containsKey('TotalAmount') && orderMap['TotalAmount'] is num) {
        orderMap['TotalAmount'] = orderMap['TotalAmount'].toString();
      }
      
      // Đảm bảo OrderId là chuỗi
      if (orderMap.containsKey('OrderId') && orderMap['OrderId'] is num) {
        orderMap['OrderId'] = orderMap['OrderId'].toString();
      }
      
      // Xử lý danh sách sản phẩm
      if (orderMap.containsKey('Products') && orderMap['Products'] is List) {
        List products = orderMap['Products'];
        
        // Tạo danh sách sản phẩm mới không chứa hình ảnh base64
        List<Map<String, dynamic>> optimizedProducts = [];
        
        for (int i = 0; i < products.length; i++) {
          Map<String, dynamic> product = Map<String, dynamic>.from(products[i]);
          
          // Chuyển đổi các trường số thành chuỗi
          if (product['Price'] is num) {
            product['Price'] = product['Price'].toString();
          }
          if (product['Quantity'] is num) {
            product['Quantity'] = product['Quantity'].toString();
          }
          
          // Loại bỏ hình ảnh base64 từ sản phẩm
          if (product.containsKey('ProductImage')) { // Đổi từ "Image" thành "ProductImage"
            // Lưu tham chiếu đến hình ảnh thay vì base64
            String productName = product['Name'] ?? '';
            String brand = product['Brand'] ?? '';
            product['ImageRef'] = "products/${brand}_${productName.replaceAll(' ', '_')}";
            product.remove('ProductImage');
          }
          
          optimizedProducts.add(product);
        }
        
        // Cập nhật danh sách sản phẩm trong orderMap
        orderMap['Products'] = optimizedProducts;
      }
      
      // Thêm timestamp
      orderMap['CreatedAt'] = FieldValue.serverTimestamp();
      
      // Lưu đơn hàng vào Firestore
      return await FirebaseFirestore.instance
          .collection("Orders")
          .add(orderMap);
    } catch (e) {
      print("Lỗi khi tạo đơn hàng: $e");
      throw e;
    }
  }
}
