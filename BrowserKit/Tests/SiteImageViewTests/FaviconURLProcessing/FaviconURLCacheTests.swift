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
        let domain = ImageDomain(baseDomain: "firefox.com", bundleDomains: [])
        let result = try? await subject.getURLFromCache(domain: domain)
        XCTAssertNil(result)
    }

    func testGetURLFromCacheWithValuePresent() async {
        let domain = ImageDomain(baseDomain: "firefox.com", bundleDomains: [])
        await subject.cacheURL(domain: domain, faviconURL: URL(string: "www.firefox.com")!)
        let result = try? await subject.getURLFromCache(domain: domain)
        XCTAssertEqual(result?.absoluteString, "www.firefox.com")
    }

    func testRetrieveCacheNotExpired() async throws {
        let fileManager = DefaultURLCacheFileManager()
        let googleDomain = ImageDomain(baseDomain: "google", bundleDomains: [])
        let testFavicons = [FaviconURL(domain: googleDomain, faviconURL: "www.google.com", createdAt: Date())]
        await fileManager.saveURLCache(data: getTestData(items: testFavicons))

        subject = DefaultFaviconURLCache(fileManager: fileManager)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let result = try? await subject.getURLFromCache(domain: googleDomain)
        XCTAssertEqual(result?.absoluteString, "www.google.com")
    }

    func testRetrieveCacheWithExpired() async throws {
        let fileManager = DefaultURLCacheFileManager()
        guard let expiredDate = Calendar.current.date(byAdding: .day, value: -31, to: Date()) else {
            XCTFail("Something went wrong generating a date in the past")
            return
        }
        let amazonDomain = ImageDomain(baseDomain: "amazon", bundleDomains: [])
        let firefoxDomain = ImageDomain(baseDomain: "firefox", bundleDomains: [])
        let testFavicons = [FaviconURL(domain: amazonDomain, faviconURL: "www.amazon.com", createdAt: Date()),
                            FaviconURL(domain: firefoxDomain, faviconURL: "www.firefox.com", createdAt: expiredDate)]
        await fileManager.saveURLCache(data: getTestData(items: testFavicons))

        subject = DefaultFaviconURLCache(fileManager: fileManager)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let result1 = try? await subject.getURLFromCache(domain: amazonDomain)
        XCTAssertEqual(result1?.absoluteString, "www.amazon.com")

        let result2 = try? await subject.getURLFromCache(domain: firefoxDomain)
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
