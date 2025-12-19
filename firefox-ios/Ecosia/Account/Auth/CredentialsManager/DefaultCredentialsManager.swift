// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

struct DefaultCredentialsManager: CredentialsManagerProtocol {

    private let credentialManager: CredentialsManager

    init(auth0SettingsProvider: Auth0SettingsProviderProtocol = DefaultAuth0SettingsProvider()) {
        self.credentialManager = CredentialsManager(authentication: Auth0.authentication(clientId: auth0SettingsProvider.id,
                                                                                         domain: auth0SettingsProvider.domain))
    }

    func store(credentials: Auth0.Credentials) -> Bool {
        credentialManager.store(credentials: credentials)
    }

    func credentials() async throws -> Auth0.Credentials {
        try await credentialManager.credentials()
    }

    func clear() -> Bool {
        credentialManager.clear()
    }

    func canRenew() -> Bool {
        credentialManager.canRenew()
    }

    func renew() async throws -> Auth0.Credentials {
        try await credentialManager.renew()
    }
}
