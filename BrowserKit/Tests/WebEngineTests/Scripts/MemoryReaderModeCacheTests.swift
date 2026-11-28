// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class MemoryReaderModeCacheTests: XCTestCase {
    private let url = URL(string: "https://example.com/article")!

    func testGet_withoutFallback_throwsWhenNothingStored() {
        let subject = MemoryReaderModeCache()

        XCTAssertThrowsError(try subject.get(url))
        XCTAssertFalse(subject.contains(url))
    }

    func testGet_afterPut_returnsStoredResult() throws {
        let subject = MemoryReaderModeCache()

        try subject.put(url, makeResult(title: "In memory"))

        XCTAssertEqual(try subject.get(url).title, "In memory")
        XCTAssertTrue(subject.contains(url))
    }

    func testGet_whenMissInMemory_returnsFallbackResult() throws {
        let fallback = FallbackReaderModeCacheStub()
        fallback.stored[url] = makeResult(title: "On disk")
        let subject = MemoryReaderModeCache(fallback: fallback)

        XCTAssertEqual(try subject.get(url).title, "On disk")
    }

    func testGet_whenInMemoryAndFallback_prefersMemory() throws {
        let fallback = FallbackReaderModeCacheStub()
        fallback.stored[url] = makeResult(title: "On disk")
        let subject = MemoryReaderModeCache(fallback: fallback)

        try subject.put(url, makeResult(title: "In memory"))

        XCTAssertEqual(try subject.get(url).title, "In memory")
    }

    func testGet_whenMissInMemoryAndFallback_throws() {
        let subject = MemoryReaderModeCache(fallback: FallbackReaderModeCacheStub())

        XCTAssertThrowsError(try subject.get(url))
    }

    func testContains_whenOnlyInFallback_returnsTrue() {
        let fallback = FallbackReaderModeCacheStub()
        fallback.stored[url] = makeResult(title: "On disk")
        let subject = MemoryReaderModeCache(fallback: fallback)

        XCTAssertTrue(subject.contains(url))
    }

    func testPut_neverWritesToFallback() throws {
        let fallback = FallbackReaderModeCacheStub()
        let subject = MemoryReaderModeCache(fallback: fallback)

        try subject.put(url, makeResult(title: "Private"))

        XCTAssertEqual(fallback.putCallCount, 0)
        XCTAssertTrue(fallback.stored.isEmpty)
    }

    func testDelete_neverDeletesFromFallback() {
        let fallback = FallbackReaderModeCacheStub()
        fallback.stored[url] = makeResult(title: "On disk")
        let subject = MemoryReaderModeCache(fallback: fallback)

        subject.delete(url, error: nil)

        XCTAssertEqual(fallback.deleteCallCount, 0)
        XCTAssertNotNil(fallback.stored[url])
    }

    func testClear_neverClearsFallback() {
        let fallback = FallbackReaderModeCacheStub()
        fallback.stored[url] = makeResult(title: "On disk")
        let subject = MemoryReaderModeCache(fallback: fallback)

        subject.clear()

        XCTAssertEqual(fallback.clearCallCount, 0)
        XCTAssertNotNil(fallback.stored[url])
    }

    private func makeResult(title: String) -> ReadabilityResult {
        let object: NSDictionary = ["content": "<p>Body</p>", "title": title, "byline": "Author"]
        return ReadabilityResult(object: object)!
    }
}

private final class FallbackReaderModeCacheStub: ReaderModeCache, @unchecked Sendable {
    var stored = [URL: ReadabilityResult]()
    private(set) var putCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var clearCallCount = 0

    func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws {
        putCallCount += 1
        stored[url] = readabilityResult
    }

    func get(_ url: URL) throws -> ReadabilityResult {
        guard let result = stored[url] else {
            throw NSError(domain: "FallbackReaderModeCacheStub", code: 0)
        }
        return result
    }

    func delete(_ url: URL, error: NSErrorPointer) {
        deleteCallCount += 1
        stored[url] = nil
    }

    func contains(_ url: URL) -> Bool {
        return stored[url] != nil
    }

    func clear() {
        clearCallCount += 1
        stored.removeAll()
    }
}
