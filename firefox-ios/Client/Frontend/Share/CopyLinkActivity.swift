// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class CopyLinkActivity: CustomAppActivity {
    // Copy link is only available for URL that are not files
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return !url.isFile
    }

    override func prepare(withActivityItems activityItems: [Any]) {}

    override func perform() {
        UIPasteboard.general.string = url.absoluteString
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shareSheet,
                                     value: .shareCopyLink,
                                     extras: nil)
        activityDidFinish(true)
    }
}
