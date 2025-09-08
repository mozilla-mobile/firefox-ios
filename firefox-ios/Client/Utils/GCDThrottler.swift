// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol ThrottleProtocol {
    func throttle(completion: @escaping @Sendable () -> Void)
}

/// For any work that needs to be delayed, you can wrap it inside a throttler
/// and specify the delay time, in seconds, and queue.
class GCDThrottler: ThrottleProtocol {
    private let defaultDelay = 0.35

    private let threshold: Double
    private var queue: DispatchQueueInterface
    private var lastExecutionTime = Date.distantPast

    init(seconds delay: Double? = nil,
         on queue: DispatchQueueInterface = DispatchQueue.main) {
        self.threshold = delay ?? defaultDelay
        self.queue = queue
    }

    // This debounces; the task will not happen unless a duration of delay passes since the function was called
    func throttle(completion: @escaping @Sendable () -> Void) {
        guard threshold <= 0 || lastExecutionTime.timeIntervalSinceNow < -threshold else { return }
        lastExecutionTime = Date()
        queue.async(execute: completion)
    }
}
