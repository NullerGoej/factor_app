import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../controllers/page_controller.dart';

class SetupPageOne extends StatefulWidget {
  const SetupPageOne({Key? key}) : super(key: key);

  @override
  _SetupPageOneState createState() => _SetupPageOneState();
}

class _SetupPageOneState extends State<SetupPageOne> {
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