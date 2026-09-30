// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// TODO: Temporarily used in Reducer side will be moved to View side next
/// Builds the address bar's browser-wide actions (cancel/new tab/menu/tabs), shown alongside the
/// address bar. Every input is already resolved by `AddressBarState`, so there's nothing here to
/// persist across dispatches.
enum BrowserActionsBuilder {
    private static let cancelEditTextAction = ToolbarActionConfiguration(
        actionType: .cancelEdit,
        actionLabel: .CancelString, // Use .AddressToolbar.CancelEditButtonLabel starting v138 (localization)
        isFlippedForRTL: true,
        isEnabled: true,
        a11yLabel: .CancelString, // Use .AddressToolbar.CancelEditButtonLabel starting v138 (localization)
        a11yId: AccessibilityIdentifiers.Browser.UrlBar.cancelButton)

    private static let newTabAction = ToolbarActionConfiguration(
        actionType: .newTab,
        iconName: StandardImageIdentifiers.Large.plus,
        isEnabled: true,
        a11yLabel: .Toolbars.NewTabButton,
        a11yId: AccessibilityIdentifiers.Toolbar.addNewTabButton)

    static func getActions(isEditing: Bool,
                           isShowingNavigationToolbar: Bool,
                           isShowingTopTabs: Bool,
                           isHomepage: Bool,
                           toolbarLayout: ToolbarLayoutStyle?,
                           tabTrayButtonStyle: TabTrayButtonStyle?,
                           numberOfTabs: Int,
                           showWarningBadge: Bool,
                           previousTabScreenshot: UIImage?,
                           nextTabScreenshot: UIImage?,
                           isPrivateMode: Bool,
                           isNovaDesignEnabled: Bool) -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        if isEditing {
            // cancel button when in edit mode
            actions.append(cancelEditTextAction)
        }

        // In compact only cancel action should be shown
        guard !isShowingNavigationToolbar else {
            return actions
        }

        if !isShowingTopTabs, !isHomepage {
            actions.append(newTabAction)
        }

        let menuIcon = StandardImageIdentifiers.Large.moreHorizontalRound
        let iconName: String? = switch tabTrayButtonStyle {
        case .number, .none: StandardImageIdentifiers.Large.tab
        case .screenshot: nil
        }

        switch toolbarLayout {
        case .version1, .none:
            actions.append(
                contentsOf: [
                    menuAction(iconName: menuIcon, showWarningBadge: showWarningBadge),
                    tabsAction(
                        iconName: iconName,
                        numberOfTabs: numberOfTabs,
                        isPrivateMode: isPrivateMode,
                        isNovaDesignEnabled: isNovaDesignEnabled,
                        previousTabScreenshot: previousTabScreenshot,
                        nextTabScreenshot: nextTabScreenshot
                    )
                ]
            )
        case .version2:
            actions.append(
                contentsOf: [
                    tabsAction(
                        iconName: iconName,
                        numberOfTabs: numberOfTabs,
                        isPrivateMode: isPrivateMode,
                        isNovaDesignEnabled: isNovaDesignEnabled,
                        previousTabScreenshot: previousTabScreenshot,
                        nextTabScreenshot: nextTabScreenshot
                    ),
                    menuAction(iconName: menuIcon, showWarningBadge: showWarningBadge)
                ]
            )
        }

        return actions
    }

    // MARK: - Helper
    private static func menuAction(iconName: String, showWarningBadge: Bool = false) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .menu,
            iconName: iconName,
            badgeImageName: showWarningBadge ? StandardImageIdentifiers.Large.warningFill : nil,
            maskImageName: showWarningBadge ? ImageIdentifiers.menuWarningMask : nil,
            isEnabled: true,
            a11yLabel: .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }

    private static func tabsAction(
        iconName: String?,
        numberOfTabs: Int = 1,
        isPrivateMode: Bool = false,
        isNovaDesignEnabled: Bool = false,
        previousTabScreenshot: UIImage?,
        nextTabScreenshot: UIImage?)
    -> ToolbarActionConfiguration {
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
