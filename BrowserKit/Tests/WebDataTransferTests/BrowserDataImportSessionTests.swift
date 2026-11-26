// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebDataTransfer

final class BrowserDataImportSessionTests: XCTestCase {
    private struct StreamError: Error {}

    func testRun_mixedRecords_succeedsAndReportsAPICompletionOnce() async throws {
        let completions = APICompletionCounter()
        let session = BrowserDataImportSession(onAPICompletion: completions.record)

        let result = try await run(stream([
            item("Safari", .unsupported),
            item("Safari", .unsupported),
            item(nil, .unsupported)
        ]), session: session)

        XCTAssertTrue(result.apiCompleted)
        XCTAssertEqual(result.outcome, .success)
        XCTAssertEqual(result.recordCount, 0)
        XCTAssertEqual(result.sourceBrowserName, "Safari")
        XCTAssertEqual(completions.count, 1)
    }

    func testRun_emptyStream_succeeds() async throws {
        let result = try await run(stream([]))

        XCTAssertTrue(result.apiCompleted)
        XCTAssertEqual(result.outcome, .success)
        XCTAssertNil(result.sourceBrowserName)
    }

    func testRun_noSourceName_isNil() async throws {
        let result = try await run(stream([
            item(nil, .unsupported),
            item("  ", .unsupported)
        ]))

        XCTAssertNil(result.sourceBrowserName)
    }

    func testRun_sourceName_ignoresMissingAndBlankNames() async throws {
        let result = try await run(stream([
            item(nil, .unsupported),
            item("  ", .unsupported),
            item(" Chrome\n", .unsupported)
        ]))

        XCTAssertEqual(result.sourceBrowserName, "Chrome")
    }

    func testRun_differentSourceNames_isNil() async throws {
        let result = try await run(stream([
            item("Chrome", .unsupported),
            item(nil, .unsupported),
            item("Safari", .unsupported)
        ]))

        XCTAssertNil(result.sourceBrowserName)
        XCTAssertEqual(result.outcome, .success)
    }

    func testRun_sameSourceNameWithSurroundingWhitespace_isKept() async throws {
        let result = try await run(stream([
            item("Chrome", .unsupported),
            item(" Chrome ", .unsupported)
        ]))

        XCTAssertEqual(result.sourceBrowserName, "Chrome")
    }

    func testRun_errorBeforeAnyRecord_failsWithoutAPICompletion() async throws {
        let completions = APICompletionCounter()

        let result = try await run(
            stream([], error: StreamError()),
            session: BrowserDataImportSession(onAPICompletion: completions.record)
        )

        XCTAssertFalse(result.apiCompleted)
        XCTAssertEqual(result.outcome, .failure(.unknown))
        XCTAssertEqual(completions.count, 0)
    }

    func testRun_errorAfterRecords_usesGenericReason() async throws {
        let result = try await run(stream([item("Safari", .unsupported)], error: StreamError()))

        XCTAssertFalse(result.apiCompleted)
        XCTAssertEqual(result.outcome, .failure(.unknown))
        XCTAssertEqual(result.sourceBrowserName, "Safari")
    }

    func testRun_cancellationError_hasNoResult() async {
        let result = await BrowserDataImportSession().run(stream([item(nil, .unsupported)], error: CancellationError()))

        XCTAssertNil(result)
    }

    func testRun_cancelledTask_hasNoResultOrAPICompletion() async {
        let completions = APICompletionCounter()
        let (records, continuation) = AsyncThrowingStream<BrowserDataImportItem, Error>.makeStream()
        let task = Task {
            await BrowserDataImportSession(onAPICompletion: completions.record).run(records)
        }
        continuation.yield(item("Safari", .unsupported))
        task.cancel()

        let result = await task.value

        XCTAssertNil(result)
        XCTAssertEqual(completions.count, 0)
    }

    // MARK: - Helpers

    private func item(_ name: String?, _ payload: BrowserDataImportItem.Payload) -> BrowserDataImportItem {
        return BrowserDataImportItem(sourceBrowserName: name, payload: payload)
    }

    private func stream(
        _ items: [BrowserDataImportItem],
        error: Error? = nil
    ) -> AsyncThrowingStream<BrowserDataImportItem, Error> {
        return AsyncThrowingStream { continuation in
            items.forEach { continuation.yield($0) }
            continuation.finish(throwing: error)
        }
    }

    private func run(
        _ records: AsyncThrowingStream<BrowserDataImportItem, Error>,
        session: BrowserDataImportSession = BrowserDataImportSession()
    ) async throws -> BrowserTransferResult {
        let result = await session.run(records)
        return try XCTUnwrap(result)
    }
}

final class APICompletionCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    var count: Int {
        lock.withLock { value }
    }

    var record: @Sendable () -> Void {
        return { [self] in lock.withLock { value += 1 } }
    }
}
