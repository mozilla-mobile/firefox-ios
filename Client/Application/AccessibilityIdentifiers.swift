// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

/// This struct defines all the accessibility identifiers to be added to
/// screen elements for testing.
///
/// These should be organized logically according to main screen or the
/// main element wherein they appear. As we continue updating views, all
/// `.accessibilityIdentifier` identifiers from the client and the tests
/// should be move here and updated throughout the app.
public struct AccessibilityIdentifiers {

    struct Toolbar {
        static let settingsMenuButton = "TabToolbar.menuButton"
        static let homeButton = "TabToolbar.homeButton"
        static let trackingProtection = "TabLocationView.trackingProtectionButton"
        static let readerModeButton = "TabLocationView.readerModeButton"
        static let reloadButton = "TabLocationView.reloadButton"
    }

    struct FirefoxHomepage {

        static let collectionView = "FxCollectionView"

        struct HomeTabBanner {
            static let ctaButton = "HomeTabBanner.ctaButton"
        }

        struct OtherButtons {
            static let logoButton = "FxHomeLogoButton"
            static let customizeHome = "FxHomeCustomizeHomeSettingButton"
        }

        struct MoreButtons {
            static let recentlySaved = "recentlySavedSectionMoreButton"
            static let jumpBackIn = "jumpBackInSectionMoreButton"
            static let historyHighlights = "historyHighlightsSectionMoreButton"
            static let customizeHomePage = "FxHomeCustomizeHomeSettingButton"
        }

        struct SectionTitles {
            static let jumpBackIn = "jumpBackInTitle"
            static let recentlySaved = "recentlySavedTitle"
            static let historyHighlights = "historyHightlightsTitle"
            static let pocket = "pocketTitle"
            static let topSites = "topSitesTitle"
        }

        struct TopSites {
            static let itemCell = "TopSitesCell"
        }

        struct Pocket {
            static let itemCell = "PocketCell"
        }

        struct HistoryHighlights {
            static let itemCell = "HistoryHighlightsCell"
        }

        struct JumpBackIn {
            static let itemCell = "JumpBackInCell"
        }
    }

    struct GeneralizedIdentifiers {
        public static let back = "Back"
    }

    struct TabTray {
        static let filteredTabs = "filteredTabs"
        static let deleteCloseAllButton = "TabTrayController.deleteButton.closeAll"
        static let deleteCancelButton = "TabTrayController.deleteButton.cancel"
        static let syncedTabs = "Synced Tabs"
        static let inactiveTabHeader = "InactiveTabs.header"
        static let inactiveTabDeleteButton = "InactiveTabs.deleteButton"
    }

    struct LibraryPanels {
        static let bookmarksView = "LibraryPanels.Bookmarks"
        static let historyView = "LibraryPanels.History"
        static let downloadsView = "LibraryPanels.Downloads"
        static let readingListView = "LibraryPanels.ReadingList"
        static let segmentedControl = "librarySegmentControl"
        static let topLeftButton = "libraryPanelTopLeftButton"
        static let topRightButton = "libraryPanelTopRightButton"
        static let bottomLeftButton = "libraryPanelBottomLeftButton"
        static let bottomRightButton = "bookmarksPanelBottomRightButton"
        static let bottomSearchButton = "historyBottomSearchButton"
        static let bottomDeleteButton = "historyBottomDeleteButton"

        struct BookmarksPanel {
            static let tableView = "Bookmarks List"
        }

        struct HistoryPanel {
            static let tableView = "History List"
            static let clearHistoryCell = "HistoryPanel.clearHistory"
            static let recentlyClosedCell = "HistoryPanel.recentlyClosedCell"
            static let syncedHistoryCell = "HistoryPanel.syncedHistoryCell"
        }

        struct GroupedList {
            static let tableView = "grouped-items-table-view"
        }
    }

    struct Onboarding {
        static let welcomeCard = "WelcomeCard"
        static let wallpapersCard = "WallpapersCard"
        static let signSyncCard = "SignSyncCard"
        static let closeButton = "CloseButton"
        static let pageControl = "PageControl"
    }

    struct Settings {
        static let tableViewController = "AppSettingsTableViewController.tableView"

        struct Homepage {
            static let homeSettings = "Home"
            static let homePageNavigationBar = "Homepage"

            struct StartAtHome {
                static let afterFourHours = "StartAtHomeAfterFourHours"
                static let always = "StartAtHomeAlways"
                static let disabled = "StartAtHomeDisabled"
            }

            struct CustomizeFirefox {
                struct Shortcuts {
                    static let settingsPage = "TopSitesSettings"
                    static let topSitesRows = "TopSitesRows"
                }

                static let jumpBackIn = "Jump Back In"
                static let recentlySaved = "Recently Saved"
                static let recentVisited = "Recently Visited"
                static let recommendedByPocket = "Recommended by Pocket"
                static let wallpaper = "WallpaperSettings"
            }
        }

        struct FirefoxAccount {
            static let qrButton = "QRCodeSignIn.button"
        }

        struct Search {
            static let customEngineViewButton = "customEngineViewButton"
            static let searchNavigationBar = "Search"
            static let deleteMozillaEngine = "Delete Mozilla Engine"
            static let deleteButton = "Delete"
        }

        struct Logins {
            static let loginsSettings = "Logins"
        }

        struct ClearData {
            static let clearPrivatedata = "ClearPrivateData"
        }

        struct SearchBar {
            static let searchBarSetting = "SearchBarSetting"
            static let topSetting = "TopSearchBar"
            static let bottomSetting = "BottomSearchBar"
        }
    }
}
