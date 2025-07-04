import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:redlink_flutter_sdk/redlink_analytics.dart';
import 'package:redlink_flutter_sdk/redlink_messaging.dart';
import 'package:redlink_flutter_sdk/redlink_user.dart';

const Color _primaryColor = Color(0xFFD30000);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RedlinkMessaging _sdk = RedlinkMessaging();
  String? _token;
  Map<String, dynamic>? _pushMessage;
  String? _pushMessageSource;
  List<dynamic> _eventParameters = []..length = 1;
  TextEditingController _eventNameEditingController = TextEditingController();
  TextEditingController _userNameEditingController = TextEditingController();
  TextEditingController _userEmailEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRedlinkSDK();
  }

  void _initRedlinkSDK() async {
    await _sdk.configure(
      onLaunch: (message) {
        setState(() {
          _pushMessage = message;
          _pushMessageSource = "onLaunch";
        });
      },
      onMessage: (message) {
        setState(() {
          _pushMessage = message;
          _pushMessageSource = "onMessage";
        });
      },
      onResume: (message) {
        setState(() {
          _pushMessage = message;
          _pushMessageSource = "onResume";
        });
      },
    );
    await _sdk.registerForPush();
    await _sdk.getToken().then(
      (value) {
        setState(
          () => _token = value,
        );
      },
      onError: (error) {
        _token = null;
        print(error.toString());
      },
    );
    _sdk.onTokenRefresh.listen((value) {
      setState(
        () => _token = value,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Redlink Push'),
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            vertical: 32.0,
            horizontal: 16.0,
          ),
          children: [
            _buildTokenSection(),
            const SizedBox(
              height: 48.0,
            ),
            _buildPushMessageSection(),
            const SizedBox(
              height: 48.0,
            ),
            _buildPushMessageSourceSection(),
            const SizedBox(
              height: 48.0,
            ),
            _buildSetUserDataSection(),
            _buildUnregisterTokenSection(),
            _buildDetachTokenSection(),
            const SizedBox(
              height: 48.0,
            ),
            _buildEventsSection(),
          ],
        ),
      ),
      theme: Theme.of(context).copyWith(
        primaryColor: _primaryColor,
      ),
    );
  }

  Widget _buildTokenSection() {
    final String? token = _token;
    return Column(
      children: [
        Text(
          'Push token:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        Center(
          child: token != null ? SelectableText(token) : Text('Waiting for token request to complete'),
        ),
      ],
    );
  }

  Widget _buildPushMessageSection() {
    return Column(
      children: [
        Text(
          'Push notification:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        Center(
          child: Text(_pushMessage != null ? _pushMessage.toString() : 'Waiting for push notification'),
        ),
      ],
    );
  }

  Widget _buildPushMessageSourceSection() {
    final String? pushMessageSource = _pushMessageSource;
    return Column(
      children: [
        Text(
          'Push notification source:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        Center(
          child: Text(pushMessageSource != null ? pushMessageSource : 'Waiting for push notification'),
        ),
      ],
    );
  }

  Widget _buildSetUserDataSection() {
    return Column(
      children: [
        Text(
          'Set user data:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        TextFormField(
          controller: _userNameEditingController,
          decoration: InputDecoration(
            labelText: 'Name',
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        TextFormField(
          controller: _userEmailEditingController,
          decoration: InputDecoration(
            labelText: 'Email',
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                final String userName = _userNameEditingController.text;
                final String email = _userEmailEditingController.text;
                if (userName.isNotEmpty || email.isNotEmpty) {
                  RedlinkUser().setUser(
                    firstName: userName,
                    email: email,
                  );
                }
              },
              child: Text(
                'Set user data',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnregisterTokenSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => RedlinkUser().removeUser(
            deletePushToken: true,
          ),
          child: Text(
            'Unregister device token',
          ),
        ),
      ],
    );
  }

  Widget _buildDetachTokenSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => RedlinkUser().detachToken(),
          child: Text(
            'Detach token',
          ),
        ),
      ],
    );
  }

  Widget _buildEventsSection() {
    return Column(
      children: [
        Text(
          'Send event:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        TextFormField(
          controller: _eventNameEditingController,
          decoration: InputDecoration(
            labelText: 'Event name',
          ),
        ),
        ...List<TextFormField>.generate(
          _eventParameters.length,
          (index) => TextFormField(
            decoration: InputDecoration(
              labelText: 'Parameter',
            ),
            onChanged: (value) {
              _eventParameters[index] = value;
            },
          ),
        ),
        const SizedBox(
          height: 16.0,
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                if (_eventNameEditingController.text.isNotEmpty) {
                  Map<String, dynamic> parametersMap = Map.fromIterable(
                    _eventParameters,
                    key: (element) => 'Parameter ${_eventParameters.indexOf(element)}',
                    value: (element) => element,
                  );
                  RedlinkAnalytics.trackEvent(
                    eventName: _eventNameEditingController.text,
                    parameters: parametersMap,
                  );
                }
              },
              child: Text(
                'Send',
              ),
            ),
            Spacer(),
            CircleAvatar(
              child: FloatingActionButton(
                backgroundColor: _primaryColor,
                child: Icon(
                  Icons.remove,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _eventParameters.length -= _eventParameters.length > 0 ? 1 : 0;
                  });
                },
              ),
            ),
            SizedBox(
              width: 4.0,
            ),
            CircleAvatar(
              child: FloatingActionButton(
                backgroundColor: _primaryColor,
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _eventParameters.length += 1;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
