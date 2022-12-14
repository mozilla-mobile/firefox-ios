// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import SiteImageView

final class SiteImageFetcherTests: XCTestCase {
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
        let siteURL = URL(string: "https://www.example.hello.com")!
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let result = await subject.getImage(siteURL: siteURL,
                                            type: .favicon,
                                            id: UUID())

        XCTAssertEqual(result.domain, "example.hello")
        XCTAssertEqual(result.siteURL, siteURL)
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .favicon)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedFaviconURL)
        XCTAssertEqual(imageHandler.capturedDomain, "example.hello")
        XCTAssertNil(imageHandler.capturedSiteURL)
    }

    func testFavicon_wrongURL_useFallbackDomain() async {
        // URL without https://
        let siteURL = URL(string: "www.example.hello.com")!
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let result = await subject.getImage(siteURL: siteURL,
                                            type: .favicon,
                                            id: UUID())

        XCTAssertEqual(result.domain, "www.example.hello.com")
        XCTAssertEqual(imageHandler.capturedDomain, "www.example.hello.com")
    }

    func testFavicon_faviconURLFound_generateFavicon() async {
        let faviconURL = URL(string: "www.mozilla.com/resource")!
        let siteURL = URL(string: "https://www.mozilla.com")!
        urlHandler.faviconURL = faviconURL
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let result = await subject.getImage(siteURL: siteURL,
                                            type: .favicon,
                                            id: UUID())

        XCTAssertEqual(result.domain, "mozilla")
        XCTAssertEqual(result.siteURL, siteURL)
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .favicon)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertEqual(imageHandler.capturedFaviconURL, faviconURL)
        XCTAssertEqual(imageHandler.capturedDomain, "mozilla")
        XCTAssertNil(imageHandler.capturedSiteURL)
    }

    // MARK: - Hero image

    func testHeroImage_heroImageNotFound_returnsFavicon() async {
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let siteURL = URL(string: "https://www.firefox.com")!
        let result = await subject.getImage(siteURL: siteURL,
                                            type: .heroImage,
                                            id: UUID())

        XCTAssertEqual(result.domain, "firefox")
        XCTAssertEqual(result.siteURL, siteURL)
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .heroImage)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedFaviconURL)
        XCTAssertEqual(imageHandler.capturedDomain, "firefox")
        XCTAssertEqual(imageHandler.capturedSiteURL, siteURL)
    }

    func testHeroImage_heroImageFound_returnsHeroImage() async {
        imageHandler.heroImage = UIImage()
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let siteURL = URL(string: "https://www.focus.com")!
        let result = await subject.getImage(siteURL: siteURL,
                                            type: .heroImage,
                                            id: UUID())

        XCTAssertEqual(result.domain, "focus")
        XCTAssertEqual(result.siteURL, siteURL)
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .heroImage)
        XCTAssertNotNil(result.heroImage)
        XCTAssertNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedFaviconURL)
        XCTAssertEqual(imageHandler.capturedDomain, "focus")
        XCTAssertEqual(imageHandler.capturedSiteURL, siteURL)
    }
}

// MARK: - MockFaviconURLHandler
private class MockFaviconURLHandler: FaviconURLHandler {
    var faviconURL: URL?
    var capturedImageModel: SiteImageModel?

    func getFaviconURL(site: SiteImageModel) async throws -> SiteImageModel {
        capturedImageModel = site
        return SiteImageModel(id: site.id,
                              expectedImageType: site.expectedImageType,
                              siteURL: site.siteURL,
                              domain: site.domain,
                              faviconURL: faviconURL)
    }
}

// MARK: - MockImageHandler
private class MockImageHandler: ImageHandler {
    var faviconImage = UIImage()
    var capturedFaviconURL: URL?
    var capturedDomain: String?

    func fetchFavicon(imageURL: URL?, domain: String) async -> UIImage {
        capturedFaviconURL = imageURL
        capturedDomain = domain
        return faviconImage
    }

    var capturedSiteURL: URL?
    var heroImage: UIImage?

    func fetchHeroImage(siteURL: URL, domain: String) async throws -> UIImage {
        capturedSiteURL = siteURL
        capturedDomain = domain
        if let image = heroImage {
            return image
        } else {
            throw SiteImageError.noHeroImage
        }
    }
}
