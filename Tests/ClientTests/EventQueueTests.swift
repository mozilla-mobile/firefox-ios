// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import Foundation
import Shared
import Common

enum TestEvent: AppEventType {
    case startingEvent
    case middleEvent
    case laterEvent

    case activityEvent

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
        var actionRun = false

        XCTAssertFalse(queue.hasSignalled(.startingEvent))

        queue.wait(for: .startingEvent) { actionRun = true }
        self.queue.signal(event: .startingEvent)

        XCTAssertTrue(actionRun)
    }

    func testBasicActionIsNeverFiredIfNoEvent() {
        XCTAssertFalse(queue.hasSignalled(.startingEvent))
        var actionRun = false
        queue.wait(for: .startingEvent) { actionRun = true }
        // Signal an event, but not the one our action is dependent on
        queue.signal(event: .middleEvent)
        XCTAssertFalse(actionRun)
    }

    func testMultiEventActionIsFired() {
        var actionRun = false

        queue.wait(for: [.startingEvent, .middleEvent]) { actionRun = true }
        XCTAssertFalse(actionRun)

        self.queue.signal(event: .startingEvent)
        XCTAssertFalse(actionRun)

        self.queue.signal(event: .middleEvent)
        XCTAssertTrue(actionRun)
    }

    func testMultiEventActionNotFiredIfOnlyOneEventOccurs() {
        var actionRun = false
        queue.wait(for: [.startingEvent, .middleEvent]) {
            actionRun = true
        }

        self.queue.signal(event: .startingEvent)

        XCTAssertFalse(actionRun)
    }

    func testContextSpecificEventWithAssociatedValue() {
        var action1Run = false
        var action2Run = false

        queue.wait(for: .contextualEvent(1)) {
            action1Run = true
        }

        queue.wait(for: .contextualEvent(2)) {
            action2Run = true
        }

        queue.signal(event: .contextualEvent(1))

        XCTAssertTrue(action1Run)
        XCTAssertFalse(action2Run)
    }

    func testActionCancellation() {
        var actionRun = false
        XCTAssertFalse(queue.hasSignalled(.startingEvent))
        let token = queue.wait(for: .startingEvent, then: { actionRun = true })
        let wasCancelled = queue.cancelAction(token: token)
        queue.signal(event: .startingEvent)
        XCTAssertFalse(actionRun)
        XCTAssertTrue(wasCancelled)
    }

    func testActionCancellationFailed() {
        var actionRun = false
        XCTAssertFalse(queue.hasSignalled(.startingEvent))
        let token = queue.wait(for: .startingEvent, then: { actionRun = true })

        queue.signal(event: .startingEvent)

        let wasCancelled = queue.cancelAction(token: token)

        XCTAssertTrue(actionRun)
        XCTAssertFalse(wasCancelled)
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

    func testActivityEventStateChanges() {
        var actionRun = false

        XCTAssertTrue(queue.activityIsNotStarted(.startingEvent))
        queue.wait(for: .activityEvent) { actionRun = true }

        // Start event
        self.queue.started(.activityEvent)
        XCTAssertFalse(actionRun)
        XCTAssertTrue(queue.activityIsInProgress(.activityEvent))

        // Complete event
        self.queue.completed(.activityEvent)
        XCTAssertTrue(actionRun)
        XCTAssertTrue(queue.activityIsCompleted(.activityEvent))
    }

    func testMultipleEventTypeDependencies() {
        var actionRun = false

        XCTAssertTrue(queue.activityIsNotStarted(.startingEvent))
        queue.wait(for: [.startingEvent, .activityEvent], then: { actionRun = true })

        queue.signal(event: .startingEvent)

        XCTAssertFalse(actionRun)
        queue.started(.activityEvent)

        XCTAssertFalse(actionRun)
        queue.completed(.activityEvent)

        XCTAssertTrue(actionRun)
        XCTAssertTrue(queue.activityIsCompleted(.activityEvent))
    }

    func testMultipleSequentialActivityEvents() {
        var actionRun = false

        // Enqueue and trigger 1st occurrence of activity event
        queue.wait(for: [.activityEvent], then: { actionRun = true })
        XCTAssertFalse(actionRun)
        queue.started(.activityEvent)
        XCTAssertFalse(actionRun)
        queue.completed(.activityEvent)
        // Expect action 1 run
        XCTAssertTrue(actionRun)

        // Trigger 2nd occurrence of activity event
        actionRun = false
        queue.started(.activityEvent)
        queue.completed(.activityEvent)
        // Expect action is not run a 2nd time (it should have been dequeued previously)
        XCTAssertFalse(actionRun)

        // Enqueue another action, since the event has already completed,
        // we expect the action to run immediately
        actionRun = false
        queue.wait(for: [.activityEvent], then: { actionRun = true })
        // Expect action 2 run immediately
        XCTAssertTrue(actionRun)

        // Enqueue another action, but this time trigger another occurrence
        // of the event _before_ the action is enqueued. It should wait
        // until the event finishes before running.
        actionRun = false
        queue.started(.activityEvent)
        queue.wait(for: [.activityEvent], then: { actionRun = true })
        XCTAssertFalse(actionRun)
        // Finish event
        queue.completed(.activityEvent)
        XCTAssertTrue(actionRun)
    }

    func testActivityDefaultStates() {
        XCTAssert(queue.activityIsNotStarted(.activityEvent))
        queue.started(.activityEvent)
        XCTAssertFalse(queue.activityIsNotStarted(.activityEvent))
    }

    func testFailedState() {
        var actionRun = false

        XCTAssertTrue(queue.activityIsNotStarted(.startingEvent))
        queue.wait(for: [.activityEvent], then: { actionRun = true })

        queue.started(.activityEvent)
        queue.failed(.activityEvent)
        XCTAssertFalse(queue.activityIsNotStarted(.activityEvent))
        XCTAssertFalse(actionRun)
    }
}
