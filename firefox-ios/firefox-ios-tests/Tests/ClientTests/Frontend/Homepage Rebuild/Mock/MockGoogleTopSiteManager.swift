// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

class MockGoogleTopSiteManager: GoogleTopSiteManagerProvider {
    private let mockSiteData: PinnedSite?
    var removeGoogleTopSiteCalledCount = 0

    init(mockSiteData: PinnedSite? = PinnedSite(
        site: Site(url: GoogleTopSiteManager.Constants.usUrl, title: "Google Test"),
        faviconResource: nil
    )) {
        self.mockSiteData = mockSiteData
    }
    var suggestedSiteData: PinnedSite? {
        return mockSiteData
    }

    func shouldAddGoogleTopSite(hasSpace: Bool) -> Bool {
        return hasSpace
    }

    func removeGoogleTopSite(site: Site) {
        removeGoogleTopSiteCalledCount += 1
    }
}
