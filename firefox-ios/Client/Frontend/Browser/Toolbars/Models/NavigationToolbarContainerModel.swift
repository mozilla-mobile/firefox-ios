// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit

struct NavigationToolbarContainerModel {
    let actions: [ToolbarElement]
    let displayBorder: Bool
    let windowUUID: WindowUUID

    var navigationToolbarState: NavigationToolbarState {
        return NavigationToolbarState(actions: actions, shouldDisplayBorder: displayBorder)
    }

    init(state: ToolbarState, windowUUID: WindowUUID) {
        self.displayBorder = state.navigationToolbar.displayBorder
        self.actions = state.navigationToolbar.actions.map { action in
            ToolbarElement(
                iconName: action.iconName,
                numberOfTabs: action.numberOfTabs,
                isEnabled: action.isEnabled,
                a11yLabel: action.a11yLabel,
                a11yId: action.a11yId,
                onSelected: {
                    let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                         gestureType: .tap,
                                                         windowUUID: windowUUID,
                                                         actionType: ToolbarMiddlewareActionType.didTapButton)
                    store.dispatch(action)
                }
            )
        }
        self.windowUUID = windowUUID
    }
}
