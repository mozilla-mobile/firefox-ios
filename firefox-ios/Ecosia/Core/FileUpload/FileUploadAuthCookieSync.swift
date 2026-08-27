// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Bridges `EASC` from the WKWebView cookie jar into `HTTPCookieStorage.shared`.
///
/// Native API calls (`URLSession`) do not see cookies that only exist in
/// `WKWebsiteDataStore`. The AI Worker presign route currently authenticates via
/// the `EASC` session cookie (web login), not the Auth0 Bearer token.
enum FileUploadAuthCookieSync {

    /// Copies `EASC` from WK into shared storage and returns it for explicit request headers.
    private static func webViewCookies(from store: CookieStoreProtocol) async -> [HTTPCookie] {
        await store.allCookies()
    }

    @discardableResult
    static func syncAuthSessionCookieToSharedStorage(
        urlProvider: URLProvider = Environment.current.urlProvider,
        cookieStore: CookieStoreProtocol? = nil
    ) async -> HTTPCookie? {
        let store = cookieStore ?? WKWebsiteDataStore.default().httpCookieStore
        let webCookies = await webViewCookies(from: store)
        let easc = webCookies.first { $0.name == Cookie.authSession.rawValue }

        if let easc {
            HTTPCookieStorage.shared.setCookie(easc)
            EcosiaLogger.network.info(
                "[FileUpload] Synced EASC from WK cookie store to HTTPCookieStorage (domain=\(easc.domain))"
            )
        } else {
            EcosiaLogger.network.error(
                "[FileUpload] No EASC cookie in WK cookie store — presign may return 401 until web session is established"
            )
        }

        let sharedCookies = HTTPCookieStorage.shared.cookies(for: urlProvider.apiRoot) ?? []
        let sharedEASC = sharedCookies.contains { $0.name == Cookie.authSession.rawValue }
        EcosiaLogger.network.info(
            "[FileUpload] EASC in HTTPCookieStorage for api root: \(sharedEASC) (total cookies=\(sharedCookies.count))"
        )

        return easc ?? sharedCookies.first { $0.name == Cookie.authSession.rawValue }
    }

    /// Removes any `EASC` cookie previously copied into `HTTPCookieStorage.shared`.
    ///
    /// `syncAuthSessionCookieToSharedStorage` copies `EASC` out of the WKWebView cookie jar so native
    /// `URLSession` calls can see it, but that copy lives independently of the WKWebView store and isn't
    /// cleared when the web session cookie is. Call this on logout so a stale session cookie for the
    /// previous user can't be attached to native requests made under a different, newly logged-in user.
    static func clearAuthSessionCookieFromSharedStorage() {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        cookies
            .filter { $0.name == Cookie.authSession.rawValue }
            .forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }
}

enum FileUploadAuthDiagnostics {

    static func logAccessTokenScopes(_ accessToken: String, grantedScope: String? = nil) {
        let scopes = EcosiaAuthScopes.parseScopeClaim(from: accessToken)
            ?? grantedScope.map(EcosiaAuthScopes.parseScopeString)

        guard let scopes else {
            EcosiaLogger.network.error("[FileUpload] Could not determine token scopes from JWT or granted scope")
            return
        }

        let joined = scopes.sorted().joined(separator: " ")
        let hasWriteConversations = scopes.contains("write:conversations")
        EcosiaLogger.network.info(
            "[FileUpload] Token scopes: \(joined) (write:conversations=\(hasWriteConversations))"
        )
        if !hasWriteConversations {
            EcosiaLogger.network.error(
                "[FileUpload] Token is missing write:conversations — CredentialsManager scope refresh is required"
            )
        }
    }
}
