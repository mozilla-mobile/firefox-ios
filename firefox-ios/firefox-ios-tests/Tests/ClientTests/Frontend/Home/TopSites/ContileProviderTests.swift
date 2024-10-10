// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class ContileProviderTests: XCTestCase {
    private var networking: MockContileNetworking!

    override func setUp() {
        super.setUp()
        networking = MockContileNetworking()
    }

    override func tearDown() {
        networking = nil
        super.tearDown()
    }

    func testErrorResponse_failsWithError() {
        networking.error = ContileProvider.Error.noDataAvailable
        let subject = createSubject()

        subject.fetchContiles { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testEmptyResponseAndData_failsWithError() {
        networking.data = getData(from: emptyResponse)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchContiles { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testWrongResponseAndData_failsWithError() {
        networking.data = getData(from: emptyWrongResponse)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchContiles { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testEmptyArrayResponseAndData_failsWithError() {
        networking.data = getData(from: emptyArrayResponse)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchContiles { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    // MARK: - Tile order

    func testOrderingTilePosition_succeedsWithCorrectPosition() {
        networking.data = getData(from: twoTilesWithOutOfOrderPositions)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchContiles { result in
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
        networking.data = getData(from: twoTilesWithOneNilPosition)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchContiles { result in
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
        let data = getData(from: twoTilesWithOutOfOrderPositions)
        let response = getResponse(from: 200)
        let request = getRequest()
        let subject = createSubject()
        subject.cache(response: response, for: request, with: data)

        subject.fetchContiles { result in
            switch result {
            case let .success(contiles):
                XCTAssertEqual(contiles.count, 2)
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testCaching_withEmptyResponse_succeedsFromCache() {
        let data = getData(from: emptyResponse)
        let response = getResponse(from: 200)
        let request = getRequest()
        let subject = createSubject()
        subject.cache(response: response, for: request, with: data)

        subject.fetchContiles { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testCachingExpires_failsIfCacheIsTooOld() {
        let data = getData(from: twoTilesWithOutOfOrderPositions)
        let response = getResponse(from: 200)
        let request = getRequest()
        let subject = createSubject()
        subject.cache(response: response, for: request, with: data)

        subject.fetchContiles(timestamp: Date.tomorrow.toTimestamp()) { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testCachingExpires_failsIfCacheIsNewerThanCurrentDate() {
        let data = getData(from: twoTilesWithOutOfOrderPositions)
        let response = getResponse(from: 200)
        let request = getRequest()
        let subject = createSubject()
        subject.cache(response: response, for: request, with: data)

        subject.fetchContiles(timestamp: Date.yesterday.toTimestamp()) { result in
            switch result {
            case let .failure(error as ContileProvider.Error):
                XCTAssertEqual(error, ContileProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }
}

// MARK: - Helper functions

private extension ContileProviderTests {
    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> ContileProvider {
        let cache = URLCache(memoryCapacity: 100000, diskCapacity: 1000, directory: URL(string: "/dev/null"))
        let subject = ContileProvider(networking: networking, urlCache: cache)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    func getData(from string: String) -> Data {
        return string.data(using: .utf8)!
    }

    func getResponse(from statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(url: URL(string: ContileProvider.contileStagingResourceEndpoint)!,
                               statusCode: statusCode,
                               httpVersion: nil,
                               headerFields: nil)!
    }

    func getRequest() -> URLRequest {
        return URLRequest(url: URL(string: ContileProvider.contileStagingResourceEndpoint)!)
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
