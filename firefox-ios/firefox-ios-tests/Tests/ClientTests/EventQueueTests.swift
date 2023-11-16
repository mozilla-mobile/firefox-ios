// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import Foundation
import Shared
import Common

enum TestEvent: AppEventType {
    // Standard test events
    case startingEvent
    case middleEvent
    case laterEvent

    // Activity test event
    case activityEvent

    // Nested (parent/hierarchical) test event
    case parentEvent

    // Contextual (associated value) test event
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

    func testEventState_hasSignalled() {
        XCTAssertFalse(queue.hasSignalled(.startingEvent))
        queue.signal(event: .startingEvent)
        XCTAssertTrue(queue.hasSignalled(.startingEvent))
    }

    func testEventState_isCompleted() {
        XCTAssertFalse(queue.activityIsCompleted(.activityEvent))
        queue.started(.activityEvent)
        XCTAssertFalse(queue.activityIsCompleted(.activityEvent))
        queue.completed(.activityEvent)
        XCTAssertTrue(queue.activityIsCompleted(.activityEvent))
    }

    func testEventState_inProgress() {
        XCTAssertFalse(queue.activityIsInProgress(.activityEvent))
        queue.started(.activityEvent)
        XCTAssertTrue(queue.activityIsInProgress(.activityEvent))
        queue.completed(.activityEvent)
        XCTAssertFalse(queue.activityIsInProgress(.activityEvent))
    }

    func testEventState_isFailed() {
        XCTAssertFalse(queue.activityIsFailed(.activityEvent))
        queue.started(.activityEvent)
        XCTAssertFalse(queue.activityIsFailed(.activityEvent))
        queue.failed(.activityEvent)
        XCTAssertTrue(queue.activityIsFailed(.activityEvent))
    }

    func testEventState_isNotStarted() {
        XCTAssertTrue(queue.activityIsNotStarted(.activityEvent))
        queue.started(.activityEvent)
        XCTAssertFalse(queue.activityIsNotStarted(.activityEvent))
        queue.completed(.activityEvent)
        XCTAssertFalse(queue.activityIsNotStarted(.activityEvent))
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

    func testNestedDependencies() {
        // Enqueue action
        queue.wait(for: [.parentEvent, .activityEvent], then: {  })
        XCTAssertFalse(queue.hasSignalled(.parentEvent))

        // Create a parent event that depends on 3 sub-events
        queue.establishDependencies(for: .parentEvent, against: [
            .startingEvent,
            .middleEvent,
            .laterEvent
        ])

        // Start and finish activity event
        queue.started(.activityEvent)
        queue.completed(.activityEvent)
        // Action should not yet run
        XCTAssertFalse(queue.hasSignalled(.parentEvent))

        // Complete 2 of 3 sub-events of parent
        queue.signal(event: .startingEvent)
        queue.signal(event: .middleEvent)
        // Action not run
        XCTAssertFalse(queue.hasSignalled(.parentEvent))

        // Complete 3rd sub-event of parent
        queue.signal(event: .laterEvent)
        // At this point all dependencies should be complete.
        XCTAssertTrue(queue.hasSignalled(.parentEvent))
    }
}
