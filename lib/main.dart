import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/page_controller.dart';

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