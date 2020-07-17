/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TodayModel {
    static var copiedURL: URL?
    static var searchedText: String?

    var scheme: String {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
            // Something went wrong/weird, but we should fallback to the public one.
            return "firefox"
        }
        return string
    }
}
