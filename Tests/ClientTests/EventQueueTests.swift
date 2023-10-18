// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import Foundation
import Shared

enum TestEvent: AppEventType {
    case startingEvent
    case middleEvent
    case laterEvent

    case contextualEvent(Int)
}

final class EventQueueTests: XCTestCase {
    var queue: EventQueue<TestEvent>!

    override func setUp() {
        super.setUp()
        self.queue = EventQueue()
    }

    func testBasicEventFiredCheck() {
        XCTAssertFalse(queue.hasSignalled(.startingEvent))
        queue.signal(event: .startingEvent)
        XCTAssertTrue(queue.hasSignalled(.startingEvent))
    }

    func testBasicSingleEventActionIsFired() {
        let expectation = self.expectation(description: "Event queue test")

        XCTAssertFalse(queue.hasSignalled(.startingEvent))
        queue.wait(for: .startingEvent) {
            expectation.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.queue.signal(event: .startingEvent)
        }

        waitForExpectations(timeout: 1)
    }

    func testBasicActionIsNeverFiredIfNoEvent() {
        XCTAssertFalse(queue.hasSignalled(.startingEvent))
        var actionRun = false
        queue.wait(for: .startingEvent) {
            actionRun = true
        }
        wait(2.0)
        XCTAssertFalse(actionRun)
    }

    func testMultiEventActionIsFired() {
        let expectation = self.expectation(description: "Event queue test")

        queue.wait(for: [.startingEvent, .middleEvent]) {
            expectation.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.queue.signal(event: .startingEvent)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.queue.signal(event: .middleEvent)
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testMultiEventActionNotFiredIfOnlyOneEventOccurs() {
        var actionRun = false
        queue.wait(for: [.startingEvent, .middleEvent]) {
            actionRun = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.queue.signal(event: .startingEvent)
        }

        wait(2.0)
 
        XCTAssertFalse(actionRun)
    }

    func testEventWithAssociatedValue() {
        var action1Run = false
        var action2Run = false

        queue.wait(for: .contextualEvent(1)) {
            action1Run = true
        }

        queue.wait(for: .contextualEvent(2)) {
            action2Run = true
        }

        queue.signal(event: .contextualEvent(1))
        wait(2)
        XCTAssertTrue(action1Run)
        XCTAssertFalse(action2Run)
    }

    func testActionsAlwaysRunOnMainThread() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.queue.wait(for: .startingEvent) {
                // Currently we always expect actions to be called on main thread
                XCTAssert(Thread.isMainThread)
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.queue.signal(event: .startingEvent)
        }
        wait(1)
    }
}
