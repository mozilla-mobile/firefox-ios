/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import MozillaRustComponents
@testable import MozillaAppServices

// Arrays are not thread-safe in Swift.
let queue = DispatchQueue(label: "InvocationsArrayQueue")

class MockFxAccount: PersistedFirefoxAccount {
    var invocations: [MethodInvocation] = []
    enum MethodInvocation {
        case checkAuthorizationStatus
        case ensureCapabilities
        case getProfile
        case registerPersistCallback
        case clearAccessTokenCache
        case getAccessToken
        case initializeDevice
        case getDevices
    }

    init() {
        super.init(inner: FirefoxAccount(config: FxaConfig(server: FxaServer.custom(url: ""), clientId: "", redirectUri: "", tokenServerUrlOverride: nil)))
    }

    required convenience init(fromJsonState _: String) throws {
        fatalError("init(fromJsonState:) has not been implemented")
    }

    required convenience init(config _: FxAConfig) {
        fatalError("init(config:) has not been implemented")
    }

    override func initializeDevice(name _: String, deviceType _: DeviceType, supportedCapabilities _: [DeviceCapability]) throws {
        queue.sync { invocations.append(.initializeDevice) }
    }

    override func getDevices(ignoreCache _: Bool) throws -> [Device] {
        queue.sync { invocations.append(.getDevices) }
        return []
    }

    override func registerPersistCallback(_: PersistCallback) {
        queue.sync { invocations.append(.registerPersistCallback) }
    }

    override func ensureCapabilities(supportedCapabilities _: [DeviceCapability]) throws {
        queue.sync { invocations.append(.ensureCapabilities) }
    }

    override func checkAuthorizationStatus() throws -> AuthorizationInfo {
        queue.sync { invocations.append(.checkAuthorizationStatus) }
        return AuthorizationInfo(active: true)
    }

    override func clearAccessTokenCache() {
        queue.sync { invocations.append(.clearAccessTokenCache) }
    }

    override func getAccessToken(scope _: String, useCache _: Bool? = true) throws -> AccessTokenInfo {
        queue.sync { invocations.append(.getAccessToken) }
        return AccessTokenInfo(scope: "profile", token: "toktok", key: nil, expiresAt: Int64.max)
    }

    override func getProfile(ignoreCache _: Bool) throws -> Profile {
        queue.sync { invocations.append(.getProfile) }
        return Profile(uid: "uid", email: "foo@bar.bobo", displayName: "Bobo the Foo", avatar: "https://example.com/avatar.png", isDefaultAvatar: false)
    }

    override func beginOAuthFlow(
        scopes _: [String],
        entrypoint _: String
    ) throws -> URL {
        return URL(string: "https://foo.bar/oauth?state=bobo")!
    }
}

final class MockFxAccountManager: FxAccountManager, @unchecked Sendable {
    var storedAccount: PersistedFirefoxAccount?

    override func createAccount() -> PersistedFirefoxAccount {
        return MockFxAccount()
    }

    override func makeDeviceConstellation(account _: PersistedFirefoxAccount) -> DeviceConstellation {
        return MockDeviceConstellation(account: account)
    }

    override func tryRestoreAccount() -> PersistedFirefoxAccount? {
        return storedAccount
    }
}

final class MockDeviceConstellation: DeviceConstellation, @unchecked Sendable {
    var invocations: [MethodInvocation] = []
    enum MethodInvocation {
        case ensureCapabilities
        case initDevice
        case refreshState
    }

    override init(account: PersistedFirefoxAccount?) {
        super.init(account: account ?? MockFxAccount())
    }

    override func initDevice(name: String, type: DeviceType, capabilities: [DeviceCapability]) {
        queue.sync { invocations.append(.initDevice) }
        super.initDevice(name: name, type: type, capabilities: capabilities)
    }

    override func ensureCapabilities(capabilities: [DeviceCapability]) {
        queue.sync { invocations.append(.ensureCapabilities) }
        super.ensureCapabilities(capabilities: capabilities)
    }

    override func refreshState() {
        queue.sync { invocations.append(.refreshState) }
        super.refreshState()
    }
}

func mockFxAManager() -> MockFxAccountManager {
    return MockFxAccountManager(
        config: FxAConfig(server: .release, clientId: "clientid", redirectUri: "redirect"),
        deviceConfig: DeviceConfig(name: "foo", type: .mobile, capabilities: [])
    )
}
