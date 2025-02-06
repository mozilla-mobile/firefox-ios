// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Cookie: String {
    case main
    case consent

    // MARK: - Init
    /// Initialize Cookie enum based on the name
    init?(_ name: String) {
        switch name {
        case "ECFG":
            self = .main
        case "ECCC":
            self = .consent
        default:
            return nil
        }
    }

    // MARK: - Main Specific Properties

    private struct MainCookieProperties {
        static let userId = "cid"
        static let suggestions = "as"
        static let personalized = "pz"
        static let customSettings = "cs"
        static let adultFilter = "f"
        static let marketCode = "mc"
        static let treeCount = "t"
        static let language = "l"
        static let marketApplied = "ma"
        static let marketReapplied = "mr"
        static let deviceType = "dt"
        static let firstSearch = "fs"
        static let addon = "a"
    }

    // MARK: - Common Properties

    var name: String {
        switch self {
        case .main:
            return "ECFG"
        case .consent:
            return "ECCC"
        }
    }

    /// Values for incognito mode cookies.
    static var incognitoValues: [String: String] {
        var values = [String: String]()
        values[MainCookieProperties.adultFilter] = User.shared.adultFilter.rawValue
        values[MainCookieProperties.marketCode] = User.shared.marketCode.rawValue
        values[MainCookieProperties.language] = Language.current.rawValue
        values[MainCookieProperties.suggestions] = .init(User.shared.autoComplete ? 1 : 0)
        values[MainCookieProperties.personalized] = .init(User.shared.personalized ? 1 : 0)
        values[MainCookieProperties.marketApplied] = "1"
        values[MainCookieProperties.marketReapplied] = "1"
        values[MainCookieProperties.deviceType] = "mobile"
        values[MainCookieProperties.firstSearch] = "0"
        values[MainCookieProperties.addon] = "1"
        return values
    }

    /// Values for standard mode cookies.
    static var standardValues: [String: String] {
        var values = incognitoValues
        values[MainCookieProperties.userId] = User.shared.id
        values[MainCookieProperties.treeCount] = .init(User.shared.searchCount)
        return values
    }

    // MARK: - Functions

    /// Creates an incognito mode ECFG cookie.
    /// - Parameter urlProvider: Provides the URL information.
    /// - Returns: An HTTPCookie configured for incognito mode.
    public static func makeIncognitoCookie(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie {
        HTTPCookie(properties: [.name: Cookie.main.name,
                                .domain: ".\(urlProvider.domain ?? "")",
                                .path: "/",
                                .value: Cookie.incognitoValues.map { $0.0 + "=" + $0.1 }.joined(separator: ":")])!
    }

    /// Creates a standard mode ECFG cookie.
    /// - Parameter urlProvider: Provides the URL information.
    /// - Returns: An HTTPCookie configured for standard mode.
    public static func makeStandardCookie(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie {
        HTTPCookie(properties: [.name: Cookie.main.name,
                                .domain: ".\(urlProvider.domain ?? "")",
                                .path: "/",
                                .value: Cookie.standardValues.map { $0.0 + "=" + $0.1 }.joined(separator: ":")])!
    }

    public static func makeConsentCookie(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie? {
        guard let cookieConsentValue = User.shared.cookieConsentValue else { return nil }
        return HTTPCookie(properties: [.name: Cookie.consent.name,
                                       .domain: ".\(urlProvider.domain ?? "")",
                                       .path: "/",
                                       .value: cookieConsentValue])
    }

    /// Processes received cookies.
    /// - Parameters:
    ///   - cookies: An array of HTTPCookie objects.
    ///   - urlProvider: Provides the URL information.
    public static func received(_ cookies: [HTTPCookie], urlProvider: URLProvider = Environment.current.urlProvider) {
        cookies.forEach { cookie in
            guard let cookieType = Cookie(cookie.name), cookie.domain.contains(".\(urlProvider.domain ?? "")") else { return }
            cookieType.extract(cookie)
        }
    }

    /// Processes received cookies from an HTTP response.
    /// - Parameters:
    ///   - response: An HTTPURLResponse object.
    ///   - urlProvider: Provides the URL information.
    public static func received(_ response: HTTPURLResponse, urlProvider: URLProvider = Environment.current.urlProvider) {
        (response.allHeaderFields as? [String: String]).map {
            HTTPCookie.cookies(withResponseHeaderFields: $0, for: urlProvider.root)
        }.map { received($0, urlProvider: urlProvider) }
    }

    /// Extracts and handles ECFG specific properties.
    /// - Parameter properties: A dictionary of cookie properties.
    private func extractECFG(_ properties: [String: String]) {
        var user = User.shared

        properties[MainCookieProperties.userId].map {
            user.id = $0
        }

        properties[MainCookieProperties.treeCount].flatMap(Int.init).map {
            // tree count should only increase or be reset to 0 on logout
            if $0 == 0 || $0 > user.searchCount {
                user.searchCount = $0
            }
        }

        properties[MainCookieProperties.marketCode].flatMap(Local.init).map {
            user.marketCode = $0
        }

        properties[MainCookieProperties.adultFilter].flatMap(AdultFilter.init).map {
            user.adultFilter = $0
        }

        properties[MainCookieProperties.personalized].flatMap(Int.init).map { NSNumber(value: $0) }.flatMap(Bool.init).map {
            user.personalized = $0
        }

        properties[MainCookieProperties.suggestions].map {
            user.autoComplete = ($0 as NSString).boolValue
        }

        User.shared = user
    }

    /// Extracts and handles ECCC specific properties.
    /// - Parameter value: A string of cookie values expressed by a sequence of letters (e.g. `eampg`)
    private func extractECCC(_ value: String) {
        User.shared.cookieConsentValue = value
    }

    /// Extracts properties from a cookie.
    /// - Parameter cookie: An HTTPCookie object.
    private func extract(_ cookie: HTTPCookie) {

        switch self {
        case .main:
            let properties = cookie.value.components(separatedBy: ":")
                .map { $0.components(separatedBy: "=") }
                .filter { $0.count == 2 }
                .reduce(into: [:]) { result, item in
                    result[item[0]] = item[1]
                }
            extractECFG(properties)
        case .consent:
            extractECCC(cookie.value)
        }
    }
}
