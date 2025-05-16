import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopping_app/pages/product_detail.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/database.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  
  const SearchPage({Key? key, this.initialQuery}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isGridView = true;
  int _gridColumns = 2;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    
    try {
      List<Map<String, dynamic>> results = await _databaseMethods.searchProducts(query);
      
      // Sắp xếp kết quả: ưu tiên các sản phẩm có tên bắt đầu bằng từ khóa tìm kiếm
      results.sort((a, b) {
        String nameA = (a["Name"] ?? "").toString().toLowerCase();
        String nameB = (b["Name"] ?? "").toString().toLowerCase();
        String queryLower = query.toLowerCase();
        
        bool aStartsWith = nameA.startsWith(queryLower);
        bool bStartsWith = nameB.startsWith(queryLower);
        
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        return 0;
      });
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi tìm kiếm: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Tìm kiếm sản phẩm...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            // Thực hiện tìm kiếm ngay khi người dùng nhập
            if (value.isNotEmpty) {
              _performSearch(value);
            } else {
              setState(() {
                _searchResults = [];
                _hasSearched = false;
              });
            }
          },
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchResults = [];
                _hasSearched = false;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Hiển thị các bộ lọc
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Text("Sắp xếp theo: ", style: TextStyle(color: Colors.grey[700])),
                    TextButton.icon(
                      onPressed: () {
                        // Sắp xếp theo giá tăng dần
                        setState(() {
                          _searchResults.sort((a, b) {
                            double priceA = double.tryParse(a["Price"].toString()) ?? 0;
                            double priceB = double.tryParse(b["Price"].toString()) ?? 0;
                            return priceA.compareTo(priceB);
                          });
                        });
                      },
                      icon: Icon(Icons.arrow_upward, size: 16),
                      label: Text("Giá"),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Sắp xếp theo giá giảm dần
                        setState(() {
                          _searchResults.sort((a, b) {
                            double priceA = double.tryParse(a["Price"].toString()) ?? 0;
                            double priceB = double.tryParse(b["Price"].toString()) ?? 0;
                            return priceB.compareTo(priceA);
                          });
                        });
                      },
                      icon: Icon(Icons.arrow_downward, size: 16),
                      label: Text("Giá"),
                    ),
                    Spacer(),
                    // Nút chuyển đổi chế độ xem
                    IconButton(
                      icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                    ),
                  ],
                ),
                // Thêm điều khiển số cột khi ở chế độ lưới
                if (_isGridView)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Số cột: ", style: TextStyle(color: Colors.grey[700])),
                      ToggleButtons(
                        isSelected: [_gridColumns == 1, _gridColumns == 2, _gridColumns == 3],
                        onPressed: (index) {
                          setState(() {
                            _gridColumns = index + 1;
                          });
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text("1"),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text("2"),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text("3"),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Hiển thị kết quả tìm kiếm
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 80, color: Colors.grey[300]),
                            SizedBox(height: 16),
                            Text(
                              "Nhập từ khóa để tìm kiếm sản phẩm",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                                SizedBox(height: 16),
                                Text(
                                  "Không tìm thấy sản phẩm phù hợp",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : _isGridView
                            ? _buildGridView() // Hiển thị dạng lưới
                            : _buildListView(), // Hiển thị dạng danh sách
          ),
        ],
      ),
    );
  }
  
  Widget _buildGridView() {
    // Điều chỉnh tỷ lệ khung hình dựa trên số cột
    double aspectRatio;
    switch (_gridColumns) {
      case 1:
        aspectRatio = 1.5; // Tỷ lệ rộng hơn cho 1 cột
        break;
      case 3:
        aspectRatio = 0.55; // Tỷ lệ hẹp hơn cho 3 cột
        break;
      case 2:
      default:
        aspectRatio = 0.65; // Tỷ lệ mặc định cho 2 cột
        break;
    }

    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumns,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> product = _searchResults[index];
        
        // Giải mã base64 từ Firestore
        String base64Image = product["Image"] ?? "";
        Uint8List? bytes;
        try {
          bytes = base64Decode(base64Image);
        } catch (e) {
          print("Lỗi giải mã hình ảnh: $e");
        }
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetail(
                  name: product["Name"] ?? "",
                  price: product["Price"] ?? "0",
                  image: product["Image"] ?? "",
                  detail: product["Detail"] ?? "",
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hình ảnh sản phẩm - Tăng kích thước phần này
                Expanded(
                  flex: 7,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      image: bytes != null
                          ? DecorationImage(
                              image: MemoryImage(bytes),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: bytes == null
                        ? Center(child: Icon(Icons.image_not_supported))
                        : null,
                  ),
                ),
                // Thông tin sản phẩm
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product["Name"] ?? "Sản phẩm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "${product["Price"] ?? "0"}đ",
                          style: TextStyle(
                            color: Color(0xfffd6f3e),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          product["Category"] ?? "",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> product = _searchResults[index];
        
        // Giải mã base64 từ Firestore
        String base64Image = product["Image"] ?? "";
        Uint8List? bytes;
        try {
          bytes = base64Decode(base64Image);
        } catch (e) {
          print("Lỗi giải mã hình ảnh: $e");
        }
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetail(
                  name: product["Name"] ?? "",
                  price: product["Price"] ?? "0",
                  image: product["Image"] ?? "",
                  detail: product["Detail"] ?? "",
                ),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Row(
              children: [
                // Hình ảnh sản phẩm
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    image: bytes != null
                        ? DecorationImage(
                            image: MemoryImage(bytes),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: bytes == null
                      ? Center(child: Icon(Icons.image_not_supported))
                      : null,
                ),
                // Thông tin sản phẩm
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product["Name"] ?? "Sản phẩm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "${product["Price"] ?? "0"}đ",
                          style: TextStyle(
                            color: Color(0xfffd6f3e),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product["Category"] ?? "",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}



