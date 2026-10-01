// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// Utility functions related to SUMO and Webcompat
public struct SupportUtils {
    public static var URLForPrivateBrowsingLearnMore: URL? {
        // Returns the predefined URL associated to private homepage message card learn more action.
        return URL(string: "https://support.mozilla.org/en-US/kb/common-myths-about-private-browsing?as=u&utm_source=inproduct")
    }

    public static var URLForGetHelp: URL? {
        // Returns the predefined URL associated to the menu's Get Help button action.
        return URL(string: "https://support.mozilla.org/products/ios")
    }

    public static var URLForPocketLearnMore: URL? {
        // Returns the predefined URL associated to homepage Pocket's Learn more action.
        return URL(string: "https://www.mozilla.org/firefox/pocket/?utm_source=ff_ios")
    }

    public static var URLForTermsOfUse: URL? {
        return URL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    public static var URLForPrivacyNotice: URL? {
        return URL(string: "https://www.mozilla.org/privacy/firefox/")
    }

    public static var URLForUpdatedPrivacyNotice: URL? {
        return URL(string: "https://www.mozilla.org/privacy/firefox/next/")
    }

    public static var URLForUpdatedPrivacyNoticeDiff: URL? {
        return URL(string: "https://www.mozilla.org/privacy/firefox/update/")
    }

    public static var URLForRelayAccountManagement: URL? {
        return URL(string: "https://relay.firefox.com/accounts/profile")
    }

    public static var URLForRelayMaskLearnMoreArticle: URL? {
        return URL(string: "https://support.mozilla.org/en-US/kb/relay-masks-ios")
    }

    public static var URLForConnectionNotSecureLearnMore: URL? {
        return URL(string: "https://support.mozilla.org/en-US/kb/what-does-your-connection-is-not-secure-mean")
    }

    public static func URLForTopic(_ topic: String, useMobilePath: Bool = true) -> URL? {
        // Construct a NSURL pointing to a specific topic on SUMO. The topic should be a non-escaped string. It will
        // be properly escaped by this function.
        //
        // The resulting NSURL will include the app version, operating system and locale code. For example, a topic
        // "cheese" will be turned into a link that looks like https://support.mozilla.org/1/mobile/2.0/iOS/en-US/cheese
        guard let escapedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let languageIdentifier = Locale.preferredLanguages.first
        else {
            return nil
        }
        let productPath = useMobilePath ? "mobile" : "firefox"
        return URL(string: "https://support.mozilla.org/1/\(productPath)/\(AppInfo.appVersion)/iOS/\(languageIdentifier)/\(escapedTopic)")
    }

    public static func URLForPrivacyNotice(source: String, campaign: String, content: String?) -> URL? {
        let defaultURL = URL(string: "https://www.mozilla.org/privacy/firefox")

        guard let languageIdentifier = Locale.preferredLanguages.first else {
            return defaultURL
        }

        var privacyNoticeString =
                    "https://www.mozilla.org/\(languageIdentifier)/privacy/firefox/?utm_medium=firefox-mobile&utm_source=\(source)&utm_campaign=\(campaign)"

        if let content {
            privacyNoticeString.append("&utm_content=\(content)")
        }

        return URL(string: privacyNoticeString) ?? defaultURL
    }
}
