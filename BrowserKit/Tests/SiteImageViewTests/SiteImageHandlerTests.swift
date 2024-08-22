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
    func testGetImage_favicon_noURL_fetchesFaviconURL() async {
        let faviconURLString = "https://www.mozilla.org/media/img/favicons/mozilla/apple-touch-icon.8cbe9c835c00.png"
        urlHandler.faviconURL = URL(string: faviconURLString)!
        let siteURL = URL(string: "https://www.mozilla.com")!
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   imageType: .favicon,
                                   siteURL: siteURL,
                                   resourceURL: nil) // No faviconURL yet
        _ = await subject.getImage(model: model)

        XCTAssertEqual(urlHandler.getFaviconURLCalled, 1, "getFaviconURLCalled should be called once")
    }

    func testGetImage_favicon_hasURL_doesNotFetchFaviconURL() async {
        let faviconURLString = "https://www.mozilla.org/media/img/favicons/mozilla/apple-touch-icon.8cbe9c835c00.png"
        let faviconURL = URL(string: faviconURLString)!
        let siteURL = URL(string: "https://www.mozilla.com")!
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   imageType: .favicon,
                                   siteURL: siteURL,
                                   resourceURL: faviconURL)
        _ = await subject.getImage(model: model)

        XCTAssertEqual(urlHandler.getFaviconURLCalled, 0, "getFaviconURLCalled should not be called")
    }

    func testGetImage_favicon_fetchesFavicon() async {
        let faviconURLString = "https://www.mozilla.org/media/img/favicons/mozilla/apple-touch-icon.8cbe9c835c00.png"
        let faviconURL = URL(string: faviconURLString)!
        let siteURL = URL(string: "https://www.mozilla.com")!
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   imageType: .favicon,
                                   siteURL: siteURL,
                                   resourceURL: faviconURL)
        _ = await subject.getImage(model: model)

        XCTAssertEqual(imageHandler.fetchFavicon, 1, "fetchFavicon should be called once")
        XCTAssertEqual(imageHandler.fetchHeroImageCalled, 0, "fetchHeroImageCalled should not be called")
    }

    func testGetImage_heroImage_hasHeroImage_fetchesHeroImage() async {
        let siteURL = URL(string: "https://www.mozilla.com")!
        imageHandler.heroImage = UIImage()
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   imageType: .heroImage,
                                   siteURL: siteURL)
        _ = await subject.getImage(model: model)

        XCTAssertEqual(imageHandler.fetchHeroImageCalled, 1, "fetchHeroImageCalled should be called once")
        XCTAssertEqual(urlHandler.getFaviconURLCalled, 0, "getFaviconURLCalled should not be called")
        XCTAssertEqual(imageHandler.fetchFavicon, 0, "fetchFavicon should not be called")
    }

    func testGetImage_heroImage_noHeroImage_returnsFavicon() async {
        let faviconURLString = "https://www.mozilla.org/media/img/favicons/mozilla/apple-touch-icon.8cbe9c835c00.png"
        urlHandler.faviconURL = URL(string: faviconURLString)!

        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let siteURL = URL(string: "https://www.mozilla.com")!
        let model = SiteImageModel(id: UUID(),
                                   imageType: .heroImage,
                                   siteURL: siteURL)
        _ = await subject.getImage(model: model)

        XCTAssertEqual(imageHandler.fetchHeroImageCalled, 1, "fetchHeroImageCalled should be called once")
        XCTAssertEqual(urlHandler.getFaviconURLCalled, 1, "getFaviconURLCalled should be called once")
        XCTAssertEqual(imageHandler.fetchFavicon, 1, "fetchFavicon should be called once as fallback")
    }

    // Test cache
    func testCacheFavicon() {
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let siteURL = URL(string: "https://firefox.com")!
        let faviconURL = URL(string: "https://firefox.com/favicon.ico")!
        subject.cacheFaviconURL(siteURL: siteURL,
                                faviconURL: faviconURL)

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
    var cacheKey: String?
    var getFaviconURLCalled = 0
    var cacheFaviconURLCalled = 0
    var clearCacheCalled = 0

    func getFaviconURL(model: SiteImageModel) async throws -> URL {
        getFaviconURLCalled += 1
        return faviconURL!
    }

    func cacheFaviconURL(cacheKey: String, faviconURL: URL) {
        cacheFaviconURLCalled += 1
        self.cacheKey = cacheKey
        self.faviconURL = faviconURL
    }

    func clearCache() {
        clearCacheCalled += 1
    }
}

// MARK: - MockImageHandler
private class MockImageHandler: ImageHandler {
    var faviconImage = UIImage()
    var heroImage: UIImage?
    var fetchFavicon = 0
    var fetchHeroImageCalled = 0
    var clearCacheCalledCount = 0

    func fetchFavicon(imageModel: SiteImageModel) async -> UIImage {
        fetchFavicon += 1
        return faviconImage
    }

    func fetchHeroImage(imageModel: SiteImageModel) async throws -> UIImage {
        fetchHeroImageCalled += 1
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
