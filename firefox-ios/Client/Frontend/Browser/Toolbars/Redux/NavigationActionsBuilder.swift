// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import UIKit

/// Builds the address bar's back/forward buttons, shown only when the navigation toolbar is hidden (compact layout)
/// and the navigation toolbar's actions (regular layout) when navigation bar and address bar are shown together
enum NavigationActionsBuilder {
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

    static func getActions(isShowingNavigationToolbar: Bool,
                           canGoBack: Bool,
                           canGoForward: Bool) -> [ToolbarActionConfiguration] {
        guard !isShowingNavigationToolbar else { return [] }
        return [
            backAction(enabled: canGoBack),
            forwardAction(enabled: canGoForward)
        ]
    }

    static func getNavigationToolbarActions(isHomepage: Bool,
                                            canGoBack: Bool,
                                            canGoForward: Bool,
                                            middleButton: NavigationBarMiddleButtonType,
                                            toolbarLayout: ToolbarLayoutStyle?,
                                            tabTrayButtonStyle: TabTrayButtonStyle?,
                                            numberOfTabs: Int,
                                            showWarningBadge: Bool,
                                            previousTabScreenshot: UIImage?,
                                            nextTabScreenshot: UIImage?,
                                            isPrivateMode: Bool,
                                            isNovaDesignEnabled: Bool) -> [ToolbarActionConfiguration] {
        let customizedMiddleButton = switch middleButton {
        case .home: homeAction
        case .newTab: newTabAction
        }
        let middleAction = isHomepage ? searchAction : customizedMiddleButton

        let iconName: String? = switch tabTrayButtonStyle {
        case .number, .none: StandardImageIdentifiers.Large.tab
        case .screenshot: nil
        }

        let menu = menuAction(iconName: StandardImageIdentifiers.Large.moreHorizontalRound,
                              showWarningBadge: showWarningBadge)
        let tabs = tabsAction(iconName: iconName,
                              numberOfTabs: numberOfTabs,
                              isPrivateMode: isPrivateMode,
                              isNovaDesignEnabled: isNovaDesignEnabled,
                              previousTabScreenshot: previousTabScreenshot,
                              nextTabScreenshot: nextTabScreenshot)

        let trailingActions = switch toolbarLayout {
        case .version1, .none: [menu, tabs]
        case .version2: [tabs, menu]
        }

        let actions = [backAction(enabled: canGoBack),
                       forwardAction(enabled: canGoForward),
                       middleAction] + trailingActions
        return actions
    }

    // MARK: - Helper
    static func backAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.chevronLeft,
            isFlippedForRTL: true,
            isEnabled: enabled,
            contextualHintType: ContextualHintType.navigation.rawValue,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    static func forwardAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.chevronRight,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }

    private static func menuAction(iconName: String, showWarningBadge: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .menu,
            iconName: iconName,
            badgeImageName: showWarningBadge ? StandardImageIdentifiers.Large.warningFill : nil,
            maskImageName: showWarningBadge ? ImageIdentifiers.menuWarningMask : nil,
            isEnabled: true,
            a11yLabel: .Toolbars.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }

    private static func tabsAction(iconName: String?,
                                   numberOfTabs: Int,
                                   isPrivateMode: Bool,
                                   isNovaDesignEnabled: Bool,
                                   previousTabScreenshot: UIImage?,
                                   nextTabScreenshot: UIImage?) -> ToolbarActionConfiguration {
        let largeContentTitle = numberOfTabs > 99 ?
            .Toolbars.TabsButtonOverflowLargeContentTitle :
            String(format: .Toolbars.TabsButtonLargeContentTitle, NSNumber(value: numberOfTabs))

        let isNovaPrivate = isPrivateMode && isNovaDesignEnabled
        let badgeImageName = isNovaPrivate
            ? StandardImageIdentifiers.Medium.privateModeCircleFillStrokeMulticolor
            : StandardImageIdentifiers.Medium.privateModeCircleFillPurple

        return ToolbarActionConfiguration(
            actionType: .tabs,
            iconName: iconName,
            badgeImageName: isPrivateMode ? badgeImageName : nil,
            maskImageName: (isPrivateMode && iconName != nil) ? ImageIdentifiers.badgeMask : nil,
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            largeContentTitle: largeContentTitle,
            previousTabScreenshot: previousTabScreenshot,
            nextTabScreenshot: nextTabScreenshot,
            a11yLabel: .Toolbars.TabsButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.tabsButton)
    }
}
