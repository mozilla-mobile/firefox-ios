// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import WebKit
import Common

/**
 The `EcosiaAuthenticationService` class manages user authentication, credential storage, and session management using Auth0.
 
 This class provides a centralized interface for all authentication operations in the Ecosia app,
 including login, logout, credential renewal, and session token management for web-to-native SSO..
 */
public final class EcosiaAuthenticationService {

    // MARK: - Public Properties

    /// The shared singleton instance of the EcosiaAuthenticationService class.
    public static let shared = EcosiaAuthenticationService()

    /// The default credentials manager used across the application.
    /// This is a static property to ensure consistent credential storage.
    public static let defaultCredentialsManager: CredentialsManagerProtocol = DefaultCredentialsManager()

    /// The Auth0 provider responsible for authentication operations.
    /// This can be customized to use different authentication flows (e.g., web auth, native-to-web SSO).
    public let auth0Provider: Auth0ProviderProtocol

    // MARK: - Private Properties

    /// The current ID token for the authenticated user.
    /// This token contains user identity information and is used for authentication.
    public private(set) var idToken: String?

    /// The current access token for the authenticated user.
    /// This token is used to access protected resources.
    public private(set) var accessToken: String?

    /// The current refresh token for the authenticated user.
    /// This token is used to obtain new access tokens when they expire.
    private(set) var refreshToken: String?

    /// The current SSO credentials for session transfer between web and native contexts.
    private(set) var ssoCredentials: SSOCredentials?

    /// Indicates whether the user is currently logged in.
    /// This property is automatically updated when login/logout operations complete successfully.
    public private(set) var isLoggedIn: Bool = false

    /// The current user's profile information from Auth0.
    /// This includes name, email, profile picture URL, etc.
    public private(set) var userProfile: UserProfile? {
        didSet {
            NotificationCenter.default.post(name: .EcosiaUserProfileUpdated, object: nil)
        }
    }

    /// For testing: Skip fetching user info from Auth0 to avoid HTTP calls
    var skipUserInfoFetch: Bool = false

    // MARK: - Initialization

    /**
     Initializes a new instance of the `Auth` class with a specified authentication provider.
     
     - Parameter auth0Provider: An object conforming to `Auth0ProviderProtocol` that handles
       the actual authentication operations. Defaults to `WebAuth0Provider()` for standard web authentication.
     
     - Note: The initializer automatically attempts to retrieve any stored credentials from the previous session.
     */
    public init(auth0Provider: Auth0ProviderProtocol = NativeToWebSSOAuth0Provider()) {
        self.auth0Provider = auth0Provider
        Task {
            await self.retrieveStoredCredentials()
        }
    }

    /// Logs in the user asynchronously and stores credentials if successful.
    /// - Throws: `AuthError.userCancelled` if user cancels the authentication,
    ///           `AuthError.authenticationFailed` if Auth0 authentication fails,
    ///           `AuthError.credentialStorageError` if credential storage throws an error,
    ///           `AuthError.credentialStorageFailed` if credential storage returns false.
    public func login() async throws {
        // First, attempt authentication
        let credentials: Credentials
        do {
            credentials = try await auth0Provider.startAuth()
            EcosiaLogger.auth.info("Authentication successful")
        } catch {
            EcosiaLogger.auth.error("Authentication failed: \(error)")

            // Check if user cancelled the login operation
            if let webAuthError = error as? WebAuthError,
               case .userCancelled = webAuthError {
                EcosiaLogger.auth.info("User cancelled login operation")
                throw AuthError.userCancelled
            }

            throw AuthError.authenticationFailed(error)
        }

        // Then, attempt to store credentials
        do {
            let didStore = try auth0Provider.storeCredentials(credentials)
            if didStore {
                setupTokensWithCredentials(credentials, settingLoggedInStateTo: true)
                if !skipUserInfoFetch {
                    await fetchUserInfoFromAuth0(accessToken: credentials.accessToken)
                }
                EcosiaLogger.auth.info("Login completed successfully")
            } else {
                EcosiaLogger.auth.error("Credential storage failed (returned false)")
                throw AuthError.credentialsStorageFailed
            }
        } catch {
            EcosiaLogger.auth.error("Credential storage error: \(error)")
            throw AuthError.credentialsStorageError(error)
        }
    }

    /// Logs out the user with option to skip web logout (for web-initiated logout)
    /// - Parameter triggerWebLogout: Whether to clear the web session. Defaults to true.
    /// - Throws: `AuthError.userCancelled` if user cancels the logout web session,
    ///           `AuthError.sessionClearingFailed` if both web session and credential clearing fail,
    ///           `AuthError.credentialsClearingFailed` if only credential clearing fails.
    public func logout(triggerWebLogout: Bool = true) async throws {
        var sessionClearingError: Error?

        // First, try to clear the web session if requested
        if triggerWebLogout {
            do {
                try await auth0Provider.clearSession()
                EcosiaLogger.auth.info("Web session cleared successfully")
            } catch {
                sessionClearingError = error
                EcosiaLogger.auth.error("Failed to clear web session: \(error)")

                // Check if user cancelled the logout operation
                if let webAuthError = error as? WebAuthError,
                   case .userCancelled = webAuthError {
                    EcosiaLogger.auth.info("User cancelled logout operation")
                    throw AuthError.userCancelled
                }
            }
        }

        // Then, try to clear stored credentials
        let credentialsCleared = auth0Provider.clearCredentials()

        if credentialsCleared {
            setupTokensWithCredentials(nil)
            // Clear user profile on logout
            try await ImageCacheLoader.clearCache(for: userProfile?.pictureURL)
            userProfile = nil
            EcosiaLogger.auth.info("Credentials cleared successfully")

            // If we had a session clearing error but credentials cleared successfully,
            // we still consider the logout successful since the user is logged out locally
            if let sessionError = sessionClearingError {
                EcosiaLogger.auth.notice("Logout completed with web session clearing warning: \(sessionError)")
            }
        } else {
            // If credentials clearing failed, throw appropriate error
            if let sessionError = sessionClearingError {
                // Both session and credentials clearing failed
                throw AuthError.sessionClearingFailed(sessionError)
            } else if auth0Provider.canRenewCredentials() {
                // Only credentials clearing failed, as we can still renew them
                throw AuthError.credentialsClearingFailed
            }
        }
    }

    /**
     Retrieves stored credentials asynchronously from secure storage.
     
     This method attempts to retrieve previously stored credentials from the device's secure storage.
     If successful, it updates the authentication state and credential properties.
     
     - Note: This method is automatically called during initialization to restore the user's
       authentication state from a previous session.
     
     ## Error Handling
     
     If credential retrieval fails (e.g., no stored credentials, corrupted data, or keychain access issues),
     the method will log the error and leave the user in an unauthenticated state.
     */
    public func retrieveStoredCredentials() async {
        do {
            let credentials = try await auth0Provider.retrieveCredentials()
            setupTokensWithCredentials(credentials, settingLoggedInStateTo: true)
            if !skipUserInfoFetch {
                await fetchUserInfoFromAuth0(accessToken: credentials.accessToken)
            }
            EcosiaLogger.auth.info("Retrieved stored credentials successfully")

            // Dispatch state loaded with current authentication status
            await dispatchAuthStateChange(isLoggedIn: self.isLoggedIn, fromCredentialRetrieval: true)
        } catch {
            EcosiaLogger.auth.error("Failed to retrieve credentials: \(error)")
            // Even if retrieval fails, dispatch state loaded as false
            await dispatchAuthStateChange(isLoggedIn: false, fromCredentialRetrieval: true)
        }
    }

    /**
     Renews credentials if they are renewable and close to expiration.
     
     This method checks if the current credentials can be renewed (i.e., a valid refresh token exists)
     and attempts to obtain new credentials using the refresh token. This is useful for maintaining
     long-lived sessions without requiring user re-authentication.
     
     - Note: This method will update the credential properties with the new tokens upon successful renewal.
     
     ## When to Use
     
     Call this method when:
     - You detect that access tokens are expired or about to expire
     - You want to proactively refresh tokens to maintain session continuity
     - You encounter authentication errors that might be resolved by token renewal
     */
    public func renewCredentialsIfNeeded() async throws {
        guard auth0Provider.canRenewCredentials() else {
            EcosiaLogger.auth.info("No renewable credentials available")
            return
        }

        do {
            let credentials = try await auth0Provider.renewCredentials()
            setupTokensWithCredentials(credentials, settingLoggedInStateTo: true)
            EcosiaLogger.auth.info("Renewed credentials successfully")
        } catch {
            EcosiaLogger.auth.error("Failed to renew credentials: \(error)")
            throw AuthError.credentialsRenewalFailed(error)
        }
    }

    /// Helper method to setup tokens and login flag
    private func setupTokensWithCredentials(_ credentials: Credentials?,
                                            settingLoggedInStateTo isLoggedIn: Bool = false) {
        self.idToken = credentials?.idToken
        self.accessToken = credentials?.accessToken
        self.refreshToken = credentials?.refreshToken
        self.isLoggedIn = isLoggedIn

        // Dispatch state change to the new state management system
        Task {
            await dispatchAuthStateChange(isLoggedIn: isLoggedIn, fromCredentialRetrieval: false)
        }
    }

    /// Fetches detailed user information from Auth0's userInfo endpoint
    private func fetchUserInfoFromAuth0(accessToken: String) async {
        do {
            let userInfo = try await Auth0
                .authentication(clientId: auth0Provider.settings.id,
                                domain: auth0Provider.settings.domain)
                .userInfo(withAccessToken: accessToken)
                .start()

            // Update user profile with actual data from Auth0
            self.userProfile = UserProfile(
                name: userInfo.name ?? userInfo.nickname,
                email: userInfo.email,
                picture: userInfo.picture?.absoluteString,
                sub: userInfo.sub
            )

            EcosiaLogger.auth.info("Updated user profile with Auth0 data: name=\(userInfo.name ?? "nil"), email=\(userInfo.email ?? "nil"), picture=\(userInfo.picture?.absoluteString ?? "nil")")
        } catch {
            EcosiaLogger.auth.error("Failed to fetch user info from Auth0: \(error)")
        }
    }
}

extension EcosiaAuthenticationService {

    // MARK: - SSO Methods

    /**
     Retrieves the session transfer token for native-to-web SSO.
     
     This method obtains a session transfer token that can be used to authenticate the user
     in web contexts without requiring them to log in again. This enables seamless transitions
     between native and web experiences.
     
     - Note: This method requires the user to be logged in and only works with providers that
       support SSO credentials (e.g., `NativeToWebSSOAuth0Provider`).
     
     ## Prerequisites
     
     - User must be logged in (`isLoggedIn` must be `true`)
     - The auth provider must support SSO credential retrieval
     */
    public func getSessionTransferToken() async {
        guard isLoggedIn else {
            EcosiaLogger.auth.notice("Cannot get session transfer token - user not logged in")
            return
        }
        ssoCredentials = await retrieveSSOCredentials()
        if ssoCredentials != nil {
            EcosiaLogger.session.info("Retrieved session transfer token for SSO")
        }
    }

    /**
     Returns a session token cookie for web authentication.
     
     This method creates an HTTP cookie containing the session transfer token that can be used
     to authenticate the user in web views or web contexts.
     
     - Returns: An `HTTPCookie` object containing the session transfer token, or `nil` if the user
       is not logged in or no session token is available.
     
     ## Usage
     
     ```swift
     if let cookie = auth.getSessionTokenCookie() {
         webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
     }
     ```
     */
    public func getSessionTokenCookie() -> HTTPCookie? {
        guard isLoggedIn else {
            EcosiaLogger.auth.notice("Cannot create session cookie - user not logged in")
            return nil
        }
        return makeSessionTokenCookieWithSSOCredentials(ssoCredentials)
    }

    /**
     Retrieves SSO credentials from the authentication provider if supported.
     
     This method checks if the current authentication provider supports SSO credential retrieval
     (specifically `NativeToWebSSOAuth0Provider`) and requests the session transfer token.
     
     - Returns: `SSOCredentials` containing the session transfer token and expiration information,
     or `nil` if the provider doesn't support SSO or if the request fails.
     
     - Note: This method performs a type check to ensure the provider supports SSO operations
     before attempting to retrieve credentials.
     */
    private func retrieveSSOCredentials() async -> SSOCredentials? {
        if let authProvider = auth0Provider as? NativeToWebSSOAuth0Provider {
            do {
                return try await authProvider.getSSOCredentials()
            } catch {
                EcosiaLogger.auth.error("Failed to retrieve SSO credentials: \(error)")
            }
        }
        return nil
    }

    /**
     Creates an HTTP cookie containing the session transfer token.
     
     This method constructs a properly formatted HTTP cookie that can be used to authenticate
     the user in web contexts. The cookie includes security attributes and expiration information.
     
     - Parameter ssoCredentials: The SSO credentials containing the session transfer token.
     - Returns: An `HTTPCookie` object configured for the Auth0 domain, or `nil` if credentials are unavailable.
     
     ## Cookie Properties
     
     The created cookie includes:
     - Domain: Set to the Auth0 domain from the provider settings
     - Path: Set to "/" for site-wide access
     - Name: "auth0_session_transfer_token"
     - Value: The session transfer token
     - Expires: Set to the token's expiration time
     - Secure: Set to `true` for HTTPS-only transmission
     */
    private func makeSessionTokenCookieWithSSOCredentials(_ ssoCredentials: SSOCredentials?) -> HTTPCookie? {
        guard let ssoCredentials else {
            EcosiaLogger.auth.notice("No SSO credentials available to create session cookie")
            return nil
        }
        return HTTPCookie(properties: [
            .domain: auth0Provider.settings.cookieDomain,
            .path: "/",
            .name: "auth0_session_transfer_token",
            .value: ssoCredentials.sessionTransferToken,
            .expires: ssoCredentials.expiresIn,
            .secure: true
        ])
    }
}

extension EcosiaAuthenticationService {

    // MARK: - State Management Integration

    /**
     Dispatches authentication state changes to the new state management system
     and posts legacy notifications for backward compatibility.
     
     - Parameters:
     -   isLoggedIn: Current authentication status
     -   fromCredentialRetrieval: Whether this is from credential retrieval (for state loaded)
     */
    private func dispatchAuthStateChange(isLoggedIn: Bool, fromCredentialRetrieval: Bool) async {
        // Determine the correct action type
        let actionType: EcosiaAuthActionType
        if fromCredentialRetrieval {
            actionType = .authStateLoaded
        } else if isLoggedIn {
            actionType = .userLoggedIn
        } else {
            actionType = .userLoggedOut
        }

        // Dispatch to the new state management system
        EcosiaBrowserWindowAuthManager.shared.dispatchAuthState(isLoggedIn: isLoggedIn, actionType: actionType)
    }
}
