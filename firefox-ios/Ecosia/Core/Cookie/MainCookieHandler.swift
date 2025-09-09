// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

public enum CookieMode {
    case standard
    case incognito
}

final class MainCookieHandler: BaseCookieHandler {
    private let mode: CookieMode

    init(mode: CookieMode = .standard) {
        self.mode = mode
        super.init(cookieName: Cookie.main.rawValue)
    }

    override func makeCookie() -> HTTPCookie? {
        return makeCookie(for: mode)
    }

    func makeCookie(for mode: CookieMode) -> HTTPCookie? {
        let value = cookieValues(for: mode).map { $0.key + "=" + $0.value }.joined(separator: ":")
        return createHTTPCookie(value: value)
    }

    override func received(_ cookie: HTTPCookie, in cookieStore: CookieStoreProtocol) {
        let value = cookie.value
        let properties = value.components(separatedBy: ":")
            .map { $0.components(separatedBy: "=") }
            .filter { $0.count == 2 }
            .reduce(into: [:]) { result, item in
                result[item[0]] = item[1]
            }
        extractMainProperties(properties)
    }

    // MARK: - Private helpers

    private struct Properties {
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

    private func cookieValues(for mode: CookieMode) -> [String: String] {
        var values = baseValues()

        switch mode {
        case .standard:
            // Add user-specific values for standard mode
            values[Properties.userId] = User.shared.id
            values[Properties.treeCount] = String(User.shared.searchCount)
        case .incognito:
            // Incognito mode uses only base values (no user ID or tree count)
            break
        }

        return values
    }

    private func baseValues() -> [String: String] {
        return [
            Properties.adultFilter: User.shared.adultFilter.rawValue,
            Properties.marketCode: User.shared.marketCode.rawValue,
            Properties.language: Language.current.rawValue,
            Properties.suggestions: String(User.shared.autoComplete ? 1 : 0),
            Properties.personalized: String(User.shared.personalized ? 1 : 0),
            Properties.marketApplied: "1",
            Properties.marketReapplied: "1",
            Properties.deviceType: "mobile",
            Properties.firstSearch: "0",
            Properties.addon: "1"
        ]
    }

    private func extractMainProperties(_ properties: [String: String]) {
        var user = User.shared

        properties[Properties.userId].map {
            user.id = $0
        }

        properties[Properties.treeCount].flatMap(Int.init).map {
            // tree count should only increase or be reset to 0 on logout
            if $0 == 0 || $0 > user.searchCount {
                user.searchCount = $0
            }
        }

        properties[Properties.marketCode].flatMap(Local.init).map {
            user.marketCode = $0
        }

        properties[Properties.adultFilter].flatMap(AdultFilter.init).map {
            user.adultFilter = $0
        }

        properties[Properties.personalized].flatMap(Int.init).map { NSNumber(value: $0) }.flatMap(Bool.init).map {
            user.personalized = $0
        }

        properties[Properties.suggestions].map {
            user.autoComplete = ($0 as NSString).boolValue
        }

        User.shared = user
    }
}
