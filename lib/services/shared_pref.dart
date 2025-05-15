import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  
  static String userIdkey = "USERKEY";
  static String userNameIdkey = "USERNAMEKEY";
  static String userEmailIdkey = "USEREMAILKEY";
  static String userImageIdkey = "USERIMAGEKEY";

  // Phương thức lưu userId
  Future<bool> saveUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdkey, userId);
  }

  // Phương thức lưu userName
  Future<bool> saveUserName(String getUserName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNameIdkey, getUserName);
  }

  // Phương thức lưu userEmail
  Future<bool> saveUserEmail(String getUserEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailIdkey, getUserEmail);
  }

  // Phương thức lưu userImage
  Future<bool> saveUserImage(String getUserImage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userImageIdkey, getUserImage);
  }

  // Phương thức lấy userId
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdkey);
  }

  // Phương thức lấy userName
  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameIdkey);
  }

  // Phương thức lấy userImage
  Future<String?> getUserImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userImageIdkey);
  }

  // Phương thức lấy userEmail
  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailIdkey);
  }
}
