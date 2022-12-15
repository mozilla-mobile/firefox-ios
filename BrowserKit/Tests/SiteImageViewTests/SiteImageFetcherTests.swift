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
        let siteURL = "https://www.example.hello.com"
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let result = await subject.getImage(urlStringRequest: siteURL,
                                            type: .favicon,
                                            id: UUID())

        XCTAssertEqual(result.domain?.baseDomain, "example.hello")
        XCTAssertEqual(result.siteURL, URL(string: siteURL))
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .favicon)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedFaviconURL)
        XCTAssertEqual(imageHandler.capturedDomain?.baseDomain, "example.hello")
        XCTAssertNil(imageHandler.capturedSiteURL)
    }

    func testFavicon_wrongURL_useFallbackDomain() async {
        // URL without https://
        let siteURL = "www.example.hello.com"
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let result = await subject.getImage(urlStringRequest: siteURL,
                                            type: .favicon,
                                            id: UUID())

        XCTAssertEqual(result.domain?.baseDomain, "www.example.hello.com")
        XCTAssertEqual(imageHandler.capturedDomain?.baseDomain, "www.example.hello.com")
    }

    func testFavicon_faviconURLFound_generateFavicon() async {
        let faviconURL = URL(string: "www.mozilla.com/resource")!
        let siteURL = "https://www.mozilla.com"
        urlHandler.faviconURL = faviconURL
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let result = await subject.getImage(urlStringRequest: siteURL,
                                            type: .favicon,
                                            id: UUID())

        XCTAssertEqual(result.domain?.baseDomain, "mozilla")
        XCTAssertEqual(result.siteURL, URL(string: siteURL))
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .favicon)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertEqual(imageHandler.capturedFaviconURL, faviconURL)
        XCTAssertEqual(imageHandler.capturedDomain?.baseDomain, "mozilla")
        XCTAssertNil(imageHandler.capturedSiteURL)
    }

    // MARK: - Hero image

    func testHeroImage_heroImageNotFound_returnsFavicon() async {
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let siteURL = "https://www.firefox.com"
        let result = await subject.getImage(urlStringRequest: siteURL,
                                            type: .heroImage,
                                            id: UUID())

        XCTAssertEqual(result.domain?.baseDomain, "firefox")
        XCTAssertEqual(result.siteURL, URL(string: siteURL))
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .heroImage)
        XCTAssertNil(result.heroImage)
        XCTAssertNotNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedFaviconURL)
        XCTAssertEqual(imageHandler.capturedDomain?.baseDomain, "firefox")
        XCTAssertEqual(imageHandler.capturedSiteURL, URL(string: siteURL))
    }

    func testHeroImage_heroImageFound_returnsHeroImage() async {
        imageHandler.heroImage = UIImage()
        let subject = DefaultSiteImageFetcher(urlHandler: urlHandler,
                                              imageHandler: imageHandler)
        let siteURL = "https://www.focus.com"
        let result = await subject.getImage(urlStringRequest: siteURL,
                                            type: .heroImage,
                                            id: UUID())

        XCTAssertEqual(result.domain?.baseDomain, "focus")
        XCTAssertEqual(result.siteURL, URL(string: siteURL))
        XCTAssertEqual(result.faviconURL, nil)
        XCTAssertEqual(result.expectedImageType, .heroImage)
        XCTAssertNotNil(result.heroImage)
        XCTAssertNil(result.faviconImage)

        XCTAssertNil(imageHandler.capturedFaviconURL)
        XCTAssertEqual(imageHandler.capturedDomain?.baseDomain, "focus")
        XCTAssertEqual(imageHandler.capturedSiteURL, URL(string: siteURL))
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
                              urlStringRequest: site.urlStringRequest,
                              siteURL: site.siteURL,
                              domain: site.domain,
                              faviconURL: faviconURL)
    }
}

// MARK: - MockImageHandler
private class MockImageHandler: ImageHandler {
    var faviconImage = UIImage()
    var capturedFaviconURL: URL?
    var capturedDomain: ImageDomain?

    func fetchFavicon(imageURL: URL?, domain: ImageDomain, expectedType: SiteImageType) async -> UIImage {
        capturedFaviconURL = imageURL
        capturedDomain = domain
        return faviconImage
    }

    var capturedSiteURL: URL?
    var heroImage: UIImage?

    func fetchHeroImage(siteURL: URL, domain: ImageDomain) async throws -> UIImage {
        capturedSiteURL = siteURL
        capturedDomain = domain
        if let image = heroImage {
            return image
        } else {
            throw SiteImageError.noHeroImage
        }
    }
}
