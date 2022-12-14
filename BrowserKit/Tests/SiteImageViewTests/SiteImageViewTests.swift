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
        let url = URL(string: "https://www.firefox.com")!
        let viewModel = FaviconImageViewModel(siteURL: url,
                                              faviconCornerRadius: 8)
        let subject = FaviconImageView(frame: .zero, imageFetcher: imageFetcher) {
            expectation.fulfill()
        }
        subject.setFavicon(viewModel)

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(imageFetcher.capturedSiteURL, url)
        XCTAssertEqual(imageFetcher.capturedType, .favicon)
    }

    func testHeroImageSetup() {
        let expectation = expectation(description: "Completed image setup")
        let url = URL(string: "https://www.firefox.com")!
        let viewModel = HeroImageViewModel(siteURL: url,
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
        XCTAssertEqual(imageFetcher.capturedSiteURL, url)
        XCTAssertEqual(imageFetcher.capturedType, .heroImage)
    }
}

class MockSiteImageFetcher: SiteImageFetcher {
    var image = UIImage()
    var capturedType: SiteImageType?
    var capturedSiteURL: URL?
    func getImage(siteURL: URL,
                  type: SiteImageType,
                  id: UUID) async -> SiteImageModel {
        capturedSiteURL = siteURL
        capturedType = type
        return SiteImageModel(id: id,
                              expectedImageType: type,
                              siteURL: siteURL,
                              domain: "",
                              faviconURL: nil,
                              faviconImage: image,
                              heroImage: image)
    }
}
