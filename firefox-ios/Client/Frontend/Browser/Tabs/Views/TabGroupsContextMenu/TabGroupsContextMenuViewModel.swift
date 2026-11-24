// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct TabGroupsContextMenuViewModel: Equatable {
    let destinationTitle: String
    let showsGroupActions: Bool
    let tabCount: Int
    let moreAccessibilityLabel: String
    var colors: TabGroupsTrayBarViewModel.Colors = .system

    var manageTitle: String { String(format: .TabGroups.ManageTitle, destinationTitle) }
    var closeTabsTitle: String { String(format: .TabGroups.CloseAllTabs, tabCount.formatted()) }
}

enum TabGroupsContextMenuAction: Equatable {
    case selectTabs
    case customizeGroup
    case closeTabs
    case closeTabsOlderThan(TabGroupsTabAge)
    case ungroup
    case deleteGroup
    case shareGroup
}

enum TabGroupsTabAge: String, CaseIterable {
    case oneDay, oneWeek, oneMonth

    var title: String {
        switch self {
        case .oneDay: return .TabsTray.TabTrayOneDayAgoTitle
        case .oneWeek: return .TabsTray.TabTrayOneWeekAgoTitle
        case .oneMonth: return .TabsTray.TabTrayOneMonthAgoTitle
        }
    }

    func dateCutoff(relativeTo date: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .oneDay: return calendar.date(byAdding: .day, value: -1, to: date) ?? date
        case .oneWeek: return calendar.date(byAdding: .day, value: -7, to: date) ?? date
        case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: date) ?? date
        }
    }
}

struct TabGroupsConfirmationViewModel: Equatable {
    enum Kind {
        case ungroup, delete
    }

    let groupName: String
    let tabCount: Int
    let kind: Kind

    var title: String {
        String(format: kind == .ungroup ? .TabGroups.UngroupTitle : .TabGroups.DeleteGroupTitle, groupName)
    }

    var message: String {
        String(format: kind == .ungroup ? .TabGroups.UngroupMessage : .TabGroups.DeleteGroupMessage, tabCount.formatted())
    }

    var actionTitle: String { kind == .ungroup ? .TabGroups.Ungroup : .TabGroups.DeleteGroup }
    var cancelTitle: String { .TabGroups.Cancel }
}
