// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
        let cacheKey = "firefox.com"
        let result = try? await subject.getURLFromCache(cacheKey: cacheKey)
        XCTAssertNil(result)
    }

    func testGetURLFromCacheWithValuePresent() async {
        let cacheKey = "firefox.com"
        await subject.cacheURL(cacheKey: cacheKey, faviconURL: URL(string: "www.firefox.com")!)
        let result = try? await subject.getURLFromCache(cacheKey: cacheKey)
        XCTAssertEqual(result?.absoluteString, "www.firefox.com")
    }

    func testRetrieveCacheNotExpired() async throws {
        let fileManager = DefaultURLCacheFileManager()
        let cacheKey = "google"
        let testFavicons = [FaviconURL(cacheKey: cacheKey, faviconURL: "www.google.com", createdAt: Date())]
        await fileManager.saveURLCache(data: getTestData(items: testFavicons))

        subject = DefaultFaviconURLCache(fileManager: fileManager)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let result = try? await subject.getURLFromCache(cacheKey: cacheKey)
        XCTAssertEqual(result?.absoluteString, "www.google.com")
    }

    func testRetrieveCacheWithExpired() async throws {
        let fileManager = DefaultURLCacheFileManager()
        guard let expiredDate = Calendar.current.date(byAdding: .day, value: -31, to: Date()) else {
            XCTFail("Something went wrong generating a date in the past")
            return
        }
        let testFavicons = [FaviconURL(cacheKey: "amazon", faviconURL: "www.amazon.com", createdAt: Date()),
                            FaviconURL(cacheKey: "firefox", faviconURL: "www.firefox.com", createdAt: expiredDate)]
        await fileManager.saveURLCache(data: getTestData(items: testFavicons))

        subject = DefaultFaviconURLCache(fileManager: fileManager)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let result1 = try? await subject.getURLFromCache(cacheKey: "amazon")
        XCTAssertEqual(result1?.absoluteString, "www.amazon.com")

        let result2 = try? await subject.getURLFromCache(cacheKey: "firefox")
        XCTAssertNil(result2)
    }

    private func getTestData(items: [FaviconURL], file: String = #file, line: UInt = #line) -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        do {
            try archiver.encodeEncodable(items, forKey: "favicon-url-cache")
        } catch {
            XCTFail("Something went wrong generating mock favicon data, file: \(file), line: \(line)")
        }
        return archiver.encodedData
    }
}

actor MockURLCacheFileManager: URLCacheFileManager {
    func getURLCache() async -> Data? {
        return Data()
    }

    func saveURLCache(data: Data) {}
}
