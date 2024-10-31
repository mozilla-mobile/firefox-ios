// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

struct TabPeekState: ScreenState, Equatable {
    let showAddToBookmarks: Bool
    let showSendToDevice: Bool
    let showCopyURL: Bool
    let showCloseTab: Bool
    let previewAccessibilityLabel: String
    let screenshot: UIImage
    let windowUUID: WindowUUID

    init(appState: AppState, uuid: WindowUUID) {
        guard let tabPeekState = store.state.screenState(TabPeekState.self,
                                                         for: AppScreen.tabPeek,
                                                         window: uuid) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: tabPeekState.windowUUID,
                  showAddToBookmarks: tabPeekState.showAddToBookmarks,
                  showSendToDevice: tabPeekState.showSendToDevice,
                  showCopyURL: tabPeekState.showCopyURL,
                  showCloseTab: tabPeekState.showCloseTab,
                  previewAccessibilityLabel: tabPeekState.previewAccessibilityLabel,
                  screenshot: tabPeekState.screenshot)
    }

    init(windowUUID: WindowUUID,
         showAddToBookmarks: Bool = false,
         showSendToDevice: Bool = false,
         showCopyURL: Bool = true,
         showCloseTab: Bool = true,
         previewAccessibilityLabel: String = "",
         screenshot: UIImage = UIImage()) {
        self.windowUUID = windowUUID
        self.showAddToBookmarks = showAddToBookmarks
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
            return TabPeekState(windowUUID: state.windowUUID,
                                showAddToBookmarks: tabPeekModel.canTabBeSaved,
                                showSendToDevice: tabPeekModel.isSyncEnabled && tabPeekModel.canTabBeSaved,
                                previewAccessibilityLabel: tabPeekModel.accessiblityLabel,
                                screenshot: tabPeekModel.screenshot)
        default:
            return defaultActionState(from: state, action: action)
        }
    }
    
    static func defaultActionState(from state: TabPeekState, action: Action) -> TabPeekState {
        return TabPeekState(windowUUID: state.windowUUID)
    }
}
