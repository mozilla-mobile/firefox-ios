// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

final class SiteImageHandlerTests: XCTestCase {
    private var urlHandler: MockFaviconURLHandler!
    private var imageHandler: MockImageHandler!

    override func setUp() {
        super.setUp()
        self.urlHandler = MockFaviconURLHandler()
        self.imageHandler = MockImageHandler()
    }

    override func tearDown() {
        super.tearDown()
        self.urlHandler = nil
        self.imageHandler = nil
    }

    // MARK: - Favicon

    func testFavicon_noFaviconURLFound_generatesFavicon() async {
        let siteURL = "https://www.example.hello.com"
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   expectedImageType: .favicon,
                                   siteURLString: siteURL)
        let result = await subject.getImage(site: model)

        XCTAssertEqual(result.cacheKey, "example.hello")
        XCTAssertEqual(result.siteURL, URL(string: siteURL))
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .favicon)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedSite?.faviconURL)
        XCTAssertEqual(imageHandler.capturedSite?.cacheKey, "example.hello")
    }

    func testFavicon_wrongURL_useFallbackDomain() async {
        // URL without https://
        let siteURL = "www.example.hello.com"
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   expectedImageType: .favicon,
                                   siteURLString: siteURL)
        let result = await subject.getImage(site: model)

        XCTAssertEqual(result.cacheKey, "www.example.hello.com")
        XCTAssertEqual(imageHandler.capturedSite?.cacheKey, "www.example.hello.com")
    }

    func testFavicon_faviconURLFound_generateFavicon() async {
        let faviconURL = URL(string: "www.mozilla.com/resource")!
        let siteURL = "https://www.mozilla.com"
        urlHandler.faviconURL = faviconURL
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   expectedImageType: .favicon,
                                   siteURLString: siteURL)
        let result = await subject.getImage(site: model)

        XCTAssertEqual(result.cacheKey, "mozilla")
        XCTAssertEqual(result.siteURL, URL(string: siteURL))
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .favicon)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertEqual(imageHandler.capturedSite?.faviconURL, faviconURL)
        XCTAssertEqual(imageHandler.capturedSite?.cacheKey, "mozilla")
    }

    func testFaviconIndirectDomain_faviconURLFound_generateFavicon() async {
        let siteURL = URL(string: "https://www.mozilla.com")
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   expectedImageType: .favicon,
                                   faviconURL: siteURL)
        let result = await subject.getImage(site: model)

        XCTAssertEqual(result.cacheKey, "https://www.mozilla.com")
        XCTAssertEqual(result.faviconURL?.absoluteString, "https://www.mozilla.com")
        XCTAssertEqual(result.expectedImageType, .favicon)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertEqual(imageHandler.capturedSite?.faviconURL?.absoluteString, "https://www.mozilla.com")
        XCTAssertEqual(imageHandler.capturedSite?.cacheKey, "https://www.mozilla.com")
    }

    // MARK: - Hero image

    func testHeroImage_heroImageNotFound_returnsFavicon() async {
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let siteURL = "https://www.firefox.com"
        let model = SiteImageModel(id: UUID(),
                                   expectedImageType: .heroImage,
                                   siteURLString: siteURL)
        let result = await subject.getImage(site: model)

        XCTAssertEqual(result.cacheKey, "https://www.firefox.com")
        XCTAssertEqual(result.siteURL, URL(string: siteURL))
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .heroImage)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedSite?.faviconURL)
        XCTAssertEqual(imageHandler.capturedSite?.cacheKey, "https://www.firefox.com")
        XCTAssertEqual(imageHandler.capturedSite?.siteURL, URL(string: siteURL))
    }

    func testHeroImage_heroImageFound_returnsHeroImage() async {
        imageHandler.heroImage = UIImage()
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let siteURL = "https://www.focus.com"
        let model = SiteImageModel(id: UUID(),
                                   expectedImageType: .heroImage,
                                   siteURLString: siteURL)
        let result = await subject.getImage(site: model)

        XCTAssertEqual(result.cacheKey, "https://www.focus.com")
        XCTAssertEqual(result.siteURL, URL(string: siteURL))
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .heroImage)
        XCTAssertNotNil(result.heroImage)
        XCTAssertNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedSite?.faviconURL)
        XCTAssertEqual(imageHandler.capturedSite?.cacheKey, "https://www.focus.com")
        XCTAssertEqual(imageHandler.capturedSite?.siteURL, URL(string: siteURL))
    }

    // Test cache
    func testCacheFavicon() {
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        subject.cacheFaviconURL(siteURL: URL(string: "https://firefox.com"),
                                faviconURL: URL(string: "https://firefox.com/favicon.ico"))

        XCTAssertEqual(urlHandler.faviconURL?.absoluteString, "https://firefox.com/favicon.ico")
        XCTAssertEqual(urlHandler.cacheKey, "firefox")
    }

    func testClearCache() {
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        subject.clearAllCaches()

        XCTAssertEqual(urlHandler.clearCacheCalled, 1)
        XCTAssertEqual(imageHandler.clearCacheCalledCount, 1)
    }
}

// MARK: - MockFaviconURLHandler
private class MockFaviconURLHandler: FaviconURLHandler {
    var faviconURL: URL?
    var capturedImageModel: SiteImageModel?
    var cacheKey: String?
    var cacheFaviconURLCalled = 0
    var clearCacheCalled = 0

    func getFaviconURL(site: SiteImageModel) async throws -> SiteImageModel {
        capturedImageModel = site
        return SiteImageModel(id: site.id,
                              expectedImageType: site.expectedImageType,
                              siteURLString: site.siteURLString,
                              siteURL: site.siteURL,
                              cacheKey: site.cacheKey,
                              faviconURL: faviconURL)
    }

    func cacheFaviconURL(cacheKey: String, faviconURL: URL) {
        self.cacheKey = cacheKey
        self.faviconURL = faviconURL
        cacheFaviconURLCalled += 1
    }

    func clearCache() {
        clearCacheCalled += 1
    }
}

// MARK: - MockImageHandler
private class MockImageHandler: ImageHandler {
    var faviconImage = UIImage()
    var heroImage: UIImage?
    var capturedSite: SiteImageModel?
    var clearCacheCalledCount = 0

    func fetchFavicon(site: SiteImageModel) async -> UIImage {
        capturedSite = site
        return faviconImage
    }

    func fetchHeroImage(site: SiteImageModel) async throws -> UIImage {
        capturedSite = site
        if let image = heroImage {
            return image
        } else {
            throw SiteImageError.noHeroImage
        }
    }

    func clearCache() {
        clearCacheCalledCount += 1
    }
}
