// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

// MARK: - Cookie Types

public enum Cookie: String, CaseIterable {
    // https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4128796/Cookies#ECFG
    case main = "ECFG"
    // https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4128796/Cookies#ECCC
    case consent = "ECCC"
    // https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4128796/Cookies#ECUNL
    case unleash = "ECUNL"
    // https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4128796/Cookies#ECAIO
    case aiOverviews = "ECAIO"
    // https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4128796/Cookies#EASC
    case authSession = "EASC"

    // MARK: - URLProvider Management

    private static var _urlProvider: URLProvider?

    /// Sets the URLProvider for all cookie operations. Primarily used for testing.
    /// If not set, defaults to EcosiaEnvironment.current.urlProvider
    public static func setURLProvider(_ provider: URLProvider) {
        _urlProvider = provider
    }

    /// Resets the URLProvider to use the default EcosiaEnvironment.current.urlProvider
    public static func resetURLProvider() {
        _urlProvider = nil
    }

    /// Gets the current URLProvider, defaulting to EcosiaEnvironment.current.urlProvider if not explicitly set
    static var urlProvider: URLProvider {
        return _urlProvider ?? EcosiaEnvironment.current.urlProvider
    }

    // MARK: - Init
    /// Initialized enum using HTTPCookie object's name. Also checks domain matches Ecosia.
    /// - Parameters:
    ///   - cookie: HTTPCookie
    init?(_ cookie: HTTPCookie) {
        let ecosiaDomain = Cookie.urlProvider.domain
        guard cookie.domain == ".\(ecosiaDomain)" else {
            return nil
        }
        self.init(cookie.name)
    }

    init?(_ name: String) {
        self.init(rawValue: name)
    }

    var name: String {
        rawValue
    }

    // MARK: - Cookie Handler Factory

    private var handler: CookieHandler {
        switch self {
        case .main:
            return MainCookieHandler()
        case .consent:
            return ConsentCookieHandler()
        case .unleash:
            return UnleashCookieHandler()
        case .aiOverviews:
            return AIOverviewsCookieHandler()
        case .authSession:
            return AuthSessionCookieHandler()
        }
    }

    /// Creates a Main Cookie for the specified mode.
    /// - Parameters:
    ///   - mode: The cookie mode (standard or incognito)
    /// - Returns: An HTTPCookie configured for the specified mode.
    private static func makeMain(withMode mode: CookieMode) -> HTTPCookie? {
        return MainCookieHandler(mode: mode).makeCookie()
    }

    // MARK: - Public Interface

    /// Processes received cookies.
    /// - Parameters:
    ///   - cookies: An array of HTTPCookie objects.
    ///   - cookieStore: WKHTTPCookieStore where cookies are set. Used when cookies need to be overwritten.
    public static func received(_ cookies: [HTTPCookie], in cookieStore: CookieStoreProtocol) {
        cookies.forEach { cookie in
            guard let cookieType = Cookie(cookie) else { return }
            cookieType.handler.received(cookie, in: cookieStore)
        }
    }

    /// Creates cookies for all required types for web view configuration.
    /// - Parameters:
    ///   - isPrivate: Whether to create cookies for private browsing mode
    /// - Returns: An array of HTTPCookie for all required types
    public static func makeRequiredCookies(isPrivate: Bool) -> [HTTPCookie] {
        var cookies: [HTTPCookie] = []

        Cookie.allCases.forEach { cookieType in
            switch cookieType {
            case .main:
                let mainMode: CookieMode = isPrivate ? .incognito : .standard
                if let cookie = makeMain(withMode: mainMode) {
                    cookies.append(cookie)
                }
            default:
                if let cookie = cookieType.handler.makeCookie() {
                    cookies.append(cookie)
                }
            }
        }

        return cookies
    }

    /// Creates cookies related to search settings for `searchSettingsChanged` notification.
    /// - Parameter isPrivate: Whether to create cookies for private browsing mode
    /// - Returns: An array of HTTPCookie for all search setting specific types
    public static func makeSearchSettingsObserverCookies(isPrivate: Bool) -> [HTTPCookie] {
        var cookies: [HTTPCookie] = []

        Cookie.allCases.forEach { cookieType in
            switch cookieType {
            case .main:
                let mainMode: CookieMode = isPrivate ? .incognito : .standard
                if let cookie = makeMain(withMode: mainMode) {
                    cookies.append(cookie)
                }
            case .aiOverviews:
                if let cookie = cookieType.handler.makeCookie() {
                    cookies.append(cookie)
                }
            default:
                break
            }
        }

        return cookies
    }
}
