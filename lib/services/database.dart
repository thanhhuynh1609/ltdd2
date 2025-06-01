import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shopping_app/services/notification_service.dart';

import '../models/discount_code.dart';

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
    // Đảm bảo có trường SoldCount
    if (!userInfoMap.containsKey("SoldCount")) {
      userInfoMap["SoldCount"] = 0;
    }
    return await FirebaseFirestore.instance
        .collection("Products")
        .add(userInfoMap);
  }

  // Thêm sản phẩm vào collection theo danh mục và trả về ID của document
  Future<String> addProduct(
      Map<String, dynamic> userInfoMap, String categoryname) async {
    // Đảm bảo có trường SoldCount
    if (!userInfoMap.containsKey("SoldCount")) {
      userInfoMap["SoldCount"] = 0;
    }
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
        .orderBy("CreatedAt", descending: true) // Sắp xếp theo thời gian giảm dần
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

  // Tìm kiếm sản phẩm theo tên - cải thiện
  Future<QuerySnapshot> search(String searchTerm) async {
    // Tìm kiếm theo ký tự đầu tiên
    QuerySnapshot initialResults = await FirebaseFirestore.instance
        .collection("Products")
        .where("SearchKey", isEqualTo: searchTerm.substring(0, 1).toUpperCase())
        .get();

    return initialResults;
  }

  // Thêm phương thức tìm kiếm nâng cao
  Future<QuerySnapshot> advancedSearch(String searchTerm) async {
    // Tìm tất cả sản phẩm
    return await FirebaseFirestore.instance
        .collection("Products")
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
      DocumentReference orderRef = await FirebaseFirestore.instance
          .collection("Orders")
          .add(orderMap);

      // Cập nhật SoldCount cho mỗi sản phẩm trong đơn hàng
      if (orderMap.containsKey('Products') && orderMap['Products'] is List) {
        List<dynamic> products = orderMap['Products'];

        for (var product in products) {
          if (product is Map && product.containsKey('Name')) {
            String productName = product['Name'];
            int quantity = int.tryParse(product['Quantity']?.toString() ?? '1') ?? 1;

            // Tìm sản phẩm trong collection Products
            QuerySnapshot productQuery = await FirebaseFirestore.instance
                .collection("Products")
                .where("Name", isEqualTo: productName)
                .get();

            if (productQuery.docs.isNotEmpty) {
              DocumentReference productRef = productQuery.docs.first.reference;

              // Lấy giá trị SoldCount hiện tại
              int currentSoldCount = productQuery.docs.first.get("SoldCount") ?? 0;

              // Cập nhật SoldCount
              await productRef.update({
                "SoldCount": currentSoldCount + quantity
              });
            }
          }
        }
      }

      return orderRef;
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

  // Hàm tiện ích để cập nhật trường SoldCount cho tất cả sản phẩm
  Future<void> updateAllProductsWithSoldCount() async {
    try {
      QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
          .collection("Products")
          .get();

      for (var doc in productsSnapshot.docs) {
        if (!doc.data().toString().contains('SoldCount')) {
          await doc.reference.update({"SoldCount": 0});
        }
      }

      print("Đã cập nhật SoldCount cho tất cả sản phẩm");
    } catch (e) {
      print("Lỗi khi cập nhật SoldCount: $e");
    }
  }

  // Thêm các phương thức quản lý ví vào class DatabaseMethods

  // Lấy thông tin ví của người dùng
  Future<Map<String, dynamic>?> getUserWallet(String userId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("wallets")
          .doc(userId)
          .get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        // Nếu ví chưa tồn tại, tạo ví mới với số dư 0
        Map<String, dynamic> newWallet = {
          'userId': userId,
          'balance': 0.0,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection("wallets")
            .doc(userId)
            .set(newWallet);

        return newWallet;
      }
    } catch (e) {
      print("Error fetching user wallet: $e");
      return null;
    }
  }

  // Cập nhật số dư ví
  Future<bool> updateWalletBalance(String userId, double amount, String type, String description, {String? paymentId, String? orderId}) async {
    try {
      // Bắt đầu transaction để đảm bảo tính nhất quán dữ liệu
      return await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        // Lấy thông tin ví hiện tại
        DocumentReference walletRef = FirebaseFirestore.instance.collection("wallets").doc(userId);
        DocumentSnapshot walletSnapshot = await transaction.get(walletRef);

        double currentBalance = 0.0;

        // Nếu ví đã tồn tại
        if (walletSnapshot.exists) {
          Map<String, dynamic> walletData = walletSnapshot.data() as Map<String, dynamic>;
          currentBalance = (walletData['balance'] ?? 0.0).toDouble();
        }

        // Tính số dư mới
        double newBalance = currentBalance + amount;

        // Kiểm tra số dư đủ không (nếu là giao dịch trừ tiền)
        if (amount < 0 && newBalance < 0) {
          return false;
        }

        // Cập nhật số dư ví
        transaction.set(walletRef, {
          'userId': userId,
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Tạo giao dịch mới
        DocumentReference transactionRef = FirebaseFirestore.instance.collection("wallet_transactions").doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'amount': amount,
          'type': type,
          'description': description,
          'paymentId': paymentId,
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed'
        });

        return true;
      });
    } catch (e) {
      print("Error updating wallet balance: $e");
      return false;
    }
  }

  // Lấy lịch sử giao dịch ví
  Future<Stream<QuerySnapshot>> getWalletTransactions(String userId) async {
    return FirebaseFirestore.instance
        .collection("wallet_transactions")
        .where("userId", isEqualTo: userId)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  // Tạo yêu cầu hoàn tiền
  Future<String> createRefundRequest(Map<String, dynamic> refundData) async {
    try {
      DocumentReference refundRef = await FirebaseFirestore.instance
          .collection("refund_requests")
          .add(refundData);

      // Cập nhật trạng thái đơn hàng
      await FirebaseFirestore.instance
          .collection("Orders")
          .doc(refundData['orderId'])
          .update({"RefundStatus": "pending"});

      return refundRef.id;
    } catch (e) {
      print("Lỗi khi tạo yêu cầu hoàn tiền: $e");
      throw e;
    }
  }

  // Lấy danh sách yêu cầu hoàn tiền của người dùng
  Future<List<Map<String, dynamic>>> getUserRefundRequests(String userId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("refund_requests")
          .where("userId", isEqualTo: userId)
          .orderBy("requestDate", descending: true)
          .get();

      List<Map<String, dynamic>> refundRequests = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        refundRequests.add(data);
      }

      return refundRequests;
    } catch (e) {
      print("Lỗi khi lấy danh sách yêu cầu hoàn tiền: $e");
      return [];
    }
  }

  // Lấy tất cả yêu cầu hoàn tiền (cho admin)
  Future<List<Map<String, dynamic>>> getAllRefundRequests() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("refund_requests")
          .orderBy("requestDate", descending: true)
          .get();

      List<Map<String, dynamic>> refundRequests = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        refundRequests.add(data);
      }

      return refundRequests;
    } catch (e) {
      print("Lỗi khi lấy tất cả yêu cầu hoàn tiền: $e");
      return [];
    }
  }

  // Xử lý yêu cầu hoàn tiền (chấp nhận hoặc từ chối)
  Future<bool> processRefundRequest(String refundId, String status, String orderId) async {
    try {
      // Cập nhật trạng thái yêu cầu hoàn tiền
      await FirebaseFirestore.instance
          .collection("refund_requests")
          .doc(refundId)
          .update({
        "status": status,
        "processDate": FieldValue.serverTimestamp(),
      });

      // Cập nhật trạng thái đơn hàng
      await FirebaseFirestore.instance
          .collection("Orders")
          .doc(orderId)
          .update({"RefundStatus": status});

      return true;
    } catch (e) {
      print("Lỗi khi xử lý yêu cầu hoàn tiền: $e");
      return false;
    }
  }

  // Hoàn tiền vào ví người dùng
  Future<bool> refundToWallet(String userId, double amount, String orderId) async {
    try {
      // Bắt đầu transaction để đảm bảo tính nhất quán dữ liệu
      return await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        // Lấy thông tin ví hiện tại
        DocumentReference walletRef = FirebaseFirestore.instance.collection("wallets").doc(userId);
        DocumentSnapshot walletSnapshot = await transaction.get(walletRef);

        double currentBalance = 0.0;

        // Nếu ví đã tồn tại
        if (walletSnapshot.exists) {
          Map<String, dynamic> walletData = walletSnapshot.data() as Map<String, dynamic>;
          currentBalance = (walletData['balance'] ?? 0.0).toDouble();
        }

        // Tính số dư mới
        double newBalance = currentBalance + amount;

        // Cập nhật số dư ví
        transaction.set(walletRef, {
          'userId': userId,
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Tạo giao dịch mới
        DocumentReference transactionRef = FirebaseFirestore.instance.collection("wallet_transactions").doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'amount': amount,
          'type': 'refund',  // Đảm bảo loại giao dịch là 'refund'
          'description': 'Hoàn tiền đơn hàng',  // Mô tả rõ ràng
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed'
        });

        return true;
      });
    } catch (e) {
      print("Lỗi khi hoàn tiền vào ví: $e");
      return false;
    }
  }

  // Thêm phương thức processRefund vào lớp DatabaseMethods
  Future<bool> processRefund(String userId, double amount, String orderId) async {
    try {
      return await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Lấy tham chiếu đến ví người dùng
        DocumentReference walletRef = FirebaseFirestore.instance.collection("wallets").doc(userId);

        // Lấy dữ liệu ví hiện tại
        DocumentSnapshot walletSnapshot = await transaction.get(walletRef);

        // Kiểm tra ví có tồn tại không
        double currentBalance = 0.0;
        if (walletSnapshot.exists) {
          Map<String, dynamic> walletData = walletSnapshot.data() as Map<String, dynamic>;
          currentBalance = walletData['balance'] ?? 0.0;
        }

        // Tính số dư mới
        double newBalance = currentBalance + amount;

        // Cập nhật số dư ví
        transaction.set(walletRef, {
          'userId': userId,
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Tạo giao dịch mới
        DocumentReference transactionRef = FirebaseFirestore.instance.collection("wallet_transactions").doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'amount': amount,
          'type': 'refund',  // Đảm bảo loại giao dịch là 'refund'
          'description': 'Hoàn tiền đơn hàng',  // Mô tả rõ ràng
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed'
        });

        // Tạo thông báo về giao dịch ví
        await NotificationService.createNotification(
          userId: userId,
          title: "Giao dịch ví thành công",
          message: "Số dư ví của bạn đã được cộng \$${amount.toStringAsFixed(2)} từ hoàn tiền đơn hàng.",
          type: "wallet_transaction",
          orderId: orderId,
        );

        return true;
      });
    } catch (e) {
      print("Lỗi khi hoàn tiền vào ví: $e");
      return false;
    }
  }
  Future<List<DiscountCode>> getDiscountCodes() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("discount_codes")
          .orderBy("createdAt", descending: true)
          .get();

      return snapshot.docs.map((doc) => DiscountCode.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Lỗi khi lấy danh sách mã giảm giá: $e");
      return [];
    }
  }

  // Thêm mã giảm giá (cho Admin)
  Future<void> addDiscountCode(DiscountCode discountCode) async {
    try {
      await FirebaseFirestore.instance
          .collection("discount_codes")
          .add(discountCode.toJson()..['createdAt'] = FieldValue.serverTimestamp());
    } catch (e) {
      print("Lỗi khi thêm mã giảm giá: $e");
      throw e;
    }
  }

  // Sửa mã giảm giá (cho Admin)
  Future<void> updateDiscountCode(DiscountCode discountCode) async {
    try {
      await FirebaseFirestore.instance
          .collection("discount_codes")
          .doc(discountCode.id)
          .update(discountCode.toJson());
    } catch (e) {
      print("Lỗi khi cập nhật mã giảm giá: $e");
      throw e;
    }
  }

  // Xóa mã giảm giá (cho Admin)
  Future<void> deleteDiscountCode(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection("discount_codes")
          .doc(id)
          .delete();
    } catch (e) {
      print("Lỗi khi xóa mã giảm giá: $e");
      throw e;
    }
  }

  // Kiểm tra mã giảm giá (cho người dùng)
  Future<DiscountCode?> checkDiscountCode(String code, double orderTotal) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("discount_codes")
          .where("code", isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      DiscountCode discountCode = DiscountCode.fromJson(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);

      // Kiểm tra điều kiện hợp lệ
      if (!discountCode.isActive) return null; // Mã không hoạt động

      DateTime now = DateTime.now();
      // Kiểm tra ngày bắt đầu
      if (discountCode.startDate != null && discountCode.startDate!.isAfter(now)) return null; // Mã chưa có hiệu lực
      // Kiểm tra ngày hết hạn
      if (discountCode.expiryDate != null && discountCode.expiryDate!.isBefore(now)) return null; // Mã đã hết hạn
      // Kiểm tra số tiền tối thiểu
      if (discountCode.minOrderAmount != null && orderTotal < discountCode.minOrderAmount!) return null; // Đơn hàng không đủ điều kiện

      return discountCode;
    } catch (e) {
      print("Lỗi khi kiểm tra mã giảm giá: $e");
      return null;
    }
  }

  // Cập nhật usageCount sau khi mã được sử dụng
  Future<void> incrementDiscountCodeUsage(String discountCodeId) async {
    try {
      await FirebaseFirestore.instance
          .collection("discount_codes")
          .doc(discountCodeId)
          .update({
        "usageCount": FieldValue.increment(1),
      });
    } catch (e) {
      print("Lỗi khi cập nhật usageCount: $e");
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
