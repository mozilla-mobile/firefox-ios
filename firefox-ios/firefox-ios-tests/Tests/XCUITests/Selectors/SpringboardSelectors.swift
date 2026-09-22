// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SpringboardSelectorsSet {
    var FENNEC_ICONS: Selector { get }
    var FIREFOX_ICON: Selector { get }
    var NEW_TAB_BUTTON: Selector { get }
    var NEW_PRIVATE_TAB_BUTTON: Selector { get }
    var OPEN_LAST_BOOKMARK_BUTTON: Selector { get }
    var APP_ICON_BUTTON: Selector { get }
    var NOTIFICATIONS_PERMISSION_ALERT: Selector { get }
    var ALLOW_NOTIFICATIONS_BUTTON: Selector { get }
    var DONT_ALLOW_NOTIFICATIONS_BUTTON: Selector { get }
    var FIREFOX_WIDGET: Selector { get }
    var SCREEN_TIME_ICON: Selector { get }
    var EDIT_HOME_SCREEN_BUTTON: Selector { get }
    var EDIT_BUTTON: Selector { get }
    var ADD_WIDGET_BUTTON: Selector { get }
    var CONFIRM_ADD_WIDGET_BUTTON: Selector { get }
    var SEARCH_WIDGETS_FIELD: Selector { get }
    var QUICK_ACTIONS_LABEL: Selector { get }
    var DONE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct SpringboardSelectors: SpringboardSelectorsSet {
    private enum IDs {
        static let fennecIconsPrefix = "Fennec "
        static let firefoxIcon = "Firefox"
        static let newTabButton = "New Tab"
        static let newPrivateTabButton = "New Private Tab"
        // Matched by identifier suffix so it works on every scheme's bundle id
        // (org.mozilla.ios.Fennec / .Firefox / .FirefoxBeta).
        static let openLastBookmarkSuffix = ".OpenLastBookmark"
        static let appIconButton = "App Icon"
        // The alert title is prefixed by the app name, so only the invariant part is matched.
        static let notificationsPermissionAlert = "Would Like to Send You Notifications"
        static let allowNotificationsButton = "Allow"
        static let dontAllowNotificationsButton = "Don’t Allow"
        // The home screen widget is labelled after the product, not the scheme.
        static let firefoxWidget = "Firefox"
        static let screenTimeIcon = "Screen Time"
        static let editHomeScreenButton = "Edit Home Screen"
        static let editButton = "Edit"
        static let addWidgetButton = "Add Widget"
        // The widget gallery's own confirm button carries a leading space in its label.
        static let confirmAddWidgetButton = " Add Widget"
        static let searchWidgetsField = "Search Widgets"
        static let quickActionsLabel = "Quick Actions"
        static let doneButton = "Done"
    }

    let FENNEC_ICONS = Selector(
        strategy: .predicate(
            NSPredicate(format: "identifier BEGINSWITH %@", IDs.fennecIconsPrefix)
        ),
        value: IDs.fennecIconsPrefix,
        description: "Fennec app icons on springboard",
        groups: ["springboard", "icons"]
    )

    let FIREFOX_ICON = Selector(
        strategy: .predicate(
            NSPredicate(format: "identifier BEGINSWITH %@", IDs.firefoxIcon)
        ),
        value: IDs.firefoxIcon,
        description: "Firefox app icons on springboard",
        groups: ["springboard", "icons"]
    )

    let NEW_TAB_BUTTON = Selector.buttonId(
        IDs.newTabButton,
        description: "New Tab button in springboard context menu",
        groups: ["springboard", "context-menu"]
    )

    let NEW_PRIVATE_TAB_BUTTON = Selector.buttonId(
        IDs.newPrivateTabButton,
        description: "New Private Tab button in springboard context menu",
        groups: ["springboard", "context-menu"]
    )

    let OPEN_LAST_BOOKMARK_BUTTON = Selector(
        strategy: .predicate(
            NSPredicate(
                format: "elementType == %d AND identifier ENDSWITH %@",
                XCUIElement.ElementType.button.rawValue,
                IDs.openLastBookmarkSuffix
            )
        ),
        value: IDs.openLastBookmarkSuffix,
        description: "Open Last Bookmark button in springboard context menu",
        groups: ["springboard", "context-menu"]
    )

    let APP_ICON_BUTTON = Selector.buttonId(
        IDs.appIconButton,
        description: "App Icon button in springboard context menu",
        groups: ["springboard", "context-menu"]
    )

    let NOTIFICATIONS_PERMISSION_ALERT = Selector.alertByTitle(
        IDs.notificationsPermissionAlert,
        description: "System alert asking for permission to send notifications",
        groups: ["springboard", "notifications"]
    )

    let ALLOW_NOTIFICATIONS_BUTTON = Selector.buttonId(
        IDs.allowNotificationsButton,
        description: "Allow button in the system notifications permission alert",
        groups: ["springboard", "notifications"]
    )

    let DONT_ALLOW_NOTIFICATIONS_BUTTON = Selector.buttonId(
        IDs.dontAllowNotificationsButton,
        description: "Don't Allow button in the system notifications permission alert",
        groups: ["springboard", "notifications"]
    )

    // The widget is labelled after the product on release schemes and after the scheme on Fennec.
    let FIREFOX_WIDGET = Selector.buttonLabelContainsEither(
        IDs.firefoxWidget,
        or: IDs.fennecIconsPrefix,
        description: "Firefox Quick Actions widget on the home screen",
        groups: ["springboard", "widget"]
    )

    let SCREEN_TIME_ICON = Selector.iconById(
        IDs.screenTimeIcon,
        description: "Screen Time icon, used as an anchor on the widget page",
        groups: ["springboard", "widget"]
    )

    let EDIT_HOME_SCREEN_BUTTON = Selector.buttonId(
        IDs.editHomeScreenButton,
        description: "Edit Home Screen button in the home screen context menu",
        groups: ["springboard", "widget"]
    )

    let EDIT_BUTTON = Selector.buttonId(
        IDs.editButton,
        description: "Edit button on the widget page",
        groups: ["springboard", "widget"]
    )

    let ADD_WIDGET_BUTTON = Selector.buttonId(
        IDs.addWidgetButton,
        description: "Add Widget button that opens the widget gallery",
        groups: ["springboard", "widget"]
    )

    let CONFIRM_ADD_WIDGET_BUTTON = Selector.buttonId(
        IDs.confirmAddWidgetButton,
        description: "Add Widget button that confirms the selected widget",
        groups: ["springboard", "widget"]
    )

    // The gallery's search field exposes "Search Widgets" as its label, not its identifier.
    let SEARCH_WIDGETS_FIELD = Selector.searchFieldByIdOrLabel(
        IDs.searchWidgetsField,
        description: "Search field in the widget gallery",
        groups: ["springboard", "widget"]
    )

    let QUICK_ACTIONS_LABEL = Selector.staticTextByLabel(
        IDs.quickActionsLabel,
        description: "Quick Actions widget name in the widget gallery",
        groups: ["springboard", "widget"]
    )

    let DONE_BUTTON = Selector.buttonId(
        IDs.doneButton,
        description: "Done button that leaves home screen edit mode",
        groups: ["springboard", "widget"]
    )

    var all: [Selector] {
        [
            FENNEC_ICONS,
            FIREFOX_ICON,
            APP_ICON_BUTTON,
            NEW_TAB_BUTTON,
            NEW_PRIVATE_TAB_BUTTON,
            OPEN_LAST_BOOKMARK_BUTTON,
            NOTIFICATIONS_PERMISSION_ALERT,
            ALLOW_NOTIFICATIONS_BUTTON,
            DONT_ALLOW_NOTIFICATIONS_BUTTON,
            FIREFOX_WIDGET,
            SCREEN_TIME_ICON,
            EDIT_HOME_SCREEN_BUTTON,
            EDIT_BUTTON,
            ADD_WIDGET_BUTTON,
            CONFIRM_ADD_WIDGET_BUTTON,
            SEARCH_WIDGETS_FIELD,
            QUICK_ACTIONS_LABEL,
            DONE_BUTTON
        ]
    }
}
