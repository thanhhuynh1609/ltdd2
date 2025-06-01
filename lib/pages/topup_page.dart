import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/services/notification_service.dart';

class TopupPage extends StatefulWidget {
  final String userId;
  
  const TopupPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<TopupPage> createState() => _TopupPageState();
}

class _TopupPageState extends State<TopupPage> {
  bool isLoading = false;
  Map<String, dynamic>? paymentIntentData;
  
  // Controller cho input số tiền
  final TextEditingController amountController = TextEditingController(text: "20");
  
  // Các mức nạp tiền gợi ý
  final List<double> suggestedAmounts = [10.0, 20.0, 50.0, 100.0];
  
  // Stripe keys
  final String stripePublishableKey = "";
  final String stripeSecretKey = "";

  @override
  void initState() {
    super.initState();
    initStripe();
  }

  @override
  void dispose() {
    // Giải phóng controller khi widget bị hủy
    amountController.dispose();
    super.dispose();
  }

  // Khởi tạo Stripe
  void initStripe() async {
    Stripe.publishableKey = stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  // Hiển thị payment sheet của Stripe
  Future<void> showStripePaymentSheet() async {
    // Kiểm tra và lấy số tiền từ input
    String amountText = amountController.text.trim();
    double? amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng nhập số tiền hợp lệ"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // Tạo payment intent
      paymentIntentData = await createPaymentIntent(
        amount.round().toString(), 
        'USD'
      );
      
      // Khởi tạo payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          merchantDisplayName: 'Shopping App',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.blue,
            ),
          ),
        ),
      );
      
      setState(() {
        isLoading = false;
      });
      
      // Hiển thị payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      // Nếu thanh toán thành công, cập nhật số dư ví
      await updateWalletBalance(amount);

      // Tạo thông báo
      await NotificationService.createNotification(
        userId: widget.userId,
        title: "Nạp tiền thành công",
        message: "Bạn đã nạp thành công \$${amount.toStringAsFixed(2)} vào ví.",
        type: "wallet_topup",
        transactionId: paymentIntentData!['id'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nạp tiền thành công!"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Quay lại trang ví với kết quả thành công
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Nạp tiền bị hủy"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tạo payment intent
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': (int.parse(amount) * 100).toString(), // Chuyển đổi sang cents
        'currency': currency,
        'payment_method_types[]': 'card'
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      
      return jsonDecode(response.body);
    } catch (err) {
      if (kDebugMode) {
        print('Lỗi tạo payment intent: ${err.toString()}');
      }
      throw Exception(err.toString());
    }
  }

  // Cập nhật số dư ví sau khi nạp tiền thành công
  Future<void> updateWalletBalance(double amount) async {
    try {
      print("Cập nhật số dư ví cho userId: ${widget.userId}");
      
      // Lấy số dư hiện tại
      DocumentSnapshot walletDoc = await FirebaseFirestore.instance
          .collection("wallets")
          .doc(widget.userId)
          .get();
      
      double currentBalance = 0.0;
      if (walletDoc.exists) {
        Map<String, dynamic> walletData = walletDoc.data() as Map<String, dynamic>;
        currentBalance = (walletData['balance'] ?? 0.0).toDouble();
        print("Số dư hiện tại: $currentBalance");
      } else {
        print("Chưa có ví, tạo mới");
      }
      
      // Cập nhật số dư ví
      double newBalance = currentBalance + amount;
      print("Số dư mới: $newBalance");
      
      // Cập nhật trong Firestore
      await FirebaseFirestore.instance
          .collection("wallets")
          .doc(widget.userId)
          .set({
        'userId': widget.userId,
        'balance': newBalance,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Thêm giao dịch mới
      Map<String, dynamic> transactionData = {
        'userId': widget.userId,
        'amount': amount,
        'type': 'topup',
        'method': 'Stripe',
        'timestamp': FieldValue.serverTimestamp(),
        'paymentId': paymentIntentData?['id'] ?? "",
        'status': 'completed'
      };
      
      print("Dữ liệu giao dịch sẽ lưu: $transactionData");
      
      DocumentReference transactionRef = await FirebaseFirestore.instance
          .collection("wallet_transactions")
          .add(transactionData);
      
      print("Đã tạo giao dịch mới với ID: ${transactionRef.id}");
    } catch (e) {
      print("Error updating wallet balance: $e");
      throw Exception("Không thể cập nhật số dư ví: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF4A5CFF),
        elevation: 0,
        title: Text(
          "Nạp tiền vào ví",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hướng dẫn
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Nhập số tiền bạn muốn nạp vào ví. Thanh toán sẽ được xử lý qua Stripe.",
                              style: TextStyle(
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Nhập số tiền
                    Text(
                      "Số tiền nạp",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Input số tiền
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.attach_money, size: 24),
                        hintText: "Nhập số tiền",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF4A5CFF), width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Các mức tiền gợi ý
                    Text(
                      "Số tiền gợi ý",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Các nút gợi ý
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: suggestedAmounts.map((amount) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              amountController.text = amount.toStringAsFixed(0);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              "\$${amount.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: 36),
                    
                    // Phương thức thanh toán
                    Text(
                      "Phương thức thanh toán",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Card thanh toán
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RadioListTile(
                        title: Row(
                          children: [
                            Image.asset(
                              'assets/images/stripe_logo.png',
                              width: 60,
                              height: 40,
                              // Nếu không có ảnh, thay bằng Icon
                              errorBuilder: (context, error, stackTrace) => 
                                Icon(Icons.credit_card, size: 30, color: Colors.blue),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Thẻ tín dụng/ghi nợ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text("Thanh toán an toàn qua Stripe"),
                        value: "stripe",
                        groupValue: "stripe",
                        onChanged: (value) {},
                        activeColor: Color(0xFF4A5CFF),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 36),
                    
                    // Nút nạp tiền
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: showStripePaymentSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A5CFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Nạp tiền ngay",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Lưu ý bảo mật
                    Center(
                      child: Text(
                        "Thông tin thanh toán của bạn được bảo mật",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            "Thanh toán được mã hóa SSL",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}




