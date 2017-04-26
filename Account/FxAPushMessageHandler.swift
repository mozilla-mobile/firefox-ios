/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
import SwiftyJSON
import Sync
import XCGLogger

private let log = Logger.syncLogger

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
    @discardableResult func handle(userInfo: [AnyHashable: Any]) -> Success {
        guard let subscription = profile.getAccount()?.pushRegistration?.defaultSubscription else {
            return deferMaybe(PushMessageError.notDecrypted)
        }

        guard let encoding = userInfo["con"] as? String, // content-encoding
            let payload = userInfo["body"] as? String else {
                return deferMaybe(PushMessageError.messageIncomplete)
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

        guard let _ = plaintext else {
            return deferMaybe(PushMessageError.notDecrypted)
        }

        return handle(message: JSON(parseJSON: plaintext!))
    }

    /// The main entry point to the handler for decrypted messages.
    func handle(message json: JSON) -> Success {
        if !json.isDictionary() {
            return handleVerification()
        }

        let rawValue = json["command"].stringValue
        guard let command = PushMessageType(rawValue: rawValue) else {
            log.warning("Command \(rawValue) received but not recognized")
            return deferMaybe(PushMessageError.messageIncomplete)
        }

        let result: Success
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
        }
        return result
    }
}

extension FxAPushMessageHandler {
    func handleVerification() -> Success {
        guard let account = profile.getAccount(), account.actionNeeded == .needsVerification else {
            log.info("Account verified by server either doesn't exist or doesn't need verifying")
            return succeed()
        }

        // If we're verified, we can start syncing.
        return account.advance().bind { _ in return succeed() }
    }
}

/// An extension to handle each of the messages.
extension FxAPushMessageHandler {
    func handleDeviceConnected(_ data: JSON?) -> Success {
        guard let deviceName = data?["deviceName"].string else {
            return messageIncomplete(.deviceConnected)
        }
        return unimplemented(.deviceConnected, with: deviceName)
    }
}

extension FxAPushMessageHandler {
    func handleDeviceDisconnected(_ data: JSON?) -> Success {
        guard let deviceID = data?["id"].string else {
            return messageIncomplete(.deviceDisconnected)
        }
        return unimplemented(.deviceDisconnected, with: deviceID)
    }
}

extension FxAPushMessageHandler {
    func handleProfileUpdated() -> Success {
        return unimplemented(.profileUpdated)
    }
}

extension FxAPushMessageHandler {
    func handlePasswordChanged() -> Success {
        return unimplemented(.passwordChanged)
    }
}

extension FxAPushMessageHandler {
    func handlePasswordReset() -> Success {
        return unimplemented(.passwordReset)
    }
}

extension FxAPushMessageHandler {
    func handleCollectionChanged(_ data: JSON?) -> Success {
        guard let collections = data?["collections"].arrayObject as? [String] else {
            log.warning("collections_changed received but incomplete: \(data ?? "nil")")
            return deferMaybe(PushMessageError.messageIncomplete)
        }
        // Possible values: "addons", "bookmarks", "history", "forms", "prefs", "tabs", "passwords", "clients"

        // syncManager will only do a subset; others will be ignored.
        return profile.syncManager.syncNamedCollections(why: .push, names: collections)
    }
}

/// Some utility methods
fileprivate extension FxAPushMessageHandler {
    func unimplemented(_ messageType: PushMessageType, with param: String? = nil) -> Success {
        if let param = param {
            log.warning("\(messageType) message received with parameter = \(param), but unimplemented")
        } else {
            log.warning("\(messageType) message received, but unimplemented")
        }
        return deferMaybe(PushMessageError.unimplemented(messageType))
    }

    func messageIncomplete(_ messageType: PushMessageType) -> Success {
        log.info("\(messageType) message received, but incomplete")
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
}

enum PushMessageError: MaybeErrorType {
    case notDecrypted
    case messageIncomplete
    case unimplemented(PushMessageType)

    public var description: String {
        switch self {
        case .notDecrypted: return "notDecrypted"
        case .messageIncomplete: return "messageIncomplete"
        case .unimplemented(let what): return "unimplemented=\(what)"
        }
    }
}
