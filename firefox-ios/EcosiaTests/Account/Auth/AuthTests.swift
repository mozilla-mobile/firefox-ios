// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia
import WebKit
// swiftlint:disable implicitly_unwrapped_optional

@MainActor
final class AuthTests: XCTestCase {

    var auth: EcosiaAuthenticationService!
    var mockProvider: MockAuth0Provider!

    override func setUp() {
        super.setUp()
        mockProvider = MockAuth0Provider()
        auth = EcosiaAuthenticationService(auth0Provider: mockProvider)
        auth.skipUserInfoFetch = true
    }

    override func tearDown() {
        mockProvider?.reset()
        mockProvider = nil
        auth = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_withDefaultProvider_createsAuthInstance() {
        // Arrange
        // Act
        let auth = EcosiaAuthenticationService()

        // Assert
        XCTAssertNotNil(auth)
        XCTAssertNotNil(auth.auth0Provider)
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    func testInit_withCustomProvider_usesProvidedProvider() {
        // Arrange
        let customProvider = MockAuth0Provider()

        // Act
        let auth = EcosiaAuthenticationService(auth0Provider: customProvider)

        // Assert
        XCTAssertNotNil(auth)
        XCTAssertTrue(auth.auth0Provider is MockAuth0Provider)
    }

    // MARK: - Login Tests

    func testLogin_withSuccessfulAuth_storesCredentialsAndUpdatesState() async {
        // Arrange
        let expectedCredentials = Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: "test-id-token",
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockProvider.mockCredentials = expectedCredentials

        // Act
        do {
            let accountOrigin = try await auth.login()
            // Default mock ID token doesn't contain the custom claim, so it defaults to existing
            XCTAssertEqual(accountOrigin, .existingAccount)
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert
        XCTAssertEqual(mockProvider.startAuthCallCount, 1)
        XCTAssertEqual(mockProvider.lastAuthScreenHint, .login)
        XCTAssertEqual(mockProvider.storeCredentialsCallCount, 1)
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertEqual(auth.idToken, expectedCredentials.idToken)
        XCTAssertEqual(auth.accessToken, expectedCredentials.accessToken)
        XCTAssertEqual(auth.refreshToken, expectedCredentials.refreshToken)
    }

    func testSignUp_usesSignUpScreenHint() async {
        // Arrange
        mockProvider.mockCredentials = Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: "test-id-token",
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )

        // Act
        do {
            _ = try await auth.signUp()
        } catch {
            XCTFail("Sign up should succeed, but failed with: \(error)")
            return
        }

        // Assert
        XCTAssertEqual(mockProvider.startAuthCallCount, 1)
        XCTAssertEqual(mockProvider.lastAuthScreenHint, .signUp)
    }

    func testLogin_withAuthFailure_doesNotUpdateState() async {
        // Arrange
        mockProvider.shouldFailAuth = true
        let initialLoginState = auth.isLoggedIn

        // Act
        do {
            try await auth.login()
            XCTFail("Expected login to throw but it didn't")
        } catch {
            // Expected to fail
        }

        // Assert
        XCTAssertEqual(mockProvider.startAuthCallCount, 1)
        XCTAssertEqual(mockProvider.storeCredentialsCallCount, 0)
        XCTAssertEqual(auth.isLoggedIn, initialLoginState)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    func testLogin_withStoreCredentialsFailure_doesNotUpdateState() async {
        // Arrange
        mockProvider.shouldFailStoreCredentials = true
        let initialLoginState = auth.isLoggedIn

        // Act
        do {
            try await auth.login()
            XCTFail("Expected login to throw but it didn't")
        } catch {
            // Expected to fail
        }

        // Assert
        XCTAssertEqual(mockProvider.startAuthCallCount, 1)
        XCTAssertEqual(mockProvider.storeCredentialsCallCount, 1)
        XCTAssertEqual(auth.isLoggedIn, initialLoginState)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    // MARK: - Account Origin Tests

    func testLogin_withNewlyCreatedAccount_returnsNewAccount() async throws {
        // Arrange — created_at within seconds of iat indicates a freshly created account
        let now = Date()
        let idToken = try makeJWT(claims: [
            "iat": now.timeIntervalSince1970,
            "https://ecosia.org/created_at": Self.iso8601Formatter.string(from: now.addingTimeInterval(-2))
        ])
        let credentials = Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: idToken,
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockProvider.mockCredentials = credentials

        // Act
        do {
            let accountOrigin = try await auth.login()

            // Assert
            XCTAssertEqual(accountOrigin, .newAccount)
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }
    }

    func testLogin_withExistingAccount_returnsExistingAccount() async throws {
        // Arrange — created_at well before iat indicates an existing account
        let now = Date()
        let idToken = try makeJWT(claims: [
            "iat": now.timeIntervalSince1970,
            "https://ecosia.org/created_at": Self.iso8601Formatter.string(from: now.addingTimeInterval(-86400))
        ])
        let credentials = Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: idToken,
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockProvider.mockCredentials = credentials

        // Act
        do {
            let accountOrigin = try await auth.login()

            // Assert
            XCTAssertEqual(accountOrigin, .existingAccount)
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }
    }

    func testLogin_withMissingCreatedAtClaim_defaultsToExistingAccount() async throws {
        // Arrange — JWT without the https://ecosia.org/created_at claim
        let idToken = try makeJWT(claims: [
            "sub": "auth0|12345",
            "iat": Date().timeIntervalSince1970
        ])
        let credentials = Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: idToken,
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockProvider.mockCredentials = credentials

        // Act
        do {
            let accountOrigin = try await auth.login()

            // Assert
            XCTAssertEqual(accountOrigin, .existingAccount)
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }
    }

    // MARK: - Logout Tests

    func testLogout_withTriggerWebLogout_clearsSessionAndCredentials() async {
        // Arrange
        await setupLoggedInState()

        // Act
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        XCTAssertEqual(mockProvider.clearSessionCallCount, 1)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    func testLogout_withoutTriggerWebLogout_clearsCredentialsOnly() async {
        // Arrange
        await setupLoggedInState()

        // Act
        do {
            try await auth.logout(triggerWebLogout: false)
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        XCTAssertEqual(mockProvider.clearSessionCallCount, 0)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    func testLogout_withClearSessionFailure_stillClearsCredentials() async {
        // Arrange
        await setupLoggedInState()
        mockProvider.shouldFailClearSession = true

        // Act
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        XCTAssertEqual(mockProvider.clearSessionCallCount, 1)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    func testLogout_withClearCredentialsFailure_maintainsLoggedInState() async {
        // Arrange
        await setupLoggedInState()
        mockProvider.clearCredentialsResult = false

        // Act
        do {
            try await auth.logout()
            XCTFail("Expected logout to throw but it didn't")
        } catch {
            // Expected to fail
        }

        // Assert
        XCTAssertEqual(mockProvider.clearSessionCallCount, 1)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotNil(auth.idToken)
        XCTAssertNotNil(auth.accessToken)
        XCTAssertNotNil(auth.refreshToken)
    }

    // MARK: - Retrieve Stored Credentials Tests

    func testRetrieveStoredCredentials_withValidCredentials_updatesState() async {
        // Arrange
        let expectedCredentials = Credentials(
            accessToken: "stored-access-token",
            tokenType: "Bearer",
            idToken: "stored-id-token",
            refreshToken: "stored-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockProvider.mockCredentials = expectedCredentials
        mockProvider.hasStoredCredentials = true  // Simulate stored credentials

        await waitForInitCredentialRetrieval()

        // Act
        await auth.retrieveStoredCredentials()

        // Assert
        // retrieveCredentials is called twice: once during Auth init and once explicitly
        XCTAssertEqual(mockProvider.retrieveCredentialsCallCount, 2)
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertEqual(auth.idToken, expectedCredentials.idToken)
        XCTAssertEqual(auth.accessToken, expectedCredentials.accessToken)
        XCTAssertEqual(auth.refreshToken, expectedCredentials.refreshToken)
    }

    func testRetrieveStoredCredentials_withFailure_maintainsLoggedOutState() async {
        // Arrange
        mockProvider.shouldFailRetrieveCredentials = true

        await waitForInitCredentialRetrieval()

        // Act
        await auth.retrieveStoredCredentials()

        // Assert
        // retrieveCredentials is called twice: once during Auth init and once explicitly
        XCTAssertEqual(mockProvider.retrieveCredentialsCallCount, 2)
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    // MARK: - Renew Credentials Tests

    func testRenewCredentialsIfNeeded_withRenewableCredentials_renewsAndUpdatesState() async {
        // Arrange
        await setupLoggedInState()
        mockProvider.canRenewCredentialsResult = true
        let renewedCredentials = Credentials(
            accessToken: "renewed-access-token",
            tokenType: "Bearer",
            idToken: "renewed-id-token",
            refreshToken: "renewed-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockProvider.mockCredentials = renewedCredentials

        // Act
        do {
            try await auth.renewCredentialsIfNeeded()
        } catch {
            XCTFail("Renew credentials should succeed, but failed with: \(error)")
        }

        // Assert
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)
        XCTAssertEqual(mockProvider.renewCredentialsCallCount, 1)
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertEqual(auth.idToken, renewedCredentials.idToken)
        XCTAssertEqual(auth.accessToken, renewedCredentials.accessToken)
        XCTAssertEqual(auth.refreshToken, renewedCredentials.refreshToken)
    }

    func testRenewCredentialsIfNeeded_withNonRenewableCredentials_doesNotRenew() async {
        // Arrange
        await setupLoggedInState()
        mockProvider.canRenewCredentialsResult = false
        let originalIdToken = auth.idToken

        // Act
        do {
            try await auth.renewCredentialsIfNeeded()
        } catch {
            XCTFail("Renew credentials should succeed, but failed with: \(error)")
        }

        // Assert
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)
        XCTAssertEqual(mockProvider.renewCredentialsCallCount, 0)
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertEqual(auth.idToken, originalIdToken)
    }

    func testRenewCredentialsIfNeeded_withRenewFailure_maintainsCurrentState() async {
        // Arrange
        await setupLoggedInState()
        mockProvider.canRenewCredentialsResult = true
        mockProvider.shouldFailRenewCredentials = true
        let originalIdToken = auth.idToken
        let originalAccessToken = auth.accessToken
        let originalRefreshToken = auth.refreshToken

        // Act
        do {
            try await auth.renewCredentialsIfNeeded()
        } catch {
            // This test expects renewal to fail, so we should catch the error
            // but the test should continue to verify the state is maintained
        }

        // Assert
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)
        XCTAssertEqual(mockProvider.renewCredentialsCallCount, 1)
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertEqual(auth.idToken, originalIdToken)
        XCTAssertEqual(auth.accessToken, originalAccessToken)
        XCTAssertEqual(auth.refreshToken, originalRefreshToken)
    }

    // MARK: - SSO Methods Tests

    func testGetSessionTransferToken_withLoggedInUser_retrievesSSOCredentials() async {
        // Arrange
        await setupLoggedInState()

        // Note: Due to the type check in Auth.retrieveSSOCredentials(), the mock provider
        // won't be recognized as a NativeToWebSSOAuth0Provider, so getSSOCredentials won't be called
        // In a real implementation, we would need integration tests or a different mocking strategy

        // Act
        await auth.getSessionTransferToken()

        // Assert
        XCTAssertTrue(auth.isLoggedIn)
        // The ssoCredentials will be nil because the type check in Auth.swift fails with the mock
        // This demonstrates that the method completes without error even when SSO is not available
        XCTAssertNil(auth.ssoCredentials)
    }

    func testGetSessionTransferToken_withLoggedOutUser_doesNotRetrieveCredentials() async {
        // Arrange
        XCTAssertFalse(auth.isLoggedIn)

        // Act
        await auth.getSessionTransferToken()

        // Assert
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.ssoCredentials)
    }

    func testGetSessionTokenCookie_withLoggedOutUser_returnsNil() {
        // Arrange
        XCTAssertFalse(auth.isLoggedIn)

        // Act
        let cookie = auth.getSessionTokenCookie()

        // Assert
        XCTAssertNil(cookie)
    }

    func testGetSessionTokenCookie_withLoggedInUserButNoSSOCredentials_returnsNil() async {
        // Arrange
        await setupLoggedInState()

        // Act
        let cookie = auth.getSessionTokenCookie()

        // Assert
        XCTAssertNil(cookie)
    }

    // MARK: - Integration Tests

    func testCompleteAuthFlow_loginLogoutCycle_worksCorrectly() async {
        // Arrange
        XCTAssertFalse(auth.isLoggedIn)

        // Act - Login
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert - Logged in
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotNil(auth.idToken)
        XCTAssertNotNil(auth.accessToken)
        XCTAssertNotNil(auth.refreshToken)

        // Act - Logout
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert - Logged out
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    func testCompleteAuthFlow_loginRenewLogoutCycle_worksCorrectly() async {
        // Arrange
        mockProvider.canRenewCredentialsResult = true

        // Act - Login
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }
        let originalIdToken = auth.idToken

        // Assert - Logged in
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotNil(originalIdToken)

        // Act - Renew
        let renewedCredentials = Credentials(
            accessToken: "renewed-access-token",
            tokenType: "Bearer",
            idToken: "renewed-id-token",
            refreshToken: "renewed-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockProvider.mockCredentials = renewedCredentials
        do {
            try await auth.renewCredentialsIfNeeded()
        } catch {
            XCTFail("Renew credentials should succeed, but failed with: \(error)")
        }

        // Assert - Credentials renewed
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotEqual(auth.idToken, originalIdToken)
        XCTAssertEqual(auth.idToken, renewedCredentials.idToken)

        // Act - Logout
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert - Logged out
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
    }

    // MARK: - Helper Methods

    /// ISO 8601 formatter with fractional seconds, matching the format Auth0 uses for `created_at`.
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private func setupLoggedInState() async {
        let credentials = Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: "test-id-token",
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockProvider.mockCredentials = credentials
        mockProvider.hasStoredCredentials = true  // Simulate having stored credentials

        do {
            try await auth.login()
        } catch {
            XCTFail("Login should not fail in test setup: \(error)")
        }

        mockProvider.startAuthCallCount = 0
        mockProvider.storeCredentialsCallCount = 0
    }

    /// Creates a minimal valid JWT string with the given payload claims.
    ///
    /// The token has the structure `header.payload.signature` where header and payload
    /// are Base64URL-encoded JSON. The signature is a placeholder since we don't verify it.
    private func makeJWT(claims: [String: Any]) throws -> String {
        let header = #"{"alg":"RS256","typ":"JWT"}"#
        let payloadData = try JSONSerialization.data(withJSONObject: claims)
        let payload = try XCTUnwrap(String(data: payloadData, encoding: .utf8))

        func base64URLEncode(_ string: String) -> String {
            Data(string.utf8)
                .base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }

        return "\(base64URLEncode(header)).\(base64URLEncode(payload)).mock-signature"
    }

    private func waitForInitCredentialRetrieval(
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(1)
        while mockProvider.retrieveCredentialsCallCount < 1 && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertEqual(
            mockProvider.retrieveCredentialsCallCount,
            1,
            "Expected init-time credential retrieval before explicit test call",
            file: file,
            line: line
        )
    }
}
// swiftlint:enable implicitly_unwrapped_optional
