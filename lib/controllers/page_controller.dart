import 'package:flutter/material.dart';

// Pages
import '../pages/login_page.dart';
import '../pages/setup_page_one.dart';
import '../pages/setup_page_two.dart';
import '../pages/setup_page_three.dart';
import '../pages/setup_page_four.dart';
import '../pages/home_page.dart';
import '../pages/accept_request_page.dart';

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
