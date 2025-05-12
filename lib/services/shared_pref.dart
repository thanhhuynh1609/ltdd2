import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper{
  
  static String userIdkey="USERKEY";
  static String userNameIdkey="USERNAMEKEY";
  static String userEmailIdkey="USEREMAILKEY";
  static String userImageIdkey="USERIMAGEKEY";


  Future<bool> saveUserId(String getUserId) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdkey, getUserId);
  }
  Future<bool> saveUserName(String getUserName) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNameIdkey, getUserName);
  }
  Future<bool> saveUserEmail(String getUserEmail) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailIdkey, getUserEmail);
  }
  Future<bool> saveUserImage(String getUserImage) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userImageIdkey, getUserImage);
  }

  Future<String?> getUserId()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdkey);
  }

  Future<String?> getUserName()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameIdkey);
  }

  Future<String?> getUserImage()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userImageIdkey);
  }

  Future<String?> getUserEmail()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailIdkey);
  }

  getUserProfile() {}

}