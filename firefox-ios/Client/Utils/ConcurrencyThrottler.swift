// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Foundation

class ConcurrencyThrottler: ThrottleProtocol {
    private var lastUpdateTime = Date.distantPast
    private var delay: Double

    init(
        seconds delay: Double = 0.35
    ) {
        self.delay = delay
    }

    func throttle(completion: @escaping () -> Void) {
        let currentTime = Date()

        guard lastUpdateTime.timeIntervalSinceNow < -delay else { return }
        lastUpdateTime = currentTime

        Task {
            await MainActor.run {
                completion()
            }
        }
    }
}
