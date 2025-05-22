import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseMethods {
  // Thêm thông tin người dùng vào Firestore
  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection(
            "user") // Lưu ý: Tên collection là "user" (không phải "users")
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

  // Thêm sản phẩm vào collection theo danh mục và trả về ID của document
  Future<String> addProduct(
      Map<String, dynamic> userInfoMap, String categoryname) async {
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection(categoryname)
        .add(userInfoMap);
    return docRef.id;
  }

  // Cập nhật trạng thái đơn hàng
  Future<void> updateStatus(String id) async {
    // Đã sửa tên hàm thành "updateStatus" (viết thường chữ "u")
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

    // Đảm bảo trường Status tồn tại
    if (!userInfoMap.containsKey("Status")) {
      userInfoMap["Status"] =
          "Processing"; // hoặc "Đang xử lý" tùy theo ngôn ngữ ứng dụng
    }

    // Đảm bảo trường OrderDate tồn tại
    if (!userInfoMap.containsKey("OrderDate")) {
      userInfoMap["OrderDate"] = Timestamp.now();
    }

    return await FirebaseFirestore.instance
        .collection("Orders")
        .add(userInfoMap);
  }

  // Tìm kiếm sản phẩm theo tên
  Future<QuerySnapshot> search(String updatename) async {
    return await FirebaseFirestore.instance
        .collection("Products")
        .where("SearchKey", isEqualTo: updatename.substring(0, 1).toUpperCase())
        .get();
  }

  // Lấy tất cả sản phẩm
  Future<Stream<QuerySnapshot>> getAllProducts() async {
    return FirebaseFirestore.instance.collection("Products").snapshots();
  }

  // Cập nhật sản phẩm
  Future updateProduct(
      String productId, Map<String, dynamic> updateInfo) async {
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
  Future updateProductInCategory(String productId, String category,
      Map<String, dynamic> updateInfo) async {
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
      if (orderMap.containsKey('TotalAmount') &&
          orderMap['TotalAmount'] is num) {
        orderMap['TotalAmount'] = orderMap['TotalAmount'].toString();
      }

      // Đảm bảo OrderId là chuỗi
      if (orderMap.containsKey('OrderId') && orderMap['OrderId'] is num) {
        orderMap['OrderId'] = orderMap['OrderId'].toString();
      }

      // Xử lý danh sách sản phẩm
      if (orderMap.containsKey('Products') && orderMap['Products'] is List) {
        List products = orderMap['Products'];

        // Tạo danh sách sản phẩm mới với hình ảnh
        List<Map<String, dynamic>> processedProducts = [];

        for (int i = 0; i < products.length; i++) {
          Map<String, dynamic> product = Map<String, dynamic>.from(products[i]);

          // Chuyển đổi các trường số thành chuỗi
          if (product['Price'] is num) {
            product['Price'] = product['Price'].toString();
          }
          if (product['Quantity'] is num) {
            product['Quantity'] = product['Quantity'].toString();
          }

          // Đảm bảo hình ảnh được lưu trữ trong trường ProductImage
          if (!product.containsKey('ProductImage') &&
              product.containsKey('Image') &&
              product['Image'] != null) {
            product['ProductImage'] = product['Image'];
          }

          processedProducts.add(product);
        }

        // Cập nhật danh sách sản phẩm trong orderMap
        orderMap['Products'] = processedProducts;
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

  // Thêm sản phẩm vào giỏ hàng
  Future addToCart(Map<String, dynamic> productData) async {
    try {
      // Đảm bảo trường OrderDate tồn tại nếu chưa có
      if (!productData.containsKey("OrderDate")) {
        productData["OrderDate"] = Timestamp.now();
      }

      // Thêm vào collection "Cart"
      return await FirebaseFirestore.instance
          .collection("Cart")
          .add(productData);
    } catch (e) {
      print("Lỗi khi thêm vào giỏ hàng: $e");
      throw e;
    }
  }

  // Lấy giỏ hàng của người dùng
  Future<Stream<QuerySnapshot>> getCart(String userEmail) async {
    return FirebaseFirestore.instance
        .collection("Cart")
        .where("Email", isEqualTo: userEmail)
        .snapshots();
  }

  // Xóa sản phẩm khỏi giỏ hàng
  Future deleteCartItem(String cartItemId) async {
    return await FirebaseFirestore.instance
        .collection("Cart")
        .doc(cartItemId)
        .delete();
  }

  // Xóa toàn bộ giỏ hàng của người dùng
  Future clearCart(String userEmail) async {
    QuerySnapshot cartItems = await FirebaseFirestore.instance
        .collection("Cart")
        .where("Email", isEqualTo: userEmail)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in cartItems.docs) {
      batch.delete(doc.reference);
    }

    return await batch.commit();
  }

  // Kiểm tra người dùng đã mua sản phẩm chưa
  Future<bool> hasUserPurchasedProduct(
      String userEmail, String productId) async {
    try {
      print("Kiểm tra mua hàng - Email: $userEmail, ProductId: $productId");

      // Chỉ kiểm tra trong collection "Orders" (viết hoa)
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection("Orders")
          .where("Email", isEqualTo: userEmail)
          .get();

      // Kiểm tra thêm với trường CustomerEmail
      QuerySnapshot customerOrdersSnapshot = await FirebaseFirestore.instance
          .collection("Orders")
          .where("CustomerEmail", isEqualTo: userEmail)
          .get();

      // Kết hợp kết quả
      List<QueryDocumentSnapshot> allDocs = [
        ...ordersSnapshot.docs,
        ...customerOrdersSnapshot.docs
      ];

      print("Tìm thấy ${allDocs.length} đơn hàng");

      for (var doc in allDocs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print("Kiểm tra đơn hàng ID: ${doc.id}");

        // Kiểm tra trường Product trực tiếp trong đơn hàng
        if (data.containsKey("Product") && data["Product"] == productId) {
          print("Tìm thấy sản phẩm trong trường Product");
          return true;
        }

        // Kiểm tra trong danh sách sản phẩm của đơn hàng
        if (data.containsKey("Products") && data["Products"] is List) {
          List<dynamic> products = data["Products"] as List<dynamic>;
          print("Đơn hàng có ${products.length} sản phẩm");

          for (var product in products) {
            if (product is Map<String, dynamic>) {
              // In ra tên sản phẩm để debug
              print(
                  "Kiểm tra sản phẩm: ${product["Name"] ?? product["Product"] ?? "Không có tên"}");

              // Kiểm tra các trường có thể chứa ID sản phẩm
              if ((product.containsKey("ProductId") &&
                      product["ProductId"] == productId) ||
                  (product.containsKey("Product") &&
                      product["Product"] == productId) ||
                  (product.containsKey("Name") &&
                      product["Name"] == productId)) {
                print("Tìm thấy sản phẩm trong danh sách Products");
                return true;
              }
            }
          }
        }
      }

      print("Không tìm thấy sản phẩm trong lịch sử mua hàng");
      return false;
    } catch (e) {
      print("Lỗi khi kiểm tra lịch sử mua hàng: $e");
      return false;
    }
  }

  // Thêm đánh giá sản phẩm
  Future<void> addProductReview(Map<String, dynamic> reviewData) async {
    try {
      // Đảm bảo có timestamp
      if (!reviewData.containsKey("Timestamp")) {
        reviewData["Timestamp"] = FieldValue.serverTimestamp();
      }

      // Kiểm tra xem người dùng đã đánh giá sản phẩm này chưa
      String userEmail = reviewData["UserEmail"] ?? "";
      String productId = reviewData["ProductId"] ?? "";

      if (userEmail.isNotEmpty && productId.isNotEmpty) {
        // Tìm đánh giá cũ của người dùng cho sản phẩm này
        QuerySnapshot existingReviews = await FirebaseFirestore.instance
            .collection("Reviews")
            .where("UserEmail", isEqualTo: userEmail)
            .where("ProductId", isEqualTo: productId)
            .get();

        if (existingReviews.docs.isNotEmpty) {
          // Nếu đã có đánh giá, cập nhật đánh giá cũ
          String reviewId = existingReviews.docs.first.id;
          await FirebaseFirestore.instance
              .collection("Reviews")
              .doc(reviewId)
              .update(reviewData);

          print("Đã cập nhật đánh giá hiện có với ID: $reviewId");
          return;
        }
      }

      // Nếu chưa có đánh giá, thêm mới
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection("Reviews")
          .add(reviewData);

      print("Đã thêm đánh giá mới với ID: ${docRef.id}");
    } catch (e) {
      print("Lỗi khi thêm đánh giá: $e");
      throw e;
    }
  }

  // Thêm sản phẩm vào danh sách yêu thích
  Future<void> addToFavorites(Map<String, dynamic> favoriteData) async {
    try {
      // Kiểm tra xem sản phẩm đã có trong danh sách yêu thích chưa
      String userEmail = favoriteData["UserEmail"] ?? "";
      String productId = favoriteData["ProductId"] ?? "";
      
      if (userEmail.isNotEmpty && productId.isNotEmpty) {
        QuerySnapshot existingFavorites = await FirebaseFirestore.instance
            .collection("Favorites")
            .where("UserEmail", isEqualTo: userEmail)
            .where("ProductId", isEqualTo: productId)
            .get();
        
        if (existingFavorites.docs.isNotEmpty) {
          // Nếu đã có trong danh sách yêu thích, xóa khỏi danh sách
          await FirebaseFirestore.instance
              .collection("Favorites")
              .doc(existingFavorites.docs.first.id)
              .delete();
          return;
        }
      }
      
      // Thêm timestamp
      favoriteData["Timestamp"] = FieldValue.serverTimestamp();
      
      // Thêm vào collection "Favorites"
      await FirebaseFirestore.instance
          .collection("Favorites")
          .add(favoriteData);
    } catch (e) {
      print("Lỗi khi thêm vào danh sách yêu thích: $e");
      throw e;
    }
  }

  // Kiểm tra sản phẩm có trong danh sách yêu thích không
  Future<bool> isProductFavorite(String userEmail, String productId) async {
    try {
      QuerySnapshot favorites = await FirebaseFirestore.instance
          .collection("Favorites")
          .where("UserEmail", isEqualTo: userEmail)
          .where("ProductId", isEqualTo: productId)
          .get();
      
      return favorites.docs.isNotEmpty;
    } catch (e) {
      print("Lỗi khi kiểm tra sản phẩm yêu thích: $e");
      return false;
    }
  }

  // Lấy danh sách sản phẩm yêu thích của người dùng
  Future<Stream<QuerySnapshot>> getFavorites(String userEmail) async {
    return FirebaseFirestore.instance
        .collection("Favorites")
        .where("UserEmail", isEqualTo: userEmail)
        .snapshots();
  }
}
