import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userData')) {
      String? jsonString = prefs.getString('userData');
      if (jsonString != null) {
        Map<String, dynamic> userData = json.decode(jsonString);
        _user = User.fromJson(userData);
        notifyListeners();
      }
    }
  }

  Future<void> _saveUserData() async {
    if (_user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('userData', json.encode(_user!.toJson()));
    }
  }

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('https://appdata.netstoic.com/expense_rpt/login.php'), // replace with your API URL
      body: {
        'username': username,
        'password': password,
      },
    );

    final responseData = json.decode(response.body);

    if (responseData['error'] != null) {
      throw Exception(responseData['error']);
    }

    _user = User.fromJson(responseData);
    _saveUserData();
    notifyListeners();
  }

  User? get user => _user;
}


// --Old Version Delete when final
// class AuthProvider with ChangeNotifier {
//   User? _user;
//
//   Future<void> login(String username, String password) async {
//     final response = await http.post(
//       Uri.parse('https://appdata.netstoic.com/expense_rpt/login.php'), // replace with your API URL
//       body: {
//         'username': username,
//         'password': password,
//       },
//     );
//
//     final responseData = json.decode(response.body);
//
//     if (responseData['error'] != null) {
//       throw Exception(responseData['error']);
//     }
//
//     // Update this line to use User.fromJson factory method
//     _user = User.fromJson(responseData);
//     notifyListeners();
//   }
//
//   User? get user => _user;
// }
// --Old Version Delete when final
// class AuthProvider with ChangeNotifier {
//   User? _user;
//
//   Future<void> login(String username, String password) async {
//     final response = await http.post(
//       Uri.parse('https://appdata.netstoic.com/expense_rpt/login.php'), // replace with your API URL
//       body: {
//         'username': username,
//         'password': password,
//       },
//     );
//
//     final responseData = json.decode(response.body);
//
//     if (responseData['error'] != null) {
//       throw Exception(responseData['error']);
//     }
//
//     _user = User(username: username, name: responseData['name'], id: '');
//     notifyListeners();
//   }
//
//   User? get user => _user;
// }