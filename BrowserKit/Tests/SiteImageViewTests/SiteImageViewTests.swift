// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

final class SiteImageViewTests: XCTestCase {
    private var imageFetcher: MockSiteImageHandler!

    override func setUp() {
        super.setUp()
        self.imageFetcher = MockSiteImageHandler()
    }

    override func tearDown() {
        super.tearDown()
        self.imageFetcher = nil
    }

    func testFaviconSetup() {
        let expectation = expectation(description: "Completed image setup")
        let url = "https://www.firefox.com"
        let viewModel = FaviconImageViewModel(siteURLString: url,
                                              faviconCornerRadius: 8)
        let subject = FaviconImageView(frame: .zero, imageFetcher: imageFetcher) {
            expectation.fulfill()
        }
        subject.setFavicon(viewModel)

        waitForExpectations(timeout: 0.1)
        XCTAssertEqual(imageFetcher.capturedSite?.siteURLString, url)
        XCTAssertEqual(imageFetcher.capturedSite?.expectedImageType, .favicon)
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
        XCTAssertEqual(imageFetcher.capturedSite?.siteURLString, url)
        XCTAssertEqual(imageFetcher.capturedSite?.expectedImageType, .heroImage)
    }

    func testCanMakeRequest_firstTime_true() {
        let url = "https://www.firefox.com"
        let subject = FaviconImageView(frame: .zero, imageFetcher: imageFetcher) {}
        let canMakeRequestFirstTime = subject.canMakeRequest(with: url)

        XCTAssertTrue(canMakeRequestFirstTime)
    }

    func testCanMakeRequest_secondTime_false() {
        let url = "https://www.firefox.com"
        let subject = FaviconImageView(frame: .zero, imageFetcher: imageFetcher) {}
        _ = subject.canMakeRequest(with: url)
        let canMakeRequestSecondTime = subject.canMakeRequest(with: url)

        XCTAssertFalse(canMakeRequestSecondTime)
    }

    func testCanMakeRequest_secondTime_newURL_true() {
        let url = "https://www.firefox.com"
        let subject = FaviconImageView(frame: .zero, imageFetcher: imageFetcher) {}
        _ = subject.canMakeRequest(with: url)
        let newURL = "https://www.google.com"
        let canMakeRequestSecondTime = subject.canMakeRequest(with: newURL)

        XCTAssertTrue(canMakeRequestSecondTime)
    }
}

class MockSiteImageHandler: SiteImageHandler {
    var image = UIImage()
    var capturedSite: SiteImageModel?
    var siteURL: URL?
    var faviconURL: URL?
    var cacheFaviconURLCalled = 0
    var clearAllCachesCalled = 0

    func getImage(site: SiteImageModel) async -> SiteImageModel {
        capturedSite = site
        return site
    }

    func cacheFaviconURL(siteURL: URL?, faviconURL: URL?) {
        self.siteURL = siteURL
        self.faviconURL = faviconURL
        cacheFaviconURLCalled += 1
    }

    func clearAllCaches() {
        clearAllCachesCalled += 1
    }
}
