// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

public protocol Auth0SettingsProviderProtocol {
    var id: String { get }
    var domain: String { get }
    var cookieDomain: String { get }
}

public struct DefaultAuth0SettingsProvider: Auth0SettingsProviderProtocol {

    public var id: String {
        guard let clientId = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: "AUTH0_CLIENT_ID") else {
            fatalError("AUTH0_CLIENT_ID not found")
        }
        return clientId
    }

    public var domain: String {
        return EcosiaEnvironment.current.urlProvider.auth0Domain
    }

    public var cookieDomain: String {
        return EcosiaEnvironment.current.urlProvider.auth0CookieDomain
    }

    public init() {}
}
