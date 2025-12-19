// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0
import WebKit

/// Native to Web SSO implementation of `Auth0ProviderProtocol` using Auth0's SDK and performing Native to Web SSO via REST API to perform the session token exchange.
public struct NativeToWebSSOAuth0Provider: Auth0ProviderProtocol {

    public let settings: Auth0SettingsProviderProtocol
    public let credentialsManager: CredentialsManagerProtocol
    public typealias SessionToken = String
    private let environment: Environment

    enum NativeToWebSSOError: Error, Equatable {
        case invalidResponse
        case missingRefreshToken(String)
        case missingConfiguration(String)
    }

    public init(settings: Auth0SettingsProviderProtocol = DefaultAuth0SettingsProvider(),
                credentialsManager: CredentialsManagerProtocol? = nil,
                environment: Environment = .current) {
        self.settings = settings
        self.credentialsManager = credentialsManager ?? DefaultCredentialsManager(auth0SettingsProvider: settings)
        self.environment = environment
    }

    public var webAuth: WebAuth {
        makeHttpsWebAuth()
            .useEphemeralSession()
            .audience(environment.urlProvider.authApiAudience.absoluteString)
            .scope("openid profile email offline_access read:impact write:impact")
    }

    public func startAuth() async throws -> Credentials {
        return try await webAuth.start()
    }

    /// Custom clearSession implementation that bypasses Auth0's default logout alert
    /// We provide immediate logout without any confirmation popups for better UX
    public func clearSession() async throws {
        // Skip calling webAuth.clearSession() to avoid Auth0's native logout alert
        // Logout happens immediately without any confirmation dialogs by clearing the auth session cookie
        await clearWebSessionCookies()
        EcosiaLogger.auth.info("\(Cookie.authSession.name) cookie cleared successfully")
    }

    /// Clears EASC (Ecosia Auth Session Cookie) cookies from the default web data store
    private func clearWebSessionCookies() async {
        let cookieStore = await WKWebsiteDataStore.default().httpCookieStore
        guard let sessionCookie = await cookieStore.allCookies().first(where: { $0.name == Cookie.authSession.name }) else { return }
        await cookieStore.deleteCookie(sessionCookie)
    }
}

extension NativeToWebSSOAuth0Provider {

    /// Requests the `session_token` with the `refresh_token`.
    ///
    /// - Returns: A `session_token` as `SessionToken` (a `String` type).
    /// - Throws: An error if the retrieval fails.
    public func getSSOCredentials() async throws -> SSOCredentials {
        let credentials = try await retrieveCredentials()
        guard let refreshToken = credentials.refreshToken else {
            throw NativeToWebSSOError.missingRefreshToken("Refresh token is missing. Please check your credentials.")
        }

        let configuration: URLSessionConfiguration = .default
        let ecosiaAuth0Session = URLSession(configuration: configuration.withCloudFlareAuthParameters())
        return try await Auth0
            .authentication(clientId: settings.id,
                            domain: settings.domain,
                            session: ecosiaAuth0Session)
            .ssoExchange(withRefreshToken: refreshToken)
            .start()
    }

    /// Retrieves configuration values from the Auth0.plist file.
    ///
    /// - Parameter bundle: The bundle containing the Auth0.plist file. Defaults to `.ecosia`.
    /// - Returns: A tuple containing the `clientId` and `domain` if available, otherwise `nil`.
    func configurationValues(bundle: Bundle = .ecosia) -> (clientId: String, domain: String)? {
        guard let path = bundle.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            EcosiaLogger.auth.error("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
        }

        guard let clientId = values["ClientId"] as? String, let domain = values["Domain"] as? String else {
            EcosiaLogger.auth.error("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            return nil
        }
        return (clientId: clientId, domain: domain)
    }
}
