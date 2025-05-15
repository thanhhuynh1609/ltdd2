import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shopping_app/pages/home.dart';
import 'package:shopping_app/pages/favorite_products.dart';
import 'package:shopping_app/pages/profile.dart';
import 'package:shopping_app/pages/Order.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({Key? key}) : super(key: key);

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentTabIndex = 0;
  
  late List<Widget> pages = [
    Home(),
    Order(),
    FavoriteProducts(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Color(0xfff2f2f2),
        color: Colors.black,
        animationDuration: Duration(milliseconds: 500),
        onTap: (int index){
          setState(() {
            currentTabIndex = index;
          });
        },
        items: [
          Icon(
            Icons.home_outlined,
            color: Colors.white,
          ),
          Icon(
            Icons.shopping_bag_outlined,
            color: Colors.white,
          ),
          Icon(
            Icons.favorite_outline,
            color: Colors.white,
          ),
          Icon(
            Icons.person_2_outlined,
            color: Colors.white,
          ),
        ]),
        body: pages[currentTabIndex],
    );
  }
}
