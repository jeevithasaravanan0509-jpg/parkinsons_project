import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class StorageService {


  // Save any data
  static Future<void> saveData(
      String key, dynamic value) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      key,
      jsonEncode(value),
    );

  }



  // Get saved data
  static Future<dynamic> getData(
      String key) async {

    final prefs = await SharedPreferences.getInstance();


    String? data = prefs.getString(key);


    if (data != null) {

      return jsonDecode(data);

    }


    return null;

  }



  // Remove data
  static Future<void> deleteData(
      String key) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(key);

  }

}