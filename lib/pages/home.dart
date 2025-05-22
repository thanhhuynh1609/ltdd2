import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/category_products.dart';
import 'package:shopping_app/pages/cart_page.dart';
import 'package:shopping_app/pages/notifications_page.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/notification_service.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shopping_app/services/cart_service.dart';
import 'package:shopping_app/pages/product_detail.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool search = false;
  String userId = ""; // Thêm biến userId

  List categories = [
    "images/headphoneicon.png",
    "images/laptopicon.png",
    "images/watchicon.png",
    "images/tvicon.png",
  ];

  List Categoryname = [
    "Headphones",
    "Laptop",
    "Watch",
    "TV",
  ];

  var queryResultSet = [];
  var tempSearchStore = [];

  Stream? bestSellingStream;

  getBestSellingProducts() async {
    bestSellingStream = FirebaseFirestore.instance
        .collection("Products")
        .orderBy("SoldCount", descending: true)
        .limit(6)
        .snapshots();
    setState(() {});
  }

  initiateSearch(value) async {
    if (value.length == 0) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        search = false;
      });
      return;
    }
    
    setState(() {
      search = true;
    });

    // Chuyển đổi giá trị tìm kiếm thành chữ hoa để so sánh không phân biệt hoa thường
    String searchValue = value.toUpperCase();
    
    if (value.length == 1) {
      // Tìm kiếm ban đầu khi người dùng nhập ký tự đầu tiên
      queryResultSet = [];
      QuerySnapshot snapshot = await DatabaseMethods().search(value);
      
      setState(() {
        for (var doc in snapshot.docs) {
          queryResultSet.add(doc.data());
        }
        
        // Lọc kết quả ngay lập tức
        tempSearchStore = queryResultSet.where((element) {
          return element['UpdateName'].toString().contains(searchValue);
        }).toList();
      });
    } else if (value.length > 1) {
      // Tìm kiếm trong kết quả đã có
      setState(() {
        tempSearchStore = queryResultSet.where((element) {
          return element['UpdateName'].toString().contains(searchValue);
        }).toList();
        
        // Nếu không có kết quả, thử tìm kiếm nâng cao
        if (tempSearchStore.isEmpty && queryResultSet.isNotEmpty) {
          // Tìm kiếm với điều kiện ít nghiêm ngặt hơn
          tempSearchStore = queryResultSet.where((element) {
            String name = element['Name']?.toString().toUpperCase() ?? '';
            return name.contains(searchValue);
          }).toList();
        }
      });
      
      // Nếu vẫn không có kết quả, thử tìm kiếm tất cả sản phẩm
      if (tempSearchStore.isEmpty) {
        QuerySnapshot allProducts = await DatabaseMethods().advancedSearch(value);
        List<Map<String, dynamic>> allResults = [];
        
        for (var doc in allProducts.docs) {
          allResults.add(doc.data() as Map<String, dynamic>);
        }
        
        setState(() {
          queryResultSet = allResults;
          tempSearchStore = queryResultSet.where((element) {
            String name = element['Name']?.toString().toUpperCase() ?? '';
            return name.contains(searchValue);
          }).toList();
        });
      }
    }
  }

  String? name, image;

  getthesharedpref() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    userId = await SharedPreferenceHelper().getUserId() ?? ""; // Lấy userId từ SharedPreferences
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    ontheload();
    updateProductsWithSoldCount();
    getBestSellingProducts();
    super.initState();
  }

  void updateProductsWithSoldCount() async {
    await DatabaseMethods().updateAllProductsWithSoldCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: name == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "images/bgr2.jpg", // ảnh nền ở đây
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Good day for shopping",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                                Text(name!,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                // Icon thông báo
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => NotificationsPage()),
                                        );
                                      },
                                      child: Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    StreamBuilder<int>(
                                      stream: NotificationService.getUnreadCount(userId),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data! > 0) {
                                          return Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                snapshot.data! > 9 ? '9+' : snapshot.data!.toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(width: 16),
                                // Icon giỏ hàng (giữ nguyên code hiện tại)
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => CartPage()),
                                        ).then((_) {
                                          // Cập nhật UI khi quay lại từ trang giỏ hàng
                                          setState(() {});
                                        });
                                      },
                                      child: Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    if (CartService.cartItems.isNotEmpty)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${CartService.cartItems.length}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          width: MediaQuery.of(context).size.width,
                          child: TextField(
                            onChanged: (value) {
                              initiateSearch(value);
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Search Products",
                              hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                              prefixIcon: Icon(
                                Icons.search_outlined,
                                color: Colors.grey,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        search
                            ? ListView(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          primary: false,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: tempSearchStore.map((element) {
                            return buildResultCard(element);
                          }).toList(),
                        )
                            : Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Categories",
                                style: AppWidget.semiboldTextFeildStyle()
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(20),
                                margin: EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: Center(
                                    child: Text(
                                      "All",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ))),
                            Expanded(
                              child: Container(
                                height: 80,
                                child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: categories.length,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      return CategoryTile(
                                          image: categories[index],
                                          name: Categoryname[index]);
                                    }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20), 
                        topRight: Radius.circular(20)
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "images/banner.jpg",
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Best Selling Products",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Chuyển đến trang tất cả sản phẩm
                              },
                              child: Text(
                                "View all",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        StreamBuilder(
                          stream: bestSellingStream,
                          builder: (context, AsyncSnapshot snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            
                            return GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                              ),
                              itemCount: snapshot.data.docs.length,
                              itemBuilder: (context, index) {
                                DocumentSnapshot ds = snapshot.data.docs[index];
                                
                                // Giải mã base64 từ Firestore
                                String base64Image = ds["Image"];
                                Uint8List bytes = base64Decode(base64Image);
                                
                                // Tạo giá giảm giá ngẫu nhiên cho một số sản phẩm
                                bool hasDiscount = index % 3 == 0;
                                String originalPrice = ds["Price"];
                                String discountPrice = "";
                                int discountPercent = 0;
                                
                                if (hasDiscount) {
                                  double price = double.parse(originalPrice);
                                  discountPercent = (10 + (index * 7) % 20); // 10%, 17%, 24%, 31%
                                  double discountedPrice = price * (1 - discountPercent / 100);
                                  discountPrice = price.toString();
                                  originalPrice = discountedPrice.toStringAsFixed(1);
                                }
                                
                                // Hiển thị số lượng đã bán
                                int soldCount = ds["SoldCount"] ?? 0;
                                
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetail(
                                          image: ds["Image"],
                                          name: ds["Name"],
                                          detail: ds["Detail"] ?? "",
                                          price: originalPrice,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Phần hình ảnh sản phẩm
                                            Stack(
                                              children: [
                                                Container(
                                                  height: 120,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(10),
                                                      topRight: Radius.circular(10),
                                                    ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(10),
                                                      topRight: Radius.circular(10),
                                                    ),
                                                    child: Image.memory(
                                                      bytes,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                
                                                // Badge giảm giá
                                                if (hasDiscount)
                                                  Positioned(
                                                    left: 0,
                                                    top: 8,
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber,
                                                        borderRadius: BorderRadius.only(
                                                          topRight: Radius.circular(8),
                                                          bottomRight: Radius.circular(8),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        "$discountPercent%",
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                
                                                // Nút yêu thích
                                                Positioned(
                                                  right: 8,
                                                  top: 8,
                                                  child: Container(
                                                    padding: EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.favorite_border,
                                                      color: Colors.grey,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            // Phần thông tin sản phẩm
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    ds["Name"],
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 14,
                                                      ),
                                                      Text(
                                                        " ${3.5 + (index % 2) * 0.5}",
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      // Thêm badge "Đã bán" ở đây
                                                      Spacer(),
                                                      Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          "Đã bán: $soldCount",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            "\$${originalPrice}",
                                                            style: TextStyle(
                                                              color: Color(0xfffd6f3e),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          // Thêm vào giỏ hàng
                                                          double priceValue = double.tryParse(originalPrice) ?? 0.0;
                                                          CartItem item = CartItem(
                                                            brand: ds["Category"] ?? "Brand",
                                                            name: ds["Name"],
                                                            color: "",
                                                            size: "",
                                                            price: priceValue,
                                                            quantity: 1,
                                                            image: ds["Image"],
                                                            detail: ds["Detail"] ?? "",
                                                          );
                                                          CartService.addToCart(item);
                                                          
                                                          // Hiển thị thông báo
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text("Đã thêm sản phẩm vào giỏ hàng"),
                                                              backgroundColor: Colors.green,
                                                              duration: Duration(seconds: 2),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.all(6),
                                                          decoration: BoxDecoration(
                                                            color: Color(0xfffd6f3e),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Icon(
                                                            Icons.add,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Thêm badge "Hot" cho sản phẩm bán chạy nhất
                                        if (index == 0)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(10),
                                                  bottomLeft: Radius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                "HOT",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget productCard(String image, String title, String price) {
    return Container(
      margin: EdgeInsets.only(right: 20),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Image.asset(
            image,
            height: 150,
            width: 150,
            fit: BoxFit.cover
          ),
          Text(
            title,
            style: AppWidget.semiboldTextFeildStyle(),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                price,
                style: TextStyle(
                    color: Color(0xfffd6f3e),
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 50),
              Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Color(0xfffd6f3e),
                      borderRadius: BorderRadius.circular(7)),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                  ))
            ],
          )
        ],
      ),
    );
  }

  Widget buildResultCard(var data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetail(
              image: data["Image"],
              name: data["Name"],
              detail: data["Detail"] ?? "",
              price: data["Price"],
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: Image.memory(
                base64Decode(data["Image"]),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data["Name"],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "\$${data["Price"]}",
                    style: TextStyle(
                      color: Color(0xfffd6f3e),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_shopping_cart, color: Color(0xfffd6f3e)),
              onPressed: () {
                // Thêm vào giỏ hàng
                double priceValue = double.tryParse(data["Price"]) ?? 0.0;
                CartItem item = CartItem(
                  brand: data["Category"] ?? "Brand",
                  name: data["Name"],
                  color: "",
                  size: "",
                  price: priceValue,
                  quantity: 1,
                  image: data["Image"],
                  detail: data["Detail"] ?? "",
                );
                CartService.addToCart(item);
                
                // Hiển thị thông báo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Đã thêm sản phẩm vào giỏ hàng"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                setState(() {}); // Cập nhật UI
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  String image, name;
  CategoryTile({required this.image, required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CategoryProduct(category: name)));
      },
      child: Container(
        width: 60,
        padding: EdgeInsets.all(1),
        margin: EdgeInsets.only(right: 30),
        decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle
        ),
        child:
            Image.asset(
              image,
              // height: 50,
              // width: 50,
              // fit: BoxFit.cover,
            ),
      ),
    );
  }
}
