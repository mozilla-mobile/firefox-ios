// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum ToastType: Equatable {
    case singleTab
    case allTabs(count: Int)
    case singleInactiveTabs
    case allInactiveTabs(count: Int)
    case copyURL
    case addBookmark

    var title: String {
        switch self {
        case .singleTab, .singleInactiveTabs:
            return .TabsTray.CloseTabsToast.SingleTabTitle
        case let .allInactiveTabs(tabsCount),
            let .allTabs(count: tabsCount):
            return String.localizedStringWithFormat(
                .TabsTray.CloseTabsToast.Title,
                tabsCount)
        case .copyURL:
            return .AppMenu.AppMenuCopyURLConfirmMessage
        case .addBookmark:
            return .AppMenu.AddBookmarkConfirmMessage
        }
    }

    var buttonText: String {
        return .TabsTray.CloseTabsToast.Action
    }

    var reduxAction: TabPanelAction? {
        switch self {
        case .singleTab: return .undoClose
        case .singleInactiveTabs: return .undoCloseInactiveTab
        case .allTabs: return .undoCloseAllTabs
        case .allInactiveTabs: return .undoCloseAllInactiveTabs
        case .copyURL, .addBookmark: return nil
        }
    }
}
