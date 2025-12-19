// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
@testable import Ecosia

final class MockCredentialsManager: CredentialsManagerProtocol {

    // MARK: - Test Control Properties
    var shouldFailCredentials = false
    var shouldFailRenew = false
    var canRenewResult = true
    var clearResult = true

    // MARK: - Mock Data
    var storedCredentials: Credentials?
    var mockCredentials: Credentials?
    var mockError: Error?
    var lastStoredCredentials: Credentials? // Track the last credentials that were stored

    // MARK: - Call Tracking
    var credentialsCallCount = 0
    var renewCallCount = 0
    var storeCallCount = 0
    var clearCallCount = 0
    var canRenewCallCount = 0

    // MARK: - Mock Implementations
    func credentials() async throws -> Credentials {
        credentialsCallCount += 1

        if shouldFailCredentials {
            throw mockError ?? NSError(domain: "MockCredentialsManager", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Mock credentials failure"])
        }

        return mockCredentials ?? storedCredentials ?? createMockCredentials()
    }

    func renew() async throws -> Credentials {
        renewCallCount += 1

        if shouldFailRenew {
            throw mockError ?? NSError(domain: "MockCredentialsManager", code: 2002, userInfo: [NSLocalizedDescriptionKey: "Mock renew failure"])
        }

        let renewedCredentials = mockCredentials ?? createMockCredentials()
        storedCredentials = renewedCredentials
        return renewedCredentials
    }

    func store(credentials: Credentials) -> Bool {
        storeCallCount += 1
        storedCredentials = credentials
        lastStoredCredentials = credentials // Track the last stored credentials
        return true
    }

    func clear() -> Bool {
        clearCallCount += 1
        if clearResult {
            storedCredentials = nil
            lastStoredCredentials = nil
        }
        return clearResult
    }

    func canRenew() -> Bool {
        canRenewCallCount += 1
        return canRenewResult
    }

    // MARK: - Helper Methods
    private func createMockCredentials() -> Credentials {
        return Credentials(
            accessToken: "mock-access-token-\(UUID().uuidString)",
            tokenType: "Bearer",
            idToken: "mock-id-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-token-\(UUID().uuidString)",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
    }

    func reset() {
        shouldFailCredentials = false
        shouldFailRenew = false
        canRenewResult = true
        clearResult = true

        storedCredentials = nil
        mockCredentials = nil
        mockError = nil
        lastStoredCredentials = nil

        credentialsCallCount = 0
        renewCallCount = 0
        storeCallCount = 0
        clearCallCount = 0
        canRenewCallCount = 0
    }
}

// MARK: - Mock Auth0SettingsProvider
class MockAuth0SettingsProvider: Auth0SettingsProviderProtocol {
    var domain: String = "test.auth0.com"
    var id: String = "mock-client-id"
    var cookieDomain: String = "test.ecosia.org"
}
