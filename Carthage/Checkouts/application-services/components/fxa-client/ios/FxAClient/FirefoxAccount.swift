/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// This class provides low-level access to `RustFxAccount` through various asynchronous wrappers.
/// It should not be used anymore and is kept for backwards compatbility for the Lockwise iOS project.
@available(*, deprecated, message: "Use FxAccountManager instead")
open class FirefoxAccount: RustFxAccount {
    /// Gets the logged-in user profile.
    /// Throws `FirefoxAccountError.Unauthorized` if we couldn't find any suitable access token
    /// to make that call. The caller should then start the OAuth Flow again with
    /// the "profile" scope.
    open func getProfile(completionHandler: @escaping (Profile?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let profile = try super.getProfile()
                DispatchQueue.main.async { completionHandler(profile, nil) }
            } catch {
                DispatchQueue.main.async { completionHandler(nil, error) }
            }
        }
    }

    /// Request a OAuth token by starting a new OAuth flow.
    ///
    /// This function returns a URL string that the caller should open in a webview.
    ///
    /// Once the user has confirmed the authorization grant, they will get redirected to `redirect_url`:
    /// the caller must intercept that redirection, extract the `code` and `state` query parameters and call
    /// `completeOAuthFlow(...)` to complete the flow.
    open func beginOAuthFlow(scopes: [String], completionHandler: @escaping (URL?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let url = try super.beginOAuthFlow(scopes: scopes)
                DispatchQueue.main.async { completionHandler(url, nil) }
            } catch {
                DispatchQueue.main.async { completionHandler(nil, error) }
            }
        }
    }

    /// Finish an OAuth flow initiated by `beginOAuthFlow(...)` and returns token/keys.
    ///
    /// This resulting token might not have all the `scopes` the caller have requested (e.g. the user
    /// might have denied some of them): it is the responsibility of the caller to accomodate that.
    open func completeOAuthFlow(code: String, state: String, completionHandler: @escaping (Void, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                try super.completeOAuthFlow(code: code, state: state)
                DispatchQueue.main.async { completionHandler((), nil) }
            } catch {
                DispatchQueue.main.async { completionHandler((), error) }
            }
        }
    }

    /// Try to get an OAuth access token.
    ///
    /// Throws `FirefoxAccountError.Unauthorized` if we couldn't provide an access token
    /// for this scope. The caller should then start the OAuth Flow again with
    /// the desired scope.
    open func getAccessToken(scope: String, completionHandler: @escaping (AccessTokenInfo?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let tokenInfo = try super.getAccessToken(scope: scope)
                DispatchQueue.main.async { completionHandler(tokenInfo, nil) }
            } catch {
                DispatchQueue.main.async { completionHandler(nil, error) }
            }
        }
    }

    /// Check whether the refreshToken is active
    open func checkAuthorizationStatus(completionHandler: @escaping (IntrospectInfo?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let tokenInfo = try super.checkAuthorizationStatus()
                DispatchQueue.main.async { completionHandler(tokenInfo, nil) }
            } catch {
                DispatchQueue.main.async { completionHandler(nil, error) }
            }
        }
    }

    /// This method should be called when a request made with
    /// an OAuth token failed with an authentication error.
    /// It clears the internal cache of OAuth access tokens,
    /// so the caller can try to call `getAccessToken` or `getProfile`
    /// again.
    open func clearAccessTokenCache(completionHandler: @escaping (Void, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                try super.clearAccessTokenCache()
                DispatchQueue.main.async { completionHandler((), nil) }
            } catch {
                DispatchQueue.main.async { completionHandler((), error) }
            }
        }
    }

    /// Disconnect from the account and optionaly destroy our device record.
    /// `beginOAuthFlow(...)` will need to be called to reconnect.
    open func disconnect(completionHandler: @escaping (Void, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                try super.disconnect()
                DispatchQueue.main.async { completionHandler((), nil) }
            } catch {
                DispatchQueue.main.async { completionHandler((), error) }
            }
        }
    }
}
