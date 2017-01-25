/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class RequestDesktopSiteActivity: UIActivity {
    fileprivate let requestMobileSite: Bool
    fileprivate let callback: () -> Void

    init(requestMobileSite: Bool, callback: @escaping () -> Void) {
        self.requestMobileSite = requestMobileSite
        self.callback = callback
    }

    override var activityTitle: String? {
        return requestMobileSite ?
            NSLocalizedString("Request Mobile Site", comment: "Share action title") :
            NSLocalizedString("Request Desktop Site", comment: "Share action title")
    }

    override var activityImage: UIImage? {
        return requestMobileSite ?
            UIImage(named: "shareRequestMobileSite") :
            UIImage(named: "shareRequestDesktopSite")
    }

    override func perform() {
        callback()
        activityDidFinish(true)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}
