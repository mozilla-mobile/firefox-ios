// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

class MockGoogleTopSiteManager: GoogleTopSiteManagerProvider {
    private let mockSiteData: Site?
    var removeGoogleTopSiteCalledCount = 0

    init(
        mockSiteData: Site? = Site.createPinnedSite(
            url: GoogleTopSiteManager.Constants.usUrl,
            title: "Google Test",
            isGooglePinnedTile: true
        )
    ) {
        self.mockSiteData = mockSiteData
    }

    var pinnedSiteData: Site? {
        return mockSiteData
    }

    func shouldAddGoogleTopSite(hasSpace: Bool) -> Bool {
        return hasSpace
    }

    func removeGoogleTopSite(site: Site) {
        removeGoogleTopSiteCalledCount += 1
    }
}
