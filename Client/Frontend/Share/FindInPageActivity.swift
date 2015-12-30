/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class FindInPageActivity: UIActivity {
    private let callback: () -> ()

    init(callback: () -> ()) {
        self.callback = callback
    }

    override func activityTitle() -> String? {
        return NSLocalizedString("Find in Page", tableName: "FindInPage", comment: "Share action title")
    }

    override func activityImage() -> UIImage? {
        return UIImage(named: "shareFindInPage")
    }

    override func performActivity() {
        callback()
        activityDidFinish(true)
    }

    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return true
    }
}