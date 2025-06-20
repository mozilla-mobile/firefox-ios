// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit

struct NavigationToolbarContainerModel: Equatable {
    let actions: [ToolbarElement]
    let canShowNavigationHint: Bool
    let displayBorder: Bool
    let isTranslucent: Bool
    let windowUUID: WindowUUID

    var navigationToolbarConfiguration: NavigationToolbarConfiguration {
        return NavigationToolbarConfiguration(actions: actions,
                                              shouldDisplayBorder: displayBorder,
                                              isTranslucencyEnabled: isTranslucent)
    }

    init(state: ToolbarState, windowUUID: WindowUUID) {
        self.displayBorder = state.navigationToolbar.displayBorder
        self.canShowNavigationHint = state.canShowNavigationHint
        self.isTranslucent = state.isTranslucent
        self.actions = state.navigationToolbar.actions.map { action in
            ToolbarElement(
                iconName: action.iconName,
                title: action.actionLabel,
                badgeImageName: action.badgeImageName,
                maskImageName: action.maskImageName,
                numberOfTabs: action.numberOfTabs,
                isEnabled: action.isEnabled,
                isFlippedForRTL: action.isFlippedForRTL,
                isSelected: action.isSelected,
                hasCustomColor: action.hasCustomColor,
                largeContentTitle: action.largeContentTitle,
                contextualHintType: action.contextualHintType,
                a11yLabel: action.a11yLabel,
                a11yHint: action.a11yHint,
                a11yId: action.a11yId,
                a11yCustomActionName: action.a11yCustomActionName,
                a11yCustomAction: action.a11yCustomActionName != nil ? {
                    let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                         windowUUID: windowUUID,
                                                         actionType: ToolbarMiddlewareActionType.customA11yAction)
                    store.dispatchLegacy(action)
                } : nil,
                hasLongPressAction: action.canPerformLongPressAction(isShowingTopTabs: state.isShowingTopTabs),
                onSelected: { button in
                    let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                         buttonTapped: button,
                                                         gestureType: .tap,
                                                         windowUUID: windowUUID,
                                                         actionType: ToolbarMiddlewareActionType.didTapButton)
                    store.dispatchLegacy(action)
                }, onLongPress: action.canPerformLongPressAction(isShowingTopTabs: state.isShowingTopTabs) ? { button in
                    let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                         buttonTapped: button,
                                                         gestureType: .longPress,
                                                         windowUUID: windowUUID,
                                                         actionType: ToolbarMiddlewareActionType.didTapButton)
                    store.dispatchLegacy(action)
                } : nil
            )
        }
        self.windowUUID = windowUUID
    }
}
