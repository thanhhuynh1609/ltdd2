import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/notification_service.dart';

class RefundRequestsPage extends StatefulWidget {
  @override
  _RefundRequestsPageState createState() => _RefundRequestsPageState();
}

class _RefundRequestsPageState extends State<RefundRequestsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> refundRequests = [];
  String selectedFilter = 'Tất cả';
  
  @override
  void initState() {
    super.initState();
    loadRefundRequests();
  }
  
  Future<void> loadRefundRequests() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      List<Map<String, dynamic>> requests = await DatabaseMethods().getAllRefundRequests();
      
      setState(() {
        refundRequests = requests;
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi tải yêu cầu hoàn tiền: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
  
  List<Map<String, dynamic>> getFilteredRequests() {
    if (selectedFilter == 'Tất cả') {
      return refundRequests;
    } else {
      String status = '';
      switch (selectedFilter) {
        case 'Đang chờ':
          status = 'pending';
          break;
        case 'Đã chấp nhận':
          status = 'approved';
          break;
        case 'Đã từ chối':
          status = 'rejected';
          break;
      }
      return refundRequests.where((request) => request['status'] == status).toList();
    }
  }
  
  Future<void> processRefund(Map<String, dynamic> request, String action) async {
    try {
      setState(() {
        isLoading = true;
      });
      
      String refundId = request['id'];
      String orderId = request['orderId'];
      String userId = request['userId'];
      double amount = (request['amount'] ?? 0.0).toDouble();
      
      // Lấy orderNumber từ request
      String orderNumber = request['orderDetails']?['orderNumber'] ?? "";
      
      if (action == 'approve') {
        // Cập nhật trạng thái yêu cầu hoàn tiền
        await FirebaseFirestore.instance
            .collection("refund_requests")
            .doc(refundId)
            .update({
          'status': 'approved',
          'processDate': FieldValue.serverTimestamp(),
        });
        
        // Cập nhật trạng thái đơn hàng thành "Đã hủy"
        await FirebaseFirestore.instance
            .collection("Orders")
            .doc(orderId)
            .update({
          'Status': 'Đã hủy',  // Thay đổi từ 'Refunded' thành 'Đã hủy'
          'RefundStatus': 'approved',
          'RefundDate': FieldValue.serverTimestamp(),
        });
        
        // Hoàn tiền vào ví người dùng
        bool refundSuccess = await DatabaseMethods().processRefund(
          userId,
          amount,
          orderId,
        );

        if (refundSuccess) {
          // Tạo thông báo
          await NotificationService.createNotification(
            userId: userId,
            title: "Hoàn tiền thành công",
            message: "Yêu cầu hoàn tiền cho đơn hàng #$orderNumber đã được chấp nhận. \$${amount.toStringAsFixed(2)} đã được hoàn vào ví của bạn.",
            type: "refund_approved",
            orderId: orderId,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã chấp nhận yêu cầu và hoàn tiền vào ví người dùng"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã chấp nhận yêu cầu nhưng có lỗi khi hoàn tiền"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Từ chối yêu cầu
        // Tạo thông báo
        await NotificationService.createNotification(
          userId: userId,
          title: "Yêu cầu hoàn tiền bị từ chối",
          message: "Yêu cầu hoàn tiền cho đơn hàng #$orderNumber đã bị từ chối.",
          type: "refund_rejected",
          orderId: orderId,
        );

        // Cập nhật trạng thái yêu cầu hoàn tiền
        await FirebaseFirestore.instance
            .collection("refund_requests")
            .doc(refundId)
            .update({
          'status': 'rejected',
          'processDate': FieldValue.serverTimestamp(),
        });
        
        // Cập nhật trạng thái đơn hàng
        await FirebaseFirestore.instance
            .collection("Orders")
            .doc(orderId)
            .update({
          'RefundStatus': 'rejected',
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã từ chối yêu cầu hoàn tiền"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      // Tải lại danh sách
      await loadRefundRequests();
    } catch (e) {
      print("Lỗi khi xử lý yêu cầu hoàn tiền: $e");
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void showRefundDetailsDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Chi tiết yêu cầu hoàn tiền"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildInfoRow("Mã đơn hàng", request['orderDetails']?['orderNumber'] ?? ""),
              buildInfoRow("Số tiền", "\$${request['amount']?.toString() ?? '0'}"),
              buildInfoRow("Trạng thái", getStatusText(request['status'] ?? "")),
              buildInfoRow("Ngày yêu cầu", formatTimestamp(request['requestDate'])),
              buildInfoRow("Ngày xử lý", formatTimestamp(request['processDate'])),
              Divider(),
              Text(
                "Lý do hoàn tiền:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(request['reason'] ?? ""),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Đóng"),
          ),
          if (request['status'] == 'pending')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    processRefund(request, 'reject');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Từ chối"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    processRefund(request, 'approve');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("Chấp nhận"),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
    
    return "N/A";
  }
  
  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ xử lý';
      case 'approved':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Không xác định';
    }
  }
  
  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRequests = getFilteredRequests();
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý hoàn tiền"),
        backgroundColor: Color(0xFF4A5CFF),
      ),
      body: Column(
        children: [
          // Bộ lọc
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lọc theo trạng thái:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildFilterChip('Tất cả'),
                      buildFilterChip('Đang chờ'),
                      buildFilterChip('Đã chấp nhận'),
                      buildFilterChip('Đã từ chối'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Nút làm mới
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: loadRefundRequests,
              icon: Icon(Icons.refresh),
              label: Text("Làm mới"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A5CFF),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40),
              ),
            ),
          ),
          
          // Danh sách yêu cầu
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_empty, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "Không có yêu cầu hoàn tiền nào",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredRequests.length,
                        padding: EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          Map<String, dynamic> request = filteredRequests[index];
                          String status = request['status'] ?? 'pending';
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => showRefundDetailsDialog(request),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Đơn hàng #${request['orderDetails']?['orderNumber']?.toString().substring(0, 8) ?? ''}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(status).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            getStatusText(status),
                                            style: TextStyle(
                                              color: getStatusColor(status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          "ID: ${request['userId']?.toString().substring(0, 10)}...",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          formatTimestamp(request['requestDate']),
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Số tiền hoàn:",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "\$${request['amount']?.toString() ?? '0'}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A5CFF),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Hiển thị nút xử lý nếu đang chờ
                                    if (status == 'pending')
                                      Padding(
                                        padding: EdgeInsets.only(top: 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => processRefund(request, 'reject'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: BorderSide(color: Colors.red),
                                                ),
                                                child: Text("Từ chối"),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => processRefund(request, 'approve'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                child: Text("Chấp nhận"),
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
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              selectedFilter = label;
            });
          }
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Color(0xFF4A5CFF).withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? Color(0xFF4A5CFF) : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


