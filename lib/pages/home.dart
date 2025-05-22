import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/category_products.dart';
import 'package:shopping_app/pages/cart_page.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shopping_app/services/cart_service.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/pages/favorites_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool search = false;

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

  initiateSearch(value) {
    if (value.length == 0) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
      });
    }
    setState(() {
      search = true;
    });

    var CapitalizedValue =
        value.substring(0, 1).toUpperCase() + value.substring(1);
    if (queryResultSet.isEmpty && value.length == 1) {
      DatabaseMethods().search(value).then((QuerySnapshot docs) {
        for (int i = 0; i < docs.docs.length; ++i) {
          queryResultSet.add(docs.docs[i].data());
        }
      });
    } else {
      tempSearchStore = [];
      queryResultSet.forEach((element) {
        if (element['UpdateName'].startsWith(CapitalizedValue)) {
          setState(() {
            tempSearchStore.add(element);
          });
        }
      });
    }
  }

  String? name, image;

  getthesharedpref() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    ontheload();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trang chủ"),
        actions: [
          // Các nút khác...
        ],
      ),
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
                              "Popular Products", 
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
                          stream: FirebaseFirestore.instance.collection("Products").limit(6).snapshots(),
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
                                
                                return Container(
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Phần ảnh sản phẩm
                                      Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Chuyển đến trang chi tiết sản phẩm khi nhấn vào hình ảnh
                                              Navigator.push(
                                                context, 
                                                MaterialPageRoute(
                                                  builder: (context) => ProductDetail(
                                                    detail: ds["Detail"] ?? "",
                                                    image: ds["Image"],
                                                    name: ds["Name"],
                                                    price: originalPrice
                                                  )
                                                )
                                              );
                                            },
                                            child: Container(
                                              height: 120,
                                              width: double.infinity,
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
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (hasDiscount)
                                                      Text(
                                                        "\$$discountPrice",
                                                        style: TextStyle(
                                                          decoration: TextDecoration.lineThrough,
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
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

  Widget buildResultCard(data) {
    return Container(
      height: 100,
      child: Row(
        children: [
          Image.network(
            data["Image"],
            height: 50,
            width: 50,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 10),
          Text(
            data["Name"],
            style: AppWidget.semiboldTextFeildStyle()
                .copyWith(color: Colors.white),
          )
        ],
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
