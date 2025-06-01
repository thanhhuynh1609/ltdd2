import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'package:shopping_app/pages/topup_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool isLoading = true;
  double walletBalance = 0.0;
  String userId = "";
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  // Khởi tạo dữ liệu ví
  Future<void> initData() async {
    try {
      // Lấy userId từ SharedPreferences
      userId = await SharedPreferenceHelper().getUserId() ?? "";
      print("Đã lấy userId: $userId");
      
      // Kiểm tra userId có hợp lệ không
      if (userId.isEmpty) {
        print("userId không hợp lệ");
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Tải dữ liệu ví và giao dịch
      await loadWalletData();
      await loadTransactions();
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error initializing wallet data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Tải dữ liệu ví
  Future<void> loadWalletData() async {
    try {
      Map<String, dynamic>? walletData = await DatabaseMethods().getUserWallet(userId);
      if (walletData != null) {
        setState(() {
          walletBalance = (walletData['balance'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      print("Error loading wallet data: $e");
    }
  }

  // Tải lịch sử giao dịch
  Future<void> loadTransactions() async {
    try {
      print("Đang tải lịch sử giao dịch cho userId: $userId");
      
      // Đảm bảo userId không rỗng
      if (userId.isEmpty) {
        print("userId rỗng, không thể tải giao dịch");
        return;
      }
      
      // Truy vấn trực tiếp từ Firestore - chỉ sử dụng where mà không orderBy để tránh lỗi index
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("wallet_transactions")
          .where("userId", isEqualTo: userId)
          .get();
      
      print("Số lượng giao dịch tìm thấy: ${snapshot.docs.length}");
      
      // Kiểm tra xem có dữ liệu không
      if (snapshot.docs.isEmpty) {
        print("Không tìm thấy giao dịch nào cho userId: $userId");
        setState(() {
          transactions = [];
        });
        return;
      }
      
      // Chuyển đổi dữ liệu từ QuerySnapshot sang List<Map>
      List<Map<String, dynamic>> loadedTransactions = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Thêm id vào dữ liệu
        data['id'] = doc.id;
        print("Giao dịch: ${data.toString()}");
        loadedTransactions.add(data);
      }
      
      // Sắp xếp theo thời gian trong ứng dụng thay vì trong truy vấn
      loadedTransactions.sort((a, b) {
        if (a['timestamp'] == null || b['timestamp'] == null) return 0;
        Timestamp aTime = a['timestamp'] as Timestamp;
        Timestamp bTime = b['timestamp'] as Timestamp;
        return bTime.compareTo(aTime); // Sắp xếp giảm dần (mới nhất lên đầu)
      });
      
      setState(() {
        transactions = loadedTransactions;
      });
    } catch (e) {
      print("Error loading transactions: $e");
      setState(() {
        transactions = [];
      });
    }
  }

  // Phương thức kiểm tra trực tiếp dữ liệu từ Firebase
  Future<void> checkFirebaseData() async {
    try {
      print("Kiểm tra dữ liệu Firebase cho userId: $userId");
      
      // Kiểm tra collection wallet_transactions
      QuerySnapshot transactionsSnapshot = await FirebaseFirestore.instance
          .collection("wallet_transactions")
          .get();
      
      print("Tổng số giao dịch trong hệ thống: ${transactionsSnapshot.docs.length}");
      
      // In ra tất cả giao dịch
      for (var doc in transactionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print("Giao dịch ID: ${doc.id}, Data: ${data.toString()}");
      }
      
      // In ra tất cả userId trong collection wallet_transactions
      Set<String> userIds = {};
      for (var doc in transactionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('userId')) {
          userIds.add(data['userId'].toString());
        }
      }
      
      print("Danh sách userId trong wallet_transactions: $userIds");
      
      // Kiểm tra xem userId hiện tại có trong danh sách không
      if (userIds.contains(userId)) {
        print("userId hiện tại có trong danh sách");
      } else {
        print("userId hiện tại KHÔNG có trong danh sách");
      }
      
      // Tải lại dữ liệu
      await loadTransactions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã kiểm tra dữ liệu Firebase, xem log để biết chi tiết")),
      );
    } catch (e) {
      print("Error checking Firebase data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4A5CFF),
        elevation: 0,
        title: Text(
          "Ví của tôi",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Thêm nút kiểm tra dữ liệu
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.white),
            onPressed: checkFirebaseData,
          ),
          // Nút làm mới
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              initData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đang làm mới dữ liệu...")),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await initData();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần hiển thị số dư
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A5CFF),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Số dư hiện tại",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "\$${walletBalance.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              // Chuyển đến trang nạp tiền
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TopupPage(userId: userId),
                                ),
                              );
                              
                              // Nếu có thay đổi (nạp tiền thành công), cập nhật lại dữ liệu
                              if (result == true) {
                                await initData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF4A5CFF),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              "Nạp tiền",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Phần lịch sử giao dịch
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Lịch sử giao dịch",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (transactions.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    // Có thể thêm trang xem tất cả giao dịch ở đây
                                  },
                                  child: Text(
                                    "Xem tất cả",
                                    style: TextStyle(
                                      color: Color(0xFF4A5CFF),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 10),
                          
                          // Hiển thị thông tin debug về userId
                          // Container(
                          //   padding: EdgeInsets.all(8),
                          //   margin: EdgeInsets.only(bottom: 10),
                          //   decoration: BoxDecoration(
                          //     color: Colors.grey.shade100,
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          //   child: Text("User ID: $userId"),
                          // ),
                          
                          transactions.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 30),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 60,
                                          color: Colors.grey.shade400,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Chưa có giao dịch nào",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Hãy nạp tiền để bắt đầu sử dụng ví",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TopupPage(userId: userId),
                                              ),
                                            );
                                            
                                            if (result == true) {
                                              await initData();
                                            }
                                          },
                                          icon: Icon(Icons.add),
                                          label: Text("Nạp tiền ngay", style: TextStyle(color: Colors.white),),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF4A5CFF),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: transactions.length,
                                  itemBuilder: (context, index) {
                                    Map<String, dynamic> transaction = transactions[index];
                                    String transactionType = transaction['type'] ?? '';
                                    
                                    // Xác định loại giao dịch và hiển thị tương ứng
                                    bool isIncoming = transactionType == 'topup' || transactionType == 'refund';
                                    String transactionTitle = '';
                                    
                                    if (transactionType == 'topup') {
                                      transactionTitle = "Nạp tiền";
                                    } else if (transactionType == 'payment') {
                                      transactionTitle = "Thanh toán";
                                    } else if (transactionType == 'refund') {
                                      transactionTitle = "Hoàn tiền"; // Thêm loại giao dịch hoàn tiền
                                    } else {
                                      transactionTitle = "Giao dịch";
                                    }
                                    
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 10),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isIncoming
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isIncoming
                                                ? Icons.add
                                                : Icons.remove,
                                            color: isIncoming
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        title: Text(
                                          transactionTitle,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          transaction['method'] ?? transaction['description'] ?? "",
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        trailing: Text(
                                          "${isIncoming ? '+' : '-'}\$${transaction['amount'].toString()}",
                                          style: TextStyle(
                                            color: isIncoming
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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





