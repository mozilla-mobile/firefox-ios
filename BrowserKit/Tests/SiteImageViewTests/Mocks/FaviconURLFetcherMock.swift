// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SiteImageView

class FaviconURLFetcherMock: FaviconURLFetcher {
    var url: URL?
    var error: SiteImageError?
    var fetchFaviconURLCalledCount = 0
    var siteURL: URL?

    func fetchFaviconURL(siteURL: URL) async throws -> URL {
        fetchFaviconURLCalledCount += 1
        self.siteURL = siteURL

        if let error = error {
            throw error
        }
        return url!
    }
}
