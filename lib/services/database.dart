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
    // Đảm bảo trường votes được khởi tạo
    if (!userInfoMap.containsKey("votes")) {
      userInfoMap["votes"] = 0;
    }
    return await FirebaseFirestore.instance
        .collection("Products")
        .add(userInfoMap);
  }

  // Thêm sản phẩm vào collection theo danh mục
  Future addProduct(Map<String, dynamic> userInfoMap, String categoryname) async {
    // Đảm bảo trường votes được khởi tạo
    if (!userInfoMap.containsKey("votes")) {
      userInfoMap["votes"] = 0;
    }
    return await FirebaseFirestore.instance
        .collection(categoryname)
        .add(userInfoMap);
  }

  // Cập nhật trạng thái đơn hàng
  Future updateStatus(String id) async {
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

  // Lấy tất cả sản phẩm
  Future<Stream<QuerySnapshot>> getAllProducts() async {
    return FirebaseFirestore.instance.collection("Products").snapshots();
  }
  
  // Lấy snapshot của tất cả sản phẩm
  Future<QuerySnapshot> getAllProductsSnapshot() async {
    return await FirebaseFirestore.instance.collection("Products").get();
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
  
  // Thêm phương thức để cập nhật số lượt thích cho sản phẩm
  Future<void> updateProductVotes(String productId, int votes) async {
    try {
      // Cập nhật trong collection Products
      await FirebaseFirestore.instance
          .collection("Products")
          .doc(productId)
          .update({"votes": votes});
      
      // Cập nhật trong tất cả các document yêu thích của người dùng
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection("user")
          .get();
      
      for (var userDoc in userSnapshot.docs) {
        String userId = userDoc.id;
        
        // Kiểm tra xem người dùng có yêu thích sản phẩm này không
        DocumentSnapshot favoriteDoc = await FirebaseFirestore.instance
            .collection("user")
            .doc(userId)
            .collection("favorites")
            .doc(productId)
            .get();
        
        if (favoriteDoc.exists) {
          // Cập nhật votes trong document yêu thích
          await FirebaseFirestore.instance
              .collection("user")
              .doc(userId)
              .collection("favorites")
              .doc(productId)
              .update({"votes": votes});
        }
      }
    } catch (e) {
      print("Error updating product votes: $e");
      throw e;
    }
  }

  // Thêm phương thức để thêm/xóa sản phẩm yêu thích của người dùng
  Future<bool> toggleFavoriteProduct(String userId, String productId, bool isFavorite) async {
    try {
      print("Toggling favorite for user: $userId, product: $productId, isFavorite: $isFavorite");
      
      if (isFavorite) {
        // Lấy thông tin sản phẩm từ collection Products
        DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
            .collection("Products")
            .doc(productId)
            .get();
        
        if (productSnapshot.exists) {
          // Lấy dữ liệu sản phẩm
          Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
          
          // Thêm vào danh sách yêu thích với đầy đủ thông tin
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
          
          print("Added to favorites with full product data");
        } else {
          print("Product does not exist");
          return false;
        }
      } else {
        // Xóa khỏi danh sách yêu thích
        await FirebaseFirestore.instance
            .collection("user")
            .doc(userId)
            .collection("favorites")
            .doc(productId)
            .delete();
        
        print("Removed from favorites");
      }
      
      return true;
    } catch (e) {
      print("Error toggling favorite: $e");
      return false;
    }
  }

  // Kiểm tra xem sản phẩm có trong danh sách yêu thích không
  Future<bool> isProductFavorite(String userId, String productId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("user")
        .doc(userId)
        .collection("favorites")
        .doc(productId)
        .get();
    
    return doc.exists;
  }

  Future<Stream<QuerySnapshot>> getUserFavorites(String userId) async {
    return FirebaseFirestore.instance
        .collection("user")
        .doc(userId)
        .collection("favorites")
        .snapshots();
  }

  // Thêm phương thức để lấy tất cả danh mục
  Future<Stream<QuerySnapshot>> getAllCategories() async {
    return FirebaseFirestore.instance.collection("Categories").snapshots();
  }

  // Thêm phương thức để xóa danh mục
  Future<void> deleteCategory(String categoryId) async {
    return await FirebaseFirestore.instance
        .collection("Categories")
        .doc(categoryId)
        .delete();
  }

  // Thêm phương thức để cập nhật danh mục
  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    return await FirebaseFirestore.instance
        .collection("Categories")
        .doc(categoryId)
        .update(data);
  }

    // Thêm phương thức để thêm danh mục mới
  Future<DocumentReference> addCategory(Map<String, dynamic> data) async {
    return await FirebaseFirestore.instance
        .collection("Categories")
        .add(data);
  }

    // Thêm phương thức để xóa sản phẩm từ danh mục
  Future<void> removeProductFromCategoryCollection(String productId, String category) async {
    // Tìm document ID trong collection category
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(category)
        .where("ProductId", isEqualTo: productId)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        await FirebaseFirestore.instance
            .collection(category)
            .doc(doc.id)
            .delete();
      }
    }
  }

  // Thêm phương thức để lấy sản phẩm được yêu thích nhiều nhất
  Future<QuerySnapshot> getMostFavoriteProducts(int limit) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .orderBy("votes", descending: true)
        .limit(limit)
        .get();
  }

  // Thêm các phương thức cho chức năng yêu thích
  Future<void> updateFavoriteStatus(String userId, String productId, bool isFavorite) async {
    try {
      if (isFavorite) {
        // Thêm vào danh sách yêu thích
        await FirebaseFirestore.instance
            .collection("user")
            .doc(userId)
            .collection("favorites")
            .doc(productId)
            .set({
          "timestamp": FieldValue.serverTimestamp(),
        });
      } else {
        // Xóa khỏi danh sách yêu thích
        await FirebaseFirestore.instance
            .collection("user")
            .doc(userId)
            .collection("favorites")
            .doc(productId)
            .delete();
      }
    } catch (e) {
      print("Error toggling favorite: $e");
      throw e;
    }
  }

  // Cập nhật số lượt thích của sản phẩm
    Future<void> updateProductVoteCount(String productId, int votes) async {
    try {
      await FirebaseFirestore.instance
          .collection("Products")
          .doc(productId)
          .update({"votes": votes});
    } catch (e) {
      print("Error updating product votes: $e");
      throw e;
    }
  }

  // Kiểm tra xem sản phẩm có được yêu thích bởi người dùng không
  Future<bool> isProductFavorited(String userId, String productId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("user")
          .doc(userId)
          .collection("favorites")
          .doc(productId)
          .get();
      return doc.exists;
    } catch (e) {
      print("Error checking if product is favorited: $e");
      return false;
    }
  }

  // Lấy danh sách sản phẩm yêu thích của người dùng
    Future<Stream<QuerySnapshot>> getFavoriteProducts(String userId) async {
    return FirebaseFirestore.instance
        .collection("user")
        .doc(userId)
        .collection("favorites")
        .snapshots();
  }
}
