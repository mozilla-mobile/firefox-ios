// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// The default app-wide queue for Firefox iOS.
public let AppEventQueue = EventQueue<AppEvent>()

/// Action taken when an event's dependencies are completed.
typealias EventQueueAction = (() -> Void)
/// Unique ID associated with an enqueued action.
typealias ActionToken = UUID

/// The state of an event. Typical one-shot events are placed into the .completed
/// state once they have occurred. Activities which represent recurring tasks may
/// be placed in one of the states below depending on their status.
///
/// (Note: there is an additional implicit state, "not started", which is indicated
/// by the event being absent from the event queue altogether.)
public enum QueueEventState: Int {
    case inProgress
    case completed
    case failed
}

/// A queue that provides synchronization between different areas of the codebase and coordinates
/// actions that depend on one or more events or app states. For example events see: AppEvent.swift.
public final class EventQueue<QueueEventType: Hashable> {
    public struct EnqueuedAction {
        let token: ActionToken
        let action: EventQueueAction
        let dependencies: [QueueEventType]
    }

    // MARK: - Properties

    private var actions: [EnqueuedAction] = []
    private var signalledEvents: [QueueEventType: QueueEventState] = [:]
    private let logger: Logger
    private let mainQueue: DispatchQueueInterface
    private var isProcessingActions = false

    // MARK: - Initializer

    init(logger: Logger = DefaultLogger.shared,
         mainQueue: DispatchQueueInterface = DispatchQueue.main) {
        self.logger = logger
        self.mainQueue = mainQueue
    }

    // MARK: - Public API

    /// Queues a particular action for execution once the required events or activities
    /// have completed. If the dependencies have already been completed, the action is
    /// executed immediately. An optional ActionToken may be provided explicitly for a
    /// particular action; if so, any subsequent calls to this function will _not_ enqueue
    /// that action again if it is already pending execution. This provides a convenience
    /// for de-duplicating calls that might accidentally enqueue the same action twice.
    /// 
    /// - Parameters:
    ///   - events: the dependent events.
    ///   - token: an optional UUID that identifies the specific work being enqueued. If
    ///   this is provided, it will be used as the token to identify the enqueued work.
    ///   Callers may wish to provide this directly in order to allow for automatic
    ///   deduplication, for example in scenarios where the same function may be called
    ///   multiple times but you only want the action to be enqueued a single time.
    ///   - action: the action or work to perform. Called on main thread by default.
    /// - Returns: a token that can be used to cancel the action.
    ///
    /// Notes: the token return value may not be immediately usable if this
    /// function is called off of the main thread (since the actual action may not be
    /// enqueued until the subsequent main thread run loop has a chance to execute). It
    /// also will have no usefulness if all dependencies are already satisfied, in which
    /// case the action will be immediately run before the function returns.
    @discardableResult
    func wait(for events: [QueueEventType],
              token: ActionToken = ActionToken(),
              then action: @escaping EventQueueAction) -> ActionToken {
        mainQueue.ensureMainThread { [weak self] in
            guard let self else { return }

            // If a specific ID has been provided for this action, ensure
            guard !actions.contains(where: { $0.token == token }) else {
                logger.log("Ignoring duplicate action (ID: \(token))", level: .info, category: .library)
                return
            }

            let enqueued = EnqueuedAction(token: token, action: action, dependencies: events)
            self.processActions(incomingActions: [enqueued])
        }
        return token
    }

    /// Shorthand for waiting on a single event. Convenience.
    @discardableResult
    func wait(for event: QueueEventType, then action: @escaping EventQueueAction) -> ActionToken {
        return wait(for: [event], token: ActionToken(), then: action)
    }

    /// Signals that a specific one-shot event has occurred. These types of events are states
    /// that only ever occur once and do not repeat. An example might be the Profile initializing
    /// its DB connection etc. Signalling the same event more than once is currently a usage error.
    func signal(event: QueueEventType) {
        mainQueue.ensureMainThread { [weak self] in
            guard let self else { return }
            guard self.signalledEvents[event] != .completed else {
                logger.log("Signalling duplicate event: \(event)", level: .warning, category: .library)
                return
            }
            self.signalledEvents[event] = .completed
            self.processActions(for: event)
        }
    }

    /// Signals that an activity has been started. This transitions the event
    /// into the In Progress state.
    func started(_ event: QueueEventType) {
        mainQueue.ensureMainThread { [weak self] in
            guard let self else { return }
            let currentState = self.signalledEvents[event]
            guard currentState != .inProgress else {
                logger.log("Started \(event) which is already in progress.", level: .warning, category: .library)
                return
            }

            self.signalledEvents[event] = .inProgress
        }
    }
    /// Signals an activity event as having completed successfully.
    /// Dependent actions will be executed (if all other dependencies
    /// are satisfied).
    func completed(_ event: QueueEventType, error: Error? = nil) {
        mainQueue.ensureMainThread { [weak self] in
            guard let self else { return }
            let currentState = self.signalledEvents[event]
            if currentState != .inProgress {
                logger.log("Completing activity \(event) that is not in progress.", level: .warning, category: .library)
                // Warn for this, but no early return; allow event to be updated to .completed as requested.
            }

            self.signalledEvents[event] = .completed
            self.processActions(for: event)
        }
    }

    /// Signals an activity event as having failed (completed with an error).
    /// Dependent actions will not be executed.
    func failed(_ event: QueueEventType) {
        mainQueue.ensureMainThread { [weak self] in
            self?.signalledEvents[event] = .failed
        }
    }

    /// Used to check whether a particular event has occurred.
    /// - Returns: true if the event has occurred.
    func hasSignalled(_ argEvent: QueueEventType) -> Bool {
        return event(argEvent, isInState: .completed)
    }

    /// Used to check whether a particular activity is in progress.
    /// - Returns: true if the event is in progress.
    func activityIsInProgress(_ argEvent: QueueEventType) -> Bool {
        return event(argEvent, isInState: .inProgress)
    }

    /// Used to check whether a particular activity failed.
    /// - Returns: true if the event failed.
    func activityIsFailed(_ argEvent: QueueEventType) -> Bool {
        return event(argEvent, isInState: .failed)
    }

    /// Used to check whether a particular activity has not yet started.
    /// - Returns: true if the event hasn't started.
    func activityIsNotStarted(_ argEvent: QueueEventType) -> Bool {
        assert(Thread.isMainThread, "Expects to be called on the main thread.")
        return signalledEvents[argEvent] == nil
    }

    /// Used to check whether a particular activity has completed.
    /// This is effectively equivalent to `hasSignalled` since completed
    /// activities share the same state as a signalled event (.completed).
    /// - Returns: true if the activity has completed.
    func activityIsCompleted(_ event: QueueEventType) -> Bool {
        return hasSignalled(event)
    }

    /// This function will automatically signal the parent event when all required sub-dependencies are
    /// completed. This is simply a convenience for working with hierarchical or nested events.
    ///
    /// Example: our startup flow consists of multiple separate steps. All of these together are then part of
    /// a parent event, .startupFlowComplete. Interested listeners can either depend on one or more individual
    /// steps or they can listen for the parent event .startupFlowComplete. This allows relationships to be
    /// easily created between different events.
    func establishDependencies(for parentEvent: QueueEventType, against otherEvents: [QueueEventType]) {
        wait(for: otherEvents, token: ActionToken()) { [weak self] in
            self?.signal(event: parentEvent)
        }
    }

    /// Used to cancel an enqueued action using the token that was provided when the action was enqueued.
    /// - Returns: true if the action was canceled.
    ///
    /// Note: if the token is invalid or the action has already been executed (or not yet enqueued) then
    /// this function has no effect.
    @discardableResult
    func cancelAction(token: ActionToken) -> Bool {
        assert(Thread.isMainThread, "Expects to be called on the main thread.")
        guard let idx = actions.firstIndex(where: { $0.token == token }) else { return false }
        actions.remove(at: idx)
        return true
    }

    // MARK: - Internal Utility

    private func event(_ event: QueueEventType, isInState state: QueueEventState) -> Bool {
        assert(Thread.isMainThread, "Expects to be called on the main thread.")
        return signalledEvents[event] == state
    }

    private func processActions(for event: QueueEventType? = nil,
                                incomingActions: [EnqueuedAction] = []) {
        assert(Thread.isMainThread, "Expects to be called on the main thread.")
        if isProcessingActions {
            // processActions() does not support reentrancy. If this gets called
            // recursively, defer next call to the subequent iteration of the MT
            // run loop. This fixes some edge case bugs with nested dependencies
            // which can potentially cause actions to be executed twice incorrectly.
            mainQueue.async { [weak self] in
                self?.actions.append(contentsOf: incomingActions)
                self?.processActions()
            }
            return
        } else {
            actions.append(contentsOf: incomingActions)
        }
        isProcessingActions = true
        defer { isProcessingActions = false }

        for enqueued in actions where allDependenciesSatisified(enqueued) {
            enqueued.action()
        }
        actions = actions.filter { !allDependenciesSatisified($0) }
    }

    private func allDependenciesSatisified(_ action: EnqueuedAction) -> Bool {
        let events = action.dependencies
        guard !events.isEmpty else { return true }
        if events.contains(where: { signalledEvents[$0] != .completed }) {
            return false
        }
        return true
    }
}
