// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// For any work that needs to be delayed, you can wrap it inside a throttler and specify the delay time, in seconds, and queue.
class Throttler {
    private var task = DispatchWorkItem(block: {})
    private let defaultDelay = 0.35

    private let delay: Double
    private var queue: DispatchQueueInterface

    init(seconds delay: Double? = nil,
         on queue: DispatchQueueInterface = DispatchQueue.main) {
        self.delay = delay ?? defaultDelay
        self.queue = queue
    }

    // This debounces; the task will not happen unless a duration of delay passes since the function was called
    func throttle(completion: @escaping () -> Void) {
        task.cancel()
        task = DispatchWorkItem { completion() }

        queue.asyncAfter(deadline: .now() + delay, execute: task)
    }
}
