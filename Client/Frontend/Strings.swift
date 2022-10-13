// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

// swiftlint:disable line_length
import Foundation

// MARK: - Localization bundle setup
class BundleClass {}

public struct Strings {
    public static let bundle = Bundle(for: BundleClass.self)
}

// MARK: - String last updated app version

// Used as a helper enum to keep track of what app version strings were last updated in. Updates
// are considered .unknown unless the string's Key is updated, or of course a new string is introduced.
private enum StringLastUpdatedAppVersion {
    case v39, v96, v97, v98, v99, v100, v101, v102, v103, v104, v105, v106, v107

    // Used for all cases before version 39.
    case unknown
}

// MARK: - Localization helper function
private func MZLocalizedString(_ key: String,
                               tableName: String? = nil,
                               value: String = "",
                               comment: String,
                               lastUpdated: StringLastUpdatedAppVersion
) -> String {
    return NSLocalizedString(key,
                             tableName: tableName,
                             bundle: Strings.bundle,
                             value: value,
                             comment: comment)
}

/// This file contains all strings for Firefox iOS.
///
/// As we continue to update strings, old strings may be present at the bottom of this
/// file. To preserve a clean implementation of strings, this file should be organized
/// alphabetically, according to specific screens or feature, on that screen. Each
/// string should be under a struct giving a clear indication as to where it is being
/// used. In this case we will prefer verbosity for the sake of accuracy, over brevity.
/// Sub structs may, and should, also be used to separate functionality where it makes
/// sense, but efforts should be made to keep structs two levels deep unless there are
/// good reasons for doing otherwise.
///
/// Note that some strings belong to one feature that appears across mulitple screens
/// throughout the application. An example is contextual hints. In this case, it makes
/// more sense to organize all those strings under the specific feature.

// MARK: - Alerts
extension String {
    public struct Alerts {

    }
}

// MARK: - Bookmarks Menu
extension String {
    public struct Bookmarks {

        public struct Menu {
            public static let DesktopBookmarks = MZLocalizedString(
                "Bookmarks.Menu.DesktopBookmarks",
                value: "Desktop Bookmarks",
                comment: "A label indicating all bookmarks grouped under the category 'Desktop Bookmarks'.",
                lastUpdated: .v96)
        }

    }
}

// MARK: - Browser View Controller
extension String {
    public struct BVC {
        public struct General {

        }

        public struct MenuItems {
            public struct Hamburger {

            }

            public struct LongPressGesture {

            }
        }
    }
}

// MARK: - Contextual Hints
extension String {
    public struct ContextualHints {

        public static let ContextualHintsCloseAccessibility = MZLocalizedString(
            "ContextualHintsCloseButtonAccessibility.v105",
            value: "Close",
            comment: "Accessibility label for action denoting closing contextual hint.",
            lastUpdated: .v105)

        public struct FirefoxHomepage {
            public struct JumpBackIn {
                public static let PersonalizedHomeOldCopy = MZLocalizedString(
                    "ContextualHints.FirefoxHomepage.JumpBackIn.PersonalizedHomeOldCopy.v106",
                    value: "Your personalized Firefox homepage now makes it easier to pick up where you left off. Find your recent tabs, bookmarks, and search results.",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. This one talks about the more personalized home feature.",
                    lastUpdated: .v106)
                public static let PersonalizedHome = MZLocalizedString(
                    "ContextualHints.FirefoxHomepage.JumpBackIn.PersonalizedHome",
                    tableName: "JumpBackIn",
                    value: "Meet your personalized homepage. Recent tabs, bookmarks, and search results will appear here.",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. This one talks about additions to the Firefox homepage regarding a more personalized experience.",
                    lastUpdated: .v106)
                public static let SyncedTab = MZLocalizedString(
                    "ContextualHints.FirefoxHomepage.JumpBackIn.SyncedTab.v106",
                    tableName: "JumpBackIn",
                    value: "Your tabs are syncing! Pick up where you left off on your other device.",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. When a user is logged in and has a tab synced from desktop, this popup indicates which tab that is within the Jump Back In section.",
                    lastUpdated: .v106)
            }
        }

        public struct TabsTray {
            public struct InactiveTabs {
                public static let Action = MZLocalizedString(
                    "ContextualHints.TabTray.InactiveTabs.CallToAction",
                    value: "Turn off in settings",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. This one is the call to action for the inactive tabs contextual popup.",
                    lastUpdated: .v39)
                public static let Body = MZLocalizedString(
                    "ContextualHints.TabTray.InactiveTabs",
                    value: "Tabs you haven’t viewed for two weeks get moved here.",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. This one talks about the inactive tabs feature.",
                    lastUpdated: .v39)
            }
        }

        public struct Toolbar {
            public static let SearchBarPlacementForNewUsers = MZLocalizedString(
                "ContextualHint.SearchBarPlacement.NewUsers",
                value: "To make entering info easier, the toolbar is now at the bottom by default.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one introduces search bar placement to new users. It tells them that by default, the search bar will appear at the bottom of the device.",
                lastUpdated: .v98)
            public static let SearchBarPlacementForExistingUsers = MZLocalizedString(
                "ContextualHint.SearchBarPlacement.ExistingUsers",
                value: "Now you can move the toolbar to the bottom, so it’s easier to enter info",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one introduces search bar placement to existing users. It tells them that the search bar can now be moved to the bottom of the screen.",
                lastUpdated: .v98)
            public static let SearchBarPlacementButtonText = MZLocalizedString(
                "ContextualHints.SearchBarPlacement.CallToAction",
                value: "Toolbar Settings",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one is a call to action for the popup describing search bar placement. It indicates a user can navigate to the settings page that allows them to customize the placement of the search bar.",
                lastUpdated: .v98)
            public static let SearchBarTopPlacement = MZLocalizedString(
                "ContextualHints.Toolbar.Top.Description.v107",
                tableName: "ToolbarLocation",
                value: "Move the toolbar to the bottom if that’s more your style.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one indicates a user can navigate to the Settings page to move the search bar to the bottom.",
                lastUpdated: .v107)
            public static let SearchBarBottomPlacement = MZLocalizedString(
                "ContextualHints.Toolbar.Bottom.Description.v107",
                tableName: "ToolbarLocation",
                value: "Move the toolbar to the top if that’s more your style.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one indicates a user can navigate to the Settings page to move the search bar to the top.",
                lastUpdated: .v107)
        }
    }
}

// MARK: - Enhanced Tracking Protection screen
extension String {
    public struct ETPMenu {

    }
}

// MARK: - Firefox Homepage
extension String {
    /// Identifiers of all new strings should begin with `FirefoxHome.`
    public struct FirefoxHomepage {

        public struct Common {
            public static let SitesCount = MZLocalizedString(
                "FirefoxHomepage.Common.SitesCount.v101",
                value: "Sites: %d",
                comment: "Label showing how many sites there is in a search group. %d represents a number",
                lastUpdated: .v101)
        }

        public struct CustomizeHomepage {
            public static let ButtonTitle = MZLocalizedString(
                "FirefoxHome.CustomizeHomeButton.Title",
                value: "Customize Homepage",
                comment: "A button at bottom of the Firefox homepage that, when clicked, takes users straight to the settings options, where they can customize the Firefox Home page",
                lastUpdated: .v39)
        }

        public struct HomeTabBanner {
            public struct EvergreenMessage {
                public static let HomeTabBannerTitle = MZLocalizedString(
                    "DefaultBrowserCard.Title",
                    tableName: "Default Browser",
                    value: "Switch Your Default Browser",
                    comment: "Title for small home tab banner shown that allows user to switch their default browser to Firefox.",
                    lastUpdated: .unknown)
                public static let HomeTabBannerDescription = MZLocalizedString(
                    "DefaultBrowserCard.Description",
                    tableName: "Default Browser",
                    value: "Set links from websites, emails, and Messages to open automatically in Firefox.",
                    comment: "Description for small home tab banner shown that allows user to switch their default browser to Firefox.",
                    lastUpdated: .unknown)
                public static let HomeTabBannerButton = MZLocalizedString(
                    "DefaultBrowserCard.Button.v2",
                    tableName: "Default Browser",
                    value: "Learn How",
                    comment: "Button string to learn how to set your default browser.",
                    lastUpdated: .unknown)
                public static let HomeTabBannerCloseAccessibility = MZLocalizedString(
                    "DefaultBrowserCloseButtonAccessibility.v102",
                    value: "Close",
                    comment: "Accessibility label for action denoting closing default browser home tab banner.",
                    lastUpdated: .v102)
            }
        }

        public struct JumpBackIn {
            public static let GroupSiteCount = MZLocalizedString(
                "ActivityStream.JumpBackIn.TabGroup.SiteCount",
                value: "Tabs: %d",
                comment: "On the Firefox homepage in the Jump Back In section, if a Tab group item - a collection of grouped tabs from a related search - exists underneath the search term for the tab group, there will be a subtitle with a number for how many tabs are in that group. The placeholder is for a number. It will read 'Tabs: 5' or similar.",
                lastUpdated: .v39)
            public static let SyncedTabTitle = MZLocalizedString(
                "FirefoxHomepage.JumpBackIn.TabPickup.v104",
                value: "Tab pickup",
                comment: "If a user is signed in, and a sync has been performed to collect their recent tabs from other signed in devices, their most recent tab from another device can now appear in the Jump Back In section. This label specifically points out which cell inside the Jump Back In section shows that synced tab.",
                lastUpdated: .v104)
            public static let SyncedTabShowAllButtonTitle = MZLocalizedString(
                "FirefoxHomepage.JumpBackIn.TabPickup.ShowAll.ButtonTitle.v104",
                value: "See all synced tabs",
                comment: "Button title shown for tab pickup on the Firefox homepage in the Jump Back In section.",
                lastUpdated: .v104)
            public static let SyncedTabOpenTabA11y = MZLocalizedString(
                "FirefoxHomepage.JumpBackIn.TabPickup.OpenTab.A11y.v106",
                value: "Open synced tab",
                comment: "Accessibility action title to open the synced tab for tab pickup on the Firefox homepage in the Jump Back In section.",
                lastUpdated: .v106)
        }

        public struct Pocket {
            public static let SectionTitle = MZLocalizedString(
                "FirefoxHome.Pocket.SectionTitle",
                value: "Thought-Provoking Stories",
                comment: "This is the title of the Pocket section on Firefox Homepage.",
                lastUpdated: .v98)
            public static let DiscoverMore = MZLocalizedString(
                "FirefoxHome.Pocket.DiscoverMore",
                value: "Discover more",
                comment: "At the end of the Pocket section on the Firefox Homepage, this button appears and indicates tapping it will navigate the user to more Pocket Stories.",
                lastUpdated: .v98)
            public static let NumberOfMinutes = MZLocalizedString(
                "FirefoxHome.Pocket.Minutes.v99",
                value: "%d min",
                comment: "On each Pocket Stories on the Firefox Homepage, this label appears and indicates the number of minutes to read an article. Minutes should be abbreviated due to space constraints. %d represents the number of minutes",
                lastUpdated: .v99)
            public static let Sponsored = MZLocalizedString(
                "FirefoxHomepage.Pocket.Sponsored.v103",
                value: "Sponsored",
                comment: "This string will show under the description on pocket story, indicating that the story is sponsored.",
                lastUpdated: .v103)
        }

        public struct RecentlySaved {

        }

        public struct HistoryHighlights {
            public static let Title = MZLocalizedString(
                "ActivityStream.RecentHistory.Title",
                value: "Recently Visited",
                comment: "Section title label for recently visited websites",
                lastUpdated: .v96)
            public static let Remove = MZLocalizedString(
                "FirefoxHome.RecentHistory.Remove",
                value: "Remove",
                comment: "When a user taps and holds on an item from the Recently Visited section, this label will appear indicating the option to remove that item.",
                lastUpdated: .v98)
        }

        public struct Shortcuts {
            public static let Sponsored = MZLocalizedString(
                "FirefoxHomepage.Shortcuts.Sponsored.v100",
                value: "Sponsored",
                comment: "This string will show under a shortcuts tile on the firefox home page, indicating that the tile is a sponsored tile. Space is limited, please keep as short as possible.",
                lastUpdated: .v100)
        }

        public struct YourLibrary {

        }

        public struct ContextualMenu {
            public static let Settings = MZLocalizedString(
                "FirefoxHomepage.ContextualMenu.Settings.v101",
                value: "Settings",
                comment: "The title for the Settings context menu action for sponsored tiles in the Firefox home page shortcuts section. Clicking this brings the users to the Shortcuts Settings.",
                lastUpdated: .v101)
            public static let SponsoredContent = MZLocalizedString(
                "FirefoxHomepage.ContextualMenu.SponsoredContent.v101",
                value: "Our Sponsors & Your Privacy",
                comment: "The title for the Sponsored Content context menu action for sponsored tiles in the Firefox home page shortcuts section. Clicking this brings the users to a support page where users can learn more about Sponsored content and how it works.",
                lastUpdated: .v101)
        }
    }
}

// MARK: - Keyboard shortcuts/"hotkeys"
extension String {
    /// Identifiers of all new strings should begin with `Keyboard.Shortcuts.`
    public struct KeyboardShortcuts {
        public static let ActualSize = MZLocalizedString(
            "Keyboard.Shortcuts.ActualSize",
            value: "Actual Size",
            comment: "A label indicating the keyboard shortcut of resetting a web page's view to the standard viewing size. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let AddBookmark = MZLocalizedString(
            "Keyboard.Shortcuts.AddBookmark",
            value: "Add Bookmark",
            comment: "A label indicating the keyboard shortcut of adding the currently viewing web page as a bookmark. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let Back = MZLocalizedString(
            "Hotkeys.Back.DiscoveryTitle",
            value: "Back",
            comment: "A label indicating the keyboard shortcut to navigate backwards, through session history, inside the current tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ClearRecentHistory = MZLocalizedString(
            "Keyboard.Shortcuts.ClearRecentHistory",
            value: "Clear Recent History",
            comment: "A label indicating the keyboard shortcut of clearing recent history. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let CloseAllTabsInTabTray = MZLocalizedString(
            "TabTray.CloseAllTabs.KeyCodeTitle",
            value: "Close All Tabs",
            comment: "A label indicating the keyboard shortcut of closing all tabs from the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let CloseCurrentTab = MZLocalizedString(
            "Hotkeys.CloseTab.DiscoveryTitle",
            value: "Close Tab",
            comment: "A label indicating the keyboard shortcut of closing the current tab a user is in. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let Find = MZLocalizedString(
            "Hotkeys.Find.DiscoveryTitle",
            value: "Find",
            comment: "A label indicating the keyboard shortcut of finding text a user desires within a page. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let FindAgain = MZLocalizedString(
            "Keyboard.Shortcuts.FindAgain",
            value: "Find Again",
            comment: "A label indicating the keyboard shortcut of finding text a user desires within a page again. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let Forward = MZLocalizedString(
            "Hotkeys.Forward.DiscoveryTitle",
            value: "Forward",
            comment: "A label indicating the keyboard shortcut of switching to a subsequent tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let NewPrivateTab = MZLocalizedString(
            "Hotkeys.NewPrivateTab.DiscoveryTitle",
            value: "New Private Tab",
            comment: "A label indicating the keyboard shortcut of creating a new private tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let NewTab = MZLocalizedString(
            "Hotkeys.NewTab.DiscoveryTitle",
            value: "New Tab",
            comment: "A label indicating the keyboard shortcut of creating a new tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let NormalBrowsingMode = MZLocalizedString(
            "Hotkeys.NormalMode.DiscoveryTitle",
            value: "Normal Browsing Mode",
            comment: "A label indicating the keyboard shortcut of switching from Private Browsing to Normal Browsing Mode. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let OpenNewTabInTabTray = MZLocalizedString(
            "TabTray.OpenNewTab.KeyCodeTitle",
            value: "Open New Tab",
            comment: "A label indicating the keyboard shortcut of opening a new tab in the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let PrivateBrowsingMode = MZLocalizedString(
            "Hotkeys.PrivateMode.DiscoveryTitle",
            value: "Private Browsing Mode",
            comment: "A label indicating the keyboard shortcut of switching from Normal Browsing mode to Private Browsing Mode. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ReloadPage = MZLocalizedString(
            "Hotkeys.Reload.DiscoveryTitle",
            value: "Reload Page",
            comment: "A label indicating the keyboard shortcut of reloading the current page. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let SelectLocationBar = MZLocalizedString(
            "Hotkeys.SelectLocationBar.DiscoveryTitle",
            value: "Select Location Bar",
            comment: "A label indicating the keyboard shortcut of directly accessing the URL, location, bar. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let Settings = MZLocalizedString(
            "Keyboard.Shortcuts.Settings",
            value: "Settings",
            comment: "A label indicating the keyboard shortcut of opening the application's settings menu. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ShowBookmarks = MZLocalizedString(
            "Keyboard.Shortcuts.ShowBookmarks",
            value: "Show Bookmarks",
            comment: "A label indicating the keyboard shortcut of showing all bookmarks. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ShowDownloads = MZLocalizedString(
            "Keyboard.Shortcuts.ShowDownloads",
            value: "Show Downloads",
            comment: "A label indcating the keyboard shortcut of showing all downloads. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ShowFirstTab = MZLocalizedString(
            "Keyboard.Shortcuts.ShowFirstTab",
            value: "Show First Tab",
            comment: "A label indicating the keyboard shortcut to switch from the current tab to the first tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ShowHistory = MZLocalizedString(
            "Keyboard.Shortcuts.ShowHistory",
            value: "Show History",
            comment: "A label indicating the keyboard shortcut of showing all history. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ShowLastTab = MZLocalizedString(
            "Keyboard.Shortcuts.ShowLastTab",
            value: "Show Last Tab",
            comment: "A label indicating the keyboard shortcut switch from your current tab to the last tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ShowNextTab = MZLocalizedString(
            "Hotkeys.ShowNextTab.DiscoveryTitle",
            value: "Show Next Tab",
            comment: "A label indicating the keyboard shortcut of switching to a subsequent tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ShowPreviousTab = MZLocalizedString(
            "Hotkeys.ShowPreviousTab.DiscoveryTitle",
            value: "Show Previous Tab",
            comment: "A label indicating the keyboard shortcut of switching to a tab immediately preceding to the currently selected tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ShowTabTray = MZLocalizedString(
            "Tab.ShowTabTray.KeyCodeTitle",
            value: "Show All Tabs",
            comment: "A label indicating the keyboard shortcut of showing the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ZoomIn = MZLocalizedString(
            "Keyboard.Shortcuts.ZoomIn",
            value: "Zoom In",
            comment: "A label indicating the keyboard shortcut of enlarging the view of the current web page. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)
        public static let ZoomOut = MZLocalizedString(
            "Keyboard.Shortcuts.ZoomOut",
            value: "Zoom Out",
            comment: "A label indicating the keyboard shortcut of shrinking the view of the current web page. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
            lastUpdated: .v96)

        public struct Sections {
            public static let Bookmarks = MZLocalizedString(
                "Keyboard.Shortcuts.Section.Bookmark",
                value: "Bookmarks",
                comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with Bookmarks. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
                lastUpdated: .v96)
            public static let History = MZLocalizedString(
                "Keyboard.Shortcuts.Section.History",
                value: "History",
                comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with History. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
                lastUpdated: .v96)
            public static let Tools = MZLocalizedString(
                "Keyboard.Shortcuts.Section.Tools",
                value: "Tools",
                comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with locally saved items. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
                lastUpdated: .v96)
            public static let Window = MZLocalizedString(
                "Keyboard.Shortcuts.Section.Window",
                value: "Window",
                comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can take when navigating between their availale set of tabs. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.",
                lastUpdated: .v96)
        }

    }
}

// MARK: - Library Panel
extension String {
    /// Identifiers of all new strings should begin with `LibraryPanel.{PanelName}.`
    public struct LibraryPanel {

        public struct Sections {
            public static let Today = MZLocalizedString(
                "Today",
                value: "Today",
                comment: "This label is meant to signify the section containing a group of items from the current day.",
                lastUpdated: .unknown)
            public static let Yesterday = MZLocalizedString(
                "Yesterday",
                value: "Yesterday",
                comment: "This label is meant to signify the section containing a group of items from the past 24 hours.",
                lastUpdated: .unknown)
            public static let LastWeek = MZLocalizedString(
                "Last week",
                value: "Last week",
                comment: "This label is meant to signify the section containing a group of items from the past seven days.",
                lastUpdated: .unknown)
            public static let LastMonth = MZLocalizedString(
                "Last month",
                value: "Last month",
                comment: "This label is meant to signify the section containing a group of items from the past thirty days.",
                lastUpdated: .unknown)
            public static let Older = MZLocalizedString(
                "LibraryPanel.Section.Older",
                value: "Older",
                comment: "This label is meant to signify the section containing a group of items that are older than thirty days.",
                lastUpdated: .v96)
        }

        public struct Bookmarks {

        }

        public struct History {
            public static let HistoryPanelClearHistoryButtonTitle = MZLocalizedString(
                "HistoryPanel.ClearHistoryButtonTitle",
                value: "Clear Recent History…",
                comment: "Title for button in the history panel to clear recent history",
                lastUpdated: .unknown)
            public static let SearchHistoryPlaceholder = MZLocalizedString(
                "LibraryPanel.History.SearchHistoryPlaceholder.v99",
                value: "Enter search terms",
                comment: "In the history panel, users will be able to search terms in their browsing history. This placeholder text inside the search component will indicate that a user can search through their browsing history.",
                lastUpdated: .v99)
            public static let NoHistoryResult = MZLocalizedString(
                "LibraryPanel.History.NoHistoryFound.v99",
                value: "No history found",
                comment: "In the history panel, users will be able to search terms in their browsing history. This label is shown when there is no results after querying the search terms in the user's history.",
                lastUpdated: .v99)
            public static let RecentlyClosedTabs = MZLocalizedString(
                "LibraryPanel.History.RecentlyClosedTabs.v99",
                value: "Recently Closed Tabs",
                comment: "In the history panel, this is the title on the button that navigates the user to a screen showing their recently closed tabs.",
                lastUpdated: .v99)
            public static let RecentlyClosedTabsButtonTitle = MZLocalizedString(
                "HistoryPanel.RecentlyClosedTabsButton.Title",
                value: "Recently Closed",
                comment: "Title for the Recently Closed button in the History Panel",
                lastUpdated: .unknown)
            public static let SyncedHistory = MZLocalizedString(
                "LibraryPanel.History.SyncedHistory.v100",
                value: "Synced History",
                comment: "Within the History Panel, users can see the option of viewing their history from synced tabs.",
                lastUpdated: .v100)
            public static let ClearHistoryMenuTitle = MZLocalizedString(
                "LibraryPanel.History.ClearHistoryMenuTitle.v100",
                value: "Removes history (including history synced from other devices), cookies and other browsing data.",
                comment: "Within the History Panel, users can open an action menu to clear recent history.",
                lastUpdated: .v100)
            public static let ClearGroupedTabsTitle = MZLocalizedString(
                "LibraryPanel.History.ClearGroupedTabsTitle.v100",
                value: "Delete all sites in %@?",
                comment: "Within the History Panel, users can delete search group sites history. %@ represents the search group name.",
                lastUpdated: .v100)
            public static let ClearGroupedTabsCancel = MZLocalizedString(
                "LibraryPanel.History.ClearGroupedTabsCancel.v100",
                value: "Cancel",
                comment: "Within the History Panel, users can delete search group sites history. They can cancel this action by pressing a cancel button.",
                lastUpdated: .v100)
            public static let ClearGroupedTabsDelete = MZLocalizedString(
                "LibraryPanel.History.ClearGroupedTabsDelete.v100",
                value: "Delete",
                comment: "Within the History Panel, users can delete search group sites history. They need to confirm the action by pressing the delete button.",
                lastUpdated: .v100)
            public static let Delete = MZLocalizedString(
                "LibraryPanel.History.DeleteGroupedItem.v104",
                value: "Delete",
                comment: "Within the history panel, a user can navigate into a screen with only grouped history items. Within that screen, a user can now swipe to delete a single item in the list. This label informs the user of a deletion action on the item.",
                lastUpdated: .v104)
        }

        public struct ReadingList {

        }

        public struct Downloads {

        }
    }
}

// MARK: - Onboarding screens
extension String {
    public struct Onboarding {
        public static let IntroDescriptionPart1 = MZLocalizedString(
            "Onboarding.IntroDescriptionPart1.v102",
            value: "Indie. Non-profit. For good.",
            comment: "String used to describes what Firefox is on the first onboarding page in our Onboarding screens. Indie means small independant.",
            lastUpdated: .v102)
        public static let IntroDescriptionPart2 = MZLocalizedString(
            "Onboarding.IntroDescriptionPart2.v102",
            value: "Committed to the promise of a better Internet for everyone.",
            comment: "String used to describes what Firefox is on the first onboarding page in our Onboarding screens.",
            lastUpdated: .v102)
        public static let IntroAction = MZLocalizedString(
            "Onboarding.IntroAction.v102",
            value: "Get Started",
            comment: "Describes the action on the first onboarding page in our Onboarding screen. This string will be on a button so user can continue the onboarding.",
            lastUpdated: .v102)
        public static let WallpaperTitle = MZLocalizedString(
            "Onboarding.WallpaperTitle.v102",
            value: "Choose a Firefox Wallpaper",
            comment: "Title for the wallpaper onboarding page in our Onboarding screens. This describes to the user that they can choose different wallpapers.",
            lastUpdated: .v102)
        public static let WallpaperAction = MZLocalizedString(
            "Onboarding.WallpaperAction.v102",
            value: "Set Wallpaper",
            comment: "Description for the wallpaper onboarding page in our Onboarding screens. This describes to the user that they can set a wallpaper.",
            lastUpdated: .v102)
        public static let LaterAction = MZLocalizedString(
            "Onboarding.LaterAction.v102",
            value: "Not Now",
            comment: "Describes an action on some of the Onboarding screen, including the wallpaper onboarding screen. This string will be on a button so user can skip that onboarding page.",
            lastUpdated: .v102)
        public static let SyncTitle = MZLocalizedString(
            "Onboarding.SyncTitle.v102",
            value: "Sync to Stay In Your Flow",
            comment: "Title for the sync onboarding page in our Onboarding screens. The user will be able to setup their Firefox sync account from that screen. 'Stay in the flow' means that a person is fully immersed in an activity. The user will sync with their Firefox sync account to stay connected and immersed in the activity they are doing.",
            lastUpdated: .v102)
        public static let SyncDescription = MZLocalizedString(
            "Onboarding.SyncDescription.v102",
            value: "Automatically sync tabs and bookmarks across devices for seamless screen-hopping.",
            comment: "Description for the sync onboarding page in our Onboarding screens. The user will be able to setup their Firefox sync account from that screen.",
            lastUpdated: .v102)
        public static let SyncAction = MZLocalizedString(
            "Onboarding.SyncAction.v102",
            value: "Sign Up and Log In",
            comment: "Describes an action on the sync onboarding page in our Onboarding screens. This string will be on a button so user can sign up or login directly in the onboarding.",
            lastUpdated: .v102)
        public static let IntroWelcomeTitle = MZLocalizedString(
            "Onboarding.Welcome.Title.v106",
            value: "Welcome to an independent internet",
            comment: "String used to describes the title of what Firefox is on the welcome onboarding page for 106 version in our Onboarding screens.",
            lastUpdated: .v106)
        public static let IntroWelcomeDescription = MZLocalizedString(
            "Onboarding.Welcome.Description.v106",
            value: "Firefox puts people over profits and defends your privacy by default.",
            comment: "String used to describes the description of what Firefox is on the welcome onboarding page for 106 version in our Onboarding screens.",
            lastUpdated: .v106)
        public static let IntroSyncTitle = MZLocalizedString(
            "Onboarding.Sync.Title.v106",
            value: "Hop from phone to laptop and back",
            comment: "String used to describes the title of what Firefox is on the Sync onboarding page for 106 version in our Onboarding screens.",
            lastUpdated: .v106)
        public static let IntroSyncDescription = MZLocalizedString(
            "Onboarding.Sync.Description.v106",
            value: "Grab tabs and passwords from your other devices to pick up where you left off.",
            comment: "String used to describes the description of what Firefox is on the Sync onboarding page for 106 version in our Onboarding screens.",
            lastUpdated: .v106)
        public static let IntroSyncSkipAction = MZLocalizedString(
            "Onboarding.Sync.Skip.Action.v106",
            value: "Skip",
            comment: "String used to describes the option to skip the Sync sign in during onboarding for 106 version in Firefox Onboarding screens.",
            lastUpdated: .v106)
        public static let WallpaperSelectorTitle = MZLocalizedString(
            "Onboarding.Wallpaper.Title.v106",
            value: "Try a splash of color",
            comment: "Title for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that they can choose different wallpapers.",
            lastUpdated: .v106)
        public static let WallpaperSelectorDescription = MZLocalizedString(
            "Onboarding.Wallpaper.Description.v106",
            value: "Choose a wallpaper that speaks to you.",
            comment: "Description for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that they can choose different wallpapers.",
            lastUpdated: .v106)
        public static let WallpaperSelectorAction = MZLocalizedString(
            "Onboarding.Wallpaper.Action.v106",
            value: "Explore more wallpapers",
            comment: "Description for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that they can set a wallpaper.",
            lastUpdated: .v106)
        public static let ClassicWallpaper = MZLocalizedString(
            "Onboarding.Wallpaper.Accessibility.Classic.v106",
            value: "Classic Wallpaper",
            comment: "Accessibility label for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that which type of wallpaper they are seeing.",
            lastUpdated: .v106)
        public static let LimitedEditionWallpaper = MZLocalizedString(
            "Onboarding.Wallpaper.Accessibility.LimitedEdition.v106",
            value: "Limited Edition Wallpaper",
            comment: "Accessibility label for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that which type of wallpaper they are seeing.",
            lastUpdated: .v106)
    }
}

// MARK: - Upgrade CoverSheet
extension String {
    public struct Upgrade {
        public static let WelcomeTitle = MZLocalizedString(
            "Upgrade.Welcome.Title.v106",
            value: "Welcome to a more personal internet",
            comment: "Title string used to welcome back users in the Upgrade screens. This screen is shown after user upgrades Firefox version.",
            lastUpdated: .v106)
        public static let WelcomeDescription = MZLocalizedString(
            "Upgrade.Welcome.Description.v106",
            value: "New colors. New convenience. Same commitment to people over profits.",
            comment: "Description string used to welcome back users in the Upgrade screens. This screen is shown after user upgrades Firefox version.",
            lastUpdated: .v106)
        public static let WelcomeAction = MZLocalizedString(
            "Upgrade.Welcome.Action.v106",
            value: "Get Started",
            comment: "Describes the action on the first upgrade page in the Upgrade screen. This string will be on a button so user can continue the Upgrade.",
            lastUpdated: .v106)
        public static let SyncSignTitle = MZLocalizedString(
            "Upgrade.SyncSign.Title.v106",
            value: "Switching screens is easier than ever",
            comment: "Title string used to sign in to sync in the Upgrade screens. This screen is shown after user upgrades Firefox version.",
            lastUpdated: .v106)
        public static let SyncSignDescription = MZLocalizedString(
            "Upgrade.SyncSign.Description.v106",
            value: "Pick up where you left off with tabs from other devices now on your homepage.",
            comment: "Description string used to to sign in to sync in the Upgrade screens. This screen is shown after user upgrades Firefox version.",
            lastUpdated: .v106)
        public static let SyncAction = MZLocalizedString(
            "Upgrade.SyncSign.Action.v106",
            value: "Sign In",
            comment: "Describes an action on the sync upgrade page in our Upgrade screens. This string will be on a button so user can sign up or login directly in the upgrade.",
            lastUpdated: .v106)
    }
}

// MARK: - Passwords and Logins
extension String {
    public struct PasswordsAndLogins {

    }
}

// MARK: - Search
extension String {
    public struct Search {
        public static let SuggestSectionTitle = MZLocalizedString(
            "Search.SuggestSectionTitle.v102",
            value: "Firefox Suggest",
            comment: "When making a new search from the awesome bar, suggestions appear to the user as they write new letters in their search. Different types of suggestions can appear. This string will be used as a header to separate Firefox suggestions from normal suggestions.",
            lastUpdated: .v102)
    }
}

// MARK: - Settings screen
extension String {
    public struct Settings {

        public struct About {
            public static let RateOnAppStore = MZLocalizedString(
                "Ratings.Settings.RateOnAppStore",
                value: "Rate on App Store",
                comment: "A label indicating the action that a user can rate the Firefox app in the App store.",
                lastUpdated: .v96)
        }

        public struct SectionTitles {
            public static let TabsTitle = MZLocalizedString(
                "Settings.Tabs.Title",
                value: "Tabs",
                comment: "In the settings menu, this is the title for the Tabs customization section option",
                lastUpdated: .v39)
        }

        public struct Homepage {

            public struct Current {
                public static let Description = MZLocalizedString(
                    "Settings.Home.Current.Description.v101",
                    value: "Choose what displays as the homepage.",
                    comment: "This is the description below the settings section located in the menu under customize current homepage. It describes what the options in the section are for.",
                    lastUpdated: .v101)
            }

            public struct CustomizeFirefoxHome {
                public static let JumpBackIn = MZLocalizedString(
                    "Settings.Home.Option.JumpBackIn",
                    value: "Jump Back In",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle the Jump Back In section on homepage on or off",
                    lastUpdated: .v39)
                public static let RecentlyVisited = MZLocalizedString(
                    "Settings.Home.Option.RecentlyVisited",
                    value: "Recently Visited",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Recently Visited section on the Firfox homepage on or off",
                    lastUpdated: .v39)
                public static let RecentlySaved = MZLocalizedString(
                    "Settings.Home.Option.RecentlySaved",
                    value: "Recently Saved",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Recently Saved section on the Firefox homepage on or off",
                    lastUpdated: .v39)
                public static let Shortcuts = MZLocalizedString(
                    "Settings.Home.Option.Shortcuts",
                    value: "Shortcuts",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Shortcuts section on the Firefox homepage on or off",
                    lastUpdated: .v39)
                public static let Pocket = MZLocalizedString(
                    "Settings.Home.Option.Pocket",
                    value: "Recommended by Pocket",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to turn the Pocket Recommendations section on the Firefox homepage on or off",
                    lastUpdated: .v39)
                public static let SponsoredPocket = MZLocalizedString(
                    "Settings.Home.Option.SponsoredPocket.v103",
                    value: "Sponsored stories",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to turn the Pocket Sponsored Stories on the Firefox homepage on or off",
                    lastUpdated: .v103)
                public static let Title = MZLocalizedString(
                    "Settings.Home.Option.Title.v101",
                    value: "Include on Homepage",
                    comment: "In the settings menu, this is the title of the Firefox Homepage customization settings section",
                    lastUpdated: .v101)
                public static let Description = MZLocalizedString(
                    "Settings.Home.Option.Description.v101",
                    value: "Choose what’s included on the Firefox homepage.",
                    comment: "In the settings menu, on the Firefox homepage customization section, this is the description below the section, describing what the options in the section are for.",
                    lastUpdated: .v101)
                public static let Wallpaper = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper",
                    value: "Wallpaper",
                    comment: "In the settings menu, on the Firefox homepage customization section, this is the title for the option that allows users to access the wallpaper settings for the application.",
                    lastUpdated: .v98)
            }

            public struct Shortcuts {
                public static let RowSettingFooter = MZLocalizedString(
                    "ActivityStream.TopSites.RowSettingFooter",
                    value: "Set Rows",
                    comment: "The title for the setting page which lets you select the number of top site rows",
                    lastUpdated: .unknown)
                public static let ToggleOn = MZLocalizedString(
                    "Settings.Homepage.Shortcuts.ToggleOn.v100",
                    value: "On",
                    comment: "Toggled ON to show the shortcuts section",
                    lastUpdated: .v100)
                public static let ToggleOff = MZLocalizedString(
                    "Settings.Homepage.Shortcuts.ToggleOff.v100",
                    value: "Off",
                    comment: "Toggled OFF to hide the shortcuts section",
                    lastUpdated: .v100)
                public static let ShortcutsPageTitle = MZLocalizedString(
                    "Settings.Homepage.Shortcuts.ShortcutsPageTitle.v100",
                    value: "Shortcuts",
                    comment: "Users can disable or enable shortcuts related settings. This string is the title of the page to change your shortcuts settings.",
                    lastUpdated: .v100)
                public static let ShortcutsToggle = MZLocalizedString(
                    "Settings.Homepage.Shortcuts.ShortcutsToggle.v100",
                    value: "Shortcuts",
                    comment: "This string is the title of the toggle to disable the shortcuts section in the settings page.",
                    lastUpdated: .v100)
                public static let SponsoredShortcutsToggle = MZLocalizedString(
                    "Settings.Homepage.Shortcuts.SponsoredShortcutsToggle.v100",
                    value: "Sponsored Shortcuts",
                    comment: "This string is the title of the toggle to disable the sponsored shortcuts functionnality which can be enabled in the shortcut sections. This toggle is in the settings page.",
                    lastUpdated: .v100)
                public static let Rows = MZLocalizedString(
                    "Settings.Homepage.Shortcuts.Rows.v100",
                    value: "Rows",
                    comment: "This string is the title of the setting button which can be clicked to open a page to customize the number of rows in the shortcuts section",
                    lastUpdated: .v100)
                public static let RowsPageTitle = MZLocalizedString(
                    "Settings.Homepage.Shortcuts.RowsPageTitle.v100",
                    value: "Rows",
                    comment: "This string is the title of the page to customize the number of rows in the shortcuts section",
                    lastUpdated: .v100)
            }

            public struct StartAtHome {
                public static let SectionTitle = MZLocalizedString(
                    "Settings.Home.Option.StartAtHome.Title",
                    value: "Opening screen",
                    comment: "Title for the section in the settings menu where users can configure the behaviour of the Start at Home feature on the Firefox Homepage.",
                    lastUpdated: .v39)
                public static let SectionDescription = MZLocalizedString(
                    "Settings.Home.Option.StartAtHome.Description",
                    value: "Choose what you see when you return to Firefox.",
                    comment: "In the settings menu, in the Start at Home customization options, this is text that appears below the section, describing what the section settings do.",
                    lastUpdated: .v39)
                public static let AfterFourHours = MZLocalizedString(
                    "Settings.Home.Option.StartAtHome.AfterFourHours",
                    value: "Homepage after four hours of inactivity",
                    comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the Homepage after four hours of inactivity.",
                    lastUpdated: .v39)
                public static let Always = MZLocalizedString(
                    "Settings.Home.Option.StartAtHome.Always",
                    value: "Homepage",
                    comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the Homepage every time they open up Firefox",
                    lastUpdated: .v39)
                public static let Never = MZLocalizedString(
                    "Settings.Home.Option.StartAtHome.Never",
                    value: "Last tab",
                    comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the last tab they were on, every time they open up Firefox",
                    lastUpdated: .v39)
            }

            public struct Wallpaper {
                public static let PageTitle = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.Title",
                    value: "Wallpaper",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of that screen, which allows users to change the wallpaper settings for the application.",
                    lastUpdated: .v98)
                public static let CollectionTitle = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.CollectionTitle",
                    value: "OPENING SCREEN",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of the section that allows users to change the wallpaper settings for the application.",
                    lastUpdated: .v98)
                public static let SwitchTitle = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.SwitchTitle.v99",
                    value: "Change wallpaper by tapping Firefox homepage logo",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the string titling the switch button's function, which allows a user to toggle wallpaper switching from the homepage logo on or off.",
                    lastUpdated: .v99)
                public static let WallpaperUpdatedToastLabel = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.UpdatedToast",
                    value: "Wallpaper Updated!",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of toast that comes up when the user changes wallpaper, which lets them know that the wallpaper has been updated.",
                    lastUpdated: .v98)
                public static let WallpaperUpdatedToastButton = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.UpdatedToastButton",
                    value: "View",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of the button found on the toast that comes up once the user changes wallpaper, and allows users to dismiss the settings page. In this case, consider View as a verb - the action of dismissing settings and seeing the wallpaper.",
                    lastUpdated: .v98)

                public static let ClassicWallpaper = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.Classic.Title.v106",
                    value: "Classic %@",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of the group of wallpapers that are always available to the user. The %@ will be replaced by the app name and thus doesn't need translation.",
                    lastUpdated: .v106)
                public static let LimitedEditionWallpaper = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.LimitedEdition.Title.v106",
                    value: "Limited Edition",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of the group of wallpapers that are seasonally available to the user.",
                    lastUpdated: .v106)
                public static let IndependentVoicesDescription = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.LimitedEdition.IndependentVoices.Description.v106",
                    value: "The new Independent Voices collection.",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the description of the group of wallpapers that are seasonally available to the user.",
                    lastUpdated: .v106)
                public static let LimitedEditionDefaultDescription = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.LimitedEdition.Default.Description.v106",
                    value: "Try the new collection.",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the default description of the group of wallpapers that are seasonally available to the user.",
                    lastUpdated: .v106)
                public static let LearnMoreButton = MZLocalizedString(
                    "Settings.Home.Option.Wallpaper.LearnMore.v106",
                    value: "Learn more",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the button title of the group of wallpapers that are seasonally available to the user.",
                    lastUpdated: .v106)

                // Accessibility
                public struct AccessibilityLabels {
                    public static let FxHomepageWallpaperButton = MZLocalizedString(
                        "FxHomepage.Wallpaper.ButtonLabel.v99",
                        value: "Firefox logo, change the wallpaper.",
                        comment: "On the firefox homepage, the string read by the voice over prompt for accessibility, for the button which changes the wallpaper",
                        lastUpdated: .v99)
                    public static let ToggleButton = MZLocalizedString(
                        "Settings.Home.Option.Wallpaper.Accessibility.ToggleButton",
                        value: "Homepage wallpaper cycle toggle",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the accessibility string of the toggle for turning wallpaper cycling shortcut on or off on the homepage.",
                        lastUpdated: .v98)
                    public static let DefaultWallpaper = MZLocalizedString(
                        "Settings.Home.Option.Wallpaper.Accessibility.DefaultWallpaper.v99",
                        value: "Default clear wallpaper.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the accessibility string for the default wallpaper.",
                        lastUpdated: .v99)
                    public static let FxAmethystWallpaper = MZLocalizedString(
                        "Settings.Home.Option.Wallpaper.Accessibility.AmethystWallpaper.v99",
                        value: "Firefox wallpaper, amethyst pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the accessibility string for the amethyst firefox wallpaper.",
                        lastUpdated: .v99)
                    public static let FxSunriseWallpaper = MZLocalizedString(
                        "Settings.Home.Option.Wallpaper.Accessibility.SunriseWallpaper.v99",
                        value: "Firefox wallpaper, sunrise pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title accessibility string for the sunrise firefox wallpaper.",
                        lastUpdated: .v99)
                    public static let FxCeruleanWallpaper = MZLocalizedString(
                        "Settings.Home.Option.Wallpaper.Accessibility.CeruleanWallpaper.v99",
                        value: "Firefox wallpaper, cerulean pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title accessibility string for the cerulean firefox wallpaper.",
                        lastUpdated: .v99)
                    public static let FxBeachHillsWallpaper = MZLocalizedString(
                        "Settings.Home.Option.Wallpaper.Accessibility.BeachHillsWallpaper.v100",
                        value: "Firefox wallpaper, beach hills pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title accessibility string for the beach hills firefox wallpaper.",
                        lastUpdated: .v100)
                    public static let FxTwilightHillsWallpaper = MZLocalizedString(
                        "Settings.Home.Option.Wallpaper.Accessibility.TwilightHillsWallpaper.v100",
                        value: "Firefox wallpaper, twilight hills pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title accessibility string for the twilight hills firefox wallpaper.",
                        lastUpdated: .v100)
                }
            }
        }

        public struct Tabs {
            public static let TabsSectionTitle = MZLocalizedString(
                "Settings.Tabs.CustomizeTabsSection.Title",
                value: "Customize Tab Tray",
                comment: "In the settings menu, in the Tabs customization section, this is the title for the Tabs Tray customization section. The tabs tray is accessed from firefox hompage",
                lastUpdated: .v39)
            public static let InactiveTabs = MZLocalizedString(
                "Settings.Tabs.CustomizeTabsSection.InactiveTabs",
                value: "Inactive Tabs",
                comment: "This is the description for the setting that toggles the Inactive Tabs feature in the settings menu under the Tabs customization section. Inactive tabs are a separate section of tabs that appears in the Tab Tray, which can be enabled or not",
                lastUpdated: .v39)
            public static let InactiveTabsDescription = MZLocalizedString(
                "Settings.Tabs.CustomizeTabsSection.InactiveTabsDescription.v101",
                value: "Tabs you haven’t viewed for two weeks get moved to the inactive section.",
                comment: "This is the description for the setting that toggles the Inactive Tabs feature in the settings menu under the Tabs customization section. Inactive tabs are a separate section of tabs that appears in the Tab Tray, which can be enabled or not",
                lastUpdated: .v101)
            public static let TabGroups = MZLocalizedString(
                "Settings.Tabs.CustomizeTabsSection.TabGroups",
                value: "Tab Groups",
                comment: "In the settings menu, in the Tabs customization section, this is the title for the setting that toggles the Tab Groups feature - where tabs from related searches are grouped - on or off",
                lastUpdated: .v39)
        }

        public struct Toolbar {
            public static let Toolbar = MZLocalizedString(
                "Settings.Toolbar.SettingsTitle",
                value: "Toolbar",
                comment: "In the settings menu, this label indicates that there is an option of customizing the Toolbar appearance.",
                lastUpdated: .v98)
            public static let Top = MZLocalizedString(
                "Settings.Toolbar.Top",
                value: "Top",
                comment: "In the settings menu, in the Toolbar customization section, this label indicates that selecting this will make the toolbar appear at the top of the screen.",
                lastUpdated: .v98)
            public static let Bottom = MZLocalizedString(
                "Settings.Toolbar.Bottom",
                value: "Bottom",
                comment: "In the settings menu, in the Toolbar customization section, this label indicates that selecting this will make the toolbar appear at the bottom of the screen.",
                lastUpdated: .v98)
        }

        public struct Toggle {
            public static let NoImageMode = MZLocalizedString(
                "Settings.NoImageModeBlockImages.Label.v99",
                value: "Block Images",
                comment: "Label for the block images toggle displayed in the settings menu. Enabling this toggle will hide images on any webpage the user visits.",
                lastUpdated: .v99)
        }

        public struct Passwords {
            public static let Title = MZLocalizedString(
                "Settings.Passwords.Title.v103",
                value: "Passwords",
                comment: "Title for the passwords screen.",
                lastUpdated: .v103)
            public static let SavePasswords = MZLocalizedString(
                "Settings.Passwords.SavePasswords.v103",
                value: "Save Passwords",
                comment: "Setting that appears in the Passwords screen to enable the built-in password manager so users can save their passwords.",
                lastUpdated: .v103)
            public static let OnboardingMessage = MZLocalizedString(
                "Settings.Passwords.OnboardingMessage.v103",
                value: "Your passwords are now protected by Face ID, Touch ID or a device passcode.",
                comment: "Message shown when you enter Passwords screen for the first time. It explains how password are protected in the Firefox for iOS application.",
                lastUpdated: .v103)
            public static let FingerPrintReason = MZLocalizedString(
                "Settings.Passwords.FingerPrintReason.v103",
                value: "Use your fingerprint to access passwords now.",
                comment: "Touch ID prompt subtitle when accessing logins and passwords",
                lastUpdated: .v103)
        }

        public struct Sync {
            public static let ButtonTitle = MZLocalizedString(
                "Settings.Sync.ButtonTitle.v103",
                value: "Sync and Save Data",
                comment: "Button label that appears in the settings to prompt the user to sign in to Firefox for iOS sync service to sync and save data.",
                lastUpdated: .v103)
            public static let ButtonDescription = MZLocalizedString(
                "Settings.Sync.ButtonDescription.v103",
                value: "Sign in to sync tabs, bookmarks, passwords, and more.",
                comment: "Ddescription that appears in the settings screen to explain what Firefox Sync is useful for.",
                lastUpdated: .unknown)

            public struct SignInView {
                public static let Title = MZLocalizedString(
                    "Settings.Sync.SignInView.Title.v103",
                    value: "Sync and Save Data",
                    comment: "Title for the page where the user sign in to their Firefox Sync account.",
                    lastUpdated: .v103)
            }

        }
    }
}

// MARK: - Share Sheet
extension String {
    public struct ShareSheet {

    }
}

// MARK: - Switch Default Browser Screen
extension String {
    public struct SwitchDefaultBrowser {

    }
}

// MARK: - Sync Screen
extension String {
    public struct SyncScreen {

    }
}

// MARK: Tabs Tray
extension String {
    public struct TabsTray {

        public struct InactiveTabs {
            public static let TabsTrayInactiveTabsSectionClosedAccessibilityTitle = MZLocalizedString(
                "TabsTray.InactiveTabs.SectionTitle.Closed.Accessibility.v103",
                value: "View Inactive Tabs",
                comment: "Accessibility title for the inactive tabs section button when section is closed. This section groups all tabs that haven't been used in a while.",
                lastUpdated: .v103)
            public static let TabsTrayInactiveTabsSectionOpenedAccessibilityTitle = MZLocalizedString(
                "TabsTray.InactiveTabs.SectionTitle.Opened.Accessibility.v103",
                value: "Hide Inactive Tabs",
                comment: "Accessibility title for the inactive tabs section button when section is open. This section groups all tabs that haven't been used in a while.",
                lastUpdated: .v103)
            public static let CloseAllInactiveTabsButton = MZLocalizedString(
                "InactiveTabs.TabTray.CloseButtonTitle",
                value: "Close All Inactive Tabs",
                comment: "In the Tabs Tray, in the Inactive Tabs section, this is the button the user must tap in order to close all inactive tabs.",
                lastUpdated: .v39)
        }
    }
}

// MARK: - What's New
extension String {
    /// The text for the What's New onboarding card
    public struct WhatsNew {
        public static let RecentButtonTitle = MZLocalizedString(
            "Onboarding.WhatsNew.Button.Title",
            value: "Start Browsing",
            comment: "On the onboarding card letting users know what's new in this version of Firefox, this is the title for the button, on the bottom of the card, used to get back to browsing on Firefox by dismissing the onboarding card",
            lastUpdated: .v39)
    }
}

// MARK: - Strings: unorganized & unchecked for use
// Here we have the original strings. What follows below is unorganized. As
// the team continues to work on new updates to strings, or to work on a view,
// these strings should be checked if in use, still. If not, they should be
// removed; if used, they should be added to the organized section of this
// file, for easier classification and use.

// MARK: - General
extension String {
    public static let OKString = MZLocalizedString(
        "OK",
        comment: "OK button",
        lastUpdated: .unknown)
    public static let CancelString = MZLocalizedString(
        "Cancel",
        comment: "Label for Cancel button",
        lastUpdated: .unknown)
    public static let NotNowString = MZLocalizedString(
        "Toasts.NotNow",
        value: "Not Now",
        comment: "label for Not Now button",
        lastUpdated: .unknown)
    public static let AppStoreString = MZLocalizedString(
        "Toasts.OpenAppStore",
        value: "Open App Store",
        comment: "Open App Store button",
        lastUpdated: .unknown)
    public static let UndoString = MZLocalizedString(
        "Toasts.Undo",
        value: "Undo",
        comment: "Label for button to undo the action just performed",
        lastUpdated: .unknown)
    public static let OpenSettingsString = MZLocalizedString(
        "Open Settings",
        comment: "See http://mzl.la/1G7uHo7",
        lastUpdated: .unknown)
}

// MARK: - Top Sites
extension String {
    public static let TopSitesRemoveButtonAccessibilityLabel = MZLocalizedString(
        "TopSites.RemovePage.Button",
        value: "Remove page — %@",
        comment: "Button shown in editing mode to remove this site from the top sites panel.",
        lastUpdated: .unknown)
}

// MARK: - Activity Stream
extension String {
    public static let ASShortcutsTitle =  MZLocalizedString(
        "ActivityStream.Shortcuts.SectionTitle",
        value: "Shortcuts",
        comment: "Section title label for Shortcuts",
        lastUpdated: .unknown)
    public static let RecentlySavedSectionTitle = MZLocalizedString(
        "ActivityStream.Library.Title",
        value: "Recently Saved",
        comment: "A string used to signify the start of the Recently Saved section in Home Screen.",
        lastUpdated: .unknown)
    public static let RecentlySavedShowAllText = MZLocalizedString(
        "RecentlySaved.Actions.More",
        value: "Show All",
        comment: "More button text for Recently Saved items at the home page.",
        lastUpdated: .unknown)
}

// MARK: - Home Panel Context Menu
extension String {
    public static let OpenInNewTabContextMenuTitle = MZLocalizedString(
        "HomePanel.ContextMenu.OpenInNewTab",
        value: "Open in New Tab",
        comment: "The title for the Open in New Tab context menu action for sites in Home Panels",
        lastUpdated: .unknown)
    public static let OpenInNewPrivateTabContextMenuTitle = MZLocalizedString(
        "HomePanel.ContextMenu.OpenInNewPrivateTab.v101",
        value: "Open in a Private Tab",
        comment: "The title for the Open in New Private Tab context menu action for sites in Home Panels",
        lastUpdated: .v101)
    public static let BookmarkContextMenuTitle = MZLocalizedString(
        "HomePanel.ContextMenu.Bookmark",
        value: "Bookmark",
        comment: "The title for the Bookmark context menu action for sites in Home Panels",
        lastUpdated: .unknown)
    public static let RemoveBookmarkContextMenuTitle = MZLocalizedString(
        "HomePanel.ContextMenu.RemoveBookmark",
        value: "Remove Bookmark",
        comment: "The title for the Remove Bookmark context menu action for sites in Home Panels",
        lastUpdated: .unknown)
    public static let DeleteFromHistoryContextMenuTitle = MZLocalizedString(
        "HomePanel.ContextMenu.DeleteFromHistory",
        value: "Delete from History",
        comment: "The title for the Delete from History context menu action for sites in Home Panels",
        lastUpdated: .unknown)
    public static let ShareContextMenuTitle = MZLocalizedString(
        "HomePanel.ContextMenu.Share",
        value: "Share",
        comment: "The title for the Share context menu action for sites in Home Panels",
        lastUpdated: .unknown)
    public static let RemoveContextMenuTitle = MZLocalizedString(
        "HomePanel.ContextMenu.Remove",
        value: "Remove",
        comment: "The title for the Remove context menu action for sites in Home Panels",
        lastUpdated: .unknown)
    public static let PinTopsiteActionTitle2 = MZLocalizedString(
        "ActivityStream.ContextMenu.PinTopsite2",
        value: "Pin",
        comment: "The title for the pinning a topsite action",
        lastUpdated: .unknown)
    public static let UnpinTopsiteActionTitle2 = MZLocalizedString(
        "ActivityStream.ContextMenu.UnpinTopsite",
        value: "Unpin",
        comment: "The title for the unpinning a topsite action",
        lastUpdated: .unknown)
    public static let AddToShortcutsActionTitle = MZLocalizedString(
        "ActivityStream.ContextMenu.AddToShortcuts",
        value: "Add to Shortcuts",
        comment: "The title for the pinning a shortcut action",
        lastUpdated: .unknown)
}

// MARK: - PhotonActionSheet String
extension String {
    public static let CloseButtonTitle = MZLocalizedString(
        "PhotonMenu.close",
        value: "Close",
        comment: "Button for closing the menu action sheet",
        lastUpdated: .unknown)
}

// MARK: - Home page
extension String {
    public static let SettingsHomePageSectionName = MZLocalizedString(
        "Settings.HomePage.SectionName",
        value: "Homepage",
        comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.",
        lastUpdated: .unknown)
    public static let SettingsHomePageURLSectionTitle = MZLocalizedString(
        "Settings.HomePage.URL.Title",
        value: "Current Homepage",
        comment: "Title of the setting section containing the URL of the current home page.",
        lastUpdated: .unknown)
    public static let ReopenLastTabAlertTitle = MZLocalizedString(
        "ReopenAlert.Title",
        value: "Reopen Last Closed Tab",
        comment: "Reopen alert title shown at home page.",
        lastUpdated: .unknown)
    public static let ReopenLastTabButtonText = MZLocalizedString(
        "ReopenAlert.Actions.Reopen",
        value: "Reopen",
        comment: "Reopen button text shown in reopen-alert at home page.",
        lastUpdated: .unknown)
    public static let ReopenLastTabCancelText = MZLocalizedString(
        "ReopenAlert.Actions.Cancel",
        value: "Cancel",
        comment: "Cancel button text shown in reopen-alert at home page.",
        lastUpdated: .unknown)
}

// MARK: - Settings
extension String {
    public static let SettingsGeneralSectionTitle = MZLocalizedString(
        "Settings.General.SectionName",
        value: "General",
        comment: "General settings section title",
        lastUpdated: .unknown)
    public static let SettingsClearPrivateDataClearButton = MZLocalizedString(
        "Settings.ClearPrivateData.Clear.Button",
        value: "Clear Private Data",
        comment: "Button in settings that clears private data for the selected items.",
        lastUpdated: .unknown)
    public static let SettingsClearAllWebsiteDataButton = MZLocalizedString(
        "Settings.ClearAllWebsiteData.Clear.Button",
        value: "Clear All Website Data",
        comment: "Button in Data Management that clears all items.",
        lastUpdated: .unknown)
    public static let SettingsClearSelectedWebsiteDataButton = MZLocalizedString(
        "Settings.ClearSelectedWebsiteData.ClearSelected.Button",
        value: "Clear Items: %1$@",
        comment: "Button in Data Management that clears private data for the selected items. Parameter is the number of items to be cleared",
        lastUpdated: .unknown)
    public static let SettingsClearPrivateDataSectionName = MZLocalizedString(
        "Settings.ClearPrivateData.SectionName",
        value: "Clear Private Data",
        comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.",
        lastUpdated: .unknown)
    public static let SettingsDataManagementSectionName = MZLocalizedString(
        "Settings.DataManagement.SectionName",
        value: "Data Management",
        comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.",
        lastUpdated: .unknown)
    public static let SettingsFilterSitesSearchLabel = MZLocalizedString(
        "Settings.DataManagement.SearchLabel",
        value: "Filter Sites",
        comment: "Default text in search bar for Data Management",
        lastUpdated: .unknown)
    public static let SettingsDataManagementTitle = MZLocalizedString(
        "Settings.DataManagement.Title",
        value: "Data Management",
        comment: "Title displayed in header of the setting panel.",
        lastUpdated: .unknown)
    public static let SettingsWebsiteDataTitle = MZLocalizedString(
        "Settings.WebsiteData.Title",
        value: "Website Data",
        comment: "Title displayed in header of the Data Management panel.",
        lastUpdated: .unknown)
    public static let SettingsWebsiteDataShowMoreButton = MZLocalizedString(
        "Settings.WebsiteData.ButtonShowMore",
        value: "Show More",
        comment: "Button shows all websites on website data tableview",
        lastUpdated: .unknown)
    public static let SettingsDisconnectSyncAlertTitle = MZLocalizedString(
        "Settings.Disconnect.Title",
        value: "Disconnect Sync?",
        comment: "Title of the alert when prompting the user asking to disconnect.",
        lastUpdated: .unknown)
    public static let SettingsDisconnectSyncAlertBody = MZLocalizedString(
        "Settings.Disconnect.Body",
        value: "Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.",
        comment: "Body of the alert when prompting the user asking to disconnect.",
        lastUpdated: .unknown)
    public static let SettingsDisconnectSyncButton = MZLocalizedString(
        "Settings.Disconnect.Button",
        value: "Disconnect Sync",
        comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA",
        lastUpdated: .unknown)
    public static let SettingsDisconnectCancelAction = MZLocalizedString(
        "Settings.Disconnect.CancelButton",
        value: "Cancel",
        comment: "Cancel action button in alert when user is prompted for disconnect",
        lastUpdated: .unknown)
    public static let SettingsDisconnectDestructiveAction = MZLocalizedString(
        "Settings.Disconnect.DestructiveButton",
        value: "Disconnect",
        comment: "Destructive action button in alert when user is prompted for disconnect",
        lastUpdated: .unknown)
    public static let SettingsSearchDoneButton = MZLocalizedString(
        "Settings.Search.Done.Button",
        value: "Done",
        comment: "Button displayed at the top of the search settings.",
        lastUpdated: .unknown)
    public static let SettingsSearchEditButton = MZLocalizedString(
        "Settings.Search.Edit.Button",
        value: "Edit",
        comment: "Button displayed at the top of the search settings.",
        lastUpdated: .unknown)
    public static let SettingsCopyAppVersionAlertTitle = MZLocalizedString(
        "Settings.CopyAppVersion.Title",
        value: "Copied to clipboard",
        comment: "Copy app version alert shown in settings.",
        lastUpdated: .unknown)
}

// MARK: - Error pages
extension String {
    public static let ErrorPagesAdvancedButton = MZLocalizedString(
        "ErrorPages.Advanced.Button",
        value: "Advanced",
        comment: "Label for button to perform advanced actions on the error page",
        lastUpdated: .unknown)
    public static let ErrorPagesAdvancedWarning1 = MZLocalizedString(
        "ErrorPages.AdvancedWarning1.Text",
        value: "Warning: we can’t confirm your connection to this website is secure.",
        comment: "Warning text when clicking the Advanced button on error pages",
        lastUpdated: .unknown)
    public static let ErrorPagesAdvancedWarning2 = MZLocalizedString(
        "ErrorPages.AdvancedWarning2.Text",
        value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.",
        comment: "Additional warning text when clicking the Advanced button on error pages",
        lastUpdated: .unknown)
    public static let ErrorPagesCertWarningDescription = MZLocalizedString(
        "ErrorPages.CertWarning.Description",
        value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Firefox has not connected to this website.",
        comment: "Warning text on the certificate error page",
        lastUpdated: .unknown)
    public static let ErrorPagesCertWarningTitle = MZLocalizedString(
        "ErrorPages.CertWarning.Title",
        value: "This Connection is Untrusted",
        comment: "Title on the certificate error page",
        lastUpdated: .unknown)
    public static let ErrorPagesGoBackButton = MZLocalizedString(
        "ErrorPages.GoBack.Button",
        value: "Go Back",
        comment: "Label for button to go back from the error page",
        lastUpdated: .unknown)
    public static let ErrorPagesVisitOnceButton = MZLocalizedString(
        "ErrorPages.VisitOnce.Button",
        value: "Visit site anyway",
        comment: "Button label to temporarily continue to the site from the certificate error page",
        lastUpdated: .unknown)
}

// MARK: - Logins Helper
extension String {
    public static let LoginsHelperSaveLoginButtonTitle = MZLocalizedString(
        "LoginsHelper.SaveLogin.Button",
        value: "Save Login",
        comment: "Button to save the user's password",
        lastUpdated: .unknown)
    public static let LoginsHelperDontSaveButtonTitle = MZLocalizedString(
        "LoginsHelper.DontSave.Button",
        value: "Don’t Save",
        comment: "Button to not save the user's password",
        lastUpdated: .unknown)
    public static let LoginsHelperUpdateButtonTitle = MZLocalizedString(
        "LoginsHelper.Update.Button",
        value: "Update",
        comment: "Button to update the user's password",
        lastUpdated: .unknown)
    public static let LoginsHelperDontUpdateButtonTitle = MZLocalizedString(
        "LoginsHelper.DontUpdate.Button",
        value: "Don’t Update",
        comment: "Button to not update the user's password",
        lastUpdated: .unknown)
}

// MARK: - Downloads Panel
extension String {
    public static let DownloadsPanelEmptyStateTitle = MZLocalizedString(
        "DownloadsPanel.EmptyState.Title",
        value: "Downloaded files will show up here.",
        comment: "Title for the Downloads Panel empty state.",
        lastUpdated: .unknown)
    public static let DownloadsPanelDeleteTitle = MZLocalizedString(
        "DownloadsPanel.Delete.Title",
        value: "Delete",
        comment: "Action button for deleting downloaded files in the Downloads panel.",
        lastUpdated: .unknown)
    public static let DownloadsPanelShareTitle = MZLocalizedString(
        "DownloadsPanel.Share.Title",
        value: "Share",
        comment: "Action button for sharing downloaded files in the Downloads panel.",
        lastUpdated: .unknown)
}

// MARK: - History Panel
extension String {
    public static let HistoryBackButtonTitle = MZLocalizedString(
        "HistoryPanel.HistoryBackButton.Title",
        value: "History",
        comment: "Title for the Back to History button in the History Panel",
        lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelStateTitle = MZLocalizedString(
        "HistoryPanel.EmptySyncedTabsState.Title",
        value: "Firefox Sync",
        comment: "Title for the empty synced tabs state in the History Panel",
        lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelNotSignedInStateDescription = MZLocalizedString(
        "HistoryPanel.EmptySyncedTabsPanelNotSignedInState.Description",
        value: "Sign in to view a list of tabs from your other devices.",
        comment: "Description for the empty synced tabs 'not signed in' state in the History Panel",
        lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelNullStateDescription = MZLocalizedString(
        "HistoryPanel.EmptySyncedTabsNullState.Description",
        value: "Your tabs from other devices show up here.",
        comment: "Description for the empty synced tabs null state in the History Panel",
        lastUpdated: .unknown)
    public static let HistoryPanelEmptyStateTitle = MZLocalizedString(
        "HistoryPanel.EmptyState.Title",
        value: "Websites you’ve visited recently will show up here.",
        comment: "Title for the History Panel empty state.",
        lastUpdated: .unknown)
    public static let RecentlyClosedTabsPanelTitle = MZLocalizedString(
        "RecentlyClosedTabsPanel.Title",
        value: "Recently Closed",
        comment: "Title for the Recently Closed Tabs Panel",
        lastUpdated: .unknown)
    public static let FirefoxHomePage = MZLocalizedString(
        "Firefox.HomePage.Title",
        value: "Firefox Home Page",
        comment: "Title for firefox about:home page in tab history list",
        lastUpdated: .unknown)
    public static let HistoryPanelDelete = MZLocalizedString(
        "Delete",
        tableName: "HistoryPanel",
        comment: "Action button for deleting history entries in the history panel.",
        lastUpdated: .unknown)
}

// MARK: - Clear recent history action menu
extension String {
    public static let ClearHistoryMenuOptionTheLastHour = MZLocalizedString(
        "HistoryPanel.ClearHistoryMenuOptionTheLastHour",
        value: "The Last Hour",
        comment: "Button to perform action to clear history for the last hour",
        lastUpdated: .unknown)
    public static let ClearHistoryMenuOptionToday = MZLocalizedString(
        "HistoryPanel.ClearHistoryMenuOptionToday",
        value: "Today",
        comment: "Button to perform action to clear history for today only",
        lastUpdated: .unknown)
    public static let ClearHistoryMenuOptionTodayAndYesterday = MZLocalizedString(
        "HistoryPanel.ClearHistoryMenuOptionTodayAndYesterday",
        value: "Today and Yesterday",
        comment: "Button to perform action to clear history for yesterday and today",
        lastUpdated: .unknown)
    public static let ClearHistoryMenuOptionEverything = MZLocalizedString(
        "HistoryPanel.ClearHistoryMenuOptionEverything",
        value: "Everything",
        comment: "Option title to clear all browsing history.",
        lastUpdated: .unknown)
}

// MARK: - Syncing
extension String {
    public static let SyncingMessageWithEllipsis = MZLocalizedString(
        "Sync.SyncingEllipsis.Label",
        value: "Syncing…",
        comment: "Message displayed when the user's account is syncing with ellipsis at the end",
        lastUpdated: .unknown)

    public static let FirefoxSyncOfflineTitle = MZLocalizedString(
        "SyncState.Offline.Title",
        value: "Sync is offline",
        comment: "Title for Sync status message when Sync failed due to being offline",
        lastUpdated: .unknown)
    public static let FirefoxSyncTroubleshootTitle = MZLocalizedString(
        "Settings.TroubleShootSync.Title",
        value: "Troubleshoot",
        comment: "Title of link to help page to find out how to solve Sync issues",
        lastUpdated: .unknown)

    public static let FirefoxSyncBookmarksEngine = MZLocalizedString(
        "Bookmarks",
        comment: "Toggle bookmarks syncing setting",
        lastUpdated: .unknown)
    public static let FirefoxSyncHistoryEngine = MZLocalizedString(
        "History",
        comment: "Toggle history syncing setting",
        lastUpdated: .unknown)
    public static let FirefoxSyncTabsEngine = MZLocalizedString(
        "Open Tabs",
        comment: "Toggle tabs syncing setting",
        lastUpdated: .unknown)
    public static let FirefoxSyncLoginsEngine = MZLocalizedString(
        "Logins",
        comment: "Toggle logins syncing setting",
        lastUpdated: .unknown)
}

// MARK: - Firefox Logins
extension String {

    // Prompts
    public static let SaveLoginUsernamePrompt = MZLocalizedString(
        "LoginsHelper.PromptSaveLogin.Title",
        value: "Save login %@ for %@?",
        comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.",
        lastUpdated: .unknown)
    public static let SaveLoginPrompt = MZLocalizedString(
        "LoginsHelper.PromptSavePassword.Title",
        value: "Save password for %@?",
        comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.",
        lastUpdated: .unknown)
    public static let UpdateLoginUsernamePrompt = MZLocalizedString(
        "LoginsHelper.PromptUpdateLogin.Title.TwoArg",
        value: "Update login %@ for %@?",
        comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.",
        lastUpdated: .unknown)
    public static let UpdateLoginPrompt = MZLocalizedString(
        "LoginsHelper.PromptUpdateLogin.Title.OneArg",
        value: "Update login for %@?",
        comment: "Prompt for updating a login. The first parameter is the hostname for which the password will be updated for.",
        lastUpdated: .unknown)

    // Setting
    public static let SettingToShowLoginsInAppMenu = MZLocalizedString(
        "Settings.ShowLoginsInAppMenu.Title",
        value: "Show in Application Menu",
        comment: "Setting to show Logins & Passwords quick access in the application menu",
        lastUpdated: .unknown)

    // List view
    public static let LoginsListTitle = MZLocalizedString(
        "LoginsList.Title",
        value: "SAVED LOGINS",
        comment: "Title for the list of logins",
        lastUpdated: .unknown)
    public static let LoginsListSearchPlaceholder = MZLocalizedString(
        "LoginsList.LoginsListSearchPlaceholder",
        value: "Filter",
        comment: "Placeholder test for search box in logins list view.",
        lastUpdated: .unknown)

    // Breach Alerts
    public static let BreachAlertsTitle = MZLocalizedString(
        "BreachAlerts.Title",
        value: "Website Breach",
        comment: "Title for the Breached Login Detail View.",
        lastUpdated: .unknown)
    public static let BreachAlertsLearnMore = MZLocalizedString(
        "BreachAlerts.LearnMoreButton",
        value: "Learn more",
        comment: "Link to monitor.firefox.com to learn more about breached passwords",
        lastUpdated: .unknown)
    public static let BreachAlertsBreachDate = MZLocalizedString(
        "BreachAlerts.BreachDate",
        value: "This breach occurred on",
        comment: "Describes the date on which the breach occurred",
        lastUpdated: .unknown)
    public static let BreachAlertsDescription = MZLocalizedString(
        "BreachAlerts.Description",
        value: "Passwords were leaked or stolen since you last changed your password. To protect this account, log in to the site and change your password.",
        comment: "Description of what a breach is",
        lastUpdated: .unknown)
    public static let BreachAlertsLink = MZLocalizedString(
        "BreachAlerts.Link",
        value: "Go to",
        comment: "Leads to a link to the breached website",
        lastUpdated: .unknown)

    // For the DevicePasscodeRequiredViewController
    public static let LoginsDevicePasscodeRequiredMessage = MZLocalizedString(
        "Logins.DevicePasscodeRequired.Message",
        value: "To save and autofill logins and passwords, enable Face ID, Touch ID or a device passcode.",
        comment: "Message shown when you enter Logins & Passwords without having a device passcode set.",
        lastUpdated: .unknown)
    public static let LoginsDevicePasscodeRequiredLearnMoreButtonTitle = MZLocalizedString(
        "Logins.DevicePasscodeRequired.LearnMoreButtonTitle",
        value: "Learn More",
        comment: "Title of the Learn More button that links to a support page about device passcode requirements.",
        lastUpdated: .unknown)

    // For the LoginOnboardingViewController
    public static let LoginsOnboardingLearnMoreButtonTitle = MZLocalizedString(
        "Logins.Onboarding.LearnMoreButtonTitle",
        value: "Learn More",
        comment: "Title of the Learn More button that links to a support page about device passcode requirements.",
        lastUpdated: .unknown)
    public static let LoginsOnboardingContinueButtonTitle = MZLocalizedString(
        "Logins.Onboarding.ContinueButtonTitle",
        value: "Continue",
        comment: "Title of the Continue button.",
        lastUpdated: .unknown)
}

// MARK: - Firefox Account
extension String {
    // Settings strings
    public static let FxAFirefoxAccount = MZLocalizedString(
        "FxA.FirefoxAccount",
        value: "Firefox Account",
        comment: "Settings section title for Firefox Account",
        lastUpdated: .unknown)
    public static let FxAManageAccount = MZLocalizedString(
        "FxA.ManageAccount",
        value: "Manage Account & Devices",
        comment: "Button label to go to Firefox Account settings",
        lastUpdated: .unknown)
    public static let FxASyncNow = MZLocalizedString(
        "FxA.SyncNow",
        value: "Sync Now",
        comment: "Button label to Sync your Firefox Account",
        lastUpdated: .unknown)
    public static let FxANoInternetConnection = MZLocalizedString(
        "FxA.NoInternetConnection",
        value: "No Internet Connection",
        comment: "Label when no internet is present",
        lastUpdated: .unknown)
    public static let FxASettingsTitle = MZLocalizedString(
        "Settings.FxA.Title",
        value: "Firefox Account",
        comment: "Title displayed in header of the FxA settings panel.",
        lastUpdated: .unknown)
    public static let FxASettingsSyncSettings = MZLocalizedString(
        "Settings.FxA.Sync.SectionName",
        value: "Sync Settings",
        comment: "Label used as a section title in the Firefox Accounts Settings screen.",
        lastUpdated: .unknown)
    public static let FxASettingsDeviceName = MZLocalizedString(
        "Settings.FxA.DeviceName",
        value: "Device Name",
        comment: "Label used for the device name settings section.",
        lastUpdated: .unknown)

    // Surface error strings
    public static let FxAAccountVerifyPassword = MZLocalizedString(
        "Enter your password to connect",
        comment: "Text message in the settings table view",
        lastUpdated: .unknown)
}

// MARK: - New tab choice settings
extension String {
    public static let CustomNewPageURL = MZLocalizedString(
        "Settings.NewTab.CustomURL",
        value: "Custom URL",
        comment: "Label used to set a custom url as the new tab option (homepage).",
        lastUpdated: .unknown)
    public static let SettingsNewTabSectionName = MZLocalizedString(
        "Settings.NewTab.SectionName",
        value: "New Tab",
        comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behavior.",
        lastUpdated: .unknown)
    public static let NewTabSectionName =
    MZLocalizedString(
        "Settings.NewTab.TopSectionName",
        value: "Show",
        comment: "Label at the top of the New Tab screen after entering New Tab in settings",
        lastUpdated: .unknown)
    public static let SettingsNewTabTitle = MZLocalizedString(
        "Settings.NewTab.Title",
        value: "New Tab",
        comment: "Title displayed in header of the setting panel.",
        lastUpdated: .unknown)
    public static let NewTabSectionNameFooter = MZLocalizedString(
        "Settings.NewTab.TopSectionNameFooter",
        value: "Choose what to load when opening a new tab",
        comment: "Footer at the bottom of the New Tab screen after entering New Tab in settings",
        lastUpdated: .unknown)
    public static let SettingsNewTabTopSites = MZLocalizedString(
        "Settings.NewTab.Option.FirefoxHome",
        value: "Firefox Home",
        comment: "Option in settings to show Firefox Home when you open a new tab",
        lastUpdated: .unknown)
    public static let SettingsNewTabBlankPage = MZLocalizedString(
        "Settings.NewTab.Option.BlankPage",
        value: "Blank Page",
        comment: "Option in settings to show a blank page when you open a new tab",
        lastUpdated: .unknown)
    public static let SettingsNewTabHomePage = MZLocalizedString(
        "Settings.NewTab.Option.HomePage",
        value: "Homepage",
        comment: "Option in settings to show your homepage when you open a new tab",
        lastUpdated: .unknown)
}

// MARK: - Advanced Sync Settings (Debug)
// For 'Advanced Sync Settings' view, which is a debug setting. English only, there is little value in maintaining L10N strings for these.
extension String {
    public static let SettingsAdvancedAccountTitle = "Advanced Sync Settings"
    public static let SettingsAdvancedAccountCustomFxAContentServerURI = "Custom Firefox Account Content Server URI"
    public static let SettingsAdvancedAccountUseCustomFxAContentServerURITitle = "Use Custom FxA Content Server"
    public static let SettingsAdvancedAccountCustomSyncTokenServerURI = "Custom Sync Token Server URI"
    public static let SettingsAdvancedAccountUseCustomSyncTokenServerTitle = "Use Custom Sync Token Server"
}

// MARK: - Open With Settings
extension String {
    public static let SettingsOpenWithSectionName = MZLocalizedString(
        "Settings.OpenWith.SectionName",
        value: "Mail App",
        comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behavior.",
        lastUpdated: .unknown)
    public static let SettingsOpenWithPageTitle = MZLocalizedString(
        "Settings.OpenWith.PageTitle",
        value: "Open mail links with",
        comment: "Title for Open With Settings",
        lastUpdated: .unknown)
}

// MARK: - Third Party Search Engines
extension String {
    public static let ThirdPartySearchEngineAdded = MZLocalizedString(
        "Search.ThirdPartyEngines.AddSuccess",
        value: "Added Search engine!",
        comment: "The success message that appears after a user sucessfully adds a new search engine",
        lastUpdated: .unknown)
    public static let ThirdPartySearchAddTitle = MZLocalizedString(
        "Search.ThirdPartyEngines.AddTitle",
        value: "Add Search Provider?",
        comment: "The title that asks the user to Add the search provider",
        lastUpdated: .unknown)
    public static let ThirdPartySearchAddMessage = MZLocalizedString(
        "Search.ThirdPartyEngines.AddMessage",
        value: "The new search engine will appear in the quick search bar.",
        comment: "The message that asks the user to Add the search provider explaining where the search engine will appear",
        lastUpdated: .unknown)
    public static let ThirdPartySearchCancelButton = MZLocalizedString(
        "Search.ThirdPartyEngines.Cancel",
        value: "Cancel",
        comment: "The cancel button if you do not want to add a search engine.",
        lastUpdated: .unknown)
    public static let ThirdPartySearchOkayButton = MZLocalizedString(
        "Search.ThirdPartyEngines.OK",
        value: "OK",
        comment: "The confirmation button",
        lastUpdated: .unknown)
    public static let ThirdPartySearchFailedTitle = MZLocalizedString(
        "Search.ThirdPartyEngines.FailedTitle",
        value: "Failed",
        comment: "A title explaining that we failed to add a search engine",
        lastUpdated: .unknown)
    public static let ThirdPartySearchFailedMessage = MZLocalizedString(
        "Search.ThirdPartyEngines.FailedMessage",
        value: "The search provider could not be added.",
        comment: "A title explaining that we failed to add a search engine",
        lastUpdated: .unknown)
    public static let CustomEngineFormErrorTitle = MZLocalizedString(
        "Search.ThirdPartyEngines.FormErrorTitle",
        value: "Failed",
        comment: "A title stating that we failed to add custom search engine.",
        lastUpdated: .unknown)
    public static let CustomEngineFormErrorMessage = MZLocalizedString(
        "Search.ThirdPartyEngines.FormErrorMessage",
        value: "Please fill all fields correctly.",
        comment: "A message explaining fault in custom search engine form.",
        lastUpdated: .unknown)
    public static let CustomEngineDuplicateErrorTitle = MZLocalizedString(
        "Search.ThirdPartyEngines.DuplicateErrorTitle",
        value: "Failed",
        comment: "A title stating that we failed to add custom search engine.",
        lastUpdated: .unknown)
    public static let CustomEngineDuplicateErrorMessage = MZLocalizedString(
        "Search.ThirdPartyEngines.DuplicateErrorMessage",
        value: "A search engine with this title or URL has already been added.",
        comment: "A message explaining fault in custom search engine form.",
        lastUpdated: .unknown)
}

// MARK: - Root Bookmarks folders
extension String {
    public static let BookmarksFolderTitleMobile = MZLocalizedString(
        "Mobile Bookmarks",
        tableName: "Storage",
        comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.",
        lastUpdated: .unknown)
    public static let BookmarksFolderTitleMenu = MZLocalizedString(
        "Bookmarks Menu",
        tableName: "Storage",
        comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.",
        lastUpdated: .unknown)
    public static let BookmarksFolderTitleToolbar = MZLocalizedString(
        "Bookmarks Toolbar",
        tableName: "Storage",
        comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.",
        lastUpdated: .unknown)
    public static let BookmarksFolderTitleUnsorted = MZLocalizedString(
        "Unsorted Bookmarks",
        tableName: "Storage",
        comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.",
        lastUpdated: .unknown)
}

// MARK: - Bookmark Management
extension String {
    public static let BookmarksFolder = MZLocalizedString(
        "Bookmarks.Folder.Label",
        value: "Folder",
        comment: "The label to show the location of the folder where the bookmark is located",
        lastUpdated: .unknown)
    public static let BookmarksNewBookmark = MZLocalizedString(
        "Bookmarks.NewBookmark.Label",
        value: "New Bookmark",
        comment: "The button to create a new bookmark",
        lastUpdated: .unknown)
    public static let BookmarksNewFolder = MZLocalizedString(
        "Bookmarks.NewFolder.Label",
        value: "New Folder",
        comment: "The button to create a new folder",
        lastUpdated: .unknown)
    public static let BookmarksNewSeparator = MZLocalizedString(
        "Bookmarks.NewSeparator.Label",
        value: "New Separator",
        comment: "The button to create a new separator",
        lastUpdated: .unknown)
    public static let BookmarksEditBookmark = MZLocalizedString(
        "Bookmarks.EditBookmark.Label",
        value: "Edit Bookmark",
        comment: "The button to edit a bookmark",
        lastUpdated: .unknown)
    public static let BookmarksEdit = MZLocalizedString(
        "Bookmarks.Edit.Button",
        value: "Edit",
        comment: "The button on the snackbar to edit a bookmark after adding it.",
        lastUpdated: .unknown)
    public static let BookmarksEditFolder = MZLocalizedString(
        "Bookmarks.EditFolder.Label",
        value: "Edit Folder",
        comment: "The button to edit a folder",
        lastUpdated: .unknown)
    public static let BookmarksDeleteFolderWarningTitle = MZLocalizedString(
        "Bookmarks.DeleteFolderWarning.Title",
        tableName: "BookmarkPanelDeleteConfirm",
        value: "This folder isn’t empty.",
        comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.",
        lastUpdated: .unknown)
    public static let BookmarksDeleteFolderWarningDescription = MZLocalizedString(
        "Bookmarks.DeleteFolderWarning.Description",
        tableName: "BookmarkPanelDeleteConfirm",
        value: "Are you sure you want to delete it and its contents?",
        comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.",
        lastUpdated: .unknown)
    public static let BookmarksDeleteFolderCancelButtonLabel = MZLocalizedString(
        "Bookmarks.DeleteFolderWarning.CancelButton.Label",
        tableName: "BookmarkPanelDeleteConfirm",
        value: "Cancel",
        comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.",
        lastUpdated: .unknown)
    public static let BookmarksDeleteFolderDeleteButtonLabel = MZLocalizedString(
        "Bookmarks.DeleteFolderWarning.DeleteButton.Label",
        tableName: "BookmarkPanelDeleteConfirm",
        value: "Delete",
        comment: "Button label for the button that deletes a folder and all of its children.",
        lastUpdated: .unknown)
    public static let BookmarksPanelDeleteTableAction = MZLocalizedString(
        "Delete",
        tableName: "BookmarkPanel",
        comment: "Action button for deleting bookmarks in the bookmarks panel.",
        lastUpdated: .unknown)
    public static let BookmarkDetailFieldTitle = MZLocalizedString(
        "Bookmark.DetailFieldTitle.Label",
        value: "Title",
        comment: "The label for the Title field when editing a bookmark",
        lastUpdated: .unknown)
    public static let BookmarkDetailFieldURL = MZLocalizedString(
        "Bookmark.DetailFieldURL.Label",
        value: "URL",
        comment: "The label for the URL field when editing a bookmark",
        lastUpdated: .unknown)
}

// MARK: - Tabs Delete All Undo Toast
extension String {
    public static let TabsDeleteAllUndoTitle = MZLocalizedString(
        "Tabs.DeleteAllUndo.Title",
        value: "%d tab(s) closed",
        comment: "The label indicating that all the tabs were closed",
        lastUpdated: .unknown)
    public static let TabsDeleteAllUndoAction = MZLocalizedString(
        "Tabs.DeleteAllUndo.Button",
        value: "Undo",
        comment: "The button to undo the delete all tabs",
        lastUpdated: .unknown)
}

// MARK: - Tab tray (chronological tabs)
extension String {
    public static let TabTrayV2Title = MZLocalizedString(
        "TabTray.Title",
        value: "Open Tabs",
        comment: "The title for the tab tray",
        lastUpdated: .unknown)

    // Segmented Control tites for iPad
    public static let TabTraySegmentedControlTitlesTabs = MZLocalizedString(
        "TabTray.SegmentedControlTitles.Tabs",
        value: "Tabs",
        comment: "The title on the button to look at regular tabs.",
        lastUpdated: .unknown)
    public static let TabTraySegmentedControlTitlesPrivateTabs = MZLocalizedString(
        "TabTray.SegmentedControlTitles.PrivateTabs",
        value: "Private",
        comment: "The title on the button to look at private tabs.",
        lastUpdated: .unknown)
    public static let TabTraySegmentedControlTitlesSyncedTabs = MZLocalizedString(
        "TabTray.SegmentedControlTitles.SyncedTabs",
        value: "Synced",
        comment: "The title on the button to look at synced tabs.",
        lastUpdated: .unknown)
}

// MARK: - Clipboard Toast
extension String {
    public static let GoToCopiedLink = MZLocalizedString(
        "ClipboardToast.GoToCopiedLink.Title",
        value: "Go to copied link?",
        comment: "Message displayed when the user has a copied link on the clipboard",
        lastUpdated: .unknown)
    public static let GoButtonTittle = MZLocalizedString(
        "ClipboardToast.GoToCopiedLink.Button",
        value: "Go",
        comment: "The button to open a new tab with the copied link",
        lastUpdated: .unknown)

    public static let SettingsOfferClipboardBarTitle = MZLocalizedString(
        "Settings.OfferClipboardBar.Title",
        value: "Offer to Open Copied Links",
        comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349",
        lastUpdated: .unknown)
    public static let SettingsOfferClipboardBarStatus = MZLocalizedString(
        "Settings.OfferClipboardBar.Status",
        value: "When Opening Firefox",
        comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349",
        lastUpdated: .unknown)
}

// MARK: - Link Previews
extension String {
    public static let SettingsShowLinkPreviewsTitle = MZLocalizedString(
        "Settings.ShowLinkPreviews.Title",
        value: "Show Link Previews",
        comment: "Title of setting to enable link previews when long-pressing links.",
        lastUpdated: .unknown)
    public static let SettingsShowLinkPreviewsStatus = MZLocalizedString(
        "Settings.ShowLinkPreviews.Status",
        value: "When Long-pressing Links",
        comment: "Description displayed under the ”Show Link Previews” option",
        lastUpdated: .unknown)
}

// MARK: - Errors
extension String {
    public static let UnableToAddPassErrorTitle = MZLocalizedString(
        "AddPass.Error.Title",
        value: "Failed to Add Pass",
        comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.",
        lastUpdated: .unknown)
    public static let UnableToAddPassErrorMessage = MZLocalizedString(
        "AddPass.Error.Message",
        value: "An error occured while adding the pass to Wallet. Please try again later.",
        comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.",
        lastUpdated: .unknown)
    public static let UnableToAddPassErrorDismiss = MZLocalizedString(
        "AddPass.Error.Dismiss",
        value: "OK",
        comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.",
        lastUpdated: .unknown)
    public static let UnableToOpenURLError = MZLocalizedString(
        "OpenURL.Error.Message",
        value: "Firefox cannot open the page because it has an invalid address.",
        comment: "The message displayed to a user when they try to open a URL that cannot be handled by Firefox, or any external app.",
        lastUpdated: .unknown)
    public static let UnableToOpenURLErrorTitle = MZLocalizedString(
        "OpenURL.Error.Title",
        value: "Cannot Open Page",
        comment: "Title of the message shown when the user attempts to navigate to an invalid link.",
        lastUpdated: .unknown)
    public static let CouldntDownloadWallpaperErrorTitle = MZLocalizedString(
        "Wallpaper.Download.Error.Title.v106",
        value: "Couldn’t Download Wallpaper",
        comment: "The title of the error displayed if download fails when changing a wallpaper.",
        lastUpdated: .v106)
    public static let CouldntDownloadWallpaperErrorBody = MZLocalizedString(
        "Wallpaper.Download.Error.Body.v106",
        value: "Something went wrong with your download.",
        comment: "The message of the error displayed to a user when they try change a wallpaper that failed downloading.",
        lastUpdated: .v106)
    public static let CouldntChangeWallpaperErrorTitle = MZLocalizedString(
        "Wallpaper.Change.Error.Title.v106",
        value: "Couldn’t Change Wallpaper",
        comment: "The title of the error displayed when changing wallpaper fails.",
        lastUpdated: .v106)
    public static let CouldntChangeWallpaperErrorBody = MZLocalizedString(
        "Wallpaper.Change.Error.Body.v106",
        value: "Something went wrong with this wallpaper.",
        comment: "The message of the error displayed to a user when they trying to change a wallpaper failed.",
        lastUpdated: .v106)
    public static let WallpaperErrorTryAgain = MZLocalizedString(
        "Wallpaper.Error.TryAgain.v106",
        value: "Try Again",
        comment: "Action displayed when changing wallpaper fails.",
        lastUpdated: .v106)
    public static let WallpaperErrorDismiss = MZLocalizedString(
        "Wallpaper.Error.Dismiss.v106",
        value: "Cancel",
        comment: "An action for the error displayed to a user when they trying to change a wallpaper failed.",
        lastUpdated: .v106)
}

// MARK: - Download Helper
extension String {
    public static let OpenInDownloadHelperAlertDownloadNow = MZLocalizedString(
        "Downloads.Alert.DownloadNow",
        value: "Download Now",
        comment: "The label of the button the user will press to start downloading a file",
        lastUpdated: .unknown)
    public static let DownloadsButtonTitle = MZLocalizedString(
        "Downloads.Toast.GoToDownloads.Button",
        value: "Downloads",
        comment: "The button to open a new tab with the Downloads home panel",
        lastUpdated: .unknown)
    public static let CancelDownloadDialogTitle = MZLocalizedString(
        "Downloads.CancelDialog.Title",
        value: "Cancel Download",
        comment: "Alert dialog title when the user taps the cancel download icon.",
        lastUpdated: .unknown)
    public static let CancelDownloadDialogMessage = MZLocalizedString(
        "Downloads.CancelDialog.Message",
        value: "Are you sure you want to cancel this download?",
        comment: "Alert dialog body when the user taps the cancel download icon.",
        lastUpdated: .unknown)
    public static let CancelDownloadDialogResume = MZLocalizedString(
        "Downloads.CancelDialog.Resume",
        value: "Resume",
        comment: "Button declining the cancellation of the download.",
        lastUpdated: .unknown)
    public static let CancelDownloadDialogCancel = MZLocalizedString(
        "Downloads.CancelDialog.Cancel",
        value: "Cancel",
        comment: "Button confirming the cancellation of the download.",
        lastUpdated: .unknown)
    public static let DownloadCancelledToastLabelText = MZLocalizedString(
        "Downloads.Toast.Cancelled.LabelText",
        value: "Download Cancelled",
        comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.",
        lastUpdated: .unknown)
    public static let DownloadFailedToastLabelText = MZLocalizedString(
        "Downloads.Toast.Failed.LabelText",
        value: "Download Failed",
        comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.",
        lastUpdated: .unknown)
    public static let DownloadMultipleFilesToastDescriptionText = MZLocalizedString(
        "Downloads.Toast.MultipleFiles.DescriptionText",
        value: "1 of %d files",
        comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.",
        lastUpdated: .unknown)
    public static let DownloadProgressToastDescriptionText = MZLocalizedString(
        "Downloads.Toast.Progress.DescriptionText",
        value: "%1$@/%2$@",
        comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).",
        lastUpdated: .unknown)
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = MZLocalizedString(
        "Downloads.Toast.MultipleFilesAndProgress.DescriptionText",
        value: "%1$@ %2$@",
        comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.",
        lastUpdated: .unknown)
}

// MARK: - Add Custom Search Engine
extension String {
    public static let SettingsAddCustomEngine = MZLocalizedString(
        "Settings.AddCustomEngine",
        value: "Add Search Engine",
        comment: "The button text in Search Settings that opens the Custom Search Engine view.",
        lastUpdated: .unknown)
    public static let SettingsAddCustomEngineTitle = MZLocalizedString(
        "Settings.AddCustomEngine.Title",
        value: "Add Search Engine",
        comment: "The title of the  Custom Search Engine view.",
        lastUpdated: .unknown)
    public static let SettingsAddCustomEngineTitleLabel = MZLocalizedString(
        "Settings.AddCustomEngine.TitleLabel",
        value: "Title",
        comment: "The title for the field which sets the title for a custom search engine.",
        lastUpdated: .unknown)
    public static let SettingsAddCustomEngineURLLabel = MZLocalizedString(
        "Settings.AddCustomEngine.URLLabel",
        value: "URL",
        comment: "The title for URL Field",
        lastUpdated: .unknown)
    public static let SettingsAddCustomEngineTitlePlaceholder = MZLocalizedString(
        "Settings.AddCustomEngine.TitlePlaceholder",
        value: "Search Engine",
        comment: "The placeholder for Title Field when saving a custom search engine.",
        lastUpdated: .unknown)
    public static let SettingsAddCustomEngineURLPlaceholder = MZLocalizedString(
        "Settings.AddCustomEngine.URLPlaceholder",
        value: "URL (Replace Query with %s)",
        comment: "The placeholder for URL Field when saving a custom search engine",
        lastUpdated: .unknown)
    public static let SettingsAddCustomEngineSaveButtonText = MZLocalizedString(
        "Settings.AddCustomEngine.SaveButtonText",
        value: "Save",
        comment: "The text on the Save button when saving a custom search engine",
        lastUpdated: .unknown)
}

// MARK: - Context menu ButtonToast instances.
extension String {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = MZLocalizedString(
        "ContextMenu.ButtonToast.NewTabOpened.LabelText",
        value: "New Tab opened",
        comment: "The label text in the Button Toast for switching to a fresh New Tab.",
        lastUpdated: .unknown)
    public static let ContextMenuButtonToastNewTabOpenedButtonText = MZLocalizedString(
        "ContextMenu.ButtonToast.NewTabOpened.ButtonText",
        value: "Switch",
        comment: "The button text in the Button Toast for switching to a fresh New Tab.",
        lastUpdated: .unknown)
    public static let ContextMenuButtonToastNewPrivateTabOpenedLabelText = MZLocalizedString(
        "ContextMenu.ButtonToast.NewPrivateTabOpened.LabelText",
        value: "New Private Tab opened",
        comment: "The label text in the Button Toast for switching to a fresh New Private Tab.",
        lastUpdated: .unknown)
}

// MARK: - Page context menu items (i.e. links and images).
extension String {
    public static let ContextMenuOpenInNewTab = MZLocalizedString(
        "ContextMenu.OpenInNewTabButtonTitle",
        value: "Open in New Tab",
        comment: "Context menu item for opening a link in a new tab",
        lastUpdated: .unknown)
    public static let ContextMenuOpenInNewPrivateTab = MZLocalizedString(
        "ContextMenu.OpenInNewPrivateTabButtonTitle",
        tableName: "PrivateBrowsing",
        value: "Open in New Private Tab",
        comment: "Context menu option for opening a link in a new private tab",
        lastUpdated: .unknown)

    public static let ContextMenuBookmarkLink = MZLocalizedString(
        "ContextMenu.BookmarkLinkButtonTitle",
        value: "Bookmark Link",
        comment: "Context menu item for bookmarking a link URL",
        lastUpdated: .unknown)
    public static let ContextMenuDownloadLink = MZLocalizedString(
        "ContextMenu.DownloadLinkButtonTitle",
        value: "Download Link",
        comment: "Context menu item for downloading a link URL",
        lastUpdated: .unknown)
    public static let ContextMenuCopyLink = MZLocalizedString(
        "ContextMenu.CopyLinkButtonTitle",
        value: "Copy Link",
        comment: "Context menu item for copying a link URL to the clipboard",
        lastUpdated: .unknown)
    public static let ContextMenuShareLink = MZLocalizedString(
        "ContextMenu.ShareLinkButtonTitle",
        value: "Share Link",
        comment: "Context menu item for sharing a link URL",
        lastUpdated: .unknown)
    public static let ContextMenuSaveImage = MZLocalizedString(
        "ContextMenu.SaveImageButtonTitle",
        value: "Save Image",
        comment: "Context menu item for saving an image",
        lastUpdated: .unknown)
    public static let ContextMenuCopyImage = MZLocalizedString(
        "ContextMenu.CopyImageButtonTitle",
        value: "Copy Image",
        comment: "Context menu item for copying an image to the clipboard",
        lastUpdated: .unknown)
    public static let ContextMenuCopyImageLink = MZLocalizedString(
        "ContextMenu.CopyImageLinkButtonTitle",
        value: "Copy Image Link",
        comment: "Context menu item for copying an image URL to the clipboard",
        lastUpdated: .unknown)
}

// MARK: - Photo Library access
extension String {
    public static let PhotoLibraryFirefoxWouldLikeAccessTitle = MZLocalizedString(
        "PhotoLibrary.FirefoxWouldLikeAccessTitle",
        value: "Firefox would like to access your Photos",
        comment: "See http://mzl.la/1G7uHo7",
        lastUpdated: .unknown)
    public static let PhotoLibraryFirefoxWouldLikeAccessMessage = MZLocalizedString(
        "PhotoLibrary.FirefoxWouldLikeAccessMessage",
        value: "This allows you to save the image to your Camera Roll.",
        comment: "See http://mzl.la/1G7uHo7",
        lastUpdated: .unknown)
}

// MARK: - Sent tabs notifications
// These are displayed when the app is backgrounded or the device is locked.
extension String {
    // zero tabs
    public static let SentTab_NoTabArrivingNotification_title = MZLocalizedString(
        "SentTab.NoTabArrivingNotification.title",
        value: "Firefox Sync",
        comment: "Title of notification received after a spurious message from FxA has been received.",
        lastUpdated: .unknown)
    public static let SentTab_NoTabArrivingNotification_body =
    MZLocalizedString(
        "SentTab.NoTabArrivingNotification.body",
        value: "Tap to begin",
        comment: "Body of notification received after a spurious message from FxA has been received.",
        lastUpdated: .unknown)

    // one or more tabs
    public static let SentTab_TabArrivingNotification_NoDevice_title = MZLocalizedString(
        "SentTab_TabArrivingNotification_NoDevice_title",
        value: "Tab received",
        comment: "Title of notification shown when the device is sent one or more tabs from an unnamed device.",
        lastUpdated: .unknown)
    public static let SentTab_TabArrivingNotification_NoDevice_body = MZLocalizedString(
        "SentTab_TabArrivingNotification_NoDevice_body",
        value: "New tab arrived from another device.",
        comment: "Body of notification shown when the device is sent one or more tabs from an unnamed device.",
        lastUpdated: .unknown)
    public static let SentTab_TabArrivingNotification_WithDevice_title = MZLocalizedString(
        "SentTab_TabArrivingNotification_WithDevice_title",
        value: "Tab received from %@",
        comment: "Title of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the device name. This device name will be localized by that device.",
        lastUpdated: .unknown)
    public static let SentTab_TabArrivingNotification_WithDevice_body = MZLocalizedString(
        "SentTab_TabArrivingNotification_WithDevice_body",
        value: "New tab arrived in %@",
        comment: "Body of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the app name.",
        lastUpdated: .unknown)

    // Notification Actions
    public static let SentTabViewActionTitle = MZLocalizedString(
        "SentTab.ViewAction.title",
        value: "View",
        comment: "Label for an action used to view one or more tabs from a notification.",
        lastUpdated: .unknown)
}

// MARK: - Additional messages sent via Push from FxA
extension String {
    public static let FxAPush_DeviceDisconnected_ThisDevice_title = MZLocalizedString(
        "FxAPush_DeviceDisconnected_ThisDevice_title",
        value: "Sync Disconnected",
        comment: "Title of a notification displayed when this device has been disconnected by another device.",
        lastUpdated: .unknown)
    public static let FxAPush_DeviceDisconnected_ThisDevice_body = MZLocalizedString(
        "FxAPush_DeviceDisconnected_ThisDevice_body",
        value: "This device has been successfully disconnected from Firefox Sync.",
        comment: "Body of a notification displayed when this device has been disconnected from FxA by another device.",
        lastUpdated: .unknown)
    public static let FxAPush_DeviceDisconnected_title = MZLocalizedString(
        "FxAPush_DeviceDisconnected_title",
        value: "Sync Disconnected",
        comment: "Title of a notification displayed when named device has been disconnected from FxA.",
        lastUpdated: .unknown)
    public static let FxAPush_DeviceDisconnected_body = MZLocalizedString(
        "FxAPush_DeviceDisconnected_body",
        value: "%@ has been successfully disconnected.",
        comment: "Body of a notification displayed when named device has been disconnected from FxA. %@ refers to the name of the disconnected device.",
        lastUpdated: .unknown)

    public static let FxAPush_DeviceDisconnected_UnknownDevice_body = MZLocalizedString(
        "FxAPush_DeviceDisconnected_UnknownDevice_body",
        value: "A device has disconnected from Firefox Sync",
        comment: "Body of a notification displayed when unnamed device has been disconnected from FxA.",
        lastUpdated: .unknown)

    public static let FxAPush_DeviceConnected_title = MZLocalizedString(
        "FxAPush_DeviceConnected_title",
        value: "Sync Connected",
        comment: "Title of a notification displayed when another device has connected to FxA.",
        lastUpdated: .unknown)
    public static let FxAPush_DeviceConnected_body = MZLocalizedString(
        "FxAPush_DeviceConnected_body",
        value: "Firefox Sync has connected to %@",
        comment: "Title of a notification displayed when another device has connected to FxA. %@ refers to the name of the newly connected device.",
        lastUpdated: .unknown)
}

// MARK: - Reader Mode
extension String {
    public static let ReaderModeAvailableVoiceOverAnnouncement = MZLocalizedString(
        "ReaderMode.Available.VoiceOverAnnouncement",
        value: "Reader Mode available",
        comment: "Accessibility message e.g. spoken by VoiceOver when Reader Mode becomes available.",
        lastUpdated: .unknown)
    public static let ReaderModeResetFontSizeAccessibilityLabel = MZLocalizedString(
        "Reset text size",
        comment: "Accessibility label for button resetting font size in display settings of reader mode",
        lastUpdated: .unknown)
}

// MARK: - QR Code scanner
extension String {
    public static let ScanQRCodeViewTitle = MZLocalizedString(
        "ScanQRCode.View.Title",
        value: "Scan QR Code",
        comment: "Title for the QR code scanner view.",
        lastUpdated: .unknown)
    public static let ScanQRCodeInstructionsLabel = MZLocalizedString(
        "ScanQRCode.Instructions.Label",
        value: "Align QR code within frame to scan",
        comment: "Text for the instructions label, displayed in the QR scanner view",
        lastUpdated: .unknown)
    public static let ScanQRCodeInvalidDataErrorMessage = MZLocalizedString(
        "ScanQRCode.InvalidDataError.Message",
        value: "The data is invalid",
        comment: "Text of the prompt that is shown to the user when the data is invalid",
        lastUpdated: .unknown)
    public static let ScanQRCodePermissionErrorMessage = MZLocalizedString(
        "ScanQRCode.PermissionError.Message.v100",
        value: "Go to device ‘Settings’ > ‘Firefox’. Allow Firefox to access camera.",
        comment: "Text of the prompt to setup the camera authorization for the Scan QR Code feature.",
        lastUpdated: .v99)
    public static let ScanQRCodeErrorOKButton = MZLocalizedString(
        "ScanQRCode.Error.OK.Button",
        value: "OK",
        comment: "OK button to dismiss the error prompt.",
        lastUpdated: .unknown)
}

// MARK: - App menu
extension String {
    /// Identifiers of all new strings should begin with `Menu.`
    public struct AppMenu {
        public static let AppMenuReportSiteIssueTitleString = MZLocalizedString(
            "Menu.ReportSiteIssueAction.Title",
            tableName: "Menu",
            value: "Report Site Issue",
            comment: "Label for the button, displayed in the menu, used to report a compatibility issue with the current page.",
            lastUpdated: .unknown)
        public static let AppMenuSharePageTitleString = MZLocalizedString(
            "Menu.SharePageAction.Title",
            tableName: "Menu",
            value: "Share Page With…",
            comment: "Label for the button, displayed in the menu, used to open the share dialog.",
            lastUpdated: .unknown)
        public static let AppMenuCopyLinkTitleString = MZLocalizedString(
            "Menu.CopyLink.Title",
            tableName: "Menu",
            value: "Copy Link",
            comment: "Label for the button, displayed in the menu, used to copy the current page link to the clipboard.",
            lastUpdated: .unknown)
        public static let AppMenuFindInPageTitleString = MZLocalizedString(
            "Menu.FindInPageAction.Title",
            tableName: "Menu",
            value: "Find in Page",
            comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.",
            lastUpdated: .unknown)
        public static let AppMenuViewDesktopSiteTitleString = MZLocalizedString(
            "Menu.ViewDekstopSiteAction.Title",
            tableName: "Menu",
            value: "Request Desktop Site",
            comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.",
            lastUpdated: .unknown)
        public static let AppMenuViewMobileSiteTitleString = MZLocalizedString(
            "Menu.ViewMobileSiteAction.Title",
            tableName: "Menu",
            value: "Request Mobile Site",
            comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.",
            lastUpdated: .unknown)
        public static let AppMenuSettingsTitleString = MZLocalizedString(
            "Menu.OpenSettingsAction.Title",
            tableName: "Menu",
            value: "Settings",
            comment: "Label for the button, displayed in the menu, used to open the Settings menu.",
            lastUpdated: .unknown)
        public static let AppMenuCloseAllTabsTitleString = MZLocalizedString(
            "Menu.CloseAllTabsAction.Title",
            tableName: "Menu",
            value: "Close All Tabs",
            comment: "Label for the button, displayed in the menu, used to close all tabs currently open.",
            lastUpdated: .unknown)
        public static let AppMenuOpenHomePageTitleString = MZLocalizedString(
            "SettingsMenu.OpenHomePageAction.Title",
            tableName: "Menu",
            value: "Homepage",
            comment: "Label for the button, displayed in the menu, used to navigate to the home page.",
            lastUpdated: .unknown)
        public static let AppMenuBookmarksTitleString = MZLocalizedString(
            "Menu.OpenBookmarksAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Bookmarks",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel. Please keep as short as possible, <15 chars of space available.",
            lastUpdated: .unknown)
        public static let AppMenuReadingListTitleString = MZLocalizedString(
            "Menu.OpenReadingListAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Reading List",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel. Please keep as short as possible, <15 chars of space available.",
            lastUpdated: .unknown)
        public static let AppMenuHistoryTitleString = MZLocalizedString(
            "Menu.OpenHistoryAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "History",
            comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel. Please keep as short as possible, <15 chars of space available.",
            lastUpdated: .unknown)
        public static let AppMenuDownloadsTitleString = MZLocalizedString(
            "Menu.OpenDownloadsAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Downloads",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel. Please keep as short as possible, <15 chars of space available.",
            lastUpdated: .unknown)
        public static let AppMenuSyncedTabsTitleString = MZLocalizedString(
            "Menu.OpenSyncedTabsAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Synced Tabs",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Synced Tabs home panel. Please keep as short as possible, <15 chars of space available.",
            lastUpdated: .unknown)
        public static let AppMenuTurnOnNightMode = MZLocalizedString(
            "Menu.NightModeTurnOn.Label2",
            value: "Turn on Night Mode",
            comment: "Label for the button, displayed in the menu, turns on night mode.",
            lastUpdated: .unknown)
        public static let AppMenuTurnOffNightMode = MZLocalizedString(
            "Menu.NightModeTurnOff.Label2",
            value: "Turn off Night Mode",
            comment: "Label for the button, displayed in the menu, turns off night mode.",
            lastUpdated: .unknown)
        public static let AppMenuHistory = MZLocalizedString(
            "Menu.History.Label",
            value: "History",
            comment: "Label for the button, displayed in the menu, takes you to to History screen when pressed.",
            lastUpdated: .unknown)
        public static let AppMenuDownloads = MZLocalizedString(
            "Menu.Downloads.Label",
            value: "Downloads",
            comment: "Label for the button, displayed in the menu, takes you to to Downloads screen when pressed.",
            lastUpdated: .unknown)
        public static let AppMenuPasswords = MZLocalizedString(
            "Menu.Passwords.Label",
            value: "Passwords",
            comment: "Label for the button, displayed in the menu, takes you to to passwords screen when pressed.",
            lastUpdated: .unknown)
        public static let AppMenuCopyURLConfirmMessage = MZLocalizedString(
            "Menu.CopyURL.Confirm",
            value: "URL Copied To Clipboard",
            comment: "Toast displayed to user after copy url pressed.",
            lastUpdated: .unknown)
        public static let AppMenuTabSentConfirmMessage = MZLocalizedString(
            "Menu.TabSent.Confirm",
            value: "Tab Sent",
            comment: "Toast displayed to the user after a tab has been sent successfully.",
            lastUpdated: .unknown)
        public static let WhatsNewString = MZLocalizedString(
            "Menu.WhatsNew.Title",
            value: "What’s New",
            comment: "The title for the option to view the What's new page.",
            lastUpdated: .unknown)
        public static let CustomizeHomePage = MZLocalizedString(
            "Menu.CustomizeHomePage.v99",
            value: "Customize Homepage",
            comment: "Label for the customize homepage button in the menu page. Pressing this button takes users to the settings options, where they can customize the Firefox Home page",
            lastUpdated: .v99)
        public static let NewTab = MZLocalizedString(
            "Menu.NewTab.v99",
            value: "New Tab",
            comment: "Label for the new tab button in the menu page. Pressing this button opens a new tab.",
            lastUpdated: .v99)
        public static let Help = MZLocalizedString(
            "Menu.Help.v99",
            value: "Help",
            comment: "Label for the help button in the menu page. Pressing this button opens the support page https://support.mozilla.org/en-US/products/ios",
            lastUpdated: .v99)
        public static let Share = MZLocalizedString(
            "Menu.Share.v99",
            value: "Share",
            comment: "Label for the share button in the menu page. Pressing this button open the share menu to share the current website.",
            lastUpdated: .v99)
        public static let SyncAndSaveData = MZLocalizedString(
            "Menu.SyncAndSaveData.v103",
            value: "Sync and Save Data",
            comment: "Label for the Firefox Sync button in the menu page. Pressing this button open the sign in to Firefox page service to sync and save data.",
            lastUpdated: .v103)

        // Shortcuts
        public static let AddToShortcuts = MZLocalizedString(
            "Menu.AddToShortcuts.v99",
            value: "Add to Shortcuts",
            comment: "Label for the add to shortcuts button in the menu. Pressing this button pins the current website as a shortcut on the home page.",
            lastUpdated: .v99)
        public static let RemoveFromShortcuts = MZLocalizedString(
            "Menu.RemovedFromShortcuts.v99",
            value: "Remove from Shortcuts",
            comment: "Label for the remove from shortcuts button in the menu. Pressing this button removes the current website from the shortcut pins on the home page.",
            lastUpdated: .v99)
        public static let AddPinToShortcutsConfirmMessage = MZLocalizedString(
            "Menu.AddPin.Confirm2",
            value: "Added to Shortcuts",
            comment: "Toast displayed to the user after adding the item to the Shortcuts.",
            lastUpdated: .unknown)
        public static let RemovePinFromShortcutsConfirmMessage = MZLocalizedString(
            "Menu.RemovePin.Confirm2.v99",
            value: "Removed from Shortcuts",
            comment: "Toast displayed to the user after removing the item to the Shortcuts.",
            lastUpdated: .v99)

        // Bookmarks
        public static let Bookmarks = MZLocalizedString(
            "Menu.Bookmarks.Label",
            value: "Bookmarks",
            comment: "Label for the button, displayed in the menu, takes you to to bookmarks screen when pressed.",
            lastUpdated: .unknown)
        public static let AddBookmark = MZLocalizedString(
            "Menu.AddBookmark.Label.v99",
            value: "Add",
            comment: "Label for the add bookmark button in the menu. Pressing this button bookmarks the current page. Please keep the text as short as possible for this label.",
            lastUpdated: .v99)
        public static let AddBookmarkAlternateTitle = MZLocalizedString(
            "Menu.AddBookmark.AlternateLabel.v99",
            value: "Add Bookmark",
            comment: "Long label for the add bookmark button displayed in the menu. Pressing this button bookmarks the current page.",
            lastUpdated: .v99)
        public static let AddBookmarkConfirmMessage = MZLocalizedString(
            "Menu.AddBookmark.Confirm",
            value: "Bookmark Added",
            comment: "Toast displayed to the user after a bookmark has been added.",
            lastUpdated: .unknown)
        public static let RemoveBookmark = MZLocalizedString(
            "Menu.RemoveBookmark.Label.v99",
            value: "Remove",
            comment: "Label for the remove bookmark button in the menu. Pressing this button remove the current page from the bookmarks. Please keep the text as short as possible for this label.",
            lastUpdated: .v99)
        public static let RemoveBookmarkAlternateTitle = MZLocalizedString(
            "Menu.RemoveBookmark.AlternateLabel.v99",
            tableName: "Menu",
            value: "Remove Bookmark",
            comment: "Long label for the remove bookmark button displayed in the menu. Pressing this button remove the current page from the bookmarks.",
            lastUpdated: .v99)
        public static let RemoveBookmarkConfirmMessage = MZLocalizedString(
            "Menu.RemoveBookmark.Confirm",
            value: "Bookmark Removed",
            comment: "Toast displayed to the user after a bookmark has been removed.",
            lastUpdated: .unknown)

        // Reading list
        public static let ReadingList = MZLocalizedString(
            "Menu.ReadingList.Label",
            value: "Reading List",
            comment: "Label for the button, displayed in the menu, takes you to to Reading List screen when pressed.",
            lastUpdated: .unknown)
        public static let AddReadingList = MZLocalizedString(
            "Menu.AddReadingList.Label.v99",
            value: "Add",
            comment: "Label for the add to reading list button in the menu. Pressing this button adds the current page to the reading list. Please keep the text as short as possible for this label.",
            lastUpdated: .v99)
        public static let AddReadingListAlternateTitle = MZLocalizedString(
            "Menu.AddToReadingList.AlternateLabel.v99",
            tableName: "Menu",
            value: "Add to Reading List",
            comment: "Long label for the button displayed in the menu, used to add a page to the reading list.",
            lastUpdated: .v99)
        public static let AddToReadingListConfirmMessage = MZLocalizedString(
            "Menu.AddToReadingList.Confirm",
            value: "Added To Reading List",
            comment: "Toast displayed to the user after adding the item to their reading list.",
            lastUpdated: .unknown)
        public static let RemoveReadingList = MZLocalizedString(
            "Menu.RemoveReadingList.Label.v99",
            value: "Remove",
            comment: "Label for the remove from reading list button in the menu. Pressing this button removes the current page from the reading list. Please keep the text as short as possible for this label.",
            lastUpdated: .v99)
        public static let RemoveReadingListAlternateTitle = MZLocalizedString(
            "Menu.RemoveReadingList.AlternateLabel.v99",
            value: "Remove from Reading List",
            comment: "Long label for the remove from reading list button in the menu. Pressing this button removes the current page from the reading list.",
            lastUpdated: .v99)
        public static let RemoveFromReadingListConfirmMessage = MZLocalizedString(
            "Menu.RemoveReadingList.Confirm.v99",
            value: "Removed from Reading List",
            comment: "Toast displayed to confirm to the user that his reading list item was correctly removed.",
            lastUpdated: .v99)

        // Toolbar
        public struct Toolbar {
            public static let MenuButtonAccessibilityLabel = MZLocalizedString(
                "Toolbar.Menu.AccessibilityLabel",
                value: "Menu",
                comment: "Accessibility label for the Menu button.",
                lastUpdated: .unknown)
            public static let HomeMenuButtonAccessibilityLabel = MZLocalizedString(
                "Menu.Toolbar.Home.AccessibilityLabel.v99",
                value: "Home",
                comment: "Accessibility label for the Home button on the toolbar. Pressing this button brings the user to the home page.",
                lastUpdated: .v99)
            public static let BookmarksButtonAccessibilityLabel = MZLocalizedString(
                "Menu.Toolbar.Bookmarks.AccessibilityLabel.v99",
                value: "Bookmarks",
                comment: "Accessibility label for the Bookmark button on the toolbar. Pressing this button opens the bookmarks menu",
                lastUpdated: .v99)
            public static let TabTrayDeleteMenuButtonAccessibilityLabel = MZLocalizedString(
                "Toolbar.Menu.CloseAllTabs",
                value: "Close All Tabs",
                comment: "Accessibility label for the Close All Tabs menu button.",
                lastUpdated: .unknown)
        }

        // 3D TouchActions
        public struct TouchActions {
            public static let SendToDeviceTitle = MZLocalizedString(
                "Send to Device",
                tableName: "3DTouchActions",
                comment: "Label for preview action on Tab Tray Tab to send the current tab to another device",
                lastUpdated: .unknown)
            public static let SendLinkToDeviceTitle = MZLocalizedString(
                "Menu.SendLinkToDevice",
                tableName: "3DTouchActions",
                value: "Send Link to Device",
                comment: "Label for preview action on Tab Tray Tab to send the current link to another device",
                lastUpdated: .unknown)
        }
    }
}

// MARK: - Snackbar shown when tapping app store link
extension String {
    public static let ExternalLinkAppStoreConfirmationTitle = MZLocalizedString(
        "ExternalLink.AppStore.ConfirmationTitle",
        value: "Open this link in the App Store?",
        comment: "Question shown to user when tapping a link that opens the App Store app",
        lastUpdated: .unknown)
    public static let ExternalLinkGenericConfirmation = MZLocalizedString(
        "ExternalLink.AppStore.GenericConfirmationTitle",
        value: "Open this link in external app?",
        comment: "Question shown to user when tapping an SMS or MailTo link that opens the external app for those.",
        lastUpdated: .unknown)
}

// MARK: - ContentBlocker/TrackingProtection string
extension String {
    public static let SettingsTrackingProtectionSectionName = MZLocalizedString(
        "Settings.TrackingProtection.SectionName",
        value: "Tracking Protection",
        comment: "Row in top-level of settings that gets tapped to show the tracking protection settings detail view.",
        lastUpdated: .unknown)

    public static let TrackingProtectionEnableTitle = MZLocalizedString(
        "Settings.TrackingProtectionOption.NormalBrowsingLabelOn",
        value: "Enhanced Tracking Protection",
        comment: "Settings option to specify that Tracking Protection is on",
        lastUpdated: .unknown)

    public static let TrackingProtectionOptionProtectionLevelTitle = MZLocalizedString(
        "Settings.TrackingProtection.ProtectionLevelTitle",
        value: "Protection Level",
        comment: "Title for tracking protection options section where level can be selected.",
        lastUpdated: .unknown)
    public static let TrackingProtectionOptionBlockListLevelStandard = MZLocalizedString(
        "Settings.TrackingProtectionOption.BasicBlockList",
        value: "Standard (default)",
        comment: "Tracking protection settings option for using the basic blocklist.",
        lastUpdated: .unknown)
    public static let TrackingProtectionOptionBlockListLevelStrict = MZLocalizedString(
        "Settings.TrackingProtectionOption.BlockListStrict",
        value: "Strict",
        comment: "Tracking protection settings option for using the strict blocklist.",
        lastUpdated: .unknown)
    public static let TrackingProtectionReloadWithout = MZLocalizedString(
        "Menu.ReloadWithoutTrackingProtection.Title",
        value: "Reload Without Tracking Protection",
        comment: "Label for the button, displayed in the menu, used to reload the current website without Tracking Protection",
        lastUpdated: .unknown)
    public static let TrackingProtectionReloadWith = MZLocalizedString(
        "Menu.ReloadWithTrackingProtection.Title",
        value: "Reload With Tracking Protection",
        comment: "Label for the button, displayed in the menu, used to reload the current website with Tracking Protection enabled",
        lastUpdated: .unknown)

    public static let TrackingProtectionCellFooter = MZLocalizedString(
        "Settings.TrackingProtection.ProtectionCellFooter",
        value: "Reduces targeted ads and helps stop advertisers from tracking your browsing.",
        comment: "Additional information about your Enhanced Tracking Protection",
        lastUpdated: .unknown)
    public static let TrackingProtectionStandardLevelDescription = MZLocalizedString(
        "Settings.TrackingProtection.ProtectionLevelStandard.Description",
        value: "Allows some ad tracking so websites function properly.",
        comment: "Description for standard level tracker protection",
        lastUpdated: .unknown)
    public static let TrackingProtectionStrictLevelDescription = MZLocalizedString(
        "Settings.TrackingProtection.ProtectionLevelStrict.Description",
        value: "Blocks more trackers, ads, and popups. Pages load faster, but some functionality may not work.",
        comment: "Description for strict level tracker protection",
        lastUpdated: .unknown)
    public static let TrackingProtectionLevelFooter = MZLocalizedString(
        "Settings.TrackingProtection.ProtectionLevel.Footer",
        value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.",
        comment: "Footer information for tracker protection level.",
        lastUpdated: .unknown)
    public static let TrackerProtectionLearnMore = MZLocalizedString(
        "Settings.TrackingProtection.LearnMore",
        value: "Learn more",
        comment: "'Learn more' info link on the Tracking Protection settings screen.",
        lastUpdated: .unknown)
    public static let TrackerProtectionAlertTitle =  MZLocalizedString(
        "Settings.TrackingProtection.Alert.Title",
        value: "Heads up!",
        comment: "Title for the tracker protection alert.",
        lastUpdated: .unknown)
    public static let TrackerProtectionAlertDescription =  MZLocalizedString(
        "Settings.TrackingProtection.Alert.Description",
        value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.",
        comment: "Decription for the tracker protection alert.",
        lastUpdated: .unknown)
    public static let TrackerProtectionAlertButton =  MZLocalizedString(
        "Settings.TrackingProtection.Alert.Button",
        value: "OK, Got It",
        comment: "Dismiss button for the tracker protection alert.",
        lastUpdated: .unknown)
}

// MARK: - Tracking Protection menu
extension String {
    public static let ETPOn = MZLocalizedString(
        "Menu.EnhancedTrackingProtectionOn.Title",
        value: "Protections are ON for this site",
        comment: "A switch to enable enhanced tracking protection inside the menu.",
        lastUpdated: .unknown)
    public static let ETPOff = MZLocalizedString(
        "Menu.EnhancedTrackingProtectionOff.Title",
        value: "Protections are OFF for this site",
        comment: "A switch to disable enhanced tracking protection inside the menu.",
        lastUpdated: .unknown)

    public static let TPDetailsVerifiedBy = MZLocalizedString(
        "Menu.TrackingProtection.Details.Verifier",
        value: "Verified by %@",
        comment: "String to let users know the site verifier, where the placeholder represents the SSL certificate signer.",
        lastUpdated: .unknown)

    // Category Titles
    public static let TPCryptominersBlocked = MZLocalizedString(
        "Menu.TrackingProtectionCryptominersBlocked.Title",
        value: "Cryptominers",
        comment: "The title that shows the number of cryptomining scripts blocked",
        lastUpdated: .unknown)
    public static let TPFingerprintersBlocked = MZLocalizedString(
        "Menu.TrackingProtectionFingerprintersBlocked.Title",
        value: "Fingerprinters",
        comment: "The title that shows the number of fingerprinting scripts blocked",
        lastUpdated: .unknown)
    public static let TPCrossSiteBlocked = MZLocalizedString(
        "Menu.TrackingProtectionCrossSiteTrackers.Title",
        value: "Cross-Site Trackers",
        comment: "The title that shows the number of cross-site URLs blocked",
        lastUpdated: .unknown)
    public static let TPSocialBlocked = MZLocalizedString(
        "Menu.TrackingProtectionBlockedSocial.Title",
        value: "Social Trackers",
        comment: "The title that shows the number of social URLs blocked",
        lastUpdated: .unknown)
    public static let TPContentBlocked = MZLocalizedString(
        "Menu.TrackingProtectionBlockedContent.Title",
        value: "Tracking content",
        comment: "The title that shows the number of content cookies blocked",
        lastUpdated: .unknown)

    // Shortcut on bottom of TP page menu to get to settings.
    public static let TPProtectionSettings = MZLocalizedString(
        "Menu.TrackingProtection.ProtectionSettings.Title",
        value: "Protection Settings",
        comment: "The title for tracking protection settings",
        lastUpdated: .unknown)

    // Settings info
    public static let TPAccessoryInfoBlocksTitle = MZLocalizedString(
        "Settings.TrackingProtection.Info.BlocksTitle",
        value: "BLOCKS",
        comment: "The Title on info view which shows a list of all blocked websites",
        lastUpdated: .unknown)

    // Category descriptions
    public static let TPCategoryDescriptionSocial = MZLocalizedString(
        "Menu.TrackingProtectionDescription.SocialNetworksNew",
        value: "Social networks place trackers on other websites to build a more complete and targeted profile of you. Blocking these trackers reduces how much social media companies can see what do you online.",
        comment: "Description of social network trackers.",
        lastUpdated: .unknown)
    public static let TPCategoryDescriptionCrossSite = MZLocalizedString(
        "Menu.TrackingProtectionDescription.CrossSiteNew",
        value: "These cookies follow you from site to site to gather data about what you do online. They are set by third parties such as advertisers and analytics companies.",
        comment: "Description of cross-site trackers.",
        lastUpdated: .unknown)
    public static let TPCategoryDescriptionCryptominers = MZLocalizedString(
        "Menu.TrackingProtectionDescription.CryptominersNew",
        value: "Cryptominers secretly use your system’s computing power to mine digital money. Cryptomining scripts drain your battery, slow down your computer, and can increase your energy bill.",
        comment: "Description of cryptominers.",
        lastUpdated: .unknown)
    public static let TPCategoryDescriptionFingerprinters = MZLocalizedString(
        "Menu.TrackingProtectionDescription.Fingerprinters",
        value: "The settings on your browser and computer are unique. Fingerprinters collect a variety of these unique settings to create a profile of you, which can be used to track you as you browse.",
        comment: "Description of fingerprinters.",
        lastUpdated: .unknown)
    public static let TPCategoryDescriptionContentTrackers = MZLocalizedString(
        "Menu.TrackingProtectionDescription.ContentTrackers",
        value: "Websites may load outside ads, videos, and other content that contains hidden trackers. Blocking this can make websites load faster, but some buttons, forms, and login fields, might not work.",
        comment: "Description of content trackers.",
        lastUpdated: .unknown)
}

// MARK: - Location bar long press menu
extension String {
    public static let PasteAndGoTitle = MZLocalizedString(
        "Menu.PasteAndGo.Title",
        value: "Paste & Go",
        comment: "The title for the button that lets you paste and go to a URL",
        lastUpdated: .unknown)
    public static let PasteTitle = MZLocalizedString(
        "Menu.Paste.Title",
        value: "Paste",
        comment: "The title for the button that lets you paste into the location bar",
        lastUpdated: .unknown)
    public static let CopyAddressTitle = MZLocalizedString(
        "Menu.Copy.Title",
        value: "Copy Address",
        comment: "The title for the button that lets you copy the url from the location bar.",
        lastUpdated: .unknown)
}

// MARK: - Settings Home
extension String {
    public static let SendUsageSettingTitle = MZLocalizedString(
        "Settings.SendUsage.Title",
        value: "Send Usage Data",
        comment: "The title for the setting to send usage data.",
        lastUpdated: .unknown)
    public static let SendUsageSettingLink = MZLocalizedString(
        "Settings.SendUsage.Link",
        value: "Learn More.",
        comment: "title for a link that explains how mozilla collects telemetry",
        lastUpdated: .unknown)
    public static let SendUsageSettingMessage = MZLocalizedString(
        "Settings.SendUsage.Message",
        value: "Mozilla strives to only collect what we need to provide and improve Firefox for everyone.",
        comment: "A short description that explains why mozilla collects usage data.",
        lastUpdated: .unknown)
    public static let SettingsSiriSectionName = MZLocalizedString(
        "Settings.Siri.SectionName",
        value: "Siri Shortcuts",
        comment: "The option that takes you to the siri shortcuts settings page",
        lastUpdated: .unknown)
    public static let SettingsSiriSectionDescription = MZLocalizedString(
        "Settings.Siri.SectionDescription",
        value: "Use Siri shortcuts to quickly open Firefox via Siri",
        comment: "The description that describes what siri shortcuts are",
        lastUpdated: .unknown)
    public static let SettingsSiriOpenURL = MZLocalizedString(
        "Settings.Siri.OpenTabShortcut",
        value: "Open New Tab",
        comment: "The description of the open new tab siri shortcut",
        lastUpdated: .unknown)
}

// MARK: - Nimbus settings
extension String {
    public static let SettingsStudiesToggleTitle = MZLocalizedString(
        "Settings.Studies.Toggle.Title",
        value: "Studies",
        comment: "Label used as a toggle item in Settings. When this is off, the user is opting out of all studies.",
        lastUpdated: .unknown)
    public static let SettingsStudiesToggleLink = MZLocalizedString(
        "Settings.Studies.Toggle.Link",
        value: "Learn More.",
        comment: "Title for a link that explains what Mozilla means by Studies",
        lastUpdated: .unknown)
    public static let SettingsStudiesToggleMessage = MZLocalizedString(
        "Settings.Studies.Toggle.Message",
        value: "Firefox may install and run studies from time to time.",
        comment: "A short description that explains that Mozilla is running studies",
        lastUpdated: .unknown)
}

// MARK: - Intro Onboarding slides
extension String {
    public static let CardTitleWelcome = MZLocalizedString(
        "Intro.Slides.Welcome.Title.v2",
        tableName: "Intro",
        value: "Welcome to Firefox",
        comment: "Title for the first panel 'Welcome' in the First Run tour.",
        lastUpdated: .unknown)
    public static let StartBrowsingButtonTitle = MZLocalizedString(
        "Start Browsing",
        tableName: "Intro",
        comment: "See http://mzl.la/1T8gxwo",
        lastUpdated: .unknown)
    public static let IntroSignInButtonTitle = MZLocalizedString(
        "Intro.Slides.Button.SignIn",
        tableName: "Intro",
        value: "Sign In",
        comment: "Sign in to Firefox account button on second intro screen.",
        lastUpdated: .unknown)
}

// MARK: - Share extension
extension String {
    public static let SendToCancelButton = MZLocalizedString(
        "SendTo.Cancel.Button",
        value: "Cancel",
        comment: "Button title for cancelling share screen",
        lastUpdated: .unknown)
    public static let SendToErrorOKButton = MZLocalizedString(
        "SendTo.Error.OK.Button",
        value: "OK",
        comment: "OK button to dismiss the error prompt.",
        lastUpdated: .unknown)
    public static let SendToErrorTitle = MZLocalizedString(
        "SendTo.Error.Title",
        value: "The link you are trying to share cannot be shared.",
        comment: "Title of error prompt displayed when an invalid URL is shared.",
        lastUpdated: .unknown)
    public static let SendToErrorMessage = MZLocalizedString(
        "SendTo.Error.Message",
        value: "Only HTTP and HTTPS links can be shared.",
        comment: "Message in error prompt explaining why the URL is invalid.",
        lastUpdated: .unknown)
    public static let SendToCloseButton = MZLocalizedString(
        "SendTo.Close.Button",
        value: "Close",
        comment: "Close button in top navigation bar",
        lastUpdated: .unknown)
    public static let SendToNotSignedInText = MZLocalizedString(
        "SendTo.NotSignedIn.Title",
        value: "You are not signed in to your Firefox Account.",
        comment: "See http://mzl.la/1ISlXnU",
        lastUpdated: .unknown)
    public static let SendToNotSignedInMessage = MZLocalizedString(
        "SendTo.NotSignedIn.Message",
        value: "Please open Firefox, go to Settings and sign in to continue.",
        comment: "See http://mzl.la/1ISlXnU",
        lastUpdated: .unknown)
    public static let SendToNoDevicesFound = MZLocalizedString(
        "SendTo.NoDevicesFound.Message",
        value: "You don’t have any other devices connected to this Firefox Account available to sync.",
        comment: "Error message shown in the remote tabs panel",
        lastUpdated: .unknown)
    public static let SendToTitle = MZLocalizedString(
        "SendTo.NavBar.Title",
        value: "Send Tab",
        comment: "Title of the dialog that allows you to send a tab to a different device",
        lastUpdated: .unknown)
    public static let SendToSendButtonTitle = MZLocalizedString(
        "SendTo.SendAction.Text",
        value: "Send",
        comment: "Navigation bar button to Send the current page to a device",
        lastUpdated: .unknown)
    public static let SendToDevicesListTitle = MZLocalizedString(
        "SendTo.DeviceList.Text",
        value: "Available devices:",
        comment: "Header for the list of devices table",
        lastUpdated: .unknown)
    public static let ShareSendToDevice = String.AppMenu.TouchActions.SendToDeviceTitle

    // The above items are re-used strings from the old extension. New strings below.

    public static let ShareAddToReadingList = MZLocalizedString(
        "ShareExtension.AddToReadingListAction.Title",
        value: "Add to Reading List",
        comment: "Action label on share extension to add page to the Firefox reading list.",
        lastUpdated: .unknown)
    public static let ShareAddToReadingListDone = MZLocalizedString(
        "ShareExtension.AddToReadingListActionDone.Title",
        value: "Added to Reading List",
        comment: "Share extension label shown after user has performed 'Add to Reading List' action.",
        lastUpdated: .unknown)
    public static let ShareBookmarkThisPage = MZLocalizedString(
        "ShareExtension.BookmarkThisPageAction.Title",
        value: "Bookmark This Page",
        comment: "Action label on share extension to bookmark the page in Firefox.",
        lastUpdated: .unknown)
    public static let ShareBookmarkThisPageDone = MZLocalizedString(
        "ShareExtension.BookmarkThisPageActionDone.Title",
        value: "Bookmarked",
        comment: "Share extension label shown after user has performed 'Bookmark this Page' action.",
        lastUpdated: .unknown)

    public static let ShareOpenInFirefox = MZLocalizedString(
        "ShareExtension.OpenInFirefoxAction.Title",
        value: "Open in Firefox",
        comment: "Action label on share extension to immediately open page in Firefox.",
        lastUpdated: .unknown)
    public static let ShareSearchInFirefox = MZLocalizedString(
        "ShareExtension.SeachInFirefoxAction.Title",
        value: "Search in Firefox",
        comment: "Action label on share extension to search for the selected text in Firefox.",
        lastUpdated: .unknown)

    public static let ShareLoadInBackground = MZLocalizedString(
        "ShareExtension.LoadInBackgroundAction.Title",
        value: "Load in Background",
        comment: "Action label on share extension to load the page in Firefox when user switches apps to bring it to foreground.",
        lastUpdated: .unknown)
    public static let ShareLoadInBackgroundDone = MZLocalizedString(
        "ShareExtension.LoadInBackgroundActionDone.Title",
        value: "Loading in Firefox",
        comment: "Share extension label shown after user has performed 'Load in Background' action.",
        lastUpdated: .unknown)

}

// MARK: - Translation bar
extension String {
    public static let TranslateSnackBarPrompt = MZLocalizedString(
        "TranslationToastHandler.PromptTranslate.Title",
        value: "This page appears to be in %1$@. Translate to %2$@ with %3$@?",
        comment: "Prompt for translation. The first parameter is the language the page is in. The second parameter is the name of our local language. The third is the name of the service.",
        lastUpdated: .unknown)
    public static let TranslateSnackBarYes = MZLocalizedString(
        "TranslationToastHandler.PromptTranslate.OK",
        value: "Yes",
        comment: "Button to allow the page to be translated to the user locale language",
        lastUpdated: .unknown)
    public static let TranslateSnackBarNo = MZLocalizedString(
        "TranslationToastHandler.PromptTranslate.Cancel",
        value: "No",
        comment: "Button to disallow the page to be translated to the user locale language",
        lastUpdated: .unknown)
}

// MARK: - Display Theme
extension String {
    public static let SettingsDisplayThemeTitle = MZLocalizedString(
        "Settings.DisplayTheme.Title.v2",
        value: "Theme",
        comment: "Title in main app settings for Theme settings",
        lastUpdated: .unknown)
    public static let DisplayThemeBrightnessThresholdSectionHeader = MZLocalizedString(
        "Settings.DisplayTheme.BrightnessThreshold.SectionHeader",
        value: "Threshold",
        comment: "Section header for brightness slider.",
        lastUpdated: .unknown)
    public static let DisplayThemeSectionFooter = MZLocalizedString(
        "Settings.DisplayTheme.SectionFooter",
        value: "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes. The circle indicates your display’s current brightness.",
        comment: "Display (theme) settings footer describing how the brightness slider works.",
        lastUpdated: .unknown)
    public static let SystemThemeSectionHeader = MZLocalizedString(
        "Settings.DisplayTheme.SystemTheme.SectionHeader",
        value: "System Theme",
        comment: "System theme settings section title",
        lastUpdated: .unknown)
    public static let SystemThemeSectionSwitchTitle = MZLocalizedString(
        "Settings.DisplayTheme.SystemTheme.SwitchTitle",
        value: "Use System Light/Dark Mode",
        comment: "System theme settings switch to choose whether to use the same theme as the system",
        lastUpdated: .unknown)
    public static let ThemeSwitchModeSectionHeader = MZLocalizedString(
        "Settings.DisplayTheme.SwitchMode.SectionHeader",
        value: "Switch Mode",
        comment: "Switch mode settings section title",
        lastUpdated: .unknown)
    public static let ThemePickerSectionHeader = MZLocalizedString(
        "Settings.DisplayTheme.ThemePicker.SectionHeader",
        value: "Theme Picker",
        comment: "Theme picker settings section title",
        lastUpdated: .unknown)
    public static let DisplayThemeAutomaticSwitchTitle = MZLocalizedString(
        "Settings.DisplayTheme.SwitchTitle",
        value: "Automatically",
        comment: "Display (theme) settings switch to choose whether to set the dark mode manually, or automatically based on the brightness slider.",
        lastUpdated: .unknown)
    public static let DisplayThemeAutomaticStatusLabel = MZLocalizedString(
        "Settings.DisplayTheme.StatusTitle",
        value: "Automatic",
        comment: "Display (theme) settings label to show if automatically switch theme is enabled.",
        lastUpdated: .unknown)
    public static let DisplayThemeAutomaticSwitchSubtitle = MZLocalizedString(
        "Settings.DisplayTheme.SwitchSubtitle",
        value: "Switch automatically based on screen brightness",
        comment: "Display (theme) settings switch subtitle, explaining the title 'Automatically'.",
        lastUpdated: .unknown)
    public static let DisplayThemeManualSwitchTitle = MZLocalizedString(
        "Settings.DisplayTheme.Manual.SwitchTitle",
        value: "Manually",
        comment: "Display (theme) setting to choose the theme manually.",
        lastUpdated: .unknown)
    public static let DisplayThemeManualSwitchSubtitle = MZLocalizedString(
        "Settings.DisplayTheme.Manual.SwitchSubtitle",
        value: "Pick which theme you want",
        comment: "Display (theme) settings switch subtitle, explaining the title 'Manually'.",
        lastUpdated: .unknown)
    public static let DisplayThemeManualStatusLabel = MZLocalizedString(
        "Settings.DisplayTheme.Manual.StatusLabel",
        value: "Manual",
        comment: "Display (theme) settings label to show if manually switch theme is enabled.",
        lastUpdated: .unknown)
    public static let DisplayThemeOptionLight = MZLocalizedString(
        "Settings.DisplayTheme.OptionLight",
        value: "Light",
        comment: "Option choice in display theme settings for light theme",
        lastUpdated: .unknown)
    public static let DisplayThemeOptionDark = MZLocalizedString(
        "Settings.DisplayTheme.OptionDark",
        value: "Dark",
        comment: "Option choice in display theme settings for dark theme",
        lastUpdated: .unknown)
}

extension String {
    public static let AddTabAccessibilityLabel = MZLocalizedString(
        "TabTray.AddTab.Button",
        value: "Add Tab",
        comment: "Accessibility label for the Add Tab button in the Tab Tray.",
        lastUpdated: .unknown)
}

// MARK: - Cover Sheet
extension String {
    // ETP Cover Sheet
    public static let CoverSheetETPTitle = MZLocalizedString(
        "CoverSheet.v24.ETP.Title",
        value: "Protection Against Ad Tracking",
        comment: "Title for the new ETP mode i.e. standard vs strict",
        lastUpdated: .unknown)
    public static let CoverSheetETPDescription = MZLocalizedString(
        "CoverSheet.v24.ETP.Description",
        value: "Built-in Enhanced Tracking Protection helps stop ads from following you around. Turn on Strict to block even more trackers, ads, and popups. ",
        comment: "Description for the new ETP mode i.e. standard vs strict",
        lastUpdated: .unknown)
    public static let CoverSheetETPSettingsButton = MZLocalizedString(
        "CoverSheet.v24.ETP.Settings.Button",
        value: "Go to Settings",
        comment: "Text for the new ETP settings button",
        lastUpdated: .unknown)
}

// MARK: - FxA Signin screen
extension String {
    public static let FxASignin_Subtitle = MZLocalizedString(
        "fxa.signin.camera-signin",
        value: "Sign In with Your Camera",
        comment: "FxA sign in view subtitle",
        lastUpdated: .unknown)
    public static let FxASignin_QRInstructions = MZLocalizedString(
        "fxa.signin.qr-link-instruction",
        value: "On your computer open Firefox and go to firefox.com/pair",
        comment: "FxA sign in view qr code instructions",
        lastUpdated: .unknown)
    public static let FxASignin_QRScanSignin = MZLocalizedString(
        "fxa.signin.ready-to-scan",
        value: "Ready to Scan",
        comment: "FxA sign in view qr code scan button",
        lastUpdated: .unknown)
    public static let FxASignin_EmailSignin = MZLocalizedString(
        "fxa.signin.use-email-instead",
        value: "Use Email Instead",
        comment: "FxA sign in view email login button",
        lastUpdated: .unknown)
}

// MARK: - Today Widget Strings - [New Search - Private Search]
extension String {
    public static let NewTabButtonLabel = MZLocalizedString(
        "TodayWidget.NewTabButtonLabelV1",
        tableName: "Today",
        value: "New Search",
        comment: "Open New Tab button label",
        lastUpdated: .unknown)
    public static let NewPrivateTabButtonLabel = MZLocalizedString(
        "TodayWidget.PrivateTabButtonLabelV1",
        tableName: "Today",
        value: "Private Search",
        comment: "Open New Private Tab button label",
        lastUpdated: .unknown)

    // Widget - Shared

    public static let QuickActionsGalleryTitle = MZLocalizedString(
        "TodayWidget.QuickActionsGalleryTitle",
        tableName: "Today",
        value: "Quick Actions",
        comment: "Quick Actions title when widget enters edit mode",
        lastUpdated: .unknown)
    public static let QuickActionsGalleryTitlev2 = MZLocalizedString(
        "TodayWidget.QuickActionsGalleryTitleV2",
        tableName: "Today",
        value: "Firefox Shortcuts",
        comment: "Firefox shortcuts title when widget enters edit mode. Do not translate the word Firefox.",
        lastUpdated: .unknown)

    // Quick Action - Medium Size Quick Action
    public static let GoToCopiedLinkLabel = MZLocalizedString(
        "TodayWidget.GoToCopiedLinkLabelV1",
        tableName: "Today",
        value: "Go to copied link",
        comment: "Go to link pasted on the clipboard",
        lastUpdated: .unknown)
    public static let GoToCopiedLinkLabelV2 = MZLocalizedString(
        "TodayWidget.GoToCopiedLinkLabelV2",
        tableName: "Today",
        value: "Go to\nCopied Link",
        comment: "Go to copied link",
        lastUpdated: .unknown)
    public static let ClosePrivateTab = MZLocalizedString(
        "TodayWidget.ClosePrivateTabsButton",
        tableName: "Today",
        value: "Close Private Tabs",
        comment: "Close Private Tabs button label",
        lastUpdated: .unknown)

    // Quick Action - Medium Size - Gallery View
    public static let FirefoxShortcutGalleryDescription = MZLocalizedString(
        "TodayWidget.FirefoxShortcutGalleryDescription",
        tableName: "Today",
        value: "Add Firefox shortcuts to your Home screen.",
        comment: "Description for medium size widget to add Firefox Shortcut to home screen",
        lastUpdated: .unknown)

    // Quick Action - Small Size Widget
    public static let SearchInPrivateTabLabelV2 = MZLocalizedString(
        "TodayWidget.SearchInPrivateTabLabelV2",
        tableName: "Today",
        value: "Search in\nPrivate Tab",
        comment: "Search in private tab",
        lastUpdated: .unknown)
    public static let SearchInFirefoxV2 = MZLocalizedString(
        "TodayWidget.SearchInFirefoxV2",
        tableName: "Today",
        value: "Search in\nFirefox",
        comment: "Search in Firefox. Do not translate the word Firefox",
        lastUpdated: .unknown)
    public static let ClosePrivateTabsLabelV2 = MZLocalizedString(
        "TodayWidget.ClosePrivateTabsLabelV2",
        tableName: "Today",
        value: "Close\nPrivate Tabs",
        comment: "Close Private Tabs",
        lastUpdated: .unknown)

    // Quick Action - Small Size - Gallery View
    public static let QuickActionGalleryDescription = MZLocalizedString(
        "TodayWidget.QuickActionGalleryDescription",
        tableName: "Today",
        value: "Add a Firefox shortcut to your Home screen. After adding the widget, touch and hold to edit it and select a different shortcut.",
        comment: "Description for small size widget to add it to home screen",
        lastUpdated: .unknown)

    // Top Sites - Medium Size - Gallery View
    public static let TopSitesGalleryTitle = MZLocalizedString(
        "TodayWidget.TopSitesGalleryTitle",
        tableName: "Today",
        value: "Top Sites",
        comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen",
        lastUpdated: .unknown)
    public static let TopSitesGalleryTitleV2 = MZLocalizedString(
        "TodayWidget.TopSitesGalleryTitleV2",
        tableName: "Today",
        value: "Website Shortcuts",
        comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen",
        lastUpdated: .unknown)
    public static let TopSitesGalleryDescription = MZLocalizedString(
        "TodayWidget.TopSitesGalleryDescription",
        tableName: "Today",
        value: "Add shortcuts to frequently and recently visited sites.",
        comment: "Description for top sites widget to add Firefox top sites shotcuts to home screen",
        lastUpdated: .unknown)

    // Quick View Open Tabs - Medium Size Widget
    public static let MoreTabsLabel = MZLocalizedString(
        "TodayWidget.MoreTabsLabel",
        tableName: "Today",
        value: "+%d More…",
        comment: "%d represents number and it becomes something like +5 more where 5 is the number of open tabs in tab tray beyond what is displayed in the widget",
        lastUpdated: .unknown)
    public static let OpenFirefoxLabel = MZLocalizedString(
        "TodayWidget.OpenFirefoxLabel",
        tableName: "Today",
        value: "Open Firefox",
        comment: "Open Firefox when there are no tabs opened in tab tray i.e. Empty State",
        lastUpdated: .unknown)
    public static let NoOpenTabsLabel = MZLocalizedString(
        "TodayWidget.NoOpenTabsLabel",
        tableName: "Today",
        value: "No open tabs.",
        comment: "Label that is shown when there are no tabs opened in tab tray i.e. Empty State",
        lastUpdated: .unknown)

    // Quick View Open Tabs - Medium Size - Gallery View
    public static let QuickViewGalleryTitle = MZLocalizedString(
        "TodayWidget.QuickViewGalleryTitle",
        tableName: "Today",
        value: "Quick View",
        comment: "Title for Quick View widget in Gallery View where user can add it to home screen",
        lastUpdated: .unknown)
    public static let QuickViewGalleryDescriptionV2 = MZLocalizedString(
        "TodayWidget.QuickViewGalleryDescriptionV2",
        tableName: "Today",
        value: "Add shortcuts to your open tabs.",
        comment: "Description for Quick View widget in Gallery View where user can add it to home screen",
        lastUpdated: .unknown)
}

// MARK: - Default Browser
extension String {
    public static let DefaultBrowserMenuItem = MZLocalizedString(
        "Settings.DefaultBrowserMenuItem",
        tableName: "Default Browser",
        value: "Set as Default Browser",
        comment: "Menu option for setting Firefox as default browser.",
        lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingScreenshot = MZLocalizedString(
        "DefaultBrowserOnboarding.Screenshot",
        tableName: "Default Browser",
        value: "Default Browser App",
        comment: "Text for the screenshot of the iOS system settings page for Firefox.",
        lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep1 = MZLocalizedString(
        "DefaultBrowserOnboarding.Description1",
        tableName: "Default Browser",
        value: "1. Go to Settings",
        comment: "Description for default browser onboarding card.",
        lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep2 = MZLocalizedString(
        "DefaultBrowserOnboarding.Description2",
        tableName: "Default Browser",
        value: "2. Tap Default Browser App",
        comment: "Description for default browser onboarding card.",
        lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep3 = MZLocalizedString(
        "DefaultBrowserOnboarding.Description3",
        tableName: "Default Browser",
        value: "3. Select Firefox",
        comment: "Description for default browser onboarding card.",
        lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingButton = MZLocalizedString(
        "DefaultBrowserOnboarding.Button",
        tableName: "Default Browser",
        value: "Go to Settings",
        comment: "Button string to open settings that allows user to switch their default browser to Firefox.",
        lastUpdated: .unknown)
}

// MARK: - FxAWebViewController
extension String {
    public static let FxAWebContentAccessibilityLabel = MZLocalizedString(
        "Web content",
        comment: "Accessibility label for the main web content view",
        lastUpdated: .unknown)
}

// MARK: - QuickActions
extension String {
    public static let QuickActionsLastBookmarkTitle = MZLocalizedString(
        "Open Last Bookmark",
        tableName: "3DTouchActions",
        comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch",
        lastUpdated: .unknown)
}

// MARK: - CrashOptInAlert
extension String {
    public static let CrashOptInAlertTitle = MZLocalizedString(
        "Oops! Firefox crashed",
        comment: "Title for prompt displayed to user after the app crashes",
        lastUpdated: .unknown)
    public static let CrashOptInAlertMessage = MZLocalizedString(
        "Send a crash report so Mozilla can fix the problem?",
        comment: "Message displayed in the crash dialog above the buttons used to select when sending reports",
        lastUpdated: .unknown)
    public static let CrashOptInAlertSend = MZLocalizedString(
        "Send Report",
        comment: "Used as a button label for crash dialog prompt",
        lastUpdated: .unknown)
    public static let CrashOptInAlertAlwaysSend = MZLocalizedString(
        "Always Send",
        comment: "Used as a button label for crash dialog prompt",
        lastUpdated: .unknown)
    public static let CrashOptInAlertDontSend = MZLocalizedString(
        "Don’t Send",
        comment: "Used as a button label for crash dialog prompt",
        lastUpdated: .unknown)
}

// MARK: - RestoreTabsAlert
extension String {
    public static let RestoreTabsAlertTitle = MZLocalizedString(
        "Well, this is embarrassing.",
        comment: "Restore Tabs Prompt Title",
        lastUpdated: .unknown)
    public static let RestoreTabsAlertMessage = MZLocalizedString(
        "Looks like Firefox crashed previously. Would you like to restore your tabs?",
        comment: "Restore Tabs Prompt Description",
        lastUpdated: .unknown)
    public static let RestoreTabsAlertNo = MZLocalizedString(
        "No",
        comment: "Restore Tabs Negative Action",
        lastUpdated: .unknown)
    public static let RestoreTabsAlertOkay = MZLocalizedString(
        "Okay",
        comment: "Restore Tabs Affirmative Action",
        lastUpdated: .unknown)
}

// MARK: - ClearPrivateDataAlert
extension String {
    public static let ClearPrivateDataAlertMessage = MZLocalizedString(
        "This action will clear all of your private data. It cannot be undone.",
        tableName: "ClearPrivateDataConfirm",
        comment: "Description of the confirmation dialog shown when a user tries to clear their private data.",
        lastUpdated: .unknown)
    public static let ClearPrivateDataAlertCancel = MZLocalizedString(
        "Cancel",
        tableName: "ClearPrivateDataConfirm",
        comment: "The cancel button when confirming clear private data.",
        lastUpdated: .unknown)
    public static let ClearPrivateDataAlertOk = MZLocalizedString(
        "OK",
        tableName: "ClearPrivateDataConfirm",
        comment: "The button that clears private data.",
        lastUpdated: .unknown)
}

// MARK: - ClearWebsiteDataAlert
extension String {
    public static let ClearAllWebsiteDataAlertMessage = MZLocalizedString(
        "Settings.WebsiteData.ConfirmPrompt",
        value: "This action will clear all of your website data. It cannot be undone.",
        comment: "Description of the confirmation dialog shown when a user tries to clear their private data.",
        lastUpdated: .unknown)
    public static let ClearSelectedWebsiteDataAlertMessage = MZLocalizedString(
        "Settings.WebsiteData.SelectedConfirmPrompt",
        value: "This action will clear the selected items. It cannot be undone.",
        comment: "Description of the confirmation dialog shown when a user tries to clear some of their private data.",
        lastUpdated: .unknown)
    // TODO: these look like the same as in ClearPrivateDataAlert, I think we can remove them
    public static let ClearWebsiteDataAlertCancel = MZLocalizedString(
        "Cancel",
        tableName: "ClearPrivateDataConfirm",
        comment: "The cancel button when confirming clear private data.",
        lastUpdated: .unknown)
    public static let ClearWebsiteDataAlertOk = MZLocalizedString(
        "OK",
        tableName: "ClearPrivateDataConfirm",
        comment: "The button that clears private data.",
        lastUpdated: .unknown)
}

// MARK: - ClearSyncedHistoryAlert
extension String {
    public static let ClearSyncedHistoryAlertMessage = MZLocalizedString(
        "This action will clear all of your private data, including history from your synced devices.",
        tableName: "ClearHistoryConfirm",
        comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.",
        lastUpdated: .unknown)
    // TODO: these look like the same as in ClearPrivateDataAlert, I think we can remove them
    public static let ClearSyncedHistoryAlertCancel = MZLocalizedString(
        "Cancel",
        tableName: "ClearHistoryConfirm",
        comment: "The cancel button when confirming clear history.",
        lastUpdated: .unknown)
    public static let ClearSyncedHistoryAlertOk = MZLocalizedString(
        "OK",
        tableName: "ClearHistoryConfirm",
        comment: "The confirmation button that clears history even when Sync is connected.",
        lastUpdated: .unknown)
}

// MARK: - DeleteLoginAlert
extension String {
    public static let DeleteLoginAlertTitle = MZLocalizedString(
        "Are you sure?",
        tableName: "LoginManager",
        comment: "Prompt title when deleting logins",
        lastUpdated: .unknown)
    public static let DeleteLoginAlertSyncedMessage = MZLocalizedString(
        "Logins will be removed from all connected devices.",
        tableName: "LoginManager",
        comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices",
        lastUpdated: .unknown)
    public static let DeleteLoginAlertLocalMessage = MZLocalizedString(
        "Logins will be permanently removed.",
        tableName: "LoginManager",
        comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them",
        lastUpdated: .unknown)
    public static let DeleteLoginAlertCancel = MZLocalizedString(
        "Cancel",
        tableName: "LoginManager",
        comment: "Prompt option for cancelling out of deletion",
        lastUpdated: .unknown)
    public static let DeleteLoginAlertDelete = MZLocalizedString(
        "Delete",
        tableName: "LoginManager",
        comment: "Label for the button used to delete the current login.",
        lastUpdated: .unknown)
}

// MARK: - Strings used in multiple areas within the Authentication Manager
extension String {
    public static let AuthenticationEnterPasscode = MZLocalizedString(
        "Enter passcode",
        tableName: "AuthenticationManager",
        comment: "Text displayed above the input field when changing the existing passcode",
        lastUpdated: .unknown)
}

// MARK: - Authenticator strings
extension String {
    public static let AuthenticatorCancel = MZLocalizedString(
        "Cancel",
        comment: "Label for Cancel button",
        lastUpdated: .unknown)
    public static let AuthenticatorLogin = MZLocalizedString(
        "Log in",
        comment: "Authentication prompt log in button",
        lastUpdated: .unknown)
    public static let AuthenticatorPromptTitle = MZLocalizedString(
        "Authentication required",
        comment: "Authentication prompt title",
        lastUpdated: .unknown)
    public static let AuthenticatorPromptRealmMessage = MZLocalizedString(
        "A username and password are being requested by %@. The site says: %@",
        comment: "Authentication prompt message with a realm. First parameter is the hostname. Second is the realm string",
        lastUpdated: .unknown)
    public static let AuthenticatorPromptEmptyRealmMessage = MZLocalizedString(
        "A username and password are being requested by %@.",
        comment: "Authentication prompt message with no realm. Parameter is the hostname of the site",
        lastUpdated: .unknown)
    public static let AuthenticatorUsernamePlaceholder = MZLocalizedString(
        "Username",
        comment: "Username textbox in Authentication prompt",
        lastUpdated: .unknown)
    public static let AuthenticatorPasswordPlaceholder = MZLocalizedString(
        "Password",
        comment: "Password textbox in Authentication prompt",
        lastUpdated: .unknown)
}

// MARK: - BrowserViewController
extension String {
    public static let ReaderModeAddPageGeneralErrorAccessibilityLabel = MZLocalizedString(
        "Could not add page to Reading list",
        comment: "Accessibility message e.g. spoken by VoiceOver after adding current webpage to the Reading List failed.",
        lastUpdated: .unknown)
    public static let ReaderModeAddPageSuccessAcessibilityLabel = MZLocalizedString(
        "Added page to Reading List",
        comment: "Accessibility message e.g. spoken by VoiceOver after the current page gets added to the Reading List using the Reader View button, e.g. by long-pressing it or by its accessibility custom action.",
        lastUpdated: .unknown)
    public static let ReaderModeAddPageMaybeExistsErrorAccessibilityLabel = MZLocalizedString(
        "Could not add page to Reading List. Maybe it’s already there?",
        comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures.",
        lastUpdated: .unknown)
    public static let WebViewAccessibilityLabel = MZLocalizedString(
        "Web content",
        comment: "Accessibility label for the main web content view",
        lastUpdated: .unknown)
}

// MARK: - Find in page
extension String {
    public static let FindInPagePreviousAccessibilityLabel = MZLocalizedString(
        "Previous in-page result",
        tableName: "FindInPage",
        comment: "Accessibility label for previous result button in Find in Page Toolbar.",
        lastUpdated: .unknown)
    public static let FindInPageNextAccessibilityLabel = MZLocalizedString(
        "Next in-page result",
        tableName: "FindInPage",
        comment: "Accessibility label for next result button in Find in Page Toolbar.",
        lastUpdated: .unknown)
    public static let FindInPageDoneAccessibilityLabel = MZLocalizedString(
        "Done",
        tableName: "FindInPage",
        comment: "Done button in Find in Page Toolbar.",
        lastUpdated: .unknown)
}

// MARK: - Reader Mode Bar
extension String {
    public static let ReaderModeBarMarkAsRead = MZLocalizedString(
        "ReaderModeBar.MarkAsRead.v106",
        value: "Mark as Read",
        comment: "Name for Mark as read button in reader mode",
        lastUpdated: .v106)
    public static let ReaderModeBarMarkAsUnread = MZLocalizedString(
        "ReaderModeBar.MarkAsUnread.v106",
        value: "Mark as Unread",
        comment: "Name for Mark as unread button in reader mode",
        lastUpdated: .v106)
    public static let ReaderModeBarSettings = MZLocalizedString(
        "Display Settings",
        comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.",
        lastUpdated: .unknown)
    public static let ReaderModeBarAddToReadingList = MZLocalizedString(
        "Add to Reading List",
        comment: "Name for button adding current article to reading list in reader mode",
        lastUpdated: .unknown)
    public static let ReaderModeBarRemoveFromReadingList = MZLocalizedString(
        "Remove from Reading List",
        comment: "Name for button removing current article from reading list in reader mode",
        lastUpdated: .unknown)
}

// MARK: - SearchViewController
extension String {
    public static let SearchSettingsAccessibilityLabel = MZLocalizedString(
        "Search Settings",
        tableName: "Search",
        comment: "Label for search settings button.",
        lastUpdated: .unknown)
    public static let SearchSearchEngineAccessibilityLabel = MZLocalizedString(
        "%@ search",
        tableName: "Search",
        comment: "Label for search engine buttons. The argument corresponds to the name of the search engine.",
        lastUpdated: .unknown)
    public static let SearchSuggestionCellSwitchToTabLabel = MZLocalizedString(
        "Search.Awesomebar.SwitchToTab",
        value: "Switch to tab",
        comment: "Search suggestion cell label that allows user to switch to tab which they searched for in url bar",
        lastUpdated: .unknown)
}

// MARK: - Tab Location View
extension String {
    public static let TabLocationURLPlaceholder = MZLocalizedString(
        "Search or enter address",
        comment: "The text shown in the URL bar on about:home",
        lastUpdated: .unknown)
    public static let TabLocationReaderModeAccessibilityLabel = MZLocalizedString(
        "Reader View",
        comment: "Accessibility label for the Reader View button",
        lastUpdated: .unknown)
    public static let TabLocationAddressBarAccessibilityLabel = MZLocalizedString(
        "Address.Bar.v99",
        value: "Address Bar",
        comment: "Accessibility label for the Address Bar, where a user can enter the search they wish to make",
        lastUpdated: .v99)
    public static let TabLocationReaderModeAddToReadingListAccessibilityLabel = MZLocalizedString(
        "Address.Bar.ReadingList.v106",
        value: "Add to Reading List",
        comment: "Accessibility label for action adding current page to reading list.",
        lastUpdated: .v106)
    public static let TabLocationReloadAccessibilityLabel = MZLocalizedString(
        "Reload page",
        comment: "Accessibility label for the reload button",
        lastUpdated: .unknown)
}

// MARK: - TabPeekViewController
extension String {
    public static let TabPeekAddToBookmarks = MZLocalizedString(
        "Add to Bookmarks",
        tableName: "3DTouchActions",
        comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks",
        lastUpdated: .unknown)
    public static let TabPeekCopyUrl = MZLocalizedString(
        "Copy URL",
        tableName: "3DTouchActions",
        comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard",
        lastUpdated: .unknown)
    public static let TabPeekCloseTab = MZLocalizedString(
        "Close Tab",
        tableName: "3DTouchActions",
        comment: "Label for preview action on Tab Tray Tab to close the current tab",
        lastUpdated: .unknown)
    public static let TabPeekPreviewAccessibilityLabel = MZLocalizedString(
        "Preview of %@",
        tableName: "3DTouchActions",
        comment: "Accessibility label, associated to the 3D Touch action on the current tab in the tab tray, used to display a larger preview of the tab.",
        lastUpdated: .unknown)
}

// MARK: - Tab Toolbar
extension String {
    public static let TabToolbarReloadAccessibilityLabel = MZLocalizedString(
        "Reload",
        comment: "Accessibility Label for the tab toolbar Reload button",
        lastUpdated: .unknown)
    public static let TabToolbarStopAccessibilityLabel = MZLocalizedString(
        "Stop",
        comment: "Accessibility Label for the tab toolbar Stop button",
        lastUpdated: .unknown)
    public static let TabToolbarSearchAccessibilityLabel = MZLocalizedString(
        "TabToolbar.Accessibility.Search.v106",
        value: "Search",
        comment: "Accessibility Label for the tab toolbar Search button",
        lastUpdated: .v106)
    public static let TabToolbarBackAccessibilityLabel = MZLocalizedString(
        "Back",
        comment: "Accessibility label for the Back button in the tab toolbar.",
        lastUpdated: .unknown)
    public static let TabToolbarForwardAccessibilityLabel = MZLocalizedString(
        "Forward",
        comment: "Accessibility Label for the tab toolbar Forward button",
        lastUpdated: .unknown)
    public static let TabToolbarHomeAccessibilityLabel = MZLocalizedString(
        "Home",
        comment: "Accessibility label for the tab toolbar indicating the Home button.",
        lastUpdated: .unknown)
    public static let TabToolbarNavigationToolbarAccessibilityLabel = MZLocalizedString(
        "Navigation Toolbar",
        comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.",
        lastUpdated: .unknown)
}

// MARK: - Tab Tray v1
extension String {
    public static let TabTrayToggleAccessibilityLabel = MZLocalizedString(
        "Private Mode",
        tableName: "PrivateBrowsing",
        comment: "Accessibility label for toggling on/off private mode",
        lastUpdated: .unknown)
    public static let TabTrayToggleAccessibilityHint = MZLocalizedString(
        "Turns private mode on or off",
        tableName: "PrivateBrowsing",
        comment: "Accessiblity hint for toggling on/off private mode",
        lastUpdated: .unknown)
    public static let TabTrayToggleAccessibilityValueOn = MZLocalizedString(
        "On",
        tableName: "PrivateBrowsing",
        comment: "Toggled ON accessibility value",
        lastUpdated: .unknown)
    public static let TabTrayToggleAccessibilityValueOff = MZLocalizedString(
        "Off",
        tableName: "PrivateBrowsing",
        comment: "Toggled OFF accessibility value",
        lastUpdated: .unknown)
    public static let TabTrayViewAccessibilityLabel = MZLocalizedString(
        "Tabs Tray",
        comment: "Accessibility label for the Tabs Tray view.",
        lastUpdated: .unknown)
    public static let TabTrayNoTabsAccessibilityHint = MZLocalizedString(
        "No tabs",
        comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray",
        lastUpdated: .unknown)
    public static let TabTrayVisibleTabRangeAccessibilityHint = MZLocalizedString(
        "Tab %@ of %@",
        comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.",
        lastUpdated: .unknown)
    public static let TabTrayVisiblePartialRangeAccessibilityHint = MZLocalizedString(
        "Tabs %@ to %@ of %@",
        comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.",
        lastUpdated: .unknown)
    public static let TabTrayClosingTabAccessibilityMessage =  MZLocalizedString(
        "Closing tab",
        comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed.",
        lastUpdated: .unknown)
    public static let TabTrayCloseAllTabsPromptCancel = MZLocalizedString(
        "Cancel",
        comment: "Label for Cancel button",
        lastUpdated: .unknown)
    public static let TabTrayPrivateBrowsingTitle = MZLocalizedString(
        "Private Browsing",
        tableName: "PrivateBrowsing",
        comment: "Title displayed for when there are no open tabs while in private mode",
        lastUpdated: .unknown)
    public static let TabTrayPrivateBrowsingDescription =  MZLocalizedString(
        "Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.",
        tableName: "PrivateBrowsing",
        comment: "Description text displayed when there are no open tabs while in private mode",
        lastUpdated: .unknown)
    public static let TabTrayAddTabAccessibilityLabel = MZLocalizedString(
        "Add Tab",
        comment: "Accessibility label for the Add Tab button in the Tab Tray.",
        lastUpdated: .unknown)
    public static let TabTrayCloseAccessibilityCustomAction = MZLocalizedString(
        "Close",
        comment: "Accessibility label for action denoting closing a tab in tab list (tray)",
        lastUpdated: .unknown)
    public static let TabTraySwipeToCloseAccessibilityHint = MZLocalizedString(
        "Swipe right or left with three fingers to close the tab.",
        comment: "Accessibility hint for tab tray's displayed tab.",
        lastUpdated: .unknown)
    public static let TabTrayCurrentlySelectedTabAccessibilityLabel = MZLocalizedString(
        "TabTray.CurrentSelectedTab.A11Y",
        value: "Currently selected tab.",
        comment: "Accessibility label for the currently selected tab.",
        lastUpdated: .unknown)
    public static let TabTrayOtherTabsSectionHeader = MZLocalizedString(
        "TabTray.Header.FilteredTabs.SectionHeader",
        value: "Others",
        comment: "In the tab tray, when tab groups appear and there exist tabs that don't belong to any group, those tabs are listed under this header as \"Others\"",
        lastUpdated: .unknown)
}

// MARK: - URL Bar
extension String {
    public static let URLBarLocationAccessibilityLabel = MZLocalizedString(
        "Address and Search",
        comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.",
        lastUpdated: .unknown)
}

// MARK: - Error Pages
extension String {
    public static let ErrorPageTryAgain = MZLocalizedString(
        "Try again",
        tableName: "ErrorPages",
        comment: "Shown in error pages on a button that will try to load the page again",
        lastUpdated: .unknown)
    public static let ErrorPageOpenInSafari = MZLocalizedString(
        "Open in Safari",
        tableName: "ErrorPages",
        comment: "Shown in error pages for files that can't be shown and need to be downloaded.",
        lastUpdated: .unknown)
}

// MARK: - LibraryPanel
extension String {
    public static let LibraryPanelBookmarksAccessibilityLabel = MZLocalizedString(
        "LibraryPanel.Accessibility.Bookmarks.v106",
        value: "Bookmarks",
        comment: "Panel accessibility label",
        lastUpdated: .v106)
    public static let LibraryPanelHistoryAccessibilityLabel = MZLocalizedString(
        "LibraryPanel.Accessibility.History.v106",
        value: "History",
        comment: "Panel accessibility label",
        lastUpdated: .v106)
    public static let LibraryPanelReadingListAccessibilityLabel = MZLocalizedString(
        "Reading list",
        comment: "Panel accessibility label",
        lastUpdated: .unknown)
    public static let LibraryPanelDownloadsAccessibilityLabel = MZLocalizedString(
        "Downloads",
        comment: "Panel accessibility label",
        lastUpdated: .unknown)
}

// MARK: - ReaderPanel
extension String {
    public static let ReaderPanelRemove = MZLocalizedString(
        "Remove",
        comment: "Title for the button that removes a reading list item",
        lastUpdated: .unknown)
    public static let ReaderPanelMarkAsRead = MZLocalizedString(
        "Mark as Read",
        comment: "Title for the button that marks a reading list item as read",
        lastUpdated: .unknown)
    public static let ReaderPanelMarkAsUnread =  MZLocalizedString(
        "Mark as Unread",
        comment: "Title for the button that marks a reading list item as unread",
        lastUpdated: .unknown)
    public static let ReaderPanelUnreadAccessibilityLabel = MZLocalizedString(
        "unread",
        comment: "Accessibility label for unread article in reading list. It's a past participle - functions as an adjective.",
        lastUpdated: .unknown)
    public static let ReaderPanelReadAccessibilityLabel = MZLocalizedString(
        "read",
        comment: "Accessibility label for read article in reading list. It's a past participle - functions as an adjective.",
        lastUpdated: .unknown)
    public static let ReaderPanelWelcome = MZLocalizedString(
        "Welcome to your Reading List",
        comment: "See http://mzl.la/1LXbDOL",
        lastUpdated: .unknown)
    public static let ReaderPanelReadingModeDescription = MZLocalizedString(
        "Open articles in Reader View by tapping the book icon when it appears in the title bar.",
        comment: "See http://mzl.la/1LXbDOL",
        lastUpdated: .unknown)
    public static let ReaderPanelReadingListDescription = MZLocalizedString(
        "Save pages to your Reading List by tapping the book plus icon in the Reader View controls.",
        comment: "See http://mzl.la/1LXbDOL",
        lastUpdated: .unknown)
}

// MARK: - Remote Tabs Panel
extension String {
    public static let RemoteTabErrorNoTabs = MZLocalizedString(
        "You don’t have any tabs open in Firefox on your other devices.",
        comment: "Error message in the remote tabs panel",
        lastUpdated: .unknown)
    public static let RemoteTabErrorFailedToSync = MZLocalizedString(
        "There was a problem accessing tabs from your other devices. Try again in a few moments.",
        comment: "Error message in the remote tabs panel",
        lastUpdated: .unknown)
    public static let RemoteTabMobileAccessibilityLabel =  MZLocalizedString(
        "mobile device",
        comment: "Accessibility label for Mobile Device image in remote tabs list",
        lastUpdated: .unknown)
    public static let RemoteTabCreateAccount = MZLocalizedString(
        "Create an account",
        comment: "See http://mzl.la/1Qtkf0j",
        lastUpdated: .unknown)
}

// MARK: - Login list
extension String {
    public static let LoginListDeselctAll = MZLocalizedString(
        "Deselect All",
        tableName: "LoginManager",
        comment: "Label for the button used to deselect all logins.",
        lastUpdated: .unknown)
    public static let LoginListSelctAll = MZLocalizedString(
        "Select All",
        tableName: "LoginManager",
        comment: "Label for the button used to select all logins.",
        lastUpdated: .unknown)
    public static let LoginListDelete = MZLocalizedString(
        "Delete",
        tableName: "LoginManager",
        comment: "Label for the button used to delete the current login.",
        lastUpdated: .unknown)
}

// MARK: - Login Detail
extension String {
    public static let LoginDetailUsername = MZLocalizedString(
        "Username",
        tableName: "LoginManager",
        comment: "Label displayed above the username row in Login Detail View.",
        lastUpdated: .unknown)
    public static let LoginDetailPassword = MZLocalizedString(
        "Password",
        tableName: "LoginManager",
        comment: "Label displayed above the password row in Login Detail View.",
        lastUpdated: .unknown)
    public static let LoginDetailWebsite = MZLocalizedString(
        "Website",
        tableName: "LoginManager",
        comment: "Label displayed above the website row in Login Detail View.",
        lastUpdated: .unknown)
    public static let LoginDetailCreatedAt =  MZLocalizedString(
        "Created %@",
        tableName: "LoginManager",
        comment: "Label describing when the current login was created with the timestamp as the parameter.",
        lastUpdated: .unknown)
    public static let LoginDetailModifiedAt = MZLocalizedString(
        "Modified %@",
        tableName: "LoginManager",
        comment: "Label describing when the current login was last modified with the timestamp as the parameter.",
        lastUpdated: .unknown)
    public static let LoginDetailDelete = MZLocalizedString(
        "Delete",
        tableName: "LoginManager",
        comment: "Label for the button used to delete the current login.",
        lastUpdated: .unknown)
}

// MARK: - No Logins View
extension String {
    public static let NoLoginsFound = MZLocalizedString(
        "No logins found",
        tableName: "LoginManager",
        comment: "Label displayed when no logins are found after searching.",
        lastUpdated: .unknown)
}

// MARK: - Reader Mode Handler
extension String {
    public static let ReaderModeHandlerLoadingContent = MZLocalizedString(
        "Loading content…",
        comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Firefox reader mode from another app.",
        lastUpdated: .unknown)
    public static let ReaderModeHandlerPageCantDisplay = MZLocalizedString(
        "The page could not be displayed in Reader View.",
        comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.",
        lastUpdated: .unknown)
    public static let ReaderModeHandlerLoadOriginalPage = MZLocalizedString(
        "Load original page",
        comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.",
        lastUpdated: .unknown)
    public static let ReaderModeHandlerError = MZLocalizedString(
        "There was an error converting the page",
        comment: "Error displayed when reader mode cannot be enabled",
        lastUpdated: .unknown)
}

// MARK: - ReaderModeStyle
extension String {
    public static let ReaderModeStyleBrightnessAccessibilityLabel = MZLocalizedString(
        "Brightness",
        comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings",
        lastUpdated: .unknown)
    public static let ReaderModeStyleFontTypeAccessibilityLabel = MZLocalizedString(
        "Changes font type.",
        comment: "Accessibility hint for the font type buttons in reader mode display settings",
        lastUpdated: .unknown)
    public static let ReaderModeStyleSansSerifFontType = MZLocalizedString(
        "Sans-serif",
        comment: "Font type setting in the reading view settings",
        lastUpdated: .unknown)
    public static let ReaderModeStyleSerifFontType = MZLocalizedString(
        "Serif",
        comment: "Font type setting in the reading view settings",
        lastUpdated: .unknown)
    public static let ReaderModeStyleSmallerLabel = MZLocalizedString(
        "-",
        comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.",
        lastUpdated: .unknown)
    public static let ReaderModeStyleSmallerAccessibilityLabel = MZLocalizedString(
        "Decrease text size",
        comment: "Accessibility label for button decreasing font size in display settings of reader mode",
        lastUpdated: .unknown)
    public static let ReaderModeStyleLargerLabel = MZLocalizedString(
        "+",
        comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.",
        lastUpdated: .unknown)
    public static let ReaderModeStyleLargerAccessibilityLabel = MZLocalizedString(
        "Increase text size",
        comment: "Accessibility label for button increasing font size in display settings of reader mode",
        lastUpdated: .unknown)
    public static let ReaderModeStyleFontSize = MZLocalizedString(
        "Aa",
        comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.",
        lastUpdated: .unknown)
    public static let ReaderModeStyleChangeColorSchemeAccessibilityHint = MZLocalizedString(
        "Changes color theme.",
        comment: "Accessibility hint for the color theme setting buttons in reader mode display settings",
        lastUpdated: .unknown)
    public static let ReaderModeStyleLightLabel = MZLocalizedString(
        "Light",
        comment: "Light theme setting in Reading View settings",
        lastUpdated: .unknown)
    public static let ReaderModeStyleDarkLabel = MZLocalizedString(
        "Dark",
        comment: "Dark theme setting in Reading View settings",
        lastUpdated: .unknown)
    public static let ReaderModeStyleSepiaLabel = MZLocalizedString(
        "Sepia",
        comment: "Sepia theme setting in Reading View settings",
        lastUpdated: .unknown)
}

// MARK: - Empty Private tab view
extension String {
    public static let PrivateBrowsingLearnMore = MZLocalizedString(
        "Learn More",
        tableName: "PrivateBrowsing",
        comment: "Text button displayed when there are no tabs open while in private mode",
        lastUpdated: .unknown)
    public static let PrivateBrowsingTitle = MZLocalizedString(
        "Private Browsing",
        tableName: "PrivateBrowsing",
        comment: "Title displayed for when there are no open tabs while in private mode",
        lastUpdated: .unknown)
}

// MARK: - Advanced Account Setting
extension String {
    public static let AdvancedAccountUseStageServer = MZLocalizedString(
        "Use stage servers",
        comment: "Debug option",
        lastUpdated: .unknown)
}

// MARK: - App Settings
extension String {
    public static let AppSettingsLicenses = MZLocalizedString(
        "Licenses",
        comment: "Settings item that opens a tab containing the licenses. See http://mzl.la/1NSAWCG",
        lastUpdated: .unknown)
    public static let AppSettingsYourRights = MZLocalizedString(
        "Your Rights",
        comment: "Your Rights settings section title",
        lastUpdated: .unknown)
    public static let AppSettingsShowTour = MZLocalizedString(
        "Show Tour",
        comment: "Show the on-boarding screen again from the settings",
        lastUpdated: .unknown)
    public static let AppSettingsSendFeedback = MZLocalizedString(
        "Send Feedback",
        comment: "Menu item in settings used to open input.mozilla.org where people can submit feedback",
        lastUpdated: .unknown)
    public static let AppSettingsHelp = MZLocalizedString(
        "Help",
        comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ",
        lastUpdated: .unknown)
    public static let AppSettingsSearch = MZLocalizedString(
        "Search",
        comment: "Open search section of settings",
        lastUpdated: .unknown)
    public static let AppSettingsPrivacyPolicy = MZLocalizedString(
        "Privacy Policy",
        comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/",
        lastUpdated: .unknown)

    public static let AppSettingsTitle = MZLocalizedString(
        "Settings",
        comment: "Title in the settings view controller title bar",
        lastUpdated: .unknown)
    public static let AppSettingsDone = MZLocalizedString(
        "Done",
        comment: "Done button on left side of the Settings view controller title bar",
        lastUpdated: .unknown)
    public static let AppSettingsPrivacyTitle = MZLocalizedString(
        "Privacy",
        comment: "Privacy section title",
        lastUpdated: .unknown)
    public static let AppSettingsBlockPopups = MZLocalizedString(
        "Block Pop-up Windows",
        comment: "Block pop-up windows setting",
        lastUpdated: .unknown)
    public static let AppSettingsClosePrivateTabsTitle = MZLocalizedString(
        "Close Private Tabs",
        tableName: "PrivateBrowsing",
        comment: "Setting for closing private tabs",
        lastUpdated: .unknown)
    public static let AppSettingsClosePrivateTabsDescription = MZLocalizedString(
        "When Leaving Private Browsing",
        tableName: "PrivateBrowsing",
        comment: "Will be displayed in Settings under 'Close Private Tabs'",
        lastUpdated: .unknown)
    public static let AppSettingsSupport = MZLocalizedString(
        "Support",
        comment: "Support section title",
        lastUpdated: .unknown)
    public static let AppSettingsAbout = MZLocalizedString(
        "About",
        comment: "About settings section title",
        lastUpdated: .unknown)
}

// MARK: - Clearables
extension String {
    // Removed Clearables as part of Bug 1226654, but keeping the string around.
    private static let removedSavedLoginsLabel = MZLocalizedString(
        "Saved Logins",
        tableName: "ClearPrivateData",
        comment: "Settings item for clearing passwords and login data",
        lastUpdated: .unknown)

    public static let ClearableHistory = MZLocalizedString(
        "Browsing History",
        tableName: "ClearPrivateData",
        comment: "Settings item for clearing browsing history",
        lastUpdated: .unknown)
    public static let ClearableCache = MZLocalizedString(
        "Cache",
        tableName: "ClearPrivateData",
        comment: "Settings item for clearing the cache",
        lastUpdated: .unknown)
    public static let ClearableOfflineData = MZLocalizedString(
        "Offline Website Data",
        tableName: "ClearPrivateData",
        comment: "Settings item for clearing website data",
        lastUpdated: .unknown)
    public static let ClearableCookies = MZLocalizedString(
        "Cookies",
        tableName: "ClearPrivateData",
        comment: "Settings item for clearing cookies",
        lastUpdated: .unknown)
    public static let ClearableDownloads = MZLocalizedString(
        "Downloaded Files",
        tableName: "ClearPrivateData",
        comment: "Settings item for deleting downloaded files",
        lastUpdated: .unknown)
    public static let ClearableSpotlight = MZLocalizedString(
        "Spotlight Index",
        tableName: "ClearPrivateData",
        comment: "A settings item that allows a user to use Apple's \"Spotlight Search\" in Data Management's Website Data option to search for and select an item to delete.",
        lastUpdated: .unknown)
}

// MARK: - SearchEngine Picker
extension String {
    public static let SearchEnginePickerTitle = MZLocalizedString(
        "Default Search Engine",
        comment: "Title for default search engine picker.",
        lastUpdated: .unknown)
    public static let SearchEnginePickerCancel = MZLocalizedString(
        "Cancel",
        comment: "Label for Cancel button",
        lastUpdated: .unknown)
}

// MARK: - SearchSettings
extension String {
    public static let SearchSettingsTitle = MZLocalizedString(
        "SearchSettings.Title.Search.v106",
        value: "Search",
        comment: "Navigation title for search settings.",
        lastUpdated: .v106)
    public static let SearchSettingsDefaultSearchEngineAccessibilityLabel = MZLocalizedString(
        "SearchSettings.Accessibility.DefaultSearchEngine.v106",
        value: "Default Search Engine",
        comment: "Accessibility label for default search engine setting.",
        lastUpdated: .v106)
    public static let SearchSettingsShowSearchSuggestions = MZLocalizedString(
        "Show Search Suggestions",
        comment: "Label for show search suggestions setting.",
        lastUpdated: .unknown)
    public static let SearchSettingsDefaultSearchEngineTitle = MZLocalizedString(
        "SearchSettings.Title.DefaultSearchEngine.v106",
        value: "Default Search Engine",
        comment: "Title for default search engine settings section.",
        lastUpdated: .v106)
    public static let SearchSettingsQuickSearchEnginesTitle = MZLocalizedString(
        "Quick-Search Engines",
        comment: "Title for quick-search engines settings section.",
        lastUpdated: .unknown)
}

// MARK: - SettingsContent
extension String {
    public static let SettingsContentPageLoadError = MZLocalizedString(
        "Could not load page.",
        comment: "Error message that is shown in settings when there was a problem loading",
        lastUpdated: .unknown)
}

// MARK: - SearchInput
extension String {
    public static let SearchInputAccessibilityLabel = MZLocalizedString(
        "Search Input Field",
        tableName: "LoginManager",
        comment: "Accessibility label for the search input field in the Logins list",
        lastUpdated: .unknown)
    public static let SearchInputTitle = MZLocalizedString(
        "SearchInput.Title.Search.v106",
        tableName: "LoginManager",
        value: "Search",
        comment: "Title for the search field at the top of the Logins list screen",
        lastUpdated: .v106)
    public static let SearchInputClearAccessibilityLabel = MZLocalizedString(
        "Clear Search",
        tableName: "LoginManager",
        comment: "Accessibility message e.g. spoken by VoiceOver after the user taps the close button in the search field to clear the search and exit search mode",
        lastUpdated: .unknown)
    public static let SearchInputEnterSearchMode = MZLocalizedString(
        "Enter Search Mode",
        tableName: "LoginManager",
        comment: "Accessibility label for entering search mode for logins",
        lastUpdated: .unknown)
}

// MARK: - TabsButton
extension String {
    public static let TabsButtonShowTabsAccessibilityLabel = MZLocalizedString(
        "Show Tabs",
        comment: "Accessibility label for the tabs button in the (top) tab toolbar",
        lastUpdated: .unknown)
}

// MARK: - TabTrayButtons
extension String {
    public static let TabTrayButtonNewTabAccessibilityLabel = MZLocalizedString(
        "New Tab",
        comment: "Accessibility label for the New Tab button in the tab toolbar.",
        lastUpdated: .unknown)
    public static let TabTrayButtonShowTabsAccessibilityLabel = MZLocalizedString(
        "TabTrayButtons.Accessibility.ShowTabs.v106",
        value: "Show Tabs",
        comment: "Accessibility Label for the tabs button in the tab toolbar",
        lastUpdated: .v106)
}

// MARK: - MenuHelper
extension String {
    public static let MenuHelperPasteAndGo = MZLocalizedString(
        "UIMenuItem.PasteGo",
        value: "Paste & Go",
        comment: "The menu item that pastes the current contents of the clipboard into the URL bar and navigates to the page",
        lastUpdated: .unknown)
    public static let MenuHelperReveal = MZLocalizedString(
        "Reveal",
        tableName: "LoginManager",
        comment: "Reveal password text selection menu item",
        lastUpdated: .unknown)
    public static let MenuHelperHide =  MZLocalizedString(
        "Hide",
        tableName: "LoginManager",
        comment: "Hide password text selection menu item",
        lastUpdated: .unknown)
    public static let MenuHelperCopy = MZLocalizedString(
        "Copy",
        tableName: "LoginManager",
        comment: "Copy password text selection menu item",
        lastUpdated: .unknown)
    public static let MenuHelperOpenAndFill = MZLocalizedString(
        "Open & Fill",
        tableName: "LoginManager",
        comment: "Open and Fill website text selection menu item",
        lastUpdated: .unknown)
    public static let MenuHelperFindInPage = MZLocalizedString(
        "Find in Page",
        tableName: "FindInPage",
        comment: "Text selection menu item",
        lastUpdated: .unknown)
    public static let MenuHelperSearchWithFirefox = MZLocalizedString(
        "UIMenuItem.SearchWithFirefox",
        value: "Search with Firefox",
        comment: "Search in New Tab Text selection menu item",
        lastUpdated: .unknown)
}

// MARK: - DeviceInfo
extension String {
    public static let DeviceInfoClientNameDescription = MZLocalizedString(
        "%@ on %@",
        tableName: "Shared",
        comment: "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs. The first argument is the app name. The second argument is the device name.",
        lastUpdated: .unknown)
}

// MARK: - TimeConstants
extension String {
    public static let TimeConstantMoreThanAMonth = MZLocalizedString(
        "more than a month ago",
        comment: "Relative date for dates older than a month and less than two months.",
        lastUpdated: .unknown)
    public static let TimeConstantMoreThanAWeek = MZLocalizedString(
        "more than a week ago",
        comment: "Description for a date more than a week ago, but less than a month ago.",
        lastUpdated: .unknown)
    public static let TimeConstantYesterday = MZLocalizedString(
        "TimeConstants.Yesterday.v106",
        value: "yesterday",
        comment: "Relative date for yesterday.",
        lastUpdated: .v106)
    public static let TimeConstantThisWeek = MZLocalizedString(
        "this week",
        comment: "Relative date for date in past week.",
        lastUpdated: .unknown)
    public static let TimeConstantRelativeToday = MZLocalizedString(
        "today at %@",
        comment: "Relative date for date older than a minute.",
        lastUpdated: .unknown)
    public static let TimeConstantJustNow = MZLocalizedString(
        "just now",
        comment: "Relative time for a tab that was visited within the last few moments.",
        lastUpdated: .unknown)
}

// MARK: - Default Suggested Site
extension String {
    public static let DefaultSuggestedFacebook = MZLocalizedString(
        "Facebook",
        comment: "Tile title for Facebook",
        lastUpdated: .unknown)
    public static let DefaultSuggestedYouTube = MZLocalizedString(
        "YouTube",
        comment: "Tile title for YouTube",
        lastUpdated: .unknown)
    public static let DefaultSuggestedAmazon = MZLocalizedString(
        "Amazon",
        comment: "Tile title for Amazon",
        lastUpdated: .unknown)
    public static let DefaultSuggestedWikipedia = MZLocalizedString(
        "Wikipedia",
        comment: "Tile title for Wikipedia",
        lastUpdated: .unknown)
    public static let DefaultSuggestedTwitter = MZLocalizedString(
        "Twitter",
        comment: "Tile title for Twitter",
        lastUpdated: .unknown)
}

// MARK: - Credential Provider
extension String {
    public static let LoginsWelcomeViewTitle2 = MZLocalizedString(
        "Logins.WelcomeView.Title2",
        value: "AutoFill Firefox Passwords",
        comment: "Label displaying welcome view title",
        lastUpdated: .unknown)
    public static let LoginsWelcomeViewTagline = MZLocalizedString(
        "Logins.WelcomeView.Tagline",
        value: "Take your passwords everywhere",
        comment: "Label displaying welcome view tagline under the title",
        lastUpdated: .unknown)
    public static let LoginsWelcomeTurnOnAutoFillButtonTitle = MZLocalizedString(
        "Logins.WelcomeView.TurnOnAutoFill",
        value: "Turn on AutoFill",
        comment: "Title of the big blue button to enable AutoFill",
        lastUpdated: .unknown)
    public static let LoginsListSearchCancel = MZLocalizedString(
        "LoginsList.Search.Cancel",
        value: "Cancel",
        comment: "Title for cancel button for user to stop searching for a particular login",
        lastUpdated: .unknown)
    public static let LoginsListSearchPlaceholderCredential = MZLocalizedString(
        "LoginsList.Search.Placeholder",
        value: "Search logins",
        comment: "Placeholder text for search field",
        lastUpdated: .unknown)
    public static let LoginsListSelectPasswordTitle = MZLocalizedString(
        "LoginsList.SelectPassword.Title",
        value: "Select a password to fill",
        comment: "Label displaying select a password to fill instruction",
        lastUpdated: .unknown)
    public static let LoginsListNoMatchingResultTitle = MZLocalizedString(
        "LoginsList.NoMatchingResult.Title",
        value: "No matching logins",
        comment: "Label displayed when a user searches and no matches can be found against the search query",
        lastUpdated: .unknown)
    public static let LoginsListNoMatchingResultSubtitle = MZLocalizedString(
        "LoginsList.NoMatchingResult.Subtitle",
        value: "There are no results matching your search.",
        comment: "Label that appears after the search if there are no logins matching the search",
        lastUpdated: .unknown)
    public static let LoginsListNoLoginsFoundTitle = MZLocalizedString(
        "LoginsList.NoLoginsFound.Title",
        value: "No logins found",
        comment: "Label shown when there are no logins saved",
        lastUpdated: .unknown)
    public static let LoginsListNoLoginsFoundDescription = MZLocalizedString(
        "LoginsList.NoLoginsFound.Description",
        value: "Saved logins will show up here. If you saved your logins to Firefox on a different device, sign in to your Firefox Account.",
        comment: "Label shown when there are no logins to list",
        lastUpdated: .unknown)
    public static let LoginsPasscodeRequirementWarning = MZLocalizedString(
        "Logins.PasscodeRequirement.Warning",
        value: "To use the AutoFill feature for Firefox, you must have a device passcode enabled.",
        comment: "Warning message shown when you try to enable or use native AutoFill without a device passcode setup",
        lastUpdated: .unknown)
}

// MARK: - v35 Strings
extension String {
    public static let FirefoxHomeJumpBackInSectionTitle = MZLocalizedString(
        "ActivityStream.JumpBackIn.SectionTitle",
        value: "Jump Back In",
        comment: "Title for the Jump Back In section. This section allows users to jump back in to a recently viewed tab",
        lastUpdated: .unknown)
    public static let TabsTrayInactiveTabsSectionTitle = MZLocalizedString(
        "TabTray.InactiveTabs.SectionTitle",
        value: "Inactive Tabs",
        comment: "Title for the inactive tabs section. This section groups all tabs that haven't been used in a while.",
        lastUpdated: .unknown)
}

// MARK: - v36 Strings
extension String {
    public static let ProtectionStatusSecure = MZLocalizedString(
        "ProtectionStatus.Secure",
        value: "Connection is secure",
        comment: "This is the value for a label that indicates if a user is on a secure https connection.",
        lastUpdated: .unknown)
    public static let ProtectionStatusNotSecure = MZLocalizedString(
        "ProtectionStatus.NotSecure",
        value: "Connection is not secure",
        comment: "This is the value for a label that indicates if a user is on an unencrypted website.",
        lastUpdated: .unknown)
}
