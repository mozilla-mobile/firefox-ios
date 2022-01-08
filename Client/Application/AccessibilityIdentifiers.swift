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
    
    struct BottomToolbar {
        static let settingsMenuButton = "TabToolbar.menuButton"
    }
    
    struct TabToolbar {
        static let homeButton = "TabToolbar.homeButton"
    }

    struct FirefoxHomepage {

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
            static let library = "libraryTitle"
            static let topSites = "topSitesTitle"
        }
    }
    
    struct GeneralizedIdentifiers {
        public static let back = "Back"
    }

    struct TabTray {
        static let filteredTabs = "filteredTabs"
        static let deleteCloseAllButton = "TabTrayController.deleteButton.closeAll"
        static let deleteCancelButton = "TabTrayController.deleteButton.cancel"
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
                static let shortcuts = ""
                static let jumpBackIn = "Jump Back In"
                static let recentlySaved = "Recently Saved"
                static let recentSearches = "Recent Searches"
                static let recommendedByPocket = "Recommended by Pocket"
            }
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
    }
}
