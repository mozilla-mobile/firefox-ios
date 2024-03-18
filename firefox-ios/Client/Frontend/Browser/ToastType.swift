// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum ToastType: Equatable {
    case closedSingleTab
    case closedSingleInactiveTab
    case closedAllTabs(count: Int)
    case closedAllInactiveTabs(count: Int)
    case copyURL
    case addBookmark

    var title: String {
        switch self {
        case .closedSingleTab, .closedSingleInactiveTab:
            return .TabsTray.CloseTabsToast.SingleTabTitle
        case let .closedAllInactiveTabs(tabsCount),
            let .closedAllTabs(count: tabsCount):
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

    func reduxAction(for uuid: WindowUUID) -> TabPanelAction? {
        switch self {
        case .closedSingleTab: return .undoClose(uuid.context)
        case .closedSingleInactiveTab: return .undoCloseInactiveTab(uuid.context)
        case .closedAllTabs: return .undoCloseAllTabs(uuid.context)
        case .closedAllInactiveTabs: return .undoCloseAllInactiveTabs(uuid.context)
        case .copyURL, .addBookmark: return nil
        }
    }
}
