// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TabWebViewPreviewState: ScreenState, Equatable {
    let windowUUID: WindowUUID = .unavailable
    let searchBarPosition: SearchBarPosition
    let screenshot: UIImage?

    init(appState: AppState) {
        guard let tabPreviewState = store.state.screenState(
            Self.self,
            for: .tabWebViewPreview,
            window: .unavailable
        )
        else {
            self.init()
            return
        }
        self.init(
            searchBarPosition: tabPreviewState.searchBarPosition,
            screenshot: tabPreviewState.screenshot
        )
    }

    init(searchBarPosition: SearchBarPosition,
         screenshot: UIImage?) {
        self.searchBarPosition = searchBarPosition
        self.screenshot = screenshot
    }

    init() {
        self.init(searchBarPosition: .top, screenshot: nil)
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action.actionType {
        case ToolbarActionType.didLoadToolbars, ToolbarActionType.toolbarPositionChanged:
            guard let toolbarPosition = (action as? ToolbarAction)?.toolbarPosition
            else { return defaultState(from: state) }

            return Self(searchBarPosition: toolbarPosition, screenshot: state.screenshot)

        case TabWebViewPreviewActionType.didTakeScreenshot:
            guard let tabPreviewAction = action as? TabWebViewPreviewAction else { return defaultState(from: state) }
            return Self(searchBarPosition: state.searchBarPosition, screenshot: tabPreviewAction.screenshot)

        default: return defaultState(from: state)
        }
    }

    static func defaultState(from state: Self) -> Self {
        return Self(searchBarPosition: state.searchBarPosition, screenshot: state.screenshot)
    }
}
