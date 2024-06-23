import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/page_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _enteredCode = '';
  String? _errorMessage;
  String? _email;

  Future<void> _checkAccessCode(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessCode = prefs.getString('access_code');
    _email = prefs.getString('email');
    // Ensure bearer token is not null
    var _bearerToken = prefs.getString('two_factor_secret');
    if (_bearerToken == null) {
      PageControllerClass controllerClass = PageControllerClass();
      controllerClass.setIndex(1, animate: false);
      return;
    }

    final response = await http.get(
      Uri.parse('https://accessio-api.moedekjaer.dk/two-factor-auth-status'),
      headers: {
        'Authorization': 'Bearer $_bearerToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['two_factor_setup'] == 2 && accessCode == null) {
        PageControllerClass().setIndex(4); // Move to the next page
        return;
      } if (data['two_factor_setup'] == 1) {
        PageControllerClass().setIndex(3);
        return;
      }
    }

    if (accessCode == null) {
      PageControllerClass controllerClass = PageControllerClass();
      controllerClass.setIndex(1, animate: false);
      return;
    }

    // Make the HTTP request
    while (true) {
      final response = await http.get(
        Uri.parse('https://accessio-api.moedekjaer.dk/two-factor-auth-status'),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
        },
      );

      if (response.statusCode == 200) {
        // Success, break the loop
        break;
      } else if (response.statusCode == 500) {
        // Server error, try again
        continue;
      } else {
        // Other error, navigate to login page
        PageControllerClass controllerClass = PageControllerClass();
        controllerClass.setIndex(1, animate: false);
        // Remove access code and bearer token
        await prefs.remove('access_code');
        await prefs.remove('two_factor_secret');
        break;
      }
    }
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (_enteredCode.length < 6) {
        _errorMessage = null;
        _enteredCode += value;
        if (_enteredCode.length == 6) {
          _validateAndLogin();
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_enteredCode.isNotEmpty) {
        _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
      }
    });
  }

  void _validateAndLogin() async {
    if (_enteredCode.length == 6) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessCode = prefs.getString('access_code');
      if (_enteredCode == accessCode) {
        PageControllerClass controllerClass = PageControllerClass();
        controllerClass.setIndex(5);
      } else {
        setState(() {
          _errorMessage = "Please enter the right code.";
          _enteredCode = '';
        });
      }
    }
  }

  Widget _buildKey(String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyPressed(value),
        child: Container(
          margin: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF77DD77), // Green color
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return Expanded(
      child: GestureDetector(
        onTap: _onDeletePressed,
        child: Container(
          margin: const EdgeInsets.all(8.0),
          child: const Center(
            child: Icon(
              Icons.backspace,
              size: 32.0,
              color: Color(0xFF77DD77), // Green color
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
          ],
        ),
        Row(
          children: <Widget>[
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
          ],
        ),
        Row(
          children: <Widget>[
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
          ],
        ),
        Row(
          children: <Widget>[
            const Expanded(
              child: SizedBox.shrink(),
            ), // Placeholder for alignment
            _buildKey('0'),
            _buildDeleteKey(),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _checkAccessCode(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40.0),
            const Text(
              'Enter your personal code to access',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                6,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 20.0,
                  height: 20.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _enteredCode.length > index
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20.0),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }
}
