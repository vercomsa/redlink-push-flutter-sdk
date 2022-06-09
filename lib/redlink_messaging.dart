import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:redlink_flutter_sdk/utils/channel_util.dart';

typedef MessageHandler = Function(Map<String, dynamic> message);

enum RedlinkPushOption {
  alert,
  badge,
  carPlay,
  sound,
}

class RedlinkMessaging {
  final StreamController<String> _tokenStreamController = StreamController<String>.broadcast();

  MessageHandler _onMessage = (_) {};
  MessageHandler _onLaunch = (_) {};
  MessageHandler _onResume = (_) {};

  Future<void> configure({
    MessageHandler? onMessage,
    MessageHandler? onLaunch,
    MessageHandler? onResume,
    List<RedlinkPushOption>? pushOptions,
  }) {
    _onMessage = onMessage ?? (_) {};
    _onLaunch = onLaunch ?? (_) {};
    _onResume = onResume ?? (_) {};

    ChannelUtil.setMethodCallHandler(_handleChannelMethodCallback);
    return ChannelUtil.invokeMethod<void>(
      method: ChannelMethod.configureSDK,
      arguments: {
        "pushOptions": pushOptions,
      },
    ).catchError(
      (error) {
        // There is no need to log a TimeoutException.
        if (error is! TimeoutException) throw error;
      },
    );
  }

  /// Registers for iOS push notifications
  Future<void> registerForPush() {
    if (Platform.isAndroid) {
      return Future.value();
    }
    return ChannelUtil.invokeMethod<void>(
      method: ChannelMethod.registerForPush,
    );
  }

  /// Fires when a new token is generated.
  Stream<String> get onTokenRefresh {
    return _tokenStreamController.stream;
  }

  /// Returns the push token.
  Future<String?> getToken() async {
    return ChannelUtil.invokeMethod<String>(
      method: ChannelMethod.getToken,
    );
  }

  Future<dynamic> _handleChannelMethodCallback(MethodCall call) async {
    String method = call.method;
    dynamic arguments = call.arguments;
    if (method == ChannelMethod.onLaunch.name) {
      return _onLaunch(arguments.cast<String, dynamic>());
    } else if (method == ChannelMethod.onMessage.name) {
      return _onMessage(arguments.cast<String, dynamic>());
    } else if (method == ChannelMethod.onResume.name) {
      return _onResume(arguments.cast<String, dynamic>());
    } else if (method == ChannelMethod.onToken.name) {
      return _tokenStreamController.add(arguments.cast<String>());
    }
    throw UnsupportedError("Unrecognized JSON message");
  }
}
