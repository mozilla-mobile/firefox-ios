// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Shared
import TestKit
import XCTest

@testable import VPNKit

final class VPNTokenProviderTests: XCTestCase {
    // MARK: - Establishing a session

    func test_proxyToken_authenticates_whenNoSessionStored() async throws {
        let auth = MockVPNAuthenticating(session: nil)
        let fetcher = MockVPNProxyTokenFetching(tokenToReturn: token())
        let subject = VPNTokenProvider(authService: auth, tokenService: fetcher)

        let result = try await subject.proxyToken()

        XCTAssertEqual(result.token, "proxy-token")
        XCTAssertEqual(auth.authenticateCallCount, 1, "Must establish a session before exchanging it")
        XCTAssertEqual(fetcher.fetchCallCount, 1)
    }

    func test_proxyToken_propagatesAuthenticationFailure_withoutFetching() async throws {
        let auth = MockVPNAuthenticating()
        auth.authenticateError = VPNAuthError.notEnrolled
        let fetcher = MockVPNProxyTokenFetching(tokenToReturn: token())
        let subject = VPNTokenProvider(authService: auth, tokenService: fetcher)

        do {
            _ = try await subject.proxyToken()
            XCTFail("Expected the authentication failure to surface.")
        } catch let error as VPNAuthError {
            XCTAssertEqual(error, .notEnrolled, "Callers need to tell enrollment loss from an outage")
        }

        XCTAssertEqual(fetcher.fetchCallCount, 0, "No point exchanging a session we never got")
    }

    func test_proxyToken_propagatesFetchFailure() async throws {
        let auth = MockVPNAuthenticating()
        let fetcher = MockVPNProxyTokenFetching(tokenToReturn: token())
        fetcher.fetchError = URLError(.notConnectedToInternet)
        let subject = VPNTokenProvider(authService: auth, tokenService: fetcher)

        do {
            _ = try await subject.proxyToken()
            XCTFail("Expected the transport failure to surface.")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }
    }

    func test_proxyToken_fetchesEveryTime() async throws {
        let auth = MockVPNAuthenticating()
        let fetcher = MockVPNProxyTokenFetching(tokenToReturn: token())
        let subject = VPNTokenProvider(authService: auth, tokenService: fetcher)

        _ = try await subject.proxyToken()
        _ = try await subject.proxyToken()

        XCTAssertEqual(fetcher.fetchCallCount, 2)
    }

    // MARK: - Construction via VPNAuthCreator

    func test_makeTokenProvider_returnsProvider() {
        XCTAssertNotNil(createCreator().makeTokenProvider(using: prefs))
    }

    func test_makeTokenProvider_returnsNil_whenAppAttestUnsupported() {
        let creator = createCreator(appAttestService: MockAppAttestService(isSupported: false))

        XCTAssertNil(creator.makeTokenProvider(using: prefs))
    }

    /// Building the provider resolves the environment once, so the credential reset that resolution
    /// can trigger happens once too.
    func test_makeTokenProvider_resetsCredentialsOnce_whenEnvironmentChanged() throws {
        try tokenStore.save(session)
        prefs.setString(VPNEnvironment.dev.rawValue, forKey: PrefsKeys.VPNSettings.lastUsedEnvironment)

        _ = createCreator().makeTokenProvider(using: prefs)

        XCTAssertEqual(tokenStore.clearCallCount, 1)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.VPNSettings.lastUsedEnvironment), VPNEnvironment.prod.rawValue)
    }

    // MARK: - Helpers

    // XCTest builds a fresh instance per test method, so these are already isolated.
    private let keyStore = MockAppAttestKeyIDStore()
    private let tokenStore = MockVPNTokenStore()
    private let prefs = MockProfilePrefs()

    private func createCreator(
        appAttestService: AppAttestServiceProtocol = MockAppAttestService(isSupported: true)
    ) -> VPNAuthCreator {
        return VPNAuthCreator(keyStore: keyStore, appAttestService: appAttestService, tokenStore: tokenStore)
    }

    private var session: VPNDeviceSession {
        VPNDeviceSession(
            deviceSessionJwt: "dsj",
            expiresAtMilliseconds: 32503680000000,
            renewAfterMilliseconds: 32503600000000
        )
    }

    private func token(value: String = "proxy-token", expiresIn: Int = 600) -> VPNProxyToken {
        return VPNProxyToken(token: value, expiresIn: expiresIn)
    }
}

// MARK: - Test doubles

private final class MockVPNAuthenticating: VPNAuthenticating, @unchecked Sendable {
    var session: VPNDeviceSession?
    var authenticateError: Error?

    private(set) var authenticateCallCount = 0

    init(session: VPNDeviceSession? = nil) {
        self.session = session
    }

    func authenticate() async throws -> String {
        authenticateCallCount += 1
        if let authenticateError { throw authenticateError }
        return session?.deviceSessionJwt ?? "dsj"
    }

    func refresh() async throws -> String {
        return try await authenticate()
    }

    func reset() throws {
        session = nil
    }

    func currentSession() -> VPNDeviceSession? {
        return session
    }
}
