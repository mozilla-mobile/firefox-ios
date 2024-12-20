// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct InactiveTabsTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    enum EventExtraKey: String {
        case inactiveTabsCollapsed = "collapsed"
        case inactiveTabsExpanded = "expanded"
    }

    func sectionShown() {
        gleanWrapper.submitCounterMetricType(event: GleanMetrics.InactiveTabsTray.inactiveTabShown)
    }

    func tabSwipedToClose() {
        gleanWrapper.submitCounterMetricType(event: GleanMetrics.InactiveTabsTray.inactiveTabSwipeClose)
    }

    func closedAllTabs() {
        gleanWrapper.submitCounterMetricType(event: GleanMetrics.InactiveTabsTray.inactiveTabsCloseAllBtn)
    }

    func tabOpened() {
        gleanWrapper.submitCounterMetricType(event: GleanMetrics.InactiveTabsTray.openInactiveTab)
    }

    func sectionToggled(hasExpanded: Bool) {
        let hasExpandedEvent: EventExtraKey = hasExpanded ? .inactiveTabsExpanded : .inactiveTabsCollapsed
        let expandedExtras = GleanMetrics.InactiveTabsTray.ToggleInactiveTabTrayExtra(toggleType: hasExpandedEvent.rawValue)
        gleanWrapper.submitEventMetricType(event: GleanMetrics.InactiveTabsTray.toggleInactiveTabTray,
                                           extras: expandedExtras)
    }
}
