// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest

protocol SettingsHomepageSelectorsSet {
    var NAVBAR: Selector { get }
    var START_AT_HOME_ALWAYS: Selector { get }
    var START_AT_HOME_DISABLED: Selector { get }
    var START_AT_HOME_AFTER_4H: Selector { get }
    var STORIES_SWITCH: Selector { get }
    var all: [Selector] { get }
}

struct SettingsHomepageSelectors: SettingsHomepageSelectorsSet {
    private enum IDs {
        static let navBar          = AccessibilityIdentifiers.Settings.Homepage.homePageNavigationBar
        static let always          = AccessibilityIdentifiers.Settings.Homepage.StartAtHome.always
        static let disabled        = AccessibilityIdentifiers.Settings.Homepage.StartAtHome.disabled
        static let afterFourHours  = AccessibilityIdentifiers.Settings.Homepage.StartAtHome.afterFourHours
        static let storiesSwitch   = "Stories"
    }

    let NAVBAR = Selector.navigationBarId(
        IDs.navBar,
        description: "Homepage settings navigation bar",
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

    var all: [Selector] {
        [NAVBAR, START_AT_HOME_ALWAYS, START_AT_HOME_DISABLED, START_AT_HOME_AFTER_4H, STORIES_SWITCH]
    }
}
