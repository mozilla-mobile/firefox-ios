// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

class FaviconURLHandlerTests: XCTestCase {
    var subject: DefaultFaviconURLHandler!
    var mockFetcher: FaviconURLFetcherMock!
    var mockCache: FaviconURLCacheMock!

    override func setUp() {
        super.setUp()
        mockFetcher = FaviconURLFetcherMock()
        mockCache = FaviconURLCacheMock()
        subject = DefaultFaviconURLHandler(urlFetcher: mockFetcher,
                                           urlCache: mockCache)
    }

    override func tearDown() {
        super.tearDown()
        mockFetcher = nil
        mockCache = nil
        subject = nil
    }

    func testGetFaviconURLInCache() async {
        await mockCache.setTestResult(url: URL(string: "www.firefox.com/image"))
        let model = createSiteImageModel(siteURL: "www.firefox.com")
        do {
            let site = try await subject.getFaviconURL(site: model)
            let getURLCount = await mockCache.getURLFromCacheCalledCount
            let cacheURLCount = await mockCache.cacheURLCalledCount
            XCTAssertEqual(getURLCount, 1, "get url should have been called on the cache")
            XCTAssertEqual(cacheURLCount, 0, "cache url should not have been called")
            XCTAssertEqual(mockFetcher.fetchFaviconURLCalledCount, 0, "fetch favicon url should not have been called")
            XCTAssertEqual(site.faviconURL?.absoluteString, "www.firefox.com/image")
            XCTAssertEqual(site.siteURL?.absoluteString, "www.firefox.com")
        } catch {
            XCTFail("failed to get favicon url from cache")
        }
    }

    func testGetFaviconURLNotInCache() async {
        await mockCache.setTestResult(error: .noURLInCache)
        mockFetcher.url = URL(string: "www.firefox.com/image")
        let model = createSiteImageModel(siteURL: "www.firefox.com")

        do {
            let site = try await subject.getFaviconURL(site: model)
            let getURLCount = await mockCache.getURLFromCacheCalledCount
            let cacheURLCount = await mockCache.cacheURLCalledCount
            XCTAssertEqual(getURLCount, 1, "get url should have been called on the cache")
            XCTAssertEqual(cacheURLCount, 1, "cache url should have been called")
            XCTAssertEqual(mockFetcher.fetchFaviconURLCalledCount, 1, "fetch favicon url should have been called")
            XCTAssertEqual(site.faviconURL?.absoluteString, "www.firefox.com/image")
            XCTAssertEqual(site.siteURL?.absoluteString, "www.firefox.com")
        } catch {
            XCTFail("failed to get fetch favicon")
        }
    }

    func testGetFaviconURLErrorNoFaviconFound() async {
        await mockCache.setTestResult(error: .noURLInCache)
        mockFetcher.error = .noFaviconFound
        let model = createSiteImageModel(siteURL: "www.firefox.com")

        do {
            _ = try await subject.getFaviconURL(site: model)
            XCTFail("Request should have thrown an error")
        } catch {
            let error = error as? SiteImageError
            XCTAssertEqual(error?.description, SiteImageError.noFaviconURLFound.description)
        }
    }

    func testCacheFaviconURL() async {
        subject.cacheFaviconURL(cacheKey: "key", faviconURL: URL(string: "myUrl")!)

        try? await Task.sleep(nanoseconds: 100_000_000)
        let count = await mockCache.cacheURLCalledCount
        let key = await mockCache.cacheKey
        let url = await mockCache.faviconURL?.absoluteString

        XCTAssertEqual(count, 1)
        XCTAssertEqual(key, "key")
        XCTAssertEqual(url, "myUrl")
    }

    func testClearCache() async {
        subject.clearCache()

        try? await Task.sleep(nanoseconds: 100_000_000)
        let count = await mockCache.clearCacheCalledCount

        XCTAssertEqual(count, 1)
    }

    private func createSiteImageModel(siteURL: String) -> SiteImageModel {
        return SiteImageModel(id: UUID(),
                              expectedImageType: .favicon,
                              siteURLString: siteURL,
                              siteURL: URL(string: siteURL)!,
                              cacheKey: "domain",
                              faviconURL: nil,
                              faviconImage: nil,
                              heroImage: nil)
    }
}
