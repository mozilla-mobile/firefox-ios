// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

// MARK: - Localization bundle setup
class BundleClass {}

public struct Strings {
    public static let bundle = Bundle(for: BundleClass.self)
}

// MARK: - String last updated app version

// Used as a helper enum to keep track of what app version strings were last updated in. Updates
// are considered .unknown unless the string's Key is updated, or of course a new string is introduced.
fileprivate enum StringLastUpdatedAppVersion {
    case v39
    case v96

    // Used for all cases before version 39.
    case unknown
}

// MARK: - Localization helper function
fileprivate func MZLocalizedString(_ key: String, tableName: String? = nil, value: String = "", comment: String, lastUpdated: StringLastUpdatedAppVersion) -> String {
    return NSLocalizedString(key, tableName: tableName, bundle: Strings.bundle, value: value, comment: comment)
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
        
        public struct Actions {
            public static let Add = MZLocalizedString("Bookmarks.Actions.Add", value: "Add", comment: "A label indicating the action of adding a web page as a bookmark.", lastUpdated: .v96)
            public static let BookmarkAllTabs = MZLocalizedString("Bookmarks.Actions.BookmarkAllTabs", value: "Bookmark All Tabs", comment: "A label indicating the action of bookmarking all currently open non private tabs.", lastUpdated: .v96)
            public static let BookmarkCurrentTab = MZLocalizedString("Bookmarks.Actions.BookmarkCurrentTab", value: "Bookmark Current Tab", comment: "A label indicating the action of bookmarking the current tab.", lastUpdated: .v96)
        }
        
        public struct Menu {
            public static let DesktopBookmarks = MZLocalizedString("Bookmarks.Menu.DesktopBookmarks", value: "Desktop Bookmarks", comment: "A label indicating all bookmarks grouped under the category 'Desktop Bookmarks'.", lastUpdated: .v96)
            public static let RecentlyBookmarked = MZLocalizedString("Bookmarks.Menu.RecentlyBookmarked", value: "Recently Bookmarked", comment: "A label indicating all bookmarks that were recently added.", lastUpdated: .v96)
        }
        
        public struct Search {
            public static let SearchBookmarks = MZLocalizedString("Bookmarks.Search.SearchBookmarks", value: "Search Bookmarks", comment: "A label serving as a placeholder text in the search bar that's embedded in the Bookmarks menu. The placeholder text indicates that a user can search and filter bookmarks.", lastUpdated: .v96)
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

            public struct ThreeDot {

            }

            public struct LongPressGesture {

            }
        }
    }
}

// MARK: - Contextual Hints
extension String {
    public struct ContextualHints {
        public static let PersonalizedHome = MZLocalizedString("ContextualHints.Homepage.PersonalizedHome", value: "Your personalized Firefox homepage now makes it easier to pick up where you left off. Find your recent tabs, bookmarks, and search results.", comment: "Contextual hints are little popups that appear for the users informing them of new features. This one talks about the more personalized home feature.", lastUpdated: .v39)
        public static let InactiveTabsBody = MZLocalizedString("ContextualHints.TabTray.InactiveTabs", value: "Tabs you haven’t viewed for two weeks get moved here.", comment: "Contextual hints are little popups that appear for the users informing them of new features. This one talks about the inactive tabs feature.", lastUpdated: .v39)
        public static let InactiveTabsAction = MZLocalizedString("ContextualHints.TabTray.InactiveTabs.CallToAction", value: "Turn off in settings", comment: "Contextual hints are little popups that appear for the users informing them of new features. This one is the call to action for the inactive tabs contextual popup.", lastUpdated: .v39)
    }
}

// MARK: - Enhanced Tracking Protection screen
extension String {
    public struct ETPMenu {

    }
}

// MARK: - Firefox Homepage
extension String {
    public struct FirefoxHomepage {

        public struct CustomizeHomepage {
            public static let ButtonTitle = MZLocalizedString("FirefoxHome.CustomizeHomeButton.Title", value: "Customize Homepage", comment: "A button at bottom of the Firefox homepage that, when clicked, takes users straight to the settings options, where they can customize the Firefox Home page", lastUpdated: .v39)
        }

        public struct JumpBackIn {
            public static let GroupSiteCount = MZLocalizedString("ActivityStream.JumpBackIn.TabGroup.SiteCount", value: "Tabs: %d", comment: "On the Firefox homepage in the Jump Back In section, if a Tab group item - a collection of grouped tabs from a related search - exists underneath the search term for the tab group, there will be a subtitle with a number for how many tabs are in that group. The placeholder is for a number. It will read 'Tabs: 5' or similar.", lastUpdated: .v39)
            public static let GroupTitle = MZLocalizedString("ActivityStream.JumpBackIn.TabGroup.Title", value: "Your search for \"%@\"", comment: "On the Firefox homepage in the Jump Back In section, if a Tab group item - a collection of grouped tabs from a related search - exists, the Tab Group item title will be 'Your search for \"video games\"'. The %@ sign is a placeholder for the actual search the user did.", lastUpdated: .v39)
        }

        public struct Pocket {

        }

        public struct RecentlySaved {

        }

        public struct HistoryHighlights {
            public static let Title = MZLocalizedString("ActivityStream.RecentHistory.Title", value: "Recently Visited", comment: "Section title label for recently visited websites", lastUpdated: .v96)

        }

        public struct Shortcuts {

        }

        public struct YourLibrary {

        }
    }
}

// MARK: - Keyboard shortcuts/"hotkeys"
extension String {
    public struct KeyboardShortcuts {
        public static let ActualSize = MZLocalizedString("Keyboard.Shortcuts.ActualSize", value: "Actual Size", comment: "A label indicating the keyboard shortcut of resetting a web page's view to the standard viewing size. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let AddBookmark = MZLocalizedString("Keyboard.Shortcuts.AddBookmark", value: "Add Bookmark", comment: "A label indicating the keyboard shortcut of adding the currently viewing web page as a bookmark. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let Back = MZLocalizedString("Hotkeys.Back.DiscoveryTitle", value: "Back", comment: "A label indicating the keyboard shortcut to navigate backwards, through session history, inside the current tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ClearRecentHistory = MZLocalizedString("Keyboard.Shortcuts.ClearRecentHistory", value: "Clear Recent History", comment: "A label indicating the keyboard shortcut of clearing recent history. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let CloseAllTabsInTabTray = MZLocalizedString("TabTray.CloseAllTabs.KeyCodeTitle", value: "Close All Tabs", comment: "A label indicating the keyboard shortcut of closing all tabs from the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let CloseSelectedTabInTabTray = MZLocalizedString("TabTray.CloseTab.KeyCodeTitle", value: "Close Selected Tab", comment: "A label indicating the keyboard shortcut of closing the currently selected tab from the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let CloseCurrentTab = MZLocalizedString("Hotkeys.CloseTab.DiscoveryTitle", value: "Close Tab", comment: "A label indicating the keyboard shortcut of closing the current tab a user is in. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let DownloadLink = MZLocalizedString("Keyboard.Shortcuts.DownloadLink", value: "Download Link", comment: "A label indicating the keyboard shortcut of downloading a link the user taps on. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let Find = MZLocalizedString("Hotkeys.Find.DiscoveryTitle", value: "Find", comment: "A label indicating the keyboard shortcut of finding text a user desires within a page. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let FindAgain = MZLocalizedString("Keyboard.Shortcuts.FindAgain", value: "Find Again", comment: "A label indicating the keyboard shortcut of finding text a user desires within a page again. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let Forward = MZLocalizedString("Hotkeys.Forward.DiscoveryTitle", value: "Forward", comment: "A label indicating the keyboard shortcut of switching to a subsequent tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let NewPrivateTab = MZLocalizedString("Hotkeys.NewPrivateTab.DiscoveryTitle", value: "New Private Tab", comment: "A label indicating the keyboard shortcut of creating a new private tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let NewTab = MZLocalizedString("Hotkeys.NewTab.DiscoveryTitle", value: "New Tab", comment: "A label indicating the keyboard shortcut of creating a new tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let NormalBrowsingMode = MZLocalizedString("Hotkeys.NormalMode.DiscoveryTitle", value: "Normal Browsing Mode", comment: "A label indicating the keyboard shortcut of switching from Private Browsing to Normal Browsing Mode. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let OpenLinkInBackground = MZLocalizedString("Keyboard.Shortcuts.OpenLinkInBackground", value: "Open Link in Background", comment: "A label indicating the keyboard shortcut of opening a link in a new tab while staying on the currently selected tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let OpenLinkInNewTab = MZLocalizedString("Keyboard.Shortcuts.OpenLinkInNewTab", value: "Open Link in New Tab", comment: "A label indicating the keyboard shortcut of opening a link in a new tab and switching to that tab at the same time. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let OpenNewTabInTabTray = MZLocalizedString("TabTray.OpenNewTab.KeyCodeTitle", value: "Open New Tab", comment: "A label indicating the keyboard shortcut of opening a new tab in the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let PrivateBrowsingMode = MZLocalizedString("Hotkeys.PrivateMode.DiscoveryTitle", value: "Private Browsing Mode", comment: "A label indicating the keyboard shortcut of switching from Normal Browsing mode to Private Browsing Mode. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ReloadPage = MZLocalizedString("Hotkeys.Reload.DiscoveryTitle", value: "Reload Page", comment: "A label indicating the keyboard shortcut of reloading the current page. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let SavePageAs = MZLocalizedString("Keyboard.Shortcuts.SavePageAs", value: "Save Page As…", comment: "A label indicating the keyboard shortcut of saving the current web page in a format of the user's choice. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let SelectLocationBar = MZLocalizedString("Hotkeys.SelectLocationBar.DiscoveryTitle", value: "Select Location Bar", comment: "A label indicating the keyboard shortcut of directly accessing the URL, location, bar. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let Settings = MZLocalizedString("Keyboard.Shortcuts.Settings", value: "Settings", comment: "A label indicating the keyboard shortcut of opening the application's settings menu. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowBookmarks = MZLocalizedString("Keyboard.Shortcuts.ShowBookmarks", value: "Show Bookmarks", comment: "A label indicating the keyboard shortcut of showing all bookmarks. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowDownloads = MZLocalizedString("Keyboard.Shortcuts.ShowDownloads", value: "Show Downloads", comment: "A label indcating the keyboard shortcut of showing all downloads. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowFirstTab = MZLocalizedString("Keyboard.Shortcuts.ShowFirstTab", value: "Show First Tab", comment: "A label indicating the keyboard shortcut to switch from the current tab to the first tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowHistory = MZLocalizedString("Keyboard.Shortcuts.ShowHistory", value: "Show History", comment: "A label indicating the keyboard shortcut of showing all history. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowLastTab = MZLocalizedString("Keyboard.Shortcuts.ShowLastTab", value: "Show Last Tab", comment: "A label indicating the keyboard shortcut switch from your current tab to the last tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowNextTab = MZLocalizedString("Hotkeys.ShowNextTab.DiscoveryTitle", value: "Show Next Tab", comment: "A label indicating the keyboard shortcut of switching to a subsequent tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowPreviousTab = MZLocalizedString("Hotkeys.ShowPreviousTab.DiscoveryTitle", value: "Show Previous Tab", comment: "A label indicating the keyboard shortcut of switching to a tab immediately preceding to the currently selected tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowTabNumber = MZLocalizedString("Keyboard.Shortcuts.ShowTabNumber", value: "Show Tab Number 1-9", comment: "A label indicating the keyboard shortcut of switching between the first nine tabs. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ShowTabTray = MZLocalizedString("Tab.ShowTabTray.KeyCodeTitle", value: "Show All Tabs", comment: "A label indicating the keyboard shortcut of showing the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ZoomIn = MZLocalizedString("Keyboard.Shortcuts.ZoomIn", value: "Zoom In", comment: "A label indicating the keyboard shortcut of enlarging the view of the current web page. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        public static let ZoomOut = MZLocalizedString("Keyboard.Shortcuts.ZoomOut", value: "Zoom Out", comment: "A label indicating the keyboard shortcut of shrinking the view of the current web page. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        
        public struct Sections {
            public static let Bookmarks = MZLocalizedString("Keyboard.Shortcuts.Section.Bookmark", value: "Bookmarks", comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with Bookmarks. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
            public static let Edit = MZLocalizedString("Keyboard.Shortcuts.Section.Edit", value: "Edit", comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do within a web page. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
            public static let File = MZLocalizedString("Keyboard.Shortcuts.Section.File", value: "File", comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can take on, and within, a Tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
            public static let History = MZLocalizedString("Keyboard.Shortcuts.Section.History", value: "History", comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with History. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
            public static let Tools = MZLocalizedString("Keyboard.Shortcuts.Section.Tools", value: "Tools", comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with locally saved items. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
            public static let View = MZLocalizedString("Keyboard.Shortcuts.Section.View", value: "View", comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do regarding the viewing experience of a webpage. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
            public static let Window = MZLocalizedString("Keyboard.Shortcuts.Section.Window", value: "Window", comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can take when navigating between their availale set of tabs. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.", lastUpdated: .v96)
        }
        
    }
}

// MARK: - Library Panel
extension String {
    public struct LibraryPanel {
        
        public struct Sections {
            public static let Today = MZLocalizedString("Today", value: "Today", comment: "This label is meant to signify the section containing a group of items from the current day.", lastUpdated: .unknown)
            public static let Yesterday = MZLocalizedString("Yesterday", value: "Yesterday", comment: "This label is meant to signify the section containing a group of items from the past 24 hours.", lastUpdated: .unknown)
            public static let LastWeek = MZLocalizedString("Last week", value: "Last week", comment: "This label is meant to signify the section containing a group of items from the past seven days.", lastUpdated: .unknown)
            public static let LastMonth = MZLocalizedString("Last month", value: "Last month", comment: "This label is meant to signify the section containing a group of items from the past thirty days.", lastUpdated: .unknown)
            public static let Older = MZLocalizedString("LibraryPanel.Section.Older", value: "Older", comment: "This label is meant to signify the section containing a group of items that are older than thirty days.", lastUpdated: .v96)
        }

        public struct Bookmarks {

        }

        public struct History {

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

    }
}

// MARK: - Passwords and Logins
extension String {
    public struct PasswordsAndLogins {

    }
}

// MARK: - Ratings Prompt
extension String {
    public struct RatingsPrompt {
        
        public struct Settings {
            public static let RateOnAppStore = MZLocalizedString("Ratings.Settings.RateOnAppStore", value: "Rate on App Store", comment: "A label indicating the action that a user can rate the Firefox app in the App store.", lastUpdated: .v96)
        }
    
    }
}

// MARK: - Settings screen
extension String {
    public struct Settings {

        public struct SectionTitles {
            public static let TabsTitle = MZLocalizedString("Settings.Tabs.Title", value: "Tabs", comment: "In the settings menu, this is the title for the Tabs customization section option", lastUpdated: .v39)
        }

        public struct Homepage {

            public struct CustomizeFirefoxHome {
                public static let JumpBackIn = MZLocalizedString("Settings.Home.Option.JumpBackIn", value: "Jump Back In", comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle the Jump Back In section on homepage on or off", lastUpdated: .v39)
                public static let RecentlyVisited = MZLocalizedString("Settings.Home.Option.RecentlyVisited", value: "Recently Visited", comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Recently Visited section on the Firfox homepage on or off", lastUpdated: .v39)
                public static let RecentlySaved = MZLocalizedString("Settings.Home.Option.RecentlySaved", value: "Recently Saved", comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Recently Saved section on the Firefox homepage on or off", lastUpdated: .v39)
                public static let RecentSearches = MZLocalizedString("Settings.Home.Option.RecentSearches", value: "Recent Searches", comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Recent Searches section on the Firefox homepage on or off", lastUpdated: .v39)
                public static let Shortcuts = MZLocalizedString("Settings.Home.Option.Shortcuts", value: "Shortcuts", comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Shortcuts section on the Firefox homepage on or off", lastUpdated: .v39)
                public static let Pocket = MZLocalizedString("Settings.Home.Option.Pocket", value: "Recommended by Pocket", comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to turn the Pocket Recommendations section on the Firefox homepage on or off", lastUpdated: .v39)
                public static let Description = MZLocalizedString("Settings.Home.Option.Description", value: "Choose content you see on the Firefox homepage.", comment: "In the settings menu, on the Firefox homepage customization section, this is the description below the section, describing what the options in the section are for.", lastUpdated: .v39)
            }

            public struct StartAtHome {
                public static let SectionTitle = MZLocalizedString("Settings.Home.Option.StartAtHome.Title", value: "Opening screen", comment: "Title for the section in the settings menu where users can configure the behaviour of the Start at Home feature on the Firefox Homepage.", lastUpdated: .v39)
                public static let SectionDescription = MZLocalizedString("Settings.Home.Option.StartAtHome.Description", value: "Choose what you see when you return to Firefox.", comment: "In the settings menu, in the Start at Home customization options, this is text that appears below the section, describing what the section settings do.", lastUpdated: .v39)
                public static let AfterFourHours = MZLocalizedString("Settings.Home.Option.StartAtHome.AfterFourHours", value: "Homepage after four hours of inactivity", comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the Homepage after four hours of inactivity.", lastUpdated: .v39)
                public static let Always = MZLocalizedString("Settings.Home.Option.StartAtHome.Always", value: "Homepage", comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the Homepage every time they open up Firefox", lastUpdated: .v39)
                public static let Never = MZLocalizedString("Settings.Home.Option.StartAtHome.Never", value: "Last tab", comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the last tab they were on, every time they open up Firefox", lastUpdated: .v39)
            }
        }

        public struct Tabs {
            public static let TabsSectionTitle = MZLocalizedString("Settings.Tabs.CustomizeTabsSection.Title", value: "Customize Tab Tray", comment: "In the settings menu, in the Tabs customization section, this is the title for the Tabs Tray customization section. The tabs tray is accessed from firefox hompage", lastUpdated: .v39)
            public static let InactiveTabs = MZLocalizedString("Settings.Tabs.CustomizeTabsSection.InactiveTabs", value: "Inactive Tabs", comment: "In the settings menu, in the Tabs customization section, this is the title for the setting that toggles the Inactive Tabs feature, a separate section of inactive tabs that appears in the Tab Tray, on or off", lastUpdated: .v39)
            public static let TabGroups = MZLocalizedString("Settings.Tabs.CustomizeTabsSection.TabGroups", value: "Tab Groups", comment: "In the settings menu, in the Tabs customization section, this is the title for the setting that toggles the Tab Groups feature - where tabs from related searches are grouped - on or off", lastUpdated: .v39)
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

        public static let OtherTabsLabelTitle = MZLocalizedString("TabTray.OtherTabs.Title", value: "Other tabs", comment: "In the Tabs Tray, summoned from the homepage, the title for the section containing non-grouped tabs, which will appear below grouped tabs", lastUpdated: .v39)

        public struct InactiveTabs {

            public static let CloseAllInactiveTabsButton = MZLocalizedString("InactiveTabs.TabTray.CloseButtonTitle", value: "Close All Inactive Tabs", comment: "In the Tabs Tray, in the Inactive Tabs section, this is the button the user must tap in order to close all inactive tabs.", lastUpdated: .v39)

            public struct AutoClose {
                public static let PromptTitle = MZLocalizedString("InactiveTabs.TabTray.AutoClosePrompt.Title", value: "Auto-close after one month?", comment: "In the Tabs Tray, in the Inactive Tabs section, a prompt may come up about auto-closing tabs. This is the title of that Auto Close prompt", lastUpdated: .v39)
                public static let PromptContent = MZLocalizedString("InactiveTabs.TabTray.AutoClosePrompt.Content", value: "Firefox will close tabs you haven’t viewed over the past month.", comment: "In the Tabs Tray, in the Inactive Tabs section, a prompt may come up about auto-closing tabs. This string describes what happens if you elect to turn on this option.", lastUpdated: .v39)
                public static let PromptButton = MZLocalizedString("InactiveTabs.TabTray.AutoClosePrompt.ButtonTitle", value: "Turn on Auto Close", comment: "In the Tabs Tray, in the Inactive Tabs section, a prompt may come up about auto-closing tabs. This string is for the button the user must tap in order to turn on the Auto close feature", lastUpdated: .v39)
            }
        }
    }
}

// MARK: - What's New
extension String {
    /// The text for the What's New onboarding card
    public struct WhatsNew {
        public static let Title = MZLocalizedString("Onboarding.WhatsNew.Title", value: "What’s New in Firefox", comment: "The title for the new onboarding card letting users know what is new in Firefox iOS", lastUpdated: .v39)
        public static let GeneralDescription = MZLocalizedString("Onboarding.WhatsNew.Description", value: "It’s now easier to pick up where you left off.", comment: "On the onboarding card, letting users know what's new in this version of Firefox, this is a general description that appears under the title for what the card is about.", lastUpdated: .v39)
        public static let PersonalizedHomeTitle = MZLocalizedString("Onboarding.WhatsNew.Title", value: "Personalized Firefox Homepage", comment: "On the onboarding card, letting users know what's new in this version of Firefox, this is the title for the Jump Back In bullet point on the card", lastUpdated: .v39)
        public static let PersonalizedHomeDescription = MZLocalizedString("Onboarding.WhatsNew.PersonalizedHome.Description", value: "Jump to your open tabs, bookmarks, and browsing history.", comment: "On the onboarding card, letting users know what's new in this version of Firefox, this is the description for the Jump Back In bullet point", lastUpdated: .v39)
        public static let TabGroupsTitle = MZLocalizedString("Onboarding.WhatsNew.TabGroups.Title", value: "Tidier Tab Groups", comment: "On the onboarding card, letting users know what's new in this version of Firefox, this is the title for the Tab Group bullet point on the card", lastUpdated: .v39)
        public static let TabGroupsDescription = MZLocalizedString("Onboarding.WhatsNew.TabGroups.Description", value: "Pages from the same search get grouped together.", comment: "On the onboarding card letting users know what's new in this version of Firefox, this is the description for the Tab Group bullet point on the card", lastUpdated: .v39)
        public static let RecentSearchesTitle = MZLocalizedString("Onboarding.WhatsNew.RecentSearches.Title", value: "Recent Searches", comment: "On the onboarding card letting users know what's new in this version of Firefox, this is the title for the Recent Searches bullet point on the card", lastUpdated: .v39)
        public static let RecentSearchesDescription = MZLocalizedString("Onboarding.WhatsNew.RecentSearches.Description", value: "Revisit your latest searches from your homepage.", comment: "On the onboarding card letting users know what's new in this version of Firefox, this is the descripion of the Recent Searches bullet point on the card", lastUpdated: .v39)
        public static let RecentButtonTitle = MZLocalizedString("Onboarding.WhatsNew.Button.Title", value: "Start Browsing", comment: "On the onboarding card letting users know what's new in this version of Firefox, this is the title for the button, on the bottom of the card, used to get back to browsing on Firefox by dismissing the onboarding card", lastUpdated: .v39)
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
    public static let OKString = MZLocalizedString("OK", comment: "OK button", lastUpdated: .unknown)
    public static let CancelString = MZLocalizedString("Cancel", comment: "Label for Cancel button", lastUpdated: .unknown)
    public static let NotNowString = MZLocalizedString("Toasts.NotNow", value: "Not Now", comment: "label for Not Now button", lastUpdated: .unknown)
    public static let AppStoreString = MZLocalizedString("Toasts.OpenAppStore", value: "Open App Store", comment: "Open App Store button", lastUpdated: .unknown)
    public static let UndoString = MZLocalizedString("Toasts.Undo", value: "Undo", comment: "Label for button to undo the action just performed", lastUpdated: .unknown)
    public static let OpenSettingsString = MZLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7", lastUpdated: .unknown)
}

// MARK: - Top Sites
extension String {
    public static let TopSitesEmptyStateDescription = MZLocalizedString("TopSites.EmptyState.Description", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.", lastUpdated: .unknown)
    public static let TopSitesEmptyStateTitle = MZLocalizedString("TopSites.EmptyState.Title", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state", lastUpdated: .unknown)
    public static let TopSitesRemoveButtonAccessibilityLabel = MZLocalizedString("TopSites.RemovePage.Button", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.", lastUpdated: .unknown)
}

// MARK: - Activity Stream
extension String {
    public static let ASPocketTitle = MZLocalizedString("ActivityStream.Pocket.SectionTitle", value: "Trending on Pocket", comment: "Section title label for Recommended by Pocket section", lastUpdated: .unknown)
    public static let ASPocketTitle2 = MZLocalizedString("ActivityStream.Pocket.SectionTitle2", value: "Recommended by Pocket", comment: "Section title label for Recommended by Pocket section", lastUpdated: .unknown)
    public static let ASTopSitesTitle =  MZLocalizedString("ActivityStream.TopSites.SectionTitle", value: "Top Sites", comment: "Section title label for Top Sites", lastUpdated: .unknown)
    public static let ASShortcutsTitle =  MZLocalizedString("ActivityStream.Shortcuts.SectionTitle", value: "Shortcuts", comment: "Section title label for Shortcuts", lastUpdated: .unknown)
    public static let HighlightVistedText = MZLocalizedString("ActivityStream.Highlights.Visited", value: "Visited", comment: "The description of a highlight if it is a site the user has visited", lastUpdated: .unknown)
    public static let HighlightBookmarkText = MZLocalizedString("ActivityStream.Highlights.Bookmark", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked", lastUpdated: .unknown)
    public static let PocketTrendingText = MZLocalizedString("ActivityStream.Pocket.Trending", value: "Trending", comment: "The description of a Pocket Story", lastUpdated: .unknown)
    public static let PocketMoreStoriesText = MZLocalizedString("ActivityStream.Pocket.MoreLink", value: "More", comment: "The link that shows more Pocket trending stories", lastUpdated: .unknown)
    public static let TopSitesRowSettingFooter = MZLocalizedString("ActivityStream.TopSites.RowSettingFooter", value: "Set Rows", comment: "The title for the setting page which lets you select the number of top site rows", lastUpdated: .unknown)
    public static let TopSitesRowCount = MZLocalizedString("ActivityStream.TopSites.RowCount", value: "Rows: %d", comment: "label showing how many rows of topsites are shown. %d represents a number", lastUpdated: .unknown)
    public static let RecentlyBookmarkedTitle = MZLocalizedString("ActivityStream.NewRecentBookmarks.Title", value: "Recent Bookmarks", comment: "Section title label for recently bookmarked websites", lastUpdated: .unknown)
    public static let RecentlySavedSectionTitle = MZLocalizedString("ActivityStream.Library.Title", value: "Recently Saved", comment: "A string used to signify the start of the Recently Saved section in Home Screen.", lastUpdated: .unknown)
    public static let RecentlySavedShowAllText = MZLocalizedString("RecentlySaved.Actions.More", value: "Show All", comment: "More button text for Recently Saved items at the home page.", lastUpdated: .unknown)
}

// MARK: - Home Panel Context Menu
extension String {
    public static let OpenInNewTabContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.OpenInNewTab", value: "Open in New Tab", comment: "The title for the Open in New Tab context menu action for sites in Home Panels", lastUpdated: .unknown)
    public static let OpenInNewPrivateTabContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.OpenInNewPrivateTab", value: "Open in New Private Tab", comment: "The title for the Open in New Private Tab context menu action for sites in Home Panels", lastUpdated: .unknown)
    public static let BookmarkContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Bookmark", value: "Bookmark", comment: "The title for the Bookmark context menu action for sites in Home Panels", lastUpdated: .unknown)
    public static let RemoveBookmarkContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.RemoveBookmark", value: "Remove Bookmark", comment: "The title for the Remove Bookmark context menu action for sites in Home Panels", lastUpdated: .unknown)
    public static let DeleteFromHistoryContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.DeleteFromHistory", value: "Delete from History", comment: "The title for the Delete from History context menu action for sites in Home Panels", lastUpdated: .unknown)
    public static let ShareContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Share", value: "Share", comment: "The title for the Share context menu action for sites in Home Panels", lastUpdated: .unknown)
    public static let RemoveContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Remove", value: "Remove", comment: "The title for the Remove context menu action for sites in Home Panels", lastUpdated: .unknown)
    public static let PinTopsiteActionTitle = MZLocalizedString("ActivityStream.ContextMenu.PinTopsite", value: "Pin to Top Sites", comment: "The title for the pinning a topsite action", lastUpdated: .unknown)
    public static let PinTopsiteActionTitle2 = MZLocalizedString("ActivityStream.ContextMenu.PinTopsite2", value: "Pin", comment: "The title for the pinning a topsite action", lastUpdated: .unknown)
    public static let UnpinTopsiteActionTitle2 = MZLocalizedString("ActivityStream.ContextMenu.UnpinTopsite", value: "Unpin", comment: "The title for the unpinning a topsite action", lastUpdated: .unknown)
    public static let AddToShortcutsActionTitle = MZLocalizedString("ActivityStream.ContextMenu.AddToShortcuts", value: "Add to Shortcuts", comment: "The title for the pinning a shortcut action", lastUpdated: .unknown)
    public static let RemoveFromShortcutsActionTitle = MZLocalizedString("ActivityStream.ContextMenu.RemoveFromShortcuts", value: "Remove from Shortcuts", comment: "The title for removing a shortcut action", lastUpdated: .unknown)
    public static let RemovePinTopsiteActionTitle = MZLocalizedString("ActivityStream.ContextMenu.RemovePinTopsite", value: "Remove Pinned Site", comment: "The title for removing a pinned topsite action", lastUpdated: .unknown)
}

//  MARK: - PhotonActionSheet String
extension String {
    public static let CloseButtonTitle = MZLocalizedString("PhotonMenu.close", value: "Close", comment: "Button for closing the menu action sheet", lastUpdated: .unknown)
}

// MARK: - Home page
extension String {
    public static let SettingsHomePageSectionName = MZLocalizedString("Settings.HomePage.SectionName", value: "Homepage", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.", lastUpdated: .unknown)
    public static let SettingsHomePageTitle = MZLocalizedString("Settings.HomePage.Title", value: "Homepage Settings", comment: "Title displayed in header of the setting panel.", lastUpdated: .unknown)
    public static let SettingsHomePageURLSectionTitle = MZLocalizedString("Settings.HomePage.URL.Title", value: "Current Homepage", comment: "Title of the setting section containing the URL of the current home page.", lastUpdated: .unknown)
    public static let SettingsHomePageUseCurrentPage = MZLocalizedString("Settings.HomePage.UseCurrent.Button", value: "Use Current Page", comment: "Button in settings to use the current page as home page.", lastUpdated: .unknown)
    public static let SettingsHomePagePlaceholder = MZLocalizedString("Settings.HomePage.URL.Placeholder", value: "Enter a webpage", comment: "Placeholder text in the homepage setting when no homepage has been set.", lastUpdated: .unknown)
    public static let SettingsHomePageUseCopiedLink = MZLocalizedString("Settings.HomePage.UseCopiedLink.Button", value: "Use Copied Link", comment: "Button in settings to use the current link on the clipboard as home page.", lastUpdated: .unknown)
    public static let SettingsHomePageUseDefault = MZLocalizedString("Settings.HomePage.UseDefault.Button", value: "Use Default", comment: "Button in settings to use the default home page. If no default is set, then this button isn't shown.", lastUpdated: .unknown)
    public static let SettingsHomePageClear = MZLocalizedString("Settings.HomePage.Clear.Button", value: "Clear", comment: "Button in settings to clear the home page.", lastUpdated: .unknown)
    public static let SetHomePageDialogTitle = MZLocalizedString("HomePage.Set.Dialog.Title", value: "Do you want to use this web page as your home page?", comment: "Alert dialog title when the user opens the home page for the first time.", lastUpdated: .unknown)
    public static let SetHomePageDialogMessage = MZLocalizedString("HomePage.Set.Dialog.Message", value: "You can change this at any time in Settings", comment: "Alert dialog body when the user opens the home page for the first time.", lastUpdated: .unknown)
    public static let SetHomePageDialogYes = MZLocalizedString("HomePage.Set.Dialog.OK", value: "Set Homepage", comment: "Button accepting changes setting the home page for the first time.", lastUpdated: .unknown)
    public static let SetHomePageDialogNo = MZLocalizedString("HomePage.Set.Dialog.Cancel", value: "Cancel", comment: "Button cancelling changes setting the home page for the first time.", lastUpdated: .unknown)
    public static let ReopenLastTabAlertTitle = MZLocalizedString("ReopenAlert.Title", value: "Reopen Last Closed Tab", comment: "Reopen alert title shown at home page.", lastUpdated: .unknown)
    public static let ReopenLastTabButtonText = MZLocalizedString("ReopenAlert.Actions.Reopen", value: "Reopen", comment: "Reopen button text shown in reopen-alert at home page.", lastUpdated: .unknown)
    public static let ReopenLastTabCancelText = MZLocalizedString("ReopenAlert.Actions.Cancel", value: "Cancel", comment: "Cancel button text shown in reopen-alert at home page.", lastUpdated: .unknown)
}

// MARK: - Settings
extension String {
    public static let SettingsGeneralSectionTitle = MZLocalizedString("Settings.General.SectionName", value: "General", comment: "General settings section title", lastUpdated: .unknown)
    public static let SettingsClearPrivateDataClearButton = MZLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.", lastUpdated: .unknown)
    public static let SettingsClearAllWebsiteDataButton = MZLocalizedString("Settings.ClearAllWebsiteData.Clear.Button", value: "Clear All Website Data", comment: "Button in Data Management that clears all items.", lastUpdated: .unknown)
    public static let SettingsClearSelectedWebsiteDataButton = MZLocalizedString("Settings.ClearSelectedWebsiteData.ClearSelected.Button", value: "Clear Items: %1$@", comment: "Button in Data Management that clears private data for the selected items. Parameter is the number of items to be cleared", lastUpdated: .unknown)
    public static let SettingsClearPrivateDataSectionName = MZLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.", lastUpdated: .unknown)
    public static let SettingsDataManagementSectionName = MZLocalizedString("Settings.DataManagement.SectionName", value: "Data Management", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.", lastUpdated: .unknown)
    public static let SettingsFilterSitesSearchLabel = MZLocalizedString("Settings.DataManagement.SearchLabel", value: "Filter Sites", comment: "Default text in search bar for Data Management", lastUpdated: .unknown)
    public static let SettingsClearPrivateDataTitle = MZLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.", lastUpdated: .unknown)
    public static let SettingsDataManagementTitle = MZLocalizedString("Settings.DataManagement.Title", value: "Data Management", comment: "Title displayed in header of the setting panel.", lastUpdated: .unknown)
    public static let SettingsWebsiteDataTitle = MZLocalizedString("Settings.WebsiteData.Title", value: "Website Data", comment: "Title displayed in header of the Data Management panel.", lastUpdated: .unknown)
    public static let SettingsWebsiteDataShowMoreButton = MZLocalizedString("Settings.WebsiteData.ButtonShowMore", value: "Show More", comment: "Button shows all websites on website data tableview", lastUpdated: .unknown)
    public static let SettingsEditWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonEdit", value: "Edit", comment: "Button to edit website search results", lastUpdated: .unknown)
    public static let SettingsDeleteWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonDelete", value: "Delete", comment: "Button to delete website in search results", lastUpdated: .unknown)
    public static let SettingsDoneWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonDone", value: "Done", comment: "Button to exit edit website search results", lastUpdated: .unknown)
    public static let SettingsDisconnectSyncAlertTitle = MZLocalizedString("Settings.Disconnect.Title", value: "Disconnect Sync?", comment: "Title of the alert when prompting the user asking to disconnect.", lastUpdated: .unknown)
    public static let SettingsDisconnectSyncAlertBody = MZLocalizedString("Settings.Disconnect.Body", value: "Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Body of the alert when prompting the user asking to disconnect.", lastUpdated: .unknown)
    public static let SettingsDisconnectSyncButton = MZLocalizedString("Settings.Disconnect.Button", value: "Disconnect Sync", comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA", lastUpdated: .unknown)
    public static let SettingsDisconnectCancelAction = MZLocalizedString("Settings.Disconnect.CancelButton", value: "Cancel", comment: "Cancel action button in alert when user is prompted for disconnect", lastUpdated: .unknown)
    public static let SettingsDisconnectDestructiveAction = MZLocalizedString("Settings.Disconnect.DestructiveButton", value: "Disconnect", comment: "Destructive action button in alert when user is prompted for disconnect", lastUpdated: .unknown)
    public static let SettingsSearchDoneButton = MZLocalizedString("Settings.Search.Done.Button", value: "Done", comment: "Button displayed at the top of the search settings.", lastUpdated: .unknown)
    public static let SettingsSearchEditButton = MZLocalizedString("Settings.Search.Edit.Button", value: "Edit", comment: "Button displayed at the top of the search settings.", lastUpdated: .unknown)
    public static let UseTouchID = MZLocalizedString("Use Touch ID", tableName: "AuthenticationManager", comment: "List section title for when to use Touch ID", lastUpdated: .unknown)
    public static let UseFaceID = MZLocalizedString("Use Face ID", tableName: "AuthenticationManager", comment: "List section title for when to use Face ID", lastUpdated: .unknown)
    public static let SettingsCopyAppVersionAlertTitle = MZLocalizedString("Settings.CopyAppVersion.Title", value: "Copied to clipboard", comment: "Copy app version alert shown in settings.", lastUpdated: .unknown)
}

// MARK: - Error pages
extension String {
    public static let ErrorPagesAdvancedButton = MZLocalizedString("ErrorPages.Advanced.Button", value: "Advanced", comment: "Label for button to perform advanced actions on the error page", lastUpdated: .unknown)
    public static let ErrorPagesAdvancedWarning1 = MZLocalizedString("ErrorPages.AdvancedWarning1.Text", value: "Warning: we can’t confirm your connection to this website is secure.", comment: "Warning text when clicking the Advanced button on error pages", lastUpdated: .unknown)
    public static let ErrorPagesAdvancedWarning2 = MZLocalizedString("ErrorPages.AdvancedWarning2.Text", value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.", comment: "Additional warning text when clicking the Advanced button on error pages", lastUpdated: .unknown)
    public static let ErrorPagesCertWarningDescription = MZLocalizedString("ErrorPages.CertWarning.Description", value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Firefox has not connected to this website.", comment: "Warning text on the certificate error page", lastUpdated: .unknown)
    public static let ErrorPagesCertWarningTitle = MZLocalizedString("ErrorPages.CertWarning.Title", value: "This Connection is Untrusted", comment: "Title on the certificate error page", lastUpdated: .unknown)
    public static let ErrorPagesGoBackButton = MZLocalizedString("ErrorPages.GoBack.Button", value: "Go Back", comment: "Label for button to go back from the error page", lastUpdated: .unknown)
    public static let ErrorPagesVisitOnceButton = MZLocalizedString("ErrorPages.VisitOnce.Button", value: "Visit site anyway", comment: "Button label to temporarily continue to the site from the certificate error page", lastUpdated: .unknown)
}

// MARK: - Logins Helper
extension String {
    public static let LoginsHelperSaveLoginButtonTitle = MZLocalizedString("LoginsHelper.SaveLogin.Button", value: "Save Login", comment: "Button to save the user's password", lastUpdated: .unknown)
    public static let LoginsHelperDontSaveButtonTitle = MZLocalizedString("LoginsHelper.DontSave.Button", value: "Don’t Save", comment: "Button to not save the user's password", lastUpdated: .unknown)
    public static let LoginsHelperUpdateButtonTitle = MZLocalizedString("LoginsHelper.Update.Button", value: "Update", comment: "Button to update the user's password", lastUpdated: .unknown)
    public static let LoginsHelperDontUpdateButtonTitle = MZLocalizedString("LoginsHelper.DontUpdate.Button", value: "Don’t Update", comment: "Button to not update the user's password", lastUpdated: .unknown)
}

// MARK: - Downloads Panel
extension String {
    public static let DownloadsPanelEmptyStateTitle = MZLocalizedString("DownloadsPanel.EmptyState.Title", value: "Downloaded files will show up here.", comment: "Title for the Downloads Panel empty state.", lastUpdated: .unknown)
    public static let DownloadsPanelDeleteTitle = MZLocalizedString("DownloadsPanel.Delete.Title", value: "Delete", comment: "Action button for deleting downloaded files in the Downloads panel.", lastUpdated: .unknown)
    public static let DownloadsPanelShareTitle = MZLocalizedString("DownloadsPanel.Share.Title", value: "Share", comment: "Action button for sharing downloaded files in the Downloads panel.", lastUpdated: .unknown)
}

// MARK: - History Panel
extension String {
    public static let SyncedTabsTableViewCellTitle = MZLocalizedString("HistoryPanel.SyncedTabsCell.Title", value: "Synced Devices", comment: "Title for the Synced Tabs Cell in the History Panel", lastUpdated: .unknown)
    public static let HistoryBackButtonTitle = MZLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel", lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelStateTitle = MZLocalizedString("HistoryPanel.EmptySyncedTabsState.Title", value: "Firefox Sync", comment: "Title for the empty synced tabs state in the History Panel", lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelNotSignedInStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelNotSignedInState.Description", value: "Sign in to view a list of tabs from your other devices.", comment: "Description for the empty synced tabs 'not signed in' state in the History Panel", lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelNotYetVerifiedStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelNotYetVerifiedState.Description", value: "Your account needs to be verified.", comment: "Description for the empty synced tabs 'not yet verified' state in the History Panel", lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelSingleDeviceSyncStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelSingleDeviceSyncState.Description", value: "Want to see your tabs from other devices here?", comment: "Description for the empty synced tabs 'single device Sync' state in the History Panel", lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelTabSyncDisabledStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelTabSyncDisabledState.Description", value: "Turn on tab syncing to view a list of tabs from your other devices.", comment: "Description for the empty synced tabs 'tab sync disabled' state in the History Panel", lastUpdated: .unknown)
    public static let EmptySyncedTabsPanelNullStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsNullState.Description", value: "Your tabs from other devices show up here.", comment: "Description for the empty synced tabs null state in the History Panel", lastUpdated: .unknown)
    public static let SyncedTabsTableViewCellDescription = MZLocalizedString("HistoryPanel.SyncedTabsCell.Description.Pluralized", value: "%d device(s) connected", comment: "Description that corresponds with a number of devices connected for the Synced Tabs Cell in the History Panel", lastUpdated: .unknown)
    public static let HistoryPanelEmptyStateTitle = MZLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.", lastUpdated: .unknown)
    public static let RecentlyClosedTabsButtonTitle = MZLocalizedString("HistoryPanel.RecentlyClosedTabsButton.Title", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel", lastUpdated: .unknown)
    public static let RecentlyClosedTabsPanelTitle = MZLocalizedString("RecentlyClosedTabsPanel.Title", value: "Recently Closed", comment: "Title for the Recently Closed Tabs Panel", lastUpdated: .unknown)
    public static let HistoryPanelClearHistoryButtonTitle = MZLocalizedString("HistoryPanel.ClearHistoryButtonTitle", value: "Clear Recent History…", comment: "Title for button in the history panel to clear recent history", lastUpdated: .unknown)
    public static let FirefoxHomePage = MZLocalizedString("Firefox.HomePage.Title", value: "Firefox Home Page", comment: "Title for firefox about:home page in tab history list", lastUpdated: .unknown)
    public static let HistoryPanelDelete = MZLocalizedString("Delete", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the history panel.", lastUpdated: .unknown)
}

// MARK: - Clear recent history action menu
extension String {
    public static let ClearHistoryMenuTitle = MZLocalizedString("HistoryPanel.ClearHistoryMenuTitle", value: "Clearing Recent History will remove history, cookies, and other browser data.", comment: "Title for popup action menu to clear recent history.", lastUpdated: .unknown)
    public static let ClearHistoryMenuOptionTheLastHour = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionTheLastHour", value: "The Last Hour", comment: "Button to perform action to clear history for the last hour", lastUpdated: .unknown)
    public static let ClearHistoryMenuOptionToday = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionToday", value: "Today", comment: "Button to perform action to clear history for today only", lastUpdated: .unknown)
    public static let ClearHistoryMenuOptionTodayAndYesterday = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionTodayAndYesterday", value: "Today and Yesterday", comment: "Button to perform action to clear history for yesterday and today", lastUpdated: .unknown)
    public static let ClearHistoryMenuOptionEverything = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionEverything", value: "Everything", comment: "Option title to clear all browsing history.", lastUpdated: .unknown)
}

// MARK: - Syncing
extension String {
    public static let SyncingMessageWithEllipsis = MZLocalizedString("Sync.SyncingEllipsis.Label", value: "Syncing…", comment: "Message displayed when the user's account is syncing with ellipsis at the end", lastUpdated: .unknown)
    public static let SyncingMessageWithoutEllipsis = MZLocalizedString("Sync.Syncing.Label", value: "Syncing", comment: "Message displayed when the user's account is syncing with no ellipsis", lastUpdated: .unknown)

    public static let FirstTimeSyncLongTime = MZLocalizedString("Sync.FirstTimeMessage.Label", value: "Your first sync may take a while", comment: "Message displayed when the user syncs for the first time", lastUpdated: .unknown)

    public static let FirefoxSyncOfflineTitle = MZLocalizedString("SyncState.Offline.Title", value: "Sync is offline", comment: "Title for Sync status message when Sync failed due to being offline", lastUpdated: .unknown)
    public static let FirefoxSyncNotStartedTitle = MZLocalizedString("SyncState.NotStarted.Title", value: "Sync is unavailable", comment: "Title for Sync status message when Sync failed to start.", lastUpdated: .unknown)
    public static let FirefoxSyncPartialTitle = MZLocalizedString("SyncState.Partial.Title", value: "Sync is experiencing issues syncing %@", comment: "Title for Sync status message when a component of Sync failed to complete, where %@ represents the name of the component, i.e. Sync is experiencing issues syncing Bookmarks", lastUpdated: .unknown)
    public static let FirefoxSyncFailedTitle = MZLocalizedString("SyncState.Failed.Title", value: "Syncing has failed", comment: "Title for Sync status message when synchronization failed to complete", lastUpdated: .unknown)
    public static let FirefoxSyncTroubleshootTitle = MZLocalizedString("Settings.TroubleShootSync.Title", value: "Troubleshoot", comment: "Title of link to help page to find out how to solve Sync issues", lastUpdated: .unknown)
    public static let FirefoxSyncCreateAccount = MZLocalizedString("Sync.NoAccount.Description", value: "No account? Create one to sync Firefox between devices.", comment: "String displayed on Sign In to Sync page that allows the user to create a new account.", lastUpdated: .unknown)

    public static let FirefoxSyncBookmarksEngine = MZLocalizedString("Bookmarks", comment: "Toggle bookmarks syncing setting", lastUpdated: .unknown)
    public static let FirefoxSyncHistoryEngine = MZLocalizedString("History", comment: "Toggle history syncing setting", lastUpdated: .unknown)
    public static let FirefoxSyncTabsEngine = MZLocalizedString("Open Tabs", comment: "Toggle tabs syncing setting", lastUpdated: .unknown)
    public static let FirefoxSyncLoginsEngine = MZLocalizedString("Logins", comment: "Toggle logins syncing setting", lastUpdated: .unknown)

    public static func localizedStringForSyncComponent(_ componentName: String) -> String? {
        switch componentName {
        case "bookmarks":
            return MZLocalizedString("SyncState.Bookmark.Title", value: "Bookmarks", comment: "The Bookmark sync component, used in SyncState.Partial.Title", lastUpdated: .unknown)
        case "clients":
            return MZLocalizedString("SyncState.Clients.Title", value: "Remote Clients", comment: "The Remote Clients sync component, used in SyncState.Partial.Title", lastUpdated: .unknown)
        case "tabs":
            return MZLocalizedString("SyncState.Tabs.Title", value: "Tabs", comment: "The Tabs sync component, used in SyncState.Partial.Title", lastUpdated: .unknown)
        case "logins":
            return MZLocalizedString("SyncState.Logins.Title", value: "Logins", comment: "The Logins sync component, used in SyncState.Partial.Title", lastUpdated: .unknown)
        case "history":
            return MZLocalizedString("SyncState.History.Title", value: "History", comment: "The History sync component, used in SyncState.Partial.Title", lastUpdated: .unknown)
        default: return nil
        }
    }
}

// MARK: - Firefox Logins
extension String {
    public static let LoginsAndPasswordsTitle = MZLocalizedString("Settings.LoginsAndPasswordsTitle", value: "Logins & Passwords", comment: "Title for the logins and passwords screen. Translation could just use 'Logins' if the title is too long", lastUpdated: .unknown)

    // Prompts
    public static let SaveLoginUsernamePrompt = MZLocalizedString("LoginsHelper.PromptSaveLogin.Title", value: "Save login %@ for %@?", comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.", lastUpdated: .unknown)
    public static let SaveLoginPrompt = MZLocalizedString("LoginsHelper.PromptSavePassword.Title", value: "Save password for %@?", comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.", lastUpdated: .unknown)
    public static let UpdateLoginUsernamePrompt = MZLocalizedString("LoginsHelper.PromptUpdateLogin.Title.TwoArg", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.", lastUpdated: .unknown)
    public static let UpdateLoginPrompt = MZLocalizedString("LoginsHelper.PromptUpdateLogin.Title.OneArg", value: "Update login for %@?", comment: "Prompt for updating a login. The first parameter is the hostname for which the password will be updated for.", lastUpdated: .unknown)

    // Setting
    public static let SettingToSaveLogins = MZLocalizedString("Settings.SaveLogins.Title", value: "Save Logins", comment: "Setting to enable the built-in password manager", lastUpdated: .unknown)
    public static let SettingToShowLoginsInAppMenu = MZLocalizedString("Settings.ShowLoginsInAppMenu.Title", value: "Show in Application Menu", comment: "Setting to show Logins & Passwords quick access in the application menu", lastUpdated: .unknown)

    // List view
    public static let LoginsListTitle = MZLocalizedString("LoginsList.Title", value: "SAVED LOGINS", comment: "Title for the list of logins", lastUpdated: .unknown)
    public static let LoginsListSearchPlaceholder = MZLocalizedString("LoginsList.LoginsListSearchPlaceholder", value: "Filter", comment: "Placeholder test for search box in logins list view.", lastUpdated: .unknown)
    public static let LoginsFilterWebsite = MZLocalizedString("LoginsList.LoginsListFilterWebsite", value: "Website", comment: "For filtering the login list, search only the website names", lastUpdated: .unknown)
    public static let LoginsFilterLogin = MZLocalizedString("LoginsList.LoginsListFilterLogin", value: "Login", comment: "For filtering the login list, search only the login names", lastUpdated: .unknown)
    public static let LoginsFilterAll = MZLocalizedString("LoginsList.LoginsListFilterSearchAll", value: "All", comment: "For filtering the login list, search both website and login names.", lastUpdated: .unknown)

    // Detail view
    public static let LoginsDetailViewLoginTitle = MZLocalizedString("LoginsDetailView.LoginTitle", value: "Login", comment: "Title for the login detail view", lastUpdated: .unknown)
    public static let LoginsDetailViewLoginModified = MZLocalizedString("LoginsDetailView.LoginModified", value: "Modified", comment: "Login detail view field name for the last modified date", lastUpdated: .unknown)

    // Breach Alerts
    public static let BreachAlertsTitle = MZLocalizedString("BreachAlerts.Title", value: "Website Breach", comment: "Title for the Breached Login Detail View.", lastUpdated: .unknown)
    public static let BreachAlertsLearnMore = MZLocalizedString("BreachAlerts.LearnMoreButton", value: "Learn more", comment: "Link to monitor.firefox.com to learn more about breached passwords", lastUpdated: .unknown)
    public static let BreachAlertsBreachDate = MZLocalizedString("BreachAlerts.BreachDate", value: "This breach occurred on", comment: "Describes the date on which the breach occurred", lastUpdated: .unknown)
    public static let BreachAlertsDescription = MZLocalizedString("BreachAlerts.Description", value: "Passwords were leaked or stolen since you last changed your password. To protect this account, log in to the site and change your password.", comment: "Description of what a breach is", lastUpdated: .unknown)
    public static let BreachAlertsLink = MZLocalizedString("BreachAlerts.Link", value: "Go to", comment: "Leads to a link to the breached website", lastUpdated: .unknown)

    // For the DevicePasscodeRequiredViewController
    public static let LoginsDevicePasscodeRequiredMessage = MZLocalizedString("Logins.DevicePasscodeRequired.Message", value: "To save and autofill logins and passwords, enable Face ID, Touch ID or a device passcode.", comment: "Message shown when you enter Logins & Passwords without having a device passcode set.", lastUpdated: .unknown)
    public static let LoginsDevicePasscodeRequiredLearnMoreButtonTitle = MZLocalizedString("Logins.DevicePasscodeRequired.LearnMoreButtonTitle", value: "Learn More", comment: "Title of the Learn More button that links to a support page about device passcode requirements.", lastUpdated: .unknown)

    // For the LoginOnboardingViewController
    public static let LoginsOnboardingMessage = MZLocalizedString("Logins.Onboarding.Message", value: "Your logins and passwords are now protected by Face ID, Touch ID or a device passcode.", comment: "Message shown when you enter Logins & Passwords for the first time.", lastUpdated: .unknown)
    public static let LoginsOnboardingLearnMoreButtonTitle = MZLocalizedString("Logins.Onboarding.LearnMoreButtonTitle", value: "Learn More", comment: "Title of the Learn More button that links to a support page about device passcode requirements.", lastUpdated: .unknown)
    public static let LoginsOnboardingContinueButtonTitle = MZLocalizedString("Logins.Onboarding.ContinueButtonTitle", value: "Continue", comment: "Title of the Continue button.", lastUpdated: .unknown)
}

// MARK: - Firefox Account
extension String {
    // Settings strings
    public static let FxAFirefoxAccount = MZLocalizedString("FxA.FirefoxAccount", value: "Firefox Account", comment: "Settings section title for Firefox Account", lastUpdated: .unknown)
    public static let FxASignInToSync = MZLocalizedString("FxA.SignIntoSync", value: "Sign in to Sync", comment: "Button label to sign into Sync", lastUpdated: .unknown)
    public static let FxATakeYourWebWithYou = MZLocalizedString("FxA.TakeYourWebWithYou", value: "Take Your Web With You", comment: "Call to action for sign into sync button", lastUpdated: .unknown)
    public static let FxASyncUsageDetails = MZLocalizedString("FxA.SyncExplain", value: "Get your tabs, bookmarks, and passwords from your other devices.", comment: "Label explaining what sync does", lastUpdated: .unknown)
    public static let FxAAccountVerificationRequired = MZLocalizedString("FxA.AccountVerificationRequired", value: "Account Verification Required", comment: "Label stating your account is not verified", lastUpdated: .unknown)
    public static let FxAAccountVerificationDetails = MZLocalizedString("FxA.AccountVerificationDetails", value: "Wrong email? Disconnect below to start over.", comment: "Label stating how to disconnect account", lastUpdated: .unknown)
    public static let FxAManageAccount = MZLocalizedString("FxA.ManageAccount", value: "Manage Account & Devices", comment: "Button label to go to Firefox Account settings", lastUpdated: .unknown)
    public static let FxASyncNow = MZLocalizedString("FxA.SyncNow", value: "Sync Now", comment: "Button label to Sync your Firefox Account", lastUpdated: .unknown)
    public static let FxANoInternetConnection = MZLocalizedString("FxA.NoInternetConnection", value: "No Internet Connection", comment: "Label when no internet is present", lastUpdated: .unknown)
    public static let FxASettingsTitle = MZLocalizedString("Settings.FxA.Title", value: "Firefox Account", comment: "Title displayed in header of the FxA settings panel.", lastUpdated: .unknown)
    public static let FxASettingsSyncSettings = MZLocalizedString("Settings.FxA.Sync.SectionName", value: "Sync Settings", comment: "Label used as a section title in the Firefox Accounts Settings screen.", lastUpdated: .unknown)
    public static let FxASettingsDeviceName = MZLocalizedString("Settings.FxA.DeviceName", value: "Device Name", comment: "Label used for the device name settings section.", lastUpdated: .unknown)
    public static let FxAOpenSyncPreferences = MZLocalizedString("FxA.OpenSyncPreferences", value: "Open Sync Preferences", comment: "Button label to open Sync preferences", lastUpdated: .unknown)
    public static let FxAConnectAnotherDevice = MZLocalizedString("FxA.ConnectAnotherDevice", value: "Connect Another Device", comment: "Button label to connect another device to Sync", lastUpdated: .unknown)
    public static let FxARemoveAccountButton = MZLocalizedString("FxA.RemoveAccount", value: "Remove", comment: "Remove button is displayed on firefox account page under certain scenarios where user would like to remove their account.", lastUpdated: .unknown)
    public static let FxARemoveAccountAlertTitle = MZLocalizedString("FxA.RemoveAccountAlertTitle", value: "Remove Account", comment: "Remove account alert is the final confirmation before user removes their firefox account", lastUpdated: .unknown)
    public static let FxARemoveAccountAlertMessage = MZLocalizedString("FxA.RemoveAccountAlertMessage", value: "Remove the Firefox Account associated with this device to sign in as a different user.", comment: "Description string for alert view that gets presented when user tries to remove an account.", lastUpdated: .unknown)

    // Surface error strings
    public static let FxAAccountVerificationRequiredSurface = MZLocalizedString("FxA.AccountVerificationRequiredSurface", value: "You need to verify %@. Check your email for the verification link from Firefox.", comment: "Message explaining that user needs to check email for Firefox Account verfication link.", lastUpdated: .unknown)
    public static let FxAResendEmail = MZLocalizedString("FxA.ResendEmail", value: "Resend Email", comment: "Button label to resend email", lastUpdated: .unknown)
    public static let FxAAccountVerifyEmail = MZLocalizedString("Verify your email address", comment: "Text message in the settings table view", lastUpdated: .unknown)
    public static let FxAAccountVerifyPassword = MZLocalizedString("Enter your password to connect", comment: "Text message in the settings table view", lastUpdated: .unknown)
    public static let FxAAccountUpgradeFirefox = MZLocalizedString("Upgrade Firefox to connect", comment: "Text message in the settings table view", lastUpdated: .unknown)
}

// MARK: - New tab choice settings
extension String {
    public static let CustomNewPageURL = MZLocalizedString("Settings.NewTab.CustomURL", value: "Custom URL", comment: "Label used to set a custom url as the new tab option (homepage).", lastUpdated: .unknown)
    public static let SettingsNewTabSectionName = MZLocalizedString("Settings.NewTab.SectionName", value: "New Tab", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behavior.", lastUpdated: .unknown)
    public static let NewTabSectionName =
        MZLocalizedString("Settings.NewTab.TopSectionName", value: "Show", comment: "Label at the top of the New Tab screen after entering New Tab in settings", lastUpdated: .unknown)
    public static let SettingsNewTabTitle = MZLocalizedString("Settings.NewTab.Title", value: "New Tab", comment: "Title displayed in header of the setting panel.", lastUpdated: .unknown)
    public static let NewTabSectionNameFooter =
        MZLocalizedString("Settings.NewTab.TopSectionNameFooter", value: "Choose what to load when opening a new tab", comment: "Footer at the bottom of the New Tab screen after entering New Tab in settings", lastUpdated: .unknown)
    public static let SettingsNewTabTopSites = MZLocalizedString("Settings.NewTab.Option.FirefoxHome", value: "Firefox Home", comment: "Option in settings to show Firefox Home when you open a new tab", lastUpdated: .unknown)
    public static let SettingsNewTabBookmarks = MZLocalizedString("Settings.NewTab.Option.Bookmarks", value: "Bookmarks", comment: "Option in settings to show bookmarks when you open a new tab", lastUpdated: .unknown)
    public static let SettingsNewTabHistory = MZLocalizedString("Settings.NewTab.Option.History", value: "History", comment: "Option in settings to show history when you open a new tab", lastUpdated: .unknown)
    public static let SettingsNewTabReadingList = MZLocalizedString("Settings.NewTab.Option.ReadingList", value: "Show your Reading List", comment: "Option in settings to show reading list when you open a new tab", lastUpdated: .unknown)
    public static let SettingsNewTabBlankPage = MZLocalizedString("Settings.NewTab.Option.BlankPage", value: "Blank Page", comment: "Option in settings to show a blank page when you open a new tab", lastUpdated: .unknown)
    public static let SettingsNewTabHomePage = MZLocalizedString("Settings.NewTab.Option.HomePage", value: "Homepage", comment: "Option in settings to show your homepage when you open a new tab", lastUpdated: .unknown)
    public static let SettingsNewTabDescription = MZLocalizedString("Settings.NewTab.Description", value: "When you open a New Tab:", comment: "A description in settings of what the new tab choice means", lastUpdated: .unknown)
    // AS Panel settings
    public static let SettingsNewTabASTitle = MZLocalizedString("Settings.NewTab.Option.ASTitle", value: "Customize Top Sites", comment: "The title of the section in newtab that lets you modify the topsites panel", lastUpdated: .unknown)
    public static let SettingsNewTabPocket = MZLocalizedString("Settings.NewTab.Option.Pocket", value: "Trending on Pocket", comment: "Option in settings to turn on off pocket recommendations", lastUpdated: .unknown)
    public static let SettingsNewTabRecommendedByPocket = MZLocalizedString("Settings.NewTab.Option.RecommendedByPocket", value: "Recommended by %@", comment: "Option in settings to turn on off pocket recommendations First argument is the pocket brand name", lastUpdated: .unknown)
    public static let SettingsNewTabRecommendedByPocketDescription = MZLocalizedString("Settings.NewTab.Option.RecommendedByPocketDescription", value: "Exceptional content curated by %@, part of the %@ family", comment: "Descriptoin for the option in settings to turn on off pocket recommendations. First argument is the pocket brand name, second argument is the pocket product name.", lastUpdated: .unknown)
    public static let SettingsNewTabPocketFooter = MZLocalizedString("Settings.NewTab.Option.PocketFooter", value: "Great content from around the web.", comment: "Footer caption for pocket settings", lastUpdated: .unknown)
    public static let SettingsNewTabHiglightsHistory = MZLocalizedString("Settings.NewTab.Option.HighlightsHistory", value: "Visited", comment: "Option in settings to turn off history in the highlights section", lastUpdated: .unknown)
    public static let SettingsNewTabHighlightsBookmarks = MZLocalizedString("Settings.NewTab.Option.HighlightsBookmarks", value: "Recent Bookmarks", comment: "Option in the settings to turn off recent bookmarks in the Highlights section", lastUpdated: .unknown)
    public static let SettingsTopSitesCustomizeTitle = MZLocalizedString("Settings.NewTab.Option.CustomizeTitle", value: "Customize Firefox Home", comment: "The title for the section to customize top sites in the new tab settings page.", lastUpdated: .unknown)
    public static let SettingsTopSitesCustomizeFooter = MZLocalizedString("Settings.NewTab.Option.CustomizeFooter", value: "The sites you visit most", comment: "The footer for the section to customize top sites in the new tab settings page.", lastUpdated: .unknown)
    public static let SettingsTopSitesCustomizeFooter2 = MZLocalizedString("Settings.NewTab.Option.CustomizeFooter2", value: "Sites you save or visit", comment: "The footer for the section to customize top sites in the new tab settings page.", lastUpdated: .unknown)
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
    public static let SettingsOpenWithSectionName = MZLocalizedString("Settings.OpenWith.SectionName", value: "Mail App", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behavior.", lastUpdated: .unknown)
    public static let SettingsOpenWithPageTitle = MZLocalizedString("Settings.OpenWith.PageTitle", value: "Open mail links with", comment: "Title for Open With Settings", lastUpdated: .unknown)
}

// MARK: - Third Party Search Engines
extension String {
    public static let ThirdPartySearchEngineAdded = MZLocalizedString("Search.ThirdPartyEngines.AddSuccess", value: "Added Search engine!", comment: "The success message that appears after a user sucessfully adds a new search engine", lastUpdated: .unknown)
    public static let ThirdPartySearchAddTitle = MZLocalizedString("Search.ThirdPartyEngines.AddTitle", value: "Add Search Provider?", comment: "The title that asks the user to Add the search provider", lastUpdated: .unknown)
    public static let ThirdPartySearchAddMessage = MZLocalizedString("Search.ThirdPartyEngines.AddMessage", value: "The new search engine will appear in the quick search bar.", comment: "The message that asks the user to Add the search provider explaining where the search engine will appear", lastUpdated: .unknown)
    public static let ThirdPartySearchCancelButton = MZLocalizedString("Search.ThirdPartyEngines.Cancel", value: "Cancel", comment: "The cancel button if you do not want to add a search engine.", lastUpdated: .unknown)
    public static let ThirdPartySearchOkayButton = MZLocalizedString("Search.ThirdPartyEngines.OK", value: "OK", comment: "The confirmation button", lastUpdated: .unknown)
    public static let ThirdPartySearchFailedTitle = MZLocalizedString("Search.ThirdPartyEngines.FailedTitle", value: "Failed", comment: "A title explaining that we failed to add a search engine", lastUpdated: .unknown)
    public static let ThirdPartySearchFailedMessage = MZLocalizedString("Search.ThirdPartyEngines.FailedMessage", value: "The search provider could not be added.", comment: "A title explaining that we failed to add a search engine", lastUpdated: .unknown)
    public static let CustomEngineFormErrorTitle = MZLocalizedString("Search.ThirdPartyEngines.FormErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.", lastUpdated: .unknown)
    public static let CustomEngineFormErrorMessage = MZLocalizedString("Search.ThirdPartyEngines.FormErrorMessage", value: "Please fill all fields correctly.", comment: "A message explaining fault in custom search engine form.", lastUpdated: .unknown)
    public static let CustomEngineDuplicateErrorTitle = MZLocalizedString("Search.ThirdPartyEngines.DuplicateErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.", lastUpdated: .unknown)
    public static let CustomEngineDuplicateErrorMessage = MZLocalizedString("Search.ThirdPartyEngines.DuplicateErrorMessage", value: "A search engine with this title or URL has already been added.", comment: "A message explaining fault in custom search engine form.", lastUpdated: .unknown)
}

// MARK: - Root Bookmarks folders
extension String {
    public static let BookmarksFolderTitleMobile = MZLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.", lastUpdated: .unknown)
    public static let BookmarksFolderTitleMenu = MZLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.", lastUpdated: .unknown)
    public static let BookmarksFolderTitleToolbar = MZLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.", lastUpdated: .unknown)
    public static let BookmarksFolderTitleUnsorted = MZLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.", lastUpdated: .unknown)
}

// MARK: - Bookmark Management
extension String {
    public static let BookmarksTitle = MZLocalizedString("Bookmarks.Title.Label", value: "Title", comment: "The label for the title of a bookmark", lastUpdated: .unknown)
    public static let BookmarksURL = MZLocalizedString("Bookmarks.URL.Label", value: "URL", comment: "The label for the URL of a bookmark", lastUpdated: .unknown)
    public static let BookmarksFolder = MZLocalizedString("Bookmarks.Folder.Label", value: "Folder", comment: "The label to show the location of the folder where the bookmark is located", lastUpdated: .unknown)
    public static let BookmarksNewBookmark = MZLocalizedString("Bookmarks.NewBookmark.Label", value: "New Bookmark", comment: "The button to create a new bookmark", lastUpdated: .unknown)
    public static let BookmarksNewFolder = MZLocalizedString("Bookmarks.NewFolder.Label", value: "New Folder", comment: "The button to create a new folder", lastUpdated: .unknown)
    public static let BookmarksNewSeparator = MZLocalizedString("Bookmarks.NewSeparator.Label", value: "New Separator", comment: "The button to create a new separator", lastUpdated: .unknown)
    public static let BookmarksEditBookmark = MZLocalizedString("Bookmarks.EditBookmark.Label", value: "Edit Bookmark", comment: "The button to edit a bookmark", lastUpdated: .unknown)
    public static let BookmarksEdit = MZLocalizedString("Bookmarks.Edit.Button", value: "Edit", comment: "The button on the snackbar to edit a bookmark after adding it.", lastUpdated: .unknown)
    public static let BookmarksEditFolder = MZLocalizedString("Bookmarks.EditFolder.Label", value: "Edit Folder", comment: "The button to edit a folder", lastUpdated: .unknown)
    public static let BookmarksFolderName = MZLocalizedString("Bookmarks.FolderName.Label", value: "Folder Name", comment: "The label for the title of the new folder", lastUpdated: .unknown)
    public static let BookmarksFolderLocation = MZLocalizedString("Bookmarks.FolderLocation.Label", value: "Location", comment: "The label for the location of the new folder", lastUpdated: .unknown)
    public static let BookmarksDeleteFolderWarningTitle = MZLocalizedString("Bookmarks.DeleteFolderWarning.Title", tableName: "BookmarkPanelDeleteConfirm", value: "This folder isn’t empty.", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.", lastUpdated: .unknown)
    public static let BookmarksDeleteFolderWarningDescription = MZLocalizedString("Bookmarks.DeleteFolderWarning.Description", tableName: "BookmarkPanelDeleteConfirm", value: "Are you sure you want to delete it and its contents?", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.", lastUpdated: .unknown)
    public static let BookmarksDeleteFolderCancelButtonLabel = MZLocalizedString("Bookmarks.DeleteFolderWarning.CancelButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Cancel", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.", lastUpdated: .unknown)
    public static let BookmarksDeleteFolderDeleteButtonLabel = MZLocalizedString("Bookmarks.DeleteFolderWarning.DeleteButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Delete", comment: "Button label for the button that deletes a folder and all of its children.", lastUpdated: .unknown)
    public static let BookmarksPanelEmptyStateTitle = MZLocalizedString("BookmarksPanel.EmptyState.Title", value: "Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.", lastUpdated: .unknown)
    public static let BookmarksPanelDeleteTableAction = MZLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.", lastUpdated: .unknown)
    public static let BookmarkDetailFieldTitle = MZLocalizedString("Bookmark.DetailFieldTitle.Label", value: "Title", comment: "The label for the Title field when editing a bookmark", lastUpdated: .unknown)
    public static let BookmarkDetailFieldURL = MZLocalizedString("Bookmark.DetailFieldURL.Label", value: "URL", comment: "The label for the URL field when editing a bookmark", lastUpdated: .unknown)
    public static let BookmarkDetailFieldsHeaderBookmarkTitle = MZLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Bookmark.Title", value: "Bookmark", comment: "The header title for the fields when editing a Bookmark", lastUpdated: .unknown)
    public static let BookmarkDetailFieldsHeaderFolderTitle = MZLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Folder.Title", value: "Folder", comment: "The header title for the fields when editing a Folder", lastUpdated: .unknown)
}

// MARK: - Tabs Delete All Undo Toast
extension String {
    public static let TabsDeleteAllUndoTitle = MZLocalizedString("Tabs.DeleteAllUndo.Title", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed", lastUpdated: .unknown)
    public static let TabsDeleteAllUndoAction = MZLocalizedString("Tabs.DeleteAllUndo.Button", value: "Undo", comment: "The button to undo the delete all tabs", lastUpdated: .unknown)
    public static let TabSearchPlaceholderText = MZLocalizedString("Tabs.Search.PlaceholderText", value: "Search Tabs", comment: "The placeholder text for the tab search bar", lastUpdated: .unknown)
}

// MARK: - Tab tray (chronological tabs)
extension String {
    public static let TabTrayV2Title = MZLocalizedString("TabTray.Title", value: "Open Tabs", comment: "The title for the tab tray", lastUpdated: .unknown)
    public static let TabTrayV2TodayHeader = MZLocalizedString("TabTray.Today.Header", value: "Today", comment: "The section header for tabs opened today", lastUpdated: .unknown)
    public static let TabTrayV2YesterdayHeader = MZLocalizedString("TabTray.Yesterday.Header", value: "Yesterday", comment: "The section header for tabs opened yesterday", lastUpdated: .unknown)
    public static let TabTrayV2LastWeekHeader = MZLocalizedString("TabTray.LastWeek.Header", value: "Last Week", comment: "The section header for tabs opened last week", lastUpdated: .unknown)
    public static let TabTrayV2OlderHeader = MZLocalizedString("TabTray.Older.Header", value: "Older", comment: "The section header for tabs opened before last week", lastUpdated: .unknown)
    public static let TabTraySwipeMenuMore = MZLocalizedString("TabTray.SwipeMenu.More", value: "More", comment: "The button title to see more options to perform on the tab.", lastUpdated: .unknown)
    public static let TabTrayMoreMenuCopy = MZLocalizedString("TabTray.MoreMenu.Copy", value: "Copy", comment: "The title on the button to copy the tab address.", lastUpdated: .unknown)
    public static let TabTrayV2PrivateTitle = MZLocalizedString("TabTray.PrivateTitle", value: "Private Tabs", comment: "The title for the tab tray in private mode", lastUpdated: .unknown)

    // Segmented Control tites for iPad
    public static let TabTraySegmentedControlTitlesTabs = MZLocalizedString("TabTray.SegmentedControlTitles.Tabs", value: "Tabs", comment: "The title on the button to look at regular tabs.", lastUpdated: .unknown)
    public static let TabTraySegmentedControlTitlesPrivateTabs = MZLocalizedString("TabTray.SegmentedControlTitles.PrivateTabs", value: "Private", comment: "The title on the button to look at private tabs.", lastUpdated: .unknown)
    public static let TabTraySegmentedControlTitlesSyncedTabs = MZLocalizedString("TabTray.SegmentedControlTitles.SyncedTabs", value: "Synced", comment: "The title on the button to look at synced tabs.", lastUpdated: .unknown)
}

// MARK: - Clipboard Toast
extension String {
    public static let GoToCopiedLink = MZLocalizedString("ClipboardToast.GoToCopiedLink.Title", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard", lastUpdated: .unknown)
    public static let GoButtonTittle = MZLocalizedString("ClipboardToast.GoToCopiedLink.Button", value: "Go", comment: "The button to open a new tab with the copied link", lastUpdated: .unknown)

    public static let SettingsOfferClipboardBarTitle = MZLocalizedString("Settings.OfferClipboardBar.Title", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349", lastUpdated: .unknown)
    public static let SettingsOfferClipboardBarStatus = MZLocalizedString("Settings.OfferClipboardBar.Status", value: "When Opening Firefox", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349", lastUpdated: .unknown)
}

// MARK: - Link Previews
extension String {
    public static let SettingsShowLinkPreviewsTitle = MZLocalizedString("Settings.ShowLinkPreviews.Title", value: "Show Link Previews", comment: "Title of setting to enable link previews when long-pressing links.", lastUpdated: .unknown)
    public static let SettingsShowLinkPreviewsStatus = MZLocalizedString("Settings.ShowLinkPreviews.Status", value: "When Long-pressing Links", comment: "Description displayed under the ”Show Link Previews” option", lastUpdated: .unknown)
}

// MARK: - Errors
extension String {
    public static let UnableToDownloadError = MZLocalizedString("Downloads.Error.Message", value: "Downloads aren’t supported in Firefox yet.", comment: "The message displayed to a user when they try and perform the download of an asset that Firefox cannot currently handle.", lastUpdated: .unknown)
    public static let UnableToAddPassErrorTitle = MZLocalizedString("AddPass.Error.Title", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.", lastUpdated: .unknown)
    public static let UnableToAddPassErrorMessage = MZLocalizedString("AddPass.Error.Message", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.", lastUpdated: .unknown)
    public static let UnableToAddPassErrorDismiss = MZLocalizedString("AddPass.Error.Dismiss", value: "OK", comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.", lastUpdated: .unknown)
    public static let UnableToOpenURLError = MZLocalizedString("OpenURL.Error.Message", value: "Firefox cannot open the page because it has an invalid address.", comment: "The message displayed to a user when they try to open a URL that cannot be handled by Firefox, or any external app.", lastUpdated: .unknown)
    public static let UnableToOpenURLErrorTitle = MZLocalizedString("OpenURL.Error.Title", value: "Cannot Open Page", comment: "Title of the message shown when the user attempts to navigate to an invalid link.", lastUpdated: .unknown)
}

// MARK: - Download Helper
extension String {
    public static let OpenInDownloadHelperAlertDownloadNow = MZLocalizedString("Downloads.Alert.DownloadNow", value: "Download Now", comment: "The label of the button the user will press to start downloading a file", lastUpdated: .unknown)
    public static let DownloadsButtonTitle = MZLocalizedString("Downloads.Toast.GoToDownloads.Button", value: "Downloads", comment: "The button to open a new tab with the Downloads home panel", lastUpdated: .unknown)
    public static let CancelDownloadDialogTitle = MZLocalizedString("Downloads.CancelDialog.Title", value: "Cancel Download", comment: "Alert dialog title when the user taps the cancel download icon.", lastUpdated: .unknown)
    public static let CancelDownloadDialogMessage = MZLocalizedString("Downloads.CancelDialog.Message", value: "Are you sure you want to cancel this download?", comment: "Alert dialog body when the user taps the cancel download icon.", lastUpdated: .unknown)
    public static let CancelDownloadDialogResume = MZLocalizedString("Downloads.CancelDialog.Resume", value: "Resume", comment: "Button declining the cancellation of the download.", lastUpdated: .unknown)
    public static let CancelDownloadDialogCancel = MZLocalizedString("Downloads.CancelDialog.Cancel", value: "Cancel", comment: "Button confirming the cancellation of the download.", lastUpdated: .unknown)
    public static let DownloadCancelledToastLabelText = MZLocalizedString("Downloads.Toast.Cancelled.LabelText", value: "Download Cancelled", comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.", lastUpdated: .unknown)
    public static let DownloadFailedToastLabelText = MZLocalizedString("Downloads.Toast.Failed.LabelText", value: "Download Failed", comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.", lastUpdated: .unknown)
    public static let DownloadFailedToastButtonTitled = MZLocalizedString("Downloads.Toast.Failed.RetryButton", value: "Retry", comment: "The button to retry a failed download from the Download Failed toast.", lastUpdated: .unknown)
    public static let DownloadMultipleFilesToastDescriptionText = MZLocalizedString("Downloads.Toast.MultipleFiles.DescriptionText", value: "1 of %d files", comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.", lastUpdated: .unknown)
    public static let DownloadProgressToastDescriptionText = MZLocalizedString("Downloads.Toast.Progress.DescriptionText", value: "%1$@/%2$@", comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).", lastUpdated: .unknown)
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = MZLocalizedString("Downloads.Toast.MultipleFilesAndProgress.DescriptionText", value: "%1$@ %2$@", comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.", lastUpdated: .unknown)
}

// MARK: - Add Custom Search Engine
extension String {
    public static let SettingsAddCustomEngine = MZLocalizedString("Settings.AddCustomEngine", value: "Add Search Engine", comment: "The button text in Search Settings that opens the Custom Search Engine view.", lastUpdated: .unknown)
    public static let SettingsAddCustomEngineTitle = MZLocalizedString("Settings.AddCustomEngine.Title", value: "Add Search Engine", comment: "The title of the  Custom Search Engine view.", lastUpdated: .unknown)
    public static let SettingsAddCustomEngineTitleLabel = MZLocalizedString("Settings.AddCustomEngine.TitleLabel", value: "Title", comment: "The title for the field which sets the title for a custom search engine.", lastUpdated: .unknown)
    public static let SettingsAddCustomEngineURLLabel = MZLocalizedString("Settings.AddCustomEngine.URLLabel", value: "URL", comment: "The title for URL Field", lastUpdated: .unknown)
    public static let SettingsAddCustomEngineTitlePlaceholder = MZLocalizedString("Settings.AddCustomEngine.TitlePlaceholder", value: "Search Engine", comment: "The placeholder for Title Field when saving a custom search engine.", lastUpdated: .unknown)
    public static let SettingsAddCustomEngineURLPlaceholder = MZLocalizedString("Settings.AddCustomEngine.URLPlaceholder", value: "URL (Replace Query with %s)", comment: "The placeholder for URL Field when saving a custom search engine", lastUpdated: .unknown)
    public static let SettingsAddCustomEngineSaveButtonText = MZLocalizedString("Settings.AddCustomEngine.SaveButtonText", value: "Save", comment: "The text on the Save button when saving a custom search engine", lastUpdated: .unknown)
}

// MARK: - Context menu ButtonToast instances.
extension String {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = MZLocalizedString("ContextMenu.ButtonToast.NewTabOpened.LabelText", value: "New Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Tab.", lastUpdated: .unknown)
    public static let ContextMenuButtonToastNewTabOpenedButtonText = MZLocalizedString("ContextMenu.ButtonToast.NewTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Tab.", lastUpdated: .unknown)
    public static let ContextMenuButtonToastNewPrivateTabOpenedLabelText = MZLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.LabelText", value: "New Private Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Private Tab.", lastUpdated: .unknown)
    public static let ContextMenuButtonToastNewPrivateTabOpenedButtonText = MZLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Private Tab.", lastUpdated: .unknown)
}

// MARK: - Page context menu items (i.e. links and images).
extension String {
    public static let ContextMenuOpenInNewTab = MZLocalizedString("ContextMenu.OpenInNewTabButtonTitle", value: "Open in New Tab", comment: "Context menu item for opening a link in a new tab", lastUpdated: .unknown)
    public static let ContextMenuOpenInNewPrivateTab = MZLocalizedString("ContextMenu.OpenInNewPrivateTabButtonTitle", tableName: "PrivateBrowsing", value: "Open in New Private Tab", comment: "Context menu option for opening a link in a new private tab", lastUpdated: .unknown)

    public static let ContextMenuOpenLinkInNewTab = MZLocalizedString("ContextMenu.OpenLinkInNewTabButtonTitle", value: "Open Link in New Tab", comment: "Context menu item for opening a link in a new tab", lastUpdated: .unknown)
    public static let ContextMenuOpenLinkInNewPrivateTab = MZLocalizedString("ContextMenu.OpenLinkInNewPrivateTabButtonTitle", value: "Open Link in New Private Tab", comment: "Context menu item for opening a link in a new private tab", lastUpdated: .unknown)

    public static let ContextMenuBookmarkLink = MZLocalizedString("ContextMenu.BookmarkLinkButtonTitle", value: "Bookmark Link", comment: "Context menu item for bookmarking a link URL", lastUpdated: .unknown)
    public static let ContextMenuDownloadLink = MZLocalizedString("ContextMenu.DownloadLinkButtonTitle", value: "Download Link", comment: "Context menu item for downloading a link URL", lastUpdated: .unknown)
    public static let ContextMenuCopyLink = MZLocalizedString("ContextMenu.CopyLinkButtonTitle", value: "Copy Link", comment: "Context menu item for copying a link URL to the clipboard", lastUpdated: .unknown)
    public static let ContextMenuShareLink = MZLocalizedString("ContextMenu.ShareLinkButtonTitle", value: "Share Link", comment: "Context menu item for sharing a link URL", lastUpdated: .unknown)
    public static let ContextMenuSaveImage = MZLocalizedString("ContextMenu.SaveImageButtonTitle", value: "Save Image", comment: "Context menu item for saving an image", lastUpdated: .unknown)
    public static let ContextMenuCopyImage = MZLocalizedString("ContextMenu.CopyImageButtonTitle", value: "Copy Image", comment: "Context menu item for copying an image to the clipboard", lastUpdated: .unknown)
    public static let ContextMenuCopyImageLink = MZLocalizedString("ContextMenu.CopyImageLinkButtonTitle", value: "Copy Image Link", comment: "Context menu item for copying an image URL to the clipboard", lastUpdated: .unknown)
}

// MARK: - Photo Library access
extension String {
    public static let PhotoLibraryFirefoxWouldLikeAccessTitle = MZLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessTitle", value: "Firefox would like to access your Photos", comment: "See http://mzl.la/1G7uHo7", lastUpdated: .unknown)
    public static let PhotoLibraryFirefoxWouldLikeAccessMessage = MZLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessMessage", value: "This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7", lastUpdated: .unknown)
}

// MARK: - Sent tabs notifications
// These are displayed when the app is backgrounded or the device is locked.
extension String {
    // zero tabs
    public static let SentTab_NoTabArrivingNotification_title = MZLocalizedString("SentTab.NoTabArrivingNotification.title", value: "Firefox Sync", comment: "Title of notification received after a spurious message from FxA has been received.", lastUpdated: .unknown)
    public static let SentTab_NoTabArrivingNotification_body =
        MZLocalizedString("SentTab.NoTabArrivingNotification.body", value: "Tap to begin", comment: "Body of notification received after a spurious message from FxA has been received.", lastUpdated: .unknown)

    // one or more tabs
    public static let SentTab_TabArrivingNotification_NoDevice_title = MZLocalizedString("SentTab_TabArrivingNotification_NoDevice_title", value: "Tab received", comment: "Title of notification shown when the device is sent one or more tabs from an unnamed device.", lastUpdated: .unknown)
    public static let SentTab_TabArrivingNotification_NoDevice_body = MZLocalizedString("SentTab_TabArrivingNotification_NoDevice_body", value: "New tab arrived from another device.", comment: "Body of notification shown when the device is sent one or more tabs from an unnamed device.", lastUpdated: .unknown)
    public static let SentTab_TabArrivingNotification_WithDevice_title = MZLocalizedString("SentTab_TabArrivingNotification_WithDevice_title", value: "Tab received from %@", comment: "Title of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the device name. This device name will be localized by that device.", lastUpdated: .unknown)
    public static let SentTab_TabArrivingNotification_WithDevice_body = MZLocalizedString("SentTab_TabArrivingNotification_WithDevice_body", value: "New tab arrived in %@", comment: "Body of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the app name.", lastUpdated: .unknown)

    // Notification Actions
    public static let SentTabViewActionTitle = MZLocalizedString("SentTab.ViewAction.title", value: "View", comment: "Label for an action used to view one or more tabs from a notification.", lastUpdated: .unknown)
    public static let SentTabBookmarkActionTitle = MZLocalizedString("SentTab.BookmarkAction.title", value: "Bookmark", comment: "Label for an action used to bookmark one or more tabs from a notification.", lastUpdated: .unknown)
    public static let SentTabAddToReadingListActionTitle = MZLocalizedString("SentTab.AddToReadingListAction.Title", value: "Add to Reading List", comment: "Label for an action used to add one or more tabs recieved from a notification to the reading list.", lastUpdated: .unknown)
}

// MARK: - Additional messages sent via Push from FxA
extension String {
    public static let FxAPush_DeviceDisconnected_ThisDevice_title = MZLocalizedString("FxAPush_DeviceDisconnected_ThisDevice_title", value: "Sync Disconnected", comment: "Title of a notification displayed when this device has been disconnected by another device.", lastUpdated: .unknown)
    public static let FxAPush_DeviceDisconnected_ThisDevice_body = MZLocalizedString("FxAPush_DeviceDisconnected_ThisDevice_body", value: "This device has been successfully disconnected from Firefox Sync.", comment: "Body of a notification displayed when this device has been disconnected from FxA by another device.", lastUpdated: .unknown)
    public static let FxAPush_DeviceDisconnected_title = MZLocalizedString("FxAPush_DeviceDisconnected_title", value: "Sync Disconnected", comment: "Title of a notification displayed when named device has been disconnected from FxA.", lastUpdated: .unknown)
    public static let FxAPush_DeviceDisconnected_body = MZLocalizedString("FxAPush_DeviceDisconnected_body", value: "%@ has been successfully disconnected.", comment: "Body of a notification displayed when named device has been disconnected from FxA. %@ refers to the name of the disconnected device.", lastUpdated: .unknown)

    public static let FxAPush_DeviceDisconnected_UnknownDevice_body = MZLocalizedString("FxAPush_DeviceDisconnected_UnknownDevice_body", value: "A device has disconnected from Firefox Sync", comment: "Body of a notification displayed when unnamed device has been disconnected from FxA.", lastUpdated: .unknown)

    public static let FxAPush_DeviceConnected_title = MZLocalizedString("FxAPush_DeviceConnected_title", value: "Sync Connected", comment: "Title of a notification displayed when another device has connected to FxA.", lastUpdated: .unknown)
    public static let FxAPush_DeviceConnected_body = MZLocalizedString("FxAPush_DeviceConnected_body", value: "Firefox Sync has connected to %@", comment: "Title of a notification displayed when another device has connected to FxA. %@ refers to the name of the newly connected device.", lastUpdated: .unknown)
}

// MARK: - Reader Mode
extension String {
    public static let ReaderModeAvailableVoiceOverAnnouncement = MZLocalizedString("ReaderMode.Available.VoiceOverAnnouncement", value: "Reader Mode available", comment: "Accessibility message e.g. spoken by VoiceOver when Reader Mode becomes available.", lastUpdated: .unknown)
    public static let ReaderModeResetFontSizeAccessibilityLabel = MZLocalizedString("Reset text size", comment: "Accessibility label for button resetting font size in display settings of reader mode", lastUpdated: .unknown)
}

// MARK: - QR Code scanner
extension String {
    public static let ScanQRCodeViewTitle = MZLocalizedString("ScanQRCode.View.Title", value: "Scan QR Code", comment: "Title for the QR code scanner view.", lastUpdated: .unknown)
    public static let ScanQRCodeInstructionsLabel = MZLocalizedString("ScanQRCode.Instructions.Label", value: "Align QR code within frame to scan", comment: "Text for the instructions label, displayed in the QR scanner view", lastUpdated: .unknown)
    public static let ScanQRCodeInvalidDataErrorMessage = MZLocalizedString("ScanQRCode.InvalidDataError.Message", value: "The data is invalid", comment: "Text of the prompt that is shown to the user when the data is invalid", lastUpdated: .unknown)
    public static let ScanQRCodePermissionErrorMessage = MZLocalizedString("ScanQRCode.PermissionError.Message", value: "Please allow Firefox to access your device’s camera in ‘Settings’ -> ‘Privacy’ -> ‘Camera’.", comment: "Text of the prompt user to setup the camera authorization.", lastUpdated: .unknown)
    public static let ScanQRCodeErrorOKButton = MZLocalizedString("ScanQRCode.Error.OK.Button", value: "OK", comment: "OK button to dismiss the error prompt.", lastUpdated: .unknown)
}

// MARK: - App menu
extension String {
    public static let AppMenuReportSiteIssueTitleString = MZLocalizedString("Menu.ReportSiteIssueAction.Title", tableName: "Menu", value: "Report Site Issue", comment: "Label for the button, displayed in the menu, used to report a compatibility issue with the current page.", lastUpdated: .unknown)
    public static let AppMenuLibraryReloadString = MZLocalizedString("Menu.Library.Reload", tableName: "Menu", value: "Reload", comment: "Label for the button, displayed in the menu, used to Reload the webpage", lastUpdated: .unknown)
    public static let StopReloadPageTitle = MZLocalizedString("Menu.Library.StopReload", value: "Stop", comment: "Label for the button displayed in the menu used to stop the reload of the webpage", lastUpdated: .unknown)
    public static let AppMenuLibraryTitleString = MZLocalizedString("Menu.Library.Title", tableName: "Menu", value: "Your Library", comment: "Label for the button, displayed in the menu, used to open the Library", lastUpdated: .unknown)
    public static let AppMenuRecentlySavedTitle = MZLocalizedString("Menu.RecentlySaved.Title", tableName: "Menu", value: "Recently Saved", comment: "A string used to signify the start of the Recently Saved section in Home Screen.", lastUpdated: .unknown)
    public static let AppMenuAddToReadingListTitleString = MZLocalizedString("Menu.AddToReadingList.Title", tableName: "Menu", value: "Add to Reading List", comment: "Label for the button, displayed in the menu, used to add a page to the reading list.", lastUpdated: .unknown)
    public static let AppMenuShowTabsTitleString = MZLocalizedString("Menu.ShowTabs.Title", tableName: "Menu", value: "Show Tabs", comment: "Label for the button, displayed in the menu, used to open the tabs tray", lastUpdated: .unknown)
    public static let AppMenuSharePageTitleString = MZLocalizedString("Menu.SharePageAction.Title", tableName: "Menu", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.", lastUpdated: .unknown)
    public static let AppMenuCopyURLTitleString = MZLocalizedString("Menu.CopyAddress.Title", tableName: "Menu", value: "Copy Address", comment: "Label for the button, displayed in the menu, used to copy the page url to the clipboard.", lastUpdated: .unknown)
    public static let AppMenuCopyLinkTitleString = MZLocalizedString("Menu.CopyLink.Title", tableName: "Menu", value: "Copy Link", comment: "Label for the button, displayed in the menu, used to copy the current page link to the clipboard.", lastUpdated: .unknown)
    public static let AppMenuNewTabTitleString = MZLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab", lastUpdated: .unknown)
    public static let AppMenuNewPrivateTabTitleString = MZLocalizedString("Menu.NewPrivateTabAction.Title", tableName: "Menu", value: "Open New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.", lastUpdated: .unknown)
    public static let AppMenuAddBookmarkTitleString = MZLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.", lastUpdated: .unknown)
    public static let AppMenuAddBookmarkTitleString2 = MZLocalizedString("Menu.AddBookmarkAction2.Title", tableName: "Menu", value: "Add Bookmark", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.", lastUpdated: .unknown)
    public static let AppMenuRemoveBookmarkTitleString = MZLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.", lastUpdated: .unknown)
    public static let AppMenuFindInPageTitleString = MZLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.", lastUpdated: .unknown)
    public static let AppMenuViewDesktopSiteTitleString = MZLocalizedString("Menu.ViewDekstopSiteAction.Title", tableName: "Menu", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.", lastUpdated: .unknown)
    public static let AppMenuViewMobileSiteTitleString = MZLocalizedString("Menu.ViewMobileSiteAction.Title", tableName: "Menu", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.", lastUpdated: .unknown)
    public static let AppMenuTranslatePageTitleString = MZLocalizedString("Menu.TranslatePageAction.Title", tableName: "Menu", value: "Translate Page", comment: "Label for the button, displayed in the menu, used to translate the current page.", lastUpdated: .unknown)
    public static let AppMenuScanQRCodeTitleString = MZLocalizedString("Menu.ScanQRCodeAction.Title", tableName: "Menu", value: "Scan QR Code", comment: "Label for the button, displayed in the menu, used to open the QR code scanner.", lastUpdated: .unknown)
    public static let AppMenuSettingsTitleString = MZLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.", lastUpdated: .unknown)
    public static let AppMenuCloseAllTabsTitleString = MZLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.", lastUpdated: .unknown)
    public static let AppMenuOpenHomePageTitleString = MZLocalizedString("SettingsMenu.OpenHomePageAction.Title", tableName: "Menu", value: "Homepage", comment: "Label for the button, displayed in the menu, used to navigate to the home page.", lastUpdated: .unknown)
    public static let AppMenuTopSitesTitleString = MZLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.", lastUpdated: .unknown)
    public static let AppMenuBookmarksTitleString = MZLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel.v2", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel. Please keep as short as possible, <15 chars of space available.", lastUpdated: .unknown)
    public static let AppMenuReadingListTitleString = MZLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel.v2", tableName: "Menu", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel. Please keep as short as possible, <15 chars of space available.", lastUpdated: .unknown)
    public static let AppMenuHistoryTitleString = MZLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel.v2", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel. Please keep as short as possible, <15 chars of space available.", lastUpdated: .unknown)
    public static let AppMenuDownloadsTitleString = MZLocalizedString("Menu.OpenDownloadsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Downloads", comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel. Please keep as short as possible, <15 chars of space available.", lastUpdated: .unknown)
    public static let AppMenuSyncedTabsTitleString = MZLocalizedString("Menu.OpenSyncedTabsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Synced Tabs", comment: "Accessibility label for the button, displayed in the menu, used to open the Synced Tabs home panel. Please keep as short as possible, <15 chars of space available.", lastUpdated: .unknown)
    public static let AppMenuLibrarySeeAllTitleString = MZLocalizedString("Menu.SeeAllAction.Title", tableName: "Menu", value: "See All", comment: "Label for the button, displayed in Firefox Home, used to see all Library panels.", lastUpdated: .unknown)
    public static let AppMenuButtonAccessibilityLabel = MZLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.", lastUpdated: .unknown)
    public static let TabTrayDeleteMenuButtonAccessibilityLabel = MZLocalizedString("Toolbar.Menu.CloseAllTabs", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.", lastUpdated: .unknown)
    public static let AppMenuNightMode = MZLocalizedString("Menu.NightModeTurnOn.Label", value: "Enable Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.", lastUpdated: .unknown)
    public static let AppMenuTurnOnNightMode = MZLocalizedString("Menu.NightModeTurnOn.Label2", value: "Turn on Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.", lastUpdated: .unknown)
    public static let AppMenuTurnOffNightMode = MZLocalizedString("Menu.NightModeTurnOff.Label2", value: "Turn off Night Mode", comment: "Label for the button, displayed in the menu, turns off night mode.", lastUpdated: .unknown)
    public static let AppMenuNoImageMode = MZLocalizedString("Menu.NoImageModeBlockImages.Label", value: "Block Images", comment: "Label for the button, displayed in the menu, hides images on the webpage when pressed.", lastUpdated: .unknown)
    public static let AppMenuShowImageMode = MZLocalizedString("Menu.NoImageModeShowImages.Label", value: "Show Images", comment: "Label for the button, displayed in the menu, shows images on the webpage when pressed.", lastUpdated: .unknown)
    public static let AppMenuBookmarks = MZLocalizedString("Menu.Bookmarks.Label", value: "Bookmarks", comment: "Label for the button, displayed in the menu, takes you to to bookmarks screen when pressed.", lastUpdated: .unknown)
    public static let AppMenuHistory = MZLocalizedString("Menu.History.Label", value: "History", comment: "Label for the button, displayed in the menu, takes you to to History screen when pressed.", lastUpdated: .unknown)
    public static let AppMenuDownloads = MZLocalizedString("Menu.Downloads.Label", value: "Downloads", comment: "Label for the button, displayed in the menu, takes you to to Downloads screen when pressed.", lastUpdated: .unknown)
    public static let AppMenuReadingList = MZLocalizedString("Menu.ReadingList.Label", value: "Reading List", comment: "Label for the button, displayed in the menu, takes you to to Reading List screen when pressed.", lastUpdated: .unknown)
    public static let AppMenuPasswords = MZLocalizedString("Menu.Passwords.Label", value: "Passwords", comment: "Label for the button, displayed in the menu, takes you to to passwords screen when pressed.", lastUpdated: .unknown)
    public static let AppMenuBackUpAndSyncData = MZLocalizedString("Menu.BackUpAndSync.Label", value: "Back up and Sync Data", comment: "Label for the button, displayed in the menu, takes you to sync sign in when pressed.", lastUpdated: .unknown)
    public static let AppMenuManageAccount = MZLocalizedString("Menu.ManageAccount.Label", value: "Manage Account %@", comment: "Label for the button, displayed in the menu, takes you to screen to manage account when pressed. First argument is the display name for the current account", lastUpdated: .unknown)
    public static let AppMenuCopyURLConfirmMessage = MZLocalizedString("Menu.CopyURL.Confirm", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.", lastUpdated: .unknown)

    public static let AppMenuAddBookmarkConfirmMessage = MZLocalizedString("Menu.AddBookmark.Confirm", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.", lastUpdated: .unknown)
    public static let AppMenuTabSentConfirmMessage = MZLocalizedString("Menu.TabSent.Confirm", value: "Tab Sent", comment: "Toast displayed to the user after a tab has been sent successfully.", lastUpdated: .unknown)
    public static let AppMenuRemoveBookmarkConfirmMessage = MZLocalizedString("Menu.RemoveBookmark.Confirm", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.", lastUpdated: .unknown)
    public static let AppMenuAddPinToTopSitesConfirmMessage = MZLocalizedString("Menu.AddPin.Confirm", value: "Pinned To Top Sites", comment: "Toast displayed to the user after adding the item to the Top Sites.", lastUpdated: .unknown)
    public static let AppMenuAddPinToShortcutsConfirmMessage = MZLocalizedString("Menu.AddPin.Confirm2", value: "Added to Shortcuts", comment: "Toast displayed to the user after adding the item to the Shortcuts.", lastUpdated: .unknown)
    public static let AppMenuRemovePinFromShortcutsConfirmMessage = MZLocalizedString("Menu.RemovePin.Confirm2", value: "Removed from Shortcuts", comment: "Toast displayed to the user after removing the item to the Shortcuts.", lastUpdated: .unknown)
    public static let AppMenuRemovePinFromTopSitesConfirmMessage = MZLocalizedString("Menu.RemovePin.Confirm", value: "Removed From Top Sites", comment: "Toast displayed to the user after removing the item from the Top Sites.", lastUpdated: .unknown)
    public static let AppMenuAddToReadingListConfirmMessage = MZLocalizedString("Menu.AddToReadingList.Confirm", value: "Added To Reading List", comment: "Toast displayed to the user after adding the item to their reading list.", lastUpdated: .unknown)
    public static let SendToDeviceTitle = MZLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device", lastUpdated: .unknown)
    public static let SendLinkToDeviceTitle = MZLocalizedString("Menu.SendLinkToDevice", tableName: "3DTouchActions", value: "Send Link to Device", comment: "Label for preview action on Tab Tray Tab to send the current link to another device", lastUpdated: .unknown)
    public static let PageActionMenuTitle = MZLocalizedString("Menu.PageActions.Title", value: "Page Actions", comment: "Label for title in page action menu.", lastUpdated: .unknown)
    public static let WhatsNewString = MZLocalizedString("Menu.WhatsNew.Title", value: "What's New", comment: "The title for the option to view the What's new page.", lastUpdated: .unknown)
    public static let AppMenuShowPageSourceString = MZLocalizedString("Menu.PageSourceAction.Title", tableName: "Menu", value: "View Page Source", comment: "Label for the button, displayed in the menu, used to show the html page source", lastUpdated: .unknown)
}

// MARK: - Snackbar shown when tapping app store link
extension String {
    public static let ExternalLinkAppStoreConfirmationTitle = MZLocalizedString("ExternalLink.AppStore.ConfirmationTitle", value: "Open this link in the App Store?", comment: "Question shown to user when tapping a link that opens the App Store app", lastUpdated: .unknown)
    public static let ExternalLinkGenericConfirmation = MZLocalizedString("ExternalLink.AppStore.GenericConfirmationTitle", value: "Open this link in external app?", comment: "Question shown to user when tapping an SMS or MailTo link that opens the external app for those.", lastUpdated: .unknown)
}

// MARK: - ContentBlocker/TrackingProtection string
extension String {
    public static let SettingsTrackingProtectionSectionName = MZLocalizedString("Settings.TrackingProtection.SectionName", value: "Tracking Protection", comment: "Row in top-level of settings that gets tapped to show the tracking protection settings detail view.", lastUpdated: .unknown)

    public static let TrackingProtectionEnableTitle = MZLocalizedString("Settings.TrackingProtectionOption.NormalBrowsingLabelOn", value: "Enhanced Tracking Protection", comment: "Settings option to specify that Tracking Protection is on", lastUpdated: .unknown)

    public static let TrackingProtectionOptionOnOffFooter = MZLocalizedString("Settings.TrackingProtectionOption.EnabledStateFooterLabel", value: "Tracking is the collection of your browsing data across multiple websites.", comment: "Description label shown on tracking protection options screen.", lastUpdated: .unknown)
    public static let TrackingProtectionOptionProtectionLevelTitle = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelTitle", value: "Protection Level", comment: "Title for tracking protection options section where level can be selected.", lastUpdated: .unknown)
    public static let TrackingProtectionOptionBlockListsHeader = MZLocalizedString("Settings.TrackingProtection.BlockListsHeader", value: "You can choose which list Firefox will use to block Web elements that may track your browsing activity.", comment: "Header description for tracking protection options section where Basic/Strict block list can be selected", lastUpdated: .unknown)
    public static let TrackingProtectionOptionBlockListLevelStandard = MZLocalizedString("Settings.TrackingProtectionOption.BasicBlockList", value: "Standard (default)", comment: "Tracking protection settings option for using the basic blocklist.", lastUpdated: .unknown)
    public static let TrackingProtectionOptionBlockListLevelStrict = MZLocalizedString("Settings.TrackingProtectionOption.BlockListStrict", value: "Strict", comment: "Tracking protection settings option for using the strict blocklist.", lastUpdated: .unknown)
    public static let TrackingProtectionReloadWithout = MZLocalizedString("Menu.ReloadWithoutTrackingProtection.Title", value: "Reload Without Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website without Tracking Protection", lastUpdated: .unknown)
    public static let TrackingProtectionReloadWith = MZLocalizedString("Menu.ReloadWithTrackingProtection.Title", value: "Reload With Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website with Tracking Protection enabled", lastUpdated: .unknown)

    public static let TrackingProtectionProtectionStrictInfoFooter = MZLocalizedString("Settings.TrackingProtection.StrictLevelInfoFooter", value: "Blocking trackers could impact the functionality of some websites.", comment: "Additional information about the strict level setting", lastUpdated: .unknown)
    public static let TrackingProtectionCellFooter = MZLocalizedString("Settings.TrackingProtection.ProtectionCellFooter", value: "Reduces targeted ads and helps stop advertisers from tracking your browsing.", comment: "Additional information about your Enhanced Tracking Protection", lastUpdated: .unknown)
    public static let TrackingProtectionStandardLevelDescription = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelStandard.Description", value: "Allows some ad tracking so websites function properly.", comment: "Description for standard level tracker protection", lastUpdated: .unknown)
    public static let TrackingProtectionStrictLevelDescription = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelStrict.Description", value: "Blocks more trackers, ads, and popups. Pages load faster, but some functionality may not work.", comment: "Description for strict level tracker protection", lastUpdated: .unknown)
    public static let TrackingProtectionLevelFooter = MZLocalizedString("Settings.TrackingProtection.ProtectionLevel.Footer", value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.", comment: "Footer information for tracker protection level.", lastUpdated: .unknown)
    public static let TrackerProtectionLearnMore = MZLocalizedString("Settings.TrackingProtection.LearnMore", value: "Learn more", comment: "'Learn more' info link on the Tracking Protection settings screen.", lastUpdated: .unknown)
    public static let TrackerProtectionAlertTitle =  MZLocalizedString("Settings.TrackingProtection.Alert.Title", value: "Heads up!", comment: "Title for the tracker protection alert.", lastUpdated: .unknown)
    public static let TrackerProtectionAlertDescription =  MZLocalizedString("Settings.TrackingProtection.Alert.Description", value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.", comment: "Decription for the tracker protection alert.", lastUpdated: .unknown)
    public static let TrackerProtectionAlertButton =  MZLocalizedString("Settings.TrackingProtection.Alert.Button", value: "OK, Got It", comment: "Dismiss button for the tracker protection alert.", lastUpdated: .unknown)
}

// MARK: - Tracking Protection menu
extension String {
    public static let TPBlockingDescription = MZLocalizedString("Menu.TrackingProtectionBlocking.Description", value: "Firefox is blocking parts of the page that may track your browsing.", comment: "Description of the Tracking protection menu when TP is blocking parts of the page", lastUpdated: .unknown)
    public static let TPNoBlockingDescription = MZLocalizedString("Menu.TrackingProtectionNoBlocking.Description", value: "No tracking elements detected on this page.", comment: "The description of the Tracking Protection menu item when no scripts are blocked but tracking protection is enabled.", lastUpdated: .unknown)
    public static let TPBlockingDisabledDescription = MZLocalizedString("Menu.TrackingProtectionBlockingDisabled.Description", value: "Block online trackers", comment: "The description of the Tracking Protection menu item when tracking is enabled", lastUpdated: .unknown)
    public static let TPBlockingMoreInfo = MZLocalizedString("Menu.TrackingProtectionMoreInfo.Description", value: "Learn more about how Tracking Protection blocks online trackers that collect your browsing data across multiple websites.", comment: "more info about what tracking protection is about", lastUpdated: .unknown)
    public static let EnableTPBlockingGlobally = MZLocalizedString("Menu.TrackingProtectionEnable.Title", value: "Enable Tracking Protection", comment: "A button to enable tracking protection inside the menu.", lastUpdated: .unknown)
    public static let TPBlockingSiteEnabled = MZLocalizedString("Menu.TrackingProtectionEnable1.Title", value: "Enabled for this site", comment: "A button to enable tracking protection inside the menu.", lastUpdated: .unknown)
    public static let TPEnabledConfirmed = MZLocalizedString("Menu.TrackingProtectionEnabled.Title", value: "Tracking Protection is now on for this site.", comment: "The confirmation toast once tracking protection has been enabled", lastUpdated: .unknown)
    public static let TPDisabledConfirmed = MZLocalizedString("Menu.TrackingProtectionDisabled.Title", value: "Tracking Protection is now off for this site.", comment: "The confirmation toast once tracking protection has been disabled", lastUpdated: .unknown)
    public static let TPBlockingSiteDisabled = MZLocalizedString("Menu.TrackingProtectionDisable1.Title", value: "Disabled for this site", comment: "The button that disabled TP for a site.", lastUpdated: .unknown)
    public static let ETPOn = MZLocalizedString("Menu.EnhancedTrackingProtectionOn.Title", value: "Protections are ON for this site", comment: "A switch to enable enhanced tracking protection inside the menu.", lastUpdated: .unknown)
    public static let ETPOff = MZLocalizedString("Menu.EnhancedTrackingProtectionOff.Title", value: "Protections are OFF for this site", comment: "A switch to disable enhanced tracking protection inside the menu.", lastUpdated: .unknown)
    public static let StrictETPWithITP = MZLocalizedString("Menu.EnhancedTrackingProtectionStrictWithITP.Title", value: "Firefox blocks cross-site trackers, social trackers, cryptominers, fingerprinters, and tracking content.", comment: "Description for having strict ETP protection with ITP offered in iOS14+", lastUpdated: .unknown)
    public static let StandardETPWithITP = MZLocalizedString("Menu.EnhancedTrackingProtectionStandardWithITP.Title", value: "Firefox blocks cross-site trackers, social trackers, cryptominers, and fingerprinters.", comment: "Description for having standard ETP protection with ITP offered in iOS14+", lastUpdated: .unknown)

    // TP Page menu title
    public static let TPPageMenuTitle = MZLocalizedString("Menu.TrackingProtection.TitlePrefix", value: "Protections for %@", comment: "Title on tracking protection menu showing the domain. eg. Protections for mozilla.org", lastUpdated: .unknown)
    public static let TPPageMenuNoTrackersBlocked = MZLocalizedString("Menu.TrackingProtection.NoTrackersBlockedTitle", value: "No trackers known to Firefox were detected on this page.", comment: "Message in menu when no trackers blocked.", lastUpdated: .unknown)
    public static let TPPageMenuBlockedTitle = MZLocalizedString("Menu.TrackingProtection.BlockedTitle", value: "Blocked", comment: "Title on tracking protection menu for blocked items.", lastUpdated: .unknown)

    public static let TPDetailsVerifiedBy = MZLocalizedString("Menu.TrackingProtection.Details.Verifier", value: "Verified by %@", comment: "String to let users know the site verifier, where the placeholder represents the SSL certificate signer.", lastUpdated: .unknown)

    // Category Titles
    public static let TPCryptominersBlocked = MZLocalizedString("Menu.TrackingProtectionCryptominersBlocked.Title", value: "Cryptominers", comment: "The title that shows the number of cryptomining scripts blocked", lastUpdated: .unknown)
    public static let TPFingerprintersBlocked = MZLocalizedString("Menu.TrackingProtectionFingerprintersBlocked.Title", value: "Fingerprinters", comment: "The title that shows the number of fingerprinting scripts blocked", lastUpdated: .unknown)
    public static let TPCrossSiteCookiesBlocked = MZLocalizedString("Menu.TrackingProtectionCrossSiteCookies.Title", value: "Cross-Site Tracking Cookies", comment: "The title that shows the number of cross-site cookies blocked", lastUpdated: .unknown)
    public static let TPCrossSiteBlocked = MZLocalizedString("Menu.TrackingProtectionCrossSiteTrackers.Title", value: "Cross-Site Trackers", comment: "The title that shows the number of cross-site URLs blocked", lastUpdated: .unknown)
    public static let TPSocialBlocked = MZLocalizedString("Menu.TrackingProtectionBlockedSocial.Title", value: "Social Trackers", comment: "The title that shows the number of social URLs blocked", lastUpdated: .unknown)
    public static let TPContentBlocked = MZLocalizedString("Menu.TrackingProtectionBlockedContent.Title", value: "Tracking content", comment: "The title that shows the number of content cookies blocked", lastUpdated: .unknown)

    // Shortcut on bottom of TP page menu to get to settings.
    public static let TPProtectionSettings = MZLocalizedString("Menu.TrackingProtection.ProtectionSettings.Title", value: "Protection Settings", comment: "The title for tracking protection settings", lastUpdated: .unknown)

    // Remove if unused -->
    public static let TPListTitle_CrossSiteCookies = MZLocalizedString("Menu.TrackingProtectionListTitle.CrossSiteCookies", value: "Blocked Cross-Site Tracking Cookies", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`", lastUpdated: .unknown)
    public static let TPListTitle_Social = MZLocalizedString("Menu.TrackingProtectionListTitle.Social", value: "Blocked Social Trackers", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`", lastUpdated: .unknown)
    public static let TPListTitle_Fingerprinters = MZLocalizedString("Menu.TrackingProtectionListTitle.Fingerprinters", value: "Blocked Fingerprinters", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`", lastUpdated: .unknown)
    public static let TPListTitle_Cryptominer = MZLocalizedString("Menu.TrackingProtectionListTitle.Cryptominers", value: "Blocked Cryptominers", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`", lastUpdated: .unknown)
    /// <--

    public static let TPSafeListOn = MZLocalizedString("Menu.TrackingProtectionOption.WhiteListOnDescription", value: "The site includes elements that may track your browsing. You have disabled protection.", comment: "label for the menu item to show when the website is whitelisted from blocking trackers.", lastUpdated: .unknown)
    public static let TPSafeListRemove = MZLocalizedString("Menu.TrackingProtectionWhitelistRemove.Title", value: "Enable for this site", comment: "label for the menu item that lets you remove a website from the tracking protection whitelist", lastUpdated: .unknown)

    // Settings info
    public static let TPAccessoryInfoTitleStrict = MZLocalizedString("Settings.TrackingProtection.Info.StrictTitle", value: "Offers stronger protection, but may cause some sites to break.", comment: "Explanation of strict mode.", lastUpdated: .unknown)
    public static let TPAccessoryInfoTitleBasic = MZLocalizedString("Settings.TrackingProtection.Info.BasicTitle", value: "Balanced for protection and performance.", comment: "Explanation of basic mode.", lastUpdated: .unknown)
    public static let TPAccessoryInfoBlocksTitle = MZLocalizedString("Settings.TrackingProtection.Info.BlocksTitle", value: "BLOCKS", comment: "The Title on info view which shows a list of all blocked websites", lastUpdated: .unknown)

    // Category descriptions
    public static let TPCategoryDescriptionSocial = MZLocalizedString("Menu.TrackingProtectionDescription.SocialNetworksNew", value: "Social networks place trackers on other websites to build a more complete and targeted profile of you. Blocking these trackers reduces how much social media companies can see what do you online.", comment: "Description of social network trackers.", lastUpdated: .unknown)
    public static let TPCategoryDescriptionCrossSite = MZLocalizedString("Menu.TrackingProtectionDescription.CrossSiteNew", value: "These cookies follow you from site to site to gather data about what you do online. They are set by third parties such as advertisers and analytics companies.", comment: "Description of cross-site trackers.", lastUpdated: .unknown)
    public static let TPCategoryDescriptionCryptominers = MZLocalizedString("Menu.TrackingProtectionDescription.CryptominersNew", value: "Cryptominers secretly use your system’s computing power to mine digital money. Cryptomining scripts drain your battery, slow down your computer, and can increase your energy bill.", comment: "Description of cryptominers.", lastUpdated: .unknown)
    public static let TPCategoryDescriptionFingerprinters = MZLocalizedString("Menu.TrackingProtectionDescription.Fingerprinters", value: "The settings on your browser and computer are unique. Fingerprinters collect a variety of these unique settings to create a profile of you, which can be used to track you as you browse.", comment: "Description of fingerprinters.", lastUpdated: .unknown)
    public static let TPCategoryDescriptionContentTrackers = MZLocalizedString("Menu.TrackingProtectionDescription.ContentTrackers", value: "Websites may load outside ads, videos, and other content that contains hidden trackers. Blocking this can make websites load faster, but some buttons, forms, and login fields, might not work.", comment: "Description of content trackers.", lastUpdated: .unknown)

    public static let TPMoreInfo = MZLocalizedString("Settings.TrackingProtection.MoreInfo", value: "More Info…", comment: "'More Info' link on the Tracking Protection settings screen.", lastUpdated: .unknown)
}

// MARK: - Location bar long press menu
extension String {
    public static let PasteAndGoTitle = MZLocalizedString("Menu.PasteAndGo.Title", value: "Paste & Go", comment: "The title for the button that lets you paste and go to a URL", lastUpdated: .unknown)
    public static let PasteTitle = MZLocalizedString("Menu.Paste.Title", value: "Paste", comment: "The title for the button that lets you paste into the location bar", lastUpdated: .unknown)
    public static let CopyAddressTitle = MZLocalizedString("Menu.Copy.Title", value: "Copy Address", comment: "The title for the button that lets you copy the url from the location bar.", lastUpdated: .unknown)
}

// MARK: - Settings Home
extension String {
    public static let SendUsageSettingTitle = MZLocalizedString("Settings.SendUsage.Title", value: "Send Usage Data", comment: "The title for the setting to send usage data.", lastUpdated: .unknown)
    public static let SendUsageSettingLink = MZLocalizedString("Settings.SendUsage.Link", value: "Learn More.", comment: "title for a link that explains how mozilla collects telemetry", lastUpdated: .unknown)
    public static let SendUsageSettingMessage = MZLocalizedString("Settings.SendUsage.Message", value: "Mozilla strives to only collect what we need to provide and improve Firefox for everyone.", comment: "A short description that explains why mozilla collects usage data.", lastUpdated: .unknown)
    public static let SettingsSiriSectionName = MZLocalizedString("Settings.Siri.SectionName", value: "Siri Shortcuts", comment: "The option that takes you to the siri shortcuts settings page", lastUpdated: .unknown)
    public static let SettingsSiriSectionDescription = MZLocalizedString("Settings.Siri.SectionDescription", value: "Use Siri shortcuts to quickly open Firefox via Siri", comment: "The description that describes what siri shortcuts are", lastUpdated: .unknown)
    public static let SettingsSiriOpenURL = MZLocalizedString("Settings.Siri.OpenTabShortcut", value: "Open New Tab", comment: "The description of the open new tab siri shortcut", lastUpdated: .unknown)
}

// MARK: - Nimbus settings
extension String {
    public static let SettingsStudiesTitle = MZLocalizedString("Settings.Studies.Title", value: "Studies", comment: "Label used as an item in Settings. Tapping on this item takes you to the Studies panel", lastUpdated: .unknown)
    public static let SettingsStudiesSectionName = MZLocalizedString("Settings.Studies.SectionName", value: "Studies", comment: "Title displayed in header of the Studies panel", lastUpdated: .unknown)
    public static let SettingsStudiesActiveSectionTitle = MZLocalizedString("Settings.Studies.Active.SectionName", value: "Active", comment: "Section title for all studies that are currently active", lastUpdated: .unknown)
    public static let SettingsStudiesCompletedSectionTitle = MZLocalizedString("Settings.Studies.Completed.SectionName", value: "Completed", comment: "Section title for all studies that are completed", lastUpdated: .unknown)
    public static let SettingsStudiesRemoveButton = MZLocalizedString("Settings.Studies.Remove.Button", value: "Remove", comment: "Button title displayed next to each study allowing the user to opt-out of the study", lastUpdated: .unknown)

    public static let SettingsStudiesToggleTitle = MZLocalizedString("Settings.Studies.Toggle.Title", value: "Studies", comment: "Label used as a toggle item in Settings. When this is off, the user is opting out of all studies.", lastUpdated: .unknown)
    public static let SettingsStudiesToggleLink = MZLocalizedString("Settings.Studies.Toggle.Link", value: "Learn More.", comment: "Title for a link that explains what Mozilla means by Studies", lastUpdated: .unknown)
    public static let SettingsStudiesToggleMessage = MZLocalizedString("Settings.Studies.Toggle.Message", value: "Firefox may install and run studies from time to time.", comment: "A short description that explains that Mozilla is running studies", lastUpdated: .unknown)

    public static let SettingsStudiesToggleValueOn = MZLocalizedString("Settings.Studies.Toggle.On", value: "On", comment: "Toggled ON to participate in studies", lastUpdated: .unknown)
    public static let SettingsStudiesToggleValueOff = MZLocalizedString("Settings.Studies.Toggle.Off", value: "Off", comment: "Toggled OFF to opt-out of studies", lastUpdated: .unknown)
}

// MARK: - Do not track
extension String {
    public static let SettingsDoNotTrackTitle = MZLocalizedString("Settings.DNT.Title", value: "Send websites a Do Not Track signal that you don’t want to be tracked", comment: "DNT Settings title", lastUpdated: .unknown)
    public static let SettingsDoNotTrackOptionOnWithTP = MZLocalizedString("Settings.DNT.OptionOnWithTP", value: "Only when using Tracking Protection", comment: "DNT Settings option for only turning on when Tracking Protection is also on", lastUpdated: .unknown)
    public static let SettingsDoNotTrackOptionAlwaysOn = MZLocalizedString("Settings.DNT.OptionAlwaysOn", value: "Always", comment: "DNT Settings option for always on", lastUpdated: .unknown)
}

// MARK: - Intro Onboarding slides
extension String {
    // First Card
    public static let CardTitleWelcome = MZLocalizedString("Intro.Slides.Welcome.Title.v2", tableName: "Intro", value: "Welcome to Firefox", comment: "Title for the first panel 'Welcome' in the First Run tour.", lastUpdated: .unknown)
    public static let CardTitleAutomaticPrivacy = MZLocalizedString("Intro.Slides.Automatic.Privacy.Title", tableName: "Intro", value: "Automatic Privacy", comment: "Title for the first item in the table related to automatic privacy", lastUpdated: .unknown)
    public static let CardDescriptionAutomaticPrivacy = MZLocalizedString("Intro.Slides.Automatic.Privacy.Description", tableName: "Intro", value: "Enhanced Tracking Protection blocks malware and stops trackers.", comment: "Description for the first item in the table related to automatic privacy", lastUpdated: .unknown)
    public static let CardTitleFastSearch = MZLocalizedString("Intro.Slides.Fast.Search.Title", tableName: "Intro", value: "Fast Search", comment: "Title for the second item in the table related to fast searching via address bar", lastUpdated: .unknown)
    public static let CardDescriptionFastSearch = MZLocalizedString("Intro.Slides.Fast.Search.Description", tableName: "Intro", value: "Search suggestions get you to websites faster.", comment: "Description for the second item in the table related to fast searching via address bar", lastUpdated: .unknown)
    public static let CardTitleSafeSync = MZLocalizedString("Intro.Slides.Safe.Sync.Title", tableName: "Intro", value: "Safe Sync", comment: "Title for the third item in the table related to safe syncing with a firefox account", lastUpdated: .unknown)
    public static let CardDescriptionSafeSync = MZLocalizedString("Intro.Slides.Safe.Sync.Description", tableName: "Intro", value: "Protect your logins and data everywhere you use Firefox.", comment: "Description for the third item in the table related to safe syncing with a firefox account", lastUpdated: .unknown)

    // Second Card
    public static let CardTitleFxASyncDevices = MZLocalizedString("Intro.Slides.Firefox.Account.Sync.Title", tableName: "Intro", value: "Sync Firefox Between Devices", comment: "Title for the first item in the table related to syncing data (bookmarks, history) via firefox account between devices", lastUpdated: .unknown)
    public static let CardDescriptionFxASyncDevices = MZLocalizedString("Intro.Slides.Firefox.Account.Sync.Description", tableName: "Intro", value: "Bring bookmarks, history, and passwords to Firefox on this device.", comment: "Description for the first item in the table related to syncing data (bookmarks, history) via firefox account between devices", lastUpdated: .unknown)

    //----Other----//
    public static let CardTitleSearch = MZLocalizedString("Intro.Slides.Search.Title", tableName: "Intro", value: "Your search, your way", comment: "Title for the second  panel 'Search' in the First Run tour.", lastUpdated: .unknown)
    public static let CardTitlePrivate = MZLocalizedString("Intro.Slides.Private.Title", tableName: "Intro", value: "Browse like no one’s watching", comment: "Title for the third panel 'Private Browsing' in the First Run tour.", lastUpdated: .unknown)
    public static let CardTitleMail = MZLocalizedString("Intro.Slides.Mail.Title", tableName: "Intro", value: "You’ve got mail… options", comment: "Title for the fourth panel 'Mail' in the First Run tour.", lastUpdated: .unknown)
    public static let CardTitleSync = MZLocalizedString("Intro.Slides.TrailheadSync.Title.v2", tableName: "Intro", value: "Sync your bookmarks, history, and passwords to your phone.", comment: "Title for the second panel 'Sync' in the First Run tour.", lastUpdated: .unknown)

    public static let CardTextWelcome = MZLocalizedString("Intro.Slides.Welcome.Description.v2", tableName: "Intro", value: "Fast, private, and on your side.", comment: "Description for the 'Welcome' panel in the First Run tour.", lastUpdated: .unknown)
    public static let CardTextSearch = MZLocalizedString("Intro.Slides.Search.Description", tableName: "Intro", value: "Searching for something different? Choose another default search engine (or add your own) in Settings.", comment: "Description for the 'Favorite Search Engine' panel in the First Run tour.", lastUpdated: .unknown)
    public static let CardTextPrivate = MZLocalizedString("Intro.Slides.Private.Description", tableName: "Intro", value: "Tap the mask icon to slip into Private Browsing mode.", comment: "Description for the 'Private Browsing' panel in the First Run tour.", lastUpdated: .unknown)
    public static let CardTextMail = MZLocalizedString("Intro.Slides.Mail.Description", tableName: "Intro", value: "Use any email app — not just Mail — with Firefox.", comment: "Description for the 'Mail' panel in the First Run tour.", lastUpdated: .unknown)
    public static let CardTextSync = MZLocalizedString("Intro.Slides.TrailheadSync.Description", tableName: "Intro", value: "Sign in to your account to sync and access more features.", comment: "Description for the 'Sync' panel in the First Run tour.", lastUpdated: .unknown)
    public static let SignInButtonTitle = MZLocalizedString("Turn on Sync…", tableName: "Intro", comment: "The button that opens the sign in page for sync. See http://mzl.la/1T8gxwo", lastUpdated: .unknown)
    public static let StartBrowsingButtonTitle = MZLocalizedString("Start Browsing", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo", lastUpdated: .unknown)
    public static let IntroNextButtonTitle = MZLocalizedString("Intro.Slides.Button.Next", tableName: "Intro", value: "Next", comment: "Next button on the first intro screen.", lastUpdated: .unknown)
    public static let IntroSignInButtonTitle = MZLocalizedString("Intro.Slides.Button.SignIn", tableName: "Intro", value: "Sign In", comment: "Sign in to Firefox account button on second intro screen.", lastUpdated: .unknown)
    public static let IntroSignUpButtonTitle = MZLocalizedString("Intro.Slides.Button.SignUp", tableName: "Intro", value: "Sign Up", comment: "Sign up to Firefox account button on second intro screen.", lastUpdated: .unknown)
}

// MARK: - Share extension
extension String {
    public static let SendToCancelButton = MZLocalizedString("SendTo.Cancel.Button", value: "Cancel", comment: "Button title for cancelling share screen", lastUpdated: .unknown)
    public static let SendToErrorOKButton = MZLocalizedString("SendTo.Error.OK.Button", value: "OK", comment: "OK button to dismiss the error prompt.", lastUpdated: .unknown)
    public static let SendToErrorTitle = MZLocalizedString("SendTo.Error.Title", value: "The link you are trying to share cannot be shared.", comment: "Title of error prompt displayed when an invalid URL is shared.", lastUpdated: .unknown)
    public static let SendToErrorMessage = MZLocalizedString("SendTo.Error.Message", value: "Only HTTP and HTTPS links can be shared.", comment: "Message in error prompt explaining why the URL is invalid.", lastUpdated: .unknown)
    public static let SendToCloseButton = MZLocalizedString("SendTo.Cancel.Button", value: "Close", comment: "Close button in top navigation bar", lastUpdated: .unknown)
    public static let SendToNotSignedInText = MZLocalizedString("SendTo.NotSignedIn.Title", value: "You are not signed in to your Firefox Account.", comment: "See http://mzl.la/1ISlXnU", lastUpdated: .unknown)
    public static let SendToNotSignedInMessage = MZLocalizedString("SendTo.NotSignedIn.Message", value: "Please open Firefox, go to Settings and sign in to continue.", comment: "See http://mzl.la/1ISlXnU", lastUpdated: .unknown)
    public static let SendToSignInButton = MZLocalizedString("SendTo.SignIn.Button", value: "Sign In to Firefox", comment: "The text for the button on the Send to Device page if you are not signed in to Firefox Accounts.", lastUpdated: .unknown)
    public static let SendToNoDevicesFound = MZLocalizedString("SendTo.NoDevicesFound.Message", value: "You don’t have any other devices connected to this Firefox Account available to sync.", comment: "Error message shown in the remote tabs panel", lastUpdated: .unknown)
    public static let SendToTitle = MZLocalizedString("SendTo.NavBar.Title", value: "Send Tab", comment: "Title of the dialog that allows you to send a tab to a different device", lastUpdated: .unknown)
    public static let SendToSendButtonTitle = MZLocalizedString("SendTo.SendAction.Text", value: "Send", comment: "Navigation bar button to Send the current page to a device", lastUpdated: .unknown)
    public static let SendToDevicesListTitle = MZLocalizedString("SendTo.DeviceList.Text", value: "Available devices:", comment: "Header for the list of devices table", lastUpdated: .unknown)
    public static let ShareSendToDevice = String.SendToDeviceTitle

    // The above items are re-used strings from the old extension. New strings below.

    public static let ShareAddToReadingList = MZLocalizedString("ShareExtension.AddToReadingListAction.Title", value: "Add to Reading List", comment: "Action label on share extension to add page to the Firefox reading list.", lastUpdated: .unknown)
    public static let ShareAddToReadingListDone = MZLocalizedString("ShareExtension.AddToReadingListActionDone.Title", value: "Added to Reading List", comment: "Share extension label shown after user has performed 'Add to Reading List' action.", lastUpdated: .unknown)
    public static let ShareBookmarkThisPage = MZLocalizedString("ShareExtension.BookmarkThisPageAction.Title", value: "Bookmark This Page", comment: "Action label on share extension to bookmark the page in Firefox.", lastUpdated: .unknown)
    public static let ShareBookmarkThisPageDone = MZLocalizedString("ShareExtension.BookmarkThisPageActionDone.Title", value: "Bookmarked", comment: "Share extension label shown after user has performed 'Bookmark this Page' action.", lastUpdated: .unknown)

    public static let ShareOpenInFirefox = MZLocalizedString("ShareExtension.OpenInFirefoxAction.Title", value: "Open in Firefox", comment: "Action label on share extension to immediately open page in Firefox.", lastUpdated: .unknown)
    public static let ShareSearchInFirefox = MZLocalizedString("ShareExtension.SeachInFirefoxAction.Title", value: "Search in Firefox", comment: "Action label on share extension to search for the selected text in Firefox.", lastUpdated: .unknown)
    public static let ShareOpenInPrivateModeNow = MZLocalizedString("ShareExtension.OpenInPrivateModeAction.Title", value: "Open in Private Mode", comment: "Action label on share extension to immediately open page in Firefox in private mode.", lastUpdated: .unknown)

    public static let ShareLoadInBackground = MZLocalizedString("ShareExtension.LoadInBackgroundAction.Title", value: "Load in Background", comment: "Action label on share extension to load the page in Firefox when user switches apps to bring it to foreground.", lastUpdated: .unknown)
    public static let ShareLoadInBackgroundDone = MZLocalizedString("ShareExtension.LoadInBackgroundActionDone.Title", value: "Loading in Firefox", comment: "Share extension label shown after user has performed 'Load in Background' action.", lastUpdated: .unknown)

}

// MARK: - PasswordAutofill extension
extension String {
    public static let PasswordAutofillTitle = MZLocalizedString("PasswordAutoFill.SectionTitle", value: "Firefox Credentials", comment: "Title of the extension that shows firefox passwords", lastUpdated: .unknown)
    public static let CredentialProviderNoCredentialError = MZLocalizedString("PasswordAutoFill.NoPasswordsFoundTitle", value: "You don’t have any credentials synced from your Firefox Account", comment: "Error message shown in the remote tabs panel", lastUpdated: .unknown)
    public static let AvailableCredentialsHeader = MZLocalizedString("PasswordAutoFill.PasswordsListTitle", value: "Available Credentials:", comment: "Header for the list of credentials table", lastUpdated: .unknown)
}

// MARK: - Translation bar
extension String {
    public static let TranslateSnackBarPrompt = MZLocalizedString("TranslationToastHandler.PromptTranslate.Title", value: "This page appears to be in %1$@. Translate to %2$@ with %3$@?", comment: "Prompt for translation. The first parameter is the language the page is in. The second parameter is the name of our local language. The third is the name of the service.", lastUpdated: .unknown)
    public static let TranslateSnackBarYes = MZLocalizedString("TranslationToastHandler.PromptTranslate.OK", value: "Yes", comment: "Button to allow the page to be translated to the user locale language", lastUpdated: .unknown)
    public static let TranslateSnackBarNo = MZLocalizedString("TranslationToastHandler.PromptTranslate.Cancel", value: "No", comment: "Button to disallow the page to be translated to the user locale language", lastUpdated: .unknown)

    public static let SettingTranslateSnackBarSectionHeader = MZLocalizedString("Settings.TranslateSnackBar.SectionHeader", value: "Services", comment: "Translation settings section title", lastUpdated: .unknown)
    public static let SettingTranslateSnackBarSectionFooter = MZLocalizedString("Settings.TranslateSnackBar.SectionFooter", value: "The web page language is detected on the device, and a translation from a remote service is offered.", comment: "Translation settings footer describing how language detection and translation happens.", lastUpdated: .unknown)
    public static let SettingTranslateSnackBarTitle = MZLocalizedString("Settings.TranslateSnackBar.Title", value: "Translation", comment: "Title in main app settings for Translation toast settings", lastUpdated: .unknown)
    public static let SettingTranslateSnackBarSwitchTitle = MZLocalizedString("Settings.TranslateSnackBar.SwitchTitle", value: "Offer Translation", comment: "Switch to choose if the language of a page is detected and offer to translate.", lastUpdated: .unknown)
    public static let SettingTranslateSnackBarSwitchSubtitle = MZLocalizedString("Settings.TranslateSnackBar.SwitchSubtitle", value: "Offer to translate any site written in a language that is different from your default language.", comment: "Switch to choose if the language of a page is detected and offer to translate.", lastUpdated: .unknown)
}

// MARK: - Display Theme
extension String {
    public static let SettingsDisplayThemeTitle = MZLocalizedString("Settings.DisplayTheme.Title.v2", value: "Theme", comment: "Title in main app settings for Theme settings", lastUpdated: .unknown)
    public static let DisplayThemeBrightnessThresholdSectionHeader = MZLocalizedString("Settings.DisplayTheme.BrightnessThreshold.SectionHeader", value: "Threshold", comment: "Section header for brightness slider.", lastUpdated: .unknown)
    public static let DisplayThemeSectionFooter = MZLocalizedString("Settings.DisplayTheme.SectionFooter", value: "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes. The circle indicates your display's current brightness.", comment: "Display (theme) settings footer describing how the brightness slider works.", lastUpdated: .unknown)
    public static let SystemThemeSectionHeader = MZLocalizedString("Settings.DisplayTheme.SystemTheme.SectionHeader", value: "System Theme", comment: "System theme settings section title", lastUpdated: .unknown)
    public static let SystemThemeSectionSwitchTitle = MZLocalizedString("Settings.DisplayTheme.SystemTheme.SwitchTitle", value: "Use System Light/Dark Mode", comment: "System theme settings switch to choose whether to use the same theme as the system", lastUpdated: .unknown)
    public static let ThemeSwitchModeSectionHeader = MZLocalizedString("Settings.DisplayTheme.SwitchMode.SectionHeader", value: "Switch Mode", comment: "Switch mode settings section title", lastUpdated: .unknown)
    public static let ThemePickerSectionHeader = MZLocalizedString("Settings.DisplayTheme.ThemePicker.SectionHeader", value: "Theme Picker", comment: "Theme picker settings section title", lastUpdated: .unknown)
    public static let DisplayThemeAutomaticSwitchTitle = MZLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatically", comment: "Display (theme) settings switch to choose whether to set the dark mode manually, or automatically based on the brightness slider.", lastUpdated: .unknown)
    public static let DisplayThemeAutomaticStatusLabel = MZLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatic", comment: "Display (theme) settings label to show if automatically switch theme is enabled.", lastUpdated: .unknown)
    public static let DisplayThemeAutomaticSwitchSubtitle = MZLocalizedString("Settings.DisplayTheme.SwitchSubtitle", value: "Switch automatically based on screen brightness", comment: "Display (theme) settings switch subtitle, explaining the title 'Automatically'.", lastUpdated: .unknown)
    public static let DisplayThemeManualSwitchTitle = MZLocalizedString("Settings.DisplayTheme.Manual.SwitchTitle", value: "Manually", comment: "Display (theme) setting to choose the theme manually.", lastUpdated: .unknown)
    public static let DisplayThemeManualSwitchSubtitle = MZLocalizedString("Settings.DisplayTheme.Manual.SwitchSubtitle", value: "Pick which theme you want", comment: "Display (theme) settings switch subtitle, explaining the title 'Manually'.", lastUpdated: .unknown)
    public static let DisplayThemeManualStatusLabel = MZLocalizedString("Settings.DisplayTheme.Manual.StatusLabel", value: "Manual", comment: "Display (theme) settings label to show if manually switch theme is enabled.", lastUpdated: .unknown)
    public static let DisplayThemeOptionLight = MZLocalizedString("Settings.DisplayTheme.OptionLight", value: "Light", comment: "Option choice in display theme settings for light theme", lastUpdated: .unknown)
    public static let DisplayThemeOptionDark = MZLocalizedString("Settings.DisplayTheme.OptionDark", value: "Dark", comment: "Option choice in display theme settings for dark theme", lastUpdated: .unknown)
}

extension String {
    public static let AddTabAccessibilityLabel = MZLocalizedString("TabTray.AddTab.Button", value: "Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.", lastUpdated: .unknown)
}

// MARK: - Cover Sheet
extension String {
    // Dark Mode Cover Sheet
    public static let CoverSheetV22DarkModeTitle = MZLocalizedString("CoverSheet.v22.DarkMode.Title", value: "Dark theme now includes a dark keyboard and dark splash screen.", comment: "Title for the new dark mode change in the version 22 app release.", lastUpdated: .unknown)
    public static let CoverSheetV22DarkModeDescription = MZLocalizedString("CoverSheet.v22.DarkMode.Description", value: "For iOS 13 users, Firefox now automatically switches to a dark theme when your phone is set to Dark Mode. To change this behavior, go to Settings > Theme.", comment: "Description for the new dark mode change in the version 22 app release. It describes the new automatic dark theme and how to change the theme settings.", lastUpdated: .unknown)

    // ETP Cover Sheet
    public static let CoverSheetETPTitle = MZLocalizedString("CoverSheet.v24.ETP.Title", value: "Protection Against Ad Tracking", comment: "Title for the new ETP mode i.e. standard vs strict", lastUpdated: .unknown)
    public static let CoverSheetETPDescription = MZLocalizedString("CoverSheet.v24.ETP.Description", value: "Built-in Enhanced Tracking Protection helps stop ads from following you around. Turn on Strict to block even more trackers, ads, and popups. ", comment: "Description for the new ETP mode i.e. standard vs strict", lastUpdated: .unknown)
    public static let CoverSheetETPSettingsButton = MZLocalizedString("CoverSheet.v24.ETP.Settings.Button", value: "Go to Settings", comment: "Text for the new ETP settings button", lastUpdated: .unknown)
}

// MARK: - FxA Signin screen
extension String {
    public static let FxASignin_Title = MZLocalizedString("fxa.signin.turn-on-sync", value: "Turn on Sync", comment: "FxA sign in view title", lastUpdated: .unknown)
    public static let FxASignin_Subtitle = MZLocalizedString("fxa.signin.camera-signin", value: "Sign In with Your Camera", comment: "FxA sign in view subtitle", lastUpdated: .unknown)
    public static let FxASignin_QRInstructions = MZLocalizedString("fxa.signin.qr-link-instruction", value: "On your computer open Firefox and go to firefox.com/pair", comment: "FxA sign in view qr code instructions", lastUpdated: .unknown)
    public static let FxASignin_QRScanSignin = MZLocalizedString("fxa.signin.ready-to-scan", value: "Ready to Scan", comment: "FxA sign in view qr code scan button", lastUpdated: .unknown)
    public static let FxASignin_EmailSignin = MZLocalizedString("fxa.signin.use-email-instead", value: "Use Email Instead", comment: "FxA sign in view email login button", lastUpdated: .unknown)
    public static let FxASignin_CreateAccountPt1 = MZLocalizedString("fxa.signin.create-account-pt-1", value: "Sync Firefox between devices with an account.", comment: "FxA sign in create account label.", lastUpdated: .unknown)
    public static let FxASignin_CreateAccountPt2 = MZLocalizedString("fxa.signin.create-account-pt-2", value: "Create Firefox account.", comment: "FxA sign in create account label. This will be linked to the site to create an account.", lastUpdated: .unknown)
}

// MARK: - FxA QR code scanning screen
extension String {
    public static let FxAQRCode_Instructions = MZLocalizedString("fxa.qr-scanning-view.instructions", value: "Scan the QR code shown at firefox.com/pair", comment: "Instructions shown on qr code scanning view", lastUpdated: .unknown)
}

// MARK: - Today Widget Strings - [New Search - Private Search]
extension String {
    public static let NewTabButtonLabel = MZLocalizedString("TodayWidget.NewTabButtonLabelV1", tableName: "Today", value: "New Search", comment: "Open New Tab button label", lastUpdated: .unknown)
    public static let CopiedLinkLabelFromPasteBoard = MZLocalizedString("TodayWidget.CopiedLinkLabelFromPasteBoardV1", tableName: "Today", value: "Copied Link from clipboard", comment: "Copied Link from clipboard displayed", lastUpdated: .unknown)
    public static let NewPrivateTabButtonLabel = MZLocalizedString("TodayWidget.PrivateTabButtonLabelV1", tableName: "Today", value: "Private Search", comment: "Open New Private Tab button label", lastUpdated: .unknown)

    // Widget - Shared

    public static let QuickActionsGalleryTitle = MZLocalizedString("TodayWidget.QuickActionsGalleryTitle", tableName: "Today", value: "Quick Actions", comment: "Quick Actions title when widget enters edit mode", lastUpdated: .unknown)
    public static let QuickActionsGalleryTitlev2 = MZLocalizedString("TodayWidget.QuickActionsGalleryTitleV2", tableName: "Today", value: "Firefox Shortcuts", comment: "Firefox shortcuts title when widget enters edit mode. Do not translate the word Firefox.", lastUpdated: .unknown)

    // Quick View - Gallery View
    public static let QuickViewGalleryTile = MZLocalizedString("TodayWidget.QuickViewGalleryTitle", tableName: "Today", value: "Quick View", comment: "Quick View title user is picking a widget to add.", lastUpdated: .unknown)

    // Quick Action - Medium Size Quick Action
    public static let QuickActionsSubLabel = MZLocalizedString("TodayWidget.QuickActionsSubLabel", tableName: "Today", value: "Firefox - Quick Actions", comment: "Sub label for medium size quick action widget", lastUpdated: .unknown)
    public static let NewSearchButtonLabel = MZLocalizedString("TodayWidget.NewSearchButtonLabelV1", tableName: "Today", value: "Search in Firefox", comment: "Open New Tab button label", lastUpdated: .unknown)
    public static let NewPrivateTabButtonLabelV2 = MZLocalizedString("TodayWidget.NewPrivateTabButtonLabelV2", tableName: "Today", value: "Search in Private Tab", comment: "Open New Private Tab button label for medium size action", lastUpdated: .unknown)
    public static let GoToCopiedLinkLabel = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV1", tableName: "Today", value: "Go to copied link", comment: "Go to link pasted on the clipboard", lastUpdated: .unknown)
    public static let GoToCopiedLinkLabelV2 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV2", tableName: "Today", value: "Go to\nCopied Link", comment: "Go to copied link", lastUpdated: .unknown)
    public static let GoToCopiedLinkLabelV3 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV3", tableName: "Today", value: "Go to Copied Link", comment: "Go To Copied Link text pasted on the clipboard but this string doesn't have new line character", lastUpdated: .unknown)
    public static let ClosePrivateTab = MZLocalizedString("TodayWidget.ClosePrivateTabsButton", tableName: "Today", value: "Close Private Tabs", comment: "Close Private Tabs button label", lastUpdated: .unknown)

    // Quick Action - Medium Size - Gallery View
    public static let FirefoxShortcutGalleryDescription = MZLocalizedString("TodayWidget.FirefoxShortcutGalleryDescription", tableName: "Today", value: "Add Firefox shortcuts to your Home screen.", comment: "Description for medium size widget to add Firefox Shortcut to home screen", lastUpdated: .unknown)

    // Quick Action - Small Size Widget
    public static let SearchInFirefoxTitle = MZLocalizedString("TodayWidget.SearchInFirefoxTitle", tableName: "Today", value: "Search in Firefox", comment: "Title for small size widget which allows users to search in Firefox. Do not translate the word Firefox.", lastUpdated: .unknown)
    public static let SearchInPrivateTabLabelV2 = MZLocalizedString("TodayWidget.SearchInPrivateTabLabelV2", tableName: "Today", value: "Search in\nPrivate Tab", comment: "Search in private tab", lastUpdated: .unknown)
    public static let SearchInFirefoxV2 = MZLocalizedString("TodayWidget.SearchInFirefoxV2", tableName: "Today", value: "Search in\nFirefox", comment: "Search in Firefox. Do not translate the word Firefox", lastUpdated: .unknown)
    public static let ClosePrivateTabsLabelV2 = MZLocalizedString("TodayWidget.ClosePrivateTabsLabelV2", tableName: "Today", value: "Close\nPrivate Tabs", comment: "Close Private Tabs", lastUpdated: .unknown)
    public static let ClosePrivateTabsLabelV3 = MZLocalizedString("TodayWidget.ClosePrivateTabsLabelV3", tableName: "Today", value: "Close\nPrivate\nTabs", comment: "Close Private Tabs", lastUpdated: .unknown)
    public static let GoToCopiedLinkLabelV4 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV4", tableName: "Today", value: "Go to\nCopied\nLink", comment: "Go to copied link", lastUpdated: .unknown)

    // Quick Action - Small Size Widget - Edit Mode
    public static let QuickActionDescription = MZLocalizedString("TodayWidget.QuickActionDescription", tableName: "Today", value: "Select a Firefox shortcut to add to your Home screen.", comment: "Quick action description when widget enters edit mode", lastUpdated: .unknown)
    public static let QuickActionDropDownMenu = MZLocalizedString("TodayWidget.QuickActionDropDownMenu", tableName: "Today", value: "Quick action", comment: "Quick Actions left label text for dropdown menu when widget enters edit mode", lastUpdated: .unknown)
    public static let DropDownMenuItemNewSearch = MZLocalizedString("TodayWidget.DropDownMenuItemNewSearch", tableName: "Today", value: "New Search", comment: "Quick Actions drop down menu item for new search when widget enters edit mode and drop down menu expands", lastUpdated: .unknown)
    public static let DropDownMenuItemNewPrivateSearch = MZLocalizedString("TodayWidget.DropDownMenuItemNewPrivateSearch", tableName: "Today", value: "New Private Search", comment: "Quick Actions drop down menu item for new private search when widget enters edit mode and drop down menu expands", lastUpdated: .unknown)
    public static let DropDownMenuItemGoToCopiedLink = MZLocalizedString("TodayWidget.DropDownMenuItemGoToCopiedLink", tableName: "Today", value: "Go to Copied Link", comment: "Quick Actions drop down menu item for Go to Copied Link when widget enters edit mode and drop down menu expands", lastUpdated: .unknown)
    public static let DropDownMenuItemClearPrivateTabs = MZLocalizedString("TodayWidget.DropDownMenuItemClearPrivateTabs", tableName: "Today", value: "Clear Private Tabs", comment: "Quick Actions drop down menu item for lear Private Tabs when widget enters edit mode and drop down menu expands", lastUpdated: .unknown)

    // Quick Action - Small Size - Gallery View
    public static let QuickActionGalleryDescription = MZLocalizedString("TodayWidget.QuickActionGalleryDescription", tableName: "Today", value: "Add a Firefox shortcut to your Home screen. After adding the widget, touch and hold to edit it and select a different shortcut.", comment: "Description for small size widget to add it to home screen", lastUpdated: .unknown)

    // Top Sites - Medium Size Widget
    public static let TopSitesSubLabel = MZLocalizedString("TodayWidget.TopSitesSubLabel", tableName: "Today", value: "Firefox - Top Sites", comment: "Sub label for Top Sites widget", lastUpdated: .unknown)
    public static let TopSitesSubLabel2 = MZLocalizedString("TodayWidget.TopSitesSubLabel2", tableName: "Today", value: "Firefox - Website Shortcuts", comment: "Sub label for Shortcuts widget", lastUpdated: .unknown)

    // Top Sites - Medium Size - Gallery View
    public static let TopSitesGalleryTitle = MZLocalizedString("TodayWidget.TopSitesGalleryTitle", tableName: "Today", value: "Top Sites", comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen", lastUpdated: .unknown)
    public static let TopSitesGalleryTitleV2 = MZLocalizedString("TodayWidget.TopSitesGalleryTitleV2", tableName: "Today", value: "Website Shortcuts", comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen", lastUpdated: .unknown)
    public static let TopSitesGalleryDescription = MZLocalizedString("TodayWidget.TopSitesGalleryDescription", tableName: "Today", value: "Add shortcuts to frequently and recently visited sites.", comment: "Description for top sites widget to add Firefox top sites shotcuts to home screen", lastUpdated: .unknown)

    // Quick View Open Tabs - Medium Size Widget
    public static let QuickViewOpenTabsSubLabel = MZLocalizedString("TodayWidget.QuickViewOpenTabsSubLabel", tableName: "Today", value: "Firefox - Open Tabs", comment: "Sub label for Top Sites widget", lastUpdated: .unknown)
    public static let MoreTabsLabel = MZLocalizedString("TodayWidget.MoreTabsLabel", tableName: "Today", value: "+%d More…", comment: "%d represents number and it becomes something like +5 more where 5 is the number of open tabs in tab tray beyond what is displayed in the widget", lastUpdated: .unknown)
    public static let OpenFirefoxLabel = MZLocalizedString("TodayWidget.OpenFirefoxLabel", tableName: "Today", value: "Open Firefox", comment: "Open Firefox when there are no tabs opened in tab tray i.e. Empty State", lastUpdated: .unknown)
    public static let NoOpenTabsLabel = MZLocalizedString("TodayWidget.NoOpenTabsLabel", tableName: "Today", value: "No open tabs.", comment: "Label that is shown when there are no tabs opened in tab tray i.e. Empty State", lastUpdated: .unknown)
    public static let NoOpenTabsLabelV2 = MZLocalizedString("TodayWidget.NoOpenTabsLabelV2", tableName: "Today", value: "No Open Tabs", comment: "Label that is shown when there are no tabs opened in tab tray i.e. Empty State", lastUpdated: .unknown)


    // Quick View Open Tabs - Medium Size - Gallery View
    public static let QuickViewGalleryTitle = MZLocalizedString("TodayWidget.QuickViewGalleryTitle", tableName: "Today", value: "Quick View", comment: "Title for Quick View widget in Gallery View where user can add it to home screen", lastUpdated: .unknown)
    public static let QuickViewGalleryDescription = MZLocalizedString("TodayWidget.QuickViewGalleryDescription", tableName: "Today", value: "Access your open tabs directly on your homescreen.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen", lastUpdated: .unknown)
    public static let QuickViewGalleryDescriptionV2 = MZLocalizedString("TodayWidget.QuickViewGalleryDescriptionV2", tableName: "Today", value: "Add shortcuts to your open tabs.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen", lastUpdated: .unknown)
    public static let ViewMore = MZLocalizedString("TodayWidget.ViewMore", tableName: "Today", value: "View More", comment: "View More for Quick View widget in Gallery View where we don't know how many tabs might be opened", lastUpdated: .unknown)

    // Quick View Open Tabs - Large Size - Gallery View
    public static let QuickViewLargeGalleryDescription = MZLocalizedString("TodayWidget.QuickViewLargeGalleryDescription", tableName: "Today", value: "Add shortcuts to your open tabs.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen", lastUpdated: .unknown)

    // Pocket - Large - Medium Size Widget
    public static let PocketWidgetSubLabel = MZLocalizedString("TodayWidget.PocketWidgetSubLabel", tableName: "Today", value: "Firefox - Recommended by Pocket", comment: "Sub label for medium size Firefox Pocket stories widge widget. Pocket is the name of another app.", lastUpdated: .unknown)
    public static let ViewMoreDots = MZLocalizedString("TodayWidget.ViewMoreDots", tableName: "Today", value: "View More…", comment: "View More… for Firefox Pocket stories widget where we don't know how many articles are available.", lastUpdated: .unknown)

    // Pocket - Large - Medium Size - Gallery View
    public static let PocketWidgetGalleryTitle = MZLocalizedString("TodayWidget.PocketWidgetTitle", tableName: "Today", value: "Recommended by Pocket", comment: "Title for Firefox Pocket stories widget in Gallery View where user can add it to home screen. Pocket is the name of another app.", lastUpdated: .unknown)
    public static let PocketWidgetGalleryDescription = MZLocalizedString("TodayWidget.PocketWidgetGalleryDescription", tableName: "Today", value: "Discover fascinating and thought-provoking stories from across the web, curated by Pocket.", comment: "Description for Firefox Pocket stories widget in Gallery View where user can add it to home screen. Pocket is the name of another app.", lastUpdated: .unknown)
}

// MARK: - Default Browser
extension String {
    public static let DefaultBrowserCardTitle = MZLocalizedString("DefaultBrowserCard.Title", tableName: "Default Browser", value: "Switch Your Default Browser", comment: "Title for small card shown that allows user to switch their default browser to Firefox.", lastUpdated: .unknown)
    public static let DefaultBrowserCardDescription = MZLocalizedString("DefaultBrowserCard.Description", tableName: "Default Browser", value: "Set links from websites, emails, and Messages to open automatically in Firefox.", comment: "Description for small card shown that allows user to switch their default browser to Firefox.", lastUpdated: .unknown)
    public static let DefaultBrowserCardButton = MZLocalizedString("DefaultBrowserCard.Button.v2", tableName: "Default Browser", value: "Learn How", comment: "Button string to learn how to set your default browser.", lastUpdated: .unknown)
    public static let DefaultBrowserMenuItem = MZLocalizedString("Settings.DefaultBrowserMenuItem", tableName: "Default Browser", value: "Set as Default Browser", comment: "Menu option for setting Firefox as default browser.", lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingScreenshot = MZLocalizedString("DefaultBrowserOnboarding.Screenshot", tableName: "Default Browser", value: "Default Browser App", comment: "Text for the screenshot of the iOS system settings page for Firefox.", lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep1 = MZLocalizedString("DefaultBrowserOnboarding.Description1", tableName: "Default Browser", value: "1. Go to Settings", comment: "Description for default browser onboarding card.", lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep2 = MZLocalizedString("DefaultBrowserOnboarding.Description2", tableName: "Default Browser", value: "2. Tap Default Browser App", comment: "Description for default browser onboarding card.", lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep3 = MZLocalizedString("DefaultBrowserOnboarding.Description3", tableName: "Default Browser", value: "3. Select Firefox", comment: "Description for default browser onboarding card.", lastUpdated: .unknown)
    public static let DefaultBrowserOnboardingButton = MZLocalizedString("DefaultBrowserOnboarding.Button", tableName: "Default Browser", value: "Go to Settings", comment: "Button string to open settings that allows user to switch their default browser to Firefox.", lastUpdated: .unknown)
}

// MARK: - FxAWebViewController
extension String {
    public static let FxAWebContentAccessibilityLabel = MZLocalizedString("Web content", comment: "Accessibility label for the main web content view", lastUpdated: .unknown)
}

// MARK: - QuickActions
extension String {
    public static let QuickActionsLastBookmarkTitle = MZLocalizedString("Open Last Bookmark", tableName: "3DTouchActions", comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch", lastUpdated: .unknown)
}

// MARK: - CrashOptInAlert
extension String {
    public static let CrashOptInAlertTitle = MZLocalizedString("Oops! Firefox crashed", comment: "Title for prompt displayed to user after the app crashes", lastUpdated: .unknown)
    public static let CrashOptInAlertMessage = MZLocalizedString("Send a crash report so Mozilla can fix the problem?", comment: "Message displayed in the crash dialog above the buttons used to select when sending reports", lastUpdated: .unknown)
    public static let CrashOptInAlertSend = MZLocalizedString("Send Report", comment: "Used as a button label for crash dialog prompt", lastUpdated: .unknown)
    public static let CrashOptInAlertAlwaysSend = MZLocalizedString("Always Send", comment: "Used as a button label for crash dialog prompt", lastUpdated: .unknown)
    public static let CrashOptInAlertDontSend = MZLocalizedString("Don’t Send", comment: "Used as a button label for crash dialog prompt", lastUpdated: .unknown)
}

// MARK: - RestoreTabsAlert
extension String {
    public static let RestoreTabsAlertTitle = MZLocalizedString("Well, this is embarrassing.", comment: "Restore Tabs Prompt Title", lastUpdated: .unknown)
    public static let RestoreTabsAlertMessage = MZLocalizedString("Looks like Firefox crashed previously. Would you like to restore your tabs?", comment: "Restore Tabs Prompt Description", lastUpdated: .unknown)
    public static let RestoreTabsAlertNo = MZLocalizedString("No", comment: "Restore Tabs Negative Action", lastUpdated: .unknown)
    public static let RestoreTabsAlertOkay = MZLocalizedString("Okay", comment: "Restore Tabs Affirmative Action", lastUpdated: .unknown)
}

// MARK: - ClearPrivateDataAlert
extension String {
    public static let ClearPrivateDataAlertMessage = MZLocalizedString("This action will clear all of your private data. It cannot be undone.", tableName: "ClearPrivateDataConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.", lastUpdated: .unknown)
    public static let ClearPrivateDataAlertCancel = MZLocalizedString("Cancel", tableName: "ClearPrivateDataConfirm", comment: "The cancel button when confirming clear private data.", lastUpdated: .unknown)
    public static let ClearPrivateDataAlertOk = MZLocalizedString("OK", tableName: "ClearPrivateDataConfirm", comment: "The button that clears private data.", lastUpdated: .unknown)
}

// MARK: - ClearWebsiteDataAlert
extension String {
    public static let ClearAllWebsiteDataAlertMessage = MZLocalizedString("Settings.WebsiteData.ConfirmPrompt", value: "This action will clear all of your website data. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.", lastUpdated: .unknown)
    public static let ClearSelectedWebsiteDataAlertMessage = MZLocalizedString("Settings.WebsiteData.SelectedConfirmPrompt", value: "This action will clear the selected items. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear some of their private data.", lastUpdated: .unknown)
    // TODO: these look like the same as in ClearPrivateDataAlert, I think we can remove them
    public static let ClearWebsiteDataAlertCancel = MZLocalizedString("Cancel", tableName: "ClearPrivateDataConfirm", comment: "The cancel button when confirming clear private data.", lastUpdated: .unknown)
    public static let ClearWebsiteDataAlertOk = MZLocalizedString("OK", tableName: "ClearPrivateDataConfirm", comment: "The button that clears private data.", lastUpdated: .unknown)
}

// MARK: - ClearSyncedHistoryAlert
extension String {
    public static let ClearSyncedHistoryAlertMessage = MZLocalizedString("This action will clear all of your private data, including history from your synced devices.", tableName: "ClearHistoryConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.", lastUpdated: .unknown)
    // TODO: these look like the same as in ClearPrivateDataAlert, I think we can remove them
    public static let ClearSyncedHistoryAlertCancel = MZLocalizedString("Cancel", tableName: "ClearHistoryConfirm", comment: "The cancel button when confirming clear history.", lastUpdated: .unknown)
    public static let ClearSyncedHistoryAlertOk = MZLocalizedString("OK", tableName: "ClearHistoryConfirm", comment: "The confirmation button that clears history even when Sync is connected.", lastUpdated: .unknown)
}

// MARK: - DeleteLoginAlert
extension String {
    public static let DeleteLoginAlertTitle = MZLocalizedString("Are you sure?", tableName: "LoginManager", comment: "Prompt title when deleting logins", lastUpdated: .unknown)
    public static let DeleteLoginAlertSyncedMessage = MZLocalizedString("Logins will be removed from all connected devices.", tableName: "LoginManager", comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices", lastUpdated: .unknown)
    public static let DeleteLoginAlertLocalMessage = MZLocalizedString("Logins will be permanently removed.", tableName: "LoginManager", comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them", lastUpdated: .unknown)
    public static let DeleteLoginAlertCancel = MZLocalizedString("Cancel", tableName: "LoginManager", comment: "Prompt option for cancelling out of deletion", lastUpdated: .unknown)
    public static let DeleteLoginAlertDelete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.", lastUpdated: .unknown)
}

// MARK: - Strings used in multiple areas within the Authentication Manager
extension String {
    public static let AuthenticationEnterPasscode = MZLocalizedString("Enter passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when changing the existing passcode", lastUpdated: .unknown)
    public static let AuthenticationLoginsTouchReason = MZLocalizedString("Use your fingerprint to access Logins now.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when accessing logins", lastUpdated: .unknown)
}

// MARK: - Authenticator strings
extension String {
    public static let AuthenticatorCancel = MZLocalizedString("Cancel", comment: "Label for Cancel button", lastUpdated: .unknown)
    public static let AuthenticatorLogin = MZLocalizedString("Log in", comment: "Authentication prompt log in button", lastUpdated: .unknown)
    public static let AuthenticatorPromptTitle = MZLocalizedString("Authentication required", comment: "Authentication prompt title", lastUpdated: .unknown)
    public static let AuthenticatorPromptRealmMessage = MZLocalizedString("A username and password are being requested by %@. The site says: %@", comment: "Authentication prompt message with a realm. First parameter is the hostname. Second is the realm string", lastUpdated: .unknown)
    public static let AuthenticatorPromptEmptyRealmMessage = MZLocalizedString("A username and password are being requested by %@.", comment: "Authentication prompt message with no realm. Parameter is the hostname of the site", lastUpdated: .unknown)
    public static let AuthenticatorUsernamePlaceholder = MZLocalizedString("Username", comment: "Username textbox in Authentication prompt", lastUpdated: .unknown)
    public static let AuthenticatorPasswordPlaceholder = MZLocalizedString("Password", comment: "Password textbox in Authentication prompt", lastUpdated: .unknown)
}

// MARK: - BrowserViewController
extension String {
    public static let ReaderModeAddPageGeneralErrorAccessibilityLabel = MZLocalizedString("Could not add page to Reading list", comment: "Accessibility message e.g. spoken by VoiceOver after adding current webpage to the Reading List failed.", lastUpdated: .unknown)
    public static let ReaderModeAddPageSuccessAcessibilityLabel = MZLocalizedString("Added page to Reading List", comment: "Accessibility message e.g. spoken by VoiceOver after the current page gets added to the Reading List using the Reader View button, e.g. by long-pressing it or by its accessibility custom action.", lastUpdated: .unknown)
    public static let ReaderModeAddPageMaybeExistsErrorAccessibilityLabel = MZLocalizedString("Could not add page to Reading List. Maybe it’s already there?", comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures.", lastUpdated: .unknown)
    public static let WebViewAccessibilityLabel = MZLocalizedString("Web content", comment: "Accessibility label for the main web content view", lastUpdated: .unknown)
}

// MARK: - Find in page
extension String {
    public static let FindInPagePreviousAccessibilityLabel = MZLocalizedString("Previous in-page result", tableName: "FindInPage", comment: "Accessibility label for previous result button in Find in Page Toolbar.", lastUpdated: .unknown)
    public static let FindInPageNextAccessibilityLabel = MZLocalizedString("Next in-page result", tableName: "FindInPage", comment: "Accessibility label for next result button in Find in Page Toolbar.", lastUpdated: .unknown)
    public static let FindInPageDoneAccessibilityLabel = MZLocalizedString("Done", tableName: "FindInPage", comment: "Done button in Find in Page Toolbar.", lastUpdated: .unknown)
}

// MARK: - Reader Mode Bar
extension String {
    public static let ReaderModeBarMarkAsRead = MZLocalizedString("Mark as Read", comment: "Name for Mark as read button in reader mode", lastUpdated: .unknown)
    public static let ReaderModeBarMarkAsUnread = MZLocalizedString("Mark as Unread", comment: "Name for Mark as unread button in reader mode", lastUpdated: .unknown)
    public static let ReaderModeBarSettings = MZLocalizedString("Display Settings", comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.", lastUpdated: .unknown)
    public static let ReaderModeBarAddToReadingList = MZLocalizedString("Add to Reading List", comment: "Name for button adding current article to reading list in reader mode", lastUpdated: .unknown)
    public static let ReaderModeBarRemoveFromReadingList = MZLocalizedString("Remove from Reading List", comment: "Name for button removing current article from reading list in reader mode", lastUpdated: .unknown)
}

// MARK: - SearchViewController
extension String {
    public static let SearchSettingsAccessibilityLabel = MZLocalizedString("Search Settings", tableName: "Search", comment: "Label for search settings button.", lastUpdated: .unknown)
    public static let SearchSearchEngineAccessibilityLabel = MZLocalizedString("%@ search", tableName: "Search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine.", lastUpdated: .unknown)
    public static let SearchSearchEngineSuggestionAccessibilityLabel = MZLocalizedString("Search suggestions from %@", tableName: "Search", comment: "Accessibility label for image of default search engine displayed left to the actual search suggestions from the engine. The parameter substituted for \"%@\" is the name of the search engine. E.g.: Search suggestions from Google", lastUpdated: .unknown)
    public static let SearchSearchSuggestionTapAccessibilityHint = MZLocalizedString("Searches for the suggestion", comment: "Accessibility hint describing the action performed when a search suggestion is clicked", lastUpdated: .unknown)
    public static let SearchSuggestionCellSwitchToTabLabel = MZLocalizedString("Search.Awesomebar.SwitchToTab", value: "Switch to tab", comment: "Search suggestion cell label that allows user to switch to tab which they searched for in url bar", lastUpdated: .unknown)
}

// MARK: - Tab Location View
extension String {
    public static let TabLocationURLPlaceholder = MZLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home", lastUpdated: .unknown)
    public static let TabLocationLockIconAccessibilityLabel = MZLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure", lastUpdated: .unknown)
    public static let TabLocationReaderModeAccessibilityLabel = MZLocalizedString("Reader View", comment: "Accessibility label for the Reader View button", lastUpdated: .unknown)
    public static let TabLocationReaderModeAddToReadingListAccessibilityLabel = MZLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list.", lastUpdated: .unknown)
    public static let TabLocationReloadAccessibilityLabel = MZLocalizedString("Reload page", comment: "Accessibility label for the reload button", lastUpdated: .unknown)
    public static let TabLocationPageOptionsAccessibilityLabel = MZLocalizedString("Page Options Menu", comment: "Accessibility label for the Page Options menu button", lastUpdated: .unknown)
}

// MARK: - TabPeekViewController
extension String {
    public static let TabPeekAddToBookmarks = MZLocalizedString("Add to Bookmarks", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks", lastUpdated: .unknown)
    public static let TabPeekCopyUrl = MZLocalizedString("Copy URL", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard", lastUpdated: .unknown)
    public static let TabPeekCloseTab = MZLocalizedString("Close Tab", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to close the current tab", lastUpdated: .unknown)
    public static let TabPeekPreviewAccessibilityLabel = MZLocalizedString("Preview of %@", tableName: "3DTouchActions", comment: "Accessibility label, associated to the 3D Touch action on the current tab in the tab tray, used to display a larger preview of the tab.", lastUpdated: .unknown)
}

// MARK: - Tab Toolbar
extension String {
    public static let TabToolbarReloadAccessibilityLabel = MZLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button", lastUpdated: .unknown)
    public static let TabToolbarStopAccessibilityLabel = MZLocalizedString("Stop", comment: "Accessibility Label for the tab toolbar Stop button", lastUpdated: .unknown)
    public static let TabToolbarSearchAccessibilityLabel = MZLocalizedString("Search", comment: "Accessibility Label for the tab toolbar Search button", lastUpdated: .unknown)
    public static let TabToolbarNewTabAccessibilityLabel = MZLocalizedString("New Tab", comment: "Accessibility Label for the tab toolbar New tab button", lastUpdated: .unknown)
    public static let TabToolbarBackAccessibilityLabel = MZLocalizedString("Back", comment: "Accessibility label for the Back button in the tab toolbar.", lastUpdated: .unknown)
    public static let TabToolbarForwardAccessibilityLabel = MZLocalizedString("Forward", comment: "Accessibility Label for the tab toolbar Forward button", lastUpdated: .unknown)
    public static let TabToolbarHomeAccessibilityLabel = MZLocalizedString("Home", comment: "Accessibility label for the tab toolbar indicating the Home button.", lastUpdated: .unknown)
    public static let TabToolbarNavigationToolbarAccessibilityLabel = MZLocalizedString("Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.", lastUpdated: .unknown)
}

// MARK: - Tab Tray v1
extension String {
    public static let TabTrayToggleAccessibilityLabel = MZLocalizedString("Private Mode", tableName: "PrivateBrowsing", comment: "Accessibility label for toggling on/off private mode", lastUpdated: .unknown)
    public static let TabTrayToggleAccessibilityHint = MZLocalizedString("Turns private mode on or off", tableName: "PrivateBrowsing", comment: "Accessiblity hint for toggling on/off private mode", lastUpdated: .unknown)
    public static let TabTrayToggleAccessibilityValueOn = MZLocalizedString("On", tableName: "PrivateBrowsing", comment: "Toggled ON accessibility value", lastUpdated: .unknown)
    public static let TabTrayToggleAccessibilityValueOff = MZLocalizedString("Off", tableName: "PrivateBrowsing", comment: "Toggled OFF accessibility value", lastUpdated: .unknown)
    public static let TabTrayViewAccessibilityLabel = MZLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.", lastUpdated: .unknown)
    public static let TabTrayNoTabsAccessibilityHint = MZLocalizedString("No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray", lastUpdated: .unknown)
    public static let TabTrayVisibleTabRangeAccessibilityHint = MZLocalizedString("Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.", lastUpdated: .unknown)
    public static let TabTrayVisiblePartialRangeAccessibilityHint = MZLocalizedString("Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.", lastUpdated: .unknown)
    public static let TabTrayClosingTabAccessibilityMessage =  MZLocalizedString("Closing tab", comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed.", lastUpdated: .unknown)
    public static let TabTrayCloseAllTabsPromptCancel = MZLocalizedString("Cancel", comment: "Label for Cancel button", lastUpdated: .unknown)
    public static let TabTrayPrivateLearnMore = MZLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode", lastUpdated: .unknown)
    public static let TabTrayPrivateBrowsingTitle = MZLocalizedString("Private Browsing", tableName: "PrivateBrowsing", comment: "Title displayed for when there are no open tabs while in private mode", lastUpdated: .unknown)
    public static let TabTrayPrivateBrowsingDescription =  MZLocalizedString("Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.", tableName: "PrivateBrowsing", comment: "Description text displayed when there are no open tabs while in private mode", lastUpdated: .unknown)
    public static let TabTrayAddTabAccessibilityLabel = MZLocalizedString("Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.", lastUpdated: .unknown)
    public static let TabTrayCloseAccessibilityCustomAction = MZLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)", lastUpdated: .unknown)
    public static let TabTraySwipeToCloseAccessibilityHint = MZLocalizedString("Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.", lastUpdated: .unknown)
    public static let TabTrayCurrentlySelectedTabAccessibilityLabel = MZLocalizedString("TabTray.CurrentSelectedTab.A11Y", value: "Currently selected tab.", comment: "Accessibility label for the currently selected tab.", lastUpdated: .unknown)
    public static let TabTrayOtherTabsSectionHeader = MZLocalizedString("TabTray.Header.FilteredTabs.SectionHeader", value: "Others", comment: "In the tab tray, when tab groups appear and there exist tabs that don't belong to any group, those tabs are listed under this header as \"Others\"", lastUpdated: .unknown)
}

// MARK: - URL Bar
extension String {
    public static let URLBarLocationAccessibilityLabel = MZLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.", lastUpdated: .unknown)
}

// MARK: - Error Pages
extension String {
    public static let ErrorPageTryAgain = MZLocalizedString("Try again", tableName: "ErrorPages", comment: "Shown in error pages on a button that will try to load the page again", lastUpdated: .unknown)
    public static let ErrorPageOpenInSafari = MZLocalizedString("Open in Safari", tableName: "ErrorPages", comment: "Shown in error pages for files that can't be shown and need to be downloaded.", lastUpdated: .unknown)
}

// MARK: - LibraryPanel
extension String {
    public static let LibraryPanelBookmarksAccessibilityLabel = MZLocalizedString("Bookmarks", comment: "Panel accessibility label", lastUpdated: .unknown)
    public static let LibraryPanelHistoryAccessibilityLabel = MZLocalizedString("History", comment: "Panel accessibility label", lastUpdated: .unknown)
    public static let LibraryPanelReadingListAccessibilityLabel = MZLocalizedString("Reading list", comment: "Panel accessibility label", lastUpdated: .unknown)
    public static let LibraryPanelDownloadsAccessibilityLabel = MZLocalizedString("Downloads", comment: "Panel accessibility label", lastUpdated: .unknown)
    public static let LibraryPanelSyncedTabsAccessibilityLabel = MZLocalizedString("Synced Tabs", comment: "Panel accessibility label", lastUpdated: .unknown)
}

// MARK: - LibraryViewController
extension String {
    public static let LibraryPanelChooserAccessibilityLabel = MZLocalizedString("Panel Chooser", comment: "Accessibility label for the Library panel's bottom toolbar containing a list of the home panels (top sites, bookmarks, history, remote tabs, reading list).", lastUpdated: .unknown)
}

// MARK: - ReaderPanel
extension String {
    public static let ReaderPanelRemove = MZLocalizedString("Remove", comment: "Title for the button that removes a reading list item", lastUpdated: .unknown)
    public static let ReaderPanelMarkAsRead = MZLocalizedString("Mark as Read", comment: "Title for the button that marks a reading list item as read", lastUpdated: .unknown)
    public static let ReaderPanelMarkAsUnread =  MZLocalizedString("Mark as Unread", comment: "Title for the button that marks a reading list item as unread", lastUpdated: .unknown)
    public static let ReaderPanelUnreadAccessibilityLabel = MZLocalizedString("unread", comment: "Accessibility label for unread article in reading list. It's a past participle - functions as an adjective.", lastUpdated: .unknown)
    public static let ReaderPanelReadAccessibilityLabel = MZLocalizedString("read", comment: "Accessibility label for read article in reading list. It's a past participle - functions as an adjective.", lastUpdated: .unknown)
    public static let ReaderPanelWelcome = MZLocalizedString("Welcome to your Reading List", comment: "See http://mzl.la/1LXbDOL", lastUpdated: .unknown)
    public static let ReaderPanelReadingModeDescription = MZLocalizedString("Open articles in Reader View by tapping the book icon when it appears in the title bar.", comment: "See http://mzl.la/1LXbDOL", lastUpdated: .unknown)
    public static let ReaderPanelReadingListDescription = MZLocalizedString("Save pages to your Reading List by tapping the book plus icon in the Reader View controls.", comment: "See http://mzl.la/1LXbDOL", lastUpdated: .unknown)
}

// MARK: - Remote Tabs Panel
extension String {
    // Backup and active strings added in Bug 1205294.
    public static let RemoteTabEmptyStateInstructionsSyncTabsPasswordsBookmarksString = MZLocalizedString("Sync your tabs, bookmarks, passwords and more.", comment: "Text displayed when the Sync home panel is empty, describing the features provided by Sync to invite the user to log in.", lastUpdated: .unknown)
    public static let RemoteTabEmptyStateInstructionsSyncTabsPasswordsString = MZLocalizedString("Sync your tabs, passwords and more.", comment: "Text displayed when the Sync home panel is empty, describing the features provided by Sync to invite the user to log in.", lastUpdated: .unknown)
    public static let RemoteTabEmptyStateInstructionsGetTabsBookmarksPasswordsString = MZLocalizedString("Get your open tabs, bookmarks, and passwords from your other devices.", comment: "A re-worded offer about Sync, displayed when the Sync home panel is empty, that emphasizes one-way data transfer, not syncing.", lastUpdated: .unknown)

    public static let RemoteTabErrorNoTabs = MZLocalizedString("You don’t have any tabs open in Firefox on your other devices.", comment: "Error message in the remote tabs panel", lastUpdated: .unknown)
    public static let RemoteTabErrorFailedToSync = MZLocalizedString("There was a problem accessing tabs from your other devices. Try again in a few moments.", comment: "Error message in the remote tabs panel", lastUpdated: .unknown)
    public static let RemoteTabLastSync = MZLocalizedString("Last synced: %@", comment: "Remote tabs last synced time. Argument is the relative date string.", lastUpdated: .unknown)
    public static let RemoteTabComputerAccessibilityLabel = MZLocalizedString("computer", comment: "Accessibility label for Desktop Computer (PC) image in remote tabs list", lastUpdated: .unknown)
    public static let RemoteTabMobileAccessibilityLabel =  MZLocalizedString("mobile device", comment: "Accessibility label for Mobile Device image in remote tabs list", lastUpdated: .unknown)
    public static let RemoteTabCreateAccount = MZLocalizedString("Create an account", comment: "See http://mzl.la/1Qtkf0j", lastUpdated: .unknown)
}

// MARK: - Login list
extension String {
    public static let LoginListDeselctAll = MZLocalizedString("Deselect All", tableName: "LoginManager", comment: "Label for the button used to deselect all logins.", lastUpdated: .unknown)
    public static let LoginListSelctAll = MZLocalizedString("Select All", tableName: "LoginManager", comment: "Label for the button used to select all logins.", lastUpdated: .unknown)
    public static let LoginListDelete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.", lastUpdated: .unknown)
}

// MARK: - Login Detail
extension String {
    public static let LoginDetailUsername = MZLocalizedString("Username", tableName: "LoginManager", comment: "Label displayed above the username row in Login Detail View.", lastUpdated: .unknown)
    public static let LoginDetailPassword = MZLocalizedString("Password", tableName: "LoginManager", comment: "Label displayed above the password row in Login Detail View.", lastUpdated: .unknown)
    public static let LoginDetailWebsite = MZLocalizedString("Website", tableName: "LoginManager", comment: "Label displayed above the website row in Login Detail View.", lastUpdated: .unknown)
    public static let LoginDetailCreatedAt =  MZLocalizedString("Created %@", tableName: "LoginManager", comment: "Label describing when the current login was created with the timestamp as the parameter.", lastUpdated: .unknown)
    public static let LoginDetailModifiedAt = MZLocalizedString("Modified %@", tableName: "LoginManager", comment: "Label describing when the current login was last modified with the timestamp as the parameter.", lastUpdated: .unknown)
    public static let LoginDetailDelete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.", lastUpdated: .unknown)
}

// MARK: - No Logins View
extension String {
    public static let NoLoginsFound = MZLocalizedString("No logins found", tableName: "LoginManager", comment: "Label displayed when no logins are found after searching.", lastUpdated: .unknown)
}

// MARK: - Reader Mode Handler
extension String {
    public static let ReaderModeHandlerLoadingContent = MZLocalizedString("Loading content…", comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Firefox reader mode from another app.", lastUpdated: .unknown)
    public static let ReaderModeHandlerPageCantDisplay = MZLocalizedString("The page could not be displayed in Reader View.", comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.", lastUpdated: .unknown)
    public static let ReaderModeHandlerLoadOriginalPage = MZLocalizedString("Load original page", comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.", lastUpdated: .unknown)
    public static let ReaderModeHandlerError = MZLocalizedString("There was an error converting the page", comment: "Error displayed when reader mode cannot be enabled", lastUpdated: .unknown)
}

// MARK: - ReaderModeStyle
extension String {
    public static let ReaderModeStyleBrightnessAccessibilityLabel = MZLocalizedString("Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings", lastUpdated: .unknown)
    public static let ReaderModeStyleFontTypeAccessibilityLabel = MZLocalizedString("Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings", lastUpdated: .unknown)
    public static let ReaderModeStyleSansSerifFontType = MZLocalizedString("Sans-serif", comment: "Font type setting in the reading view settings", lastUpdated: .unknown)
    public static let ReaderModeStyleSerifFontType = MZLocalizedString("Serif", comment: "Font type setting in the reading view settings", lastUpdated: .unknown)
    public static let ReaderModeStyleSmallerLabel = MZLocalizedString("-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.", lastUpdated: .unknown)
    public static let ReaderModeStyleSmallerAccessibilityLabel = MZLocalizedString("Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode", lastUpdated: .unknown)
    public static let ReaderModeStyleLargerLabel = MZLocalizedString("+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.", lastUpdated: .unknown)
    public static let ReaderModeStyleLargerAccessibilityLabel = MZLocalizedString("Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode", lastUpdated: .unknown)
    public static let ReaderModeStyleFontSize = MZLocalizedString("Aa", comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.", lastUpdated: .unknown)
    public static let ReaderModeStyleChangeColorSchemeAccessibilityHint = MZLocalizedString("Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings", lastUpdated: .unknown)
    public static let ReaderModeStyleLightLabel = MZLocalizedString("Light", comment: "Light theme setting in Reading View settings", lastUpdated: .unknown)
    public static let ReaderModeStyleDarkLabel = MZLocalizedString("Dark", comment: "Dark theme setting in Reading View settings", lastUpdated: .unknown)
    public static let ReaderModeStyleSepiaLabel = MZLocalizedString("Sepia", comment: "Sepia theme setting in Reading View settings", lastUpdated: .unknown)
}

// MARK: - Empty Private tab view
extension String {
    public static let PrivateBrowsingLearnMore = MZLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode", lastUpdated: .unknown)
    public static let PrivateBrowsingTitle = MZLocalizedString("Private Browsing", tableName: "PrivateBrowsing", comment: "Title displayed for when there are no open tabs while in private mode", lastUpdated: .unknown)
    public static let PrivateBrowsingDescription = MZLocalizedString("Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.", tableName: "PrivateBrowsing", comment: "Description text displayed when there are no open tabs while in private mode", lastUpdated: .unknown)
}

// MARK: - Advanced Account Setting
extension String {
    public static let AdvancedAccountUseStageServer = MZLocalizedString("Use stage servers", comment: "Debug option", lastUpdated: .unknown)
}

// MARK: - App Settings
extension String {
    public static let AppSettingsLicenses = MZLocalizedString("Licenses", comment: "Settings item that opens a tab containing the licenses. See http://mzl.la/1NSAWCG", lastUpdated: .unknown)
    public static let AppSettingsYourRights = MZLocalizedString("Your Rights", comment: "Your Rights settings section title", lastUpdated: .unknown)
    public static let AppSettingsShowTour = MZLocalizedString("Show Tour", comment: "Show the on-boarding screen again from the settings", lastUpdated: .unknown)
    public static let AppSettingsSendFeedback = MZLocalizedString("Send Feedback", comment: "Menu item in settings used to open input.mozilla.org where people can submit feedback", lastUpdated: .unknown)
    public static let AppSettingsHelp = MZLocalizedString("Help", comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ", lastUpdated: .unknown)
    public static let AppSettingsSearch = MZLocalizedString("Search", comment: "Open search section of settings", lastUpdated: .unknown)
    public static let AppSettingsPrivacyPolicy = MZLocalizedString("Privacy Policy", comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/", lastUpdated: .unknown)

    public static let AppSettingsTitle = MZLocalizedString("Settings", comment: "Title in the settings view controller title bar", lastUpdated: .unknown)
    public static let AppSettingsDone = MZLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar", lastUpdated: .unknown)
    public static let AppSettingsPrivacyTitle = MZLocalizedString("Privacy", comment: "Privacy section title", lastUpdated: .unknown)
    public static let AppSettingsBlockPopups = MZLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting", lastUpdated: .unknown)
    public static let AppSettingsClosePrivateTabsTitle = MZLocalizedString("Close Private Tabs", tableName: "PrivateBrowsing", comment: "Setting for closing private tabs", lastUpdated: .unknown)
    public static let AppSettingsClosePrivateTabsDescription = MZLocalizedString("When Leaving Private Browsing", tableName: "PrivateBrowsing", comment: "Will be displayed in Settings under 'Close Private Tabs'", lastUpdated: .unknown)
    public static let AppSettingsSupport = MZLocalizedString("Support", comment: "Support section title", lastUpdated: .unknown)
    public static let AppSettingsAbout = MZLocalizedString("About", comment: "About settings section title", lastUpdated: .unknown)
}

// MARK: - Clearables
extension String {
    // Removed Clearables as part of Bug 1226654, but keeping the string around.
    private static let removedSavedLoginsLabel = MZLocalizedString("Saved Logins", tableName: "ClearPrivateData", comment: "Settings item for clearing passwords and login data", lastUpdated: .unknown)

    public static let ClearableHistory = MZLocalizedString("Browsing History", tableName: "ClearPrivateData", comment: "Settings item for clearing browsing history", lastUpdated: .unknown)
    public static let ClearableCache = MZLocalizedString("Cache", tableName: "ClearPrivateData", comment: "Settings item for clearing the cache", lastUpdated: .unknown)
    public static let ClearableOfflineData = MZLocalizedString("Offline Website Data", tableName: "ClearPrivateData", comment: "Settings item for clearing website data", lastUpdated: .unknown)
    public static let ClearableCookies = MZLocalizedString("Cookies", tableName: "ClearPrivateData", comment: "Settings item for clearing cookies", lastUpdated: .unknown)
    public static let ClearableDownloads = MZLocalizedString("Downloaded Files", tableName: "ClearPrivateData", comment: "Settings item for deleting downloaded files", lastUpdated: .unknown)
    public static let ClearableSpotlight = MZLocalizedString("Spotlight Index", tableName: "ClearPrivateData", comment: "A settings item that allows a user to use Apple's \"Spotlight Search\" in Data Management's Website Data option to search for and select an item to delete.", lastUpdated: .unknown)
}

// MARK: - SearchEngine Picker
extension String {
    public static let SearchEnginePickerTitle = MZLocalizedString("Default Search Engine", comment: "Title for default search engine picker.", lastUpdated: .unknown)
    public static let SearchEnginePickerCancel = MZLocalizedString("Cancel", comment: "Label for Cancel button", lastUpdated: .unknown)
}

// MARK: - SearchSettings
extension String {
    public static let SearchSettingsTitle = MZLocalizedString("Search", comment: "Navigation title for search settings.", lastUpdated: .unknown)
    public static let SearchSettingsDefaultSearchEngineAccessibilityLabel = MZLocalizedString("Default Search Engine", comment: "Accessibility label for default search engine setting.", lastUpdated: .unknown)
    public static let SearchSettingsShowSearchSuggestions = MZLocalizedString("Show Search Suggestions", comment: "Label for show search suggestions setting.", lastUpdated: .unknown)
    public static let SearchSettingsDefaultSearchEngineTitle = MZLocalizedString("Default Search Engine", comment: "Title for default search engine settings section.", lastUpdated: .unknown)
    public static let SearchSettingsQuickSearchEnginesTitle = MZLocalizedString("Quick-Search Engines", comment: "Title for quick-search engines settings section.", lastUpdated: .unknown)
}

// MARK: - SettingsContent
extension String {
    public static let SettingsContentPageLoadError = MZLocalizedString("Could not load page.", comment: "Error message that is shown in settings when there was a problem loading", lastUpdated: .unknown)
}

// MARK: - SearchInput
extension String {
    public static let SearchInputAccessibilityLabel = MZLocalizedString("Search Input Field", tableName: "LoginManager", comment: "Accessibility label for the search input field in the Logins list", lastUpdated: .unknown)
    public static let SearchInputTitle = MZLocalizedString("Search", tableName: "LoginManager", comment: "Title for the search field at the top of the Logins list screen", lastUpdated: .unknown)
    public static let SearchInputClearAccessibilityLabel = MZLocalizedString("Clear Search", tableName: "LoginManager", comment: "Accessibility message e.g. spoken by VoiceOver after the user taps the close button in the search field to clear the search and exit search mode", lastUpdated: .unknown)
    public static let SearchInputEnterSearchMode = MZLocalizedString("Enter Search Mode", tableName: "LoginManager", comment: "Accessibility label for entering search mode for logins", lastUpdated: .unknown)
}

// MARK: - TabsButton
extension String {
    public static let TabsButtonShowTabsAccessibilityLabel = MZLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the (top) tab toolbar", lastUpdated: .unknown)
}

// MARK: - TabTrayButtons
extension String {
    public static let TabTrayButtonNewTabAccessibilityLabel = MZLocalizedString("New Tab", comment: "Accessibility label for the New Tab button in the tab toolbar.", lastUpdated: .unknown)
    public static let TabTrayButtonShowTabsAccessibilityLabel = MZLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the tab toolbar", lastUpdated: .unknown)
}

// MARK: - MenuHelper
extension String {
    public static let MenuHelperPasteAndGo = MZLocalizedString("UIMenuItem.PasteGo", value: "Paste & Go", comment: "The menu item that pastes the current contents of the clipboard into the URL bar and navigates to the page", lastUpdated: .unknown)
    public static let MenuHelperReveal = MZLocalizedString("Reveal", tableName: "LoginManager", comment: "Reveal password text selection menu item", lastUpdated: .unknown)
    public static let MenuHelperHide =  MZLocalizedString("Hide", tableName: "LoginManager", comment: "Hide password text selection menu item", lastUpdated: .unknown)
    public static let MenuHelperCopy = MZLocalizedString("Copy", tableName: "LoginManager", comment: "Copy password text selection menu item", lastUpdated: .unknown)
    public static let MenuHelperOpenAndFill = MZLocalizedString("Open & Fill", tableName: "LoginManager", comment: "Open and Fill website text selection menu item", lastUpdated: .unknown)
    public static let MenuHelperFindInPage = MZLocalizedString("Find in Page", tableName: "FindInPage", comment: "Text selection menu item", lastUpdated: .unknown)
    public static let MenuHelperSearchWithFirefox = MZLocalizedString("UIMenuItem.SearchWithFirefox", value: "Search with Firefox", comment: "Search in New Tab Text selection menu item", lastUpdated: .unknown)
}

// MARK: - DeviceInfo
extension String {
    public static let DeviceInfoClientNameDescription = MZLocalizedString("%@ on %@", tableName: "Shared", comment: "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs. The first argument is the app name. The second argument is the device name.", lastUpdated: .unknown)
}

// MARK: - TimeConstants
extension String {
    public static let TimeConstantMoreThanAMonth = MZLocalizedString("more than a month ago", comment: "Relative date for dates older than a month and less than two months.", lastUpdated: .unknown)
    public static let TimeConstantMoreThanAWeek = MZLocalizedString("more than a week ago", comment: "Description for a date more than a week ago, but less than a month ago.", lastUpdated: .unknown)
    public static let TimeConstantYesterday = MZLocalizedString("yesterday", comment: "Relative date for yesterday.", lastUpdated: .unknown)
    public static let TimeConstantThisWeek = MZLocalizedString("this week", comment: "Relative date for date in past week.", lastUpdated: .unknown)
    public static let TimeConstantRelativeToday = MZLocalizedString("today at %@", comment: "Relative date for date older than a minute.", lastUpdated: .unknown)
    public static let TimeConstantJustNow = MZLocalizedString("just now", comment: "Relative time for a tab that was visited within the last few moments.", lastUpdated: .unknown)
}

// MARK: - Default Suggested Site
extension String {
    public static let DefaultSuggestedFacebook = MZLocalizedString("Facebook", comment: "Tile title for Facebook", lastUpdated: .unknown)
    public static let DefaultSuggestedYouTube = MZLocalizedString("YouTube", comment: "Tile title for YouTube", lastUpdated: .unknown)
    public static let DefaultSuggestedAmazon = MZLocalizedString("Amazon", comment: "Tile title for Amazon", lastUpdated: .unknown)
    public static let DefaultSuggestedWikipedia = MZLocalizedString("Wikipedia", comment: "Tile title for Wikipedia", lastUpdated: .unknown)
    public static let DefaultSuggestedTwitter = MZLocalizedString("Twitter", comment: "Tile title for Twitter", lastUpdated: .unknown)
}

// MARK: - MR1 Strings
extension String {
    public static let AwesomeBarSearchWithEngineButtonTitle = MZLocalizedString("Awesomebar.SearchWithEngine.Title", value: "Search with %@", comment: "Title for button to suggest searching with a search engine. First argument is the name of the search engine to select", lastUpdated: .unknown)
    public static let AwesomeBarSearchWithEngineButtonDescription = MZLocalizedString("Awesomebar.SearchWithEngine.Description", value: "Search %@ directly from the address bar", comment: "Description for button to suggest searching with a search engine. First argument is the name of the search engine to select", lastUpdated: .unknown)
}

// MARK: - Credential Provider
extension String {
    public static let LoginsWelcomeViewTitle2 = MZLocalizedString("Logins.WelcomeView.Title2", value: "AutoFill Firefox Passwords", comment: "Label displaying welcome view title", lastUpdated: .unknown)
    public static let LoginsWelcomeViewTagline = MZLocalizedString("Logins.WelcomeView.Tagline", value: "Take your passwords everywhere", comment: "Label displaying welcome view tagline under the title", lastUpdated: .unknown)
    public static let LoginsWelcomeTurnOnAutoFillButtonTitle = MZLocalizedString("Logins.WelcomeView.TurnOnAutoFill", value: "Turn on AutoFill", comment: "Title of the big blue button to enable AutoFill", lastUpdated: .unknown)
    public static let LoginsListSearchCancel = MZLocalizedString("LoginsList.Search.Cancel", value: "Cancel", comment: "Title for cancel button for user to stop searching for a particular login", lastUpdated: .unknown)
    public static let LoginsListSearchPlaceholderCredential = MZLocalizedString("LoginsList.Search.Placeholder", value: "Search logins", comment: "Placeholder text for search field", lastUpdated: .unknown)
    public static let LoginsListSelectPasswordTitle = MZLocalizedString("LoginsList.SelectPassword.Title", value: "Select a password to fill", comment: "Label displaying select a password to fill instruction", lastUpdated: .unknown)
    public static let LoginsListNoMatchingResultTitle = MZLocalizedString("LoginsList.NoMatchingResult.Title", value: "No matching logins", comment: "Label displayed when a user searches and no matches can be found against the search query", lastUpdated: .unknown)
    public static let LoginsListNoMatchingResultSubtitle = MZLocalizedString("LoginsList.NoMatchingResult.Subtitle", value: "There are no results matching your search.", comment: "Label that appears after the search if there are no logins matching the search", lastUpdated: .unknown)
    public static let LoginsListNoLoginsFoundTitle = MZLocalizedString("LoginsList.NoLoginsFound.Title", value: "No logins found", comment: "Label shown when there are no logins saved", lastUpdated: .unknown)
    public static let LoginsListNoLoginsFoundDescription = MZLocalizedString("LoginsList.NoLoginsFound.Description", value: "Saved logins will show up here. If you saved your logins to Firefox on a different device, sign in to your Firefox Account.", comment: "Label shown when there are no logins to list", lastUpdated: .unknown)
    public static let LoginsPasscodeRequirementWarning = MZLocalizedString("Logins.PasscodeRequirement.Warning", value: "To use the AutoFill feature for Firefox, you must have a device passcode enabled.", comment: "Warning message shown when you try to enable or use native AutoFill without a device passcode setup", lastUpdated: .unknown)
}

// MARK: - v35 Strings
extension String {
    public static let FirefoxHomeJumpBackInSectionTitle = MZLocalizedString("ActivityStream.JumpBackIn.SectionTitle", value: "Jump Back In", comment: "Title for the Jump Back In section. This section allows users to jump back in to a recently viewed tab", lastUpdated: .unknown)
    public static let FirefoxHomeRecentlySavedSectionTitle = MZLocalizedString("ActivityStream.RecentlySaved.SectionTitle", value: "Recently Saved", comment: "Section title for the Recently Saved section. This shows websites that have had a save action. Right now it is just bookmarks but it could be used for other things like the reading list in the future.", lastUpdated: .unknown)
    public static let FirefoxHomeShowAll = MZLocalizedString("ActivityStream.RecentlySaved.ShowAll", value: "Show all", comment: "This button will open the library showing all the users bookmarks", lastUpdated: .unknown)
    public static let TabsTrayInactiveTabsSectionTitle = MZLocalizedString("TabTray.InactiveTabs.SectionTitle", value: "Inactive Tabs", comment: "Title for the inactive tabs section. This section groups all tabs that haven't been used in a while.", lastUpdated: .unknown)
    public static let TabsTrayRecentlyCloseTabsSectionTitle = MZLocalizedString("TabTray.RecentlyClosed.SectionTitle", value: "Recently closed", comment: "Title for the recently closed tabs section. This section shows a list of all the tabs that have been recently closed.", lastUpdated: .unknown)
    public static let TabsTrayRecentlyClosedTabsDescritpion = MZLocalizedString("TabTray.RecentlyClosed.Description", value: "Tabs are available here for 30 days. After that time, tabs will be automatically closed.", comment: "Describes what the Recently Closed tabs behavior is for users unfamiliar with it.", lastUpdated: .unknown)
}

// MARK: - v36 Strings
extension String {
    public static let ProtectionStatusSecure = MZLocalizedString("ProtectionStatus.Secure", value: "Connection is secure", comment: "This is the value for a label that indicates if a user is on a secure https connection.", lastUpdated: .unknown)
    public static let ProtectionStatusNotSecure = MZLocalizedString("ProtectionStatus.NotSecure", value: "Connection is not secure", comment: "This is the value for a label that indicates if a user is on an unencrypted website.", lastUpdated: .unknown)
}

extension String {
    // Customize homepage options
    public static let SettingsCustomizeHomeTitle = MZLocalizedString("Settings.Home.Option.Title", value: "Firefox Homepage", comment: "In the settings menu, this is the title of the Firefox Homepage customization settings section", lastUpdated: .v39)

    // Home screen
    public static let RecentlyVisitedRemoveButtonTitle = MZLocalizedString("ActivityStream.RecentlyVisited.RemoveButton.Title", value: "Remove", comment: "When long pressing an item in the Recently Visited section, this is the title of the button that appears, letting the user know to remove that particular item from the menu.", lastUpdated: .v39)
}
