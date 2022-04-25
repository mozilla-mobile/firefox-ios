// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

import XCTest
import Storage
import Shared
import LinkPresentation

class SiteImageHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SiteImageHelper.clearCacheData()
    }

    override func tearDown() {
        super.tearDown()
        SiteImageHelper.clearCacheData()
    }

    // MARK: Hero image

    func test_heroImageLoading_completesOnUrlNotAWebsite() {
        let sut = createSiteImageHelper()

        fetchImage(for: "not a website", imageType: .heroImage, sut: sut) { image in
            XCTAssertNil(image)
        }
    }

    func test_heroImageLoads_completesOnEmptyMetadata() {
        let sut = createSiteImageHelper()
        sut.metadataProvider = MetadataProviderFake()

        fetchImage(for: "www.a-website.com", imageType: .heroImage, sut: sut) { image in
            XCTAssertNil(image)
        }
    }

    func test_heroImageLoads_completesOnError() {
        let sut = createSiteImageHelper()
        let fake = MetadataProviderFake()
        fake.errorResult = TestError.invalidResult
        sut.metadataProvider = fake

        fetchImage(for: "www.a-website.com", imageType: .heroImage, sut: sut) { image in
            XCTAssertNil(image)
        }
    }

    func test_heroImageLoads_completesProviderImageError() {
        let sut = createSiteImageHelper()
        let fake = MetadataProviderFake()
        let providerFake = ItemProviderFake()
        providerFake.errorResult = TestError.invalidResult
        providerFake.imageResult = nil
        fake.metadataResult.imageProvider = providerFake
        sut.metadataProvider = fake

        fetchImage(for: "www.a-website.com", imageType: .heroImage, sut: sut) { image in
            XCTAssertNil(image)
        }
    }

    func test_heroImageLoads_completesOnImage() {
        let sut = createSiteImageHelper()
        let fake = MetadataProviderFake()
        fake.metadataResult.imageProvider = ItemProviderFake()
        sut.metadataProvider = fake

        fetchImage(for: "www.a-website.com", imageType: .heroImage, sut: sut) { image in
            XCTAssertNotNil(image)
        }
    }

    func test_heroImageLoads_completesFromCache() {
        let sut = createSiteImageHelper()
        let fake = MetadataProviderFake()
        fake.metadataResult.imageProvider = ItemProviderFake()
        sut.metadataProvider = fake

        let site = Site(url: "www.a-website.com", title: "Website")
        let expectation = self.expectation(description: "Hero image is fetched from cache")
        sut.fetchImageFor(site: site,
                          imageType: .heroImage,
                          shouldFallback: false,
                          completion: { image in
            XCTAssertNotNil(image)

            // Image is now cached, fake an error to see if it's fetched from cache
            let sut2 = self.createSiteImageHelper()
            let fake2 = MetadataProviderFake()
            fake2.errorResult = TestError.invalidResult
            sut2.metadataProvider = fake2
            sut2.fetchImageFor(site: site,
                               imageType: .heroImage,
                               shouldFallback: false,
                               completion: { image in
                XCTAssertNotNil(image)
                expectation.fulfill()
            })
        })
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: Favicon image

    func test_faviconLoads_completesOnError() {
        let sut = createSiteImageHelper(shouldFaviconSucceeds: false)
        fetchImage(for: "www.a-website.com", imageType: .favicon, sut: sut) { image in
            XCTAssertNil(image)
        }
    }

    func test_faviconLoads_completesOnImage() {
        let sut = createSiteImageHelper()
        fetchImage(for: "www.a-website.com", imageType: .favicon, sut: sut) { image in
            XCTAssertNotNil(image)
        }
    }

    func test_faviconLoads_completesFromCache() {
        let sut = createSiteImageHelper()

        let site = Site(url: "www.a-website.com", title: "Website")
        let expectation = self.expectation(description: "Favicon image is fetched from cache")
        sut.fetchImageFor(site: site,
                          imageType: .favicon,
                          shouldFallback: false,
                          completion: { image in
            XCTAssertNotNil(image)

            // Image is now cached, fake an error to see if it's fetched from cache
            let sut2 = self.createSiteImageHelper(shouldFaviconSucceeds: false)
            sut2.fetchImageFor(site: site,
                               imageType: .favicon,
                               shouldFallback: false,
                               completion: { image in
                XCTAssertNotNil(image)
                expectation.fulfill()
            })
        })
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

// MARK: Helper tests
extension SiteImageHelperTests {

    enum TestError: Error, CustomStringConvertible {
        var description: String { "A test error" }

        case invalidResult
    }

    func fetchImage(for siteName: String,
                    imageType: SiteImageType,
                    sut: SiteImageHelper,
                    completion: @escaping (UIImage?) -> Void) {

        let site = Site(url: siteName, title: "Website")
        let expectation = self.expectation(description: "Completion is called")
        sut.fetchImageFor(site: site,
                          imageType: imageType,
                          shouldFallback: false,
                          completion: { image in
            completion(image)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func createSiteImageHelper(shouldFaviconSucceeds: Bool = true, file: StaticString = #file, line: UInt = #line) -> SiteImageHelper {
        let faviconFetcher = FaviconFetcherMock()
        faviconFetcher.shouldSucceed = shouldFaviconSucceeds
        let sut = SiteImageHelper(faviconFetcher: faviconFetcher)

        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}

class FaviconFetcherMock: Favicons {
    func addFavicon(_ icon: Favicon) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    func addFavicon(_ icon: Favicon, forSite site: Site) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    var shouldSucceed = true
    func getFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>> {
        return shouldSucceed ? deferMaybe(UIImage()) : Deferred(value: Maybe(failure: SiteImageHelperTests.TestError.invalidResult))
    }
}

class MetadataProviderFake: LPMetadataProvider {

    var metadataResult = LPLinkMetadata()
    var errorResult: Error? = nil
    override func startFetchingMetadata(for URL: URL, completionHandler: @escaping (LPLinkMetadata?, Error?) -> Void) {
        completionHandler(metadataResult, errorResult)
    }
}

class ItemProviderFake: NSItemProvider {

    var imageResult: UIImage? = UIImage()
    var errorResult: Error? = nil
    override func loadObject(ofClass aClass: NSItemProviderReading.Type, completionHandler: @escaping (NSItemProviderReading?, Error?) -> Void) -> Progress {
        completionHandler(imageResult, errorResult)
        return Progress()
    }
}
