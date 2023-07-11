// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabsQuantityTelemetry {
    static func trackTabsQuantity(tabManager: TabManager) {
        let privateExtra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: Int64(tabManager.privateTabs.count)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .background,
                                     object: .tabPrivateQuantity,
                                     extras: privateExtra)

        let normalExtra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: Int64(tabManager.normalActiveTabs.count)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .background,
                                     object: .tabNormalQuantity,
                                     extras: normalExtra)

        let inactiveExtra = [TelemetryWrapper.EventExtraKey.tabsQuantity.rawValue: Int64(tabManager.inactiveTabs.count)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .background,
                                     object: .tabInactiveQuantity,
                                     extras: inactiveExtra)
    }
}
