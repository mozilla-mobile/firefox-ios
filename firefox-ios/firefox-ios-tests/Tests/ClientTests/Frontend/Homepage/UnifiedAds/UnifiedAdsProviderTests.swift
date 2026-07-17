// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import XCTest

@testable import Client

class MockMozAdsClient: MozAdsClient, @unchecked Sendable {
    var mockAdsImages: [String: MozAdsImage]?
    var mockAdsTiles: [String: MozAdsTile]?
    var mockError: Error?

    var recordClickCalledWith: String?
    var recordImpressionCalledWith: String?

    init() {
        super.init(noHandle: MozAdsClient.NoHandle())
    }

    required init(unsafeFromHandle handle: UInt64) {
        super.init(unsafeFromHandle: handle)
    }

    override func recordClick(clickUrl: String, options: MozAdsCallbackOptions?) throws {
        if let error = mockError { throw error }
        recordClickCalledWith = clickUrl
    }

    override func recordImpression(impressionUrl: String, options: MozAdsCallbackOptions?) throws {
        if let error = mockError { throw error }
        recordImpressionCalledWith = impressionUrl
    }

    override func reportAd(reportUrl: String, reason: MozAdsReportReason, options: MozAdsCallbackOptions?) throws {}

    override func requestImageAds(
        mozAdRequests: [MozAdsPlacementRequest],
        options: MozAdsRequestOptions?
    ) throws -> [String: MozAdsImage] {
        if let error = mockError { throw error }
        return mockAdsImages ?? [:]
    }

    override func requestSpocAds(
        mozAdRequests: [MozAdsPlacementRequestWithCount],
        options: MozAdsRequestOptions?
    ) throws -> [String: [MozAdsSpoc]] {
        return [:]
    }

    override func requestTileAds(
        mozAdRequests: [MozAdsPlacementRequest],
        options: MozAdsRequestOptions?
    ) throws -> [String: MozillaAppServices.MozAdsTile] {
        if let error = mockError { throw error }
        return mockAdsTiles ?? [:]
    }
}

@MainActor
class UnifiedAdsProviderTests: XCTestCase {
    private var mockAdsClient: MockMozAdsClient!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        TelemetryContextualIdentifier.setupContextId()
        mockAdsClient = MockMozAdsClient()
    }

    override func tearDown() async throws {
        mockAdsClient = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testFetchTiles_whenSuccessful_thenReturnsTiles() {
        let adTile1 = MozAdsTile(
            blockKey: "12345",
            callbacks: MozAdsCallbacks(
                click: "https://www.test2.com",
                impression: "https://www.test3.com",
                report: nil
            ),
            format: "tile",
            imageUrl: "https://www.test4.com",
            name: "newtab_mobile_tile_1",
            url: "https://www.test1.com"
        )

        let adTile2 = MozAdsTile(
            blockKey: "6789",
            callbacks: MozAdsCallbacks(
                click: "https://www.test6.com",
                impression: "https://www.test7.com",
                report: nil
            ),
            format: "tile",
            imageUrl: "https://www.test8.com",
            name: "newtab_mobile_tile_2",
            url: "https://www.test5.com"
        )

        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": adTile1,
            "newtab_mobile_tile_2": adTile2
        ]

        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .success(tiles):
                XCTAssertEqual(tiles.count, 2)
                XCTAssertEqual(tiles[0].url, "https://www.test1.com")
                XCTAssertEqual(tiles[1].url, "https://www.test5.com")
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testFetchTiles_whenInvertedOrder_thenReturnsProperTileOrder() {
        let adTile1 = MozAdsTile(
            blockKey: "12345",
            callbacks: MozAdsCallbacks(
                click: "https://www.test2.com",
                impression: "https://www.test3.com",
                report: nil
            ),
            format: "tile",
            imageUrl: "https://www.test4.com",
            name: "newtab_mobile_tile_1",
            url: "https://www.test1.com"
        )

        let adTile2 = MozAdsTile(
            blockKey: "6789",
            callbacks: MozAdsCallbacks(
                click: "https://www.test6.com",
                impression: "https://www.test7.com",
                report: nil
            ),
            format: "tile",
            imageUrl: "https://www.test8.com",
            name: "newtab_mobile_tile_2",
            url: "https://www.test5.com"
        )

        // Insert position2 before position1 to verify the order does not depend
        // on the dictionary's iteration order.
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_2": adTile2,
            "newtab_mobile_tile_1": adTile1
        ]

        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .success(tiles):
                XCTAssertEqual(tiles.count, 2)
                XCTAssertEqual(tiles[0].url, "https://www.test1.com")
                XCTAssertEqual(tiles[1].url, "https://www.test5.com")
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testFetchTiles_whenOnlyFirstPlacement_thenReturnsSingleTile() {
        let adTile1 = MozAdsTile(
            blockKey: "12345",
            callbacks: MozAdsCallbacks(
                click: "https://www.test2.com",
                impression: "https://www.test3.com",
                report: nil
            ),
            format: "tile",
            imageUrl: "https://www.test4.com",
            name: "newtab_mobile_tile_1",
            url: "https://www.test1.com"
        )

        mockAdsClient.mockAdsTiles = ["newtab_mobile_tile_1": adTile1]

        let subject = createSubject()

        subject.fetchTiles { result in
            switch result {
            case let .success(tiles):
                XCTAssertEqual(tiles.count, 1)
                XCTAssertEqual(tiles[0].url, "https://www.test1.com")
            default:
                XCTFail("Expected success, got \(result) instead")
            }
        }
    }

    func testFetchTiles_whenError_thenFailsWithError() {
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

    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> UnifiedAdsProvider {
        let factory = MockMozAdsClientFactory(mockClient: mockAdsClient)
        let subject = UnifiedAdsProvider(adsClientFactory: factory)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}
