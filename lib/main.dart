import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var prefs = await SharedPreferences.getInstance();
  runApp(MainApp(prefs: prefs));
  prefs.setString('two_factor_secret', '2JSVNK2O4R6VSRC3USXAL7LU');
  prefs.setString('access_code', '000000');
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
      AcceptRequestPage(),
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

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _enteredCode = '';
  String? _errorMessage;

  Future<void> _checkAccessCode(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessCode = prefs.getString('access_code');
    if (accessCode == null) {
      // Navigate to login page after the current build cycle
      PageControllerClass controllerClass = PageControllerClass();
      controllerClass.setIndex(1, animate: false);
      return;
    }

    // Ensure bearer token is not null
    var _bearerToken = prefs.getString('two_factor_secret');
    if (_bearerToken == null) {
      PageControllerClass controllerClass = PageControllerClass();
      controllerClass.setIndex(1, animate: false);
      return;
    }

    // Make the HTTP request
    int attempts = 0;
    while (attempts < 3) {
      final response = await http.get(
        Uri.parse(
            'https://zealand.moedekjaer.dk/final/api/public/api/two-factor-auth-status'),
        headers: {
          'Authorization': 'Bearer $_bearerToken',
        },
      );

      if (response.statusCode == 200) {
        // Success, break the loop
        break;
      } else if (response.statusCode == 500) {
        // Server error, increment attempts and try again
        attempts++;
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
              'Username',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
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
          'https://zealand.moedekjaer.dk/final/api/public/api/two-factor-auth-request'),
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
            const SizedBox(height: 20.0),
            const Text(
              'Approve',
              style: TextStyle(fontSize: 18.0, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
