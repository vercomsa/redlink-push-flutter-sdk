import 'package:flutter/services.dart';

class ChannelUtil {
  static const String _channelName = 'pl.redlink.sdk/channel';
  static const Duration _channelTimeout = Duration(seconds: 15);
  static const MethodChannel _channel = MethodChannel(_channelName);

  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call) handler) {
    _channel.setMethodCallHandler(handler);
  }

  static Future<T?> invokeMethod<T>({
    required ChannelMethod method,
    dynamic arguments,
  }) {
    return _channel.invokeMethod<T>(method.name, arguments).timeout(_channelTimeout);
  }
}

enum ChannelMethod {
  configureSDK,
  detachToken,
  registerForPush,
  getToken,
  onLaunch,
  onMessage,
  onResume,
  onToken,
  removeUser,
  setUser,
  trackEvent,
}

extension ChannelMethodExtensions on ChannelMethod {
  String get name {
    switch (this) {
      case ChannelMethod.configureSDK:
        return 'configureSDK';
      case ChannelMethod.detachToken:
        return 'detachToken';
      case ChannelMethod.registerForPush:
        return 'registerForPush';
      case ChannelMethod.getToken:
        return 'getToken';
      case ChannelMethod.onLaunch:
        return 'onLaunch';
      case ChannelMethod.onMessage:
        return 'onMessage';
      case ChannelMethod.onResume:
        return 'onResume';
      case ChannelMethod.onToken:
        return 'onToken';
      case ChannelMethod.removeUser:
        return 'removeUser';
      case ChannelMethod.setUser:
        return 'setUser';
      case ChannelMethod.trackEvent:
        return 'trackEvent';
      default:
        return '';
    }
  }
}
