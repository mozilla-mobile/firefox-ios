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

    public var searchAutocomplete: URL {
        // For now only production to avoid messing with Firefox's logic to include CF headers.
        URL(string: "https://ac.ecosia.org/autocomplete")!
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
        case .production, .debug:
            return "sp.ecosia.org"
        case .staging:
            return "https://osc.ecosia-staging.xyz"
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

    public var support: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://de.support.ecosia.org/")!
        case .fr:
            return URL(string: "https://fr.support.ecosia.org/")!
        default:
            return URL(string: "https://support.ecosia.org/")!
        }
    }

    public var helpPage: URL {
        switch Language.current {
        case .de:
            return support.appendingPathComponent("category/695-ecosia-ios-app")
        case .fr:
            return support.appendingPathComponent("category/805-ecosia-ios-app")
        default:
            return support.appendingPathComponent("category/827-ecosia-ios-app")
        }
    }

    public var trackingProtectionHelpPage: URL {
        switch Language.current {
        case .de:
            return support.appendingPathComponent("article/1024-tracking-protection-mobile")
        case .fr:
            return support.appendingPathComponent("article/1025-tracking-protection")
        default:
            return support.appendingPathComponent("article/1023-tracking-protection")
        }
    }

    public var privateBrowsingLearnMore: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://de.support.ecosia.org/article/730-private-browsing-de")!
        case .fr:
            return URL(string: "https://fr.support.ecosia.org/article/956-private-browsing-fr")!
        default:
            return URL(string: "https://support.ecosia.org/article/651-private-browsing-en")!
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

    public enum AIChatOrigin: String {
        case ntp = "newtabbutton"
        case autocomplete = "autocomplete_app"
        case omnibox = "omnibox_app"
    }

    /// Builds the AI chat URL, optionally tagged with where the user came
    /// from (`origin`), seeded with a `query` to start the conversation,
    /// with optional `files` for attachment routing, and extended with
    /// `additionalQueryItems` (e.g. an omnibox chat mode's backend flags).
    /// Centralizing the parameters here keeps callers from having to know
    /// the URL's query-item conventions.
    public func aiChat(
        origin: AIChatOrigin? = nil,
        query: String? = nil,
        files: [AIChatFileQuery] = [],
        additionalQueryItems: [URLQueryItem] = []
    ) -> URL {
        let baseURL = root.appendingPathComponent("ai-chat")
        var items: [URLQueryItem] = []
        if let origin {
            items.append(URLQueryItem(name: "origin", value: origin.rawValue))
        }
        if let query {
            items.append(URLQueryItem(name: "q", value: query))
        }
        if !files.isEmpty, let filesJSON = AIChatFileQuery.urlQueryValue(files) {
            items.append(URLQueryItem(name: "files", value: filesJSON))
        }
        items.append(contentsOf: additionalQueryItems)
        guard !items.isEmpty else { return baseURL }
        return baseURL.appendingPercentEncodedQueryItems(items)
    }

    public var storeWriteReviewPage: URL {
        URL(string: "https://itunes.apple.com/app/id670881887?action=write-review")!
	}

    public var seedCounterInfo: URL {
        URL(string: "https://support.ecosia.org/article/844-seed-counter")!
    }

    // CDN-hosted JSON list of rotating USP titles shown above the NTP impact tiles.
    public var rotatingTitles: URL {
        switch self {
        case .production, .debug:
            return URL(string: "https://cdn.ecosia.org/rotating-titles/v1/titles.json")!
        case .staging:
            return URL(string: "https://cdn.ecosia-staging.xyz/rotating-titles/v1/titles.json")!
        }
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

/// File metadata for the web AI chat `files` URL query parameter.
/// Matches `nxt-ai-search` omnibox routing (`fileId`, `filename`, `mimeType`, `sizeBytes`).
public struct AIChatFileQuery: Codable, Equatable, Sendable {
    public let fileId: String
    public let filename: String
    public let mimeType: String
    public let sizeBytes: Int

    public init(fileId: String, filename: String, mimeType: String, sizeBytes: Int) {
        self.fileId = fileId
        self.filename = Self.filenameEnsuringExtension(filename, mimeType: mimeType)
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
    }

    /// The AI Worker validates the extension in `filename` (e.g. `IMG_0111` → rejected, `IMG_0111.jpg` → ok).
    static func filenameEnsuringExtension(_ filename: String, mimeType: String) -> String {
        if !URL(fileURLWithPath: filename).pathExtension.isEmpty {
            return filename
        }
        guard let ext = preferredExtension(for: mimeType) else { return filename }
        return "\(filename).\(ext)"
    }

    static func preferredExtension(for mimeType: String) -> String? {
        switch mimeType.lowercased() {
        case "image/jpeg": return "jpg"
        case "image/png": return "png"
        case "application/pdf": return "pdf"
        case "text/plain": return "txt"
        case "application/msword": return "doc"
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document": return "docx"
        case "application/vnd.ms-powerpoint": return "ppt"
        case "application/vnd.openxmlformats-officedocument.presentationml.presentation": return "pptx"
        default: return nil
        }
    }

    static func urlQueryValue(_ files: [AIChatFileQuery]) -> String? {
        guard let data = try? JSONEncoder().encode(files) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
