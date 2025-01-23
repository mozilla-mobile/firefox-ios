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
                                   siteResource: nil) // No faviconURL yet
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
                                   siteResource: .remoteURL(url: faviconURL))
        _ = await subject.getImage(model: model)

        XCTAssertEqual(urlHandler.getFaviconURLCalled, 0, "getFaviconURLCalled should not be called")
    }

    func testGetImage_favicon_noURL_stillCallsImageHandler_fetchFavicon() async {
        let siteURL = URL(string: "https://www.mozilla.com")!
        let subject = DefaultSiteImageHandler(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   imageType: .favicon,
                                   siteURL: siteURL,
                                   siteResource: nil)
        _ = await subject.getImage(model: model)

        XCTAssertEqual(urlHandler.getFaviconURLCalled, 1, "getFaviconURLCalled should be called")
        XCTAssertEqual(imageHandler.fetchFaviconCalledCount, 1, "fetchFavicon should be called")
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
                                   siteResource: .remoteURL(url: faviconURL))
        _ = await subject.getImage(model: model)

        XCTAssertEqual(imageHandler.fetchFaviconCalledCount, 1, "fetchFavicon should be called once")
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
        XCTAssertEqual(imageHandler.fetchFaviconCalledCount, 0, "fetchFavicon should not be called")
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
        XCTAssertEqual(imageHandler.fetchFaviconCalledCount, 1, "fetchFavicon should be called once as fallback")
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

    func testFavicon_multipleCalls_singletonQueue() async {
        // This method duplicates the behaviour currently seen in the app where each TopSiteItemCell has its own
        // SiteImageHandler, which is repeatedly deallocated and reallocated during reloads.
        let urlHandler1 = MockFaviconURLHandler()
        urlHandler1.sleepOnGetFaviconURL = true
        urlHandler1.faviconURL = URL(string: "https://firefox.com/favicon.ico")!

        let urlHandler2 = MockFaviconURLHandler()
        urlHandler2.sleepOnGetFaviconURL = true
        urlHandler1.faviconURL = URL(string: "https://firefox.com/favicon.ico")!

        let urlHandler3 = MockFaviconURLHandler()
        urlHandler3.sleepOnGetFaviconURL = true
        urlHandler1.faviconURL = URL(string: "https://firefox.com/favicon.ico")!

        let siteURL = URL(string: "https://www.example.hello.com")!
        let subject1 = DefaultSiteImageHandler(urlHandler: urlHandler1,
                                               imageHandler: imageHandler)
        let subject2 = DefaultSiteImageHandler(urlHandler: urlHandler2,
                                               imageHandler: imageHandler)
        let subject3 = DefaultSiteImageHandler(urlHandler: urlHandler3,
                                               imageHandler: imageHandler)
        let model = SiteImageModel(id: UUID(),
                                   imageType: .favicon,
                                   siteURL: siteURL)

        // A task group will start all these requests simultaneously
        let results = await withTaskGroup(of: (UIImage).self, returning: [UIImage].self) { group in
            for subject in [subject1, subject2, subject3] {
                for _ in 0...10 {
                    group.addTask {
                        return await subject.getImage(model: model)
                    }
                }
            }

            var images: [UIImage] = []

            for await image in group {
                images.append(image)
            }

            return images
        }

        XCTAssert(!results.isEmpty)

        // Only one of the urlHandlers should ever be called for multiple requests for the same resource. We don't
        // want repeated network requests to the same resource. Note that the order of threading will determine
        // which of the three urlHandlers is triggered.
        let urlHandlerCalls = [
            urlHandler1.getFaviconURLCalled,
            urlHandler2.getFaviconURLCalled,
            urlHandler3.getFaviconURLCalled
        ]
        XCTAssertEqual(urlHandlerCalls.reduce(0, +), 1, "Only one of the urlHandlers should ever be called")
        XCTAssertEqual(imageHandler.fetchFaviconCalledCount, 1, "image handler should only be called once")
    }
}

// MARK: - MockFaviconURLHandler
private class MockFaviconURLHandler: FaviconURLHandler {
    var faviconURL: URL?
    var cacheKey: String?
    var getFaviconURLCalled = 0
    var cacheFaviconURLCalled = 0
    var clearCacheCalled = 0
    var sleepOnGetFaviconURL = false

    func getFaviconURL(model: SiteImageModel) async throws -> URL {
        getFaviconURLCalled += 1

        if sleepOnGetFaviconURL {
            let sleepTime = UInt64(0.3 * Double(NSEC_PER_SEC))
            try? await Task.sleep(nanoseconds: sleepTime)
        }

        if let faviconURL {
            return faviconURL
        } else {
            throw SiteImageError.noFaviconURLFound
        }
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
    var fetchFaviconCalledCount = 0
    var fetchHeroImageCalled = 0
    var clearCacheCalledCount = 0

    func fetchFavicon(imageModel: SiteImageModel) async -> UIImage {
        fetchFaviconCalledCount += 1
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
