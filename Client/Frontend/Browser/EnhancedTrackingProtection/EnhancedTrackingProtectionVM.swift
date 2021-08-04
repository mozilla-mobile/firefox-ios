/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage

class EnhancedTrackingProtectionMenuVM {
    var tab: Tab
    var profile: Profile?

    var websiteTitle: String {
        return tab.url?.baseDomain ?? ""
    }
//            let trackingProtectionMenu = self.getTrackingSubMenu(for: tab)
    var favIcon: UIImage?

    init(tab: Tab, profile: Profile?) {
        self.tab = tab
        self.profile = profile

        getFavicon()
    }

    func getFavicon() {
        let itemURL = tab.url?.absoluteString ?? ""
        let site = Site(url: itemURL, title: tab.displayTitle)

        profile?.favicons.getFaviconImage(forSite: site).uponQueue(.main, block: { result in
            guard let image = result.successValue else { return }
            self.favIcon = image
        })
    }

    func updateDetails() {
        
    }
}
