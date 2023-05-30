// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import MozillaAppServices


protocol AutopushProtocol {
    /// Updates the APNS token `Autopush` is using to send notifications to the device
    ///
    ///  - Parameter withDeviceToken: The APNS token the push servers should use to communicate with this device
    ///
    ///  - Throws: If the underlying native call to update the push servers fails
    func updateToken(withDeviceToken deviceToken: Data) async throws

    /// Creates a subscription with the `Autopush` servers with the given scope, returns the subscription if it already exists
    ///
    ///  - Parameter scope: A consumer controlled string. When push notifications are decrypted, the scope will be broadcased so consumers
    ///                                             can handle the notification
    ///  - Returns: A `SubscriptionResponse` that includes:
    ///         - Encryption keys to be used to encrypt any push notifications that will be sent to this device
    ///         - A URL that consumer can use to send push notifications to this device
    ///  - Throws: If the underlying native call to subscribe with the autopush servers fails
    func subscribe(scope: String) async throws -> SubscriptionResponse

    /// Unsubscribes a push subscription with the given scope.
    ///
    /// - Parameter scope: A consumer controlled string. When push notifications are decrypted, the scope will be broadcased so consumers
    ///                                             can handle the notification
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
    /// - Returns: `DecryptResponse`, which includes both the decrypted payload, and the scope the push notification was for
    /// - Throws: If the native push client was unable to decrypt the payload
    func decrypt(payload: [String: String]) async throws -> DecryptResponse
}

open class Autopush {
    private var pushClient: PushManagerProtocol?
    private let dbPath: String

    public init(dbPath: String) {
        self.dbPath = dbPath
        self.pushClient = nil
    }

    /// Suspends execution and runs the given function in the global default dispatch queue against a native push client
    ///
    /// - Parameters:
    ///   - fn:  A function that takes a `PushManagerProtocol` and returns the value `withClient` would return
    ///
    /// - Returns: The return value of `fn`
    ///
    /// - Throws:
    ///     - if `withClient` could not get an opened push connection
    ///     - An error was throwing from `fn`
    ///
    /// - Note:
    ///     - `withClient` assumes that `fn` might need to do blocking IO and proactively schedules it on the global default dispatch queue
    ///     - `withClient` will attempt to open the underlying native client if not open already - The openning is done using `getOpenedPushClient`
    private func withClient<T>(_ fn: @escaping (PushManagerProtocol) throws -> T) async throws -> T {
        let pushClient = try await getOpenedPushClient()
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    continuation.resume(returning: try fn(pushClient))
                } catch let e {
                    continuation.resume(throwing: e)
                }
            }
        }
    }

    /// Gets a native push client if available, would otherwise open a new native push client and return it
    ///
    /// This function is called by `withClient` to prepare a client for execution.
    ///
    /// - Returns: An opened `PushManagerProtocol` that is ready to be queried
    private func getOpenedPushClient() async throws -> PushManagerProtocol {
        return try await withCheckedThrowingContinuation { continuation in
            if let pushClient = self.pushClient {
                continuation.resume(returning: pushClient)
                return
            }
            DispatchQueue.global().async {
                do {
                    let pushManagerConfig = try PushConfigurationLabel.fromScheme(scheme: AppConstants.scheme).toConfiguration(dbPath: self.dbPath)
                    let pushClient = try PushManager(config: pushManagerConfig)
                    self.pushClient = pushClient
                    continuation.resume(returning: pushClient)
                } catch let e {
                    continuation.resume(throwing: e)
                }
            }
        }
    }
}

extension Autopush: AutopushProtocol {
    public func updateToken(withDeviceToken deviceToken: Data) async throws {
        try await withClient { pushClient in
            try pushClient.update(registrationToken: deviceToken.hexEncodedString)
        }
    }

    public func subscribe(scope: String) async throws -> SubscriptionResponse {
        try await withClient { pushClient in
            return try pushClient.subscribe(scope: scope, appServerSey: nil)
        }
    }

    public func unsubscribe(scope: String) async throws -> Bool {
        return try await withClient { pushClient in
            return try pushClient.unsubscribe(scope: scope)
        }
    }

    public func unsubscribeAll() async throws {
        try await withClient { pushClient in
            try pushClient.unsubscribeAll()
        }
    }

    public func decrypt(payload: [String: String]) async throws -> DecryptResponse {
        return try await withClient { pushClient in
            return try pushClient.decrypt(payload: payload)
        }
    }
}
