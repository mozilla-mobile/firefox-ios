// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

class SiteImageModelTests: XCTestCase {
    let siteURL = URL(string: "https://www.mozilla.org")!
    let faviconURL = URL(string: "https://www.mozilla.org/media/img/favicons/mozilla/apple-touch-icon.8cbe9c835c00.png")!

    func testFaviconURL_isCacheKey_whenProvidedForFavicon() async {
        let model = SiteImageModel(id: UUID(), imageType: .favicon, siteURL: siteURL, resourceURL: faviconURL)

        XCTAssertEqual(model.cacheKey, faviconURL.absoluteString)
    }

    func testShortDomain_isCacheKey_forFavicon() async {
        let model = SiteImageModel(id: UUID(), imageType: .favicon, siteURL: siteURL)

        XCTAssertEqual(model.cacheKey, siteURL.shortDomain)
    }

    func testAbsolutePath_isCacheKey_forHeroImage() async {
        let model = SiteImageModel(id: UUID(), imageType: .heroImage, siteURL: siteURL)

        XCTAssertEqual(model.cacheKey, siteURL.absoluteString)
    }

    func testShortDomain_isCacheKey_whenResourceURLProvidedForHeroImage() async {
        let model = SiteImageModel(id: UUID(), imageType: .heroImage, siteURL: siteURL, resourceURL: faviconURL)

        XCTAssertEqual(model.cacheKey, siteURL.absoluteString)
    }

    // MARK: - Test generateCacheKey

    func testGenerateCacheKey_returnsShortDomain_forFavicon() async {
        let cacheKey = SiteImageModel.generateCacheKey(siteURL: siteURL, type: .favicon)

        XCTAssertEqual(cacheKey, siteURL.shortDomain)
    }

    func testGenerateCacheKey_returnsAbsolutePath_forHeroImage() async {
        let cacheKey = SiteImageModel.generateCacheKey(siteURL: siteURL, type: .heroImage)

        XCTAssertEqual(cacheKey, siteURL.absoluteString)
    }
}
