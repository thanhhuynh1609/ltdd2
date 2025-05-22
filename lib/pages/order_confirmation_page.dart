import 'package:flutter/material.dart';
import 'package:shopping_app/pages/bottomnav.dart';

class OrderConfirmationPage extends StatelessWidget {
  final String orderTotal;
  final String orderId;
  // Thêm trường paymentMethod vào constructor
  final String paymentMethod;

  const OrderConfirmationPage({
    Key? key,
    required this.orderTotal,
    required this.orderId,
    this.paymentMethod = "",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Thêm dòng debug này
    print("OrderConfirmationPage - orderTotal: $orderTotal");
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Xác nhận đơn hàng"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            SizedBox(height: 20),
            Text(
              "Đặt hàng thành công!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Mã đơn hàng: #$orderId",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 30),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Hiển thị phương thức thanh toán
                    ListTile(
                      leading: Icon(
                        paymentMethod == "Ví điện tử" 
                            ? Icons.account_balance_wallet 
                            : Icons.credit_card,
                        color: Colors.blue,
                      ),
                      title: Text("Phương thức thanh toán"),
                      subtitle: Text(paymentMethod.isEmpty ? "Thanh toán online" : paymentMethod),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> Bottomnav()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A5CFF),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text(
                "Tiếp tục mua sắm",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


