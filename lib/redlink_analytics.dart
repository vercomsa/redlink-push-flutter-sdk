import 'package:redlink_flutter_sdk/utils/channel_util.dart';

class RedlinkAnalytics {
  const RedlinkAnalytics._();

  static void trackEvent({
    required String eventName,
    required Map<String, dynamic> parameters,
    String? userData,
  }) {
    ChannelUtil.invokeMethod(
      method: ChannelMethod.trackEvent,
      arguments: {
        'eventName': eventName,
        'parameters': parameters,
        'userData': userData,
      },
    );
  }
}
