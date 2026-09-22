// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This enum is a subset of `TabTrayPanelType`. It is only possible for the user to manually create either `normal` or
/// `private` tabs in the `TabsDisplayView`, not synced tabs.
///
/// Eventually it would be nice for `TabTrayPanelType` to inherit from `TabsDisplayViewPanelType`, but because of the
/// `tabTrayUIExperiments` experiment, we can't alter the `TabTrayPanelType` rawValue indices right now.
enum TabsDisplayViewPanelType {
    case normal
    case `private`

    init?(fromTabTrayPanelType panelType: TabTrayPanelType) {
        switch panelType {
        case .tabs:
            self = .normal
        case .privateTabs:
            self = .private
        case .syncedTabs:
            return nil
        }
    }

    var modeForTelemetry: TabsPanelTelemetry.Mode {
        switch self {
        case .normal:
            return .normal
        case .private:
            return .private
        }
    }
}
