import Foundation
import Redlink

final class MessagingChannel {

    static let channelIdentifier = "pl.redlink.sdk/channel"

    enum MethodIdentifier: String {
        case configureSDK, getToken, onMessage, setUser, onToken
    }

    static var supportedMethodIdentifiers: [String] {
        return [MethodIdentifier.configureSDK.rawValue,
                MethodIdentifier.getToken.rawValue]
    }

    private static let current = MessagingChannel()
    private var channel: FlutterMethodChannel?
    private var token: String?
    private var onToken: ((String) -> Void)?
    
    static var result: FlutterResult?

    static func handleCall(_ call: FlutterMethodCall, methodIdentifier: String, result: @escaping FlutterResult) {
        switch methodIdentifier {
        case MethodIdentifier.configureSDK.rawValue:
            return handleConfigureSDKMethodCall(call, result: result)
        case MethodIdentifier.setUser.rawValue:
            return handleSetUserMethodCall(call, result: result)
        case MethodIdentifier.getToken.rawValue:
            return handleGetTokenMethodCall(call, result: result)
        default:
            return result(FlutterMethodNotImplemented)
        }
    }

    private static func handleConfigureSDKMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let configuration = RedlinkConfiguration.defaultConfiguration()
        configuration.isLoggingEnabled = true
        Redlink.configure(using: configuration)
        Redlink.push.delegate = current
        Redlink.push.registerForPushNotifications(with: RedlinkPushOptions.default())
    }

    private static func handleSetUserMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? NSDictionary else { return Redlink.user.removeUser() }
        Redlink.user.email = arguments.value(forKey: "email") as? String ?? ""
        Redlink.user.firstName = arguments.value(forKey: "firstName") as? String ?? ""
        Redlink.user.lastName = arguments.value(forKey: "lastName") as? String ?? ""
        Redlink.user.phone = arguments.value(forKey: "phone") as? String ?? ""
        Redlink.user.companyName = arguments.value(forKey: "companyName") as? String ?? ""
        Redlink.user.customParameters = arguments.value(forKey: "customParameters") as? [String: Any] ?? [:]
        Redlink.user.saveUser()
    }
    
    private static func handleGetTokenMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let token = current.token else {
            return current.onToken = { token in
                result(token)
            }
        }
        result(token)
    }
    
    static func setChannel(_ channel: FlutterMethodChannel) {
        current.channel = channel
    }
    
    static func setToken(_ token: String) {
        current.onToken?(token)
    }
}

// MARK: - RedlinkPushDelegate
extension MessagingChannel: RedlinkPushDelegate {
    func didRecieveNotification(userInfo: [AnyHashable : Any]) {
        guard let channel = channel else { return }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let data = try? JSONSerialization.data(withJSONObject: userInfo, options: .fragmentsAllowed), let _ = try? decoder.decode(Message.self, from: data, at: "data") {
            channel.invokeMethod(MethodIdentifier.onMessage.rawValue, arguments: userInfo["data"])
        } else {
            channel.invokeMethod(MethodIdentifier.onMessage.rawValue, arguments: userInfo)
        }
    }

    func didOpenNotification(userInfo: [AnyHashable : Any]) {

    }

    func didClickOnActionButton(withIdentifier identifier: String, userInfo: [AnyHashable : Any]) {

    }

    func unreachedNotificationIsAvailableToDisplay(userInfo: [AnyHashable : Any], completion: ((Bool) -> Void)) {
        // do nothing
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
