// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import SiteImageView

class FaviconURLCacheTests: XCTestCase {
    var subject: DefaultFaviconURLCache!
    var mockFileManager: MockURLCacheFileManager!

    override func setUp() {
        super.setUp()
        mockFileManager = MockURLCacheFileManager()
        subject = DefaultFaviconURLCache(fileManager: mockFileManager)
    }

    override func tearDown() {
        super.tearDown()
        mockFileManager = nil
        subject = nil
    }

    func testGetURLFromCacheWithEmptyCache() async {
        let result = try? await subject.getURLFromCache(domain: "firefox")
        XCTAssertNil(result)
    }

    func testGetURLFromCacheWithValuePresent() async {
        await subject.cacheURL(domain: "firefox", faviconURL: URL(string: "www.firefox.com")!)
        let result = try? await subject.getURLFromCache(domain: "firefox")
        XCTAssertEqual(result?.absoluteString, "www.firefox.com")
    }
}

actor MockURLCacheFileManager: URLCacheFileManager {
    func getURLCache() async -> Data? {
        return Data()
    }

    func saveURLCache(data: Data) {}
}
