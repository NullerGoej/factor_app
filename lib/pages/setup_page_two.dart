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
  Barcode? result;
  late QRViewController controller;
  late StreamSubscription<Barcode> scanSubscription;
  double _opacity = 0.0;
  bool isSetupReady = true;

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
  void reassemble() {
    super.reassemble();
    controller.pauseCamera();
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: const Color(0xFF77DD77),
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        //Expanded(flex: 4, child: _buildQrView(context)),
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
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        if (result != scanData) {
          result = scanData;
          onResultChanged();
        }
      });
    });
  }

  void onResultChanged() async {
    if (!isSetupReady) {
      return;
    }

    if (result?.code != "") {
      isSetupReady = false;
      try {
        var ip = await http.read(Uri.parse('https://api.ipify.org'));
        var os = UniversalPlatform.operatingSystem;
        final response = await http.post(
          Uri.parse(
              'https://accessio-api.moedekjaer.dk/two-factor-auth-verify'),
          body: {
            'qr_code': result?.code,
            'ip_address': ip,
            'device': os,
          },
        );
        if (response.statusCode == 200) {
          PageControllerClass().setIndex(3);
          var data = jsonDecode(response.body);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', data['email'].toString());
          await prefs.setString('two_factor_secret', result?.code as String);
          await prefs.setString(
              'two_factor_6_digit', data['two_factor_6_digit'].toString());
        }
      } catch (e) {
        print(e);
      }
      isSetupReady = true;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
