import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}


class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? selectedImageBytes; // Dùng cho Flutter Web
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  bool isLoading = false;

  // Chọn ảnh từ thư viện
  Future<void> getImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // Dành cho Web
          selectedImageBytes = await image.readAsBytes();
        } else {
          // Dành cho Mobile
          selectedImage = File(image.path);
        }
        setState(() {});
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // Upload sản phẩm
  Future<void> uploadItem() async {
    if ((selectedImage != null || selectedImageBytes != null) &&
        nameController.text.isNotEmpty &&
        value != null) {  // Kiểm tra value có null không
      
      // Hiển thị loading
      setState(() {
        isLoading = true;
      });

      try {
        // Chuyển đổi ảnh thành Base64
        String? base64Image;
        if (kIsWeb && selectedImageBytes != null) {
          base64Image = base64Encode(selectedImageBytes!);
        } else if (selectedImage != null) {
          base64Image = base64Encode(await selectedImage!.readAsBytes());
        }

        if (base64Image == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Error converting image to Base64.",
              style: TextStyle(fontSize: 18),
            ),
          ));
          return;
        }
        
        String firstletter = nameController.text.substring(0,1).toUpperCase();
        
        // Thêm sản phẩm vào cơ sở dữ liệu
        Map<String, dynamic> addProduct = {
          "Name": nameController.text,
          "Image": base64Image,
          "SearchKey": firstletter,
          "UpdateName": nameController.text.toUpperCase(),
          "Price": priceController.text,
          "Detail": detailController.text,
          "Category": value,
        };

        // Thêm vào collection danh mục
        await DatabaseMethods().addProduct(addProduct, value!);
        
        // Thêm vào collection Products
        await DatabaseMethods().addAllProducts(addProduct);
        
        // Reset form
        setState(() {
          selectedImage = null;
          selectedImageBytes = null;
          nameController.clear();
          priceController.clear();
          detailController.clear();
          // Không reset value để người dùng có thể tiếp tục thêm sản phẩm cùng danh mục
        });
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Product has been uploaded successfully!",
            style: TextStyle(fontSize: 20),
          ),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Error uploading product: $e",
            style: TextStyle(fontSize: 18),
          ),
        ));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Please fill all fields, select an image, and choose a category.",
          style: TextStyle(fontSize: 18),
        ),
      ));
    }
  }

  String? value;
  final List<String> categoryItems = ['Watch', 'Laptop', 'TV', 'Headphones'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios_new_outlined),
        ),
        title: Text(
          "Add Product",
          style: AppWidget.semiboldTextFeildStyle(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Upload the Product Image",
                style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            GestureDetector(
              onTap: getImage,
              child: Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: selectedImage == null && selectedImageBytes == null
                      ? Icon(Icons.camera_alt_outlined)
                      : kIsWeb
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(selectedImageBytes!,
                                  fit: BoxFit.cover),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child:
                                  Image.file(selectedImage!, fit: BoxFit.cover),
                            ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text("Product Name", style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xffececf8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            SizedBox(height: 20),
            Text("Product Price", style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xffececf8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: priceController,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            SizedBox(height: 20),
            Text("Product Detail", style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xffececf8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                maxLines: 6,
                controller: detailController,
                decoration: InputDecoration(border: InputBorder.none),
              ),
            ),
            
            SizedBox(height: 20),
            Text("Product Category", style: AppWidget.lightTextFeildStyle()),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Color(0xffececf8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  items: categoryItems
                      .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item,
                                style: AppWidget.semiboldTextFeildStyle()),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => this.value = value),
                  dropdownColor: Colors.white,
                  hint: Text("Select Category"),
                  iconSize: 36,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                  value: value,
                ),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: uploadItem,
                child: Text("Add Product", style: TextStyle(fontSize: 22)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}








// import 'dart:io';

// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:random_string/random_string.dart';
// import 'package:shopping_app/pages/widget/support_widget.dart';
// import 'package:shopping_app/services/database.dart';

// class AddProduct extends StatefulWidget {
//   const AddProduct({super.key});

//   @override
//   State<AddProduct> createState() => _AddProductState();
// }

// class _AddProductState extends State<AddProduct> {
// final ImagePicker _picker = new ImagePicker();
// File? selectedImage;
// TextEditingController namecontroller = new TextEditingController();

// Future getImage()async{
//   var image = await _picker.pickImage(source: ImageSource.gallery);
//   selectedImage= File(image!.path);
//   setState(() {
    
//   });
// }

// uploadItem()async{
//   if(selectedImage!=null && namecontroller.text!=""){
//     String addId = randomAlphaNumeric(10);
//     Reference firebaseStorageRef = FirebaseStorage.instance.ref().child("blogImage").child(addId);

//     final UploadTask task = firebaseStorageRef.putFile(selectedImage!);
//     var dowloadUrl = await (await task).ref.getDownloadURL();

//     Map<String, dynamic> addProduct={
//       "Name": namecontroller.text,
//       "Image": dowloadUrl,

//     };
//     await DatabaseMethods().addProduct(addProduct, value!).then((value){
//       selectedImage=null;
//       namecontroller.text="";
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         backgroundColor: Colors.redAccent,
//         content: Text("Product has been uploaded Success", style: TextStyle(fontSize: 20),)));
//     });
//       }
// }

//   String? value;
//   final List<String> categoryitem = ['Watch', 'Laptop', 'TV', 'Headphones'];
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: GestureDetector(
//             onTap: () {
//               Navigator.pop(context);
//             },
//             child: Icon(Icons.arrow_back_ios_new_outlined)),
//         title: Text(
//           "Add Product",
//           style: AppWidget.semiboldTextFeildStyle(),
//         ),
//       ),
//       body: Container(
//         margin: EdgeInsets.only(left: 20, top: 20, right: 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Upload the Product Image",
//               style: AppWidget.lightTextFeildStyle(),
//             ),
//             SizedBox(
//               height: 20,
//             ),
//            selectedImage==null? GestureDetector(
//               onTap: (){
//                 getImage();
//               },
//               child: Center(
//                 child: Container(
//                   height: 150,
//                   width: 150,
//                   decoration: BoxDecoration(
//                       border: Border.all(color: Colors.black, width: 1.5),
//                       borderRadius: BorderRadius.circular(20)),
//                   child: Icon(Icons.camera_alt_outlined),
//                 ),
//               ),
//             ): Material(
//               borderRadius: BorderRadius.circular(20),
//               child: Container(
//                   height: 150,
//                   width: 150,
//                   decoration: BoxDecoration(
//                       border: Border.all(color: Colors.black, width: 1.5),
//                       borderRadius: BorderRadius.circular(20)),
//                   child: Image.file(selectedImage!, fit: BoxFit.cover,)
//                 ),
//             ),
//             SizedBox(
//               height: 20,
//             ),
//             Text(
//               "Product Name",
//               style: AppWidget.lightTextFeildStyle(),
//             ),
//             SizedBox(
//               height: 20,
//             ),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               width: MediaQuery.of(context).size.width,
//               decoration: BoxDecoration(
//                   color: Color(0xffececf8),
//                   borderRadius: BorderRadius.circular(20)),
//               child: TextField(
//                 controller: namecontroller,
//                 decoration: InputDecoration(border: InputBorder.none),
//               ),
//             ),
//             SizedBox(height: 20,),
//             Text(
//               "Product Category",
//               style: AppWidget.lightTextFeildStyle(),
//             ),
//             SizedBox(height: 20,),
//             Container(
//                 padding: EdgeInsets.symmetric(horizontal: 10),
//                 width: MediaQuery.of(context).size.width,
//                 decoration: BoxDecoration(
//                     color: Color(0xffececf8),
//                     borderRadius: BorderRadius.circular(10)),
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     items: categoryitem
//                         .map((item) => DropdownMenuItem(
//                             value: item,
//                             child: Text(
//                               item,
//                               style: AppWidget.semiboldTextFeildStyle(),
//                             )))
//                         .toList(),
//                     onChanged: ((value) => setState(() {
//                           this.value = value;
//                         })),
//                         dropdownColor: Colors.white,
//                         hint: Text("Select Category"),
//                         iconSize: 36,
//                         icon: Icon(Icons.arrow_drop_down, color: Colors.black,),
//                                 value: value,  ),
//                 )),
//                 SizedBox(height: 30,),
//                 Center(child: ElevatedButton(onPressed: (){
//                   uploadItem();
//                 }, child: Text("Add Product", style: TextStyle(fontSize: 22),)))
//           ],
//         ),
//       ),
//     );
//   }
// }
