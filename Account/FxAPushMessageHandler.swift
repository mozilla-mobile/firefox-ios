/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SwiftyJSON
import Account
import SwiftKeychainWrapper
import os.log

private let log = Logger.syncLogger

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
        let keychain = KeychainWrapper.sharedAppContainerKeychain
        guard let pushReg = keychain.object(forKey: KeychainKey.fxaPushRegistration) as? PushRegistration else {
            return deferMaybe(PushMessageError.accountError)
        }

        let subscription = pushReg.defaultSubscription

        guard let encoding = userInfo["con"] as? String, // content-encoding
            let payload = userInfo["body"] as? String else {
                return deferMaybe(PushMessageError.messageIncomplete("missing con or body"))
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
            // The app will detect this missing, and re-register. see AppDelegate+PushNotifications.swift.
            keychain.removeObject(forKey: KeychainKey.apnsToken)
            return deferMaybe(PushMessageError.notDecrypted)
        }

        // return handle(plaintext: string)
        let deferred = PushMessageResult()
        RustFirefoxAccounts.startup(prefs: profile.prefs).uponQueue(.main) { _ in
            RustFirefoxAccounts.reconfig { accountManager in
                accountManager.deviceConstellation()?.processRawIncomingAccountEvent(pushPayload: string) {
                    result in
                    guard case .success(let events) = result, let firstEvent = events.first else {
                        let err: PushMessageError
                        if case .failure(let error) = result {
                            err = PushMessageError.messageIncomplete(error.localizedDescription)
                        } else {
                            err = PushMessageError.messageIncomplete("empty message")
                        }
                        deferred.fill(Maybe(failure: err))
                        return
                    }
                    if events.count > 1 {
                        // Log to the console for debugging release builds
                        os_log("%{public}@", log: OSLog(subsystem: "org.mozilla.firefox", category: "firefoxnotificationservice"), type: OSLogType.debug, "Multiple events arrived, only handling the first event.")
                    }
                    switch firstEvent {
                    case .incomingDeviceCommand(let deviceCommand):
                        switch deviceCommand {
                        case .tabReceived(_, let tabData):
                            let title = tabData.last?.title ?? ""
                            let url = tabData.last?.url ?? ""
                            let message = PushMessage.commandReceived(tab: ["title": title, "url": url])
                            deferred.fill(Maybe(success: message))
                        }
                    case .deviceConnected(let deviceName):
                        let message = PushMessage.deviceConnected(deviceName)
                        deferred.fill(Maybe(success: message))
                    case let .deviceDisconnected(deviceId, isLocalDevice):
                        if isLocalDevice {
                            // We can't disconnect the device from the account until we have access to the application, so we'll handle this properly in the AppDelegate (as this code in an extension),
                            // by calling the FxALoginHelper.applicationDidDisonnect(application).
                            self.profile.prefs.setBool(true, forKey: PendingAccountDisconnectedKey)
                            let message = PushMessage.thisDeviceDisconnected
                            deferred.fill(Maybe(success: message))
                            return
                        }
                        
                        guard let profile = self.profile as? BrowserProfile else {
                            // We can't look up a name in testing, so this is the same as not knowing about it.
                            let message = PushMessage.deviceDisconnected(nil)
                            deferred.fill(Maybe(success: message))
                            return
                        }
                        
                        profile.remoteClientsAndTabs.getClient(fxaDeviceId: deviceId).uponQueue(.main) { result in
                            guard let device = result.successValue else { return }
                            let message = PushMessage.deviceDisconnected(device?.name)
                            if let id = device?.guid {
                                profile.remoteClientsAndTabs.deleteClient(guid: id).uponQueue(.main) { _ in
                                    print("deleted client")
                                }
                            }

                            deferred.fill(Maybe(success: message))
                        }
                    }
                }
            }
        }
        return deferred
    }
}

enum PushMessageType: String {
    case commandReceived = "fxaccounts:command_received"
    case deviceConnected = "fxaccounts:device_connected"
    case deviceDisconnected = "fxaccounts:device_disconnected"
    case profileUpdated = "fxaccounts:profile_updated"
    case passwordChanged = "fxaccounts:password_changed"
    case passwordReset = "fxaccounts:password_reset"
}

enum PushMessage: Equatable {
    case commandReceived(tab: [String : String])
    case deviceConnected(String)
    case deviceDisconnected(String?)
    case profileUpdated
    case passwordChanged
    case passwordReset

    // This is returned when we detect that it is us that has been disconnected.
    case thisDeviceDisconnected

    var messageType: PushMessageType {
        switch self {
        case .commandReceived(_):
            return .commandReceived
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
        }
    }

    public static func ==(lhs: PushMessage, rhs: PushMessage) -> Bool {
        guard lhs.messageType == rhs.messageType else {
            return false
        }

        switch (lhs, rhs) {
        case (.commandReceived(let lIndex), .commandReceived(let rIndex)):
            return lIndex == rIndex
        case (.deviceConnected(let lName), .deviceConnected(let rName)):
            return lName == rName
        default:
            return true
        }
    }
}

typealias PushMessageResult = Deferred<Maybe<PushMessage>>

enum PushMessageError: MaybeErrorType {
    case notDecrypted
    case messageIncomplete(String)
    case unimplemented(PushMessageType)
    case timeout
    case accountError
    case noProfile
    case subscriptionOutOfDate

    public var description: String {
        switch self {
        case .notDecrypted: return "notDecrypted"
        case .messageIncomplete(let message): return "messageIncomplete=\(message)"
        case .unimplemented(let what): return "unimplemented=\(what)"
        case .timeout: return "timeout"
        case .accountError: return "accountError"
        case .noProfile: return "noProfile"
        case .subscriptionOutOfDate: return "subscriptionOutOfDate"
        }
    }
}
