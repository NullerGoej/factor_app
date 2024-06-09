import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/page_controller.dart';

class SetupPageTwo extends StatefulWidget {
  const SetupPageTwo({Key? key}) : super(key: key);

  @override
  _SetupPageTwoState createState() => _SetupPageTwoState();
}

class _SetupPageTwoState extends State<SetupPageTwo> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  late StreamSubscription<Barcode> scanSubscription;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 1500),
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FractionallySizedBox(
            widthFactor: 1,
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Scan ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'the QR code to connect with Accessio app',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    var broadcastStream = controller.scannedDataStream.asBroadcastStream();
    scanSubscription = broadcastStream.listen((scanData) async {
      if (scanData.code != "") {
        await scanSubscription.cancel();
        try {
          var ip = await http.read(Uri.parse('https://api.ipify.org'));
          var os = UniversalPlatform.operatingSystem;
          final response = await http.post(
            Uri.parse(
                'https://accessio-api.moedekjaer.dk/two-factor-auth-verify'),
            body: {
              'qr_code': scanData.code,
              'ip_address': ip,
              'device': os,
            },
          );
          if (response.statusCode == 200) {
            PageControllerClass().setIndex(3);
            var data = jsonDecode(response.body);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('two_factor_secret', scanData.code!);
            await prefs.setString(
                'two_factor_6_digit', data['two_factor_6_digit'].toString());
          } else {
            _restartScan();
          }
        } catch (e) {
          _restartScan();
        }
      }
    });
  }

  void _restartScan() {
    scanSubscription = controller.scannedDataStream.listen((scanData) {
      // Handle new scan data
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}