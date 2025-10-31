// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class ImpressionTrackerTests: XCTestCase {
    private var subject: ImpressionTrackingUtility!

    override func setUp() {
        super.setUp()
        subject = ImpressionTrackingUtility()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Helpers
    private struct SendCapture {
        var calls = 0
        var payloads: [[IndexPath]] = []

        mutating func record(_ ips: [IndexPath]) {
            calls += 1

            payloads.append(ips)
            print(payloads)
        }
    }

    private func makeIP(_ item: Int, _ section: Int = 0) -> IndexPath {
        IndexPath(item: item, section: section)
    }

    private func asSet(_ ips: [IndexPath]) -> Set<IndexPath> {
        Set(ips)
    }

    // MARK: - Tests
    func testFlushWhenEmpty_DoesNotSend() {
        var validator = SendCapture()
        subject.flush { validator.record($0) }
        XCTAssertEqual(validator.calls, 0)
        XCTAssertTrue(validator.payloads.isEmpty)
    }

    func testSinglePending_GetsSentOnce() {
        var validator = SendCapture()
        let ip = makeIP(0)
        subject.markPending(ip)

        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 1)
        XCTAssertEqual(asSet(validator.payloads[0]), [ip])
    }

    func testMultiplePending_SendsAllInOneBatch() {
        var validator = SendCapture()
        let a = makeIP(0), b = makeIP(1), c = makeIP(2)
        [a, b, c].forEach(subject.markPending)

        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 1)
        XCTAssertEqual(asSet(validator.payloads[0]), [a, b, c])
    }

    func testDuplicateMarks_AreDeDuplicated() {
        var validator = SendCapture()
        let ip = makeIP(3)
        subject.markPending(ip)
        subject.markPending(ip)
        subject.markPending(ip)

        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 1)
        XCTAssertEqual(asSet(validator.payloads[0]), [ip])
    }

    func testAlreadySent_NotResentOnNextFlush() {
        var validator = SendCapture()
        let ip = makeIP(1)
        subject.markPending(ip)
        subject.flush { validator.record($0) }

        subject.markPending(ip)
        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 1)
        XCTAssertEqual(validator.payloads.count, 1)
        XCTAssertEqual(asSet(validator.payloads[0]), [ip])
    }

    func testPendingClearsOnFlush_EvenWhenNoNewItems() {
        var validator = SendCapture()
        let ip = makeIP(2)

        subject.markPending(ip)
        subject.flush { validator.record($0) }
        XCTAssertEqual(validator.calls, 1)

        subject.markPending(ip)
        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 1)
        XCTAssertEqual(validator.payloads.count, 1)
    }

    func testReset_AllowsResend() {
        var validator = SendCapture()
        let ip = makeIP(4)

        subject.markPending(ip)
        subject.flush { validator.record($0) }
        XCTAssertEqual(validator.calls, 1)

        subject.reset()

        subject.markPending(ip)
        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 2)
        XCTAssertEqual(asSet(validator.payloads.last ?? []), [ip], "After reset, item should be sendable again.")
    }

    func testSectionsMatter_IndexPathEqualityBySectionAndItem() {
        var validator = SendCapture()
        let itemOne = makeIP(0, 0)
        let sameAsItemOneButDifferentSection = makeIP(0, 1)

        subject.markPending(itemOne)
        subject.markPending(sameAsItemOneButDifferentSection)
        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 1)
        XCTAssertEqual(
            asSet(validator.payloads[0]),
            [itemOne, sameAsItemOneButDifferentSection],
            "Different sections must be treated as distinct."
        )
    }

    func testInterleavedFlushes_SendsOnlyNewItemsEachTime() {
        var validator = SendCapture()
        let a = makeIP(0), b = makeIP(1), c = makeIP(2)

        subject.markPending(a)
        subject.flush { validator.record($0) }

        subject.markPending(a)
        subject.markPending(b)
        subject.flush { validator.record($0) }

        subject.markPending(c)
        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 3)
        XCTAssertEqual(asSet(validator.payloads[0]), [a])
        XCTAssertEqual(asSet(validator.payloads[1]), [b])
        XCTAssertEqual(asSet(validator.payloads[2]), [c])
    }

    func testNoLeakBetweenBatches_PendingIsIsolated() {
        var validator = SendCapture()
        let a = makeIP(10), b = makeIP(11)

        subject.markPending(a)
        subject.flush { validator.record($0) }

        // Ensure previous pending doesn't "stick" and reappear.
        subject.flush { validator.record($0) }

        subject.markPending(b)
        subject.flush { validator.record($0) }

        XCTAssertEqual(validator.calls, 2)
        XCTAssertEqual(asSet(validator.payloads[0]), [a])
        XCTAssertEqual(asSet(validator.payloads[1]), [b])
    }
}
