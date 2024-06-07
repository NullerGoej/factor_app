import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/page_controller.dart';

class SetupPageThree extends StatefulWidget {
  const SetupPageThree({Key? key}) : super(key: key);

  @override
  _SetupPageThreeState createState() => _SetupPageThreeState();
}

class _SetupPageThreeState extends State<SetupPageThree> {
  late Timer _timer;
  String _twoFactorCode = '';
  String? _bearerToken;

  @override
  void initState() {
    super.initState();
    _loadTwoFactorCode().then((code) {
      setState(() {
        _twoFactorCode = code;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _checkTwoFactorStatus();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<String> _loadTwoFactorCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _bearerToken = prefs.getString('two_factor_secret');
    return prefs.getString('two_factor_6_digit') ?? '';
  }

  Future<void> _checkTwoFactorStatus() async {
    if (_bearerToken == null) return;

    final response = await http.get(
      Uri.parse(
          'https://zealand.moedekjaer.dk/final/api/public/api/two-factor-auth-status'),
      headers: {
        'Authorization': 'Bearer $_bearerToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['two_factor_setup'] == 2) {
        _timer.cancel();
        PageControllerClass().setIndex(4); // Move to the next page
      }
    } else {
      // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadTwoFactorCode(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error retrieving code.'));
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 75.0),
                  child: Text(
                    'Enter this code on the website!',
                    style: TextStyle(fontSize: 28.0),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  _twoFactorCode,
                  style: const TextStyle(fontSize: 24.0),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                    color: Color(0xFF77DD77), width: 5),
                                bottom: BorderSide(
                                    color: Color(0xFF77DD77), width: 5),
                              ),
                            ),
                            child: Text(
                              _twoFactorCode,
                              style: const TextStyle(
                                color: Color(0xFF77DD77),
                                fontSize: 50.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Do you need ',
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        TextSpan(
                          text: 'help?',
                          style: TextStyle(color: Color(0xFF77DD77)),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Add your onTap code here
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}