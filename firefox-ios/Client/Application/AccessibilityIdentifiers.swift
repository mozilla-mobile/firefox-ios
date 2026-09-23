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
enum AccessibilityIdentifiers {
    /// Used for toolbar/URL bar buttons since our classes are built that buttons can live in one or the other
    /// Using only those a11y identifiers for both ensures we have standard way to refer to buttons from iPad to iPhone
    enum Toolbar {
        static let settingsMenuButton = "TabToolbar.menuButton"
        static let homeButton = "TabToolbar.homeButton"
        static let readerModeButton = "TabLocationView.readerModeButton"
        static let readerModeWithSummarizerButton = "TabLocationView.readerModeWithSummarizerButton"
        static let reloadButton = "TabLocationView.reloadButton"
        static let shareButton = "TabLocationView.shareButton"
        static let summarizeButton = "TabLocationView.summarizeButton"
        static let backButton = "TabToolbar.backButton"
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

    enum Browser {
        enum TopTabs {
            static let collectionView = "Top Tabs View"
            static let privateModeButton = "TopTabsViewController.privateModeButton"
        }

        enum UrlBar {
            static let cancelButton = "urlBar-cancel"
        }

        enum KeyboardAccessory {
            static let doneButton = "KeyboardAccessory.doneButton"
            static let nextButton = "KeyboardAccessory.nextButton"
            static let previousButton = "KeyboardAccessory.previousButton"
            static let addressAutofillButton = "KeyboardAccessory.addressAutofillButton"
            static let creditCardAutofillButton = "KeyboardAccessory.creditCardAutofillButton"
            static let relayMaskAutofillButton = "KeyboardAccessory.relayMaskAutofillButton"
        }

        enum AddressToolbar {
            static let lockIcon = "AddressToolbar.lockIcon"
            static let lockIconOff = "AddressToolbar.lockIconOff"
            static let searchTextField = "AddressToolbar.address"
            static let searchEngine = "AddressToolbar.searchEngine"
            static let googleLensButton = "AddressToolbar.googleLensButton"
            static let googleLensTakePhotoAction = "AddressToolbar.googleLensTakePhotoAction"
            static let googleLensPhotoLibraryAction = "AddressToolbar.googleLensPhotoLibraryAction"
            static let leadingSkeleton = "AddressToolbar.leadingSkeleton"
            static let trailingSkeleton = "AddressToolbar.trailingSkeleton"
        }

        enum WebView {
            static let documentLoadingLabel = "WebView.documentLoadingLabel"
            static let automationTestLeakIndicator = "WebView.LeakIndicatorElement"
            static let contentView = "contentView"
        }

        enum Tab {
            static let automationTestLeakIndicator = "Tab.LeakIndicatorElement"
        }

        static let overKeyboardContainer = "Browser.overKeyboardContainer"
        static let headerContainer = "Browser.headerContainer"
        static let bottomContainer = "Browser.bottomContainer"
        static let bottomContentStackView = "Browser.bottomContentStackView"
        static let contentContainer = "Browser.contentContainer"
        static let statusBarOverlay = "Browser.statusBarOverlay"
        static let topBlurView = "Browser.topBlurView"
        static let bottomBlurView = "Browser.bottomBlurView"
        static let keyboardSpacer = "AddressToolbar.keyboardSpacer"
    }

    enum ContextualHints {
        static let actionButton = "ContextualHints.ActionButton"
    }

    enum MainMenu {
        enum SiteProtectionsHeaderView {
            static let header = "MainMenu.SiteProtectionHeader"
        }

        enum HeaderBanner {
            static let closeButton = "MainMenu.HeaderBanner.CloseMenuButton"
        }

        enum HeaderView {
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
        static let translatePage = "MainMenu.TranslatePage"
        static let trackigProtection = "shieldCheckmarkLarge"
    }

    enum WebCompatReporter {
        static let urlField = "WebCompatReporter.URLField"
        static let categoryMenu = "WebCompatReporter.CategoryMenu"
        static let subOption = "WebCompatReporter.SubOption"
        static let additionalDetails = "WebCompatReporter.AdditionalDetails"
        static let sendButton = "WebCompatReporter.SendButton"
        static let includeScreenshot = "WebCompatReporter.IncludeScreenshot"
        static let includeBlockedList = "WebCompatReporter.IncludeBlockedList"
        static let learnMore = "WebCompatReporter.LearnMore"

        enum Preview {
            static let closeButton = "WebCompatReporter.Preview.CloseButton"
            static let summary = "WebCompatReporter.Preview.Summary"
            static let technicalDataRow = "WebCompatReporter.Preview.TechnicalDataRow"
            /// Suffixed with the payload group id, e.g. `…SectionHeader.basic`.
            static let sectionHeader = "WebCompatReporter.Preview.SectionHeader"
            static let sectionContent = "WebCompatReporter.Preview.SectionContent"
        }
    }

    enum UnifiedSearch {
        enum BottomSheetRow {
            static let engine = "UnifiedSearch.BottomSheetRow.Engine"
            static let searchSettings = "UnifiedSearch.BottomSheetRow.SearchSettings"
        }
    }

    enum EnhancedTrackingProtection {
        enum MainScreen {
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

        enum DetailsScreen {
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

        enum BlockedTrackers {
            static let headerView = "BlockedTrackers.HeaderView"
            static let footerView = "BlockedTrackers.FooterView"
            static let mainView = "BlockedTrackers.MainView"
            static let containerView = "BlockedTrackers.BaseView"
            static let trackersTable = "BlockedTrackers.TrackersTable"
            static let totalTrackersBlockedLabel = "BlockedTrackers.TotalTrackersBlockedLabel"
            static let trackersBlockedInfoTextView = "BlockedTrackers.TrackersBlockedInfoTextView"

            static let crossSiteTitle = "BlockedTrackers.CrossSiteTitle"
            static let crossSiteImage = "BlockedTrackers.CrossSiteImage"

            static let fingerPrintersTitle = "BlockedTrackers.FingerPrintersTitle"
            static let fingerPrintersImage = "BlockedTrackers.FingerPrintersImage"

            static let trackingContentTitle = "BlockedTrackers.TrackingContentTitle"
            static let trackingContentImage = "BlockedTrackers.TrackingContentImage"

            static let socialMediaTitle = "BlockedTrackers.SocialMediaTitle"
            static let socialMediaImage = "BlockedTrackers.SocialMediaImage"
        }

        enum BlockedTrackersLearnMore {
            static let headerView = "BlockedTrackersLearnMore.HeaderView"
            static let containerView = "BlockedTrackersLearnMore.containerView"
            static let closeButton = "BlockedTrackersLearnMore.CloseButton"
            static let backButton = "BlockedTrackersLearnMore.BackButton"
            static let titleLabel = "BlockedTrackersLearnMore.TitleLabel"
        }

        enum CertificatesScreen {
            static let headerView = "CertificatesViewController.HeaderView"
        }
    }

    enum FirefoxHomepage {
        static let collectionView = "FxCollectionView"

        enum HomeTabBanner {
            static let titleLabel = "HomeTabBanner.titleLabel"
            static let descriptionLabel = "HomeTabBanner.descriptionLabel"
            static let descriptionLabel1 = "HomeTabBanner.descriptionLabel1"
            static let descriptionLabel2 = "HomeTabBanner.descriptionLabel2"
            static let descriptionLabel3 = "HomeTabBanner.descriptionLabel3"
            static let ctaButton = "HomeTabBanner.goToSettingsButton"
            static let closeButton = "HomeTabBanner.closeButton"
        }

        enum OtherButtons {
            static let logoID = "FxHomeLogoID"
            static let closeButton = "FirefoxHomepage.closeButton"
            static let quickAnswersButton = "FirefoxHomepage.quickAnswersButton"
        }

        enum MoreButtons {
            static let shortcuts = "shortcutsSectionMoreButton"
            static let bookmarks = "bookmarksSectionMoreButton"
            static let jumpBackIn = "jumpBackInSectionMoreButton"
        }

        enum SectionTitles {
            static let jumpBackIn = "jumpBackInTitle"
            static let bookmarks = "bookmarksTitle"
            static let merino = "pocketTitle"
            static let topSites = "topSitesTitle"
        }

        enum TopSites {
            static let itemCell = "TopSitesCell"

            enum AddShortcutAlert {
                static let view = "TopSites.AddShortcutAlert"
                static let urlTextField = "TopSites.AddShortcutAlert.URLTextField"
            }
        }

        enum SearchBar {
            static let itemCell = "SearchBarCell"
        }

        enum Pocket {
            static let allCategory = "Category.All"
            static let category = "Category"
            static let itemCell = "PocketCell"
            static let footerLearnMoreLabel = "Pocket.footerLearnMoreLabel"
        }

        enum JumpBackIn {
            static let itemCell = "JumpBackInCell"
        }

        enum Bookmarks {
            static let itemCell = "BookmarksCell"
        }

        enum SyncedTab {
            static let itemCell = "SyncedTabCell"
            static let cardTitle = "SyncedTabCardTitle"
            static let showAllButton = "SyncedTabShowAllButton"
            static let itemTitle = "SyncedTabItemTitle"
            static let favIconImage = "SyncedTabFavIconImage"
            static let descriptionLabel = "SyncedTabDescriptionLabel"
        }

        enum TrackerBlockerModule {
            static let containerPill = "TrackerBlockerModule.containerPill"
            static let shieldIcon = "TrackerBlockerModule.shieldIcon"
            static let titleLabel = "TrackerBlockerModule.titleLabel"

            enum Sheet {
                static let closeButton = "TrackerBlockerModule.Sheet.closeButton"
                static let shieldIcon = "TrackerBlockerModule.Sheet.shieldIcon"
                static let weeklyCountLabel = "TrackerBlockerModule.Sheet.weeklyCountLabel"
                static let headerLabel = "TrackerBlockerModule.Sheet.headerLabel"
                static let categoriesCard = "TrackerBlockerModule.Sheet.categoriesCard"
                static let totalPill = "TrackerBlockerModule.Sheet.totalPill"
                static func categoryRow(_ index: Int) -> String {
                    return "TrackerBlockerModule.Sheet.categoryRow.\(index)"
                }
            }
        }
    }

    enum GeneralizedIdentifiers {
        public static let back = "Back"
    }

    enum Microsurvey {
        enum Prompt {
            static let firefoxLogo = "Microsurvey.Prompt.FirefoxLogo"
            static let closeButton = "Microsurvey.Prompt.CloseButton"
            static let takeSurveyButton = "Microsurvey.Prompt.TakeSurveyButton"
        }

        enum Survey {
            static let firefoxLogo = "Microsurvey.Survey.FirefoxLogo"
            static let closeButton = "Microsurvey.Survey.CloseButton"
            static let privacyPolicyLink = "Microsurvey.Prompt.PrivacyPolicyLink"
            static let submitButton = "Microsurvey.Survey.SubmitButton"
            static let radioButton = "Microsurvey.Survey.RadioButton"
        }
    }

    enum Translations {
        enum AutoTranslatePrompt {
            static let messageLabel = "Translations.AutoTranslatePrompt.MessageLabel"
            static let enableButton = "Translations.AutoTranslatePrompt.EnableButton"
            static let closeButton = "Translations.AutoTranslatePrompt.CloseButton"
        }
    }

    enum TermsOfUse {
        static let logo = "TermsOfUse.Logo"
        static let title = "TermsOfUse.Title"
        static let description = "TermsOfUse.Description"
        static let acceptButton = "TermsOfUse.AcceptButton"
        static let remindMeLaterButton = "TermsOfUse.RemindMeLaterButton"
        static let linkTermsOfUse = "TermsOfUse.Link.TermsOfUse"
        static let linkPrivacyNotice = "TermsOfUse.Link.PrivacyNotice"
        static let linkLearnMore = "TermsOfUse.Link.LearnMore"
    }

    enum PrivateMode {
        static let dimmingView = "PrivateMode.DimmingView"
        enum Homepage {
            static let title = "PrivateMode.Homepage.Title"
            static let body = "PrivateMode.Homepage.Body"
            static let link = "PrivateMode.Homepage.Link"
            static let card = "PrivateMode.Homepage.MessageCard"
        }
    }

    enum ZeroSearch {
        static let dimmingView = "ZeroSearch.dimmingView"
    }

    enum TabTray {
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
        static let iPadSelectionBackgroundView =  "TabTraySelectorView.selectionBackgroundView"
    }

    enum LibraryPanels {
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

        enum BookmarksPanel {
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
            static let bookmarksFolder = "BookmarksDetail.ParentFolderSelector.FolderCell_0"
            static let folderSectionHeader = "BookmarksDetail.ParentFolderSelector.SectionHeader"
            static let changeLocationCell = "BookmarksDetail.ParentFolderSelector.ChangeLocationCell"
        }

        enum HistoryPanel {
            static let tableView = "History List"
            static let recentlyClosedCell = "HistoryPanel.recentlyClosedCell"
        }

        enum GroupedList {
            static let tableView = "grouped-items-table-view"
        }

        enum ReadingListPanel {
            static let tableView = "Reading list"
            static let emptyReadingList1 = "Welcome to your Reading List"
            static let emptyReadingList2 = "Open articles in Reader View by tapping the book icon when it appears in the title bar."
            static let emptyReadingList3 = "Save pages to your Reading List by tapping the book plus icon in the Reader View controls."
        }

        enum DownloadsPanel {
            static let tableView = "DownloadsTable"
        }
    }

    enum Onboarding {
        static let backgroundImage = "Onboarding.BackgroundImage"
        static let onboarding = "onboarding."
        static let closeButton = "CloseButton"
        static let pageControl = "PageControl"
        static let bottomSheetCloseButton = "Onboarding.bottomSheetCloseButton"

        enum VideoIntro {
            static let continueButton = "Onboarding.VideoIntro.ContinueButton"
        }
    }

    enum TermsOfService {
        static let root = "TermsOfService.Onboarding"
        static let logo = "TermsOfService.Logo"
        static let title = "TermsOfService.Title"
        static let subtitle = "TermsOfService.Subtitle"
        static let termsOfServiceAgreement = "TermsOfService.TermsOfServiceAgreement"
        static let privacyNoticeAgreement = "TermsOfService.PrivacyNoticeAgreement"
        static let manageDataCollectionAgreement = "TermsOfService.ManageDataCollectionAgreement"
        static let agreeAndContinueButton = "TermsOfService.AgreeAndContinueButton"
        static let doneButton = "TermsOfService.DoneButton"

        enum PrivacyNotice {
            static let title = "TermsOfService.PrivacyNotice.Title"
            static let doneButton = "TermsOfService.PrivacyNotice.DoneButton"

            enum CrashReports {
                static let contentStackView = "TermsOfService.PrivacyNotice.CrashReports.ContentStackView"
                static let actionContentView = "TermsOfService.PrivacyNotice.CrashReports.ActionContentView"
                static let actionTitleLabel = "TermsOfService.PrivacyNotice.CrashReports.ActionTitleLabel"
                static let actionSwitch = "TermsOfService.PrivacyNotice.CrashReports.ActionSwitch"
                static let actionDescriptionLabel = "TermsOfService.PrivacyNotice.CrashReports.ActionDescriptionLabel"
            }

            enum TechnicalData {
                static let contentStackView = "TermsOfService.PrivacyNotice.TechnicalData.ContentStackView"
                static let actionContentView = "TermsOfService.PrivacyNotice.TechnicalData.ActionContentView"
                static let actionTitleLabel = "TermsOfService.PrivacyNotice.TechnicalData.ActionTitleLabel"
                static let actionSwitch = "TermsOfService.PrivacyNotice.TechnicalData.ActionSwitch"
                static let actionDescriptionLabel = "TermsOfService.PrivacyNotice.TechnicalData.ActionDescriptionLabel"
            }
        }
    }

    enum Upgrade {
        static let upgrade = "upgrade."
        static let closeButton = "Upgrade.CloseButton"
        static let pageControl = "Upgrade.PageControl"
    }

    enum Settings {
        static let title = "Settings"
        static let tableViewController = "AppSettingsTableViewController.tableView"
        static let navigationBarItem = "AppSettingsTableViewController.navigationItem.rightBarButtonItem"

        enum AIControls {
            static let title = "AIControlsSettings"
        }

        enum Appearance {
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

        enum AppIconSelection {
            static let settingsRowTitle = "AppIconSelectionTitle"
        }

        enum DefaultBrowser {
            static let defaultBrowser = "DefaultBrowserSettings"
        }

        enum Homepage {
            static let homeSettings = "Home"
            static let homePageNavigationBar = "Homepage"

            enum StartAtHome {
                static let afterFourHours = "StartAtHomeAfterFourHours"
                static let always = "StartAtHomeAlways"
                static let disabled = "StartAtHomeDisabled"
            }

            enum CustomizeFirefox {
                enum Shortcuts {
                    static let settingsPage = "TopSitesSettings"
                    static let topSitesRows = "TopSitesRows"
                }

                enum Wallpaper {
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

        enum FirefoxAccount {
            static let continueButton = "Sign up or sign in"
            static let emailTextField = "Enter your email"
            static let fxaNavigationBar = "Sync and Save Data"
            static let fxaSettingsButton = "Sync and Save Data"
            static let fxaSignInButton = "EmailSignIn.button"
            static let qrButton = "QRCodeSignIn.button"
            static let qrScanFailedAlertOkButton = "qrCodeAlert.okButton"
            static let signInButton = "Sign in"
        }

        enum Search {
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
            // These are based on the matching `PrefsKeys.SearchSettings` keys
            static let showPrivateModeSearchSuggestionsSwitch = "ShowPrivateModeSearchSuggestionsKey"
            static let showBrowsingHistorySuggestionsSwitch = "FirefoxSuggestBrowsingHistorySuggestions"
            static let showBookmarksSuggestionsSwitch = "FirefoxSuggestBookmarksSuggestions"
            static let showSyncedTabsSuggestionsSwitch = "FirefoxSuggestSyncedTabsSuggestions"
            static let showNonSponsoredSuggestionsSwitch = "FirefoxSuggestShowNonSponsoredSuggestions"
            static let showSponsoredSuggestionsSwitch = "FirefoxSuggestShowSponsoredSuggestions"
            static let backButtoniOS26 = "BackButton"
            static let backButton = "Settings"
        }

        enum AdvancedAccountSettings {
            static let title = "AdvancedAccount.Setting"
        }

        enum Logins {
            static let title = "Logins"

            enum Passwords {
                static let saveLogins = "saveLogins"
                static let showLoginsInAppMenu = "showLoginsInAppMenu"
                static let searchPasswords = "Search passwords"
                static let emptyList = "No passwords found"
                static let addButton = "Add"

                enum AddLogin {
                    static let saveButton = "Save"
                    static let cancelButton = "Cancel"
                    static let addCredential = "Add Credential"
                }
            }
        }

        enum CreditCards {
            static let title = "AutofillCreditCard"

            enum AutoFillCreditCard {
                static let autoFillCreditCards = "Payment Methods"
                static let addCard = "Add Card"
                static let saveAutofillCards = "Save and Fill Payment Methods"
                static let savedCards = "SAVED CARDS"
            }

            enum AddCreditCard {
                static let addCreditCard = "Add Card"
                static let nameOnCard = "Name on Card"
                static let cardNumber = "Card Number"
                static let expiration = "Expiration MM / YY"
                static let close = "Close"
                static let save = "Save"
            }

            enum ViewCreditCard {
                static let viewCard = "View Card"
                static let edit = "Edit"
                static let close = "Close"
            }

            enum EditCreditCard {
                static let editCreditCard = "Edit Card"
                static let removeCard = "Remove Card"
                static let removeThisCard = "Remove Card?"
                static let cancel = "Cancel"
                static let remove = "Remove"
            }
        }

        enum ClearData {
            static let title = "ClearPrivateData"
            static let websiteDataSection = "WebsiteData"
            static let clearPrivateDataSection = "ClearPrivateData"
            static let clearAllWebsiteData = "ClearAllWebsiteData"
        }

        enum Notifications {
            static let title = "NotificationsSetting"
        }

        enum CreditCard {
            static let title = "AutofillCreditCard"
        }

        enum Address {
            static let title = "AutofillAddress"

            enum Addresses {
                static let title = "Addresses"
                static let addAddress = "Add address"
                static let addressCell = "AddressCell"
            }
        }

        enum ConnectSetting {
            static let title = "SignInToSync"
        }

        enum ContentBlocker {
            static let title = "TrackingProtection"
        }

        enum NewTab {
            static let title = "NewTab"
        }

        enum NoImageMode {
            static let title = "NoImageMode"
        }

        enum BlockPopUp {
            static let title = "BlockPopUp"
        }

        enum OpenWithMail {
            static let title = "OpenWith.Setting"
        }

        enum OfferToOpen {
            static let title = "showClipboardBar"
        }

        enum BlockExternal {
            static let title = "blockOpeningExternalApps"
        }

        enum ShowLink {
            static let title = "showLinkPreviews"
        }

        enum ClosePrivateTabs {
            static let title = "ClosePrivateTabs"
        }

        enum SearchBar {
            static let searchBarSetting = "SearchBarSetting"
            static let topSetting = "TopSearchBar"
            static let bottomSetting = "BottomSearchBar"
        }

        enum NavigationToolbar {
            static let homeButton = "HomeButton"
            static let newTabButton = "NewTabButton"
        }

        enum SendData {
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

        enum PrivacyPolicy {
            static let title = "PrivacyPolicy"
        }

        enum ShowIntroduction {
            static let title = "ShowTour"
        }

        enum SentFromFirefox {
            static let whatsApp = "SentFromFirefox.WhatsApp"
        }

        enum SendFeedback {
            static let title = "SendFeedback"
        }

        enum Help {
            static let title = "Help"
        }

        enum RateOnAppStore {
            static let title = "RateOnAppStore"
        }

        enum Licenses {
            static let title = "Licenses"
        }

        enum YourRights {
            static let title = "YourRights"
        }

        enum Siri {
            static let title = "SiriSettings"
        }

        enum Browsing {
            static let title = "BrowsingSettings"
            static let tabs = "TABS"
            static let links = "LINKS"
            static let blockPopUps = "blockPopups"
            static let autoPlay = "AutoplaySettings"
            static let blockImages = "NoImageModeStatus"
            static let adBlockerTitle = "AdBlocker"
            static let adBlockerLearnMore = "AdBlockerLearnMore"
            static let backgroundAudio = "BackgroundAudio"
        }

        enum Summarize {
            static let title = "SummarizeSettings"
            static let summarizeContentSwitch = "summarizeContentFeature"
            static let shakeGestureSwitch = "shakeGestureEnabledKey"
            static let languageCell = "summarizeLanguageCell"
        }

        enum Theme {
            static let title = "DisplayThemeOption"
        }

        enum Translation {
            static let title = "Settings.Translation.Title"
            // This is based on `PrefsKeys.Settings.translationsFeature`
            static let toggleSwitch = "settings.translationFeature"
            static let autoTranslateSwitch = "settings.translationAutoTranslate"
            static let navigationBar = "Settings.Translation.navigationBar"
            static let backButtoniOS26 = "BackButton"
            static let backButton = "Settings"
            static let languagePickerList = "Settings.Translation.LanguagePickerList"
        }

        enum QuickAnswers {
            static let title = "Settings.QuickAnswers.Title"
            static let learnMoreButton = "Settings.QuickAnswers.LearnMoreButton"
        }

        enum BlockImages {
            static let title = "Block Images"
        }

        enum AutofillsPasswords {
            static let title = "AutofillsPasswordsSettings"
        }

        enum RelayMask {
            static let title = "RelayMaskSettings"
            static let manageMasksButton = "manageEmailMasks"
        }

        enum Passwords {
            static let usernameField = "usernameField"
            static let passwordField = "passwordField"
            static let websiteField = "websiteField"
            static let onboardingContinue = "onboardingContinue"
            static let onboardingLearnMore = "Passwords.onboardingLearnMore"
            static let addCredentialButton = "addCredentialButton"
            static let editButton = "editButton"
        }

        enum Version {
            static let title = "FxVersion"
        }

        enum TrackingProtection {
            static let basic = "Settings.TrackingProtectionOption.BlockListBasic"
            static let strict = "Settings.TrackingProtectionOption.BlockListStrict"
        }

        enum Autoplay {
            static let allowAudioAndVideo = "AllowAudioAndVideo"
            static let blockAudio = "BlockAudio"
            static let blockAudioAndVideo = "BlockAudioAndVideo"
        }

        enum Debug {
            static let offloadBackgroundWebViews = "Settings.Debug.OffloadBackgroundWebViews"
        }
    }

    enum Summarizer {
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

    enum ShareTo {
        enum HelpView {
            static let doneButton = "doneButton"
            static let topMessageLabel = "topMessageLabel"
            static let bottomMessageLabel = "bottomMessageLabel"
        }
    }

    enum SurveySurface {
        static let takeSurveyButton = "takeSurveyButton"
        static let dismissButton = "dismissSurveyButton"
        static let textLabel = "surveyDescriptionLabel"
        static let imageView = "surveyImageView"
    }

    enum Photon {
        static let closeButton = "PhotonMenu.close"
        static let view = "Action Sheet"
        static let tableView = "Context Menu"
        static let pasteAction = "pasteAction"
        static let pasteAndGoAction = "pasteAndGoAction"
        static let copyAddressAction = "copyAddressAction"
    }

    enum Alert {
        static let cancelDownloadResume = "cancelDownloadAlert.resume"
        static let cancelDownloadCancel = "cancelDownloadAlert.cancel"
    }

    enum ZoomPageBar {
        static let zoomPageZoomInButton = "ZoomPage.zoomInButton"
        static let zoomPageZoomOutButton = "ZoomPage.zoomOutButton"
        static let zoomPageZoomLevelLabel = "ZoomPage.zoomLevelLabel"
        static let doneButton = "find.doneButton"
    }

    enum FindInPage {
        static let findInPageCloseButton = "find.doneButton"
        static let findNextButton = "find.nextButton"
        static let findPreviousButton = "find.previousButton"
    }

    enum RememberCreditCard {
        static let rememberCreditCardHeader = "RememberCreditCard.Header"
        static let yesButton = "RememberCreditCard.yesButton"
        static let manageCardsButton = "RememberCreditCard.manageCardsButton"
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

    enum NativeErrorPage {
        static let foxImage = "NativeErrorPage.foxImage"
        static let titleLabel = "NativeErrorPage.titleLabel"
        static let errorDescriptionLabel = "NativeErrorPage.errorDescriptionLabel"
        static let reloadButton = "NativeErrorPage.reloadButton"
        static let waybackButton = "NativeErrorPage.waybackButton"
        static let waybackErrorCard = "NativeErrorPage.waybackErrorCard"
        static let waybackErrorLabel = "NativeErrorPage.waybackErrorLabel"
        static let waybackErrorButton = "NativeErrorPage.waybackRetryButton"
        static let goBackButton = "NativeErrorPage.goBackButton"
        static let proceedButton = "NativeErrorPage.proceedButton"
        static let advancedSectionHeader = "NativeErrorPage.advancedSectionHeader"
        static let viewCertificateLink = "NativeErrorPage.viewCertificateLink"
        static let learnMoreLink = "NativeErrorPage.learnMoreLink"
        static let waybackFooterTextView = "NativeErrorPage.waybackFooterTextView"
    }

    enum SaveLoginAlert {
        static let saveButton = "SaveLoginPrompt.saveLoginButton"
        static let notNowButton = "SaveLoginPrompt.dontSaveButton"
        static let updateButton = "UpdateLoginPrompt.updateButton"
        static let dontUpdateButton = "UpdateLoginPrompt.dontUpdateButton"
    }

    enum ReaderMode {
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

        enum BarView {
            static let readStatusButton = "ReaderModeBarView.readStatusButton"
            static let settingsButton = "ReaderModeBarView.settingsButton"
            static let listStatusButton = "ReaderModeBarView.listStatusButton"
            static let summarizerButton = "ReaderModeBarView.summarizerButton"
        }
    }
}
// swiftlint:enable line_length
