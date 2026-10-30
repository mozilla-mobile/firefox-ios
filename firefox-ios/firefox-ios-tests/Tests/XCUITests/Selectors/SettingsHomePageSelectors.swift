// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest

protocol SettingsHomepageSelectorsSet {
    var NAVBAR: Selector { get }
    var OPENING_SCREEN_SECTION: Selector { get }
    var INCLUDE_ON_HOMEPAGE_SECTION: Selector { get }
    var CURRENT_HOMEPAGE_SECTION: Selector { get }
    var START_AT_HOME_ALWAYS: Selector { get }
    var START_AT_HOME_DISABLED: Selector { get }
    var START_AT_HOME_AFTER_4H: Selector { get }
    var STORIES_SWITCH: Selector { get }
    var HOME_AS_FIREFOX_HOME: Selector { get }
    var HOME_AS_CUSTOM_URL: Selector { get }
    var all: [Selector] { get }
}

struct SettingsHomepageSelectors: SettingsHomepageSelectorsSet {
    private enum IDs {
        static let navBar          = AccessibilityIdentifiers.Settings.Homepage.homePageNavigationBar
        static let always          = AccessibilityIdentifiers.Settings.Homepage.StartAtHome.always
        static let disabled        = AccessibilityIdentifiers.Settings.Homepage.StartAtHome.disabled
        static let afterFourHours  = AccessibilityIdentifiers.Settings.Homepage.StartAtHome.afterFourHours
        // Mirrors PrefsKeys.UserFeatureFlagPrefs.ASPocketStories, used as the switch identifier
        static let storiesSwitch   = "ASPocketStoriesUserPrefsKey"
        static let firefoxHome     = "HomeAsFirefoxHome"
        static let customURL       = "HomeAsCustomURL"
        // Section headers have no accessibility identifier, they are matched on their uppercased title
        static let openingScreenSection     = "OPENING SCREEN"
        static let includeOnHomepageSection = "INCLUDE ON HOMEPAGE"
        static let currentHomepageSection   = "CURRENT HOMEPAGE"
    }

    let NAVBAR = Selector.navigationBarId(
        IDs.navBar,
        description: "Homepage settings navigation bar",
        groups: ["settings", "homepage"]
    )

    let OPENING_SCREEN_SECTION = Selector.tableOtherById(
        IDs.openingScreenSection,
        description: "Opening screen section header",
        groups: ["settings", "homepage"]
    )

    let INCLUDE_ON_HOMEPAGE_SECTION = Selector.tableOtherById(
        IDs.includeOnHomepageSection,
        description: "Include on homepage section header",
        groups: ["settings", "homepage"]
    )

    let CURRENT_HOMEPAGE_SECTION = Selector.tableOtherById(
        IDs.currentHomepageSection,
        description: "Current homepage section header",
        groups: ["settings", "homepage"]
    )

    let START_AT_HOME_ALWAYS = Selector.tableCellById(
        IDs.always,
        description: "Start at Home: Always cell",
        groups: ["settings", "homepage"]
    )

    let START_AT_HOME_DISABLED = Selector.tableCellById(
        IDs.disabled,
        description: "Start at Home: Disabled cell",
        groups: ["settings", "homepage"]
    )

    let START_AT_HOME_AFTER_4H = Selector.tableCellById(
        IDs.afterFourHours,
        description: "Start at Home: After Four Hours cell",
        groups: ["settings", "homepage"]
    )

    let STORIES_SWITCH = Selector.switchByIdOrLabel(
        IDs.storiesSwitch,
        description: "Stories switch",
        groups: ["settings", "homepage"]
    )

    let HOME_AS_FIREFOX_HOME = Selector.tableCellById(
        IDs.firefoxHome,
        description: "Firefox Home option of the current homepage section",
        groups: ["settings", "homepage"]
    )

    let HOME_AS_CUSTOM_URL = Selector.tableCellById(
        IDs.customURL,
        description: "Custom URL option of the current homepage section",
        groups: ["settings", "homepage"]
    )

    var all: [Selector] {
        [
            NAVBAR,
            OPENING_SCREEN_SECTION,
            INCLUDE_ON_HOMEPAGE_SECTION,
            CURRENT_HOMEPAGE_SECTION,
            START_AT_HOME_ALWAYS,
            START_AT_HOME_DISABLED,
            START_AT_HOME_AFTER_4H,
            STORIES_SWITCH,
            HOME_AS_FIREFOX_HOME,
            HOME_AS_CUSTOM_URL
        ]
    }
}
