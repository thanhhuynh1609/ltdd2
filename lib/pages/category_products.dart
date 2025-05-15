import 'dart:convert';  // Để sử dụng base64Decode
import 'dart:typed_data';  // Để sử dụng Uint8List

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/pages/widget/favorite_button.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';

class CategoryProduct extends StatefulWidget {
  String category;
  CategoryProduct({required this.category});

  @override
  State<CategoryProduct> createState() => _CategoryProductState();
}

class _CategoryProductState extends State<CategoryProduct> {
  Stream? CategoryStream;

  // Hàm lấy dữ liệu từ Firestore
  getontheload() async {
    CategoryStream = await DatabaseMethods().getProducts(widget.category);
    setState(() {});
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  // Hàm hiển thị sản phẩm từ Firestore
  Widget allProducts() {
    return StreamBuilder(
      stream: CategoryStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];

                  // Giải mã base64 từ Firestore
                  String base64Image = ds["Image"];
                  Uint8List bytes = base64Decode(base64Image);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetail(
                            detail: ds["Detail"] ?? "",
                            image: ds["Image"] ?? "",
                            name: ds["Name"] ?? "",
                            price: ds["Price"] ?? "",
                            productId: ds.id, // Thêm productId
                            votes: ds["votes"] ?? 0, // Thêm votes
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              SizedBox(height: 10,),
                              // Hiển thị hình ảnh từ base64
                              Image.memory(
                                bytes,
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: 10,),
                              Text(
                                ds["Name"],
                                style: AppWidget.semiboldTextFeildStyle(),
                              ),
                              Spacer(),
                              Row(
                                children: [
                                  Text(
                                    "\$" + ds["Price"],
                                    style: TextStyle(
                                        color: Color(0xfffd6f3e),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    width: 30,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetail(
                                            detail: ds["Detail"] ?? "",
                                            image: ds["Image"] ?? "",
                                            name: ds["Name"] ?? "",
                                            price: ds["Price"] ?? "",
                                            productId: ds.id, // Thêm productId
                                            votes: ds["votes"] ?? 0, // Thêm votes
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Color(0xfffd6f3e),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              icon: Icon(
                                Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                try {
                                  String? userId = await SharedPreferenceHelper().getUserId();
                                  if (userId != null) {
                                    // Kiểm tra trạng thái yêu thích hiện tại
                                    bool isFavorite = await DatabaseMethods().isProductFavorite(userId, ds.id);
                                    
                                    // Cập nhật trạng thái yêu thích trong database
                                    await DatabaseMethods().toggleFavoriteProduct(userId, ds.id, !isFavorite);
                                    
                                    // Thêm trường votes vào sản phẩm nếu chưa có
                                    try {
                                      // Đầu tiên, thêm trường votes vào sản phẩm trong collection Products
                                      await FirebaseFirestore.instance
                                          .collection("Products")
                                          .doc(ds.id)
                                          .set({"votes": 0}, SetOptions(merge: true));
                                          
                                      // Sau đó cập nhật số lượt thích
                                      int newVotes = !isFavorite ? 1 : 0;
                                      await FirebaseFirestore.instance
                                          .collection("Products")
                                          .doc(ds.id)
                                          .update({"votes": newVotes});
                                    } catch (e) {
                                      print("Lỗi khi cập nhật votes: $e");
                                    }
                                    
                                    // Hiển thị thông báo
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(!isFavorite 
                                        ? "Đã thêm vào danh sách yêu thích" 
                                        : "Đã xóa khỏi danh sách yêu thích"))
                                    );
                                    
                                    // Cập nhật UI
                                    setState(() {});
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Vui lòng đăng nhập để thêm vào yêu thích"))
                                    );
                                  }
                                } catch (e) {
                                  print("Lỗi khi thêm vào yêu thích: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Có lỗi xảy ra: $e"))
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
            : Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xfff2f2f2),
      ),
      body: Container(
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Container(
          child: Column(
            children: [
              Expanded(child: allProducts()),
            ],
          ),
        ),
      ),
    );
  }
}









// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:shopping_app/pages/widget/support_widget.dart';
// import 'package:shopping_app/services/database.dart';

// class CategoryProduct extends StatefulWidget {
//   String category;
//   CategoryProduct({required this.category});

//   @override
//   State<CategoryProduct> createState() => _CategoryProductState();
// }

// class _CategoryProductState extends State<CategoryProduct> {
//   Stream? CategoryStream;

//   getontheload()async{
//     CategoryStream= await DatabaseMethods().getProducts(widget.category);
//     setState(() {
      
//     });
//   }

//  @override
//  void initState(){
//   getontheload();
//    super.initState();
//  }


//   Widget allProducts() {
//     return StreamBuilder(
//         stream: CategoryStream,
//         builder: (context, AsyncSnapshot snapshot) {
//           return snapshot.hasData
//               ? GridView.builder(
//                   padding: EdgeInsets.zero,
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       childAspectRatio: 0.6,
//                       mainAxisSpacing: 10,
//                       crossAxisSpacing: 10),
//                   itemCount: snapshot.data.docs.length,
//                   itemBuilder: (context, index) {
//                     DocumentSnapshot ds = snapshot.data.docs[index];

//                     return Container(
//                       margin: EdgeInsets.only(right: 20),
//                       padding: EdgeInsets.symmetric(horizontal: 20),
//                       decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10)),
//                       child: Column(
//                         children: [
//                           Image.network(
//                             ds["Image"],
//                             height: 150,
//                             width: 150,
//                             fit: BoxFit.cover,
//                           ),
//                           Text(
//                             ds["Name"],
//                             style: AppWidget.semiboldTextFeildStyle(),
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Row(
//                             children: [
//                               Text(
//                                 "\$"+ds["Price"],
//                                 style: TextStyle(
//                                     color: Color(0xfffd6f3e),
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               SizedBox(
//                                 width: 50,
//                               ),
//                               Container(
//                                   padding: EdgeInsets.all(5),
//                                   decoration: BoxDecoration(
//                                       color: Color(0xfffd6f3e),
//                                       borderRadius: BorderRadius.circular(7)),
//                                   child: Icon(
//                                     Icons.add,
//                                     color: Colors.white,
//                                   ))
//                             ],
//                           )
//                         ],
//                       ),
//                     );
//                   })
//               : Container();
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xfff2f2f2),
//       ),
//       body: Container(
//         child: Container(
//           child: Column(
//             children: [
//               Expanded(child: allProducts()),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
