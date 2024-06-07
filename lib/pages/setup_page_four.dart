import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/page_controller.dart';

class SetupPageFour extends StatefulWidget {
  const SetupPageFour({Key? key}) : super(key: key);

  @override
  _SetupPageFourState createState() => _SetupPageFourState();
}

class _SetupPageFourState extends State<SetupPageFour> {
  String _enteredCode = '';
  String _confirmCode = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onKeyPressed(String value) {
    setState(() {
      if (_isConfirming) {
        if (_confirmCode.length < 6) {
          _confirmCode += value;
        }
      } else {
        if (_enteredCode.length < 6) {
          _enteredCode += value;
        }
      }

      if (_enteredCode.length == 6 && !_isConfirming) {
        _isConfirming = true;
      } else if (_confirmCode.length == 6) {
        _validateAndSave();
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_isConfirming && _confirmCode.isNotEmpty) {
        _confirmCode = _confirmCode.substring(0, _confirmCode.length - 1);
      } else if (!_isConfirming && _enteredCode.isNotEmpty) {
        _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
      }
    });
  }

  Future<void> _saveCode(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_code', code);
  }

  void _validateAndSave() {
    if (_enteredCode == _confirmCode) {
      _saveCode(_enteredCode);
      // Navigate to the next page or show a success message
      PageControllerClass().setIndex(5); // Assuming next index is 4
    } else {
      setState(() {
        _errorMessage = "The codes do not match. Please try again.";
        _enteredCode = '';
        _confirmCode = '';
        _isConfirming = false;
      });
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40.0),
            Text(
              _isConfirming
                  ? 'Repeat your personal code'
                  : 'Create your personal code',
              style:
                  const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Enter your 6-digit access code',
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
                    color: _isConfirming
                        ? (_confirmCode.length > index
                            ? Colors.green
                            : Colors.grey)
                        : (_enteredCode.length > index
                            ? Colors.green
                            : Colors.grey),
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
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: () {
                setState(() {
                  _enteredCode = '';
                  _confirmCode = '';
                  _isConfirming = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}