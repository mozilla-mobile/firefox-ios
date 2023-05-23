// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import XCTest

@testable import Client

class ContileProviderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearState()
    }

    override func tearDown() {
        super.tearDown()
        clearState()
    }

    func testErrorResponse_failsWithError() {
        stubResponse(response: nil, statusCode: 200, error: anError)
        testProvider { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.failure)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testNilDataResponse_failsWithError() {
        stubResponse(response: nil, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.failure)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testEmptyResponse_failsWithError() {
        stubResponse(response: emptyResponse, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.failure)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testAuthStatusCodeResponse_failsWithError() {
        stubResponse(response: nil, statusCode: 403, error: nil)
        testProvider { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.failure)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testWrongResponse_failsWithError() {
        stubResponse(response: emptyWrongResponse, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.failure)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testEmptyArrayResponse_succeedsWithEmptyArray() {
        stubResponse(response: emptyArrayResponse, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .success(contiles):
                XCTAssertEqual(contiles, [])
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    // MARK: - Tile order

    func testOrderingTilePosition_succeedsWithCorrectPosition() {
        stubResponse(response: twoTilesWithOutOfOrderPositions, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .success(contiles):
                XCTAssertEqual(contiles[0].name, "Tile1")
                XCTAssertEqual(contiles[1].name, "Tile2")
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testOrderingTilePositionWithNilPosition_succeedsWithCorrectPosition() {
        stubResponse(response: twoTilesWithOneNilPosition, statusCode: 200, error: nil)
        testProvider { result in
            switch result {
            case let .success(contiles):
                XCTAssertEqual(contiles[0].name, "TileNilPosition")
                XCTAssertEqual(contiles[1].name, "Tile1")
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    // MARK: - Cache

    func testCaching_succeedsFromCache() {
        stubResponse(response: twoTilesWithOutOfOrderPositions, statusCode: 200, error: nil)
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        provider.fetchContiles { result in
            URLProtocolStub.removeStub()

            provider.fetchContiles { result in
                switch result {
                case let .success(contiles):
                    XCTAssertEqual(contiles.count, 2)
                default:
                    XCTFail("Expected success, got \(result) instead")
                }

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCaching_withEmptyResponse_succeedsFromCache() {
        stubResponse(response: emptyResponse, statusCode: 200, error: nil)
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        provider.fetchContiles { _ in
            URLProtocolStub.removeStub()

            provider.fetchContiles { result in
                switch result {
                case let .failure(error as ContileProvider.Error):
                    XCTAssertEqual(error, ContileProvider.Error.failure)
                default:
                    XCTFail("Expected failure, got \(result) instead")
                }

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCachingExpires_failsIfCacheIsTooOld() {
        stubResponse(response: twoTilesWithOutOfOrderPositions, statusCode: 200, error: nil)
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        provider.fetchContiles { result in
            self.stubResponse(response: nil, statusCode: 403, error: nil)

            provider.fetchContiles(timestamp: Date.tomorrow.toTimestamp()) { result in
                switch result {
                case let .failure(error as ContileProvider.Error):
                    XCTAssertEqual(error, ContileProvider.Error.failure)
                default:
                    XCTFail("Expected failure, got \(result) instead")
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCachingExpires_failsIfCacheIsNewerThanCurrentDate() {
        stubResponse(response: twoTilesWithOutOfOrderPositions, statusCode: 200, error: nil)
        let provider = getProvider()
        let expectation = expectation(description: "Wait for completion")
        provider.fetchContiles { result in
            self.stubResponse(response: nil, statusCode: 403, error: nil)

            provider.fetchContiles(timestamp: Date.yesterday.toTimestamp()) { result in
                switch result {
                case let .failure(error as ContileProvider.Error):
                    XCTAssertEqual(error, ContileProvider.Error.failure)
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
        provider.fetchContiles { result in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

// MARK: - Helper functions

private extension ContileProviderTests {
    func getProvider(file: StaticString = #filePath, line: UInt = #line) -> ContileProvider {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let cache = URLCache(memoryCapacity: 100000, diskCapacity: 1000, directory: URL(string: "/dev/null"))

        let subject = ContileProvider()
        subject.urlSession = session
        subject.urlCache = cache

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    func testProvider(file: StaticString = #filePath, line: UInt = #line, completion: @escaping (ContileResult) -> Void) {
        let provider = getProvider(file: file, line: line)
        let expectation = expectation(description: "Wait for completion")
        provider.fetchContiles { result in
            completion(result)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func stubResponse(response: String?, statusCode: Int, error: Error?) {
        let mockJSONData = response?.data(using: .utf8)
        let response = HTTPURLResponse(url: URL(string: ContileProvider.contileStagingResourceEndpoint)!,
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
        return "{\"tiles\":[]}"
    }

    var emptyWrongResponse: String {
        return "{\"tiles\":[{\"answer\":\"isBad\"}]}"
    }

    var emptyResponse: String {
        return "{}"
    }

    var twoTilesWithOneNilPosition: String {
        return "{\"tiles\":[\(oneTileEmptyPosition),\(oneTileWithPosition)]}"
    }

    var twoTilesWithOutOfOrderPositions: String {
        return "{\"tiles\":[\(secondTileWithPosition),\(oneTileWithPosition)]}"
    }

    var oneTileEmptyPosition: String {
        return """
{\"id\":1,\"name\":\"TileNilPosition\",\"url\":\"https://www.website.com\",\"\
click_url\":\"https://www.website.com\",\"image_url\":\"https://www.website.com\",\"\
image_size\":200,\"impression_url\":\"https://www.website.com\"}
"""
    }

    var oneTileWithPosition: String {
        return """
{\"id\":1,\"name\":\"Tile1\",\"url\":\"https://www.website.com\",\"click_url\":\"\
https://www.website.com\",\"image_url\":\"https://www.website.com\",\"\
image_size\":200,\"impression_url\":\"https://www.website.com\",\"position\":1}
"""
    }

    var secondTileWithPosition: String {
        return """
{\"id\":2,\"name\":\"Tile2\",\"url\":\"https://www.website2.com\",\"click_url\":\"\
https://www.website2.com\",\"image_url\":\"https://www.website2.com\",\"\
image_size\":200,\"impression_url\":\"https://www.website2.com\",\"position\":2}
"""
    }

    var anError: NSError {
        return NSError(domain: "test error", code: 0)
    }
}
