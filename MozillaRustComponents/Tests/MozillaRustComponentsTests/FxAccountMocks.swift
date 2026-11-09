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
        case processEvent
    }

    /// Controls what state `processEvent(.initialize)` returns.
    /// Set to `.connected` for a restored account, `.disconnected` for no account,
    /// `.authIssues` for a restored account with auth problems.
    var initializeResult: FxaState = .disconnected
    /// Events received by `processEvent`, in order.
    var processedEvents = [FxaEvent]()
    /// Last state returned by `processEvent`, mirroring the Rust state machine's own tracking.
    private(set) var currentState: FxaState = .uninitialized

    init() {
        super.init(inner: FirefoxAccount(config: FxaConfig(server: FxaServer.custom(url: ""), clientId: "", redirectUri: "", tokenServerUrlOverride: nil)))
    }

    required convenience init(fromJsonState _: String) throws {
        fatalError("init(fromJsonState:) has not been implemented")
    }

    required convenience init(config _: FxAConfig) {
        fatalError("init(config:) has not been implemented")
    }

    override func processEvent(event: FxaEvent) throws -> FxaState {
        queue.sync {
            invocations.append(.processEvent)
            processedEvents.append(event)
        }
        let newState = try transition(event: event)
        queue.sync { currentState = newState }
        return newState
    }

    private func transition(event: FxaEvent) throws -> FxaState {
        switch event {
        case .initialize:
            return initializeResult
        case .beginOAuthFlow:
            return .authenticating(oauthUrl: "https://foo.bar/oauth?state=bobo", initialState: .disconnected)
        case .beginPairingFlow:
            // Mirrors the Rust state machine, which has no `AuthIssues -> BeginPairingFlow` transition.
            if currentState == .authIssues {
                throw FxaError.Other(message: "Invalid state transition: AuthIssues -> BeginPairingFlow")
            }
            return .authenticating(oauthUrl: "https://foo.bar/oauth?state=bobo", initialState: .disconnected)
        case let .completeOAuthFlow(_, state):
            // Simulate Rust's OAuth state validation
            return state == "bobo" ? .connected : .disconnected
        case .cancelOAuthFlow:
            return .disconnected
        case .checkAuthorizationStatus:
            let info = try checkAuthorizationStatus()
            return info.active ? .connected : .authIssues
        case .disconnect:
            return .disconnected
        case .callGetProfile, .webChannelPasswordChange:
            return .connected
        }
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
}

final class MockFxAccountManager: FxAccountManager, @unchecked Sendable {
    var storedAccount: MockFxAccount?

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
        case refreshState
    }

    override init(account: PersistedFirefoxAccount?) {
        super.init(account: account ?? MockFxAccount())
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
