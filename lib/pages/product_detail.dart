import 'dart:convert'; // Để sử dụng base64Decode
import 'dart:typed_data'; // Để sử dụng Uint8List

import 'package:flutter/material.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';

class ProductDetail extends StatefulWidget {
  String image, name, detail, price;
  ProductDetail(
      {required this.detail,
      required this.image,
      required this.name,
      required this.price});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  String? name, mail, image;

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
  }

  @override
  Widget build(BuildContext context) {
    // Giải mã base64 từ chuỗi hình ảnh
    String base64Image = widget.image;
    Uint8List bytes = base64Decode(base64Image);

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
                // Hiển thị hình ảnh từ base64
                Center(
                  child: Image.memory(
                    bytes,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
                ),
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
                          style: AppWidget.boldTextFeildStyle(),
                        ),
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
      Map<String, dynamic> orderInfoMap = {
        "Product": widget.name,
        "Price": widget.price,
        "Name": name,
        "Email": mail,
        "Image": image,
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


















// import 'dart:convert'; // Để sử dụng base64Decode
// import 'dart:typed_data'; // Để sử dụng Uint8List

// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:shopping_app/pages/widget/support_widget.dart';
// import 'package:http/http.dart' as http;
// import 'package:shopping_app/services/constant.dart';
// import 'package:shopping_app/services/database.dart';
// import 'package:shopping_app/services/shared_pref.dart';

// class ProductDetail extends StatefulWidget {
//   String image, name, detail, price;
//   ProductDetail(
//       {required this.detail,
//       required this.image,
//       required this.name,
//       required this.price});

//   @override
//   State<ProductDetail> createSt ate() => _ProductDetailState();
// }

// class _ProductDetailState extends State<ProductDetail> {
// String? name, mail, image;
// getthesharedpref()async{
//   name = await SharedPreferenceHelper().getUserName();
//   mail = await SharedPreferenceHelper().getUserEmail();
//   image = await SharedPreferenceHelper().getUserImage(); 
//   setState(() {
    
//   });
// }

// ontheload()async{
//   await getthesharedpref();
//   setState(() {
    
//   });
// }

// @override
// void initState(){
//   super.initState();
//   ontheload();
// }


//   Map<String, dynamic>? paymentIntent;

//   @override
//   Widget build(BuildContext context) {
//     // Giải mã base64 từ chuỗi hình ảnh
//     String base64Image = widget.image;
//     Uint8List bytes = base64Decode(base64Image);

//     return Scaffold(
//       backgroundColor: Color(0xfffef5f1),
//       body: Container(
//         padding: EdgeInsets.only(top: 50),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Stack(
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.pop(context);
//                   },
//                   child: Container(
//                     margin: EdgeInsets.only(left: 20),
//                     padding: EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                         border: Border.all(),
//                         borderRadius: BorderRadius.circular(30)),
//                     child: Icon(Icons.arrow_back_ios_outlined),
//                   ),
//                 ),
//                 // Hiển thị hình ảnh từ base64
//                 Center(
//                   child: Image.memory(
//                     bytes,
//                     height: 400,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ],
//             ),
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.only(top: 20, left: 20, right: 20),
//                 decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(20),
//                         topRight: Radius.circular(20))),
//                 width: MediaQuery.of(context).size.width,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           widget.name,
//                           style: AppWidget.boldTextFeildStyle(),
//                         ),
//                         Text(
//                           "\$" + widget.price,
//                           style: TextStyle(
//                               color: Color(0xfffd6f3e),
//                               fontSize: 23,
//                               fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                     SizedBox(
//                       height: 20,
//                     ),
//                     Text(
//                       "Details",
//                       style: AppWidget.semiboldTextFeildStyle(),
//                     ),
//                     SizedBox(
//                       height: 10,
//                     ),
//                     Text(widget.detail),
//                     SizedBox(
//                       height: 40,
//                     ),
//                     GestureDetector(
//                       onTap: (){
//                         makePayment(widget.price);
//                       },
//                       child: Container(
//                         padding: EdgeInsets.symmetric(vertical: 10),
//                         decoration: BoxDecoration(
//                             color: Color(0xfffd6f3e),
//                             borderRadius: BorderRadius.circular(10)),
//                         width: MediaQuery.of(context).size.width,
//                         child: Center(
//                           child: Text(
//                             "Buy Now",
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> makePayment(String amount) async {
//     try {
//       paymentIntent = await createPaymentIntent(amount, 'INR');
//       await Stripe.instance
//           .initPaymentSheet(
//               paymentSheetParameters: SetupPaymentSheetParameters(
//                   paymentIntentClientSecret: paymentIntent?['client_secret'],
//                   style: ThemeMode.dark,
//                   merchantDisplayName: 'Adnan'))
//           .then((value) {});

//       displayPaymetSheet();
//     } catch (e, s) {
//       print('exception:$e$s');
//     }
//   }

//   displayPaymetSheet() async {
//     try {
//       await Stripe.instance.presentPaymentSheet().then((value) async {
//         Map<String, dynamic> orderInfoMap={
//           "Product": widget.name,
//           "Price": widget.price,
//           "Name": name,
//           "Email": mail,
//           "Image": image, 
//           "ProductImage": widget.image,
//         };
//         await DatabaseMethods().orderDetails(orderInfoMap);
//         showDialog(
//             context: context,
//             builder: (_) => AlertDialog(
//                   content: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.check_circle,
//                             color: Colors.green,
//                           ),
//                           Text("Payment Successfull!")
//                         ],
//                       )
//                     ],
//                   ),
//                 ));
//         paymentIntent = null;
//       }).onError((error, StackTrace) {
//         print("Error is :--->$error $StackTrace");
//       });
//     } on StripeException catch (e) {
//       print("Error is:---> $e");
//       showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//                 content: Text("Cancelled"),
//               ));
//     } catch (e) {
//       print('$e');
//     }
//   }

//   createPaymentIntent(String amount, String currency) async {
//     try {
//       Map<String, dynamic> body = {
//         'amount': calculateAmount(amount),
//         'currency': currency,
//         'payment_method_types[]': 'card'
//       };

//       var response = await http.post(
//           Uri.parse('https://api.stripe.com/v1/payment_intents'),
//           headers: {
//             'Authorization': 'Bearer $secretkey',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           }, body: body,
//           );
//           return jsonDecode(response.body); 
//     } catch (err) {
//       print('err charging user: ${err.toString()}');
//     }
//   }

//   calculateAmount(String amount) {
//     final calculatedAmount = (int.parse(amount) * 100);
//     return calculatedAmount.toString();
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:shopping_app/pages/widget/support_widget.dart';

// class ProductDetail extends StatefulWidget {
//   String image, name, detail, price;
//   ProductDetail({required this.detail, required this.image, required this.name, required this.price});

//   @override
//   State<ProductDetail> createState() => _ProductDetailState();
// }

// class _ProductDetailState extends State<ProductDetail> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xfffef5f1),
//       body: Container(
//         padding: EdgeInsets.only(top: 50,),
//         child: Column(
          
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Stack(
//               children: [GestureDetector(
//                 onTap: (){
//                   Navigator.pop(context);
//                 },
//                 child: Container(
//                   margin: EdgeInsets.only( left: 20),
//                   padding: EdgeInsets.all(10),
//                   decoration: BoxDecoration(border: Border.all(),borderRadius: BorderRadius.circular(30)),
//                   child: Icon(Icons.arrow_back_ios_outlined)),
//               ),
//               Center(child: Image.network(
//                 widget.image,
//                 height: 400,))
//               ]
//             ), 
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.only(top: 20, left: 20, right: 20  ),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
//                 ),
//                 width: MediaQuery.of(context).size.width, child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(widget.name, style:AppWidget.boldTextFeildStyle() ,),
//                         Text(
//                       "\$"+widget.price,
//                       style: TextStyle(
//                           color: Color(0xfffd6f3e),
//                           fontSize: 23,
//                           fontWeight: FontWeight.bold),
//                     )
//                       ],
//                     ),
//                     SizedBox(height: 20,),
//                     Text("Details", style: AppWidget.semiboldTextFeildStyle(),),
//                     SizedBox(height: 10,),
//                     Text(widget.detail),
//                     SizedBox(height: 40,),
//                     Container(
//                       padding: EdgeInsets.symmetric(vertical: 10),
//                       decoration: BoxDecoration(
//                         color: Color(0xfffd6f3e), borderRadius: BorderRadius.circular(10)
//                       ),
//                       width: MediaQuery.of(context).size.width,
//                       child: Center(child: Text("Buy Now", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),)),
//                     )
//                   ],
//                 ),),
//             )
            
//           ],
//         ),
//       ),
//     );
//   }
// }