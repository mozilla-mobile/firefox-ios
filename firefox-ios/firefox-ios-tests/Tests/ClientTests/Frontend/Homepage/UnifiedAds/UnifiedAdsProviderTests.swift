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
    private let lock = NSLock()
    private var enqueuedWork: [() -> Void] = []
    private var enqueueWaiters: [CheckedContinuation<Void, Never>] = []

    var pendingWork: [() -> Void] {
        lock.lock()
        defer { lock.unlock() }
        return enqueuedWork
    }

    func runAllPendingWork() {
        lock.lock()
        let work = enqueuedWork
        enqueuedWork = []
        lock.unlock()

        work.forEach { $0() }
    }

    /// Suspends until at least one work item has been enqueued, so tests can deterministically
    /// wait for the provider's background request to reach the queue.
    func waitForPendingWork() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if !enqueuedWork.isEmpty {
                lock.unlock()
                continuation.resume()
            } else {
                enqueueWaiters.append(continuation)
                lock.unlock()
            }
        }
    }

    func async(group: DispatchGroup?,
               qos: DispatchQoS,
               flags: DispatchWorkItemFlags,
               execute work: @escaping @Sendable @convention(block) () -> Void) {
        lock.lock()
        enqueuedWork.append(work)
        let waiters = enqueueWaiters
        enqueueWaiters = []
        lock.unlock()

        waiters.forEach { $0.resume() }
    }

    func asyncAfter(deadline: DispatchTime,
                    qos: DispatchQoS,
                    flags: DispatchWorkItemFlags,
                    execute work: @escaping @Sendable @convention(block) () -> Void) {
        async(group: nil, qos: qos, flags: flags, execute: work)
    }

    func asyncAfter(deadline: DispatchTime, execute: DispatchWorkItem) {
        async(group: nil, qos: .unspecified, flags: []) { execute.perform() }
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

    func testFetchTiles_whenSuccessful_thenReturnsTiles() async {
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.test1.com"),
            "newtab_mobile_tile_2": createAdTile(name: "newtab_mobile_tile_2", url: "https://www.test5.com")
        ]

        let subject = createSubject()

        await fetchAndExpect(tileURLs: ["https://www.test1.com", "https://www.test5.com"],
                             from: subject,
                             timestamp: baseTimestamp)
    }

    func testFetchTiles_whenInvertedOrder_thenReturnsProperTileOrder() async {
        // Insert position2 before position1 to verify the order does not depend
        // on the dictionary's iteration order.
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_2": createAdTile(name: "newtab_mobile_tile_2", url: "https://www.test5.com"),
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.test1.com")
        ]

        let subject = createSubject()

        await fetchAndExpect(tileURLs: ["https://www.test1.com", "https://www.test5.com"],
                             from: subject,
                             timestamp: baseTimestamp)
    }

    func testFetchTiles_whenOnlyFirstPlacement_thenReturnsSingleTile() async {
        mockAdsClient.mockAdsTiles = [
            "newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: "https://www.test1.com")
        ]

        let subject = createSubject()

        await fetchAndExpect(tileURLs: ["https://www.test1.com"], from: subject, timestamp: baseTimestamp)
    }

    func testFetchTiles_whenErrorAndNoLastKnownTiles_thenFailsWithError() async {
        mockAdsClient.mockError = NSError(domain: "test", code: 1)

        let subject = createSubject()
        let result = await subject.fetchTiles(timestamp: baseTimestamp)

        switch result {
        case let .failure(error as UnifiedAdsProvider.Error):
            XCTAssertEqual(error, UnifiedAdsProvider.Error.noDataAvailable)
        default:
            XCTFail("Expected failure, got \(result) instead")
        }
    }

    // MARK: - Serving last known tiles

    func testFetchTiles_withinStalenessWindow_servesLastKnownTilesAndRevalidates() async {
        mockAdsClient.mockAdsTiles = tiles(url: "https://www.first.com")

        let subject = createSubject()
        await fetchAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = tiles(url: "https://www.refreshed.com")

        await fetchAndExpect(tileURLs: ["https://www.first.com"],
                             from: subject,
                             timestamp: baseTimestamp + 30 * oneMinute)
        await subject.awaitPendingRevalidation()
        XCTAssertEqual(mockAdsClient.requestTileAdsCalledCount, 2, "Expected a background revalidation request")
    }

    func testFetchTiles_afterRevalidation_servesRefreshedTiles() async {
        mockAdsClient.mockAdsTiles = tiles(url: "https://www.first.com")

        let subject = createSubject()
        await fetchAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = tiles(url: "https://www.refreshed.com")
        await fetchAndExpect(tileURLs: ["https://www.first.com"],
                             from: subject,
                             timestamp: baseTimestamp + 30 * oneMinute)
        await subject.awaitPendingRevalidation()

        await fetchAndExpect(tileURLs: ["https://www.refreshed.com"],
                             from: subject,
                             timestamp: baseTimestamp + 31 * oneMinute)
        await subject.awaitPendingRevalidation()
    }

    func testFetchTiles_atExactStalenessBound_servesLastKnownTiles() async {
        mockAdsClient.mockAdsTiles = tiles(url: "https://www.first.com")

        let subject = createSubject()
        await fetchAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = tiles(url: "https://www.refreshed.com")

        await fetchAndExpect(tileURLs: ["https://www.first.com"],
                             from: subject,
                             timestamp: baseTimestamp + maxStaleness)
        await subject.awaitPendingRevalidation()
    }

    func testFetchTiles_beyondStalenessWindow_fetchesFromAdsClient() async {
        mockAdsClient.mockAdsTiles = tiles(url: "https://www.first.com")

        let subject = createSubject()
        await fetchAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = tiles(url: "https://www.refreshed.com")

        await fetchAndExpect(tileURLs: ["https://www.refreshed.com"],
                             from: subject,
                             timestamp: baseTimestamp + maxStaleness + 1)
        XCTAssertEqual(mockAdsClient.requestTileAdsCalledCount, 2)
    }

    func testFetchTiles_whenRevalidationFails_keepsServingLastKnownTiles() async {
        mockAdsClient.mockAdsTiles = tiles(url: "https://www.first.com")

        let subject = createSubject()
        await fetchAndExpect(tileURLs: ["https://www.first.com"], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockError = NSError(domain: "test", code: 1)

        await fetchAndExpect(tileURLs: ["https://www.first.com"],
                             from: subject,
                             timestamp: baseTimestamp + 30 * oneMinute)
        await subject.awaitPendingRevalidation()

        await fetchAndExpect(tileURLs: ["https://www.first.com"],
                             from: subject,
                             timestamp: baseTimestamp + 31 * oneMinute)
        await subject.awaitPendingRevalidation()
        XCTAssertEqual(mockAdsClient.requestTileAdsCalledCount, 3, "Expected one revalidation per served fetch")
    }

    func testFetchTiles_whenEmptySuccess_cachesEmptyTiles() async {
        mockAdsClient.mockAdsTiles = [:]

        let subject = createSubject()
        await fetchAndExpect(tileURLs: [], from: subject, timestamp: baseTimestamp)

        mockAdsClient.mockAdsTiles = tiles(url: "https://www.refreshed.com")

        await fetchAndExpect(tileURLs: [], from: subject, timestamp: baseTimestamp + oneMinute)
        await subject.awaitPendingRevalidation()
        await fetchAndExpect(tileURLs: ["https://www.refreshed.com"],
                             from: subject,
                             timestamp: baseTimestamp + 2 * oneMinute)
        await subject.awaitPendingRevalidation()
    }

    func testFetchTiles_whileRevalidationInFlight_doesNotStartSecondRevalidation() async {
        let pendingQueue = PendingWorkDispatchQueue()
        mockAdsClient.mockAdsTiles = tiles(url: "https://www.first.com")

        let subject = createSubject(fetchQueue: pendingQueue)

        // Warm the cache with a cold fetch whose blocking work we run explicitly.
        let coldFetch = Task { await subject.fetchTiles(timestamp: baseTimestamp) }
        await pendingQueue.waitForPendingWork()
        pendingQueue.runAllPendingWork()
        _ = await coldFetch.value

        // The first warm fetch starts a revalidation; the second must reuse the in-flight one.
        _ = await subject.fetchTiles(timestamp: baseTimestamp + 30 * oneMinute)
        _ = await subject.fetchTiles(timestamp: baseTimestamp + 31 * oneMinute)

        await pendingQueue.waitForPendingWork()
        XCTAssertEqual(pendingQueue.pendingWork.count, 1, "Expected the in-flight revalidation to be reused")

        pendingQueue.runAllPendingWork()
        await subject.awaitPendingRevalidation()
        XCTAssertEqual(mockAdsClient.requestTileAdsCalledCount, 2)
    }

    func testFetchTiles_resultArrivingAfterCallerStoppedWaiting_isServedOnNextFetch() async {
        let pendingQueue = PendingWorkDispatchQueue()
        mockAdsClient.mockAdsTiles = tiles(url: "https://www.first.com")

        let subject = createSubject(fetchQueue: pendingQueue)

        // The caller stops waiting for the result; the slow request only completes afterwards.
        let coldFetch = Task { _ = await subject.fetchTiles(timestamp: baseTimestamp) }
        await pendingQueue.waitForPendingWork()
        pendingQueue.runAllPendingWork()
        _ = await coldFetch.value

        await fetchAndExpect(tileURLs: ["https://www.first.com"],
                             from: subject,
                             timestamp: baseTimestamp + oneMinute)

        await pendingQueue.waitForPendingWork()
        XCTAssertFalse(pendingQueue.pendingWork.isEmpty, "Expected a background revalidation to be enqueued")
        pendingQueue.runAllPendingWork()
        await subject.awaitPendingRevalidation()
    }

    // MARK: - Helper functions

    private func fetchAndExpect(
        tileURLs expectedTileURLs: [String],
        from subject: UnifiedAdsProvider,
        timestamp: Timestamp,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let result = await subject.fetchTiles(timestamp: timestamp)
        switch result {
        case let .success(tiles):
            XCTAssertEqual(tiles.map(\.url), expectedTileURLs, file: file, line: line)
        case .failure:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
        }
    }

    private func tiles(url: String) -> [String: MozAdsTile] {
        return ["newtab_mobile_tile_1": createAdTile(name: "newtab_mobile_tile_1", url: url)]
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
