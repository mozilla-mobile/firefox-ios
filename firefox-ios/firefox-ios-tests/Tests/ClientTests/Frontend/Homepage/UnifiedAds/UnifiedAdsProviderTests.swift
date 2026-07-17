// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared
import XCTest

@testable import Client

class MockMozAdsClient: MozAdsClient, @unchecked Sendable {
    var mockAdsImages: [String: MozAdsImage]?
    var mockAdsTiles: [String: MozAdsTile]?
    var mockError: Error?

    var recordClickCalledWith: String?
    var recordImpressionCalledWith: String?
    var requestTileAdsCalledCount = 0

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
        requestTileAdsCalledCount += 1
        if let error = mockError { throw error }
        return mockAdsTiles ?? [:]
    }
}

/// Collects dispatched work so tests can control when the provider's fetch queue runs,
/// simulating requests that are still in flight.
private final class PendingWorkDispatchQueue: DispatchQueueInterface, @unchecked Sendable {
    private(set) var pendingWork: [() -> Void] = []

    func runAllPendingWork() {
        let work = pendingWork
        pendingWork = []
        work.forEach { $0() }
    }

    func async(group: DispatchGroup?,
               qos: DispatchQoS,
               flags: DispatchWorkItemFlags,
               execute work: @escaping @Sendable @convention(block) () -> Void) {
        pendingWork.append(work)
    }

    func asyncAfter(deadline: DispatchTime,
                    qos: DispatchQoS,
                    flags: DispatchWorkItemFlags,
                    execute work: @escaping @Sendable @convention(block) () -> Void) {
        pendingWork.append(work)
    }

    func asyncAfter(deadline: DispatchTime, execute: DispatchWorkItem) {
        pendingWork.append { execute.perform() }
    }
}

@MainActor
class UnifiedAdsProviderTests: XCTestCase {
    private var mockAdsClient: MockMozAdsClient!

    private let baseTimestamp: Timestamp = 1_735_000_000_000
    private let oneMinute: Timestamp = OneMinuteInMilliseconds
    private let maxStaleness: Timestamp = UnifiedAdsProvider.maxTileStaleness

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
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.test1.com"),
            "newtab_mobile_tile_2": createAdTile(name: "newtab_mobile_tile_2", url: "https://www.test5.com")
        ]

        let subject = createSubject()

        fetchTilesAndExpect(tileURLs: ["https://www.test1.com", "https://www.test5.com"],
                            from: subject,
                            timestamp: baseTimestamp)
    }

    func testFetchTiles_whenInvertedOrder_thenReturnsProperTileOrder() {
        // Insert position2 before position1 to verify the order does not depend
        // on the dictionary's iteration order.
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_2": createAdTile(name: "newtab_mobile_tile_2", url: "https://www.test5.com"),
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.test1.com")
        ]

        let subject = createSubject()

        fetchTilesAndExpect(tileURLs: ["https://www.test1.com", "https://www.test5.com"],
                            from: subject,
                            timestamp: baseTimestamp)
    }

    func testFetchTiles_whenOnlyFirstPlacement_thenReturnsSingleTile() {
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.test1.com")
        ]

        let subject = createSubject()

        fetchTilesAndExpect(tileURLs: ["https://www.test1.com"], from: subject, timestamp: baseTimestamp)
    }

    func testFetchTiles_whenErrorAndNoLastKnownTiles_thenFailsWithError() {
        mockAdsClient.mockError = NSError(domain: "test", code: 1)

        let subject = createSubject()
        let expectation = expectation(description: "fetchTiles completion is called")

        subject.fetchTiles(timestamp: baseTimestamp) { result in
            switch result {
            case let .failure(error as UnifiedAdsProvider.Error):
                XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - Serving last known tiles

    func testFetchTiles_withinStalenessWindow_servesLastKnownTilesAndRevalidates() {
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.first.com")
        ]

        let subject = createSubject()
        fetchTilesAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.refreshed.com")
        ]

        fetchTilesAndExpect(tileURLs: ["https://www.first.com"],
                            from: subject,
                            timestamp: baseTimestamp + 30 * oneMinute)
        XCTAssertEqual(mockAdsClient.requestTileAdsCalledCount, 2, "Expected a background revalidation request")
    }

    func testFetchTiles_afterRevalidation_servesRefreshedTiles() {
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.first.com")
        ]

        let subject = createSubject()
        fetchTilesAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.refreshed.com")
        ]
        fetchTilesAndExpect(tileURLs: ["https://www.first.com"],
                            from: subject,
                            timestamp: baseTimestamp + 30 * oneMinute)

        fetchTilesAndExpect(tileURLs: ["https://www.refreshed.com"],
                            from: subject,
                            timestamp: baseTimestamp + 31 * oneMinute)
    }

    func testFetchTiles_atExactStalenessBound_servesLastKnownTiles() {
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.first.com")
        ]

        let subject = createSubject()
        fetchTilesAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.refreshed.com")
        ]

        fetchTilesAndExpect(tileURLs: ["https://www.first.com"],
                            from: subject,
                            timestamp: baseTimestamp + maxStaleness)
    }

    func testFetchTiles_beyondStalenessWindow_fetchesFromAdsClient() {
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.first.com")
        ]

        let subject = createSubject()
        fetchTilesAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.refreshed.com")
        ]

        fetchTilesAndExpect(tileURLs: ["https://www.refreshed.com"],
                            from: subject,
                            timestamp: baseTimestamp + maxStaleness + 1)
        XCTAssertEqual(mockAdsClient.requestTileAdsCalledCount, 2)
    }

    func testFetchTiles_whenRevalidationFails_keepsServingLastKnownTiles() {
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.first.com")
        ]

        let subject = createSubject()
        fetchTilesAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockError = NSError(domain: "test", code: 1)

        fetchTilesAndExpect(tileURLs: ["https://www.first.com"],
                            from: subject,
                            timestamp: baseTimestamp + 30 * oneMinute)
        fetchTilesAndExpect(tileURLs: ["https://www.first.com"],
                            from: subject,
                            timestamp: baseTimestamp + 31 * oneMinute)
        XCTAssertEqual(mockAdsClient.requestTileAdsCalledCount, 3, "Expected one revalidation per served fetch")
    }

    func testFetchTiles_whenEmptySuccess_cachesEmptyTiles() {
        mockAdsClient.mockAdsTiles = [:]

        let subject = createSubject()
        fetchTilesAndExpect(tileURLs: [], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.refreshed.com")
        ]

        fetchTilesAndExpect(tileURLs: [], from: subject, timestamp: baseTimestamp + oneMinute)
        fetchTilesAndExpect(tileURLs: ["https://www.refreshed.com"],
                            from: subject,
                            timestamp: baseTimestamp + 2 * oneMinute)
    }

    func testFetchTiles_whileRevalidationInFlight_doesNotStartSecondRevalidation() {
        let pendingQueue = PendingWorkDispatchQueue()
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.first.com")
        ]

        let subject = createSubject(fetchQueue: pendingQueue)
        subject.fetchTiles(timestamp: baseTimestamp) { _ in }
        pendingQueue.runAllPendingWork()

        subject.fetchTiles(timestamp: baseTimestamp + 30 * oneMinute) { _ in }
        subject.fetchTiles(timestamp: baseTimestamp + 31 * oneMinute) { _ in }

        XCTAssertEqual(pendingQueue.pendingWork.count, 1, "Expected the in-flight revalidation to be reused")

        pendingQueue.runAllPendingWork()
        XCTAssertEqual(mockAdsClient.requestTileAdsCalledCount, 2)
    }

    func testFetchTiles_resultArrivingAfterCallerStoppedWaiting_isServedOnNextFetch() {
        let pendingQueue = PendingWorkDispatchQueue()
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.first.com")
        ]

        let subject = createSubject(fetchQueue: pendingQueue)
        subject.fetchTiles(timestamp: baseTimestamp) { _ in }

        // The slow request completes only after the caller stopped waiting for it.
        pendingQueue.runAllPendingWork()

        fetchTilesAndExpect(tileURLs: ["https://www.first.com"],
                            from: subject,
                            timestamp: baseTimestamp + oneMinute)
        XCTAssertFalse(pendingQueue.pendingWork.isEmpty, "Expected a background revalidation to be enqueued")
        pendingQueue.runAllPendingWork()
    }

    // MARK: - Helper functions

    private func fetchTilesAndExpect(
        tileURLs expectedTileURLs: [String],
        from subject: UnifiedAdsProvider,
        timestamp: Timestamp,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "fetchTiles completion is called")
        subject.fetchTiles(timestamp: timestamp) { result in
            switch result {
            case let .success(tiles):
                XCTAssertEqual(tiles.map(\.url), expectedTileURLs, file: file, line: line)
            case .failure:
                XCTFail("Expected success, got \(result) instead", file: file, line: line)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    private func createAdTile(name: String, url: String) -> MozAdsTile {
        return MozAdsTile(
            blockKey: "12345",
            callbacks: MozAdsCallbacks(
                click: "\(url)/click",
                impression: "\(url)/impression",
                report: nil
            ),
            format: "tile",
            imageUrl: "\(url)/image",
            name: name,
            url: url
        )
    }

    func createSubject(
        fetchQueue: DispatchQueueInterface = MockDispatchQueue(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UnifiedAdsProvider {
        let factory = MockMozAdsClientFactory(mockClient: mockAdsClient)
        let subject = UnifiedAdsProvider(adsClientFactory: factory, fetchQueue: fetchQueue)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}
