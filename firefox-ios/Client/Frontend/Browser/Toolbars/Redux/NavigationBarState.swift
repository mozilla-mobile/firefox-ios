// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux

enum NavigationBarMiddleButtonType: String, Equatable, CaseIterable {
    case home
    case newTab

    var label: String {
        return switch self {
        case .home:
            .Settings.Appearance.NavigationToolbar.Home
        case .newTab:
            .Settings.Appearance.NavigationToolbar.NewTab
        }
    }

    var imageName: String {
        return switch self {
        case .home:
            StandardImageIdentifiers.Large.home
        case .newTab:
            StandardImageIdentifiers.Large.plus
        }
    }
}

@CopyWithUpdates
struct NavigationBarState: StateType, Equatable {
    var windowUUID: WindowUUID
    var actions: [ToolbarActionConfiguration]
    var displayBorder: Bool
    var middleButton: NavigationBarMiddleButtonType

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

    private static let newTabAction = ToolbarActionConfiguration(
        actionType: .newTab,
        iconName: StandardImageIdentifiers.Large.plus,
        isEnabled: true,
        a11yLabel: .Toolbars.NewTabButton,
        a11yId: AccessibilityIdentifiers.Toolbar.addNewTabButton)

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  actions: [],
                  displayBorder: false,
                  middleButton: .newTab)
    }

    init(windowUUID: WindowUUID,
         actions: [ToolbarActionConfiguration],
         displayBorder: Bool,
         middleButton: NavigationBarMiddleButtonType) {
        self.windowUUID = windowUUID
        self.actions = actions
        self.displayBorder = displayBorder
        self.middleButton = middleButton
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

        case ToolbarActionType.didSetTabScreenshot:
            return handleDidSetTabScreenshotAction(state: state, action: action)

        case ToolbarActionType.backForwardButtonStateChanged:
            return handleBackForwardButtonStateChangedAction(state: state, action: action)

        case ToolbarActionType.showMenuWarningBadge:
            return handleShowMenuWarningBadgeAction(state: state, action: action)

        case ToolbarActionType.borderPositionChanged,
            ToolbarActionType.toolbarPositionChanged:
            return handlePositionChangedAction(state: state, action: action)

        case ToolbarActionType.navigationMiddleButtonDidChange:
            return handleNavigationMiddleButtonDidChange(state: state, action: action)

        default:
            return defaultState(from: state)
        }
    }

    @MainActor
    private static func handleDidLoadToolbarsAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction,
              let displayBorder = toolbarAction.displayNavBorder,
              let middleButton = toolbarAction.middleButton
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            displayBorder: displayBorder,
            middleButton: middleButton
        )
    }

    @MainActor
    private static func handleUrlDidChangeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            actions: navigationActions(action: toolbarAction, navigationBarState: state)
        )
    }

    @MainActor
    private static func handleNumberOfTabsChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            actions: navigationActions(action: toolbarAction, navigationBarState: state)
        )
    }

    @MainActor
    private static func handleDidSetTabScreenshotAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            actions: navigationActions(action: toolbarAction, navigationBarState: state)
        )
    }

    @MainActor
    private static func handleBackForwardButtonStateChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            actions: navigationActions(action: toolbarAction, navigationBarState: state)
        )
    }

    @MainActor
    private static func handleShowMenuWarningBadgeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            actions: navigationActions(action: toolbarAction, navigationBarState: state)
        )
    }

    private static func handlePositionChangedAction(state: Self, action: Action) -> Self {
        guard let displayBorder = (action as? ToolbarAction)?.displayNavBorder
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            displayBorder: displayBorder
        )
    }

    @MainActor
    private static func handleNavigationMiddleButtonDidChange(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction,
              let middleButton = toolbarAction.middleButton
        else { return defaultState(from: state) }

        return state.copyWithUpdates(
            actions: navigationActions(action: toolbarAction, navigationBarState: state),
            middleButton: middleButton
        )
    }

    static func defaultState(from state: NavigationBarState) -> NavigationBarState {
        return state.copyWithUpdates()
    }

    // MARK: - Navigation Toolbar Actions
    @MainActor
    private static func navigationActions(
        action: ToolbarAction,
        navigationBarState: NavigationBarState)
    -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        guard let toolbarState = store.state.componentState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return actions }

        let isLoadAction = action.actionType as? ToolbarActionType == .didLoadToolbars
        let layout = isLoadAction ? action.toolbarLayout : toolbarState.toolbarLayout
        let tabTrayButtonStyle = isLoadAction ? action.tabTrayButtonStyle : toolbarState.tabTrayButtonStyle

        let isUrlChangeAction = action.actionType as? ToolbarActionType == .urlDidChange
        let url = isUrlChangeAction ? action.url : toolbarState.addressToolbar.url

        let isMiddleButtonChangeAction = action.actionType as? ToolbarActionType == .navigationMiddleButtonDidChange
        let middleButton = isMiddleButtonChangeAction ? action.middleButton ?? .newTab : navigationBarState.middleButton

        let middleAction = getMiddleButtonAction(url: url,
                                                 isPrivateMode: toolbarState.isPrivateMode,
                                                 middleButton: middleButton)

        let canGoBack = action.canGoBack ?? toolbarState.canGoBack
        let canGoForward = action.canGoForward ?? toolbarState.canGoForward
        let numberOfTabs = action.numberOfTabs ?? toolbarState.numberOfTabs

        let isShowMenuWarningAction = action.actionType as? ToolbarActionType == .showMenuWarningBadge
        let showActionWarningBadge = action.showMenuWarningBadge ?? toolbarState.showMenuWarningBadge
        let showWarningBadge = isShowMenuWarningAction ? showActionWarningBadge : toolbarState.showMenuWarningBadge

        let isTabScreenshotAction = action.actionType as? ToolbarActionType == .didSetTabScreenshot
        let previousTabScreenshot = isTabScreenshotAction ? action.previousTabScreenshot : toolbarState.previousTabScreenshot
        let nextTabScreenshot = isTabScreenshotAction ? action.nextTabScreenshot : toolbarState.nextTabScreenshot

        actions = [
            backAction(enabled: canGoBack),
            forwardAction(enabled: canGoForward)
        ]

        let iconName: String? = switch tabTrayButtonStyle {
        case .number, .none: StandardImageIdentifiers.Large.tab
        case .screenshot: nil
        }

        switch layout {
        case .version1, .none:
            actions.append(middleAction)
            actions.append(menuAction(iconName: StandardImageIdentifiers.Large.moreHorizontalRound,
                                      showWarningBadge: showWarningBadge))
            actions.append(tabsAction(iconName: iconName,
                                      numberOfTabs: numberOfTabs,
                                      isPrivateMode: toolbarState.isPrivateMode,
                                      previousTabScreenshot: previousTabScreenshot,
                                      nextTabScreenshot: nextTabScreenshot)
            )
        case .version2:
            actions.append(middleAction)
            actions.append(tabsAction(iconName: iconName,
                                      numberOfTabs: numberOfTabs,
                                      isPrivateMode: toolbarState.isPrivateMode,
                                      previousTabScreenshot: previousTabScreenshot,
                                      nextTabScreenshot: nextTabScreenshot)
            )
            actions.append(menuAction(iconName: StandardImageIdentifiers.Large.moreHorizontalRound,
                                      showWarningBadge: showWarningBadge))
        }

        return actions
    }

    private static func getMiddleButtonAction(url: URL?,
                                              isPrivateMode: Bool,
                                              middleButton: NavigationBarMiddleButtonType)
    -> ToolbarActionConfiguration {
        let customizedMiddleButton = switch middleButton {
        case .home: homeAction
        case .newTab: newTabAction
        }
        let middleActionForWebpage = customizedMiddleButton
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

    private static func tabsAction(iconName: String?,
                                   numberOfTabs: Int = 1,
                                   isPrivateMode: Bool = false,
                                   previousTabScreenshot: UIImage? = nil,
                                   nextTabScreenshot: UIImage? = nil) -> ToolbarActionConfiguration {
        let largeContentTitle = numberOfTabs > 99 ?
            .Toolbars.TabsButtonOverflowLargeContentTitle :
            String(format: .Toolbars.TabsButtonLargeContentTitle, NSNumber(value: numberOfTabs))

        return ToolbarActionConfiguration(
            actionType: .tabs,
            iconName: iconName,
            badgeImageName: isPrivateMode ? StandardImageIdentifiers.Medium.privateModeCircleFillPurple : nil,
            maskImageName: (isPrivateMode && iconName != nil) ? ImageIdentifiers.badgeMask : nil,
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            largeContentTitle: largeContentTitle,
            previousTabScreenshot: previousTabScreenshot,
            nextTabScreenshot: nextTabScreenshot,
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
