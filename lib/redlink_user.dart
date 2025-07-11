import 'package:redlink_flutter_sdk/utils/channel_util.dart';

class RedlinkUser {
  void detachToken() {
    ChannelUtil.invokeMethod(
      method: ChannelMethod.detachToken,
    );
  }

  void setUser({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? companyName,
    String? externalId,
  }) {
    ChannelUtil.invokeMethod(
      method: ChannelMethod.setUser,
      arguments: {
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phone": phoneNumber,
        "companyName": companyName,
        "externalId": externalId,
      },
    );
  }

  void removeUser({
    bool? deletePushToken,
  }) {
    ChannelUtil.invokeMethod(
      method: ChannelMethod.removeUser,
      arguments: {
        "deletePushToken": deletePushToken,
      },
    );
  }
}
