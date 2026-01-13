// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol MainThreadThrottlerProtocol {
    func throttle(completion: @escaping @MainActor () -> Void)
}

/// For any work that needs to be delayed, you can wrap it inside a throttler
/// and specify the delay time, in seconds, and queue.
class MainThreadThrottler: MainThreadThrottlerProtocol {
    private let defaultDelay = 0.35

    private let threshold: Double
    private var lastExecutionTime = Date.distantPast

    init(seconds delay: Double? = nil) {
        self.threshold = delay ?? defaultDelay
    }

    // This debounces; the task will not happen unless a duration of delay passes since the function was called
    func throttle(completion: @escaping @MainActor () -> Void) {
        guard threshold <= 0 || lastExecutionTime.timeIntervalSinceNow < -threshold else { return }
        lastExecutionTime = Date()
        DispatchQueue.main.async(execute: completion)
    }
}
