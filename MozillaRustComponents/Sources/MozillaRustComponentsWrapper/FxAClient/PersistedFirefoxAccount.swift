/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
#if canImport(MozillaRustComponents)
    import MozillaRustComponents
#endif

/// This class inherits from the Rust `FirefoxAccount` and adds:
/// - Automatic state persistence through `PersistCallback`.
/// - Auth error signaling through observer notifications.
/// - Some convenience higher-level datatypes, such as URLs rather than plain Strings.
///
/// Eventually we'd like to move all of this into the underlying Rust code, once UniFFI
/// grows support for these extra features:
///   - Callback interfaces in Swift: https://github.com/mozilla/uniffi-rs/issues/353
///   - Higher-level data types: https://github.com/mozilla/uniffi-rs/issues/348
///
/// It's not yet clear how we might integrate with observer notifications in
/// a cross-platform way, though.
///
class PersistedFirefoxAccount {
    private var persistCallback: PersistCallback?
    private var inner: FirefoxAccount

    init(inner: FirefoxAccount) {
        self.inner = inner
    }

    public convenience init(config: FxaConfig) {
        self.init(inner: FirefoxAccount(config: config))
    }

    /// Registers a persistence callback. The callback will get called every time
    /// the `FxAccounts` state needs to be saved. The callback must
    /// persist the passed string in a secure location (like the keychain).
    public func registerPersistCallback(_ cb: PersistCallback) {
        persistCallback = cb
    }

    /// Unregisters a persistence callback.
    public func unregisterPersistCallback() {
        persistCallback = nil
    }

    public static func fromJSON(data: String) throws -> PersistedFirefoxAccount {
        return try PersistedFirefoxAccount(inner: FirefoxAccount.fromJson(data: data))
    }

    public func toJSON() throws -> String {
        try inner.toJson()
    }

    public func setUserData(userData: UserData) {
        defer { tryPersistState() }
        inner.setUserData(userData: userData)
    }

    public func beginOAuthFlow(
        scopes: [String],
        entrypoint: String
    ) throws -> URL {
        return try notifyAuthErrors {
            try URL(string: self.inner.beginOauthFlow(
                scopes: scopes,
                entrypoint: entrypoint
            ))!
        }
    }

    public func getPairingAuthorityURL() throws -> URL {
        return try URL(string: inner.getPairingAuthorityUrl())!
    }

    public func beginPairingFlow(
        pairingUrl: String,
        scopes: [String],
        entrypoint: String
    ) throws -> URL {
        return try notifyAuthErrors {
            try URL(string: self.inner.beginPairingFlow(pairingUrl: pairingUrl,
                                                        scopes: scopes,
                                                        entrypoint: entrypoint))!
        }
    }

    public func completeOAuthFlow(code: String, state: String) throws {
        defer { tryPersistState() }
        try notifyAuthErrors {
            try self.inner.completeOauthFlow(code: code, state: state)
        }
    }

    public func checkAuthorizationStatus() throws -> AuthorizationInfo {
        defer { tryPersistState() }
        return try notifyAuthErrors {
            try self.inner.checkAuthorizationStatus()
        }
    }

    public func disconnect() {
        defer { tryPersistState() }
        inner.disconnect()
    }

    public func getProfile(ignoreCache: Bool) throws -> Profile {
        defer { tryPersistState() }
        return try notifyAuthErrors {
            try self.inner.getProfile(ignoreCache: ignoreCache)
        }
    }

    public func initializeDevice(
        name: String,
        deviceType: DeviceType,
        supportedCapabilities: [DeviceCapability]
    ) throws {
        defer { tryPersistState() }
        try notifyAuthErrors {
            try self.inner.initializeDevice(name: name,
                                            deviceType: deviceType,
                                            supportedCapabilities: supportedCapabilities)
        }
    }

    public func getCurrentDeviceId() throws -> String {
        return try notifyAuthErrors {
            try self.inner.getCurrentDeviceId()
        }
    }

    public func getDevices(ignoreCache: Bool = false) throws -> [Device] {
        return try notifyAuthErrors {
            try self.inner.getDevices(ignoreCache: ignoreCache)
        }
    }

    public func getAttachedClients() throws -> [AttachedClient] {
        return try notifyAuthErrors {
            try self.inner.getAttachedClients()
        }
    }

    public func setDeviceName(_ name: String) throws {
        defer { tryPersistState() }
        try notifyAuthErrors {
            try self.inner.setDeviceName(displayName: name)
        }
    }

    public func clearDeviceName() throws {
        defer { tryPersistState() }
        try notifyAuthErrors {
            try self.inner.clearDeviceName()
        }
    }

    public func ensureCapabilities(supportedCapabilities: [DeviceCapability]) throws {
        defer { tryPersistState() }
        try notifyAuthErrors {
            try self.inner.ensureCapabilities(supportedCapabilities: supportedCapabilities)
        }
    }

    public func setDevicePushSubscription(sub: DevicePushSubscription) throws {
        try notifyAuthErrors {
            try self.inner.setPushSubscription(subscription: sub)
        }
    }

    public func handlePushMessage(payload: String) throws -> AccountEvent {
        defer { tryPersistState() }
        return try notifyAuthErrors {
            try self.inner.handlePushMessage(payload: payload)
        }
    }

    public func pollDeviceCommands() throws -> [IncomingDeviceCommand] {
        defer { tryPersistState() }
        return try notifyAuthErrors {
            try self.inner.pollDeviceCommands()
        }
    }

    public func sendSingleTab(targetDeviceId: String, title: String, url: String) throws {
        return try notifyAuthErrors {
            try self.inner.sendSingleTab(targetDeviceId: targetDeviceId, title: title, url: url)
        }
    }

    public func closeTabs(targetDeviceId: String, urls: [String]) throws -> CloseTabsResult {
        return try notifyAuthErrors {
            try self.inner.closeTabs(targetDeviceId: targetDeviceId, urls: urls)
        }
    }

    public func getTokenServerEndpointURL() throws -> URL {
        return try URL(string: inner.getTokenServerEndpointUrl())!
    }

    public func getConnectionSuccessURL() throws -> URL {
        return try URL(string: inner.getConnectionSuccessUrl())!
    }

    public func getManageAccountURL(entrypoint: String) throws -> URL {
        return try URL(string: inner.getManageAccountUrl(entrypoint: entrypoint))!
    }

    public func getManageDevicesURL(entrypoint: String) throws -> URL {
        return try URL(string: inner.getManageDevicesUrl(entrypoint: entrypoint))!
    }

    public func getAccessToken(scope: String, ttl: UInt64? = nil) throws -> AccessTokenInfo {
        defer { tryPersistState() }
        return try notifyAuthErrors {
            try self.inner.getAccessToken(scope: scope, ttl: ttl == nil ? nil : Int64(clamping: ttl!))
        }
    }

    public func getSessionToken() throws -> String {
        defer { tryPersistState() }
        return try notifyAuthErrors {
            try self.inner.getSessionToken()
        }
    }

    public func handleSessionTokenChange(sessionToken: String) throws {
        defer { tryPersistState() }
        return try notifyAuthErrors {
            try self.inner.handleSessionTokenChange(sessionToken: sessionToken)
        }
    }

    public func authorizeCodeUsingSessionToken(params: AuthorizationParameters) throws -> String {
        defer { tryPersistState() }
        return try notifyAuthErrors {
            try self.inner.authorizeCodeUsingSessionToken(params: params)
        }
    }

    public func clearAccessTokenCache() {
        defer { tryPersistState() }
        inner.clearAccessTokenCache()
    }

    public func gatherTelemetry() throws -> String {
        return try notifyAuthErrors {
            try self.inner.gatherTelemetry()
        }
    }

    private func tryPersistState() {
        guard let cb = persistCallback else {
            return
        }
        do {
            let json = try toJSON()
            cb.persist(json: json)
        } catch {
            // Ignore the error because the prior operation might have worked,
            // but still log it.
            FxALog.error("FxAccounts internal state serialization failed.")
        }
    }

    func notifyAuthErrors<T>(_ cb: () throws -> T) rethrows -> T {
        do {
            return try cb()
        } catch let error as FxaError {
            if case let .Authentication(msg) = error {
                FxALog.debug("Auth error caught: \(msg)")
                notifyAuthError()
            }
            throw error
        }
    }

    func notifyAuthError() {
        NotificationCenter.default.post(name: .accountAuthException, object: nil)
    }
}

public protocol PersistCallback {
    func persist(json: String)
}
