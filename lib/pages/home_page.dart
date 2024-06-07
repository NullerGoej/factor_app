import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/page_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> checkForNewRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerToken = prefs.getString('two_factor_secret');
    final response = await http.get(
      Uri.parse(
          'https://zealand.moedekjaer.dk/final/api/public/api/two-factor-auth-request-status'),
      headers: {
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode == 200) {
      PageControllerClass controllerClass = PageControllerClass();
      await prefs.setString('two_factor_request', response.body);
      controllerClass.setIndex(7, animate: false);
    } else {
      await Future.delayed(const Duration(seconds: 5));
      checkForNewRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    checkForNewRequests();
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 75.0),
            child: Text(
              'Ready to use!',
              style: TextStyle(fontSize: 28.0),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 150.0),
            child: Text(
              'You can access - when',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 80.0, vertical: 10.0),
            child: Text(
              'you are, for example, logging in to your accounts.',
              style: TextStyle(fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}