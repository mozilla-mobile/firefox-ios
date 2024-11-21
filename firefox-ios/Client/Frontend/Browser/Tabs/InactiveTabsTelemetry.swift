// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

// Laurie: TODO unit tests
struct InactiveTabsTelemetry {
    private enum EventExtraKey: String {
        case inactiveTabsCollapsed = "collapsed"
        case inactiveTabsExpanded = "expanded"
    }

    func sectionShown() {
        GleanMetrics.InactiveTabsTray.inactiveTabShown.add()
    }

    func tabSwipedToClose() {
        GleanMetrics.InactiveTabsTray.inactiveTabSwipeClose.add()
    }

    func closedAllTabs() {
        GleanMetrics.InactiveTabsTray.inactiveTabsCloseAllBtn.add()
    }

    func tabOpened() {
        GleanMetrics.InactiveTabsTray.openInactiveTab.add()
    }

    func section(hasExpanded: Bool) {
        let hasExpandedEvent: EventExtraKey = hasExpanded ? .inactiveTabsExpanded : .inactiveTabsCollapsed
        let expandedExtras = GleanMetrics.InactiveTabsTray.ToggleInactiveTabTrayExtra(toggleType: hasExpandedEvent.rawValue)

        GleanMetrics.InactiveTabsTray.toggleInactiveTabTray.record(expandedExtras)
    }
}
