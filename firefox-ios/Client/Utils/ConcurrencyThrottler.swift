// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Foundation

protocol ConcurrencyThrottlerProtocol {
    @MainActor
    func throttle(completion: @escaping @Sendable () async -> Void)
}

final class ConcurrencyThrottler: ConcurrencyThrottlerProtocol {
    private var lastUpdateTime = Date.distantPast
    private var delay: Double
    private var taskComplete = true

    init(seconds delay: Double = 0.35) {
        self.delay = delay
    }

    func throttle(completion: @escaping @Sendable () async -> Void) {
        let currentTime = Date()

        guard taskComplete && (lastUpdateTime.timeIntervalSinceNow < -delay) else { return }
        taskComplete = false

        Task {
            await completion()
            lastUpdateTime = currentTime
            taskComplete = true
        }
    }
}
