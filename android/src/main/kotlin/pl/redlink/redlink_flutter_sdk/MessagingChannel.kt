package pl.redlink.redlink_flutter_sdk

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import pl.redlink.push.manager.token.FcmTokenManager
import pl.redlink.push.manager.user.RedlinkUser

private fun MethodCall.stringArgument(key: String): String? = argument(key) as? String

object MessagingChannel {

    const val channelIdentifier = "pl.redlink.sdk/channel"

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            MethodIdentifier.SET_USER.identifier -> setUser(call, result)
            MethodIdentifier.GET_TOKEN.identifier -> handleGetTokenMethod(call, result)
        }
    }

    private fun setUser(call: MethodCall, result: MethodChannel.Result) {
        RedlinkUser.Edit()
                .email(call.stringArgument("email").orEmpty())
                .firstName(call.stringArgument("firstName").orEmpty())
                .lastName(call.stringArgument("lastName").orEmpty())
                .phone(call.stringArgument("phone").orEmpty())
                .save()
    }

    private fun handleGetTokenMethod(call: MethodCall, result: MethodChannel.Result) {
        result.success(FcmTokenManager.get().orEmpty())
    }

    enum class MethodIdentifier(
            val identifier: String
    ) {

        GET_TOKEN("getToken"),
        ON_MESSAGE("onMessage"),
        SET_USER("setUser"),
        ON_TOKEN("onToken"),

    }

}
