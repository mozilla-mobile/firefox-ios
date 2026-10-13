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

    @MainActor
    init(
        state: ToolbarState,
        longPressMenuProvider: @escaping @MainActor (ToolbarActionConfiguration.ActionType) -> UIMenu? = { _ in nil },
        windowUUID: WindowUUID
    ) {
        self.displayBorder = state.navigationToolbar.displayBorder
        self.canShowNavigationHint = state.canShowNavigationHint
        self.isTranslucent = state.isTranslucent
        self.actions = state.navigationToolbar.actions.map { action in
            return ToolbarElement(
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
                a11yCustomAction: NavigationToolbarContainerModel.getA11yCustomAction(action: action,
                                                                                      windowUUID: windowUUID),
                longPressBehavior: NavigationToolbarContainerModel.makeLongPressBehavior(
                    action: action,
                    isShowingTopTabs: state.isShowingTopTabs,
                    longPressMenuProvider: longPressMenuProvider,
                    windowUUID: windowUUID
                ),
                previousTabScreenshot: action.previousTabScreenshot,
                nextTabScreenshot: action.nextTabScreenshot,
                onSelected: NavigationToolbarContainerModel.getOnSelected(action: action, windowUUID: windowUUID)
            )
        }
        self.windowUUID = windowUUID
    }

    @MainActor
    private static func getA11yCustomAction(action: ToolbarActionConfiguration, windowUUID: WindowUUID) -> (() -> Void)? {
        return action.a11yCustomActionName != nil ? {
            let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.customA11yAction)
            store.dispatch(action)
        } : nil
    }

    @MainActor
    private static func getOnSelected(action: ToolbarActionConfiguration, windowUUID: WindowUUID) -> ((UIButton) -> Void)? {
        return { button in
            let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                 buttonTapped: button,
                                                 gestureType: .tap,
                                                 windowUUID: windowUUID,
                                                 actionType: ToolbarMiddlewareActionType.didTapButton)
            store.dispatch(action)
        }
    }

    @MainActor
    private static func makeLongPressBehavior(
        action: ToolbarActionConfiguration,
        isShowingTopTabs: Bool,
        longPressMenuProvider: @escaping @MainActor (ToolbarActionConfiguration.ActionType) -> UIMenu?,
        windowUUID: WindowUUID
    ) -> ToolbarLongPressBehavior {
        guard action.canPerformLongPressAction(isShowingTopTabs: isShowingTopTabs) else {
            return .none
        }

        switch action.actionType {
        case .tabs, .newTab:
            return .menu { longPressMenuProvider(action.actionType) }
        default:
            return .action { button in
                let action = ToolbarMiddlewareAction(buttonType: action.actionType,
                                                     buttonTapped: button,
                                                     gestureType: .longPress,
                                                     windowUUID: windowUUID,
                                                     actionType: ToolbarMiddlewareActionType.didTapButton)
                store.dispatch(action)
            }
        }
    }
}
