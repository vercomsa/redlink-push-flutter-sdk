package pl.redlink.redlink_flutter_sdk

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import pl.redlink.push.analytics.RedlinkAnalytics
import pl.redlink.push.manager.token.FcmTokenManager
import pl.redlink.push.manager.user.RedlinkUser

private fun MethodCall.booleanArgument(key: String): Boolean? = argument(key) as? Boolean

private fun MethodCall.stringArgument(key: String): String? = argument(key) as? String

object MessagingChannel {

    const val channelIdentifier = "pl.redlink.sdk/channel"

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            MethodIdentifier.SET_USER.identifier -> setUser(call, result)
            MethodIdentifier.GET_TOKEN.identifier -> handleGetTokenMethod(call, result)
            MethodIdentifier.REMOVE_USER.identifier -> removeUser(call, result)
            MethodIdentifier.TRACK_EVENT.identifier -> trackEvent(call, result)
        }
    }

    private fun setUser(call: MethodCall, result: MethodChannel.Result) {
        RedlinkUser.Edit()
                .email(call.stringArgument("email").orEmpty())
                .firstName(call.stringArgument("firstName").orEmpty())
                .lastName(call.stringArgument("lastName").orEmpty())
                .phone(call.stringArgument("phone").orEmpty())
                .save()
        result.success(null)
    }

    private fun trackEvent(call: MethodCall, result: MethodChannel.Result) {
        val eventName = call.stringArgument("eventName") ?: return result.error("BAD_ARGS", "`eventName` property required", null)
        val parameters = call.argument<Map<String, Any>>("parameters") ?: return result.error("BAD_ARGS", "`parameters` property required", null)
        RedlinkAnalytics.trackEvent(eventName, parameters)
        result.success(null)
    }

    private fun removeUser(call: MethodCall, result: MethodChannel.Result) {
        RedlinkUser.remove(
            deletePushToken = call.booleanArgument("deletePushToken")
        )
        result.success(null)
    }

    private fun handleGetTokenMethod(call: MethodCall, result: MethodChannel.Result) {
        result.success(FcmTokenManager.get().orEmpty())
    }

    enum class MethodIdentifier(
            val identifier: String
    ) {

        CONFIGURE_SDK("configureSDK"),
        GET_TOKEN("getToken"),
        ON_LAUNCH("onLaunch"),
        ON_MESSAGE("onMessage"),
        ON_RESUME("onResume"),
        ON_TOKEN("onToken"),        
        REMOVE_USER("removeUser"),
        SET_USER("setUser"),
        TRACK_EVENT("trackEvent"),

    }

}
