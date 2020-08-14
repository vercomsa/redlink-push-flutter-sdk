import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ChannelUtil {
  static const String _CHANNEL = "pl.redlink.sdk/channel";
  static const Duration _channelTimeout = Duration(seconds: 15);
  static const MethodChannel channel = const MethodChannel(_CHANNEL);

  static Future<T> invokeMethod<T>({@required ChannelMethod method, dynamic arguments}) {
    return channel.invokeMethod<T>("${method.lastComponent('.')}", arguments).timeout(_channelTimeout);
  }
}

enum ChannelMethod { configureSDK, getToken, onToken, onMessage, setUser }

extension Strings on ChannelMethod {
  String lastComponent(String delimiter) {
    if (delimiter == null) {
      return this.toString();
    }
    return this.toString().split(delimiter).last ?? '';
  }
}
