// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum URLProvider {

    case production
    case staging
    case debug

    // MARK: - Public Properties

    public var domain: String {
        switch self {
        case .production, .debug:
            return "ecosia.org"
        case .staging:
            return "ecosia-staging.xyz"
        }
    }

    public var root: URL {
        URL(string: "https://www.\(domain)")!
    }

    public var apiRoot: URL {
        URL(string: "https://api.\(domain)")!
    }

    public var snowplowMicro: String? {
        switch self {
        case .staging:
            return "https://www.\(domain)/analytics-test-micro"
        case .production, .debug:
            return nil
        }
    }

    public var snowplow: String {
        switch self {
        case .production:
            return "sp.ecosia.org"
        case .staging, .debug:
            return "org-ecosia-prod1.mini.snplow.net"
        }
    }

    var unleash: String {
        switch self {
        case .production, .debug:
            return "prod"
        case .staging:
            return "staging"
        }
    }

    public var brazeEndpoint: String {
        "sdk.fra-02.braze.eu"
    }

    public var statistics: URL {
        URL(string: "https://d2wfixp891z15b.cloudfront.net")!
    }

    public var financialReportsData: URL {
        URL(string: "https://s3.amazonaws.com/blog-en.ecosia.org/financial-reports/data.json")!
    }

    public var privacy: URL {
        URL(string: "https://www.ecosia.org/privacy")!
    }

    public var faq: URL {
        URL(string: "https://ecosia.helpscoutdocs.com/")!
    }

    public var terms: URL {
        URL(string: "https://www.ecosia.org/terms-of-service")!
    }

    public var aboutCounter: URL {
        URL(string: "https://ecosia.helpscoutdocs.com/article/369-impact-counter")!
    }

    public var bookmarksHelp: URL {
        URL(string: "https://ecosia.helpscoutdocs.com/article/458-import-export-bookmarks")!
    }

    public var referHelp: URL {
        URL(string: "https://ecosia.helpscoutdocs.com/article/358-refer-a-friend-ios-only")!
    }

    public var financialReports: URL {
        switch Language.current {
        case .de:
            return blog.appendingPathComponent("ecosia-finanzberichte-baumplanzbelege/")
        case .fr:
            return blog.appendingPathComponent("rapports-financiers-recus-de-plantations-arbres/")
        default:
            return blog.appendingPathComponent("ecosia-financial-reports-tree-planting-receipts/")
        }
    }

    public var blog: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://de.blog.ecosia.org/")!
        case .fr:
            return URL(string: "https://fr.blog.ecosia.org/")!
        default:
            return URL(string: "https://blog.ecosia.org/")!
        }
    }

    public var trees: URL {
        switch Language.current {
        case .de:
            return blog.appendingPathComponent("tag/projekte/")
        case .fr:
            return blog.appendingPathComponent("tag/projets/")
        default:
            return blog.appendingPathComponent("tag/where-does-ecosia-plant-trees/")
        }
    }

    public var betaProgram: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://ecosia.typeform.com/to/catmFLuA")!
        case .fr:
            return URL(string: "https://ecosia.typeform.com/to/oaFZzT0F")!
        default:
            return URL(string: "https://ecosia.typeform.com/to/EeMLqL3X")!
        }
    }

    public var betaFeedback: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://ecosia.typeform.com/to/pIQ3uwp9")!
        case .fr:
            return URL(string: "https://ecosia.typeform.com/to/PRw7550n")!
        default:
            return URL(string: "https://ecosia.typeform.com/to/LlUGlFT9")!
        }
    }

    public var helpPage: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://de.support.ecosia.org/category/695-ecosia-ios-app")!
        case .fr:
            return URL(string: "https://fr.support.ecosia.org/category/805-ecosia-ios-app")!
        default:
            return URL(string: "https://support.ecosia.org/category/827-ecosia-ios-app")!
        }
    }

    public var notifications: URL {
        let url = URL(string: "https://api.ecosia.org/v1/notifications")!
        return url.appendingQueryItems([
            .init(name: "language", value: Language.current.rawValue),
            .init(name: "market", value: User.shared.marketCode.rawValue),
            .init(name: "limit", value: "50")
        ])
    }

    public enum AISearchOrigin: String {
        case ntp = "newtabbutton"
        case autocomplete = "autocomplete_app"
    }
    public func aiSearch(origin: AISearchOrigin?) -> URL {
        let baseURL = root.appendingPathComponent("ai-search")
        guard let origin = origin else {
            return baseURL
        }

        return baseURL.appendingQueryItems([URLQueryItem(name: "origin", value: origin.rawValue)])
    }

    public var storeWriteReviewPage: URL {
        URL(string: "https://itunes.apple.com/app/id670881887?action=write-review")!
	}

    public var seedCounterInfo: URL {
        URL(string: "https://support.ecosia.org/article/844-seed-counter")!
    }

    public var profileURL: URL {
        root.appendingPathComponent("accounts/profile")
    }

    // MARK: - Authentication URL Patterns

    /// URL paths that indicate errors in either the signUp or signOut flow
    public var errorPaths: [String] {
        ["/accounts/error"]
    }

    // MARK: - Authentication URLs

    /// Complete URL for user login/sign-up flow
    public var signUpURL: URL {
        root.appendingPathComponent("accounts/sign-up")
    }

    /// Complete URL for user sign-in flow
    public var signInURL: URL {
        root.appendingPathComponent("accounts/sign-in")
    }

    /// Complete URL for user logout/sign-out flow
    public var logoutURL: URL {
        root.appendingPathComponent("accounts/sign-out")
    }

    /// The API Identifier matching the `audience` parameter used by Auth0 when creating the `WebAuth`
    public var authApiAudience: URL {
        URL(string: "https://auth0.api.ecosia.org/v1/accounts/web")!
    }

    // MARK: - Auth0 Configuration

    /// Auth0 domain for authentication (custom domain)
    public var auth0Domain: String {
        "login.\(domain)"
    }

    /// Auth0 cookie domain for session management
    /// Returns the same value as `auth0Domain` since they must match for custom domain authentication
    public var auth0CookieDomain: String {
        auth0Domain
    }
}
