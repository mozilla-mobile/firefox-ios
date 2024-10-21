// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

enum ToastType: Equatable {
    case addBookmark
    case addToReadingList
    case addShortcut
    case closedSingleTab
    case closedSingleInactiveTab
    case closedAllTabs(count: Int)
    case closedAllInactiveTabs(count: Int)
    case copyURL
    case removeFromReadingList
    case removeShortcut

    var title: String {
        switch self {
        case .addBookmark:
            return .LegacyAppMenu.AddBookmarkConfirmMessage
        case .addToReadingList:
            return .LegacyAppMenu.AddToReadingListConfirmMessage
        case .addShortcut:
            return .LegacyAppMenu.AddPinToShortcutsConfirmMessage
        case .closedSingleTab, .closedSingleInactiveTab:
            return .TabsTray.CloseTabsToast.SingleTabTitle
        case let .closedAllInactiveTabs(tabsCount),
            let .closedAllTabs(count: tabsCount):
            return String.localizedStringWithFormat(
                .TabsTray.CloseTabsToast.Title,
                tabsCount)
        case .copyURL:
            return .LegacyAppMenu.AppMenuCopyURLConfirmMessage
        case .removeFromReadingList:
            return .LegacyAppMenu.RemoveFromReadingListConfirmMessage
        case .removeShortcut:
            return .LegacyAppMenu.RemovePinFromShortcutsConfirmMessage
        }
    }

    var buttonText: String {
        return .TabsTray.CloseTabsToast.Action
    }

    func reduxAction(
        for uuid: WindowUUID,
        panelType: TabTrayPanelType = .tabs
    ) -> TabPanelViewAction? {
        var actionType = TabPanelViewActionType.undoClose
        switch self {
        case .closedSingleTab: actionType = TabPanelViewActionType.undoClose
        case .closedSingleInactiveTab: actionType = TabPanelViewActionType.undoCloseInactiveTab
        case .closedAllTabs: actionType = TabPanelViewActionType.undoCloseAllTabs
        case .closedAllInactiveTabs: actionType = TabPanelViewActionType.undoCloseAllInactiveTabs
        case .copyURL,
                .addBookmark,
                .addShortcut,
                .addToReadingList,
                .removeFromReadingList,
                .removeShortcut:
            return nil
        }

        return TabPanelViewAction(panelType: panelType,
                                  windowUUID: uuid,
                                  actionType: actionType)
    }
}
