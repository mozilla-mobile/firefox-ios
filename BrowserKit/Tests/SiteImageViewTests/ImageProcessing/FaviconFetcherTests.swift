// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
import Kingfisher
@testable import SiteImageView

final class FaviconFetcherTests: XCTestCase {
    private var mockImageDownloader: MockSiteImageDownloader!

    override func setUp() {
        super.setUp()
        self.mockImageDownloader = MockSiteImageDownloader()
    }

    override func tearDown() {
        super.tearDown()
        self.mockImageDownloader = nil
    }

    func testReturnsFailure_onAnyError() async {
        mockImageDownloader.error = KingfisherError.requestError(reason: .emptyRequest)
        let subject = DefaultFaviconFetcher(imageDownloader: mockImageDownloader)

        do {
            _ = try await subject.fetchFavicon(from: URL(string: "www.mozilla.com")!)
            XCTFail("Should have failed with error")
        } catch let error as SiteImageError {
            XCTAssertEqual("Unable to download image with reason: The request is empty or `nil`.",
                           error.description)
        } catch {
            XCTFail("Should have failed with SiteImageError type")
        }
    }

    func testReturnsSuccess_onImage() async {
        let resultImage = UIImage()
        mockImageDownloader.image = resultImage
        let subject = DefaultFaviconFetcher(imageDownloader: mockImageDownloader)

        do {
            let result = try await subject.fetchFavicon(from: URL(string: "www.mozilla.com")!)
            XCTAssertEqual(resultImage, result)
        } catch {
            XCTFail("Should have succeeded with image")
        }
    }
}

// MARK: - MockSiteImageDownloader
private class MockSiteImageDownloader: SiteImageDownloader {
    var image: UIImage?
    var error: KingfisherError?

    func downloadImage(with url: URL, completionHandler: ((Result<SiteImageLoadingResult, KingfisherError>) -> Void)?) -> DownloadTask? {
        if let error = error {
            completionHandler?(.failure(error))
        } else if let image = image {
            completionHandler?(.success(MockSiteImageLoadingResult(image: image)))
        }

        return nil // not using download task
    }
}

// MARK: - MockSiteImageLoadingResult
private struct MockSiteImageLoadingResult: SiteImageLoadingResult {
    var image: UIImage
}
