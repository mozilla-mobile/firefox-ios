// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

final class TabsTelemetry {
    /// Measure with a time distribution https://mozilla.github.io/glean/book/reference/metrics/timing_distribution.html
    /// how long it takes to switch to a new tab
    private var tabSwitchTimerId: GleanTimerId?

    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func startTabSwitchMeasurement() {
        tabSwitchTimerId = GleanMetrics.Tabs.tabSwitch.start()
    }

    func stopTabSwitchMeasurement() {
        guard let timerId = tabSwitchTimerId else { return }
        GleanMetrics.Tabs.tabSwitch.stopAndAccumulate(timerId)
        tabSwitchTimerId = nil
    }

    func trackConsecutiveCrashTelemetry(attemptNumber: UInt) {
        let extras = GleanMetrics.Webview.ProcessDidTerminateExtra(consecutiveCrash: Int32(attemptNumber))
        gleanWrapper.recordEvent(for: GleanMetrics.Webview.processDidTerminate,
                                 extras: extras)
    }
}
