// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Account
import Common
import enum MozillaAppServices.IncomingDeviceCommand
import enum MozillaAppServices.AccountEvent

let PendingAccountDisconnectedKey = "PendingAccountDisconnect"

/// This class provides handles push messages from FxA.
/// The main entry point is the `handleDecryptedMessage` method to accept the decrypted push message and parse it into a
/// `PushMessage`
class FxAPushMessageHandler {
    let profile: Profile
    private let logger: Logger

    init(with profile: Profile, logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
    }
}

extension FxAPushMessageHandler {
    func handleDecryptedMessage(
        message: String,
        completion: @escaping (Result<PushMessage, PushMessageError>) -> Void
    ) {
        // Reconfig has to happen on the main thread, since it calls `startup`
        // and `startup` asserts that we are on the main thread. Otherwise the notification
        // service will crash.
        DispatchQueue.main.async {
            RustFirefoxAccounts.reconfig(prefs: self.profile.prefs) { accountManager in
                accountManager.deviceConstellation()?.handlePushMessage(pushPayload: message) { result in
                    guard case .success(let event) = result else {
                        let err = self.makePushErrorMessageFrom(result: result)
                        completion(.failure(err))
                        return
                    }

                    switch event {
                    case .commandReceived(let deviceCommand):
                        let pushMessage = self.makePushMessageFrom(deviceCommand: deviceCommand)
                        completion(.success(pushMessage))
                    case .deviceConnected(let deviceName):
                        completion(.success(PushMessage.deviceConnected(deviceName)))
                    case let .deviceDisconnected(_, isLocalDevice):
                        if isLocalDevice {
                            // We can't disconnect the device from the account until we have access to the application,
                            // so we'll handle this properly in the AppDelegate (as this code in an extension),
                            // by calling the FxALoginHelper.applicationDidDisonnect(application).
                            self.profile.prefs.setBool(true, forKey: PendingAccountDisconnectedKey)
                            completion(.success(PushMessage.thisDeviceDisconnected))
                        }
                        completion(.success(PushMessage.deviceDisconnected))
                    default:
                        // There are other events, but we ignore them at this level.
                        break
                    }
                }
            }
        }
    }

    private func makePushErrorMessageFrom(result: Result<AccountEvent, Error>) -> PushMessageError {
        if case .failure(let error) = result {
            self.logger.log("Failed to get any events from FxA",
                            level: .warning,
                            category: .sync,
                            description: error.localizedDescription)
            return PushMessageError.messageIncomplete(error.localizedDescription)
        } else {
            self.logger.log("Got zero events from FxA",
                            level: .warning,
                            category: .sync,
                            description: "No events retrieved from fxa")
            return PushMessageError.messageIncomplete("empty message")
        }
    }

    private func makePushMessageFrom(deviceCommand: IncomingDeviceCommand) -> PushMessage {
        switch deviceCommand {
        case .tabReceived(_, let tabData):
            let title = tabData.entries.last?.title ?? ""
            let url = tabData.entries.last?.url ?? ""
            let command = CommandReceived.tabReceived(tab: ["title": title, "url": url])
            return PushMessage.commandReceived(command: command)
        case .tabsClosed(_, let payload):
            let command = CommandReceived.tabsClosed(urls: payload.urls)
            return PushMessage.commandReceived(command: command)
        }
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
    case commandReceived(command: CommandReceived)
    case deviceConnected(String)
    case deviceDisconnected
    case profileUpdated
    case passwordChanged
    case passwordReset

    // This is returned when we detect that it is us that has been disconnected.
    case thisDeviceDisconnected

    var messageType: PushMessageType {
        switch self {
        case .commandReceived:
            return .commandReceived
        case .deviceConnected:
            return .deviceConnected
        case .deviceDisconnected:
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

    public static func == (lhs: PushMessage, rhs: PushMessage) -> Bool {
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

enum CommandReceived: Equatable {
    case tabReceived(tab: [String: String])
    case tabsClosed(urls: [String])
}
