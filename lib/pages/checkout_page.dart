import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/pages/cart_page.dart';
import 'package:shopping_app/pages/order_confirmation_page.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';
import 'package:shopping_app/services/cart_service.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'package:shopping_app/services/notification_service.dart';
import '../models/discount_code.dart'; // Thêm import

// Thêm các khóa Stripe (nên đặt trong file riêng trong thực tế)
const String stripePublishableKey = "pk_test_51RPcK7CrdiAruMyrzDn1P7rG9cpU4oiEblmxvu8NaGqojPJim3266dMKKYlg6s6mZbCyrE5HyMkiBO0D7cygWJIg00ciOGJswd";
const stripeSecretKey = String.fromEnvironment('STRIPE_SECRET_KEY');

class CheckoutPage extends StatefulWidget {
  final List<CartItem>? buyNowItems;

  const CheckoutPage({Key? key, this.buyNowItems}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? name;
  String? email;
  String? profileImage;
  String shippingAddress = "8281 Jimmy Coves, South Liana, Maine";
  String phoneNumber = "+923378095628";
  String paymentMethod = "Stripe";
  TextEditingController promoController = TextEditingController();
  Map<String, dynamic>? paymentIntentData;
  bool isLoading = false;

  // Danh sách sản phẩm thanh toán
  List<CartItem> get checkoutItems => widget.buyNowItems ?? CartService.cartItems;

  // Phí vận chuyển cố định
  final double shippingFee = 5.0;

  // Tính tổng tiền hàng
  double get subtotal {
    if (widget.buyNowItems != null) {
      return widget.buyNowItems!.fold(0, (sum, item) => sum + (item.price * item.quantity));
    } else {
      return CartService.getTotalAmount();
    }
  }

  // Tính thuế (10% tổng tiền hàng)
  double get taxFee => subtotal * 0.1;

  // Biến để lưu mã giảm giá đã áp dụng
  DiscountCode? appliedDiscountCode;
  double discount = 0.0;

  // Tính tổng đơn hàng sau khi áp dụng giảm giá
  double get orderTotal {
    double total = subtotal + shippingFee + taxFee - discount;
    return double.parse(total.toStringAsFixed(1));
  }

  // Thêm biến để lưu số dư ví
  double walletBalance = 0.0;
  bool isWalletLoading = false;

  @override
  void initState() {
    super.initState();
    getUserInfo();
    initStripe();
    getWalletBalance();
  }

  // Khởi tạo Stripe
  void initStripe() async {
    Stripe.publishableKey = stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  getUserInfo() async {
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    profileImage = await SharedPreferenceHelper().getUserProfile();
    setState(() {});
  }

  // Lấy số dư ví
  Future<void> getWalletBalance() async {
    setState(() {
      isWalletLoading = true;
    });

    try {
      String userId = await SharedPreferenceHelper().getUserId() ?? "";
      DocumentSnapshot walletDoc = await FirebaseFirestore.instance
          .collection("wallets")
          .doc(userId)
          .get();

      if (walletDoc.exists) {
        Map<String, dynamic> walletData = walletDoc.data() as Map<String, dynamic>;
        setState(() {
          walletBalance = (walletData['balance'] ?? 0.0).toDouble();
          isWalletLoading = false;
        });
      } else {
        setState(() {
          walletBalance = 0.0;
          isWalletLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi khi lấy số dư ví: $e");
      setState(() {
        isWalletLoading = false;
        walletBalance = 0.0;
      });
    }
  }

  // Hàm kiểm tra và áp dụng mã giảm giá
  Future<void> applyDiscountCode() async {
    String code = promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng nhập mã giảm giá')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      DiscountCode? discountCode = await DatabaseMethods().checkDiscountCode(code, subtotal);
      if (discountCode != null) {
        setState(() {
          appliedDiscountCode = discountCode;
          discount = discountCode.discountAmount;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Áp dụng mã giảm giá thành công')));
      } else {
        setState(() {
          appliedDiscountCode = null;
          discount = 0.0;
        });
        // Thông báo chi tiết hơn
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mã giảm giá không hợp lệ hoặc chưa có hiệu lực')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi kiểm tra mã giảm giá')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Hiển thị payment sheet của Stripe
  Future<void> showStripePaymentSheet() async {
    setState(() {
      isLoading = true;
    });

    try {
      paymentIntentData = await createPaymentIntent(
        orderTotal.round().toString(),
        'USD',
      );

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

      await Stripe.instance.presentPaymentSheet();

      // Cập nhật usageCount nếu có mã giảm giá
      if (appliedDiscountCode != null) {
        await DatabaseMethods().incrementDiscountCodeUsage(appliedDiscountCode!.id);
      }

      await processOrder();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Thanh toán thành công!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Thanh toán bị hủy"),
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
        'amount': (int.parse(amount) * 100).toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
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

  // Thanh toán bằng ví
  Future<void> processWalletPayment() async {
    setState(() {
      isLoading = true;
    });

    try {
      String userId = await SharedPreferenceHelper().getUserId() ?? "";

      if (walletBalance < orderTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Số dư ví không đủ. Vui lòng nạp thêm tiền hoặc chọn phương thức thanh toán khác."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      bool success = await DatabaseMethods().updateWalletBalance(
        userId,
        -orderTotal,
        "payment",
        "Thanh toán đơn hàng",
        orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      if (success) {
        // Cập nhật usageCount nếu có mã giảm giá
        if (appliedDiscountCode != null) {
          await DatabaseMethods().incrementDiscountCodeUsage(appliedDiscountCode!.id);
        }

        await processOrder(paymentMethod: "Ví điện tử");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Thanh toán thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Thanh toán thất bại. Vui lòng thử lại sau."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Lỗi khi thanh toán bằng ví: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Xử lý đặt hàng
  Future<void> processOrder({String? paymentMethod}) async {
    try {
      String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      List<CartItem> itemsToCheckout = checkoutItems;

      List<Map<String, dynamic>> productsList = itemsToCheckout.map((item) => {
        "Name": item.name,
        "Price": item.price.toString(),
        "Quantity": item.quantity,
        "Image": item.image,
        "Detail": item.detail,
      }).toList();

      Map<String, dynamic> orderMap = {
        "OrderId": orderId,
        "CustomerName": name ?? "",
        "CustomerEmail": email ?? "",
        "CustomerImage": profileImage ?? "",
        "ShippingAddress": shippingAddress,
        "PhoneNumber": phoneNumber,
        "PaymentMethod": paymentMethod ?? this.paymentMethod,
        "TotalAmount": orderTotal.toString(),
        "Subtotal": subtotal.toString(),
        "ShippingFee": shippingFee.toString(),
        "TaxFee": taxFee.toString(),
        "Discount": discount.toString(),
        "DiscountCode": appliedDiscountCode?.code ?? "",
        "Status": "Đang xử lý",
        "UserId": await SharedPreferenceHelper().getUserId(),
        "CreatedAt": FieldValue.serverTimestamp(),
        "Products": productsList,
        "PaymentId": paymentIntentData?['id'] ?? "",
      };

      await DatabaseMethods().createOrder(orderMap);

      String userId = await SharedPreferenceHelper().getUserId() ?? "";
      await NotificationService.createNotification(
        userId: userId,
        title: "Đơn hàng mới",
        message: "Đơn hàng #$orderId của bạn đã được đặt thành công.",
        type: "order",
        orderId: orderId,
      );

      if (widget.buyNowItems == null) {
        CartService.clearCart();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationPage(
            orderTotal: orderTotal.toString(),
            orderId: orderId,
            paymentMethod: paymentMethod ?? this.paymentMethod,
          ),
        ),
      );
    } catch (e) {
      print("Lỗi khi xử lý đơn hàng: $e");
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thanh toán"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildShippingSection(),
              SizedBox(height: 16),
              buildPromoCodeSection(),
              SizedBox(height: 16),
              buildPaymentMethodSection(),
              SizedBox(height: 16),
              buildOrderSummary(),
              SizedBox(height: 16),
              buildCheckoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sản phẩm",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: checkoutItems.length,
          itemBuilder: (context, index) {
            CartItem item = checkoutItems[index];
            return Container(
              margin: EdgeInsets.only(bottom: 15),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(item.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.brand,
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.verified, color: Colors.blue, size: 14),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Số lượng: ${item.quantity} x \$${item.price}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "\$${(item.price * item.quantity).toStringAsFixed(1)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildPromoCodeSection() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: promoController,
              decoration: InputDecoration(
                hintText: "Bạn có mã khuyến mãi? Nhập tại đây",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: applyDiscountCode,
            child: Text("Áp dụng"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tổng đơn hàng",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        buildSummaryRow("Tạm tính", "\$${subtotal.toStringAsFixed(1)}"),
        buildSummaryRow("Phí vận chuyển", "\$${shippingFee.toStringAsFixed(1)}"),
        buildSummaryRow("Thuế", "\$${taxFee.toStringAsFixed(1)}"),
        if (discount > 0) buildSummaryRow("Giảm giá", "-\$${discount.toStringAsFixed(1)}"),
        Divider(height: 30),
        buildSummaryRow(
          "Tổng cộng",
          "\$${orderTotal.toStringAsFixed(1)}",
          isBold: true,
        ),
      ],
    );
  }

  Widget buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.black : Colors.grey[600],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaymentMethodSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Phương thức thanh toán",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          if (isWalletLoading)
            Center(child: CircularProgressIndicator(strokeWidth: 2))
          else
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.purple),
                      SizedBox(width: 8),
                      Text("Số dư ví:"),
                    ],
                  ),
                  Text(
                    "\$${walletBalance.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: walletBalance >= orderTotal ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 15),
          InkWell(
            onTap: showPaymentMethodDialog,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        paymentMethod == "Ví điện tử"
                            ? Icons.account_balance_wallet
                            : Icons.credit_card,
                        color: paymentMethod == "Ví điện tử" ? Colors.purple : Colors.blue,
                      ),
                      SizedBox(width: 10),
                      Text(
                        paymentMethod.isEmpty
                            ? "Chọn phương thức thanh toán"
                            : paymentMethod,
                        style: TextStyle(
                          fontWeight: paymentMethod.isEmpty ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          if (paymentMethod == "Ví điện tử" && walletBalance < orderTotal)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Số dư không đủ. Vui lòng nạp thêm tiền hoặc chọn phương thức khác.",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Chọn phương thức thanh toán"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.account_balance_wallet, color: Colors.purple),
              title: Text("Ví điện tử"),
              subtitle: Text("Số dư: \$${walletBalance.toStringAsFixed(2)}"),
              enabled: walletBalance >= orderTotal,
              onTap: () {
                setState(() {
                  paymentMethod = "Ví điện tử";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blue),
              title: Text("Thẻ tín dụng/ghi nợ"),
              subtitle: Text("Thanh toán qua Stripe"),
              onTap: () {
                setState(() {
                  paymentMethod = "Stripe";
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildShippingSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thông tin giao hàng",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.location_on, color: Colors.blue),
            title: Text("Địa chỉ giao hàng"),
            subtitle: Text(shippingAddress),
            trailing: IconButton(
              icon: Icon(Icons.edit, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Cập nhật địa chỉ giao hàng"),
                    content: TextField(
                      decoration: InputDecoration(
                        hintText: "Nhập địa chỉ mới",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        shippingAddress = value;
                      },
                      controller: TextEditingController(text: shippingAddress),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Hủy"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Text("Lưu"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.phone, color: Colors.blue),
            title: Text("Số điện thoại"),
            subtitle: Text(phoneNumber),
            trailing: IconButton(
              icon: Icon(Icons.edit, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Cập nhật số điện thoại"),
                    content: TextField(
                      decoration: InputDecoration(
                        hintText: "Nhập số điện thoại mới",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        phoneNumber = value;
                      },
                      controller: TextEditingController(text: phoneNumber),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Hủy"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Text("Lưu"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCheckoutButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () async {
          if (paymentMethod == "Stripe") {
            await showStripePaymentSheet();
          } else if (paymentMethod == "Ví điện tử") {
            await processWalletPayment();
          } else {
            showPaymentMethodDialog();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A5CFF),
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
          "Thanh toán \$${orderTotal.toStringAsFixed(1)}",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}