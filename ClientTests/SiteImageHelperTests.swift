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

    // TODO: issue when multiple tests are run - completes with what exactly?
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

    // TODO: Hero image Caching

    // MARK: Favicon image

    func test_faviconLoads_completesOnUrlNotAWebsite() {
        let sut = createSiteImageHelper()
        fetchImage(for: "not a website", imageType: .favicon, sut: sut) { image in
            XCTAssertNil(image)
        }
    }

    // TODO: No result success value
    // TODO: Image light
    // TODO: Image dark
    // TODO: Favicon Caching
}

// MARK: Helper tests
extension SiteImageHelperTests {

    enum TestError: Error {
        case invalidResult
    }

    func fetchImage(for siteName: String,
                    imageType: SiteImageType,
                    sut: SiteImageHelper,
                    completion: @escaping (UIImage?) -> Void) {

        let site = Site(url: siteName, title: "Website")
        let expectation = self.expectation(description: "Completion is called")
        sut.fetchImageFor(site: site,
                          imageType: .heroImage,
                          shouldFallback: false,
                          completion: { image in
            completion(image)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func createSiteImageHelper() -> SiteImageHelper {
        let profile = MockProfile()
        let sut = SiteImageHelper(profile: profile)

        trackForMemoryLeaks(sut)
        return sut
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
