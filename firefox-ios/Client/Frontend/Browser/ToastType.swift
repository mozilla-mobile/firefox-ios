// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux

enum ToastType: Equatable {
    case addBookmark(urlString: String)
    case addToReadingList
    case clearCookies
    case openNewTab
    case removeFromReadingList
    case removeShortcut
    case retryTranslatingPage
    case shakeToSummarizeNotAvailable

    var title: String {
        switch self {
        case .addBookmark:
            return .LegacyAppMenu.AddBookmarkConfirmMessage
        case .addToReadingList:
            return .LegacyAppMenu.AddToReadingListConfirmMessage
        case .clearCookies:
            return .Menu.EnhancedTrackingProtection.clearDataToastMessage
        case .openNewTab:
            return .ContextMenuButtonToastNewTabOpenedLabelText
        case .removeFromReadingList:
            return .LegacyAppMenu.RemoveFromReadingListConfirmMessage
        case .removeShortcut:
            return .LegacyAppMenu.RemovePinFromShortcutsConfirmMessage
        case .retryTranslatingPage:
            return .Translations.Sheet.Error.GeneralTitle
        case .shakeToSummarizeNotAvailable:
            return .Summarizer.ToastLabel
        }
    }

    var buttonText: String {
        switch self {
        case .openNewTab:
            return .ContextMenuButtonToastNewTabOpenedButtonText
        case .retryTranslatingPage:
            return .Translations.Banner.RetryButton
        default:
            return .TabsTray.CloseTabsToast.Action
        }
    }

    func reduxAction(for uuid: WindowUUID) -> Action? {
        switch self {
        case .retryTranslatingPage:
            return TranslationsAction(windowUUID: uuid, actionType: TranslationsActionType.didTapRetryFailedTranslation)
        case .clearCookies,
                .addBookmark,
                .addToReadingList,
                .openNewTab,
                .removeFromReadingList,
                .removeShortcut,
                .shakeToSummarizeNotAvailable:
            return nil
        }
    }

    private func tabPanelAction(for actionType: TabPanelViewActionType, uuid: WindowUUID) -> TabPanelViewAction {
        // None of the above handled toast actions require a specific panelType
        return TabPanelViewAction(panelType: nil,
                                  windowUUID: uuid,
                                  actionType: actionType)
    }
}
