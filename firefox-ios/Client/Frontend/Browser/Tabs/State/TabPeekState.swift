// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import ModifiedCopy
import Common

@Copyable
struct TabPeekState: ScreenState {
    let windowUUID: WindowUUID
    let showAddToBookmarks: Bool
    let showRemoveBookmark: Bool
    let showSendToDevice: Bool
    let showCopyURL: Bool
    let showCloseTab: Bool
    let previewAccessibilityLabel: String
    let screenshot: UIImage

    init(appState: AppState, uuid: WindowUUID) {
        guard let tabPeekState = appState.componentState(
            TabPeekState.self,
            for: .tabPeek,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: tabPeekState.windowUUID,
                  showAddToBookmarks: tabPeekState.showAddToBookmarks,
                  showRemoveBookmark: tabPeekState.showRemoveBookmark,
                  showSendToDevice: tabPeekState.showSendToDevice,
                  showCopyURL: tabPeekState.showCopyURL,
                  showCloseTab: tabPeekState.showCloseTab,
                  previewAccessibilityLabel: tabPeekState.previewAccessibilityLabel,
                  screenshot: tabPeekState.screenshot)
    }

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.showAddToBookmarks = false
        self.showRemoveBookmark = false
        self.showSendToDevice = false
        self.showCopyURL = true
        self.showCloseTab = true
        self.previewAccessibilityLabel = ""
        self.screenshot = UIImage()
    }

    init(windowUUID: WindowUUID,
         showAddToBookmarks: Bool,
         showRemoveBookmark: Bool,
         showSendToDevice: Bool,
         showCopyURL: Bool,
         showCloseTab: Bool,
         previewAccessibilityLabel: String,
         screenshot: UIImage) {
        self.windowUUID = windowUUID
        self.showAddToBookmarks = showAddToBookmarks
        self.showRemoveBookmark = showRemoveBookmark
        self.showSendToDevice = showSendToDevice
        self.showCopyURL = showCopyURL
        self.showCloseTab = showCloseTab
        self.previewAccessibilityLabel = previewAccessibilityLabel
        self.screenshot = screenshot
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
              let action = action as? TabPeekAction else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case TabPeekActionType.loadTabPeek:
            guard let tabPeekModel = action.tabPeekModel else { return defaultState(from: state) }

            return state
                .copy(showAddToBookmarks: tabPeekModel.canTabBeSaved)
                .copy(showRemoveBookmark: tabPeekModel.canTabBeRemoved)
                .copy(showSendToDevice: tabPeekModel.isSyncEnabled && tabPeekModel.canTabBeSaved)
                .copy(showCopyURL: tabPeekModel.canCopyURL)
                .copy(previewAccessibilityLabel: tabPeekModel.accessiblityLabel)
                .copy(screenshot: tabPeekModel.screenshot)
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: TabPeekState) -> TabPeekState {
        return TabPeekState(windowUUID: state.windowUUID)
    }
}
