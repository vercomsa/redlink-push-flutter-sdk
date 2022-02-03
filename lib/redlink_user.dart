import 'package:redlink_flutter_sdk/utils/channel_util.dart';

class RedlinkUser {
  void setUser({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) {
    ChannelUtil.invokeMethod(
      method: ChannelMethod.setUser,
      arguments: {
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phone": phoneNumber,
      },
    );
  }

  void removeUser() {
    ChannelUtil.invokeMethod(
      method: ChannelMethod.removeUser,
    );
  }
}
