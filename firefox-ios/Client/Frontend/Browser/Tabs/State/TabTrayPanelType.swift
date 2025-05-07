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
            return .TabsTray.TabTrayV2Title
        case .privateTabs:
            return .TabsTray.TabTrayPrivateBrowsingTitle
        case .syncedTabs:
            return .LegacyAppMenu.AppMenuSyncedTabsTitleString
        }
    }

    var label: String {
        switch self {
        case .tabs:
            return .TabsTray.TabsSelectorNormalTabsTitle
        case .privateTabs:
            return .TabsTray.TabsSelectorPrivateTabsTitle
        case .syncedTabs:
            return .TabsTray.TabsSelectorSyncedTabsTitle
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

    var modeForTelemetry: TabsPanelTelemetry.Mode {
        switch self {
        case .tabs:
            return .normal
        case .privateTabs:
            return .private
        case .syncedTabs:
            return .sync
        }
    }

    static func getExperimentConvert(index: Int) -> TabTrayPanelType {
        var panelType: TabTrayPanelType = .tabs
        switch index {
        case 0: panelType = .privateTabs
        case 1: panelType = .tabs
        case 2: panelType = .syncedTabs
        default: break
        }
        return panelType
    }
}
