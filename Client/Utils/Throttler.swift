// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

/// For any work that needs to be delayed, you can wrap it inside a throttler and specify the delay time, in seconds, and queue.
class Throttler {
    private var task: DispatchWorkItem = DispatchWorkItem(block: {})
    private var minimumDelay = 0.35
    private var queueType: DispatchQueue = .main

    init(seconds delay: Double? = nil, on queue: DispatchQueue?) {
        self.minimumDelay = delay ?? minimumDelay
        self.queueType = queue ?? queueType
    }

    func throttle(completion: @escaping () -> Void) {
        task.cancel()
        task = DispatchWorkItem { completion() }

        queueType.asyncAfter(deadline: .now() + minimumDelay, execute: task)
    }
}
