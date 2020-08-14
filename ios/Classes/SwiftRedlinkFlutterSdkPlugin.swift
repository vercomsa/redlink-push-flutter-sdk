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
        channel?.invokeMethod(MessagingChannel.MethodIdentifier.onToken.rawValue, arguments: nil)
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    private func configureSDK(with call: FlutterMethodCall, result: @escaping FlutterResult) {
        let configuration = RedlinkConfiguration.defaultConfiguration()
        
        let arguments = call.arguments as? NSDictionary
        let isLoggingEnabled = arguments?.value(forKey: "isLoggingEnabled") as? Bool ?? false
        configuration.isLoggingEnabled = isLoggingEnabled
        
        Redlink.configure(using: configuration)
        Redlink.push.registerForPushNotifications(with: RedlinkPushOptions.default())
        
        Redlink.push.delegate = self
        result(nil)
    }
}


extension SwiftRedlinkFlutterSdkPlugin: RedlinkPushDelegate {
    public func didRecieveNotification(userInfo: [AnyHashable : Any]) {
        channel?.invokeMethod(ChannelMethod.onMessage.rawValue, arguments: userInfo)
    }
    
    public func didOpenNotification(userInfo: [AnyHashable : Any]) {
        
    }
    
    public func didClickOnActionButton(withIdentifier identifier: String, userInfo: [AnyHashable : Any]) {
        
    }
    
    public func unreachedNotificationIsAvailableToDisplay(userInfo: [AnyHashable : Any], completion: ((Bool) -> Void)) {
        // do nothing (🐛)
    }
}

private enum ChannelMethod: String {
    case configureSDK, getToken, onToken, onMessage
}

private enum ChannelError: Error {
    case methodNotSupported
}
