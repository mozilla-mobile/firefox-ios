/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Shared
import SwiftyJSON

let PendingAccountDisconnectedKey = "PendingAccountDisconnect"

/// This class provides handles push messages from FxA.
/// For reference, the [message schema][0] and [Android implementation][1] are both useful resources.
/// [0]: https://github.com/mozilla/fxa-auth-server/blob/master/docs/pushpayloads.schema.json#L26
/// [1]: https://dxr.mozilla.org/mozilla-central/source/mobile/android/services/src/main/java/org/mozilla/gecko/fxa/FxAccountPushHandler.java
/// The main entry points are `handle` methods, to accept the raw APNS `userInfo` and then to process the resulting JSON.
class FxAPushMessageHandler {
    let profile: Profile

    init(with profile: Profile) {
        self.profile = profile
    }
}

extension FxAPushMessageHandler {
    /// Accepts the raw Push message from Autopush.
    /// This method then decrypts it according to the content-encoding (aes128gcm or aesgcm)
    /// and then effects changes on the logged in account.
    @discardableResult func handle(userInfo: [AnyHashable: Any]) -> PushMessageResult {
        guard let subscription = profile.getAccount()?.pushRegistration?.defaultSubscription else {
            return deferMaybe(PushMessageError.notDecrypted)
        }

        guard let encoding = userInfo["con"] as? String, // content-encoding
            let payload = userInfo["body"] as? String else {
                return handleVerification()
        }
        // ver == endpointURL path, chid == channel id, aps == alert text and content_available.

        let plaintext: String?
        if let cryptoKeyHeader = userInfo["cryptokey"] as? String,  // crypto-key
            let encryptionHeader = userInfo["enc"] as? String, // encryption
            encoding == "aesgcm" {
            plaintext = subscription.aesgcm(payload: payload, encryptionHeader: encryptionHeader, cryptoHeader: cryptoKeyHeader)
        } else if encoding == "aes128gcm" {
            plaintext = subscription.aes128gcm(payload: payload)
        } else {
            plaintext = nil
        }

        guard let string = plaintext else {
            return deferMaybe(PushMessageError.notDecrypted)
        }

        return handle(plaintext: string)
    }

    func handle(plaintext: String) -> PushMessageResult {
        return handle(message: JSON(parseJSON: plaintext))
    }

    /// The main entry point to the handler for decrypted messages.
    func handle(message json: JSON) -> PushMessageResult {
        if !json.isDictionary() || json.isEmpty {
            return handleVerification()
        }

        let rawValue = json["command"].stringValue
        guard let command = PushMessageType(rawValue: rawValue) else {
            print("Command \(rawValue) received but not recognized")
            return deferMaybe(PushMessageError.messageIncomplete)
        }

        let result: PushMessageResult
        switch command {
        case .deviceConnected:
            result = handleDeviceConnected(json["data"])
        case .deviceDisconnected:
            result = handleDeviceDisconnected(json["data"])
        case .profileUpdated:
            result = handleProfileUpdated()
        case .passwordChanged:
            result = handlePasswordChanged()
        case .passwordReset:
            result = handlePasswordReset()
        case .collectionChanged:
            result = handleCollectionChanged(json["data"])
        case .accountVerified:
            result = handleVerification()
        }
        return result
    }
}

extension FxAPushMessageHandler {
    func handleVerification() -> PushMessageResult {
        // What we'd really like to be able to start syncing immediately we receive this
        // message, but this method is run by the extension, so we can't do it here.
        return deferMaybe(.accountVerified)
    }

    // This will be executed by the app, not the extension.
    // This isn't guaranteed to be run (when the app is backgrounded, and the user
    // doesn't tap on the notification), but that's okay because:
    // We'll naturally be syncing shortly after startup.
    func postVerification() -> Success {
        if let account = profile.getAccount(),
            let syncManager = profile.syncManager {
            return account.advance().bind { _ in
                return syncManager.syncEverything(why: .didLogin)
            } >>> succeed
        }
        return succeed()
    }
}

/// An extension to handle each of the messages.
extension FxAPushMessageHandler {
    func handleDeviceConnected(_ data: JSON?) -> PushMessageResult {
        guard let deviceName = data?["deviceName"].string else {
            return messageIncomplete(.deviceConnected)
        }
        let message = PushMessage.deviceConnected(deviceName)
        return deferMaybe(message)
    }
}

extension FxAPushMessageHandler {
    func handleDeviceDisconnected(_ data: JSON?) -> PushMessageResult {
        guard let deviceId = data?["id"].string else {
            return messageIncomplete(.deviceDisconnected)
        }

        if let ourDeviceId = self.getOurDeviceId(), deviceId == ourDeviceId {
            // We can't disconnect the device from the account until we have 
            // access to the application, so we'll handle this properly in the AppDelegate,
            // by calling the FxALoginHelper.applicationDidDisonnect(application).
            profile.prefs.setBool(true, forKey: PendingAccountDisconnectedKey)
            return deferMaybe(PushMessage.thisDeviceDisconnected)
        }

        guard let profile = self.profile as? BrowserProfile else {
            // We can't look up a name in testing, so this is the same as
            // not knowing about it.
            return deferMaybe(PushMessage.deviceDisconnected(nil))
        }

        let clients = profile.remoteClientsAndTabs
        let getClient = clients.getClient(fxaDeviceId: deviceId)
        
        return getClient >>== { device in
            let message = PushMessage.deviceDisconnected(device?.name)
            if let id = device?.guid {
                return clients.deleteClient(guid: id) >>== { _ in deferMaybe(message) }
            }

            return deferMaybe(message)
        }
    }

    fileprivate func getOurDeviceId() -> String? {
        return profile.getAccount()?.deviceRegistration?.id
    }
}

extension FxAPushMessageHandler {
    func handleProfileUpdated() -> PushMessageResult {
        return unimplemented(.profileUpdated)
    }
}

extension FxAPushMessageHandler {
    func handlePasswordChanged() -> PushMessageResult {
        return unimplemented(.passwordChanged)
    }
}

extension FxAPushMessageHandler {
    func handlePasswordReset() -> PushMessageResult {
        return unimplemented(.passwordReset)
    }
}

extension FxAPushMessageHandler {
    func handleCollectionChanged(_ data: JSON?) -> PushMessageResult {
        guard let collections = data?["collections"].arrayObject as? [String] else {
            print("collections_changed received but incomplete: \(data ?? "nil")")
            return deferMaybe(PushMessageError.messageIncomplete)
        }
        // Possible values: "addons", "bookmarks", "history", "forms", "prefs", "tabs", "passwords", "clients"

        // syncManager will only do a subset; others will be ignored.
        return profile.syncManager.syncNamedCollections(why: .push, names: collections) >>== { deferMaybe(.collectionChanged(collections: collections)) }
    }
}

/// Some utility methods
fileprivate extension FxAPushMessageHandler {
    func unimplemented(_ messageType: PushMessageType, with param: String? = nil) -> PushMessageResult {
        if let param = param {
            print("\(messageType) message received with parameter = \(param), but unimplemented")
        } else {
            print("\(messageType) message received, but unimplemented")
        }
        return deferMaybe(PushMessageError.unimplemented(messageType))
    }

    func messageIncomplete(_ messageType: PushMessageType) -> PushMessageResult {
        print("\(messageType) message received, but incomplete")
        return deferMaybe(PushMessageError.messageIncomplete)
    }
}

enum PushMessageType: String {
    case deviceConnected = "fxaccounts:device_connected"
    case deviceDisconnected = "fxaccounts:device_disconnected"
    case profileUpdated = "fxaccounts:profile_updated"
    case passwordChanged = "fxaccounts:password_changed"
    case passwordReset = "fxaccounts:password_reset"
    case collectionChanged = "sync:collection_changed"

    // This isn't a real message type, just the absence of one.
    case accountVerified = "account_verified"
}

enum PushMessage: Equatable {
    case deviceConnected(String)
    case deviceDisconnected(String?)
    case profileUpdated
    case passwordChanged
    case passwordReset
    case collectionChanged(collections: [String])
    case accountVerified

    // This is returned when we detect that it is us that has been disconnected.
    case thisDeviceDisconnected

    var messageType: PushMessageType {
        switch self {
        case .deviceConnected(_):
            return .deviceConnected
        case .deviceDisconnected(_):
            return .deviceDisconnected
        case .thisDeviceDisconnected:
            return .deviceDisconnected
        case .profileUpdated:
            return .profileUpdated
        case .passwordChanged:
            return .passwordChanged
        case .passwordReset:
            return .passwordReset
        case .collectionChanged(collections: _):
            return .collectionChanged
        case .accountVerified:
            return .accountVerified
        }
    }

    public static func ==(lhs: PushMessage, rhs: PushMessage) -> Bool {
        guard lhs.messageType == rhs.messageType else {
            return false
        }

        switch (lhs, rhs) {
        case (.deviceConnected(let lName), .deviceConnected(let rName)):
            return lName == rName
        case (.collectionChanged(let lList), .collectionChanged(let rList)):
            return lList == rList
        default:
            return true
        }
    }
}

typealias PushMessageResult = Deferred<Maybe<PushMessage>>

enum PushMessageError: MaybeErrorType {
    case notDecrypted
    case messageIncomplete
    case unimplemented(PushMessageType)
    case timeout
    case accountError
    case noProfile

    public var description: String {
        switch self {
        case .notDecrypted: return "notDecrypted"
        case .messageIncomplete: return "messageIncomplete"
        case .unimplemented(let what): return "unimplemented=\(what)"
        case .timeout: return "timeout"
        case .accountError: return "accountError"
        case .noProfile: return "noProfile"
        }
    }
}
