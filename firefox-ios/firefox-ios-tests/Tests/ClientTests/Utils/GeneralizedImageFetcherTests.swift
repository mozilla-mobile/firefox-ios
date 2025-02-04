// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class GeneralizedImageFetcherTests: XCTestCase {
    override func setUp() {
        super.setUp()

        clearState()
    }

    override func tearDown() {
        clearState()
        super.tearDown()
    }

    func testErrorResponse() {
        loadStubResponse(response: nil, statusCode: 200, error: anError)

        testGeneralizedImageFetcher { imageData in
            XCTAssertNil(imageData)
        }
    }

    func testNilData() {
        loadStubResponse(response: nil, statusCode: 200, error: nil)

        testGeneralizedImageFetcher { imageData in
            XCTAssertNil(imageData)
        }
    }

    func testBadStatusCode() {
        loadStubResponse(response: nil, statusCode: 500, error: nil)

        testGeneralizedImageFetcher { imageData in
            XCTAssertNil(imageData)
        }
    }

    func testFetchFailForUnsupportedImageType() {
        loadStubResponse(response: sampleResponseUnsupportedImageType, statusCode: 200, error: nil)

        testGeneralizedImageFetcher { imageData in
            XCTAssertNil(imageData)
        }
    }

    func testFetchSucceeds() {
        _ = XCTSkip("Production is currently giving back an unsupported image type, SVG.")
    }
}

// MARK: - Helpers
extension GeneralizedImageFetcherTests {
    var testUrl: URL {
        return URL(string: "https://profile.accounts.firefox.com/v1/avatar/a")!
    }
    var anError: NSError {
        return NSError(domain: "test error", code: 0)
    }
    var sampleResponseUnsupportedImageType: String {
        return """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <path d="M30,1h40l29,29v40l-29,29h-40l-29-29v-40z" stroke="#000" fill="none"/>
  <path d="M31,3h38l28,28v38l-28,28h-38l-28-28v-38z" fill="#a23"/>
  <text x="50" y="68" font-size="48" fill="#FFF" text-anchor="middle">410</text>
</svg>
"""
    }

    func clearState() {
        URLProtocolStub.removeStub()
    }

    func loadStubResponse(
        response: String?,
        statusCode: Int,
        error: Error?
    ) {
        let mockData = response?.data(using: .utf8)
        let response = HTTPURLResponse(
            url: testUrl,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )

        URLProtocolStub.stub(
            data: mockData,
            response: response,
            error: error
        )
    }

    func testGeneralizedImageFetcher(completion: @escaping (UIImage?) -> Void) {
        let imageFetcher = getGeneralizedImageFetcher()
        let expectation = expectation(description: "Wait on completion.")

        imageFetcher.getImageFor(url: testUrl) { imageData in
            completion(imageData)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func getGeneralizedImageFetcher(file: StaticString = #filePath, line: UInt = #line) -> GeneralizedImageFetcher {
        let configuration = URLSessionConfiguration.ephemeralMPTCP
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let cache = URLCache(memoryCapacity: 100000, diskCapacity: 1000, directory: URL(string: "/dev/null"))

        var fetcher = GeneralizedImageFetcher()
        fetcher.urlSession = session
        fetcher.urlCache = cache

        trackForMemoryLeaks(cache, file: file, line: line)

        return fetcher
    }
}
