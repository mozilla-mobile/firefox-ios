// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class StopWatchTimer {
    private var timer: Timer?
    var isPaused = true
    // Recorded in seconds
    var elapsedTime: Int32 = 0

    func startOrResume() {
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(incrementValue),
            userInfo: nil,
            repeats: true
        )
    }

    @objc
    func incrementValue() {
        elapsedTime += 1
    }

    func pauseOrStop() {
        timer?.invalidate()
    }

    func resetTimer() {
        elapsedTime = 0
        timer = nil
    }
}
