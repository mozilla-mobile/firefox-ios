// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
    func test_heroImageLoading_doesNotCompleteOnUrlNotAWebsite() {
        let imageHelper = createSiteImageHelper()

        fetchImage(for: "not a website",
                   imageType: .heroImage,
                   imageHelper: imageHelper,
                   isExpectationInverted: true) { image in
            XCTFail("Should not complete")
        }
    }

    func test_heroImageLoads_doesNotCompleteOnEmptyMetadata() {
        let imageHelper = createSiteImageHelper()

        fetchImage(for: "www.a-website.com",
                   imageType: .heroImage,
                   imageHelper: imageHelper,
                   isExpectationInverted: true,
                   metadataProvider: MetadataProviderFake()) { image in
            XCTFail("Should not complete")
        }
    }

    func test_heroImageLoads_doesNotCompleteOnError() {
        let imageHelper = createSiteImageHelper()
        let fake = MetadataProviderFake()
        fake.errorResult = TestError.invalidResult

        fetchImage(for: "www.a-website.com",
                   imageType: .heroImage,
                   imageHelper: imageHelper,
                   isExpectationInverted: true,
                   metadataProvider: fake) { image in
            XCTFail("Should not complete")
        }
    }

    func test_heroImageLoads_doesNotCompleteProviderImageError() {
        let imageHelper = createSiteImageHelper()
        let fake = MetadataProviderFake()
        let providerFake = ItemProviderFake()
        providerFake.errorResult = TestError.invalidResult
        providerFake.imageResult = nil
        fake.metadataResult.imageProvider = providerFake

        fetchImage(for: "www.a-website.com",
                   imageType: .heroImage,
                   imageHelper: imageHelper,
                   isExpectationInverted: true,
                   metadataProvider: fake) { image in
            XCTFail("Should not complete")
        }
    }

    func test_heroImageLoads_completesOnImage() {
        let imageHelper = createSiteImageHelper()
        let fake = MetadataProviderFake()
        fake.metadataResult.imageProvider = ItemProviderFake()

        fetchImage(for: "www.a-website.com",
                   imageType: .heroImage,
                   imageHelper: imageHelper,
                   metadataProvider: fake) { image in
            XCTAssertNotNil(image)
        }
    }

    func test_heroImageLoads_completesFromCache() {
        let imageHelper = createSiteImageHelper()
        let fake = MetadataProviderFake()
        fake.metadataResult.imageProvider = ItemProviderFake()

        let site = Site(url: "www.a-website.com", title: "Website")
        let expectation = self.expectation(description: "Hero image is fetched from cache")
        imageHelper.fetchImageFor(site: site,
                                  imageType: .heroImage,
                                  shouldFallback: false,
                                  metadataProvider: fake,
                                  completion: { image in
            XCTAssertNotNil(image)

            // Image is now cached, fake an error to see if it's fetched from cache
            let imageHelper2 = self.createSiteImageHelper()
            let fake2 = MetadataProviderFake()
            fake2.errorResult = TestError.invalidResult
            imageHelper2.fetchImageFor(site: site,
                                       imageType: .heroImage,
                                       shouldFallback: false,
                                       metadataProvider: fake2,
                                       completion: { image in
                XCTAssertNotNil(image)
                expectation.fulfill()
            })
        })
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    // MARK: Favicon image
    func test_faviconLoads_doesNotCompleteOnError() {
        let imageHelper = createSiteImageHelper(shouldFaviconSucceeds: false)
        fetchImage(for: "www.a-website.com",
                   imageType: .favicon,
                   imageHelper: imageHelper,
                   isExpectationInverted: true) { image in
            XCTAssertNil(image)
        }
    }

    func test_faviconLoads_completesOnImage() {
        let imageHelper = createSiteImageHelper()
        fetchImage(for: "www.a-website.com", imageType: .favicon, imageHelper: imageHelper) { image in
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
        waitForExpectations(timeout: 5.0, handler: nil)
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
                    imageHelper: SiteImageHelper,
                    isExpectationInverted: Bool = false,
                    metadataProvider: LPMetadataProvider = LPMetadataProvider(),
                    completion: @escaping (UIImage?) -> Void) {

        let site = Site(url: siteName, title: "Website")
        let expectation = self.expectation(description: "Completion is called when fetched image")
        expectation.isInverted = isExpectationInverted
        imageHelper.fetchImageFor(site: site,
                                  imageType: imageType,
                                  shouldFallback: false,
                                  metadataProvider: metadataProvider,
                                  completion: { image in
            completion(image)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func createSiteImageHelper(shouldFaviconSucceeds: Bool = true, file: StaticString = #file, line: UInt = #line) -> SiteImageHelper {
        let faviconFetcher = FaviconFetcherMock()
        faviconFetcher.shouldSucceed = shouldFaviconSucceeds
        let imageHelper = SiteImageHelper(faviconFetcher: faviconFetcher)

        trackForMemoryLeaks(imageHelper, file: file, line: line)
        return imageHelper
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
    var errorResult: Error?
    override func startFetchingMetadata(for URL: URL, completionHandler: @escaping (LPLinkMetadata?, Error?) -> Void) {
        completionHandler(metadataResult, errorResult)
    }
}

class ItemProviderFake: NSItemProvider {

    var imageResult: UIImage? = UIImage()
    var errorResult: Error?
    override func loadObject(ofClass aClass: NSItemProviderReading.Type, completionHandler: @escaping (NSItemProviderReading?, Error?) -> Void) -> Progress {
        completionHandler(imageResult, errorResult)
        return Progress()
    }
}
