import Flutter
import UIKit
import Redlink

public class SwiftRedlinkFlutterSdkPlugin: NSObject, FlutterPlugin {

    private var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: MessagingChannel.channelIdentifier, binaryMessenger: registrar.messenger())
        
        let instance = SwiftRedlinkFlutterSdkPlugin()
        instance.channel = channel
        MessagingChannel.setChannel(channel)
        
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let methodIdentifier = call.method.components(separatedBy: "/").last ?? call.method
        MessagingChannel.handleCall(call, methodIdentifier: methodIdentifier, result: result)
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Redlink.push.didRegisterForRemoteNotifications(with: deviceToken)
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02.2hhx", $1)})
        MessagingChannel.setToken(deviceTokenString)
    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Redlink.push.didFailToRegisterForRemoteNotifications(with: error)
        MessagingChannel.setTokenError(error)
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
}
