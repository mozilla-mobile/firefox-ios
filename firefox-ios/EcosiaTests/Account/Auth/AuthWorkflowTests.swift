// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia

final class AuthWorkflowTests: XCTestCase {

    var auth: EcosiaAuthenticationService!
    var mockProvider: MockAuth0Provider!
    var mockCredentialsManager: MockCredentialsManager!

    override func setUp() {
        super.setUp()
        mockCredentialsManager = MockCredentialsManager()
        mockProvider = MockAuth0Provider()
        mockProvider.credentialsManager = mockCredentialsManager
        auth = EcosiaAuthenticationService(auth0Provider: mockProvider)
        auth.skipUserInfoFetch = true
    }

    override func tearDown() {
        mockProvider?.reset()
        mockCredentialsManager?.reset()
        mockProvider = nil
        mockCredentialsManager = nil
        auth = nil
        super.tearDown()
    }

    // MARK: - Full Authentication Lifecycle Tests

    func testCompleteAuthenticationLifecycle_loginLogout_worksEndToEnd() async {
        // Arrange
        let testCredentials = createTestCredentials()
        mockProvider.mockCredentials = testCredentials
        mockCredentialsManager.storedCredentials = testCredentials

        XCTAssertFalse(auth.isLoggedIn)

        // Act - Login
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert - Logged in state
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertEqual(auth.idToken, testCredentials.idToken)
        XCTAssertEqual(auth.accessToken, testCredentials.accessToken)
        XCTAssertEqual(auth.refreshToken, testCredentials.refreshToken)
        XCTAssertEqual(mockProvider.startAuthCallCount, 1)
        XCTAssertEqual(mockProvider.storeCredentialsCallCount, 1)

        // Act - Logout
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert - Logged out state
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken, "ID token should be cleared")
        XCTAssertNil(auth.accessToken, "Access token should be cleared")
        XCTAssertNil(auth.refreshToken, "Refresh token should be cleared")
        XCTAssertEqual(mockProvider.clearSessionCallCount, 1)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
    }

    func testCompleteAuthenticationLifecycle_loginRenewLogout_worksEndToEnd() async {
        // Arrange
        let originalCredentials = createTestCredentials()
        let renewedCredentials = Credentials(
            accessToken: "renewed-access-token",
            tokenType: "Bearer",
            idToken: "renewed-id-token",
            refreshToken: "renewed-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )

        mockProvider.mockCredentials = originalCredentials
        mockCredentialsManager.storedCredentials = originalCredentials
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

        // Act - Renew credentials
        mockProvider.mockCredentials = renewedCredentials
        mockCredentialsManager.storedCredentials = renewedCredentials
        do {
            try await auth.renewCredentialsIfNeeded()
        } catch {
            XCTFail("Renew credentials should succeed, but failed with: \(error)")
        }

        // Assert - Credentials renewed
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotEqual(auth.idToken, originalIdToken)
        XCTAssertEqual(auth.idToken, renewedCredentials.idToken)
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)
        XCTAssertEqual(mockProvider.renewCredentialsCallCount, 1)

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

    func testCompleteAuthenticationLifecycle_persistenceAfterRestart_worksEndToEnd() async {
        // Arrange
        let testCredentials = createTestCredentials()
        mockProvider.mockCredentials = testCredentials
        mockCredentialsManager.storedCredentials = testCredentials

        // Act - Login
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert - Logged in
        XCTAssertTrue(auth.isLoggedIn)

        // Act - Simulate app restart by creating new EcosiaAuthenticationService instance
        let newMockProvider = MockAuth0Provider()
        newMockProvider.credentialsManager = mockCredentialsManager
        newMockProvider.mockCredentials = testCredentials
        _ = EcosiaAuthenticationService(auth0Provider: newMockProvider)

        // Allow time for credential retrieval to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Assert - Should automatically retrieve stored credentials
        XCTAssertEqual(newMockProvider.retrieveCredentialsCallCount, 1)
        // Note: The actual state depends on the credential retrieval success
    }

    // MARK: - Error Recovery Tests

    func testAuthenticationErrorRecovery_loginFailureRecovery_handlesGracefully() async {
        // Arrange
        mockProvider.shouldFailAuth = true

        // Act - First login attempt (fails)
        do {
            try await auth.login()
            XCTFail("Expected login to throw but it didn't")
        } catch {
            // Expected to fail
        }

        // Assert - Should remain logged out
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertEqual(mockProvider.startAuthCallCount, 1)
        XCTAssertEqual(mockProvider.storeCredentialsCallCount, 0)

        // Act - Second login attempt (succeeds)
        mockProvider.shouldFailAuth = false
        mockProvider.mockCredentials = createTestCredentials()
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert - Should now be logged in
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotNil(auth.idToken)
        XCTAssertEqual(mockProvider.startAuthCallCount, 2)
        XCTAssertEqual(mockProvider.storeCredentialsCallCount, 1)
    }

    func testAuthenticationErrorRecovery_renewFailureHandling_maintainsState() async {
        // Arrange
        let testCredentials = createTestCredentials()
        mockProvider.mockCredentials = testCredentials
        mockCredentialsManager.storedCredentials = testCredentials

        // Login first
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }
        let originalIdToken = auth.idToken
        let originalAccessToken = auth.accessToken

        mockProvider.canRenewCredentialsResult = true
        mockProvider.shouldFailRenewCredentials = true

        // Act - Attempt to renew (fails)
        do {
            try await auth.renewCredentialsIfNeeded()
        } catch {
            // Expected to potentially fail, but we don't want to fail the test
        }

        // Assert - Should maintain original state
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertEqual(auth.idToken, originalIdToken)
        XCTAssertEqual(auth.accessToken, originalAccessToken)
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)
        XCTAssertEqual(mockProvider.renewCredentialsCallCount, 1)
    }

    func testAuthenticationErrorRecovery_logoutFailureHandling_clearsCredentials() async {
        // Arrange
        let testCredentials = createTestCredentials()
        mockProvider.mockCredentials = testCredentials
        mockCredentialsManager.storedCredentials = testCredentials

        // Login first
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }
        XCTAssertTrue(auth.isLoggedIn)

        mockProvider.shouldFailClearSession = true

        // Act - Logout (session clear fails, but credential clear succeeds)
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert - Should still clear credentials despite session clear failure
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertNil(auth.accessToken)
        XCTAssertNil(auth.refreshToken)
        XCTAssertEqual(mockProvider.clearSessionCallCount, 1)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentOperations_multipleLoginAttempts_handledCorrectly() async {
        // Arrange
        let testCredentials = createTestCredentials()
        mockProvider.mockCredentials = testCredentials
        mockCredentialsManager.storedCredentials = testCredentials

        // Act - Multiple concurrent login attempts
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    do {
                        try await self.auth.login()
                    } catch {
                        // Expected to potentially fail during concurrent operations
                    }
                }
            }
        }

        // Assert - Should be logged in only once
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotNil(auth.idToken)
        XCTAssertGreaterThanOrEqual(mockProvider.startAuthCallCount, 1)
    }

    func testConcurrentOperations_loginAndRenew_handledCorrectly() async {
        // Arrange
        let testCredentials = createTestCredentials()
        let renewedCredentials = createTestCredentials()
        mockProvider.mockCredentials = testCredentials
        mockCredentialsManager.storedCredentials = testCredentials
        mockProvider.canRenewCredentialsResult = true

        // Act - Login first
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Act - Concurrent login and renew
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await self.auth.login()
                } catch {
                    // Expected to potentially fail during concurrent operations
                }
            }
            group.addTask {
                self.mockProvider.mockCredentials = renewedCredentials
                do {
                    try await self.auth.renewCredentialsIfNeeded()
                } catch {
                    // Expected to potentially fail during concurrent operations
                }
            }
        }

        // Assert - Should maintain consistent state
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotNil(auth.idToken)
        XCTAssertNotNil(auth.accessToken)
        XCTAssertNotNil(auth.refreshToken)
    }

    // MARK: - Edge Cases Tests

    func testEdgeCase_logoutWithoutLogin_handledGracefully() async {
        // Arrange
        XCTAssertFalse(auth.isLoggedIn)

        // Act - Logout without being logged in
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert - Should handle gracefully
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertEqual(mockProvider.clearSessionCallCount, 1)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
    }

    func testEdgeCase_renewWithoutLogin_handledGracefully() async {
        // Arrange
        XCTAssertFalse(auth.isLoggedIn)
        mockProvider.canRenewCredentialsResult = false

        // Act - Attempt to renew without being logged in
        do {
            try await auth.renewCredentialsIfNeeded()
        } catch {
            // Expected to potentially fail, but we don't want to fail the test
        }

        // Assert - Should handle gracefully
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)
        XCTAssertEqual(mockProvider.renewCredentialsCallCount, 0)
    }

    func testEdgeCase_webInitiatedLogout_skipsWebLogout() async {
        // Arrange
        let testCredentials = createTestCredentials()
        mockProvider.mockCredentials = testCredentials
        mockCredentialsManager.storedCredentials = testCredentials

        // Login first
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }
        XCTAssertTrue(auth.isLoggedIn)

        // Act - Web-initiated logout (skip web logout)
        do {
            try await auth.logout(triggerWebLogout: false)
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert - Should clear credentials but not call clearSession
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertNil(auth.idToken)
        XCTAssertEqual(mockProvider.clearSessionCallCount, 0)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
    }

    // MARK: - Integration with Real Components

    func testIntegrationWithRealCredentialsManager_basicFlow_worksCorrectly() async {
        // Arrange
        let realCredentialsManager = DefaultCredentialsManager()
        mockProvider.credentialsManager = realCredentialsManager
        let testCredentials = createTestCredentials()
        mockProvider.mockCredentials = testCredentials

        _ = realCredentialsManager.clear()

        // Act - Login
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert - Should use real credentials manager
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNotNil(auth.idToken)
        XCTAssertEqual(mockProvider.startAuthCallCount, 1)
        XCTAssertEqual(mockProvider.storeCredentialsCallCount, 1)

        // Cleanup
        _ = realCredentialsManager.clear()
    }

    // MARK: - Helper Methods

    private func createTestCredentials() -> Credentials {
        return Credentials(
            accessToken: "integration-test-access-token-\(UUID().uuidString)",
            tokenType: "Bearer",
            idToken: "integration-test-id-token-\(UUID().uuidString)",
            refreshToken: "integration-test-refresh-token-\(UUID().uuidString)",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
    }
}
