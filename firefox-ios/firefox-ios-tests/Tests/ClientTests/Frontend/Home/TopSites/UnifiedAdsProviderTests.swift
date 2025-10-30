// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import XCTest

@testable import Client

class MockMozAdsClient: MozAdsClientProtocol, @unchecked Sendable {
    var mockPlacements: [String: MozAdsPlacement]?
    var mockError: Error?

    func clearCache() throws {}

    func cycleContextId() throws -> String {
        return "test-context-id"
    }

    func recordClick(placement: MozAdsPlacement) throws {}

    func recordImpression(placement: MozAdsPlacement) throws {}

    func reportAd(placement: MozAdsPlacement) throws {}

    func requestAds(
        mozAdRequests: [MozAdsPlacementRequest],
        options: MozAdsRequestOptions?
    ) throws -> [String: MozAdsPlacement] {
        if let error = mockError {
            throw error
        }
        return mockPlacements ?? [:]
    }
}

class UnifiedAdsProviderTests: XCTestCase {
    private var mockAdsClient: MockMozAdsClient!
    private var networking: MockContileNetworking!

    override func setUp() {
        super.setUp()
        TelemetryContextualIdentifier.setupContextId()
        mockAdsClient = MockMozAdsClient()
        networking = MockContileNetworking()
        LegacyFeatureFlagsManager.shared.set(feature: .adsClient, to: false, isDebug: true)
    }

    override func tearDown() {
        networking = nil
        mockAdsClient = nil
        super.tearDown()
    }

    func testFetchTile_givenErrorResponse_thenFailsWithError() {
        networking.error = UnifiedAdsProvider.Error.noDataAvailable
        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testFetchTile_whenEmptyResponseAndData_thenFailsWithError() {
        networking.data = getData(from: emptyResponse)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testFetchTile_whenWrongResponseAndData_thenFailsWithError() {
        networking.data = getData(from: emptyWrongResponse)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testFetchTile_whenEmptyArrayResponseAndData_thenFailsWithError() {
        networking.data = getData(from: emptyArrayResponse)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testfetchTiles_whenProperTiles_thenSucceedsWithDecodedTiles() {
        networking.data = getData(from: tiles)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .success(tiles):
                XCTAssertEqual(tiles.count, 2)
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testfetchTiles_whenInvertedOrder_thenReturnsProperTileOrder() {
        networking.data = getData(from: invertedTiles)
        networking.response = getResponse(from: 200)
        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .success(tiles):
                XCTAssertEqual(tiles[0].name, "Test1")
                XCTAssertEqual(tiles[1].name, "Test2")
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    // MARK: - Cache

    func testCaching_whenCacheData_thenSucceedsFromCache() {
        let data = getData(from: tiles)
        let response = getResponse(from: 200)
        let request = getRequest()
        let subject = createSubject()
        subject.cache(response: response, for: request, with: data)

        subject.fetchTiles { result in
            switch result {
            case let .success(tiles):
                XCTAssertEqual(tiles.count, 2)
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testCaching_whenEmptyResponse_thenSucceedsFromCache() {
        let data = getData(from: emptyResponse)
        let response = getResponse(from: 200)
        let request = getRequest()
        let subject = createSubject()
        subject.cache(response: response, for: request, with: data)

        subject.fetchTiles { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testCaching_whenExpiredData_thenFailsWhenCacheIsTooOld() {
        let data = getData(from: tiles)
        let response = getResponse(from: 200)
        let request = getRequest()
        let subject = createSubject()
        subject.cache(response: response, for: request, with: data)

        subject.fetchTiles(timestamp: Date.tomorrow.toTimestamp()) { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    func testCaching_whenExpired_thenFailsIfCacheIsNewerThanCurrentDate() {
        let data = getData(from: tiles)
        let response = getResponse(from: 200)
        let request = getRequest()
        let subject = createSubject()
        subject.cache(response: response, for: request, with: data)

        subject.fetchTiles(timestamp: Date.yesterday.toTimestamp()) { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    // MARK: - Ads Client Tests

    func testFetchTilesWithAdsClient_whenSuccessful_thenReturnsTiles() {
        LegacyFeatureFlagsManager.shared.set(feature: .adsClient, to: true, isDebug: true)

        let placementRequest1 = MozAdsPlacementRequest(placementId: "newtab_mobile_tile_1", iabContent: nil)
        let placementRequest2 = MozAdsPlacementRequest(placementId: "newtab_mobile_tile_2", iabContent: nil)

        let adContent1 = MozAd(
            altText: nil,
            blockKey: "12345",
            callbacks: AdCallbacks(click: "https://www.test2.com", impression: "https://www.test3.com", report: nil),
            format: "tile",
            imageUrl: "https://www.test4.com",
            url: "https://www.test1.com"
        )

        let adContent2 = MozAd(
            altText: nil,
            blockKey: "6789",
            callbacks: AdCallbacks(click: "https://www.test6.com", impression: "https://www.test7.com", report: nil),
            format: "tile",
            imageUrl: "https://www.test8.com",
            url: "https://www.test5.com"
        )

        let placement1 = MozAdsPlacement(placementRequest: placementRequest1, content: adContent1)
        let placement2 = MozAdsPlacement(placementRequest: placementRequest2, content: adContent2)

        mockAdsClient.mockPlacements = [
            "newtab_mobile_tile_1": placement1,
            "newtab_mobile_tile_2": placement2
        ]

        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .success(tiles):
                XCTAssertEqual(tiles.count, 2)
                let actual = Dictionary(uniqueKeysWithValues: tiles.map { ($0.name, $0.url) })
                let expected = [
                    "newtab_mobile_tile_1": "https://www.test1.com",
                    "newtab_mobile_tile_2": "https://www.test5.com"
                ]
                XCTAssertEqual(actual, expected)
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testFetchTilesWithAdsClient_whenError_thenFailsWithError() {
        LegacyFeatureFlagsManager.shared.set(feature: .adsClient, to: true, isDebug: true)

        mockAdsClient.mockError = NSError(domain: "test", code: 1)

        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
    }

    // MARK: - Helper functions

    func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line,
    ) -> UnifiedAdsProvider {
        let cache = URLCache(memoryCapacity: 100000, diskCapacity: 1000, directory: URL(string: "/dev/null"))
        let subject = UnifiedAdsProvider(adsClient: mockAdsClient, networking: networking, urlCache: cache)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    func getData(from string: String) -> Data {
        return string.data(using: .utf8)!
    }

    func getResponse(from statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(url: URL(string: UnifiedAdsProvider.stagingResourceEndpoint)!,
                               statusCode: statusCode,
                               httpVersion: nil,
                               headerFields: nil)!
    }

    func getRequest() -> URLRequest {
        return URLRequest(url: URL(string: UnifiedAdsProvider.stagingResourceEndpoint)!)
    }

    // MARK: - Mock responses

    var emptyArrayResponse: String {
        return "{\"newtab_mobile_tile_1\":[]}"
    }

    var emptyWrongResponse: String {
        return "{\"newtab_mobile_tile_1\":[{\"answer\":\"isBad\"}]}"
    }

    var emptyResponse: String {
        return "{}"
    }

    let tiles = """
{
    "newtab_mobile_tile_1": [
        {
            "format": "tile",
            "url": "https://www.test1.com",
            "callbacks": {
                "click": "https://www.test2.com",
                "impression": "https://www.test3.com"
            },
            "image_url": "https://www.test4.com",
            "name": "Test1",
            "block_key": "12345"
        }
    ],
    "newtab_mobile_tile_2": [
        {
            "format": "tile",
            "url": "https://www.test5.com",
            "callbacks": {
                "click": "https://www.test6.com",
                "impression": "https://www.test7.com"
            },
            "image_url": "https://www.test8.com",
            "name": "Test2",
            "block_key": "6789"
        }
    ]
}
"""

    let invertedTiles = """
{
    "newtab_mobile_tile_2": [
        {
            "format": "tile",
            "url": "https://www.test5.com",
            "callbacks": {
                "click": "https://www.test6.com",
                "impression": "https://www.test7.com"
            },
            "image_url": "https://www.test8.com",
            "name": "Test2",
            "block_key": "6789"
        }
    ],
    "newtab_mobile_tile_1": [
        {
            "format": "tile",
            "url": "https://www.test1.com",
            "callbacks": {
                "click": "https://www.test2.com",
                "impression": "https://www.test3.com"
            },
            "image_url": "https://www.test4.com",
            "name": "Test1",
            "block_key": "12345"
        }
    ]
}
"""

    var anError: NSError {
        return NSError(domain: "test error", code: 0)
    }
}
