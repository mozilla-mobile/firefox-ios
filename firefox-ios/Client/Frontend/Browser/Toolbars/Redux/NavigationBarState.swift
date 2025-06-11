// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct NavigationBarState: StateType, Equatable {
    var windowUUID: WindowUUID
    var actions: [ToolbarActionConfiguration]
    var displayBorder: Bool

    private static let searchAction = ToolbarActionConfiguration(
        actionType: .search,
        iconName: StandardImageIdentifiers.Large.search,
        isEnabled: true,
        a11yLabel: .TabToolbarSearchAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.searchButton)

    private static let homeAction = ToolbarActionConfiguration(
        actionType: .home,
        iconName: StandardImageIdentifiers.Large.home,
        isEnabled: true,
        a11yLabel: .TabToolbarHomeAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.homeButton)

    private static let dataClearanceAction = ToolbarActionConfiguration(
        actionType: .dataClearance,
        iconName: StandardImageIdentifiers.Large.dataClearance,
        isEnabled: true,
        contextualHintType: ContextualHintType.dataClearance.rawValue,
        a11yLabel: .TabToolbarDataClearanceAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.fireButton)

    private static let newTabAction = ToolbarActionConfiguration(
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
         actions: [ToolbarActionConfiguration],
         displayBorder: Bool) {
        self.windowUUID = windowUUID
        self.actions = actions
        self.displayBorder = displayBorder
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            return handleDidLoadToolbarsAction(state: state, action: action)

        case ToolbarActionType.urlDidChange:
            return handleUrlDidChangeAction(state: state, action: action)

        case ToolbarActionType.numberOfTabsChanged:
            return handleNumberOfTabsChangedAction(state: state, action: action)

        case ToolbarActionType.backForwardButtonStateChanged:
            return handleBackForwardButtonStateChangedAction(state: state, action: action)

        case ToolbarActionType.showMenuWarningBadge:
            return handleShowMenuWarningBadgeAction(state: state, action: action)

        case ToolbarActionType.borderPositionChanged,
            ToolbarActionType.toolbarPositionChanged:
            return handlePositionChangedAction(state: state, action: action)

        default:
            return defaultState(from: state)
        }
    }

    private static func handleDidLoadToolbarsAction(state: Self, action: Action) -> Self {
        guard let displayBorder = (action as? ToolbarAction)?.displayNavBorder,
              let toolbarAction = action as? ToolbarAction
        else {
            return defaultState(from: state)
        }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: displayBorder
        )
    }

    private static func handleUrlDidChangeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: state.displayBorder
        )
    }

    private static func handleNumberOfTabsChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: state.displayBorder
        )
    }

    private static func handleBackForwardButtonStateChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: state.displayBorder
        )
    }

    private static func handleShowMenuWarningBadgeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: state.displayBorder
        )
    }

    private static func handlePositionChangedAction(state: Self, action: Action) -> Self {
        guard let displayBorder = (action as? ToolbarAction)?.displayNavBorder
        else {
            return defaultState(from: state)
        }

        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: state.actions,
            displayBorder: displayBorder
        )
    }

    static func defaultState(from state: NavigationBarState) -> NavigationBarState {
        return NavigationBarState(
            windowUUID: state.windowUUID,
            actions: state.actions,
            displayBorder: state.displayBorder
        )
    }

    // MARK: - Navigation Toolbar Actions
    private static func navigationActions(
        action: ToolbarAction,
        navigationBarState: NavigationBarState)
    -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        guard let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return actions }

        let isLoadAction = action.actionType as? ToolbarActionType == .didLoadToolbars
        let layout = isLoadAction ? action.toolbarLayout : toolbarState.toolbarLayout

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
            forwardAction(enabled: canGoForward)
        ]

        switch layout {
        case .version1, .none:
            actions.append(middleAction)
            actions.append(menuAction(iconName: StandardImageIdentifiers.Large.moreHorizontalRound,
                                      showWarningBadge: showWarningBadge))
            actions.append(tabsAction(numberOfTabs: numberOfTabs, isPrivateMode: toolbarState.isPrivateMode))
        case .version2:
            actions.append(middleAction)
            actions.append(tabsAction(numberOfTabs: numberOfTabs, isPrivateMode: toolbarState.isPrivateMode))
            actions.append(menuAction(iconName: StandardImageIdentifiers.Large.moreHorizontalRound,
                                      showWarningBadge: showWarningBadge))
        }

        return actions
    }

    private static func getMiddleButtonAction(url: URL?,
                                              isPrivateMode: Bool,
                                              canShowDataClearanceAction: Bool,
                                              isNewTabFeatureEnabled: Bool)
    -> ToolbarActionConfiguration {
        let canShowDataClearanceAction = canShowDataClearanceAction && isPrivateMode
        let isNewTabEnabled = isNewTabFeatureEnabled
        let middleActionForWebpage = canShowDataClearanceAction ?
                                     dataClearanceAction : isNewTabEnabled ? newTabAction : homeAction
        let middleActionForHomepage = searchAction
        let middleAction = url == nil ? middleActionForHomepage : middleActionForWebpage

        return middleAction
    }

    // MARK: - Helper
    private static func backAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.chevronLeft,
            isFlippedForRTL: true,
            isEnabled: enabled,
            contextualHintType: ContextualHintType.navigation.rawValue,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    private static func forwardAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.chevronRight,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }

    private static func tabsAction(numberOfTabs: Int = 1,
                                   isPrivateMode: Bool = false) -> ToolbarActionConfiguration {
        let largeContentTitle = numberOfTabs > 99 ?
            .Toolbars.TabsButtonOverflowLargeContentTitle :
            String(format: .Toolbars.TabsButtonLargeContentTitle, NSNumber(value: numberOfTabs))

        return ToolbarActionConfiguration(
            actionType: .tabs,
            iconName: StandardImageIdentifiers.Large.tab,
            badgeImageName: isPrivateMode ? StandardImageIdentifiers.Medium.privateModeCircleFillPurple : nil,
            maskImageName: isPrivateMode ? ImageIdentifiers.badgeMask : nil,
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            largeContentTitle: largeContentTitle,
            a11yLabel: .Toolbars.TabsButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.tabsButton)
    }

    private static func menuAction(iconName: String, showWarningBadge: Bool = false) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .menu,
            iconName: iconName,
            badgeImageName: showWarningBadge ? StandardImageIdentifiers.Large.warningFill : nil,
            maskImageName: showWarningBadge ? ImageIdentifiers.menuWarningMask : nil,
            isEnabled: true,
            a11yLabel: .Toolbars.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }
}
