// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class PocketSponsoredStoriesProviderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        clearState()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        clearState()
    }

    func testErrorResponse_failsWithError() {
        stubResponse(response: nil, statusCode: 200, error: anError)
        testProvider { result in
            switch result {
            case let .failure(error as PocketSponsoredStoriesProvider.Error):
                XCTAssertEqual(error, PocketSponsoredStoriesProvider.Error.failure)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testNilDataResponse_failsWithError() {
        stubResponse(response: nil, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .failure(error as PocketSponsoredStoriesProvider.Error):
                XCTAssertEqual(error, PocketSponsoredStoriesProvider.Error.invalidHTTPResponse)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testEmptyResponse_failsWithError() {
        stubResponse(response: emptyResponse, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .failure(error as PocketSponsoredStoriesProvider.Error):
                XCTAssertEqual(error, PocketSponsoredStoriesProvider.Error.decodingFailure)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testAuthStatusCodeResponse_failsWithError() {
        stubResponse(response: nil, statusCode: 403, error: nil)
        testProvider { result in
            switch result {
            case let .failure(error as PocketSponsoredStoriesProvider.Error):
                XCTAssertEqual(error, PocketSponsoredStoriesProvider.Error.invalidHTTPResponse)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testWrongResponse_failsWithError() {
        stubResponse(response: emptyWrongResponse, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .failure(error as PocketSponsoredStoriesProvider.Error):
                XCTAssertEqual(error, PocketSponsoredStoriesProvider.Error.decodingFailure)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testEmptyArrayResponse_succeedsWithEmptyArray() {
        stubResponse(response: emptyArrayResponse, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .success(stories):
                XCTAssertEqual(stories, [])
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testValidResponse_succeedsWithValidSponsoredStories() {
        stubResponse(response: validSpocResponse, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .success(stories):
                XCTAssertEqual(stories.count, 2)
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testCachingExpires_failsIfCacheIsTooOld() {
        stubResponse(response: validSpocResponse, statusCode: 200, error: nil)
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        provider.fetchSponsoredStories { result in
            self.stubResponse(response: nil, statusCode: 403, error: nil)
            provider.fetchSponsoredStories(timestamp: Date.tomorrow.toTimestamp()) { result in
                switch result {
                case let .failure(error as PocketSponsoredStoriesProvider.Error):
                    XCTAssertEqual(error, PocketSponsoredStoriesProvider.Error.invalidHTTPResponse)
                default:
                    XCTFail("Expected failure, got \(result) instead")
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCachingExpires_failsIfCacheIsNewerThanCurrentDate() {
        stubResponse(response: validSpocResponse, statusCode: 200, error: nil)
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        provider.fetchSponsoredStories { result in
            self.stubResponse(response: nil, statusCode: 403, error: nil)
            provider.fetchSponsoredStories(timestamp: Date.yesterday.toTimestamp()) { result in
                switch result {
                case let .failure(error as PocketSponsoredStoriesProvider.Error):
                    XCTAssertEqual(error, PocketSponsoredStoriesProvider.Error.invalidHTTPResponse)
                default:
                    XCTFail("Expected failure, got \(result) instead")
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testNoStubbing_doesntComplete() {
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        expectation.isInverted = true
        provider.fetchSponsoredStories { result in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

// MARK: - Helper functions

private extension PocketSponsoredStoriesProviderTests {
    func getProvider(file: StaticString = #filePath, line: UInt = #line) -> PocketSponsoredStoriesProviding {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let cache = URLCache(memoryCapacity: 100000, diskCapacity: 1000, directory: URL(string: "/dev/null"))

        let provider = PocketSponsoredStoriesProvider()
        provider.urlSession = session
        provider.urlCache = cache

        trackForMemoryLeaks(provider, file: file, line: line)
        trackForMemoryLeaks(cache, file: file, line: line)

        return provider
    }

    func testProvider(completion: @escaping (Result<[PocketSponsoredStory], Error>) -> Void) {
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        provider.fetchSponsoredStories { result in
            completion(result)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func stubResponse(response: String?, statusCode: Int, error: Error?) {
        let mockJSONData = response?.data(using: .utf8)
        let response = HTTPURLResponse(url: PocketSponsoredConstants.staging,
                                       statusCode: statusCode,
                                       httpVersion: nil,
                                       headerFields: nil)!
        URLProtocolStub.stub(data: mockJSONData, response: response, error: error)
    }

    func clearState() {
        URLProtocolStub.removeStub()
    }

    // MARK: - Mock responses

    var emptyArrayResponse: String {
        """
        {
        "spocs": []
        }
        """
    }

    var emptyWrongResponse: String {
        """
        {
            "bad": []
        }
        """
    }

    var emptyResponse: String {
        return "{}"
    }

    var validSpocResponse: String {
        """
        {
            "spocs": [
                \(spoc1),
                \(spoc2)
            ]
        }
        """
    }

    var spoc1: String {
        """
        {
            "id" : 1,
            "flight_id" : 1,
            "campaign_id" : 1,
            "title" : "test",
            "domain" : "test",
            "excerpt" : "test",
            "priority" : 2,
            "context" : "test",
            "raw_image_src" : "www.google.com",
            "image_src" : "www.google.com",
            "sponsor" : "test",
            "caps": {
                "lifetime": 50,
                "campaign": {
                    "count": 10,
                    "period": 86400
                },
                "flight": {
                    "count": 10,
                    "period": 86400
                }
            },
             "shim": {
                 "click": "test",
                 "impression": "test",
                 "delete": "test",
                 "save": "test"
             }
        }
        """
    }

    var spoc2: String {
        """
        {
            "id" : 1,
            "flight_id" : 1,
            "campaign_id" : 1,
            "title" : "test",
            "domain" : "test",
            "excerpt" : "test",
            "priority" : 2,
            "context" : "test",
            "raw_image_src" : "www.google.com",
            "image_src" : "www.google.com",
            "sponsor" : "test",
            "caps": {
                "lifetime": 50,
                "campaign": {
                    "count": 10,
                    "period": 86400
                },
                "flight": {
                    "count": 10,
                    "period": 86400
                }
            },
             "shim": {
                 "click": "test",
                 "impression": "test",
                 "delete": "test",
                 "save": "test"
             }
        }
        """
    }

    var anError: NSError {
        return NSError(domain: "test error", code: 0)
    }
}
