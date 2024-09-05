// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct NavigationBarState: StateType, Equatable {
    var windowUUID: WindowUUID
    var actions: [ToolbarActionState]
    var displayBorder: Bool

    static let searchAction = ToolbarActionState(
        actionType: .search,
        iconName: StandardImageIdentifiers.Large.search,
        isEnabled: true,
        a11yLabel: .TabToolbarSearchAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.searchButton)

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  actions: [],
                  displayBorder: false)
    }

    init(windowUUID: WindowUUID,
         actions: [ToolbarActionState],
         displayBorder: Bool) {
        self.windowUUID = windowUUID
        self.actions = actions
        self.displayBorder = displayBorder
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            guard let displayBorder = (action as? ToolbarAction)?.displayNavBorder else { return state }

            let actions = [
                backAction(enabled: false),
                forwardAction(enabled: false),
                searchAction,
                tabsAction(),
                menuAction()
            ]
            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: actions,
                displayBorder: displayBorder
            )

        case ToolbarActionType.urlDidChange:
            guard let model = (action as? ToolbarAction)?.navigationToolbarModel else { return state }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: model.actions ?? state.actions,
                displayBorder: model.displayBorder ?? state.displayBorder
            )

        case ToolbarActionType.numberOfTabsChanged:
            guard let navToolbarModel = (action as? ToolbarAction)?.navigationToolbarModel else { return state }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: navToolbarModel.actions ?? state.actions,
                displayBorder: state.displayBorder
            )

        case ToolbarActionType.backForwardButtonStatesChanged:
            guard let model = (action as? ToolbarAction)?.navigationToolbarModel else { return state }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: model.actions ?? state.actions,
                displayBorder: state.displayBorder
            )

        case ToolbarActionType.showMenuWarningBadge:
            guard let model = (action as? ToolbarAction)?.navigationToolbarModel else { return state }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: model.actions ?? state.actions,
                displayBorder: state.displayBorder
            )

        case ToolbarActionType.scrollOffsetChanged,
            ToolbarActionType.toolbarPositionChanged:
            guard let displayBorder = (action as? ToolbarAction)?.displayNavBorder else { return state }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: state.actions,
                displayBorder: displayBorder
            )

        default:
            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: state.actions,
                displayBorder: state.displayBorder
            )
        }
    }

    // MARK: - Helper
    private static func backAction(enabled: Bool) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.back,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    private static func forwardAction(enabled: Bool) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.forward,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }

    private static  func tabsAction(numberOfTabs: Int = 1,
                                    isPrivateMode: Bool = false,
                                    isShowingTopTabs: Bool = false) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .tabs,
            iconName: StandardImageIdentifiers.Large.tab,
            badgeImageName: isPrivateMode ? StandardImageIdentifiers.Medium.privateModeCircleFillPurple : nil,
            maskImageName: isPrivateMode ? ImageIdentifiers.badgeMask : nil,
            numberOfTabs: numberOfTabs,
            isShowingTopTabs: isShowingTopTabs,
            isEnabled: true,
            a11yLabel: .TabsButtonShowTabsAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.tabsButton)
    }

    private static func menuAction(badgeImageName: String? = nil, maskImageName: String? = nil) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .menu,
            iconName: StandardImageIdentifiers.Large.appMenu,
            badgeImageName: badgeImageName,
            maskImageName: maskImageName,
            isEnabled: true,
            a11yLabel: .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }
}
