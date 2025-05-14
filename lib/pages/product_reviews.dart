import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'package:intl/intl.dart';

class ProductReviews extends StatefulWidget {
  final String productId;
  final String productName;
  final String productImage;

  const ProductReviews({
    Key? key,
    required this.productId,
    required this.productName,
    this.productImage = "",
  }) : super(key: key);

  @override
  _ProductReviewsState createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  bool _isLoading = true;
  bool _canReview = false;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kiểm tra người dùng có thể đánh giá không
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail != null) {
        _canReview = await _databaseMethods.hasUserPurchasedProduct(
            userEmail, widget.productId);
      }

      // Lấy danh sách đánh giá - Sửa lại truy vấn để tránh cần composite index
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection("Reviews")
          .where("ProductId", isEqualTo: widget.productId)
          .get();

      // Lấy dữ liệu từ snapshot
      _reviews = reviewsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "userName": data["UserName"] ?? "Người dùng",
          "userImage": data["UserImage"] ?? "",
          "rating": data["Rating"] ?? 5,
          "review": data["Review"] ?? "",
          "timestamp": data["Timestamp"] != null
              ? (data["Timestamp"] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList();

      // Sắp xếp theo thời gian mới nhất (thay vì dùng orderBy trong truy vấn)
      _reviews.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

      // Tính điểm trung bình
      if (_reviews.isNotEmpty) {
        double total =
            _reviews.fold(0, (sum, item) => sum + (item["rating"] as int));
        _averageRating = total / _reviews.length;
      }
    } catch (e) {
      print("Lỗi khi tải đánh giá: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddReviewDialog() {
    int rating = 5;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Đánh giá sản phẩm"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Chọn số sao:"),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Nhập đánh giá của bạn",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (reviewController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Vui lòng nhập nội dung đánh giá")));
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      String? userEmail =
                          FirebaseAuth.instance.currentUser!.email;
                      String? userName =
                          await SharedPreferenceHelper().getUserName();
                      String? userImage =
                          await SharedPreferenceHelper().getUserProfile();

                      Map<String, dynamic> reviewData = {
                        "ProductId": widget.productId,
                        "UserEmail": userEmail,
                        "UserName": userName ?? "Người dùng",
                        "UserImage": userImage ?? "",
                        "Rating": rating,
                        "Review": reviewController.text.trim(),
                        "Timestamp": FieldValue.serverTimestamp(),
                      };

                      await _databaseMethods.addProductReview(reviewData);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text("Đánh giá của bạn đã được gửi thành công"),
                        backgroundColor: Colors.green,
                      ));

                      _loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Lỗi: $e"),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  child: Text("Gửi đánh giá"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Đánh giá sản phẩm",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Thông tin sản phẩm và đánh giá trung bình
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(
                        widget.productName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${_averageRating.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < _averageRating.floor()
                                        ? Icons.star
                                        : (index < _averageRating.ceil() &&
                                                index >= _averageRating.floor())
                                            ? Icons.star_half
                                            : Icons.star_border,
                                    color: Colors.amber,
                                    size: 24,
                                  );
                                }),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${_reviews.length} đánh giá",
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Danh sách đánh giá
                Expanded(
                  child: _reviews.isEmpty
                      ? Center(
                          child: Text(
                            "Chưa có đánh giá nào cho sản phẩm này",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            return _buildReviewItem(_reviews[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _canReview
          ? FloatingActionButton(
              onPressed: _showAddReviewDialog,
              child: Icon(Icons.rate_review),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: review["userImage"].isNotEmpty
                    ? NetworkImage(review["userImage"])
                    : null,
                child: review["userImage"].isEmpty ? Icon(Icons.person) : null,
                radius: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review["userName"],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat("dd/MM/yyyy").format(review["timestamp"]),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review["rating"] ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(review["review"]),
        ],
      ),
    );
  }
}
