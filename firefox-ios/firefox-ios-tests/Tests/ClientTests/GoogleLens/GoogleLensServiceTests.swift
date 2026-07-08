// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UIKit

@testable import Client

final class GoogleLensServiceTests: XCTestCase {
    func test_makeUploadRequest_passesProcessedImageAndViewportToBuilder() {
        let processed = ProcessedLensImage(jpegData: Data([0x01, 0x02]),
                                           dimensions: CGSize(width: 800, height: 600))
        let processor = MockImageProcessor(result: processed)
        let builder = MockRequestBuilder()
        let subject = GoogleLensService(imageProcessor: processor, requestBuilder: builder)

        _ = subject.makeUploadRequest(for: UIImage(), viewportSize: CGSize(width: 390, height: 844))

        XCTAssertEqual(builder.receivedInput,
                       GoogleLensUploadInput(jpegData: processed.jpegData,
                                             imageDimensions: processed.dimensions,
                                             viewportSize: CGSize(width: 390, height: 844)))
    }

    func test_makeUploadRequest_returnsBuilderRequest() {
        let processor = MockImageProcessor(result: ProcessedLensImage(jpegData: Data([0x01]),
                                                                      dimensions: .zero))
        let builder = MockRequestBuilder()
        let subject = GoogleLensService(imageProcessor: processor, requestBuilder: builder)

        let request = subject.makeUploadRequest(for: UIImage(), viewportSize: .zero)

        XCTAssertEqual(request, builder.stubbedRequest)
    }

    func test_makeUploadRequest_returnsNilAndSkipsBuilder_whenProcessingFails() {
        let processor = MockImageProcessor(result: nil)
        let builder = MockRequestBuilder()
        let subject = GoogleLensService(imageProcessor: processor, requestBuilder: builder)

        let request = subject.makeUploadRequest(for: UIImage(), viewportSize: .zero)

        XCTAssertNil(request)
        XCTAssertNil(builder.receivedInput, "Builder should not be called when processing fails")
    }

    // MARK: - Mocks
    private final class MockImageProcessor: GoogleLensImageProcessing {
        private let result: ProcessedLensImage?
        init(result: ProcessedLensImage?) { self.result = result }
        func process(_ image: UIImage) -> ProcessedLensImage? { return result }
    }

    private final class MockRequestBuilder: GoogleLensRequestBuilding {
        let stubbedRequest = URLRequest(url: URL(string: "https://lens.google.com/upload")!)
        private(set) var receivedInput: GoogleLensUploadInput?

        func makeUploadRequest(for input: GoogleLensUploadInput) -> URLRequest {
            receivedInput = input
            return stubbedRequest
        }
    }
}
