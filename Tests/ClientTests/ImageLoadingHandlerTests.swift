// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

import XCTest
import SDWebImage

class ImageLoadingHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: SDWebImageCacheKey.hasClearedCacheKey)
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_SDWebImageDiskCacheClear() {
        let expectation = expectation(description: "Wait for SDWebImage disk cache to clear")

        SDImageCache.shared.clearDiskCache { didClear in
            XCTAssertTrue(didClear)
            let defaults = UserDefaults.standard
            let hasClearedDiskCache = defaults.bool(forKey: SDWebImageCacheKey.hasClearedCacheKey)
            XCTAssertTrue(hasClearedDiskCache)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)
    }
}
