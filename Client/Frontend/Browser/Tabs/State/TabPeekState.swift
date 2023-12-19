// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

struct TabPeekState: ScreenState, Equatable {
    let showAddToBookmarks: Bool
    let showSendToDevice: Bool
    let showCopyURL: Bool
    let showCloseTab: Bool
    let previewAccessibilityLabel: String
    let screenshot: UIImage

    init(_ appState: AppState) {
        guard let tabPeekState = store.state.screenState(TabPeekState.self, for: AppScreen.tabPeek) else {
            self.init()
            return
        }

        self.init(showAddToBookmarks: tabPeekState.showAddToBookmarks,
                  showSendToDevice: tabPeekState.showSendToDevice,
                  showCopyURL: tabPeekState.showCopyURL,
                  showCloseTab: tabPeekState.showCloseTab,
                  previewAccessibilityLabel: tabPeekState.previewAccessibilityLabel,
                  screenshot: tabPeekState.screenshot)
    }

    init(showAddToBookmarks: Bool = false,
         showSendToDevice: Bool = false,
         showCopyURL: Bool = true,
         showCloseTab: Bool = true,
         previewAccessibilityLabel: String = "",
         screenshot: UIImage = UIImage()) {
        self.showAddToBookmarks = showAddToBookmarks
        self.showSendToDevice = showSendToDevice
        self.showCopyURL = showCopyURL
        self.showCloseTab = showCloseTab
        self.previewAccessibilityLabel = previewAccessibilityLabel
        self.screenshot = screenshot
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case TabPeekAction.loadTabPeek(let tabPeekModel):
            return TabPeekState(showAddToBookmarks: tabPeekModel.canTabBeSaved,
                                showSendToDevice: tabPeekModel.isSyncEnabled && tabPeekModel.canTabBeSaved,
                                previewAccessibilityLabel: tabPeekModel.accessiblityLabel,
                                screenshot: tabPeekModel.screenshot)
        default:
            return state
        }
    }
}
