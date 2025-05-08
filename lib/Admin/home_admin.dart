import 'package:flutter/material.dart';
import 'package:shopping_app/Admin/add_product.dart';
import 'package:shopping_app/Admin/all_orders.dart';
import 'package:shopping_app/Admin/manage_products.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      appBar: AppBar(
        backgroundColor: Color(0xfff2f2f2),
        title: Text(
          'Trang quản trị',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            // Nút thêm sản phẩm
            _buildAdminButton(
              icon: Icons.add_circle_outline,
              title: "Thêm sản phẩm mới",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AddProduct()));
              },
            ),
            SizedBox(height: 20.0),
            
            // Nút quản lý sản phẩm
            _buildAdminButton(
              icon: Icons.inventory,
              title: "Quản lý sản phẩm",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ManageProducts()));
              },
            ),
            SizedBox(height: 20.0),
            
            // Nút quản lý đơn hàng
            _buildAdminButton(
              icon: Icons.shopping_cart,
              title: "Quản lý đơn hàng",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AllOrders()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
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
            SizedBox(width: 20.0),
            Icon(
              icon,
              size: 30.0,
              color: Color(0xfffd6f3e),
            ),
            SizedBox(width: 20.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
