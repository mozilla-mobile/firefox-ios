// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

typealias EventQueueAction = (() -> Void)
typealias ActionToken = UUID

let DefaultEventQueue = EventQueue<AppEvent>()

final class EventQueue<QueueEventType: Hashable> {
    struct EnqueuedAction {
        let token: ActionToken
        let action: EventQueueAction
        let dependencies: [QueueEventType]
    }

    // MARK: - Properties

    private var actions: [EnqueuedAction] = []
    private var signalledEvents = Set<QueueEventType>()
    private let logger: Logger
    private let mainQueue: DispatchQueueInterface

    // MARK: - Initializer

    init(logger: Logger = DefaultLogger.shared,
         mainQueue: DispatchQueueInterface = DispatchQueue.main) {
        self.logger = logger
        self.mainQueue = mainQueue
    }

    /// Signals that a specific event has occurred. Currently signalling the same
    /// event more than once is considered a usage error.
    func signal(event: QueueEventType) {
        mainQueue.ensureMainThread { [weak self] in
            guard let self else { return }
            guard !self.signalledEvents.contains(event) else {
                logger.log("Signalling duplicate event: \(event)", level: .warning, category: .library)
                return
            }
            self.signalledEvents.insert(event)
            self.processActions(for: event)
        }
    }

    /// Queues a particular action for execution once the provided events have all
    /// been signaled. If the events have already all occurred, the block is executed
    /// immediately.
    /// - Parameters:
    ///   - events: the dependent events.
    ///   - action: the action or work to perform. Called on main thread by default.
    /// - Returns: a token that can be used to cancel the action.
    ///
    /// Notes: the token return value may not be immediately usable if this
    /// function is called off of the main thread (since the actual action may not be
    /// enqueued until the subsequent main thread run loop has a chance to execute). It
    /// also will have no usefulness if all dependencies are already satisfied, in which
    /// case the action will be immediately run before the function returns.
    @discardableResult
    func wait(for events: [QueueEventType], then action: @escaping EventQueueAction) -> ActionToken {
        let token = ActionToken()
        mainQueue.ensureMainThread { [weak self] in
            guard let self else { return }
            let enqueued = EnqueuedAction(token: token, action: action, dependencies: events)
            self.actions.append(enqueued)
            self.processActions()
        }
        return token
    }

    /// Qeues a particular action for a single dependency.
    @discardableResult
    func wait(for event: QueueEventType, then action: @escaping EventQueueAction) -> ActionToken {
        return wait(for: [event], then: action)
    }

    /// Used to check whether a particular event has occurred.
    /// - Returns: true if the event has occurred.
    func hasSignalled(_ event: QueueEventType) -> Bool {
        assert(Thread.isMainThread, "Expects to be called on the main thread.")
        return signalledEvents.contains(event)
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

    private func processActions(for event: QueueEventType? = nil) {
        assert(Thread.isMainThread, "Expects to be called on the main thread.")

        for enqueued in actions where allDependenciesSatisified(enqueued) {
            enqueued.action()
        }
        actions = actions.filter { !allDependenciesSatisified($0) }
    }

    private func allDependenciesSatisified(_ action: EnqueuedAction) -> Bool {
        let events = action.dependencies
        guard !events.isEmpty else { return true }
        if events.contains(where: { signalledEvents.contains($0) == false }) {
            return false
        }
        return true
    }
}
