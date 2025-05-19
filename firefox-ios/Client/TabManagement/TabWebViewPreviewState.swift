// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TabWebViewPreviewState: ScreenState, Equatable {
    let windowUUID: WindowUUID
    let searchBarPosition: SearchBarPosition
    let screenshot: UIImage?

    init(appState: AppState, uuid: WindowUUID) {
        guard let tabPreviewState = store.state.screenState(
            Self.self,
            for: .tabWebViewPreview,
            window: uuid
        )
        else {
            self.init(windowUUID: uuid)
            return
        }
        self.init(
            windowUUID: tabPreviewState.windowUUID,
            searchBarPosition: tabPreviewState.searchBarPosition,
            screenshot: tabPreviewState.screenshot
        )
    }

    init(windowUUID: WindowUUID,
         searchBarPosition: SearchBarPosition,
         screenshot: UIImage?) {
        self.windowUUID = windowUUID
        self.searchBarPosition = searchBarPosition
        self.screenshot = screenshot
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID, searchBarPosition: .top, screenshot: nil)
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else { return defaultState(from: state) }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars, ToolbarActionType.toolbarPositionChanged:
            guard let toolbarPosition = (action as? ToolbarAction)?.toolbarPosition
            else { return defaultState(from: state) }

            return Self(
                windowUUID: state.windowUUID,
                searchBarPosition: toolbarPosition,
                screenshot: state.screenshot
            )

        case TabWebViewPreviewActionType.didTakeScreenshot:
            guard let tabPreviewAction = action as? TabWebViewPreviewAction else { return defaultState(from: state) }

            return Self(
                windowUUID: state.windowUUID,
                searchBarPosition: state.searchBarPosition,
                screenshot: tabPreviewAction.screenshot
            )

        default: return defaultState(from: state)
        }
    }

    static func defaultState(from state: Self) -> Self {
        return Self(
            windowUUID: state.windowUUID,
            searchBarPosition: state.searchBarPosition,
            screenshot: state.screenshot
        )
    }
}
