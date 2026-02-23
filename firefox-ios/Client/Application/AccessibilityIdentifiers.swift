// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// swiftlint:disable line_length
import Foundation

/// This struct defines all the accessibility identifiers to be added to
/// screen elements for testing.
///
/// These should be organized logically according to main screen or the
/// main element wherein they appear. As we continue updating views, all
/// `.accessibilityIdentifier` identifiers from the client and the tests
/// should be move here and updated throughout the app.
struct AccessibilityIdentifiers {
    /// Used for toolbar/URL bar buttons since our classes are built that buttons can live in one or the other
    /// Using only those a11y identifiers for both ensures we have standard way to refer to buttons from iPad to iPhone
    struct Toolbar {
        static let settingsMenuButton = "TabToolbar.menuButton"
        static let homeButton = "TabToolbar.homeButton"
        static let readerModeButton = "TabLocationView.readerModeButton"
        static let reloadButton = "TabLocationView.reloadButton"
        static let shareButton = "TabLocationView.shareButton"
        static let summarizeButton = "TabLocationView.summarizeButton"
        static let backButton = "TabToolbar.backButton"
        static let fireButton = "TabToolbar.fireButton"
        static let forwardButton = "TabToolbar.forwardButton"
        static let tabsButton = "TabToolbar.tabsButton"
        static let addNewTabButton = "TabToolbar.addNewTabButton"
        static let searchButton = "TabToolbar.searchButton"
        static let stopButton = "TabToolbar.stopButton"
        static let translateButton = "TabToolbar.translateButton"
        static let translateLoadingButton = "TabToolbar.translateLoadingButton"
        static let translateActiveButton = "TabToolbar.translateActiveButton"
        static let topBorder = "TabToolbar.toolbarTopBorderView"
    }

    struct Browser {
        struct TopTabs {
            static let collectionView = "Top Tabs View"
            static let privateModeButton = "TopTabsViewController.privateModeButton"
        }

        struct UrlBar {
            static let cancelButton = "urlBar-cancel"
        }

        struct KeyboardAccessory {
            static let doneButton = "KeyboardAccessory.doneButton"
            static let nextButton = "KeyboardAccessory.nextButton"
            static let previousButton = "KeyboardAccessory.previousButton"
            static let addressAutofillButton = "KeyboardAccessory.addressAutofillButton"
            static let creditCardAutofillButton = "KeyboardAccessory.creditCardAutofillButton"
            static let relayMaskAutofillButton = "KeyboardAccessory.relayMaskAutofillButton"
        }

        struct AddressToolbar {
            static let lockIcon = "AddressToolbar.lockIcon"
            static let searchTextField = "AddressToolbar.address"
            static let searchEngine = "AddressToolbar.searchEngine"
            static let leadingSkeleton = "AddressToolbar.leadingSkeleton"
            static let trailingSkeleton = "AddressToolbar.trailingSkeleton"
        }

        struct WebView {
            static let documentLoadingLabel = "WebView.documentLoadingLabel"
        }

        static let overKeyboardContainer = "Browser.overKeyboardContainer"
        static let headerContainer = "Browser.headerContainer"
        static let bottomContainer = "Browser.bottomContainer"
        static let bottomContentStackView = "Browser.bottomContentStackView"
        static let contentContainer = "Browser.contentContainer"
        static let statusBarOverlay = "Browser.statusBarOverlay"
    }

    struct ContextualHints {
        static let actionButton = "ContextualHints.ActionButton"
    }

    struct MainMenu {
        struct SiteProtectionsHeaderView {
            static let header = "MainMenu.SiteProtectionHeader"
        }

        struct HeaderBanner {
            static let closeButton = "MainMenu.HeaderBanner.CloseMenuButton"
        }

        struct HeaderView {
            static let mainButton = "MainMenu.MainButton"
            static let closeButton = "MainMenu.CloseMenuButton"
        }

        static let mainMenu = "MainMenu.Menu"
        static let newTab = "MainMenu.NewTab"
        static let newPrivateTab = "MainMenu.NewPrivateTab"
        static let switchToDesktopSite = "MainMenu.SwitchToDesktopSite"
        static let desktopSite = "MainMenu.DesktopSite"
        static let findInPage = "MainMenu.FindInPage"
        static let bookmarks = "MainMenu.Bookmarks"
        static let history = "MainMenu.History"
        static let downloads = "MainMenu.Downloads"
        static let passwords = "MainMenu.Passwords"
        static let getHelp = "MainMenu.GetHelp"
        static let settings = "MainMenu.Settings"
        static let whatsNew = "MainMenu.WhatsNew"
        static let saveToReadingList = "MainMenu.SaveToReadingList"
        static let addToShortcuts = "MainMenu.AddToShortcuts"
        static let bookmarkThisPage = "MainMenu.BookmarkThisPage"
        static let bookmarkPage = "MainMenu.BookmarkPage"
        static let print = "MainMenu.Print"
        static let share = "MainMenu.Share"
        static let saveAsPDF = "MainMenu.SaveAsPDF"
        static let reportBrokenSite = "MainMenu.ReportBrokenSite"
        static let readerView = "MainMenu.ReaderViewOn"
        static let nightMode = "MainMenu.NightModeOn"
        static let zoom = "MainMenu.Zoom"
        static let moreLess = "MainMenu.MoreLess"
        static let signIn = "MainMenu.SignIn"
        static let summarizePage = "MainMenu.SummarizePage"
        static let trackigProtection = "shieldCheckmarkLarge"
    }

    struct UnifiedSearch {
        struct BottomSheetRow {
            static let engine = "UnifiedSearch.BottomSheetRow.Engine"
            static let searchSettings = "UnifiedSearch.BottomSheetRow.SearchSettings"
        }
    }

    struct EnhancedTrackingProtection {
        struct MainScreen {
            static let scrollView = "TrackingProtection.ScrollView"
            static let baseView = "TrackingProtection.BaseView"
            static let clearCookiesButton = "TrackingProtection.ClearCookiesButton"
            static let trackingProtectionSettingsButton = "TrackingProtection.SettingsButton"
            static let connectionDetailsContentView = "TrackingProtection.ConnectionDetailsContentView"
            static let foxImage = "TrackingProtection.FoxStatusImage"
            static let connectionDetailsLabelsContainer = "TrackingProtection.ConnectionDetailsLabelsContainer"
            static let connectionDetailsTitleLabel = "TrackingProtection.ConnectionDetailsTitleLabel"
            static let connectionDetailsStatusLabel = "TrackingProtection.ConnectionDetailsStatusLabel"
            static let shieldImage = "TrackingProtection.ShieldImage"
            static let lockImage = "TrackingProtection.LockImage"
            static let arrowImage = "TrackingProtection.ArrowImage"
            static let domainLabel = "TrackingProtection.DomainTitleLabel"
            static let domainHeaderLabel = "TrackingProtection.DomainHeaderLabel"
            static let statusTitleLabel = "TrackingProtection.ConnectionStatusTitleLabel"
            static let statusBodyLabel = "TrackingProtection.ConnectionStatusBodyLabel"
            static let trackersBlockedButton = "TrackingProtection.TrackersBlockedButton"
            static let securityStatusButton = "TrackingProtection.ConnectionSecurityStatusButton"
            static let toggleViewLabelsContainer = "TrackingProtection.ToggleViewLabelsContainer"
            static let toggleLabel = "TrackingProtection.ToggleLabel"
            static let toggleSwitch = "TrackingProtection.ToggleSwitch"
            static let toggleStatusLabel = "TrackingProtection.ToggleStatusLabel"
            static let toggleViewBodyLabel = "TrackingProtection.ToggleViewBodyLabel"
            static let closeButton = "TrackingProtection.CloseButton"
            static let faviconImage = "TrackingProtection.FaviconImage"
            static let trackersLabel  = "TrackingProtection.TrackersLabel"
            static let trackersHorizontalLine = "TrackingProtection.TrackersHorizontalLine"
            static let trackersConnectionContainer = "TrackingProtection.TrackersConnectionContainer"
            static let connectionStatusImage = "TrackingProtection.ConnectionStatusImage"
            static let connectionStatusLabel = "TrackingProtection.ConnectionStatusLabel"
            static let connectionHorizontalLine = "TrackingProtection.ConnectionHorizontalLine"
            static let favicon = "TrackingProtection.Favicon"
            static let titleLabel = "TrackingProtection.TitleLabel"
            static let subtitleLabel = "TrackingProtection.SubtitleLabel"
        }

        struct DetailsScreen {
            static let scrollView = "TrackingProtectionDetails.ScrollView"
            static let headerView = "TrackingProtectionDetails.HeaderView"
            static let mainView = "TrackingProtectionDetails.MainView"
            static let containerView = "TrackingProtectionDetails.BaseView"
            static let connectionView = "TrackingProtectionDetails.ConnectionView"
            static let certificatesButton = "TrackingProtectionDetails.CertificatesButton"
            static let closeButton = "TrackingProtectionDetails.CloseButton"
            static let backButton = "TrackingProtectionDetails.BackButton"
            static let titleLabel = "TrackingProtectionDetails.TitleLabel"
            static let certificatesTitleLabel = "TrackingProtectionDetails.CertificatesTitleLabel"
            static let tableView = "TrackingProtectionDetails.TableView"
            static let tableViewHeader = "TrackingProtectionDetails.TableViewHeader"
            static let sectionLabel = "TrackingProtectionDetails.SectionLabel"
            static let allSectionItems = "TrackingProtectionDetails.AllSectionItems"
            static let itemLabel = "TrackingProtectionDetails.ItemLabel"
            static let connectionImage = "TrackingProtectionDetails.ConnectionImage"
            static let connectionStatusLabel = "TrackingProtectionDetails.ConnectionStatusLabel"
            static let dividerView = "TrackingProtectionDetails.DividerView"
            static let verifiedByView = "TrackingProtectionDetails.VerifiedByView"
            static let verifiedByLabel = "TrackingProtectionDetails.VerifiedByLabel"
        }

        struct BlockedTrackers {
            static let headerView = "BlockedTrackers.HeaderView"
            static let mainView = "BlockedTrackers.MainView"
            static let containerView = "BlockedTrackers.BaseView"
            static let trackersTable = "BlockedTrackers.TrackersTable"
            static let totalTrackersBlockedLabel = "BlockedTrackers.TotalTrackersBlockedLabel"

            static let crossSiteTitle = "BlockedTrackers.CrossSiteTitle"
            static let crossSiteImage = "BlockedTrackers.CrossSiteImage"

            static let fingerPrintersTitle = "BlockedTrackers.FingerPrintersTitle"
            static let fingerPrintersImage = "BlockedTrackers.FingerPrintersImage"

            static let trackingContentTitle = "BlockedTrackers.TrackingContentTitle"
            static let trackingContentImage = "BlockedTrackers.TrackingContentImage"

            static let socialMediaTitle = "BlockedTrackers.SocialMediaTitle"
            static let socialMediaImage = "BlockedTrackers.SocialMediaImage"
        }

        struct CertificatesScreen {
            static let headerView = "CertificatesViewController.HeaderView"
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
            static let logoID = "FxHomeLogoID"
            static let closeButton = "FirefoxHomepage.closeButton"
        }

        struct MoreButtons {
            static let shortcuts = "shortcutsSectionMoreButton"
            static let bookmarks = "bookmarksSectionMoreButton"
            static let jumpBackIn = "jumpBackInSectionMoreButton"
            static let stories = "storiesSectionMoreButton"
        }

        struct SectionTitles {
            static let jumpBackIn = "jumpBackInTitle"
            static let bookmarks = "bookmarksTitle"
            static let merino = "pocketTitle"
            static let topSites = "topSitesTitle"
        }

        struct TopSites {
            static let itemCell = "TopSitesCell"
        }

        struct SearchBar {
            static let itemCell = "SearchBarCell"
        }

        struct Pocket {
            static let itemCell = "PocketCell"
            static let footerLearnMoreLabel = "Pocket.footerLearnMoreLabel"
        }

        struct JumpBackIn {
            static let itemCell = "JumpBackInCell"
        }

        struct Bookmarks {
            static let itemCell = "BookmarksCell"
        }

        struct SyncedTab {
            static let itemCell = "SyncedTabCell"
            static let cardTitle = "SyncedTabCardTitle"
            static let showAllButton = "SyncedTabShowAllButton"
            static let itemTitle = "SyncedTabItemTitle"
            static let favIconImage = "SyncedTabFavIconImage"
            static let descriptionLabel = "SyncedTabDescriptionLabel"
        }

        struct StoriesFeed {
            static let storiesFeedCell = "StoriesFeedCell"
        }

        struct StoriesWebview {
            static let reloadButton = "StoriesWebviewReloadButton"
        }
    }

    struct GeneralizedIdentifiers {
        public static let back = "Back"
    }

    struct SaveCardPrompt {
        struct Prompt {
            static let closeButton = "a11yCloseButton"
        }
    }

    struct Microsurvey {
        struct Prompt {
            static let firefoxLogo = "Microsurvey.Prompt.FirefoxLogo"
            static let closeButton = "Microsurvey.Prompt.CloseButton"
            static let takeSurveyButton = "Microsurvey.Prompt.TakeSurveyButton"
        }

        struct Survey {
            static let firefoxLogo = "Microsurvey.Survey.FirefoxLogo"
            static let closeButton = "Microsurvey.Survey.CloseButton"
            static let privacyPolicyLink = "Microsurvey.Prompt.PrivacyPolicyLink"
            static let submitButton = "Microsurvey.Survey.SubmitButton"
            static let radioButton = "Microsurvey.Survey.RadioButton"
        }
    }

    struct TermsOfUse {
        static let logo = "TermsOfUse.Logo"
        static let title = "TermsOfUse.Title"
        static let description = "TermsOfUse.Description"
        static let acceptButton = "TermsOfUse.AcceptButton"
        static let remindMeLaterButton = "TermsOfUse.RemindMeLaterButton"
        static let linkTermsOfUse = "TermsOfUse.Link.TermsOfUse"
        static let linkPrivacyNotice = "TermsOfUse.Link.PrivacyNotice"
        static let linkLearnMore = "TermsOfUse.Link.LearnMore"
    }

    struct PrivateMode {
        static let dimmingView = "PrivateMode.DimmingView"
        struct Homepage {
            static let title = "PrivateMode.Homepage.Title"
            static let body = "PrivateMode.Homepage.Body"
            static let link = "PrivateMode.Homepage.Link"
            static let card = "PrivateMode.Homepage.MessageCard"
        }
    }

    struct ZeroSearch {
        static let dimmingView = "ZeroSearch.dimmingView"
    }

    struct TabTray {
        static let deleteCloseAllButton = "TabTrayController.deleteButton.closeAll"
        static let deleteCancelButton = "TabTrayController.deleteButton.cancel"
        static let deleteOlderTabsButton = "TabTrayController.deleteButton.closeOlderTabs"
        static let deleteTabsOlderThan1DayButton = "TabTrayController.deleteButton.olderThan1Day"
        static let deleteTabsOlderThan1WeekButton = "TabTrayController.deleteButton.olderThan1Week"
        static let deleteTabsOlderThan1MonthButton = "TabTrayController.deleteButton.olderThan1Month"
        static let syncedTabs = "Synced Tabs"
        static let closeAllTabsButton = "closeAllTabsButtonTabTray"
        static let newTabButton = "newTabButtonTabTray"
        static let doneButton = "doneButtonTabTray"
        static let syncTabsButton = "syncTabsButtonTabTray"
        static let navBarSegmentedControl = "navBarTabTray"
        static let selectorCell = "selectorCell"
        static let syncDataButton = "syncDataButton"
        static let learnMoreButton = "learnMoreButton"
        static let collectionView = "TabDisplayView.collectionView"
        static let tabCell = "TabDisplayView.tabCell"
        static let closeButton = "tabCloseButton"
        static let tabsTray = "Tabs Tray"
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
            static let bookmarksCell = "BookmarksPanel.BookmarksCell"
            static let bookmarksCellDisclosureButton = ".DisclosureButton"
            static let emptyStateLogoImage = "BookmarksPanel.EmptyState.emptyStateLogoImage"
            static let emptyStateTitleLabel = "BookmarksPanel.EmptyState.emptyStateTitleLabel"
            static let emptyStateBodyLabel = "BookmarksPanel.EmptyState.emptyStateBodyLabel"
            static let emptyStateSignInButton = "BookmarksPanel.EmptyState.signInButton"
            static let titleTextField = "BookmarkDetail.titleTextField"
            static let urlTextField = "BookmarkDetail.urlTextField"
            static let bookmarkParentFolderCell = "BookmarksDetail.ParentFolderSelector.FolderCell"
            static let newFolderCell = "BookmarksDetail.ParentFolderSelector.NewFolderCell"
            static let saveButton = "BookmarksDetail.SaveButton"
            static let titleTextFieldClearButton = "BookmarksDetail.TitleTextFieldClearButton"
            static let urlTextFieldClearButton = "BookmarksDetail.UrlTextFieldClearButton"
        }

        struct HistoryPanel {
            static let tableView = "History List"
            static let recentlyClosedCell = "HistoryPanel.recentlyClosedCell"
        }

        struct GroupedList {
            static let tableView = "grouped-items-table-view"
        }

        struct ReadingListPanel {
            static let tableView = "Reading list"
            static let emptyReadingList1 = "Welcome to your Reading List"
            static let emptyReadingList2 = "Open articles in Reader View by tapping the book icon when it appears in the title bar."
            static let emptyReadingList3 = "Save pages to your Reading List by tapping the book plus icon in the Reader View controls."
        }

        struct DownloadsPanel {
            static let tableView = "DownloadsTable"
        }
    }

    struct Onboarding {
        static let backgroundImage = "Onboarding.BackgroundImage"
        static let onboarding = "onboarding."
        static let closeButton = "CloseButton"
        static let pageControl = "PageControl"
        static let bottomSheetCloseButton = "Onboarding.bottomSheetCloseButton"

        struct Wallpaper {
            static let card = "wallpaperCard"
            static let title = "wallpaperOnboardingTitle"
            static let description = "wallpaperOnboardingDescription"
        }
    }

    struct TermsOfService {
        static let root = "TermsOfService.Onboarding"
        static let logo = "TermsOfService.Logo"
        static let title = "TermsOfService.Title"
        static let subtitle = "TermsOfService.Subtitle"
        static let termsOfServiceAgreement = "TermsOfService.TermsOfServiceAgreement"
        static let privacyNoticeAgreement = "TermsOfService.PrivacyNoticeAgreement"
        static let manageDataCollectionAgreement = "TermsOfService.ManageDataCollectionAgreement"
        static let agreeAndContinueButton = "TermsOfService.AgreeAndContinueButton"
        static let doneButton = "TermsOfService.DoneButton"

        struct PrivacyNotice {
            static let title = "TermsOfService.PrivacyNotice.Title"
            static let doneButton = "TermsOfService.PrivacyNotice.DoneButton"

            struct CrashReports {
                static let contentStackView = "TermsOfService.PrivacyNotice.CrashReports.ContentStackView"
                static let actionContentView = "TermsOfService.PrivacyNotice.CrashReports.ActionContentView"
                static let actionTitleLabel = "TermsOfService.PrivacyNotice.CrashReports.ActionTitleLabel"
                static let actionSwitch = "TermsOfService.PrivacyNotice.CrashReports.ActionSwitch"
                static let actionDescriptionLabel = "TermsOfService.PrivacyNotice.CrashReports.ActionDescriptionLabel"
            }

            struct TechnicalData {
                static let contentStackView = "TermsOfService.PrivacyNotice.TechnicalData.ContentStackView"
                static let actionContentView = "TermsOfService.PrivacyNotice.TechnicalData.ActionContentView"
                static let actionTitleLabel = "TermsOfService.PrivacyNotice.TechnicalData.ActionTitleLabel"
                static let actionSwitch = "TermsOfService.PrivacyNotice.TechnicalData.ActionSwitch"
                static let actionDescriptionLabel = "TermsOfService.PrivacyNotice.TechnicalData.ActionDescriptionLabel"
            }
        }
    }

    struct Upgrade {
        static let backgroundImage = "Upgrade.BackgroundImage"
        static let upgrade = "upgrade."
        static let closeButton = "Upgrade.CloseButton"
        static let pageControl = "Upgrade.PageControl"
    }

    struct Settings {
        static let title = "Settings"
        static let tableViewController = "AppSettingsTableViewController.tableView"
        static let navigationBarItem = "AppSettingsTableViewController.navigationItem.rightBarButtonItem"

        struct Appearance {
            static let browserThemeSectionTitle = "BrowserThemeSectionTitle"
            static let websiteAppearanceSectionTitle = "WebsiteAppearanceSectionTitle"
            static let navigationToolbarSectionTitle = "NavigationToolbarSectionTitle"
            static let pageZoomTitle = "PageZoomTitle"
            static let specificSiteSettings = "SpecificSiteSettings"
            static let automaticThemeView = "AutomaticThemeView"
            static let lightThemeView = "LightThemeView"
            static let darkThemeView = "DarkThemeView"
            static let darkModeToggle = "DarkModeToggle"
        }

        struct AppIconSelection {
            static let settingsRowTitle = "AppIconSelectionTitle"
        }

        struct DefaultBrowser {
            static let defaultBrowser = "DefaultBrowserSettings"
        }

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
                static let wallpaper = "WallpaperSettings"
            }
        }

        struct FirefoxAccount {
            static let continueButton = "Sign up or sign in"
            static let emailTextField = "Enter your email"
            static let fxaNavigationBar = "Sync and Save Data"
            static let fxaSettingsButton = "Sync and Save Data"
            static let fxaSignInButton = "EmailSignIn.button"
            static let qrButton = "QRCodeSignIn.button"
            static let qrScanFailedAlertOkButton = "qrCodeAlert.okButton"
            static let signInButton = "Sign in"
        }

        struct Search {
            static let title = "Search"
            static let customEngineViewButton = "customEngineViewButton"
            static let searchNavigationBar = "Search"
            static let deleteMozillaEngine = "Remove Mozilla Engine"
            static let deleteButton = "Delete"
            static let showPrivateSuggestions = "PrivateMode.showPrivateSuggestions"
            static let showTrendingSearches = "showTrendingSearch"
            // This is based on `PrefsKeys.SearchSettings.showTrendingSearches`
            static let showTrendingSearchesSwitch = "trendingSearchesFeatureKey"
            static let showRecentSearches = "showRecentSearch"
            // This is based on `PrefsKeys.SearchSettings.showRecentSearches`
            static let showRecentSearchesSwitch = "recentSearchesFeatureKey"
            static let showSearchSuggestions = "FirefoxSuggestShowSearchSuggestions"
            static let backButtoniOS26 = "BackButton"
            static let backButton = "Settings"
        }

        struct AdvancedAccountSettings {
            static let title = "AdvancedAccount.Setting"
        }

        struct Logins {
            static let title = "Logins"

            struct Passwords {
                static let saveLogins = "saveLogins"
                static let showLoginsInAppMenu = "showLoginsInAppMenu"
                static let searchPasswords = "Search passwords"
                static let emptyList = "No passwords found"
                static let addButton = "Add"

                struct AddLogin {
                    static let saveButton = "Save"
                    static let cancelButton = "Cancel"
                    static let addCredential = "Add Credential"
                }
            }
        }

        struct CreditCards {
            static let title = "AutofillCreditCard"

            struct AutoFillCreditCard {
                static let autoFillCreditCards = "Payment Methods"
                static let addCard = "Add Card"
                static let saveAutofillCards = "Save and Fill Payment Methods"
                static let savedCards = "SAVED CARDS"
            }

            struct AddCreditCard {
                static let addCreditCard = "Add Card"
                static let nameOnCard = "Name on Card"
                static let cardNumber = "Card Number"
                static let expiration = "Expiration MM / YY"
                static let close = "Close"
                static let save = "Save"
            }

            struct ViewCreditCard {
                static let viewCard = "View Card"
                static let edit = "Edit"
                static let close = "Close"
            }

            struct EditCreditCard {
                static let editCreditCard = "Edit Card"
                static let removeCard = "Remove Card"
                static let removeThisCard = "Remove Card?"
                static let cancel = "Cancel"
                static let remove = "Remove"
            }
        }

        struct ClearData {
            static let title = "ClearPrivateData"
            static let websiteDataSection = "WebsiteData"
            static let clearPrivateDataSection = "ClearPrivateData"
            static let clearAllWebsiteData = "ClearAllWebsiteData"
        }

        struct Notifications {
            static let title = "NotificationsSetting"
        }

        struct CreditCard {
            static let title = "AutofillCreditCard"
        }

        struct Address {
            static let title = "AutofillAddress"

            struct Addresses {
                static let title = "Addresses"
                static let addAddress = "Add address"
            }
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

        struct OfferToOpen {
            static let title = "showClipboardBar"
        }

        struct BlockExternal {
            static let title = "blockOpeningExternalApps"
        }

        struct ShowLink {
            static let title = "showLinkPreviews"
        }

        struct ClosePrivateTabs {
            static let title = "ClosePrivateTabs"
        }

        struct SearchBar {
            static let searchBarSetting = "SearchBarSetting"
            static let topSetting = "TopSearchBar"
            static let bottomSetting = "BottomSearchBar"
        }

        struct NavigationToolbar {
            static let homeButton = "HomeButton"
            static let newTabButton = "NewTabButton"
        }

        struct SendData {
            static let sendTechnicalDataTitle = "SendTechnicalData"
            static let sendCrashReportsTitle = "SendCrashReports"
            static let sendDailyUsagePingTitle = "SendDailyUsagePing"
            static let studiesTitle = "StudiesToggle"
            static let rolloutsTitle = "RolloutsToggle"
            static let sendTechnicalDataLearnMoreButton = "SendTechnicalDataLearnMoreButton"
            static let sendCrashReportsLearnMoreButton = "SendCrashReportsLearnMoreButton"
            static let sendDailyUsagePingLearnMoreButton = "SendDailyUsagePingLearnMoreButton"
            static let studiesLearnMoreButton = "StudiesLearnMoreButton"
            static let rolloutsLearnMoreButton = "RolloutsLearnMoreButton"
        }

        struct PrivacyPolicy {
            static let title = "PrivacyPolicy"
        }

        struct ShowIntroduction {
            static let title = "ShowTour"
        }

        struct SentFromFirefox {
            static let whatsApp = "SentFromFirefox.WhatsApp"
        }

        struct SendFeedback {
            static let title = "SendFeedback"
        }

        struct Help {
            static let title = "Help"
        }

        struct RateOnAppStore {
            static let title = "RateOnAppStore"
        }

        struct Licenses {
            static let title = "Licenses"
        }

        struct YourRights {
            static let title = "YourRights"
        }

        struct Siri {
            static let title = "SiriSettings"
        }

        struct Browsing {
            static let title = "BrowsingSettings"
            static let tabs = "TABS"
            static let links = "LINKS"
            static let blockPopUps = "blockPopups"
            static let autoPlay = "AutoplaySettings"
            static let blockImages = "NoImageModeStatus"
        }

        struct Summarize {
            static let title = "SummarizeSettings"
            static let summarizeContentSwitch = "summarizeContentFeature"
            static let shakeGestureSwitch = "shakeGestureEnabledKey"
            static let languageCell = "summarizeLanguageCell"
            static let languageCellPickerButton = "summarizeLanguageCellPickerButton"
        }

        struct Theme {
            static let title = "DisplayThemeOption"
        }

        struct Translation {
            static let title = "Settings.Translation.Title"
            // This is based on `PrefsKeys.Settings.translationsFeature`
            static let toggleSwitch = "settings.translationFeature"
            static let navigationBar = "Settings.Translation.navigationBar"
            static let backButtoniOS26 = "BackButton"
            static let backButton = "Settings"
        }

        struct BlockImages {
            static let title = "Block Images"
        }

        struct AutofillsPasswords {
            static let title = "AutofillsPasswordsSettings"
        }

        struct RelayMask {
            static let title = "RelayMaskSettings"
            static let manageMasksButton = "manageEmailMasks"
        }

        struct Passwords {
            static let usernameField = "usernameField"
            static let passwordField = "passwordField"
            static let websiteField = "websiteField"
            static let onboardingContinue = "onboardingContinue"
            static let onboardingLearnMore = "Passwords.onboardingLearnMore"
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

        struct Autoplay {
            static let allowAudioAndVideo = "AllowAudioAndVideo"
            static let blockAudio = "BlockAudio"
            static let blockAudioAndVideo = "BlockAudioAndVideo"
        }
    }

    struct Summarizer {
        static let tabSnapshotView = "tabSnapshotView"
        static let closeSummaryButton = "closeSummaryButton"
        static let titleLabel = "summaryTitleLabel"
        static let compactTitleLabel = "summaryCompactTitleLabel"
        static let loadingLabel = "summaryLoadingLabel"
        static let brandLabel = "summaryBrandLabel"
        static let brandImage = "summaryBrandImage"
        static let summaryTableView = "summaryTextView"
        static let errorContentView = "errorContentView"
        static let retryErrorButton = "retryErrorButton"
        static let closeSummaryErrorButton = "closeSummaryErrorButton"
        static let tosAllowButton = "tosAllowButton"
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
        static let doneButton = "find.doneButton"
    }

    struct FindInPage {
        static let findInPageCloseButton = "find.doneButton"
        static let findNextButton = "find.nextButton"
        static let findPreviousButton = "find.previousButton"
    }

    struct RememberCreditCard {
        static let rememberCreditCardHeader = "RememberCreditCard.Header"
        static let yesButton = "RememberCreditCard.yesButton"
        static let manageCardsButton = "RememberCreditCard.manageCardsButton"
        static let notNowButton = "RememberCreditCard.notNowButton"
    }

    enum Autofill {
        static let footerPrimaryAction = "Autofill.footerPrimaryAction"
        static let addressCloseButton = "Autofill.addressCloseButton"
        static let creditCardCloseButton = "Autofill.creditCardCloseButton"
        static let loginCloseButton = "Autofill.loginCloseButton"
    }

    enum PasswordGenerator {
        static let closeButton = "PasswordGenerator.closeButton"
        static let headerLabel = "PasswordGenerator.headerLabel"
        static let usePasswordButton = "PasswordGenerator.usePasswordButton"
        static let headerImage = "PasswordGenerator.headerImage"
        static let descriptionLabel = "PasswordGenerator.descriptionLabel"
        static let passwordField = "PasswordGenerator.passwordField"
        static let passwordRefreshButton = "PasswordGenerator.passwordRefreshButton"
        static let passwordlabel = "PasswordGenerator.passwordLabel"
        static let content = "PasswordGenerator.content"
        static let header = "PasswordGenerator.header"
        static let keyboardButton = "PasswordGenerator.keyboardButton"
    }

    struct NativeErrorPage {
        static let foxImage = "NativeErrorPage.foxImage"
        static let titleLabel = "NativeErrorPage.titleLabel"
        static let errorDescriptionLabel = "NativeErrorPage.errorDescriptionLabel"
        static let reloadButton = "NativeErrorPage.reloadButton"
    }

    struct SaveLoginAlert {
        static let saveButton = "SaveLoginPrompt.saveLoginButton"
        static let notNowButton = "SaveLoginPrompt.dontSaveButton"
        static let updateButton = "UpdateLoginPrompt.updateButton"
        static let dontUpdateButton = "UpdateLoginPrompt.dontUpdateButton"
    }

    struct ReaderMode {
        static let sansSerifFontButton = "ReaderMode.sansSerifFontButton"
        static let serifFontButton = "ReaderMode.serifFontButton"
        static let smallerFontSizeButton = "ReaderMode.smallerFontSizeButton"
        static let biggerFontSizeButton = "ReaderMode.biggerFontSizeButton"
        static let resetFontSizeButton = "ReaderMode.resetFontSizeButton"
        static let lightThemeButton = "ReaderMode.lightThemeButton"
        static let sepiaThemeButton = "ReaderMode.sepiaThemeButton"
        static let darkThemeButton = "ReaderMode.darkThemeButton"
        static let lighterBrightnessButton = "ReaderMode.lighterBrightnessButton"
        static let darkerBrightnessButton = "ReaderMode.darkerBrightnessButton"
        static let brightnessSlider = "ReaderMode.brightnessSlider"
    }
}
// swiftlint:enable line_length
