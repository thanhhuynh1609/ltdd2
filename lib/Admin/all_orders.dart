import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/pages/widget/support_widget.dart';

class AllOrders extends StatefulWidget {
  const AllOrders({Key? key}) : super(key: key);

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String selectedStatus = "Tất cả";

  @override
  void initState() {
    getOrders();
    super.initState();
  }

  getOrders() async {
    try {
      // Lấy dữ liệu từ Firestore một lần thay vì dùng stream
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Orders")
          .get();

      // Chuyển đổi dữ liệu từ QuerySnapshot sang List<Map>
      orders = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Thêm id vào dữ liệu
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sắp xếp theo ID thay vì thời gian
      orders.sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Lọc đơn hàng theo trạng thái
  List<Map<String, dynamic>> getFilteredOrders() {
    if (selectedStatus == "Tất cả") {
      return orders;
    } else {
      return orders.where((order) => order['Status'] == selectedStatus).toList();
    }
  }

  void showStatusUpdateDialog(Map<String, dynamic> order) {
    String currentStatus = order['Status'] ?? "Đang xử lý";
    String selectedStatus = currentStatus;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Cập nhật trạng thái đơn hàng"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Chọn trạng thái mới:"),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: [
                      "Đang xử lý",
                      "Đang giao hàng",
                      "Đã giao hàng",
                      "Đã hủy"
                    ].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                // Thêm nút xóa đơn hàng
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    deleteOrder(order['id']);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text("Xóa đơn hàng"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Cập nhật trạng thái đơn hàng
                      await FirebaseFirestore.instance
                          .collection("Orders")
                          .doc(order['id'])
                          .update({"Status": selectedStatus});
                      
                      // Cập nhật trạng thái trong danh sách local
                      setState(() {
                        int index = orders.indexWhere((o) => o['id'] == order['id']);
                        if (index != -1) {
                          orders[index]['Status'] = selectedStatus;
                        }
                      });
                      
                      Navigator.pop(context);
                      
                      // Hiển thị thông báo thành công
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đã cập nhật trạng thái đơn hàng"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Refresh UI
                      this.setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Lỗi: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xfffd6f3e),
                  ),
                  child: Text("Cập nhật"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Thêm phương thức xóa đơn hàng
  void deleteOrder(String orderId) async {
    try {
      // Hiển thị dialog xác nhận
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có chắc chắn muốn xóa đơn hàng này?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Xóa", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (!confirmDelete) return;

      // Xóa đơn hàng từ Firestore
      await FirebaseFirestore.instance
          .collection("Orders")
          .doc(orderId)
          .delete();
      
      // Cập nhật danh sách đơn hàng local
      setState(() {
        orders.removeWhere((order) => order['id'] == orderId);
      });
      
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã xóa đơn hàng thành công"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error deleting order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi xóa đơn hàng: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      appBar: AppBar(
        backgroundColor: Color(0xfff2f2f2),
        title: Text(
          'Quản lý đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bộ lọc trạng thái
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        "Lọc theo trạng thái: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: [
                              "Tất cả",
                              "Đang xử lý",
                              "Đang giao hàng",
                              "Đã giao hàng",
                              "Đã hủy"
                            ].map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Nút làm mới
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                      getOrders();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text(""),
                    style: ElevatedButton.styleFrom(
                    
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                ),
                // Danh sách đơn hàng
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: buildOrdersList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildOrdersList() {
    List<Map<String, dynamic>> filteredOrders = getFilteredOrders();
    
    if (filteredOrders.isEmpty) {
      return Center(
        child: Text(
          selectedStatus == "Tất cả" 
              ? "Không có đơn hàng nào" 
              : "Không có đơn hàng nào với trạng thái '$selectedStatus'",
          style: AppWidget.semiboldTextFeildStyle(),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> order = filteredOrders[index];
        
        // Lấy thông tin đơn hàng
        String status = order['Status'] ?? "Đang xử lý";
        String customerName = order['CustomerName'] ?? "Khách hàng";
        String customerEmail = order['CustomerEmail'] ?? "";
        String totalAmount = order['TotalAmount'] ?? "0";
        
        // Lấy danh sách sản phẩm
        List<dynamic> products = order['Products'] ?? [];
        
        // Nếu không có sản phẩm, bỏ qua đơn hàng này
        if (products.isEmpty) {
          return SizedBox();
        }
        
        // Lấy thông tin sản phẩm đầu tiên để hiển thị
        var firstProduct = products.first;
        String productName = firstProduct['Name'] ?? "Sản phẩm";

        return GestureDetector(
          onTap: () {
            // Hiển thị dialog cập nhật trạng thái
            showStatusUpdateDialog(order);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hiển thị icon thay vì ảnh
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: Icon(
                            Icons.shopping_bag,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                        ),
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                "Mã đơn: #${order['id'].toString().substring(0, 8)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Tên: " + customerName,
                                style: AppWidget.semiboldTextFeildStyle(),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width/3,
                                child: Text(
                                  "Email: " + customerEmail,
                                  style: AppWidget.lightTextFeildStyle(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                productName + (products.length > 1 ? " + ${products.length - 1} sản phẩm khác" : ""),
                                style: AppWidget.semiboldTextFeildStyle(),
                              ),
                              Text(
                                "\$$totalAmount",
                                style: TextStyle(
                                  color: Color(0xfffd6f3e),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10), 
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      showStatusUpdateDialog(order);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(status),
                                        borderRadius: BorderRadius.circular(10)
                                      ),
                                      child: Center(
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  // Thêm nút xóa trực tiếp
                                  GestureDetector(
                                    onTap: () {
                                      deleteOrder(order['id']);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10)
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Xóa",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Hàm trả về màu dựa trên trạng thái
  Color getStatusColor(String status) {
    switch (status) {
      case "Đã giao hàng":
        return Colors.green;
      case "Đang giao hàng":
        return Colors.blue;
      case "Đã hủy":
        return Colors.red;
      default:
        return Color(0xfffd6f3e); // Đang xử lý
    }
  }
}
