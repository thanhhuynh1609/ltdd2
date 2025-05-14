import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shopping_app/Admin/add_product.dart';
import 'package:shopping_app/Admin/admin_login.dart';
import 'package:shopping_app/Admin/all_orders.dart';
import 'package:shopping_app/Admin/home_admin.dart';
import 'package:shopping_app/firebase_options.dart';
import 'package:shopping_app/pages/bottomnav.dart';
import 'package:shopping_app/pages/home.dart';
import 'package:shopping_app/pages/login.dart';
import 'package:shopping_app/pages/obboarding.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/pages/profile.dart';
import 'package:shopping_app/pages/signup.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Login());
  }
}


