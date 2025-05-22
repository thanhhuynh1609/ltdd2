// lib/Admin/manage_discount_codes.dart
import 'package:flutter/material.dart';
import '../services/database.dart';
import '../models/discount_code.dart';

class ManageDiscountCodes extends StatefulWidget {
  @override
  _ManageDiscountCodesState createState() => _ManageDiscountCodesState();
}

class _ManageDiscountCodesState extends State<ManageDiscountCodes> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  List<DiscountCode> discountCodes = [];

  @override
  void initState() {
    super.initState();
    _loadDiscountCodes();
  }

  Future<void> _loadDiscountCodes() async {
    try {
      List<DiscountCode> codes = await _databaseMethods.getDiscountCodes();
      setState(() {
        discountCodes = codes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tải danh sách mã giảm giá')));
    }
  }

  Future<void> _deleteDiscountCode(String id) async {
    try {
      await _databaseMethods.deleteDiscountCode(id);
      _loadDiscountCodes();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa mã giảm giá thành công')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa mã giảm giá')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý mã giảm giá'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditDiscountCodePage()),
              ).then((_) => _loadDiscountCodes());
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: discountCodes.length,
        itemBuilder: (context, index) {
          final code = discountCodes[index];
          return ListTile(
            title: Text(code.code),
            subtitle: Text('Giảm: \$${code.discountAmount} | Hoạt động: ${code.isActive ? 'Có' : 'Không'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditDiscountCodePage(discountCode: code)),
                    ).then((_) => _loadDiscountCodes());
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteDiscountCode(code.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddEditDiscountCodePage extends StatefulWidget {
  final DiscountCode? discountCode;

  AddEditDiscountCodePage({this.discountCode});

  @override
  _AddEditDiscountCodePageState createState() => _AddEditDiscountCodePageState();
}

class _AddEditDiscountCodePageState extends State<AddEditDiscountCodePage> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _discountAmountController;
  late TextEditingController _minOrderAmountController;
  late bool _isActive;
  DateTime? _startDate; // Thêm biến cho ngày bắt đầu
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.discountCode?.code ?? '');
    _discountAmountController = TextEditingController(text: widget.discountCode?.discountAmount.toString() ?? '');
    _minOrderAmountController = TextEditingController(text: widget.discountCode?.minOrderAmount?.toString() ?? '');
    _isActive = widget.discountCode?.isActive ?? true;
    _startDate = widget.discountCode?.startDate;
    _expiryDate = widget.discountCode?.expiryDate;
  }

  Future<void> _saveDiscountCode() async {
    if (_formKey.currentState!.validate()) {
      try {
        DiscountCode discountCode = DiscountCode(
          id: widget.discountCode?.id ?? '',
          code: _codeController.text,
          discountAmount: double.parse(_discountAmountController.text),
          isActive: _isActive,
          createdAt: widget.discountCode?.createdAt ?? DateTime.now(),
          startDate: _startDate, // Lưu ngày bắt đầu
          expiryDate: _expiryDate,
          minOrderAmount: _minOrderAmountController.text.isNotEmpty ? double.parse(_minOrderAmountController.text) : null,
          usageCount: widget.discountCode?.usageCount ?? 0,
        );

        if (widget.discountCode == null) {
          await _databaseMethods.addDiscountCode(discountCode);
        } else {
          await _databaseMethods.updateDiscountCode(discountCode);
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu mã giảm giá')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.discountCode == null ? 'Thêm mã giảm giá' : 'Sửa mã giảm giá')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Mã giảm giá'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập mã giảm giá' : null,
              ),
              TextFormField(
                controller: _discountAmountController,
                decoration: InputDecoration(labelText: 'Số tiền giảm'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập số tiền giảm' : null,
              ),
              TextFormField(
                controller: _minOrderAmountController,
                decoration: InputDecoration(labelText: 'Số tiền tối thiểu (tùy chọn)'),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: Text('Hoạt động'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              ListTile(
                title: Text(_startDate == null ? 'Chọn ngày bắt đầu' : 'Bắt đầu: ${_startDate.toString()}'),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(_expiryDate == null ? 'Chọn ngày hết hạn' : 'Hết hạn: ${_expiryDate.toString()}'),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _expiryDate = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveDiscountCode,
                child: Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}