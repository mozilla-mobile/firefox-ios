// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

typealias EventQueueAction = (() -> Void)

let DefaultEventQueue = EventQueue<AppEvent>()

final class EventQueue<QueueEventType: Hashable> {
    struct EnqueuedAction {
        let action: EventQueueAction
        let dependencies: [QueueEventType]
    }

    // MARK: - Properties

    private var actions: [EnqueuedAction] = []
    private var signalledEvents = Set<QueueEventType>()
    private let logger: Logger

    // MARK: - Initializer

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    /// Signals that a specific event has occurred. Currently signalling the same
    /// event more than once is considered a usage error.
    func signal(event: QueueEventType) {
        ensureMainThread { [weak self] in
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
    ///   - action: the action or work to perform. Currently by default these will
    ///   always be called on the main thread.
    func wait(for events: [QueueEventType], then action: @escaping EventQueueAction) {
        ensureMainThread { [weak self] in
            guard let self else { return }
            let enqueued = EnqueuedAction(action: action, dependencies: Array(events))
            self.actions.append(enqueued)
            self.processActions()
        }
    }

    /// Qeues a particular action for a single dependency.
    func wait(for event: QueueEventType, then action: @escaping EventQueueAction) {
        wait(for: [event], then: action)
    }

    /// Used to check whether a particular event has occurred.
    /// - Returns: true if the event has occurred.
    func hasSignalled(_ event: QueueEventType) -> Bool {
        return signalledEvents.contains(event)
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
        if events.contains(where: { signalledEvents.contains($0) }) {
            return false
        }
        return true
    }
}
