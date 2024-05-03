/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class Debouncer {
    var completion: (() -> Void)?
    private let timeInterval: TimeInterval
    private var timer: Timer?

    init(timeInterval: TimeInterval, completion: (() -> Void)? = nil) {
        self.timeInterval = timeInterval
        self.completion = completion
    }

    func renewInterval() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(triggerCompletion), userInfo: nil, repeats: false)
    }

    @objc
    private func triggerCompletion() {
        guard let timer = timer, timer.isValid else { return }
        completion?()
    }
}
