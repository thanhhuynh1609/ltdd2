import 'package:flutter/material.dart';
import 'package:shopping_app/pages/chat_page.dart';
import 'package:shopping_app/services/chat_service.dart';
import 'package:shopping_app/services/shared_pref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopping_app/pages/login.dart';
import 'package:shopping_app/pages/wallet_page.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? image, name, email, phone;
  bool isLoading = true;
  String userId = "";

  getthesharedpref() async {
    setState(() {
      isLoading = true;
    });

    image = await SharedPreferenceHelper().getUserImage();
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    phone = await SharedPreferenceHelper().getUserPhone();
    userId = await SharedPreferenceHelper().getUserId() ?? "";

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getthesharedpref();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Đăng xuất"),
        content: Text("Bạn có chắc chắn muốn đăng xuất?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              await SharedPreferenceHelper().clearUserData();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Login()),
                (route) => false,
              );
            },
            child: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xóa tài khoản"),
        content: Text(
          "Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác và tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                setState(() {
                  isLoading = true;
                });

                // Lấy user hiện tại
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  String userId = user.uid;

                  // Đánh dấu tài khoản đã xóa trong Firestore
                  await FirebaseFirestore.instance
                      .collection("deleted_users")
                      .doc(userId)
                      .set({
                    "email": user.email,
                    "deletedAt": FieldValue.serverTimestamp(),
                  });

                  // Xóa dữ liệu người dùng từ Firestore
                  await FirebaseFirestore.instance
                      .collection("user")
                      .doc(userId)
                      .delete();

                  // Xóa tài khoản Firebase Auth
                  await user.delete();

                  // Xóa dữ liệu local
                  await SharedPreferenceHelper().clearUserData();

                  // Chuyển về trang đăng nhập
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
                  );
                }
              } catch (e) {
                setState(() {
                  isLoading = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Lỗi khi xóa tài khoản: $e"),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: Text("Xóa tài khoản", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          name: name ?? "",
          email: email ?? "",
          phone: phone ?? "",
          image: image,
        ),
      ),
    ).then((_) => getthesharedpref());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF4A5CFF),
        elevation: 0,
        title: Text(
          "Tài khoản",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user info
                  Container(
                    padding: EdgeInsets.only(bottom: 20),
                    color: Color(0xFF4A5CFF),
                    child: Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: image != null && image!.isNotEmpty
                                ? NetworkImage(image!)
                                : AssetImage('images/user.png') as ImageProvider,
                          ),
                          SizedBox(height: 10),
                          Text(
                            name ?? "Người dùng",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            email ?? "",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Account Settings Section
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cài đặt tài khoản",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Address List
                        SettingItem(
                          icon: Icons.location_on_outlined,
                          title: "Địa chỉ giao hàng",
                          subtitle: "Quản lý địa chỉ giao hàng của bạn",
                          onTap: () {
                            // Navigate to address management
                          },
                        ),

                        // Payment Methods
                        SettingItem(
                          icon: Icons.payment_outlined,
                          title: "Phương thức thanh toán",
                          subtitle: "Quản lý thẻ và phương thức thanh toán",
                          onTap: () {
                            // Navigate to payment methods
                          },
                        ),

                        // Wallet
                        SettingItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: "Ví của tôi",
                          subtitle: "Quản lý và nạp tiền vào ví",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => WalletPage()),
                            );
                          },
                        ),

                        // Bank Account
                        SettingItem(
                          icon: Icons.account_balance_outlined,
                          title: "Tài khoản ngân hàng",
                          subtitle: "Quản lý tài khoản ngân hàng liên kết",
                          onTap: () {
                            // Navigate to bank accounts
                          },
                        ),

                        // Edit Profile
                        SettingItem(
                          icon: Icons.person_outline,
                          title: "Thông tin cá nhân",
                          subtitle: "Chỉnh sửa thông tin cá nhân của bạn",
                          onTap: _navigateToEditProfile,
                        ),

                        // Account Security
                        SettingItem(
                          icon: Icons.security_outlined,
                          title: "Bảo mật tài khoản",
                          subtitle: "Thay đổi mật khẩu và bảo mật",
                          onTap: () {
                            // Navigate to security settings
                          },
                        ),
                        StreamBuilder<int>(
  stream: ChatService.getUnreadCount(userId, false),
  builder: (context, snapshot) {
    int unreadCount = snapshot.data ?? 0;

    return SettingItem(
      icon: Icons.chat,
      title: "Chat với Admin",
      subtitle: "Nhắn tin trao đổi với admin",
      badgeCount: unreadCount,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatPage()),
        );
      },
    );
  },
),


                        // Chat with Admin
                        // StreamBuilder<int>(
                        //   stream: ChatService.getUnreadCount(userId, false),
                        //   builder: (context, snapshot) {
                        //     int unreadCount = snapshot.data ?? 0;
                            
                        //     return ListTile(
                        //       leading: Container(
                        //         padding: EdgeInsets.all(10),
                        //         decoration: BoxDecoration(
                        //           color: Colors.blue.withOpacity(0.1),
                        //           borderRadius: BorderRadius.circular(10),
                        //         ),
                        //         child: Icon(
                        //           Icons.chat,
                        //           color: const Color.fromARGB(255, 86, 42, 233),
                        //           size: 25,
                        //         ),
                        //       ),
                        //       title: Text(
                        //         "Chat với Admin",
                        //         style: TextStyle(
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.w500,
                        //         ),
                        //       ),
                        //       trailing: Row(
                        //         mainAxisSize: MainAxisSize.min,
                        //         children: [
                        //           if (unreadCount > 0)
                        //             Container(
                        //               padding: EdgeInsets.all(6),
                        //               decoration: BoxDecoration(
                        //                 color: Colors.red,
                        //                 shape: BoxShape.circle,
                        //               ),
                        //               child: Text(
                        //                 unreadCount.toString(),
                        //                 style: TextStyle(
                        //                   color: Colors.white,
                        //                   fontSize: 12,
                        //                   fontWeight: FontWeight.bold,
                        //                 ),
                        //               ),
                        //             ),
                        //           SizedBox(width: 8),
                        //           Icon(
                        //             Icons.arrow_forward_ios,
                        //             size: 18,
                        //           ),
                        //         ],
                        //       ),
                        //       onTap: () {
                        //         Navigator.push(
                        //           context,
                        //           MaterialPageRoute(builder: (context) => ChatPage()),
                        //         );
                        //       },
                        //     );
                        //   },
                        // ),

                        SizedBox(height: 24),

                        // App Settings Section
                        Text(
                          "Cài đặt ứng dụng",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Notifications
                        SettingItem(
                          icon: Icons.notifications_outlined,
                          title: "Thông báo",
                          subtitle: "Quản lý thông báo từ ứng dụng",
                          onTap: () {
                            // Navigate to notification settings
                          },
                        ),

                        // Dark Mode
                        SettingItemSwitch(
                          icon: Icons.dark_mode_outlined,
                          title: "Chế độ tối",
                          subtitle: "Bật/tắt chế độ tối",
                          value: false,
                          onChanged: (value) {
                            // Toggle dark mode
                          },
                        ),

                        SizedBox(height: 24),

                        // Logout Button
                        ActionButton(
                          icon: Icons.logout,
                          label: "Đăng xuất",
                          onTap: _showLogoutConfirmation,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 12),

                        // Delete Account Button
                        ActionButton(
                          icon: Icons.delete_outline,
                          label: "Xóa tài khoản",
                          onTap: _showDeleteAccountConfirmation,
                          color: Colors.red,
                        ),

                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Widget for Setting Items
// class SettingItem extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;

//   const SettingItem({
//     Key? key,
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 12.0),
//         child: Row(
//           children: [
//             Container(
//               padding: EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(icon, color: Color(0xFF4A5CFF), size: 24),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }
// }


class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? badgeCount; // thêm biến này

  const SettingItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Color(0xFF4A5CFF), size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Badge nếu có
            if (badgeCount != null && badgeCount! > 0)
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (badgeCount != null && badgeCount! > 0)
              SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}


// Widget for Setting Items with Switch
class SettingItemSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const SettingItemSwitch({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFF4A5CFF), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF4A5CFF),
          ),
        ],
      ),
    );
  }
}

// Widget for Action Buttons
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String? image;

  const EditProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.phone,
    this.image,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool isLoading = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _imageUrl = widget.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Vui lòng nhập tên của bạn"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Lấy user hiện tại
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cập nhật thông tin trong Firestore
        await FirebaseFirestore.instance
            .collection("user")
            .doc(user.uid)
            .update({
          "Name": _nameController.text.trim(),
          "Phone": _phoneController.text.trim(),
        });

        // Cập nhật SharedPreferences
        await SharedPreferenceHelper()
            .saveUserName(_nameController.text.trim());
        await SharedPreferenceHelper()
            .saveUserPhone(_phoneController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Thông tin đã được cập nhật thành công"),
          backgroundColor: Colors.green,
        ));

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi khi cập nhật thông tin: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Chỉnh sửa thông tin",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Image
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _imageUrl != null &&
                                  _imageUrl!.isNotEmpty
                              ? NetworkImage(_imageUrl!)
                              : AssetImage('images/user.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFF4A5CFF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Profile Information Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Thông tin cá nhân",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Name Field
                        ProfileTextField(
                          label: "Họ và tên",
                          controller: _nameController,
                          icon: Icons.person_outline,
                        ),
                        SizedBox(height: 16),

                        // Email Field (Disabled)
                        ProfileTextField(
                          label: "Email",
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),
                        SizedBox(height: 16),

                        // Phone Field
                        ProfileTextField(
                          label: "Số điện thoại",
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4A5CFF),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Lưu thay đổi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Profile Text Field
class ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final TextInputType keyboardType;

  const ProfileTextField({
    Key? key,
    required this.label,
    required this.controller,
    required this.icon,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF4A5CFF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF4A5CFF)),
            ),
          ),
          enabled: enabled,
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}
