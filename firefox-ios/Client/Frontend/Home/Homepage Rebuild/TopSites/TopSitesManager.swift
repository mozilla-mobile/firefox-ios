// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

// TODO: FXIOS-10165 - Add full logic + tests for retrieving top sites
class TopSitesManager {
    private let googleTopSiteManager: GoogleTopSiteManager

    init(
        googleTopSiteManager: GoogleTopSiteManager
    ) {
        self.googleTopSiteManager = googleTopSiteManager
    }

    func getTopSites() async -> [TopSiteState] {
        guard let googleTopSite = addGoogleTopSite() else {
            return []
        }
        return [googleTopSite]
    }

    private func addGoogleTopSite() -> TopSiteState? {
        guard let googleSite = googleTopSiteManager.suggestedSiteData else {
            return nil
        }
        return TopSiteState(site: googleSite)
    }
}
