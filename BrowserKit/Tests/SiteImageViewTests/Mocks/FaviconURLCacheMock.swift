// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
@testable import SiteImageView

actor FaviconURLCacheMock: FaviconURLCache {
    var url: URL?
    var error: SiteImageError?

    var getURLFromCacheCalledCount = 0
    var cacheURLCalledCount = 0

    var domain: ImageDomain?
    var faviconURL: URL?

    func setTestResult(url: URL? = nil, error: SiteImageError? = nil) {
        self.url = url
        self.error = error
    }

    func getURLFromCache(domain: ImageDomain) async throws -> URL {
        getURLFromCacheCalledCount += 1
        if let error = error {
            throw error
        }
        return url!
    }

    func cacheURL(domain: ImageDomain, faviconURL: URL) async {
        cacheURLCalledCount += 1
        self.domain = domain
        self.faviconURL = faviconURL
    }
}
