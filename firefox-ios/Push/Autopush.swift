// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

import class MozillaAppServices.PushManager
import protocol MozillaAppServices.PushManagerProtocol
import struct MozillaAppServices.DecryptResponse
import struct MozillaAppServices.SubscriptionResponse

public protocol AutopushProtocol {
    /// Updates the APNS token `Autopush` is using to send notifications to the device
    ///
    ///  - Parameter withDeviceToken: The APNS token the push servers should use to communicate with this device
    ///
    ///  - Throws: If the underlying native call to update the push servers fails
    func updateToken(withDeviceToken deviceToken: Data) async throws

    /// Creates a subscription with the `Autopush` servers with the given scope, 
    /// returns the subscription if it already exists
    ///
    ///  - Parameter scope: A consumer controlled string. When push notifications are decrypted,
    ///                     the scope will be broadcased so consumers can handle the notification
    ///  - Returns: A `SubscriptionResponse` that includes:
    ///         - Encryption keys to be used to encrypt any push notifications that will be sent to this device
    ///         - A URL that consumer can use to send push notifications to this device
    ///  - Throws: If the underlying native call to subscribe with the autopush servers fails
    func subscribe(scope: String) async throws -> SubscriptionResponse

    /// Unsubscribes a push subscription with the given scope.
    ///
    /// - Parameter scope: A consumer controlled string. When push notifications are decrypted,
    ///                    the scope will be broadcased so consumers can handle the notification
    /// - Returns: `true` if the subscription was unsubscribed, `false` if the subscription did not exist
    /// - Throws: If the underlying native call to unsubscribe with the autopush servers fails
    func unsubscribe(scope: String) async throws -> Bool

    /// Unsubscribes from all scopes
    ///
    /// - Throws: If the underlying native call to unsubscribe with the autopush servers fails
    func unsubscribeAll() async throws

    /// Decrypts an incoming push payload from `Autopush` server
    ///
    /// - Parameter payload: A map of String keys and String values representing payload as sent by the push servers
    ///
    /// - Returns: `DecryptResponse`, which includes both the decrypted payload, 
    ///            and the scope the push notification was for
    /// - Throws: If the native push client was unable to decrypt the payload
    func decrypt(payload: [String: String]) async throws -> DecryptResponse
}

public actor Autopush {
    private let pushManager: PushManagerProtocol

    public init(files: FileAccessor) async throws {
        let pushDB = URL(
            fileURLWithPath: try files.getAndEnsureDirectory(),
            isDirectory: true
        ).appendingPathComponent("push.db").path

        let pushManagerConfig = try PushConfigurationLabel
            .fromScheme(scheme: AppConstants.scheme)
            .toConfiguration(dbPath: pushDB)
        self.pushManager = try PushManager(config: pushManagerConfig)
    }

    /// Initializer for tests that want to inject a mock push manager
    public init(withPushManager pushManager: PushManagerProtocol) {
        self.pushManager = pushManager
    }
}

extension Autopush: AutopushProtocol {
    public func updateToken(withDeviceToken deviceToken: Data) async throws {
        try pushManager.update(registrationToken: deviceToken.hexEncodedString)
    }

    public func subscribe(scope: String) async throws -> SubscriptionResponse {
        return try pushManager.subscribe(scope: scope, appServerSey: nil)
    }

    public func unsubscribe(scope: String) async throws -> Bool {
        return try pushManager.unsubscribe(scope: scope)
    }

    public func unsubscribeAll() async throws {
        try pushManager.unsubscribeAll()
    }

    public func decrypt(payload: [String: String]) async throws -> DecryptResponse {
        return try pushManager.decrypt(payload: payload)
    }
}
