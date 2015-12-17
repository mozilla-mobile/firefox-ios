/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

@available(iOS 9, *)
class RequestDesktopSiteActivity: UIActivity {
    private let requestMobileSite: Bool
    private let callback: () -> ()

    init(requestMobileSite: Bool, callback: () -> ()) {
        self.requestMobileSite = requestMobileSite
        self.callback = callback
    }

    override func activityTitle() -> String? {
        return requestMobileSite ?
            NSLocalizedString("Request Mobile Site", comment: "Share action title") :
            NSLocalizedString("Request Desktop Site", comment: "Share action title")
    }

    override func activityImage() -> UIImage? {
        return requestMobileSite ?
            UIImage(named: "shareRequestMobileSite") :
            UIImage(named: "shareRequestDesktopSite")
    }

    override func performActivity() {
        callback()
        activityDidFinish(true)
    }

    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return true
    }
}