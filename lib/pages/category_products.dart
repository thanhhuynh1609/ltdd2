import 'dart:convert';  // Để sử dụng base64Decode
import 'dart:typed_data';  // Để sử dụng Uint8List

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';

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

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Column(
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
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ProductDetail(detail: ds["Detail"], image: ds["Image"], name: ds["Name"], price: ds["Price"])));
                              },
                              child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                      color: Color(0xfffd6f3e),
                                      borderRadius: BorderRadius.circular(7)),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  )),
                            )
                          ],
                        )
                      ],
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
