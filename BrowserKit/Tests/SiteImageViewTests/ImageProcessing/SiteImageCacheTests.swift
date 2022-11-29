// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Kingfisher
import XCTest
@testable import SiteImageView

final class SiteImageCacheTests: XCTestCase {

    private var imageCache: MockDefaultSiteImageCache!

    override func setUp() {
        super.setUp()
        self.imageCache = MockDefaultSiteImageCache()
    }

    override func tearDown() {
        super.tearDown()
        self.imageCache = nil
    }

    // MARK: - Get from cache

    func testGetFromCache_whenError_returnsError() async {
        imageCache.retrievalError = KingfisherError.requestError(reason: .emptyRequest)
        let subject = DefaultSiteImageCache(imageCache: imageCache)
        let result = await subject.getImageFromCache(domain: "www.example.com", type: .favicon)

        XCTAssertEqual(imageCache.capturedRetrievalKey, "www.example.com-favicon")
        switch result {
        case .success:
            XCTFail("Should have failed with error")
        case .failure(let error):
            XCTAssertEqual("Unable to retrieve image from cache with reason: The request is empty or `nil`.",
                           error.description)
        }
    }

    func testGetFromCache_whenEmptyImage_returnsError() async {
        let subject = DefaultSiteImageCache(imageCache: imageCache)
        let result = await subject.getImageFromCache(domain: "www.example.com", type: .heroImage)

        XCTAssertEqual(imageCache.capturedRetrievalKey, "www.example.com-heroImage")
        switch result {
        case .success:
            XCTFail("Should have failed with error")
        case .failure(let error):
            XCTAssertEqual("Unable to retrieve image from cache with reason: Image was nil",
                           error.description)
        }
    }

    func testGetFromCache_whenImage_returnsSuccess() async {
        let expectedImage = UIImage()
        imageCache.image = expectedImage
        let subject = DefaultSiteImageCache(imageCache: imageCache)
        let result = await subject.getImageFromCache(domain: "www.example2.com", type: .favicon)

        XCTAssertEqual(imageCache.capturedRetrievalKey, "www.example2.com-favicon")
        switch result {
        case .success(let image):
            XCTAssertEqual(expectedImage, image)
        case .failure:
            XCTFail("Should have succeeded with image")
        }
    }

    // MARK: - Cache image

    func testCacheImage_whenError_returnsError() async {
        let expectedImage = UIImage()
        imageCache.storageError = KingfisherError.requestError(reason: .emptyRequest)
        let subject = DefaultSiteImageCache(imageCache: imageCache)
        let result = await subject.cacheImage(image: expectedImage, domain: "www.firefox.com", type: .favicon)

        XCTAssertEqual(imageCache.capturedStorageKey, "www.firefox.com-favicon")
        XCTAssertEqual(imageCache.capturedImage, expectedImage)
        switch result {
        case .success:
            XCTFail("Should have failed with error")
        case .failure(let error):
            XCTAssertEqual("Unable to retrieve image from cache with reason: The request is empty or `nil`.",
                           error.description)
        }
    }

    func testCacheImage_whenSuccess_returnsSuccess() async {
        let expectedImage = UIImage()
        let subject = DefaultSiteImageCache(imageCache: imageCache)
        let result = await subject.cacheImage(image: expectedImage, domain: "www.firefox.com", type: .favicon)

        XCTAssertEqual(imageCache.capturedStorageKey, "www.firefox.com-favicon")
        XCTAssertEqual(imageCache.capturedImage, expectedImage)
        switch result {
        case .success:
            break
        case .failure:
            XCTFail("Should have succeeded")
        }
    }
}

private class MockDefaultSiteImageCache: DefaultImageCache {

    var image: UIImage?
    var retrievalError: KingfisherError?
    var capturedRetrievalKey: String?
    func retrieveImage(forKey key: String) async -> Result<UIImage?, Kingfisher.KingfisherError> {
        capturedRetrievalKey = key
        if let error = retrievalError {
            return .failure(error)
        } else {
            return .success(image)
        }
    }

    var storageError: KingfisherError?
    var capturedImage: UIImage?
    var capturedStorageKey: String?
    func store(image: UIImage, forKey key: String) async -> Result<(), Kingfisher.KingfisherError> {
        capturedImage = image
        capturedStorageKey = key
        if let error = storageError {
            return .failure(error)
        } else {
            return .success(())
        }
    }
}
