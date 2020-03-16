/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import MozillaAppServices

class MockFxAccount: FxAccount {
    var invocations: [MethodInvocation] = []
    enum MethodInvocation {
        case checkAuthorizationStatus
        case ensureCapabilities
        case getProfile
        case registerPersistCallback
        case clearAccessTokenCache
        case getAccessToken
        case initializeDevice
        case fetchDevices
    }

    init() {
        super.init(raw: 0)
    }

    required convenience init(fromJsonState _: String) throws {
        fatalError("init(fromJsonState:) has not been implemented")
    }

    required convenience init(config _: FxAConfig) throws {
        fatalError("init(config:) has not been implemented")
    }

    override func initializeDevice(name _: String, deviceType _: DeviceType, supportedCapabilities _: [DeviceCapability]) throws {
        invocations.append(.initializeDevice)
    }

    override func fetchDevices() throws -> [Device] {
        invocations.append(.fetchDevices)
        return []
    }

    override func registerPersistCallback(_: PersistCallback) {
        invocations.append(.registerPersistCallback)
    }

    override func ensureCapabilities(supportedCapabilities _: [DeviceCapability]) throws {
        invocations.append(.ensureCapabilities)
    }

    override func checkAuthorizationStatus() throws -> IntrospectInfo {
        invocations.append(.checkAuthorizationStatus)
        return IntrospectInfo(active: true, tokenType: "refresh_token")
    }

    override func clearAccessTokenCache() throws {
        invocations.append(.clearAccessTokenCache)
    }

    override func getAccessToken(scope _: String) throws -> AccessTokenInfo {
        invocations.append(.getAccessToken)
        return AccessTokenInfo(scope: "profile", token: "toktok")
    }

    override func getProfile() throws -> Profile {
        invocations.append(.getProfile)
        return Profile(uid: "uid", email: "foo@bar.bobo")
    }

    override func beginOAuthFlow(scopes _: [String]) throws -> URL {
        return URL(string: "https://foo.bar/oauth?state=bobo")!
    }
}

class MockFxAccountManager: FxAccountManager {
    var invocations: [MethodInvocation] = []
    enum MethodInvocation {}

    var storedAccount: FxAccount?

    override func createAccount() -> FxAccount {
        return MockFxAccount()
    }

    override func makeDeviceConstellation(account _: FxAccount) -> DeviceConstellation {
        return MockDeviceConstellation(account: account)
    }

    override func tryRestoreAccount() -> FxAccount? {
        return storedAccount
    }
}

class MockDeviceConstellation: DeviceConstellation {
    var invocations: [MethodInvocation] = []
    enum MethodInvocation {
        case ensureCapabilities
        case initDevice
        case refreshState
    }

    override init(account: FxAccount?) {
        super.init(account: account ?? MockFxAccount())
    }

    override func initDevice(name: String, type: DeviceType, capabilities: [DeviceCapability]) {
        invocations.append(.initDevice)
        super.initDevice(name: name, type: type, capabilities: capabilities)
    }

    override func ensureCapabilities(capabilities: [DeviceCapability]) {
        invocations.append(.ensureCapabilities)
        super.ensureCapabilities(capabilities: capabilities)
    }

    override func refreshState() {
        invocations.append(.refreshState)
        super.refreshState()
    }
}

func mockFxAManager() -> MockFxAccountManager {
    return MockFxAccountManager(
        config: .release(clientId: "clientid", redirectUri: "redirect"),
        deviceConfig: DeviceConfig(name: "foo", type: .mobile, capabilities: [])
    )
}
