// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

enum TabTrayPanelType: Int, CaseIterable {
    case tabs
    case privateTabs
    case syncedTabs

    var navTitle: String {
        switch self {
        case .tabs:
            return .TabTrayV2Title
        case .privateTabs:
            return .TabTrayPrivateBrowsingTitle
        case .syncedTabs:
            return .LegacyAppMenu.AppMenuSyncedTabsTitleString
        }
    }

    var label: String {
        switch self {
        case .tabs:
            return String.TabTraySegmentedControlTitlesTabs
        case .privateTabs:
            return String.TabTraySegmentedControlTitlesPrivateTabs
        case .syncedTabs:
            return String.TabTraySegmentedControlTitlesSyncedTabs
        }
    }

    var image: UIImage? {
        switch self {
        case .tabs:
            return UIImage(named: StandardImageIdentifiers.Large.tab)
        case .privateTabs:
            return UIImage(named: StandardImageIdentifiers.Large.privateMode)
        case .syncedTabs:
            return UIImage(named: StandardImageIdentifiers.Large.syncTabs)
        }
    }
}
