// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

//protocol TileActionManager {
//    var tilePressedHandler: ((Site, Bool) -> Void)? { get set }
//    var tileLongPressedHandler: ((Site, UIView?) -> Void)? { get set }
//
//    func hideURLFromTopSites(_ site: Site)
//    func removePinTopSite(_ site: Site)
//    func pinTopSite(_ site: Site)
//}
//
//class TileActionManagerImplementation: TileActionManager {
//
//    var tilePressedHandler: ((Site, Bool) -> Void)?
//    var tileLongPressedHandler: ((Site, UIView?) -> Void)?
//
//    // Laurie - maybe dont need whole profile?
//    private var profile: Profile
//    init(profile: Profile) {
//        self.profile = profile
//    }
//
//    func hideURLFromTopSites(_ site: Site) {
//        guard let host = site.tileURL.normalizedHost else { return }
//        tileManager.topSiteHistoryManager.removeDefaultTopSitesTile(site: site)
//
//        profile.history.removeHostFromTopSites(host).uponQueue(.main) { [weak self] result in
//            guard result.isSuccess, let self = self else { return }
//            self.tileManager.refreshIfNeeded(forceTopSites: true)
//        }
//    }
//
//    func removePinTopSite(_ site: Site) {
//        tileManager.removePinTopSite(site: site)
//    }
//
//    func pinTopSite(_ site: Site) {
//        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
//            guard result.isSuccess else { return }
//            self.tileManager.refreshIfNeeded(forceTopSites: true)
//        }
//    }
//}
