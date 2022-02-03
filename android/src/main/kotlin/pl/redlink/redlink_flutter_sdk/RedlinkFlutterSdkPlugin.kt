package pl.redlink.redlink_flutter_sdk

import android.app.Activity
import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import com.google.firebase.FirebaseApp
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import io.flutter.plugin.common.PluginRegistry.Registrar
import pl.redlink.push.RedlinkApp
import pl.redlink.push.fcm.PushMessage
import pl.redlink.push.fcm.RedlinkFirebaseMessagingService
import pl.redlink.push.lifecycle.InAppPushHandler

// todo Implement token change observer and send token change on method `ON_TOKEN`
/** RedlinkFlutterSdkPlugin */
class RedlinkFlutterSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, NewIntentListener {

    private var channel: MethodChannel? = null
    private var onLaunchPushMessage: PushMessage? = null

    private val pushBroadcast: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (context?.isApplicationInForeground() == true) {
                intent?.getExtraPushMessage()?.let(::handleOnMessage)
            }
        }
    }

    private val customInAppPushHandler: InAppPushHandler = object : InAppPushHandler {
        override fun handleLastPush(activity: Activity, pushMessage: PushMessage) {
            // implement if needed
        }

        override fun dismissExpiredLastPushes(activity: Activity) {
            // implement if needed
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(binding.applicationContext, binding.binaryMessenger)
    }

    private fun onAttachedToEngine(context: Context, binaryMessenger: BinaryMessenger) {
        FirebaseApp.initializeApp(context.applicationContext)

        channel = MethodChannel(binaryMessenger, MessagingChannel.channelIdentifier)
        channel?.setMethodCallHandler(this)

        (context.applicationContext as? Application)
                ?.registerReceiver(pushBroadcast, IntentFilter(RedlinkFirebaseMessagingService.PUSH_ACTION))

        RedlinkApp.customInAppPushHandler(customInAppPushHandler)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == MessagingChannel.MethodIdentifier.CONFIGURE_SDK.identifier) {
            handleOnLaunch()
            result.success(null)
        }
        MessagingChannel.handleMethodCall(call, result)
    }

    private fun handleOnLaunch() {
        onLaunchPushMessage?.let { pushMessage ->
            channel?.invokeMethod(MessagingChannel.MethodIdentifier.ON_LAUNCH.identifier, pushMessage.data)
            onLaunchPushMessage = null
        }
    }

    private fun handleOnResume(pushMessage: PushMessage) {
        channel?.invokeMethod(MessagingChannel.MethodIdentifier.ON_RESUME.identifier, pushMessage.data)
    }

    private fun handleOnMessage(pushMessage: PushMessage) {
        channel?.invokeMethod(MessagingChannel.MethodIdentifier.ON_MESSAGE.identifier, pushMessage.data)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        (binding.applicationContext as? Application)?.unregisterReceiver(pushBroadcast)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        onLaunchPushMessage = binding.activity.intent?.getExtraPushMessage()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // no implementation needed
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        // no implementation needed
    }

    override fun onNewIntent(intent: Intent?): Boolean {
        intent?.getExtraPushMessage()?.let { pushMessage ->
            handleOnResume(pushMessage)
            return true
        }
        return false
    }

    private fun Intent.getExtraPushMessage(): PushMessage? =
            getParcelableExtra(RedlinkFirebaseMessagingService.EXTRA_PUSH_MESSAGE) as? PushMessage
                    ?: getParcelableExtra(EXTRA_PUSH_MESSAGE) as? PushMessage

    companion object {

        // NotificationActionBroadcast is internal in pl.redlink.push.fcm
        private const val /*pl.redlink.push.fcm.NotificationActionBroadcast.*/EXTRA_PUSH_MESSAGE =
                "pl.redlink.push.fcm.extra-push-message"

        // This static function is optional and equivalent to onAttachedToEngine. It supports the old
        // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
        // plugin registration via this function while apps migrate to use the new Android APIs
        // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
        //
        // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
        // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
        // depending on the user's project. onAttachedToEngine or registerWith must both be defined
        // in the same class.
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            RedlinkFlutterSdkPlugin().apply {
                registrar.addNewIntentListener(this)
                onAttachedToEngine(registrar.context(), registrar.messenger())
            }
        }

    }

}
