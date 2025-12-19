// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0
@testable import Ecosia

/// A mock that simulates NativeToWebSSOAuth0Provider behavior for testing
/// Note: Since NativeToWebSSOAuth0Provider is a struct, we can't inherit from it
/// Instead, we create a separate mock that can be used in tests that need SSO functionality
final class MockNativeToWebSSOAuth0Provider: MockAuth0Provider {

    // MARK: - Additional Test Control Properties for SSO
    var shouldFailGetSSOCredentials = false
    var mockSSOError: Error?
    var getSSOCredentialsCallCount = 0

    /// Mock implementation of getSSOCredentials for testing SSO functionality
    func getSSOCredentials() async throws -> SSOCredentials {
        getSSOCredentialsCallCount += 1

        if shouldFailGetSSOCredentials {
            throw mockSSOError ?? NSError(domain: "MockNativeToWebSSOAuth0Provider", code: 1008, userInfo: [NSLocalizedDescriptionKey: "Mock getSSOCredentials failure"])
        }

        // Check if we have stored credentials (simulating the real implementation's behavior)
        guard hasStoredCredentials else {
            throw NSError(domain: "MockNativeToWebSSOAuth0Provider", code: 1009, userInfo: [NSLocalizedDescriptionKey: "No credentials available for SSO"])
        }

        // Check if refresh token exists (simulating the real implementation's validation)
        guard let credentials = mockCredentials, credentials.refreshToken != nil else {
            throw NSError(domain: "MockNativeToWebSSOAuth0Provider", code: 1010, userInfo: [NSLocalizedDescriptionKey: "No refresh token available for SSO"])
        }

        // Since SSOCredentials is from Auth0 SDK and difficult to instantiate in tests,
        // we'll throw an error that simulates the Auth0 SDK call failing in a test environment
        // This allows us to test the validation logic without needing actual Auth0 integration
        throw NSError(domain: "MockNativeToWebSSOAuth0Provider", code: 1011, userInfo: [NSLocalizedDescriptionKey: "Mock Auth0 SDK call - would succeed in real environment"])
    }

    override func reset() {
        super.reset()
        shouldFailGetSSOCredentials = false
        mockSSOError = nil
        getSSOCredentialsCallCount = 0
    }
}
