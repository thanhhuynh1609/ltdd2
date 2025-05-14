import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Admin/home_admin.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  TextEditingController usernamecontroller = new TextEditingController();
  TextEditingController userpasswordcontroller = new TextEditingController();


  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset("images/logook.png", width: 170,),
              SizedBox(height: 20,),
              Text(
                "Hello, Administrator!",
                style: AppWidget.semiboldTextFeildStyle(),
              ),
              Text("Manage your system securely and efficiently.", style: TextStyle(fontSize: 18),),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                    color: Color(0xfff4f5f9),
                    borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  controller: usernamecontroller,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_outlined, color: Colors.grey,),
                      border: InputBorder.none, hintText: "Username",
                    contentPadding: EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                    color: Color(0xfff4f5f9),
                    borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  obscureText: true,
                  controller: userpasswordcontroller,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.password_outlined, color: Colors.grey,),
                      border: InputBorder.none, hintText: "Password",
                      contentPadding: EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
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
              SizedBox(height: 30,),
              GestureDetector(
                onTap: () {
                  loginAdmin();
                },
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: Color(0xff4b69fe),
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                        child: Text(
                      "LOGIN",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    )),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  loginAdmin() {
    FirebaseFirestore.instance.collection("Admin").get().then((snapshot) {
      snapshot.docs.forEach((result) {
        if (result.data()['username'] != usernamecontroller.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(
                "Your id is not correct",
                style: TextStyle(fontSize: 20),
              )));
        } else if (result.data()['password'] !=
            userpasswordcontroller.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(
                "Your Password is not correct",
                style: TextStyle(fontSize: 20),
              )));
        }
        else
        {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> HomeAdmin()));
        }
        // 2.57.15els
      });
    });
  }
}
