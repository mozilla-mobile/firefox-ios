/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Utility functions related to SUMO.
public struct SupportUtils {
    /// Construct a NSURL pointing to a specific topic on SUMO. The topic should be a non-escaped string. It will
    /// be properly escaped by this function.
    ///
    /// The resulting NSURL will include the app version, operating system and locale code. For example, a topic
    /// "cheese" will be turned into a link that looks like https://support.mozilla.org/1/mobile/2.0/iOS/en-US/cheese
    public static func URLForTopic(topic: String) -> NSURL? {
        guard let escapedTopic = topic.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) else {
            return nil
        }
        return NSURL(string: "https://support.mozilla.org/1/mobile/\(AppInfo.appVersion)/iOS/\(NSLocale.currentLocale().localeIdentifier)/\(escapedTopic)")
    }
}
