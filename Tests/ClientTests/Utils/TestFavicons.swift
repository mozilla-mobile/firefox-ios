// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import XCTest
import Storage
@testable import Client
import Shared

class TestFavicons: ProfileTest {

    fileprivate func addSite(_ favicons: Favicons, url: String, isSuccessful: Bool = true) {
        let expectation = self.expectation(description: "Wait for history")
        let site = Site(url: url, title: "")
        let icon = Favicon(url: url + "/icon.png")
        favicons.addFavicon(icon, forSite: site).upon {
            XCTAssertEqual($0.isSuccess, isSuccessful, "Icon added \(url)")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 100, handler: nil)
    }

    func testFaviconFetcherParse() {
        let expectation = self.expectation(description: "Wait for Favicons to be fetched")

        let profile = MockProfile()
        // I want a site that also has an iOS app so I can get "apple-touch-icon-precomposed" icons as well
        let url = URL(string: "https://instagram.com")
        FaviconFetcher.getForURL(url!, profile: profile).uponQueue(.main) { result in
            guard let favicons = result.successValue,
                  !favicons.isEmpty,
                  let url = favicons.first?.url.asURL
            else {
                XCTFail("Favicons were not found.")
                return expectation.fulfill()
            }

            XCTAssertEqual(favicons.count, 1, "Instagram should have a Favicon.")
            ImageLoadingHandler.shared.getImageFromCacheOrDownload(with: url, limit: ImageLoadingConstants.NoLimitImageSize) { img, err in
                guard let image = img else {
                    XCTFail("Not a valid URL provided for a favicon.")
                    return expectation.fulfill()
                }
                XCTAssertNotEqual(image.size, .zero)
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 3000, handler: nil)
    }

    func testDefaultFavicons() {
        // The amazon case tests a special case for multi-reguin domain lookups
        ["http://www.youtube.com", "https://www.taobao.com/", "https://www.amazon.ca"].forEach {
            let url = URL(string: $0)!
            let icon = FaviconFetcher.getBundledIcon(forUrl: url)
            XCTAssertNotNil(icon)
        }
    }
}
