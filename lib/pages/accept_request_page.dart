import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/page_controller.dart';

class AcceptRequestPage extends StatefulWidget {
  const AcceptRequestPage({Key? key}) : super(key: key);

  @override
  _AcceptRequestPageState createState() => _AcceptRequestPageState();
}

class _AcceptRequestPageState extends State<AcceptRequestPage> {
  double _sliderValue = 0.0;
  late SharedPreferences prefs;
  late String _action = '';
  late String _ip = '';
  late String _id;
  bool _hasRequestBeenAccepted = false;

  void _onSliderValueChange(double value) {
    setState(() {
      _sliderValue = value;
    });

    if (_sliderValue == 100.0 && !_hasRequestBeenAccepted) {
      _acceptRequest();
      _hasRequestBeenAccepted = true;
    }
  }

  void _onDragCompleted(
      int handlerIndex, double lowerValue, double upperValue) {
    if (_sliderValue != 100.0) {
      setState(() {
        _sliderValue = 0.0;
      });
    }
  }

  Future<void> _acceptRequest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerToken = prefs.getString('two_factor_secret');

    final response = await http.post(
      Uri.parse(
          'https://zealand.moedekjaer.dk/final/api/public/api/two-factor-auth-request-accept'),
      headers: {
        'Authorization': 'Bearer $bearerToken',
      },
      body: {
        'unique_id': _id,
      },
    );

    if (response.statusCode == 200) {
      PageControllerClass controllerClass = PageControllerClass();
      await prefs.remove('two_factor_request');
      controllerClass.setIndex(5);
    }
  }

  Future<void> _getJsonData() async {
    prefs = await SharedPreferences.getInstance();
    String? request = prefs.getString('two_factor_request');
    if (request != null) {
      var data = jsonDecode(request) as Map<String, dynamic>;
      var requestData = data['request'] as Map<String, dynamic>;
      String? action = requestData['action'] as String?;
      String? ip = requestData['ip_address'] as String?;
      String? id = requestData['unique_id'] as String?;
      if (action != null && ip != null && id != null && mounted) {
        setState(() {
          _action = action;
          _ip = ip;
          _id = id;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _getJsonData();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_action from $_ip',
              style:
                  const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Swipe to approve',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 40.0),
            Container(
              width: 300.0,
              height: 60.0,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: FlutterSlider(
                values: [_sliderValue],
                max: 100,
                min: 0,
                handlerAnimation: FlutterSliderHandlerAnimation(
                  curve: Curves.elasticOut,
                  reverseCurve: Curves.bounceIn,
                  duration: const Duration(milliseconds: 500),
                  scale: 1.5,
                ),
                handler: FlutterSliderHandler(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32.0,
                  ),
                ),
                trackBar: FlutterSliderTrackBar(
                  activeTrackBar: BoxDecoration(
                    color: Colors.green.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  inactiveTrackBar: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                tooltip: FlutterSliderTooltip(
                  disabled: true,
                ),
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  _onSliderValueChange(lowerValue);
                },
                onDragCompleted: (handlerIndex, lowerValue, upperValue) =>
                    _onDragCompleted(handlerIndex, lowerValue as double,
                        upperValue as double),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
