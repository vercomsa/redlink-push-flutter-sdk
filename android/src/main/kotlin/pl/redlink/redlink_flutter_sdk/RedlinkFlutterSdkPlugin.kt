package pl.redlink.redlink_flutter_sdk

import android.app.Activity
import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import pl.redlink.push.RedlinkApp
import pl.redlink.push.fcm.PushMessage
import pl.redlink.push.fcm.RedlinkFirebaseMessagingService
import pl.redlink.push.lifecycle.InAppPushHandler

/** RedlinkFlutterSdkPlugin */
public class RedlinkFlutterSdkPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private val pushBroadcast: BroadcastReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
      (intent?.getParcelableExtra(RedlinkFirebaseMessagingService.EXTRA_PUSH_MESSAGE) as? PushMessage)
              ?.let(::handlePushMessage)
    }
  }

  private val customInAppPushHandler: InAppPushHandler = object : InAppPushHandler {
    override fun handleLastPush(activity: Activity, pushMessage: PushMessage) {
      handlePushMessage(pushMessage)
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "redlink_flutter_sdk")
    channel.setMethodCallHandler(this)

    (flutterPluginBinding.applicationContext as? Application)?.registerReceiver(pushBroadcast, IntentFilter(RedlinkFirebaseMessagingService.PUSH_ACTION));

    RedlinkApp.customInAppPushHandler(customInAppPushHandler)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    MessagingChannel.handleMethodCall(call, result)
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), MessagingChannel.channelIdentifier)
      channel.setMethodCallHandler(RedlinkFlutterSdkPlugin())
    }
  }

  private fun handlePushMessage(pushMessage: PushMessage) {
    channel.invokeMethod(MessagingChannel.MethodIdentifier.ON_MESSAGE.identifier, pushMessage.data)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    (binding.applicationContext as? Application)?.unregisterReceiver(pushBroadcast)
  }
}
