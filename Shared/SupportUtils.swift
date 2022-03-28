// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit

/// Utility functions related to SUMO and Webcompat
public struct SupportUtils {
    public static func URLForTopic(_ topic: String) -> URL? {
        /// Construct a NSURL pointing to a specific topic on SUMO. The topic should be a non-escaped string. It will
        /// be properly escaped by this function.
        ///
        /// The resulting NSURL will include the app version, operating system and locale code. For example, a topic
        /// "cheese" will be turned into a link that looks like https://support.mozilla.org/1/mobile/2.0/iOS/en-US/cheese
        guard let escapedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let languageIdentifier = Locale.preferredLanguages.first
        else {
            return nil
        }
        return URL(string: "https://support.mozilla.org/1/mobile/\(AppInfo.appVersion)/iOS/\(languageIdentifier)/\(escapedTopic)")
    }

    public static func URLForReportSiteIssue(_ siteUrl: String?) -> URL? {
        /// Construct a NSURL pointing to the webcompat.com server to report an issue.
        ///
        /// It specifies the source as mobile-reporter. This helps the webcompat server to classify the issue.
        /// It also adds browser-firefox-ios to the labels in the URL to make it clear
        /// that this about Firefox on iOS. It makes it easier for webcompat people doing triage and diagnostics.
        /// It adds a device-type label to help discriminating in between tablet and mobile devices.
        let deviceType: String
        if UIDevice.current.userInterfaceIdiom == .pad {
            deviceType = "device-tablet"
        } else {
            deviceType = "device-mobile"
        }
        guard let escapedUrl = siteUrl?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else {
            return nil
        }
        return URL(string: "https://webcompat.com/issues/new?src=mobile-reporter&label=browser-firefox-ios&label=\(deviceType)&url=\(escapedUrl)")
    }
}
