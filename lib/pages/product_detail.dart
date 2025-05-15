import 'dart:convert'; // Để sử dụng base64Decode
import 'dart:typed_data'; // Để sử dụng Uint8List

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'package:shopping_app/pages/widget/favorite_button.dart';

class ProductDetail extends StatefulWidget {
  final String detail, image, name, price, productId;
  final int? votes; // Thay đổi từ int sang int? để cho phép null

  const ProductDetail({
    Key? key,
    required this.detail,
    required this.image,
    required this.name,
    required this.price,
    required this.productId,
    this.votes, // Không bắt buộc
  }) : super(key: key);

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool isFavorite = false;
  bool isLoading = true;
  String? userId;
  String? name;
  String? mail;
  String? image;
  int productVotes = 0;

  // Lấy thông tin người dùng từ Shared Preferences
  getthesharedpref() async {
    name = await SharedPreferenceHelper().getUserName();
    mail = await SharedPreferenceHelper().getUserEmail();
    image = await SharedPreferenceHelper().getUserImage();
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ontheload();
    loadFavoriteStatus();
    // Khởi tạo productVotes từ widget.votes hoặc 0 nếu null
    productVotes = widget.votes ?? 0;
    
    // Hoặc lấy giá trị votes từ Firestore
    loadProductVotes();
  }

  Future<void> loadFavoriteStatus() async {
    userId = await SharedPreferenceHelper().getUserId();
    if (userId != null) {
      try {
        bool favorited = await DatabaseMethods().isProductFavorited(userId!, widget.productId);
        if (mounted) {
          setState(() {
            isFavorite = favorited;
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error loading favorite status: $e");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> toggleFavorite() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng đăng nhập để thêm vào yêu thích")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      bool newFavoriteState = !isFavorite;
      // Sửa lỗi ở đây - đảm bảo widget.votes không null
      int newVotes = widget.votes ?? 0; // Sử dụng toán tử ?? để cung cấp giá trị mặc định
      
      if (newFavoriteState) {
        newVotes += 1;
      } else {
        newVotes = newVotes > 0 ? newVotes - 1 : 0;
      }

      await DatabaseMethods().toggleFavoriteProduct(userId!, widget.productId, newFavoriteState);
      await DatabaseMethods().updateProductVotes(widget.productId, newVotes);

      setState(() {
        isFavorite = newFavoriteState;
        isLoading = false;
      });
    } catch (e) {
      print("Error toggling favorite: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra: $e")),
      );
    }
  }

  Future<void> loadProductVotes() async {
    try {
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection("Products")
          .doc(widget.productId)
          .get();
      
      if (productDoc.exists) {
        var data = productDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('votes')) {
          setState(() {
            productVotes = data['votes'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Error loading product votes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giải mã base64 từ chuỗi hình ảnh với xử lý lỗi
    Widget imageWidget;
    try {
      String base64Image = widget.image;
      Uint8List bytes = base64Decode(base64Image);
      imageWidget = Image.memory(
        bytes,
        height: 400,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image: $error");
          return Container(
            height: 400,
            color: Colors.grey[300],
            child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey[600]),
          );
        },
      );
    } catch (e) {
      print("Error decoding image: $e");
      imageWidget = Container(
        height: 400,
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, size: 100, color: Colors.grey[600]),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xfffef5f1),
      body: Container(
        padding: EdgeInsets.only(top: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 20),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(30)),
                    child: Icon(Icons.arrow_back_ios_outlined),
                  ),
                ),
                // Hiển thị hình ảnh từ base64 với xử lý lỗi
                Center(child: imageWidget),
              ],
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () {
                            toggleFavorite();
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "\$" + widget.price,
                          style: TextStyle(
                              color: Color(0xfffd6f3e),
                              fontSize: 23,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Details",
                      style: AppWidget.semiboldTextFeildStyle(),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(widget.detail),
                    SizedBox(
                      height: 40,
                    ),
                    GestureDetector(
                      onTap: () {
                        saveOrderToDatabase(); // Lưu đơn hàng vào cơ sở dữ liệu
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                            color: Color(0xfffd6f3e),
                            borderRadius: BorderRadius.circular(10)),
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Text(
                            "Buy Now",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Hàm lưu đơn hàng vào cơ sở dữ liệu
  Future<void> saveOrderToDatabase() async {
    try {
      // Kiểm tra xem đã có thông tin người dùng chưa
      if (name == null || mail == null || image == null) {
        await getthesharedpref(); // Lấy thông tin người dùng nếu chưa có
      }
      
      Map<String, dynamic> orderInfoMap = {
        "Product": widget.name,
        "Price": widget.price,
        "Name": name ?? "Unknown",
        "Email": mail ?? "Unknown",
        "Image": image ?? "",
        "ProductImage": widget.image,
        "Status": "On the way"
      };

      // Gọi phương thức lưu đơn hàng trong DatabaseMethods
      await DatabaseMethods().orderDetails(orderInfoMap);

      // Hiển thị thông báo thành công
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: 10),
                  Text("Order placed successfully!"),
                ],
              )
            ],
          ),
        ),
      );
    } catch (e) {
      print("Error saving order: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Text("Failed to place order. Please try again."),
        ),
      );
    }
  }
}
