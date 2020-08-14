import 'package:flutter/material.dart';
import 'package:redlink_flutter_sdk/redlink_messaging.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool didConfigureSDK = false;
  RedlinkMessaging sdk = RedlinkMessaging();
  String token;
  Map<String, dynamic> _pushMessage;

  @override
  void initState() {
    super.initState();
    initRedlinkSDK();
  }

  initRedlinkSDK() {
    sdk.configure(onMessage: (message) {
      setState(() {
        _pushMessage = message;
      });
    });
    sdk.getToken().asStream().listen((event) {
      setState(() {
        token = event;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 50,
            ),
            Text(
              'Push token:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Center(
                child: token != null ? SelectableText('$token') : Text('Waiting for token request to complete'),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Text(
              'Push notification:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Center(
                child: Text(_pushMessage != null ? '$_pushMessage' : 'Waiting for push notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
