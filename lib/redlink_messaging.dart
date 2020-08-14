import 'dart:async';

import 'package:flutter/services.dart';
import 'package:redlink_flutter_sdk/utils/channel_util.dart';

typedef MessageHandler = Function(Map<String, dynamic> message);

enum RedlinkPushOption { badge, sound, alert, carPlay }

class RedlinkMessaging {
  MessageHandler _onMessage;

  final StreamController<String> _tokenStreamController = StreamController<String>.broadcast();

  void configure({
    List<RedlinkPushOption> pushOptions,
    MessageHandler onMessage,
    MessageHandler onLaunch,
    MessageHandler onResume,
  }) {
    _onMessage = onMessage;
    ChannelUtil.channel.setMethodCallHandler(_handleChannelMethodCallback);
    ChannelUtil.invokeMethod<void>(method: ChannelMethod.configureSDK, arguments: {"pushOptions": pushOptions});
  }

  void setUser(String firstName, String lastName, String email, String phoneNumber) {
    ChannelUtil.invokeMethod(method: ChannelMethod.setUser, arguments: {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phoneNumber": phoneNumber,
    });
  }

  /// Fires when a new token is generated.
  Stream<String> get onTokenRefresh {
    return _tokenStreamController.stream;
  }

  /// Returns the push token.
  Future<String> getToken() async {
    return await ChannelUtil.invokeMethod<String>(method: ChannelMethod.getToken);
  }

  Future<dynamic> _handleChannelMethodCallback(MethodCall call) async {
    if (call.method == ChannelMethod.onMessage.lastComponent('.')) {
      print(call.arguments.cast<String, dynamic>());
      return _onMessage(call.arguments.cast<String, dynamic>());
    } else if (call.method == ChannelMethod.onToken.lastComponent('.')) {
      String token = call.arguments.cast<String>();
      print('Token $token');
      return _tokenStreamController.add(token);
    }
    throw UnsupportedError("Unrecognized JSON message");
  }
}
