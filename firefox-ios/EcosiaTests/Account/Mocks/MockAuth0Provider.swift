// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import Combine
@testable import Ecosia

class MockAuth0Provider: Auth0ProviderProtocol {

    // MARK: - Test Control Properties
    var shouldFailAuth = false
    var shouldFailStoreCredentials = false
    var shouldFailRetrieveCredentials = false
    var shouldFailClearSession = false
    var shouldFailRenewCredentials = false
    var canRenewCredentialsResult = true
    var clearCredentialsResult = true

    // MARK: - Mock Data
    var mockCredentials: Credentials?
    var mockError: Error?
    var hasStoredCredentials = false

    // MARK: - Call Tracking
    var startAuthCallCount = 0
    var clearSessionCallCount = 0
    var storeCredentialsCallCount = 0
    var retrieveCredentialsCallCount = 0
    var clearCredentialsCallCount = 0
    var renewCredentialsCallCount = 0
    var canRenewCredentialsCallCount = 0

    // MARK: - Protocol Requirements
    var settings: Auth0SettingsProviderProtocol = MockAuth0SettingsProvider()
    var credentialsManager: CredentialsManagerProtocol = MockCredentialsManager()
    lazy var webAuth: WebAuth = Auth0.webAuth(clientId: "test-client", domain: "test.auth0.com")

    // MARK: - Mock Implementations
    func startAuth() async throws -> Credentials {
        startAuthCallCount += 1

        if shouldFailAuth {
            throw mockError ?? NSError(domain: "MockAuth0Provider", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Mock auth failure"])
        }

        return mockCredentials ?? createMockCredentials()
    }

    func clearSession() async throws {
        clearSessionCallCount += 1

        if shouldFailClearSession {
            throw mockError ?? NSError(domain: "MockAuth0Provider", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Mock clear session failure"])
        }
    }

    func storeCredentials(_ credentials: Credentials) throws -> Bool {
        storeCredentialsCallCount += 1

        if shouldFailStoreCredentials {
            throw mockError ?? NSError(domain: "MockAuth0Provider", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Mock store credentials failure"])
        }

        // Mark that we now have stored credentials
        hasStoredCredentials = true
        return true
    }

    func retrieveCredentials() async throws -> Credentials {
        retrieveCredentialsCallCount += 1

        if shouldFailRetrieveCredentials {
            throw mockError ?? NSError(domain: "MockAuth0Provider", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Mock retrieve credentials failure"])
        }

        // Only return credentials if we actually have stored credentials
        guard hasStoredCredentials else {
            throw NSError(domain: "MockAuth0Provider", code: 1006, userInfo: [NSLocalizedDescriptionKey: "No credentials were found in the store."])
        }

        return mockCredentials ?? createMockCredentials()
    }

    func clearCredentials() -> Bool {
        clearCredentialsCallCount += 1

        if clearCredentialsResult {
            hasStoredCredentials = false
            mockCredentials = nil
        }

        return clearCredentialsResult
    }

    func canRenewCredentials() -> Bool {
        canRenewCredentialsCallCount += 1
        return canRenewCredentialsResult && hasStoredCredentials
    }

    func renewCredentials() async throws -> Credentials {
        renewCredentialsCallCount += 1

        if shouldFailRenewCredentials {
            throw mockError ?? NSError(domain: "MockAuth0Provider", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Mock renew credentials failure"])
        }

        guard hasStoredCredentials else {
            throw NSError(domain: "MockAuth0Provider", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Cannot renew credentials: no stored credentials"])
        }

        return mockCredentials ?? createMockCredentials()
    }

    // MARK: - Helper Methods
    private func createMockCredentials() -> Credentials {
        return Credentials(
            accessToken: "mock-access-token",
            tokenType: "Bearer",
            idToken: "mock-id-token",
            refreshToken: "mock-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
    }

    func reset() {
        shouldFailAuth = false
        shouldFailStoreCredentials = false
        shouldFailRetrieveCredentials = false
        shouldFailClearSession = false
        shouldFailRenewCredentials = false
        canRenewCredentialsResult = true
        clearCredentialsResult = true

        mockCredentials = nil
        mockError = nil
        hasStoredCredentials = false  // Clear stored credentials state

        startAuthCallCount = 0
        clearSessionCallCount = 0
        storeCredentialsCallCount = 0
        retrieveCredentialsCallCount = 0
        clearCredentialsCallCount = 0
        renewCredentialsCallCount = 0
        canRenewCredentialsCallCount = 0
    }
}
