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
class FxAPushMessageHandler {
    let profile: Profile

    init(with profile: Profile) {
        self.profile = profile
    }
}

extension FxAPushMessageHandler {
    /// The main entry point to the handler.
    func handle(message: JSON?) -> Success {
        guard let json = message else {
            return handleVerification()
        }

        // https://dxr.mozilla.org/mozilla-central/source/mobile/android/services/src/main/java/org/mozilla/gecko/fxa/FxAccountPushHandler.java#19


        // https://github.com/mozilla/fxa-auth-server/blob/master/docs/pushpayloads.schema.json#L26

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
            return deferMaybe(PushMessageError.noActionNeeded)
        }

        // Now we're verified, we can start syncing.
        return account.advance().bind { _ in
            return succeed()
        }
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
            log.warning("collections_changed received but incomplete: \(data)")
            return deferMaybe(PushMessageError.messageIncomplete)
        }
        let sm = profile.syncManager
        let deferreds = collections.flatMap { (id: String) -> SyncResult? in
            switch id {
            case "addons":
                return nil
            case "forms":
                return nil
            case "prefs":
                return nil
            case "bookmarks":
                return nil
            case "history":
                return sm.syncHistory()
            case "tabs":
                return sm.syncClientsThenTabs()
            case "passwords":
                return sm.syncLogins()
            case "clients":
                // if we get "tabs", "clients" then we'll do "tabs" first, 
                // then "client", but not "tabs" a second time.
                return sm.syncClients()
            default:
                return nil
            }
        }

        if deferreds.isEmpty {
            return deferMaybe(PushMessageError.noActionNeeded)
        }

        return all(deferreds).bind { _ in
            return succeed()
        }
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
    case messageIncomplete
    case unimplemented(PushMessageType)
    case noActionNeeded

    public var description: String {
        switch self {
        case .messageIncomplete: return "messageIncomplete"
        case .noActionNeeded: return "noActionNeeded"
        case .unimplemented(let what): return "unimplemented=\(what)"
        }
    }
}
