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

    private static let searchAction = ToolbarActionState(
        actionType: .search,
        iconName: StandardImageIdentifiers.Large.search,
        isEnabled: true,
        a11yLabel: .TabToolbarSearchAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.searchButton)

    private static let homeAction = ToolbarActionState(
        actionType: .home,
        iconName: StandardImageIdentifiers.Large.home,
        isEnabled: true,
        a11yLabel: .TabToolbarHomeAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.homeButton)

    private static let dataClearanceAction = ToolbarActionState(
        actionType: .dataClearance,
        iconName: StandardImageIdentifiers.Large.dataClearance,
        isEnabled: true,
        contextualHintType: ContextualHintType.dataClearance.rawValue,
        a11yLabel: .TabToolbarDataClearanceAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.fireButton)

    private static let newTabAction = ToolbarActionState(
        actionType: .newTab,
        iconName: StandardImageIdentifiers.Large.plus,
        isEnabled: true,
        a11yLabel: .Toolbars.NewTabButton,
        a11yId: AccessibilityIdentifiers.Toolbar.addNewTabButton)

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
            return handleToolbarDidLoadToolbars(state: state, action: action)

        case ToolbarActionType.urlDidChange:
            return handleToolbarUrlDidChange(state: state, action: action)

        case ToolbarActionType.numberOfTabsChanged:
            return handleToolbarNumberOfTabsChanged(state: state, action: action)

        case ToolbarActionType.backForwardButtonStateChanged:
            return handleToolbarBackForwardButtonStateChanged(state: state, action: action)

        case ToolbarActionType.showMenuWarningBadge:
            return handleToolbarShowMenuWarningBadge(state: state, action: action)

        case ToolbarActionType.borderPositionChanged,
            ToolbarActionType.toolbarPositionChanged:
            return handleToolbarPositionChanged(state: state, action: action)

        default:
            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: state.actions,
                displayBorder: state.displayBorder
            )
        }
    }

    private static func handleToolbarDidLoadToolbars(state: Self, action: Action) -> Self {
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
    }

    private static func handleToolbarUrlDidChange(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: state.displayBorder
        )
    }

    private static func handleToolbarNumberOfTabsChanged(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: state.displayBorder
        )
    }

    private static func handleToolbarBackForwardButtonStateChanged(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: state.displayBorder
        )
    }

    private static func handleToolbarShowMenuWarningBadge(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: state.displayBorder
        )
    }

    private static func handleToolbarPositionChanged(state: Self, action: Action) -> Self {
        guard let displayBorder = (action as? ToolbarAction)?.displayNavBorder else { return state }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: state.actions,
            displayBorder: displayBorder
        )
    }

    // MARK: - Navigation Toolbar Actions

    private static func navigationActions(
        action: ToolbarAction,
        navigationBarState: NavigationBarState)
    -> [ToolbarActionState] {
        var actions = [ToolbarActionState]()

        guard let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return actions }

        let isUrlChangeAction = action.actionType as? ToolbarActionType == .urlDidChange
        let url = isUrlChangeAction ? action.url : toolbarState.addressToolbar.url

        let middleAction = getMiddleButtonAction(url: url,
                                                 isPrivateMode: toolbarState.isPrivateMode,
                                                 canShowDataClearanceAction: toolbarState.canShowDataClearanceAction,
                                                 isNewTabFeatureEnabled: toolbarState.isNewTabFeatureEnabled)

        let canGoBack = action.canGoBack ?? toolbarState.canGoBack
        let canGoForward = action.canGoForward ?? toolbarState.canGoForward
        let numberOfTabs = action.numberOfTabs ?? toolbarState.numberOfTabs

        let isShowMenuWarningAction = action.actionType as? ToolbarActionType == .showMenuWarningBadge
        let showActionWarningBadge = action.showMenuWarningBadge ?? toolbarState.showMenuWarningBadge
        let showWarningBadge = isShowMenuWarningAction ? showActionWarningBadge : toolbarState.showMenuWarningBadge

        actions = [
            backAction(enabled: canGoBack),
            forwardAction(enabled: canGoForward),
            middleAction,
            tabsAction(numberOfTabs: numberOfTabs, isPrivateMode: toolbarState.isPrivateMode),
            menuAction(showWarningBadge: showWarningBadge)
        ]

        return actions
    }

    private static func getMiddleButtonAction(url: URL?,
                                              isPrivateMode: Bool,
                                              canShowDataClearanceAction: Bool,
                                              isNewTabFeatureEnabled: Bool)
    -> ToolbarActionState {
        // WT ToDo
        let canShowDataClearanceAction = canShowDataClearanceAction && isPrivateMode
        let isNewTabEnabled = isNewTabFeatureEnabled
        let middleActionForWebpage = canShowDataClearanceAction ?
                                     dataClearanceAction : isNewTabEnabled ? newTabAction : homeAction
        let middleActionForHomepage = searchAction
        let middleAction = url == nil ? middleActionForHomepage : middleActionForWebpage

        return middleAction
    }

    // MARK: - Helper
    private static func backAction(enabled: Bool) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.back,
            isFlippedForRTL: true,
            isEnabled: enabled,
            contextualHintType: ContextualHintType.navigation.rawValue,
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

    private static func tabsAction(numberOfTabs: Int = 1,
                                   isPrivateMode: Bool = false) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .tabs,
            iconName: StandardImageIdentifiers.Large.tab,
            badgeImageName: isPrivateMode ? StandardImageIdentifiers.Medium.privateModeCircleFillPurple : nil,
            maskImageName: isPrivateMode ? ImageIdentifiers.badgeMask : nil,
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            a11yLabel: .TabsButtonShowTabsAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.tabsButton)
    }

    private static func menuAction(showWarningBadge: Bool = false) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .menu,
            iconName: StandardImageIdentifiers.Large.appMenu,
            badgeImageName: showWarningBadge ? StandardImageIdentifiers.Large.warningFill : nil,
            maskImageName: showWarningBadge ? ImageIdentifiers.menuWarningMask : nil,
            isEnabled: true,
            a11yLabel: .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }
}
