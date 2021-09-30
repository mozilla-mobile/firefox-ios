/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// For any work that needs to be delayed, you can wrap it inside a throttler and specify the delay time, in seconds.
class Throttler {
    private var task: DispatchWorkItem = DispatchWorkItem(block: {})
    private var minimumDelay = 0.35

    init(seconds delay: Double? = nil) {
        self.minimumDelay = delay ?? minimumDelay
    }

    func throttle(completion: @escaping () -> Void) {
        let queue = DispatchQueue.main

        task.cancel()
        task = DispatchWorkItem { completion() }

        queue.asyncAfter(deadline: .now() + minimumDelay, execute: task)
    }
}
