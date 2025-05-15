import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/category_products.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'dart:convert';
import 'dart:typed_data';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool search = false;
  bool isLoading = false;

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

  // Thêm biến để lưu danh sách sản phẩm được yêu thích nhất
  List<Map<String, dynamic>> mostFavoriteProducts = [];

  // Sửa hàm initiateSearch để tránh lỗi RangeError
  initiateSearch(value) {
    // Reset search results if search term is empty
    if (value.length == 0) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        search = false;
        isLoading = false;
      });
      return;
    }
    
    setState(() {
      search = true;
      isLoading = true;
      tempSearchStore = [];
    });

    // Perform search in Firestore - sửa để tránh lỗi RangeError
    DatabaseMethods().getAllProductsSnapshot().then((QuerySnapshot docs) {
      setState(() {
        isLoading = false;
        queryResultSet = [];
        // Add all documents to queryResultSet
        for (int i = 0; i < docs.docs.length; ++i) {
          if (docs.docs[i].data() != null) {
            queryResultSet.add(docs.docs[i].data());
          }
        }
        
        tempSearchStore = [];
        // Filter results manually
        queryResultSet.forEach((element) {
          // Check if Name contains search term (case insensitive)
          if (element['Name'] != null && 
              element['Name'].toString().toLowerCase().contains(value.toLowerCase())) {
            tempSearchStore.add(element);
          }
        });
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      print("Error in search: $error");
    });
  }

  String? name, image;

  getthesharedpref() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    setState(() {});
  }

  // Thêm phương thức getontheload nếu chưa có
  void getontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  // Sửa lỗi cú pháp return
  Widget mostFavoriteProductsSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sản phẩm được yêu thích",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          FutureBuilder<QuerySnapshot>(
            future: DatabaseMethods().getMostFavoriteProducts(5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text("Đã xảy ra lỗi"));
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("Không có sản phẩm nào"));
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return buildResultCard(doc);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getontheload();
    loadMostFavoriteProducts();
  }

  // Thêm hàm để kiểm tra tất cả sản phẩm
  void showAllProducts() {
    setState(() {
      isLoading = true;
    });
    
    DatabaseMethods().getAllProductsSnapshot().then((QuerySnapshot docs) {
      setState(() {
        isLoading = false;
      });
      // Hiển thị tổng số sản phẩm
      print("Total products: ${docs.docs.length}");
      
      // Duyệt qua từng sản phẩm và in ra tên
      docs.docs.forEach((doc) {
        // Kiểm tra xem doc.data() có tồn tại và có trường 'Name' không
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data != null && data.containsKey('Name')) {
          print("Product: ${data['Name']}");
        } else {
          print("Product without name: ${doc.id}");
        }
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching all products: $error");
    });
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
                                // Thêm nút để kiểm tra sản phẩm
                                IconButton(
                                  icon: Icon(Icons.refresh, color: Colors.white),
                                  onPressed: showAllProducts,
                                ),
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 30,
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
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: isLoading 
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : ListView(
                                      padding: EdgeInsets.all(10),
                                      primary: false,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      children: tempSearchStore.isEmpty
                                          ? [
                                              Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20.0),
                                                  child: Text(
                                                    "Không tìm thấy sản phẩm",
                                                    style: TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                              )
                                            ]
                                          : tempSearchStore.map<Widget>((element) {
                                              return buildResultCard(element);
                                            }).toList(),
                                    ),
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
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)), ),

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
                        SizedBox(
                          height: 20,
                        ),
                        Text("Popular Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),)
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

  Widget buildResultCard(product) {
    try {
      // Kiểm tra xem hình ảnh có phải là base64 không
      Widget imageWidget;
      try {
        if (product["Image"] == null || product["Image"].toString().isEmpty) {
          // Nếu không có hình ảnh
          imageWidget = Container(
            width: 80,
            height: 80,
            color: Colors.grey[300],
            child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
          );
        } else if (product["Image"].toString().startsWith('http')) {
          // Nếu là URL
          imageWidget = Image.network(
            product["Image"],
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print("Error loading network image: $error");
              return Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, color: Colors.grey[600]),
              );
            },
          );
        } else {
          // Nếu là base64
          try {
            String base64Image = product["Image"];
            // Xử lý base64 an toàn
            if (base64Image.contains(',')) {
              base64Image = base64Image.split(',').last;
            }
            
            // Đảm bảo chuỗi base64 hợp lệ
            base64Image = base64Image.trim();
            
            // Thêm padding nếu cần
            while (base64Image.length % 4 != 0) {
              base64Image += '=';
            }
            
            Uint8List bytes = base64Decode(base64Image);
            imageWidget = Image.memory(
              bytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print("Error displaying memory image: $error");
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                );
              },
            );
          } catch (e) {
            print("Error decoding base64: $e");
            imageWidget = Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
            );
          }
        }
      } catch (e) {
        // Nếu có lỗi, hiển thị ảnh mặc định
        print("Error processing image: $e");
        imageWidget = Container(
          width: 80,
          height: 80,
          color: Colors.grey[300],
          child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
        );
      }
      
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetail(
                detail: product["Detail"] ?? "",
                image: product["Image"] ?? "",
                name: product["Name"] ?? "",
                price: product["Price"] ?? "",
                productId: product.id, // Thêm productId
                votes: product["votes"] ?? 0, // Thêm votes
              ),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageWidget,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product["Name"] ?? "Unknown Product",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "\$${product["Price"] ?? "0"}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xfffd6f3e),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      );
    } catch (e) {
      print("Error building result card: $e");
      return Container(); // Return empty container on error
    }
  }

  // Thêm widget hiển thị sản phẩm được yêu thích nhất
   Widget topFavoriteProductsSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sản phẩm được yêu thích",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          FutureBuilder<QuerySnapshot>(
            future: DatabaseMethods().getMostFavoriteProducts(5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text("Đã xảy ra lỗi"));
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("Không có sản phẩm nào"));
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return buildResultCard(doc);
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  void loadMostFavoriteProducts() {}

  Future<void> toggleFavorite(DocumentSnapshot product) async {
    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      if (userId != null) {
        String productId = product.id;
        
        // Kiểm tra trạng thái yêu thích hiện tại
        bool isFavorite = await isProductFavorite(userId, productId);
        
        // Lấy dữ liệu sản phẩm
        Map<String, dynamic> productData = product.data() as Map<String, dynamic>;
        
        if (!isFavorite) {
          // Thêm vào yêu thích với đầy đủ thông tin
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Đã thêm vào danh sách yêu thích"))
          );
        } else {
          // Xóa khỏi yêu thích
          await FirebaseFirestore.instance
              .collection("user")
              .doc(userId)
              .collection("favorites")
              .doc(productId)
              .delete();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Đã xóa khỏi danh sách yêu thích"))
          );
        }
        
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vui lòng đăng nhập để thêm vào yêu thích"))
        );
      }
    } catch (e) {
      print("Lỗi khi thêm/xóa yêu thích: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra: $e"))
      );
    }
  }

  // Thêm phương thức này để kiểm tra trạng thái yêu thích
  Future<bool> isProductFavorite(String userId, String productId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("user")
          .doc(userId)
          .collection("favorites")
          .doc(productId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print("Lỗi khi kiểm tra trạng thái yêu thích: $e");
      return false;
    }
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
