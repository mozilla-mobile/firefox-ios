// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common
import CopyWithUpdates

@CopyWithUpdates
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

        self = tabPeekState.copyWithUpdates()
    }

    init(windowUUID: WindowUUID,
         showAddToBookmarks: Bool = false,
         showRemoveBookmark: Bool = false,
         showSendToDevice: Bool = false,
         showCopyURL: Bool = true,
         showCloseTab: Bool = true,
         previewAccessibilityLabel: String = "",
         screenshot: UIImage = UIImage()) {
        self.windowUUID = windowUUID
        self.showAddToBookmarks = showAddToBookmarks
        self.showRemoveBookmark = showRemoveBookmark
        self.showSendToDevice = showSendToDevice
        self.showCopyURL = showCopyURL
        self.showCloseTab = showCloseTab
        self.previewAccessibilityLabel = previewAccessibilityLabel
        self.screenshot = screenshot
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
              let action = action as? TabPeekAction
        else { return state }

        switch action.actionType {
        case TabPeekActionType.loadTabPeek:
            guard let tabPeekModel = action.tabPeekModel else { return state }
            return state.copyWithUpdates(
                                showAddToBookmarks: tabPeekModel.canTabBeSaved,
                                showRemoveBookmark: tabPeekModel.canTabBeRemoved,
                                showSendToDevice: tabPeekModel.isSyncEnabled && tabPeekModel.canTabBeSaved,
                                showCopyURL: tabPeekModel.canCopyURL,
                                previewAccessibilityLabel: tabPeekModel.accessiblityLabel,
                                screenshot: tabPeekModel.screenshot)
        default:
            return state
        }
    }

    static func defaultState(from state: TabPeekState) -> TabPeekState {
        return state.copyWithUpdates()
    }
}
