import 'dart:convert'; // Để sử dụng base64Decode
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';

class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
Stream? orderStream;

getontheload()async{
  orderStream = await DatabaseMethods().allOrders();
  setState(() {
    
  });
}

@override
void initState() {
  getontheload();
  super.initState();
}



Widget allOrders() {
    return StreamBuilder(
      stream: orderStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data.docs.isEmpty) {
          return Center(
            child: Text("No orders found", style: AppWidget.semiboldTextFeildStyle()),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];

            // Giải mã base64 từ Firestore
            String base64Image = ds["ProductImage"];
            Uint8List? imageBytes;

            try {
              imageBytes = base64Decode(base64Image);
            } catch (e) {
              print("Error decoding base64 image: $e");
              imageBytes = null;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hiển thị ảnh từ base64 hoặc placeholder nếu lỗi
                          imageBytes != null
                              ? Image.memory(
                                  imageBytes,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 120,
                                  width: 120,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image_not_supported),
                                ),
                                Spacer(),
                                 Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20,),
                                  Text(
                                    "Name: "+ds["Name"],
                                    style: AppWidget.semiboldTextFeildStyle(),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width/3,
                                    child: Text(
                                      "Email: "+ds["Email"],
                                      style: AppWidget.lightTextFeildStyle(),
                                    ),
                                  ),
                                  Text(
                                    ds["Product"],
                                    style: AppWidget.semiboldTextFeildStyle(),
                                  ),
                                  Text(
                                    "\$${ds["Price"]}",
                                    style: TextStyle(
                                      color: Color(0xfffd6f3e),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10,), 
                                  GestureDetector(
                                    onTap: ()async{
                                      await DatabaseMethods().UpdateStatus(ds.id);
                                      setState(() {
                                        
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 5),
                                      width: 150,
                                      decoration: BoxDecoration(
                                        color: Color(0xfffd6f3e),
                                        borderRadius: BorderRadius.circular(10)
                                      ),
                                      child: Center(child: Text("Done", style: AppWidget.semiboldTextFeildStyle(),)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Center(child: Text("All Orders", style: AppWidget.boldTextFeildStyle(),)),),
      body: Container(
        margin: EdgeInsets.only(top: 20, left: 20, right: 20,),
        child: Column(children: [
            Expanded(child: allOrders())
        ],),
      ),
    );
  }
}