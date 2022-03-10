import Foundation
import Redlink

final class MessagingChannel: NSObject {

    static let channelIdentifier = "pl.redlink.sdk/channel"

    enum MethodIdentifier: String {
        // calls
        case configureSDK
        case registerForPush // ios only

        case getToken
        case setUser
        case removeUser
        case trackEvent

        // callbacks
        case onMessage
        case onLaunch // android only
        case onResume
        case onToken

        case unknown
    }

    private static let current = MessagingChannel()
    private var channel: FlutterMethodChannel?

    private var token: String?
    private var tokenError: Error?
    private var onToken: ((String?, Error?) -> Void)?

    static var result: FlutterResult?

    static func handleCall(_ call: FlutterMethodCall, methodIdentifier: String, result: @escaping FlutterResult) {
        let method = MethodIdentifier(rawValue:  methodIdentifier)
        switch method {
        case .configureSDK:
            return handleConfigureSDKMethodCall(call, result: result)
        case .registerForPush:
            return handleRegisterForPushMethodCall(call, result: result)
        case .setUser:
            return handleSetUserMethodCall(call, result: result)
        case .getToken:
            return handleGetTokenMethodCall(call, result: result)
        case .trackEvent:
            return handleTrackEventMethodCall(call, result: result)
        case .removeUser:
            return handleRemoveUserMethodCall(call, result: result)
        default:
            return result(FlutterMethodNotImplemented)
        }
    }

    private static func handleConfigureSDKMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let configuration = RedlinkConfiguration.defaultConfiguration()
        configuration.isLoggingEnabled = true
        Redlink.configure(using: configuration)
        result(nil)
    }

    private static func handleRegisterForPushMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Redlink.push.registerForPushNotifications(with: RedlinkPushOptions(authorizationOptions: [.badge, .alert, .sound], useAutomaticConfiguration: false))
        result(nil)
    }

    private static func handleSetUserMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? NSDictionary else { return Redlink.user.removeUser() }
        Redlink.user.email = arguments.value(forKey: "email") as? String
        Redlink.user.firstName = arguments.value(forKey: "firstName") as? String
        Redlink.user.lastName = arguments.value(forKey: "lastName") as? String
        Redlink.user.phone = arguments.value(forKey: "phone") as? String
        Redlink.user.companyName = arguments.value(forKey: "companyName") as? String
        Redlink.user.customParameters = arguments.value(forKey: "customParameters") as? [String: Any] ?? [:]
        Redlink.user.saveUser()
        result(nil)
    }
    
    private static func handleRemoveUserMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Redlink.user.removeUser()
        result(nil)
    }
    
    private static func handleTrackEventMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? NSDictionary else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        guard let eventName = arguments.value(forKey: "eventName") as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "`eventName` property required", details: nil))
            return
        }
        guard let parameters = arguments.value(forKey: "parameters") as? [String: Any] else {
            result(FlutterError(code: "BAD_ARGS", message: "`parameters` property required", details: nil))
            return
        }
        let userData = arguments.value(forKey: "userData") as? String
        Redlink.analytics.trackEvent(withName: eventName, parameters: parameters, userData: userData)
        result(nil)
    }
    
    private static func handleGetTokenMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard current.tokenError == nil else {
            result(FlutterError(code: "PERMISSION", message: "Token fetch failed", details: current.tokenError))
            return
        }
        guard let token = current.token else {
            current.onToken = { token, error in
                guard error == nil else {
                    result(FlutterError(code: "PERMISSION", message: "Token fetch failed", details: error))
                    return
                }
                result(token)
            }
            return
        }
        result(token)
    }
    
    static func setChannel(_ channel: FlutterMethodChannel) {
        current.channel = channel
        Redlink.push.delegate = current
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = current
        }
    }
    
    static func setToken(_ token: String) {
        current.token = token
        current.tokenError = nil

        current.onToken?(token, nil)
        current.onToken = nil

        current.channel?.invokeMethod(MethodIdentifier.onToken.rawValue, arguments: token)
    }

    static func setTokenError(_ error: Error) {
        current.token = nil
        current.tokenError = error

        current.onToken?(nil, error)
        current.onToken = nil

        current.channel?.invokeMethod(MethodIdentifier.onToken.rawValue, arguments: nil)
    }
}

// MARK: - RedlinkPushDelegate
extension MessagingChannel: RedlinkPushDelegate {
    func unreachedNotificationIsAvailableToDisplay(userInfo: [AnyHashable : Any], completion: ((Bool) -> Void)) {
        completion(false)
    }
}

// MARK: - RedlinkPushDelegate
extension MessagingChannel: UNUserNotificationCenterDelegate {
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(Redlink.push.willPresentNotification(notification, presentationOptions: [.alert, .sound]))
        sendNotification(userInfo: notification.request.content.userInfo, method: .onMessage)
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Redlink.push.didReceiveNotificationResponse(response: response)
        sendNotification(userInfo: response.notification.request.content.userInfo, method: .onResume)
        completionHandler()
    }

    func sendNotification(userInfo: [AnyHashable: Any], method: MethodIdentifier) {
        guard let channel = channel else { return }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let data = try? JSONSerialization.data(withJSONObject: userInfo, options: .fragmentsAllowed), let _ = try? decoder.decode(Message.self, from: data, at: "data") {
            channel.invokeMethod(method.rawValue, arguments: userInfo["data"])
        } else {
            channel.invokeMethod(method.rawValue, arguments: userInfo)
        }
    }
}

extension MessagingChannel {
    struct Message: Decodable {
        let id: String
        let title: String?
        let body: String?
        let image: String?
    }
}

private extension JSONDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data, at keyPath: String) throws -> T {
        let toplevel = try JSONSerialization.jsonObject(with: data)
        if let nestedJson = (toplevel as AnyObject).value(forKeyPath: keyPath) {
            let nestedJsonData = try JSONSerialization.data(withJSONObject: nestedJson)
            return try decode(type, from: nestedJsonData)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Nested json not found for key path \"\(keyPath)\""))
        }
    }
}
