// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This struct defines all the accessibility identifiers to be added to
/// screen elements for testing.
///
/// These should be organized logically according to main screen or the
/// main element wherein they appear. As we continue updating views, all
/// `.accessibilityIdentifier` identifiers from the client and the tests
/// should be move here and updated throughout the app.
public struct AccessibilityIdentifiers {
    /// Used for toolbar/URL bar buttons since our classes are built that buttons can live in one or the other
    /// Using only those a11y identifiers for both ensures we have standard way to refer to buttons from iPad to iPhone
    struct Toolbar {
        static let settingsMenuButton = "TabToolbar.menuButton"
        static let homeButton = "TabToolbar.homeButton"
        static let trackingProtection = "TabLocationView.trackingProtectionButton"
        static let readerModeButton = "TabLocationView.readerModeButton"
        static let reloadButton = "TabLocationView.reloadButton"
        static let shareButton = "TabLocationView.shareButton"
        static let backButton = "TabToolbar.backButton"
        static let forwardButton = "TabToolbar.forwardButton"
        static let tabsButton = "TabToolbar.tabsButton"
        static let addNewTabButton = "TabToolbar.addNewTabButton"
        static let searchButton = "TabToolbar.searchButton"
        static let stopButton = "TabToolbar.stopButton"
        static let bookmarksButton = "TabToolbar.libraryButton"
    }

    struct Browser {
        struct TopTabs {
            static let collectionView = "Top Tabs View"
            static let privateModeButton = "TopTabsViewController.privateModeButton"
        }

        struct UrlBar {
            static let scanQRCodeButton = "urlBar-scanQRCode"
            static let cancelButton = "urlBar-cancel"
            static let searchTextField = "address"
        }
    }

    struct FirefoxHomepage {
        static let collectionView = "FxCollectionView"

        struct HomeTabBanner {
            static let titleLabel = "HomeTabBanner.titleLabel"
            static let descriptionLabel = "HomeTabBanner.descriptionLabel"
            static let descriptionLabel1 = "HomeTabBanner.descriptionLabel1"
            static let descriptionLabel2 = "HomeTabBanner.descriptionLabel2"
            static let descriptionLabel3 = "HomeTabBanner.descriptionLabel3"
            static let ctaButton = "HomeTabBanner.goToSettingsButton"
            static let closeButton = "HomeTabBanner.closeButton"
        }

        struct OtherButtons {
            static let logoImage = "FxHomeLogoImage"
            static let logoText = "FxHomeLogoText"
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
            static let footerLearnMoreLabel = "Pocket.footerLearnMoreLabel"
        }

        struct HistoryHighlights {
            static let itemCell = "HistoryHighlightsCell"
        }

        struct JumpBackIn {
            static let itemCell = "JumpBackInCell"
        }

        struct RecentlySaved {
            static let itemCell = "RecentlySavedCell"
        }

        struct SyncedTab {
            static let itemCell = "SyncedTabCell"
            static let cardTitle = "SyncedTabCardTitle"
            static let showAllButton = "SyncedTabShowAllButton"
            static let heroImage = "SyncedTabHeroImage"
            static let itemTitle = "SyncedTabItemTitle"
            static let favIconImage = "SyncedTabFavIconImage"
            static let fallbackFavIconImage = "SyncedTabFallbackFavIconImage"
            static let descriptionLabel = "SyncedTabDescriptionLabel"
        }
    }

    struct GeneralizedIdentifiers {
        public static let back = "Back"
    }

    struct Shopping {
        static let sheetHeaderTitle = "Shopping.Sheet.HeaderTitle"

        struct ErrorCard {
            static let card = "Shopping.ErrorCard.Card"
            static let title = "Shopping.ErrorCard.Title"
            static let description = "Shopping.ErrorCard.Description"
            static let primaryAction = "Shopping.ErrorCard.PrimaryAction"
        }

        struct ReliabilityCard {
            static let card = "Shopping.ReliabilityCard.Card"
            static let title = "Shopping.ReliabilityCard.Title"
            static let ratingLetter = "Shopping.ReliabilityCard.RatingLetter"
            static let ratingDescription = "Shopping.ReliabilityCard.RatingDescription"
        }

        struct HighlightsCard {
            static let card = "Shopping.HighlightsCard.Card"
            static let footerTitle = "Shopping.HighlightsCard.FooterTitle"
            static let footerAction = "Shopping.HighlightsCard.FooterAction"
        }
    }

    struct TabTray {
        static let filteredTabs = "filteredTabs"
        static let deleteCloseAllButton = "TabTrayController.deleteButton.closeAll"
        static let deleteCancelButton = "TabTrayController.deleteButton.cancel"
        static let syncedTabs = "Synced Tabs"
        static let inactiveTabHeader = "InactiveTabs.header"
        static let inactiveTabDeleteButton = "InactiveTabs.deleteButton"
        static let closeAllTabsButton = "closeAllTabsButtonTabTray"
        static let newTabButton = "newTabButtonTabTray"
        static let doneButton = "doneButtonTabTray"
        static let syncTabsButton = "syncTabsButtonTabTray"
        static let navBarSegmentedControl = "navBarTabTray"
        static let syncDataButton = "syncDataButton"
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
        static let backgroundImage = "Onboarding.BackgroundImage"
        static let onboarding = "onboarding."
        static let closeButton = "CloseButton"
        static let pageControl = "PageControl"

        struct Wallpaper {
            static let card = "wallpaperCard"
            static let title = "wallpaperOnboardingTitle"
            static let description = "wallpaperOnboardingDescription"
        }
    }

    struct Upgrade {
        static let backgroundImage = "Upgrade.BackgroundImage"
        static let upgrade = "upgrade."
        static let closeButton = "Upgrade.CloseButton"
        static let pageControl = "Upgrade.PageControl"
    }

    struct Settings {
        static let tableViewController = "AppSettingsTableViewController.tableView"
        static let navigationBarItem = "AppSettingsTableViewController.navigationItem.rightBarButtonItem"

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

                struct Wallpaper {
                    static let collectionTitle = "wallpaperCollectionTitle"
                    static let collectionDescription = "wallpaperCollectionDescription"
                    static let collectionButton = "wallpaperCollectionButton"
                    static let card = "wallpaperCard"
                }

                static let jumpBackIn = "Jump Back In"
                static let recentlySaved = "Recently Saved"
                static let recentVisited = "Recently Visited"
                static let wallpaper = "WallpaperSettings"
            }
        }

        struct FirefoxAccount {
            static let continueButton = "Sign up or sign in"
            static let emailTextFieldChinaFxA = "Email"
            static let emailTextField = "Enter your email"
            static let fxaNavigationBar = "Sync and Save Data"
            static let fxaSettingsButton = "Sync and Save Data"
            static let fxaSignInButton = "EmailSignIn.button"
            static let qrButton = "QRCodeSignIn.button"
            static let qrScanFailedAlertOkButton = "qrCodeAlert.okButton"
        }

        struct Search {
            static let title = "Search"
            static let customEngineViewButton = "customEngineViewButton"
            static let searchNavigationBar = "Search"
            static let deleteMozillaEngine = "Delete Mozilla Engine"
            static let deleteButton = "Delete"
        }

        struct AdvancedAccountSettings {
            static let title = "AdvancedAccount.Setting"
        }

        struct Logins {
            static let title = "Logins"
        }

        struct ClearData {
            static let title = "ClearPrivateData"
            static let websiteDataSection = "WebsiteData"
            static let clearPrivateDataSection = "ClearPrivateData"
        }

        struct Notifications {
            static let title = "NotificationsSetting"
        }

        struct CreditCard {
            static let title = "AutofillCreditCard"
        }

        struct ConnectSetting {
            static let title = "SignInToSync"
        }

        struct ContentBlocker {
            static let title = "TrackingProtection"
        }

        struct NewTab {
            static let title = "NewTab"
        }

        struct NoImageMode {
            static let title = "NoImageMode"
        }

        struct BlockPopUp {
            static let title = "BlockPopUp"
        }

        struct OpenWithMail {
            static let title = "OpenWith.Setting"
        }

        struct SearchBar {
            static let searchBarSetting = "SearchBarSetting"
            static let topSetting = "TopSearchBar"
            static let bottomSetting = "BottomSearchBar"
        }

        struct SendAnonymousUsageData {
            static let title = "SendAnonymousUsageData"
        }

        struct ShowIntroduction {
            static let title = "ShowTour"
        }

        struct Siri {
            static let title = "SiriSettings"
        }

        struct StudiesToggle {
            static let title = "StudiesToggle"
        }

        struct Tabs {
            static let title = "TabsSetting"
        }

        struct Theme {
            static let title = "DisplayThemeOption"
        }

        struct BlockImages {
            static let title = "Block Images"
        }

        struct Passwords {
            static let usernameField = "usernameField"
            static let passwordField = "passwordField"
            static let websiteField = "websiteField"
            static let onboardingContinue = "onboardingContinue"
            static let addCredentialButton = "addCredentialButton"
            static let editButton = "editButton"
        }

        struct Version {
            static let title = "FxVersion"
        }

        struct TrackingProtection {
            static let basic = "Settings.TrackingProtectionOption.BlockListBasic"
            static let strict = "Settings.TrackingProtectionOption.BlockListStrict"
        }
    }

    struct ShareTo {
        struct HelpView {
            static let doneButton = "doneButton"
            static let topMessageLabel = "topMessageLabel"
            static let bottomMessageLabel = "bottomMessageLabel"
        }
    }

    struct SurveySurface {
        static let takeSurveyButton = "takeSurveyButton"
        static let dismissButton = "dismissSurveyButton"
        static let textLabel = "surveyDescriptionLabel"
        static let imageView = "surveyImageView"
    }

    struct Photon {
        static let closeButton = "PhotonMenu.close"
        static let view = "Action Sheet"
        static let tableView = "Context Menu"
        static let pasteAction = "pasteAction"
        static let pasteAndGoAction = "pasteAndGoAction"
    }

    struct Alert {
        static let cancelDownloadResume = "cancelDownloadAlert.resume"
        static let cancelDownloadCancel = "cancelDownloadAlert.cancel"
    }

    struct ZoomPageBar {
        static let zoomPageZoomInButton = "ZoomPage.zoomInButton"
        static let zoomPageZoomOutButton = "ZoomPage.zoomOutButton"
        static let zoomPageZoomLevelLabel = "ZoomPage.zoomLevelLabel"
    }

    struct FindInPage {
        static let findInPageCloseButton = "FindInPage.closeButton"
        static let findNextButton = "FindInPage.find_next"
        static let findPreviousButton = "FindInPage.find_previous"
    }

    struct RememberCreditCard {
        static let rememberCreditCardHeader = "RememberCreditCard.Header"
        static let yesButton = "RememberCreditCard.yesButton"
        static let notNowButton = "RememberCreditCard.notNowButton"
    }

    struct ActionFooter {
        static let title = "ActionFooter.title"
        static let primaryAction = "ActionFooter.primaryAction"
    }
}
