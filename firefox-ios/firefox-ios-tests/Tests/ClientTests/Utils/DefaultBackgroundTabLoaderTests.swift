// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import TestKit
import XCTest
@testable import Client

@MainActor
final class DefaultBackgroundTabLoaderTests: XCTestCase {
    private var applicationHelper: MockApplicationHelper!
    private var tabQueue: MockTabQueue!
    private var logger: MockLogger!

    override func setUp() async throws {
        try await super.setUp()
        self.applicationHelper = MockApplicationHelper()
        self.tabQueue = MockTabQueue()
        self.logger = MockLogger()
    }

    override func tearDown() async throws {
        self.applicationHelper = nil
        self.tabQueue = nil
        self.logger = nil
        try await super.tearDown()
    }

    func testLoadBackgroundTabs_noTabs_doesntLoad() {
        let subject = createSubject()

        subject.loadBackgroundTabs()

        let predicate = NSPredicate { _, _ in
            return self.tabQueue.getQueuedTabsCalled == 1
        }
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: .none)

        wait(for: [exp], timeout: 3.0)

        XCTAssertEqual(tabQueue.getQueuedTabsCalled, 1)
        XCTAssertEqual(applicationHelper.openURLCalled, 0)
    }

    func testLoadBackgroundTabs_withTabs_load() {
        let urlString = "https://www.mozilla.com"
        tabQueue.queuedTabs = [ShareItem(url: urlString, title: "Title 1"),
                               ShareItem(url: urlString, title: "Title 2"),
                               ShareItem(url: urlString, title: "Title 3")]
        let subject = createSubject()

        subject.loadBackgroundTabs()

        // `clearQueuedTabs` is the last step of the dequeue, so waiting on it
        // guarantees the urls have already been opened.
        let predicate = NSPredicate { _, _ in
            return self.tabQueue.clearQueuedTabsCalled == 1
        }
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: .none)

        wait(for: [exp], timeout: 3.0)

        XCTAssertEqual(tabQueue.getQueuedTabsCalled, 1)
        XCTAssertEqual(applicationHelper.openURLCalled, 3)
        XCTAssertEqual(tabQueue.clearQueuedTabsCalled, 1)
    }

    func testLoadBackgroundTabs_whenReadFails_doesntLoadOrClearQueue() {
        tabQueue.queuedTabs = [ShareItem(url: "https://www.mozilla.com", title: "Title 1")]
        tabQueue.getQueuedTabsError = TestQueueError.readFailed
        let subject = createSubject()

        subject.loadBackgroundTabs()

        // The logged warning is the last step of the failure path, so waiting on it
        // means the dequeue actually finished rather than merely started.
        let predicate = NSPredicate { _, _ in
            return self.logger.savedMessage != nil
        }
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: .none)

        wait(for: [exp], timeout: 3.0)

        XCTAssertEqual(logger.savedLevel, .warning)
        XCTAssertEqual(logger.savedCategory, .tabs)
        // A failed read must not open tabs, and must not drain the queue -
        // the tabs stay queued for the next attempt.
        XCTAssertEqual(applicationHelper.openURLCalled, 0)
        XCTAssertEqual(tabQueue.clearQueuedTabsCalled, 0)
    }

    // MARK: Helper functions

    func createSubject() -> DefaultBackgroundTabLoader {
        let subject = DefaultBackgroundTabLoader(tabQueue: tabQueue,
                                                 applicationHelper: applicationHelper,
                                                 logger: logger)
        trackForMemoryLeaks(subject)
        return subject
    }
}

private enum TestQueueError: Error {
    case readFailed
}
