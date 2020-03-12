/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftProtobuf

/// This class wraps Rust calls safely and performs necessary type conversions.
open class RustFxAccount {
    private let raw: UInt64

    internal init(raw: UInt64) {
        self.raw = raw
    }

    /// Create a `RustFxAccount` from scratch. This is suitable for callers using the
    /// OAuth Flow.
    public required convenience init(config: FxAConfig) throws {
        let pointer = try rustCall { err in
            fxa_new(config.contentUrl, config.clientId, config.redirectUri, err)
        }
        self.init(raw: pointer)
    }

    /// Restore a previous instance of `RustFxAccount` from a serialized state (obtained with `toJSON(...)`).
    public required convenience init(fromJsonState state: String) throws {
        let pointer = try rustCall { err in fxa_from_json(state, err) }
        self.init(raw: pointer)
    }

    deinit {
        if self.raw != 0 {
            try! rustCall { err in
                // Is `try!` the right thing to do? We should only hit an error here
                // for panics and handle misuse, both inidicate bugs in our code
                // (the first in the rust code, the 2nd in this swift wrapper).
                fxa_free(self.raw, err)
            }
        }
    }

    /// Serializes the state of a `RustFxAccount` instance. It can be restored
    /// later with `fromJSON(...)`. It is the responsability of the caller to
    /// persist that serialized state regularly (after operations that mutate
    /// `RustFxAccount`) in a **secure** location.
    open func toJSON() throws -> String {
        let ptr = try rustCall { err in fxa_to_json(self.raw, err) }
        return String(freeingFxaString: ptr)
    }

    /// Gets the logged-in user profile.
    /// Throws `FirefoxAccountError.Unauthorized` if we couldn't find any suitable access token
    /// to make that call. The caller should then start the OAuth Flow again with
    /// the "profile" scope.
    open func getProfile() throws -> Profile {
        let ptr = try rustCall { err in
            fxa_profile(self.raw, false, err)
        }
        defer { fxa_bytebuffer_free(ptr) }
        let msg = try! MsgTypes_Profile(serializedData: Data(rustBuffer: ptr))
        return Profile(msg: msg)
    }

    open func getTokenServerEndpointURL() throws -> URL {
        let ptr = try rustCall { err in
            fxa_get_token_server_endpoint_url(self.raw, err)
        }
        return URL(string: String(freeingFxaString: ptr))!
    }

    open func getConnectionSuccessURL() throws -> URL {
        let ptr = try rustCall { err in
            fxa_get_connection_success_url(self.raw, err)
        }
        return URL(string: String(freeingFxaString: ptr))!
    }

    open func getManageAccountURL(entrypoint: String) throws -> URL {
        let ptr = try rustCall { err in
            fxa_get_manage_account_url(self.raw, entrypoint, err)
        }
        return URL(string: String(freeingFxaString: ptr))!
    }

    open func getManageDevicesURL(entrypoint: String) throws -> URL {
        let ptr = try rustCall { err in
            fxa_get_manage_devices_url(self.raw, entrypoint, err)
        }
        return URL(string: String(freeingFxaString: ptr))!
    }

    /// Request a OAuth token by starting a new OAuth flow.
    ///
    /// This function returns a URL string that the caller should open in a webview.
    ///
    /// Once the user has confirmed the authorization grant, they will get redirected to `redirect_url`:
    /// the caller must intercept that redirection, extract the `code` and `state` query parameters and call
    /// `completeOAuthFlow(...)` to complete the flow.
    open func beginOAuthFlow(scopes: [String]) throws -> URL {
        let scope = scopes.joined(separator: " ")
        let ptr = try rustCall { err in
            fxa_begin_oauth_flow(self.raw, scope, err)
        }
        return URL(string: String(freeingFxaString: ptr))!
    }

    open func beginPairingFlow(pairingUrl: String, scopes: [String]) throws -> URL {
        let scope = scopes.joined(separator: " ")
        let ptr = try rustCall { err in
            fxa_begin_pairing_flow(self.raw, pairingUrl, scope, err)
        }
        return URL(string: String(freeingFxaString: ptr))!
    }

    /// Finish an OAuth flow initiated by `beginOAuthFlow(...)` and returns token/keys.
    ///
    /// This resulting token might not have all the `scopes` the caller have requested (e.g. the user
    /// might have denied some of them): it is the responsibility of the caller to accomodate that.
    open func completeOAuthFlow(code: String, state: String) throws {
        try rustCall { err in
            fxa_complete_oauth_flow(self.raw, code, state, err)
        }
    }

    /// Try to get an OAuth access token.
    ///
    /// Throws `FirefoxAccountError.Unauthorized` if we couldn't provide an access token
    /// for this scope. The caller should then start the OAuth Flow again with
    /// the desired scope.
    open func getAccessToken(scope: String) throws -> AccessTokenInfo {
        let ptr = try rustCall { err in
            fxa_get_access_token(self.raw, scope, err)
        }
        defer { fxa_bytebuffer_free(ptr) }
        let msg = try! MsgTypes_AccessTokenInfo(serializedData: Data(rustBuffer: ptr))
        return AccessTokenInfo(msg: msg)
    }

    /// Get the session token. If non-present an error will be thrown.
    open func getSessionToken() throws -> String {
        let ptr = try rustCall { err in
            fxa_get_session_token(self.raw, err)
        }
        return String(freeingFxaString: ptr)
    }

    /// Check whether the refreshToken is active
    open func checkAuthorizationStatus() throws -> IntrospectInfo {
        let ptr = try rustCall { err in
            fxa_check_authorization_status(self.raw, err)
        }
        defer { fxa_bytebuffer_free(ptr) }
        let msg = try! MsgTypes_IntrospectInfo(serializedData: Data(rustBuffer: ptr))
        return IntrospectInfo(msg: msg)
    }

    /// This method should be called when a request made with
    /// an OAuth token failed with an authentication error.
    /// It clears the internal cache of OAuth access tokens,
    /// so the caller can try to call `getAccessToken` or `getProfile`
    /// again.
    open func clearAccessTokenCache() throws {
        try rustCall { err in
            fxa_clear_access_token_cache(self.raw, err)
        }
    }

    /// Disconnect from the account and optionaly destroy our device record.
    /// `beginOAuthFlow(...)` will need to be called to reconnect.
    open func disconnect() throws {
        try rustCall { err in
            fxa_disconnect(self.raw, err)
        }
    }

    open func fetchDevices() throws -> [Device] {
        let ptr = try rustCall { err in
            fxa_get_devices(self.raw, err)
        }
        defer { fxa_bytebuffer_free(ptr) }
        let msg = try! MsgTypes_Devices(serializedData: Data(rustBuffer: ptr))
        return Device.fromCollectionMsg(msg: msg)
    }

    open func setDeviceDisplayName(_ name: String) throws {
        try rustCall { err in
            fxa_set_device_name(self.raw, name, err)
        }
    }

    open func pollDeviceCommands() throws -> [IncomingDeviceCommand] {
        let ptr = try rustCall { err in
            fxa_poll_device_commands(self.raw, err)
        }
        defer { fxa_bytebuffer_free(ptr) }
        let msg = try! MsgTypes_IncomingDeviceCommands(serializedData: Data(rustBuffer: ptr))
        return IncomingDeviceCommand.fromCollectionMsg(msg: msg)
    }

    open func handlePushMessage(payload: String) throws -> [AccountEvent] {
        let ptr = try rustCall { err in
            fxa_handle_push_message(self.raw, payload, err)
        }
        defer { fxa_bytebuffer_free(ptr) }
        let msg = try! MsgTypes_AccountEvents(serializedData: Data(rustBuffer: ptr))
        return AccountEvent.fromCollectionMsg(msg: msg)
    }

    open func sendSingleTab(targetId: String, title: String, url: String) throws {
        try rustCall { err in
            fxa_send_tab(self.raw, targetId, title, url, err)
        }
    }

    open func setDevicePushSubscription(endpoint: String, publicKey: String, authKey: String) throws {
        try rustCall { err in
            fxa_set_push_subscription(self.raw, endpoint, publicKey, authKey, err)
        }
    }

    open func initializeDevice(
        name: String,
        deviceType: DeviceType,
        supportedCapabilities: [DeviceCapability]
    ) throws {
        let (data, size) = msgToBuffer(msg: supportedCapabilities.toCollectionMsg())
        try data.withUnsafeBytes { bytes in
            try rustCall { err in
                fxa_initialize_device(
                    self.raw,
                    name,
                    Int32(deviceType.toMsg().rawValue),
                    bytes.bindMemory(to: UInt8.self).baseAddress!,
                    size,
                    err
                )
            }
        }
    }

    open func ensureCapabilities(supportedCapabilities: [DeviceCapability]) throws {
        let (data, size) = msgToBuffer(msg: supportedCapabilities.toCollectionMsg())
        try data.withUnsafeBytes { bytes in
            try rustCall { err in
                fxa_ensure_capabilities(
                    self.raw,
                    bytes.bindMemory(to: UInt8.self).baseAddress!,
                    size,
                    err
                )
            }
        }
    }

    open func migrateFromSessionToken(sessionToken: String, kSync: String, kXCS: String) throws -> Bool {
        let json = try nullableRustCall { err in
            fxa_migrate_from_session_token(self.raw, sessionToken, kSync, kXCS, 0 /* reuse session token */, err)
        }
        // We don't parse the JSON coz nobody uses it...
        return json != nil
    }

    open func retryMigrateFromSessionToken() throws -> Bool {
        let json = try nullableRustCall { err in
            fxa_retry_migrate_from_session_token(self.raw, err)
        }
        return json != nil
    }

    open func isInMigrationState() throws -> Bool {
        let number = try rustCall { err in
            fxa_is_in_migration_state(self.raw, err)
        }
        let state = MigrationState.fromNumber(number)
        // We never initiate a "copy-session-token" migration,
        // so we can just return a boolean.
        return state == .reuseSessionToken
    }

    open func handleSessionTokenChange(sessionToken: String) throws {
        try rustCall { err in
            fxa_handle_session_token_change(self.raw, sessionToken, err)
        }
    }

    private func msgToBuffer(msg: SwiftProtobuf.Message) -> (Data, Int32) {
        let data = try! msg.serializedData()
        let size = Int32(data.count)
        return (data, size)
    }
}

// This queue serves as a semaphore to the rust layer.
private let fxaRustQueue = DispatchQueue(label: "com.mozilla.fxa-rust")

internal func rustCall<T>(_ cb: (UnsafeMutablePointer<FxAError>) throws -> T?) throws -> T {
    return try FirefoxAccountError.unwrap { err in
        try fxaRustQueue.sync {
            try cb(err)
        }
    }
}

internal func nullableRustCall<T>(_ cb: (UnsafeMutablePointer<FxAError>) throws -> T?) throws -> T? {
    return try FirefoxAccountError.tryUnwrap { err in
        try fxaRustQueue.sync {
            try cb(err)
        }
    }
}
