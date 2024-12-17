/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum SupportTopic: CaseIterable {
    case searchSuggestions
    case usageData
    case studies
    case autofillDomain
    case trackingProtection
    case addSearchEngine
    case mobileCrashReports

    public var slug: String {
        switch self {
        case .searchSuggestions:
            return "search-suggestions-focus-ios"
        case .usageData:
            return "usage-data"
        case .studies:
            return "studies-focus-ios"
        case .autofillDomain:
            return "autofill-domain-ios"
        case .trackingProtection:
            return "tracking-protection-focus-ios"
        case .addSearchEngine:
            return "add-search-engine-ios"
        case .mobileCrashReports:
            return "mobile-crash-reports"
        }
    }

    static let fallbackURL = "https://support.mozilla.org"
}

extension URL {
    /// Construct an URL pointing to a specific topic on SUMO. The topic comes from the Topics enum.
    ///
    /// The resulting URL will include the app version, operating system and locale code. For example, a topic
    /// "cheese" will be turned into a link that looks like https://support.mozilla.org/1/mobile/2.0/iOS/en-US/cheese
    ///
    /// If for some reason the URL could not be created, a default URL to support.mozilla.org is returned. This is
    /// a very rare case that should not happen except in the rare case where the URL may be dynamically formatted.
    init(forSupportTopic topic: SupportTopic) {
        guard let escapedTopic = topic.slug.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed), let languageIdentifier = Locale.preferredLanguages.first else {
            self.init(string: SupportTopic.fallbackURL)!
            return
        }
        self.init(string: "https://support.mozilla.org/1/mobile/\(AppInfo.shortVersion)/iOS/\(languageIdentifier)/\(escapedTopic)")!
    }
}
