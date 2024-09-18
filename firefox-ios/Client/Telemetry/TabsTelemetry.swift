// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

final class TabsTelemetry {
    /// Measure with a time distribution https://mozilla.github.io/glean/book/reference/metrics/timing_distribution.html
    /// how long it takes to switch to a new tab
    private var tabSwitchTimerId: GleanTimerId?

    func startTabSwitchMeasurement() {
        tabSwitchTimerId = GleanMetrics.Tabs.tabSwitch.start()
    }

    func stopTabSwitchMeasurement() {
        guard let timerId = tabSwitchTimerId else { return }
        GleanMetrics.Tabs.tabSwitch.stopAndAccumulate(timerId)
        tabSwitchTimerId = nil
    }

    static func trackTabsQuantity(tabManager: TabManager) {
        let privateExtra = [
            TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: Int64(tabManager.privateTabs.count)
        ]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .background,
                                     object: .tabPrivateQuantity,
                                     extras: privateExtra)

        let normalExtra = [
            TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: Int64(tabManager.normalActiveTabs.count)
        ]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .background,
                                     object: .tabNormalQuantity,
                                     extras: normalExtra)

        let inactiveExtra = [
            TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: Int64(tabManager.normalInactiveTabs.count)
        ]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .background,
                                     object: .tabInactiveQuantity,
                                     extras: inactiveExtra)
    }
}
