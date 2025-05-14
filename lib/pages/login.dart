import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Admin/admin_login.dart';
import 'package:shopping_app/pages/bottomnav.dart';
import 'package:shopping_app/pages/signup.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = "", password = "";
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  userLogin() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      // Kiểm tra xem tài khoản có bị đánh dấu là "đã xóa" hay không
      DocumentSnapshot deletedUserDoc = await FirebaseFirestore.instance
          .collection("deleted_users")
          .doc(userCredential.user!.uid)
          .get();
      
      if (deletedUserDoc.exists) {
        // Tài khoản đã bị xóa, đăng xuất và hiển thị thông báo
        await FirebaseAuth.instance.signOut();
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Tài khoản này đã bị vô hiệu hóa bởi quản trị viên", 
                       style: TextStyle(fontSize: 18)),
        ));
        
        return;
      }
      
      // Tiếp tục quá trình đăng nhập bình thường
      // Fetch dữ liệu người dùng từ Firestore bằng UID
      Map<String, dynamic>? userData = await DatabaseMethods()
          .getUserDetails(userCredential.user!.uid);

      // Nếu không tìm thấy bằng UID, tra cứu bằng email
      if (userData == null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection("user")
            .where("Email", isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
          // Cập nhật ID trong Shared Preferences và Firestore với UID mới
          String newId = userCredential.user!.uid;
          userData["Id"] = newId;
          await DatabaseMethods().addUserDetails(userData, newId);
        } else {
          // Nếu không tìm thấy, tạo tài khoản mới (hiếm khi xảy ra)
          userData = {
            "Name": "User", // Có thể yêu cầu nhập tên sau
            "Email": userCredential.user!.email,
            "Id": userCredential.user!.uid,
            "Image":
                "https://firebasestorage.googleapis.com/v0/b/barberapp-ebcc1.appspot.com/o/icon1.png?alt=media&token=0fad24a5-a01b-4d67-b4a0-676fbc75b34a"
          };
          await DatabaseMethods().addUserDetails(userData, userCredential.user!.uid);
        }
      }

      // Lưu dữ liệu vào Shared Preferences
      await SharedPreferenceHelper().saveUserEmail(userData["Email"]);
      await SharedPreferenceHelper().saveUserId(userData["Id"]);
      await SharedPreferenceHelper().saveUserName(userData["Name"]);
      await SharedPreferenceHelper().saveUserImage(userData["Image"]);

      // Chuyển hướng đến Bottomnav
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Bottomnav()));
    } on FirebaseException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              "No User Found for that Email",
              style: TextStyle(fontSize: 20),
            )));
      } else if (e.code == "wrong-password") {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              "Wrong Password Provided by User",
              style: TextStyle(fontSize: 20),
            )));
      }
    }
  }

  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 40),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                    "images/logook.png",
                  width: 170,
                ),
                SizedBox(height: 20,),
                Text(
                  "Welcome back,",
                  style: AppWidget.semiboldTextFeildStyle(),
                ),
                SizedBox(height: 20),
                Text(
                    "Discover Limitiess Choices and Unmatched Convenience.",
                    style: AppWidget.lightTextFeildStyle(),
                  ),
                SizedBox(height: 40),
                Container(
                  // padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                      color: Color(0xfff4f5f9),
                      borderRadius: BorderRadius.circular(10)),
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter your email';
                      }
                      return null;
                    },
                    controller: mailcontroller,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey,),
                        border: InputBorder.none,
                        hintText: "Email",
                        hintStyle: TextStyle(
                          color: Colors.grey
                        ),
                      contentPadding: EdgeInsets.symmetric(vertical: 20),),
                  ),
                ),
                SizedBox(height: 20),
                // Text("Password", style: AppWidget.semiboldTextFeildStyle()),
                SizedBox(height: 20),
                Container(
                  // padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                      color: Color(0xfff4f5f9),
                      borderRadius: BorderRadius.circular(10)),
                  child: TextFormField(
                    obscureText: true,
                    controller: passwordcontroller,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter your Password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.password_outlined, color: Colors.grey,),
                        border: InputBorder.none,
                        hintText: "Password",
                        hintStyle: TextStyle(
                          color: Colors.grey
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 20),),
                  ),
                ),
                SizedBox(height: 29),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  Row(
                    children: [
                      Checkbox(
                      value: isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isChecked = value!;
                        });
                      },
                      activeColor: Color(0xff4b69fe), // màu khi tick
                      checkColor: Colors.white,  // màu dấu tick
                                      ),
                      Text(
                        "Remember me!",
                        style: TextStyle(
                          color: Color(0xff7e7e7e),
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                        ),
                      )
                    ],
                  ),
                    GestureDetector(
                      onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdminLogin()));
                        },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                            color: Color(0xFFb8b4cc),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    if (_formkey.currentState!.validate()) {
                      setState(() {
                        email = mailcontroller.text;
                        password = passwordcontroller.text;
                      });
                      userLogin();
                    }
                  },
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Color(0xff4b69fe),
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                          child: Text(
                        "Login",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                      )),
                    ),
                  ),
                ),
                SizedBox(height: 20,),
                GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp()));
                  },
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1
                          )
                      ),
                      child: Center(
                          child: Text(
                            "Create Account",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                // fontWeight: FontWeight.bold
                            ),
                          )),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text("or sign in with", style: TextStyle(fontSize: 15),),
                ),
                SizedBox(height: 20,),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey,
                            width: 1
                          )
                        ),
                        child: Image.asset("images/fb.png", width: 30,),
                      ),
                      SizedBox(width: 20,),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.grey,
                                width: 1
                            )
                        ),
                        child: Image.asset("images/gg.png", width: 30,),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}














