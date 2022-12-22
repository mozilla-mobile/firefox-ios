// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import SiteImageView

final class SiteImageViewTests: XCTestCase {
    private var imageFetcher: MockSiteImageFetcher!

    override func setUp() {
        super.setUp()
        self.imageFetcher = MockSiteImageFetcher()
    }

    override func tearDown() {
        super.tearDown()
        self.imageFetcher = nil
    }

    func testFaviconSetup() {
        let expectation = expectation(description: "Completed image setup")
        let url = "https://www.firefox.com"
        let viewModel = DefaultFaviconImageViewModel(urlStringRequest: url,
                                                     faviconCornerRadius: 8)
        let subject = FaviconImageView(frame: .zero, imageFetcher: imageFetcher) {
            expectation.fulfill()
        }
        subject.setFavicon(viewModel)

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(imageFetcher.capturedStringRequest, url)
        XCTAssertEqual(imageFetcher.capturedType, .favicon)
    }

    func testHeroImageSetup() {
        let expectation = expectation(description: "Completed image setup")
        let url = "https://www.firefox.com"
        let viewModel = DefaultHeroImageViewModel(urlStringRequest: url,
                                                  generalCornerRadius: 8,
                                                  faviconCornerRadius: 4,
                                                  faviconBorderWidth: 0.5,
                                                  heroImageSize: CGSize(),
                                                  fallbackFaviconSize: CGSize())
        let subject = HeroImageView(frame: .zero, imageFetcher: imageFetcher) {
            expectation.fulfill()
        }
        subject.setHeroImage(viewModel)

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(imageFetcher.capturedStringRequest, url)
        XCTAssertEqual(imageFetcher.capturedType, .heroImage)
    }
}

class MockSiteImageFetcher: SiteImageFetcher {
    var image = UIImage()
    var capturedType: SiteImageType?
    var capturedStringRequest: String?
    func getImage(urlStringRequest: String,
                  type: SiteImageType,
                  id: UUID,
                  usesIndirectDomain: Bool) async -> SiteImageModel {
        capturedStringRequest = urlStringRequest
        capturedType = type
        return SiteImageModel(id: id,
                              expectedImageType: type,
                              urlStringRequest: urlStringRequest,
                              siteURL: URL(string: urlStringRequest)!,
                              cacheKey: "",
                              domain: ImageDomain(bundleDomains: []),
                              faviconURL: nil,
                              faviconImage: image,
                              heroImage: image)
    }
}
