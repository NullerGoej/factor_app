import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var prefs = await SharedPreferences.getInstance();
  runApp(MainApp(prefs: prefs));
}

class MainApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MainApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      home: MainPage(prefs: prefs),
    );
  }
}

class PageControllerClass {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<Widget> _children;

  static final PageControllerClass _instance = PageControllerClass._internal();

  factory PageControllerClass() {
    return _instance;
  }

  PageControllerClass._internal() {
    _children = [
      LoginPage(),
      SetupPageOne(),
      SetupPageTwo(),
      SetupPageThree(),
      SetupPageFour(),
      HomePage(),
    ];
    _pageController = PageController();
  }

  int get currentIndex => _currentIndex;
  PageController get pageController => _pageController;
  List<Widget> get children => _children;

  void setIndex(int index, {bool animate = true}) {
    _currentIndex = index;
    _pageController.jumpToPage(index);
  }
}

class MainPage extends StatefulWidget {
  final SharedPreferences prefs;

  const MainPage({Key? key, required this.prefs}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    PageControllerClass controllerClass = PageControllerClass();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: const Color(0xFF77DD77),
          title: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: SizedBox(
              height: 60.0,
              child: Image.asset('logo.png', fit: BoxFit.cover),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: PageView(
        controller: controllerClass.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: controllerClass.children,
        onPageChanged: (index) {
          setState(() {
            controllerClass.setIndex(index);
          });
        },
      ),
    );
  }
}

class SetupPageOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    PageControllerClass controllerClass = PageControllerClass();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 75.0),
            child: Text(
              'Welcome!',
              style: TextStyle(fontSize: 28.0),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 150.0),
            child: Text(
              'Add your account!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 80.0, vertical: 10.0),
            child: Text(
              'Click on add account to setup your account',
              style: TextStyle(fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF77DD77),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                controllerClass.setIndex(2);
              },
              child: const Text('Add Account'),
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
          )
        ],
      ),
    );
  }
}

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
      if (scanData != null) {
        await scanSubscription.cancel();
        try {
          var ip = await http.read(Uri.parse('https://api.ipify.org'));
          var os = UniversalPlatform.operatingSystem;
          final response = await http.post(
            Uri.parse(
                'https://zealand.moedekjaer.dk/final/api/public/api/two-factor-auth-verify'),
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
                  color: Color(0xFF77DD77)), // Green color
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
            child: Icon(Icons.backspace,
                size: 32.0, color: Color(0xFF77DD77)), // Green color
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
                child: SizedBox.shrink()), // Placeholder for alignment
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
            Center(
              child: Text(
                _isConfirming
                    ? 'Repeat your personal code'
                    : 'Create your personal code',
                style: const TextStyle(
                    fontSize: 24.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                6,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      _isConfirming
                          ? (_confirmCode.length > index ? '•' : '')
                          : (_enteredCode.length > index ? '•' : ''),
                      style: const TextStyle(fontSize: 24.0),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20.0),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _enteredCode = '';
  String? _errorMessage;
  
  Future<void> _checkAccessCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessCode = prefs.getString('access_code');
    if (accessCode == null) {
      // Access code exists, navigate to login page after the current build cycle
      PageControllerClass controllerClass = PageControllerClass();
      controllerClass.setIndex(1, animate: false);
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
    _checkAccessCode();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Enter your 6-digit access code',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                6,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      _enteredCode.length > index ? '•' : '',
                      style: const TextStyle(fontSize: 24.0),
                    ),
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20.0),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
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
            padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 10.0),
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