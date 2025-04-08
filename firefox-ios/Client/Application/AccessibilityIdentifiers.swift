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
        static let urlBarBorder = "TabToolbar.urlBarBorder"
        static let settingsMenuButton = "TabToolbar.menuButton"
        static let homeButton = "TabToolbar.homeButton"
        static let trackingProtection = "TabLocationView.trackingProtectionButton"
        static let readerModeButton = "TabLocationView.readerModeButton"
        static let reloadButton = "TabLocationView.reloadButton"
        static let shareButton = "TabLocationView.shareButton"
        static let backButton = "TabToolbar.backButton"
        static let fireButton = "TabToolbar.fireButton"
        static let forwardButton = "TabToolbar.forwardButton"
        static let tabsButton = "TabToolbar.tabsButton"
        static let addNewTabButton = "TabToolbar.addNewTabButton"
        static let searchButton = "TabToolbar.searchButton"
        static let stopButton = "TabToolbar.stopButton"
        static let bookmarksButton = "TabToolbar.libraryButton"
        static let shoppingButton = "TabLocationView.shoppingButton"
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

        struct KeyboardAccessory {
            static let doneButton = "KeyboardAccessory.doneButton"
            static let nextButton = "KeyboardAccessory.nextButton"
            static let previousButton = "KeyboardAccessory.previousButton"
            static let addressAutofillButton = "KeyboardAccessory.addressAutofillButton"
            static let creditCardAutofillButton = "KeyboardAccessory.creditCardAutofillButton"
        }

        struct AddressToolbar {
            static let lockIcon = "AddressToolbar.lockIcon"
            static let searchTextField = "AddressToolbar.address"
            static let searchEngine = "AddressToolbar.searchEngine"
        }

        struct ToolbarButtons {
            static let qrCode = "Toolbar.QRCode.button"
        }

        struct WebView {
            static let documentLoadingLabel = "WebView.documentLoadingLabel"
        }
    }

    struct ContextualHints {
        static let actionButton = "ContextualHints.ActionButton"
    }

    struct MainMenu {
        struct HeaderView {
            static let mainButton = "MainMenu.MainButton"
            static let closeButton = "MainMenu.CloseMenuButton"
        }

        struct NavigationHeaderView {
            static let backButton = "MainMenu.BackButton"
            static let title = "MainMenu.Title"
            static let closeButton = "MainMenu.CloseMenuButton"
        }

        static let mainMenu = "MainMenu.Menu"
        static let newTab = "MainMenu.NewTab"
        static let newPrivateTab = "MainMenu.NewPrivateTab"
        static let switchToDesktopSite = "MainMenu.SwitchToDesktopSite"
        static let findInPage = "MainMenu.FindInPage"
        static let tools = "MainMenu.Tools"
        static let save = "MainMenu.Save"
        static let bookmarks = "MainMenu.Bookmarks"
        static let history = "MainMenu.History"
        static let downloads = "MainMenu.Downloads"
        static let passwords = "MainMenu.Passwords"
        static let getHelp = "MainMenu.GetHelp"
        static let settings = "MainMenu.Settings"
        static let whatsNew = "MainMenu.WhatsNew"
        static let customizeHomepage = "MainMenu.CustomizeHomepage"
        static let saveToReadingList = "MainMenu.SaveToReadingList"
        static let addToShortcuts = "MainMenu.AddToShortcuts"
        static let bookmarkThisPage = "MainMenu.BookmarkThisPage"
        static let print = "MainMenu.Print"
        static let share = "MainMenu.Share"
        static let saveAsPDF = "MainMenu.SaveAsPDF"
        static let reportBrokenSite = "MainMenu.ReportBrokenSite"
        static let readerView = "MainMenu.ReaderViewOn"
        static let nightMode = "MainMenu.NightModeOn"
        static let zoom = "MainMenu.Zoom"
    }

    struct UnifiedSearch {
        struct BottomSheetRow {
            static let engine = "UnifiedSearch.BottomSheetRow.Engine"
            static let searchSettings = "UnifiedSearch.BottomSheetRow.SearchSettings"
        }
    }

    struct EnhancedTrackingProtection {
        struct MainScreen {
            static let clearCookiesButton = "TrackingProtection.ClearCookiesButton"
            static let trackingProtectionSettingsButton = "TrackingProtection.SettingsButton"
            static let foxImage = "TrackingProtection.FoxStatusImage"
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
            static let toggleViewBodyLabel = "TrackingProtection.ToggleViewBodyLabel"
            static let closeButton = "TrackingProtection.CloseButton"
            static let faviconImage = "TrackingProtection.FaviconImage"
        }

        struct DetailsScreen {
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
        }

        struct BlockedTrackers {
            static let headerView = "BlockedTrackers.HeaderView"
            static let mainView = "BlockedTrackers.MainView"
            static let containerView = "BlockedTrackers.BaseView"
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
            static let customizeHome = "FxHomeCustomizeHomeSettingButton"
            static let closeButton = "FirefoxHomepage.closeButton"
        }

        struct MoreButtons {
            static let bookmarks = "bookmarksSectionMoreButton"
            static let jumpBackIn = "jumpBackInSectionMoreButton"
            static let historyHighlights = "historyHighlightsSectionMoreButton"
            static let customizeHomePage = "FxHomeCustomizeHomeSettingButton"
        }

        struct SectionTitles {
            static let jumpBackIn = "jumpBackInTitle"
            static let bookmarks = "bookmarksTitle"
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

    struct PrivateMode {
        static let dimmingView = "PrivateMode.DimmingView"
        struct Homepage {
            static let title = "PrivateMode.Homepage.Title"
            static let body = "PrivateMode.Homepage.Body"
            static let link = "PrivateMode.Homepage.Link"
            static let card = "PrivateMode.Homepage.MessageCard"
        }
    }

    struct Shopping {
        static let sheetHeaderTitle = "Shopping.Sheet.HeaderTitle"
        static let sheetHeaderBetaLabel = "Shopping.Sheet.HeaderBetaLabel"
        static let sheetCloseButton = "Shopping.Sheet.CloseButton"

        struct InfoComingSoonCard {
            static let card = "Shopping.InfoComingSoonCard.Card"
            static let title = "Shopping.InfoComingSoonCard.Title"
            static let description = "Shopping.InfoComingSoonCard.Description"
        }

        struct ReportingProductFeedbackCard {
            static let card = "Shopping.ReportingProductFeedbackCard.Card"
            static let title = "Shopping.ReportingProductFeedbackCard.Title"
            static let description = "Shopping.ReportingProductFeedbackCard.Description"
        }

        struct ReportProductInStockCard {
            static let card = "Shopping.ReportProductInStockCard.Card"
            static let title = "Shopping.ReportProductInStockCard.Title"
            static let description = "Shopping.ReportProductInStockCard.Description"
            static let primaryAction = "Shopping.ReportProductInStockCard.PrimaryAction"
        }

        struct AnalysisProgressInfoCard {
            static let card = "Shopping.AnalysisProgressInfoCard.Card"
            static let title = "Shopping.AnalysisProgressInfoCard.Title"
        }

        struct NeedsAnalysisInfoCard {
            static let card = "Shopping.NeedsAnalysisInfoCard.Card"
            static let title = "Shopping.NeedsAnalysisInfoCard.Title"
            static let primaryAction = "Shopping.NeedsAnalysisInfoCard.PrimaryAction"
        }

        struct NotEnoughReviewsInfoCard {
            static let card = "Shopping.NotEnoughReviewsInfoCard.Card"
            static let title = "Shopping.NotEnoughReviewsInfoCard.Title"
            static let description = "Shopping.NotEnoughReviewsInfoCard.Description"
        }

        struct DoesNotAnalyzeReviewsInfoCard {
            static let card = "Shopping.DoesNotAnalyzeReviewsInfoCard.Card"
            static let title = "Shopping.DoesNotAnalyzeReviewsInfoCard.Title"
            static let description = "Shopping.DoesNotAnalyzeReviewsInfoCard.Description"
        }

        struct GenericErrorInfoCard {
            static let card = "Shopping.GenericErrorInfoCard.Card"
            static let title = "Shopping.GenericErrorInfoCard.Title"
            static let description = "Shopping.GenericErrorInfoCard.Description"
        }

        struct NoConnectionCard {
            static let card = "Shopping.NoConnectionCard.Card"
            static let title = "Shopping.NoConnectionCard.Title"
            static let description = "Shopping.NoConnectionCard.Description"
        }

        struct ConfirmationCard {
            static let card = "Shopping.ConfirmationCard.Card"
            static let title = "Shopping.ConfirmationCard.Title"
            static let primaryAction = "Shopping.ConfirmationCard.PrimaryAction"
        }

        struct ReliabilityCard {
            static let card = "Shopping.ReliabilityCard.Card"
            static let title = "Shopping.ReliabilityCard.Title"
            static let ratingLetter = "Shopping.ReliabilityCard.RatingLetter"
            static let ratingDescription = "Shopping.ReliabilityCard.RatingDescription"
        }

        struct AdjustRating {
            static let card = "Shopping.AdjustRating.Card"
            static let title = "Shopping.ReliabilityCard.Title"
            static let description = "Shopping.ReliabilityCard.Description"
        }

        struct HighlightsCard {
            static let card = "Shopping.HighlightsCard.Card"
            static let title = "Shopping.HighlightsCard.Title"
            static let moreButton = "Shopping.HighlightsCard.MoreButton"
            static let lessButton = "Shopping.HighlightsCard.LessButton"

            static let groupPriceTitle = "Shopping.HighlightsCard.Group.Price.Title"
            static let groupPriceIcon = "Shopping.HighlightsCard.Group.Price.Icon"
            static let groupPriceHighlightsLabel = "Shopping.HighlightsCard.Group.Price.HighlightsLabel"

            static let groupQualityTitle = "Shopping.HighlightsCard.Group.Quality.Title"
            static let groupQualityIcon = "Shopping.HighlightsCard.Group.Quality.Icon"
            static let groupQualityHighlightsLabel = "Shopping.HighlightsCard.Group.Quality.HighlightsLabel"

            static let groupCompetitivenessTitle = "Shopping.HighlightsCard.Group.Competitiveness.Title"
            static let groupCompetitivenessIcon = "Shopping.HighlightsCard.Group.Competitiveness.Icon"
            static let groupCompetitivenessHighlightsLabel = "Shopping.HighlightsCard.Group.Competitiveness.HighlightsLabel"

            static let groupShippingTitle = "Shopping.HighlightsCard.Group.Shipping.Title"
            static let groupShippingIcon = "Shopping.HighlightsCard.Group.Shipping.Icon"
            static let groupShippingHighlightsLabel = "Shopping.HighlightsCard.Group.Shipping.HighlightsLabel"

            static let groupPackagingTitle = "Shopping.HighlightsCard.Group.Packaging.Title"
            static let groupPackagingIcon = "Shopping.HighlightsCard.Group.Packaging.Icon"
            static let groupPackagingHighlightsLabel = "Shopping.HighlightsCard.Group.Packaging.HighlightsLabel"
        }

        struct SettingsCard {
            static let card = "Shopping.SettingsCard.Card"
            static let title = "Shopping.SettingsCard.Title"
            static let expandButton = "Shopping.SettingsCard.ExpandButton"
            static let productsRecommendedGroup = "Shopping.SettingsCard.ProductsRecommendedGroup"
            static let turnOffButton = "Shopping.SettingsCard.TurnOffButton"
            static let footerTitle = "Shopping.SettingCard.footerTitle"
            static let footerAction = "Shopping.SettingCard.footerAction"
        }

        struct NoAnalysisCard {
            static let card = "Shopping.NoAnalysisCard.Card"
            static let headlineTitle = "Shopping.NoAnalysisCard.HeadlineTitle"
            static let bodyTitle = "Shopping.NoAnalysisCard.BodyTitle"
            static let analyzerButtonTitle = "Shopping.NoAnalysisCard.AnalyzerButtonTitle"
        }

        struct ReviewQualityCard {
            static let card = "Shopping.ReviewQualityCard.Card"
            static let title = "Shopping.ReviewQualityCard.Title"
            static let expandButton = "Shopping.ReviewQualityCard.ExpandButton"
            static let headlineLabel = "Shopping.ReviewQualityCard.HeadlineLabel"
            static let subHeadlineLabel = "Shopping.ReviewQualityCard.SubHeadlineLabel"
            static let reliableReviewsLabel = "Shopping.ReviewQualityCard.ReliableReviewsLabel"
            static let mixedReviewsLabel = "Shopping.ReviewQualityCard.MixedReviewsLabel"
            static let unreliableReviewsLabel = "Shopping.ReviewQualityCard.UnreliableReviewsLabel"
            static let adjustedRatingLabel = "Shopping.ReviewQualityCard.AdjustedRatingLabel"
            static let highlightsLabel = "Shopping.ReviewQualityCard.HighlightsLabel"
            static let learnMoreButtonTitle = "Shopping.ReviewQualityCard.LearnMoreButtonTitle"
        }

        struct OptInCard {
            static let card = "Shopping.OptInCard.Card"
            static let headerTitle = "Shopping.OptInCard.HeaderTitle"
            static let optInCopy = "Shopping.OptInCard.BodyFirstParagraph"
            static let disclaimerText = "Shopping.OptInCard.DisclaimerText"
            static let learnMoreButton = "Shopping.OptInCard.LearnMoreButton"
            static let termsOfUseButton = "Shopping.OptInCard.TermsOfUseButton"
            static let privacyPolicyButton = "Shopping.OptInCard.PrivacyPolicyButton"
            static let mainButton = "Shopping.OptInCard.MainButton"
            static let secondaryButton = "Shopping.OptInCard.SecondaryButton"
        }

        struct AdCard {
            static let card = "Shopping.AdCard.Card"
            static let title = "Shopping.AdCard.Title"
            static let price = "Shopping.AdCard.PriceLabel"
            static let starRating = "Shopping.AdCard.starRating"
            static let productTitle = "Shopping.AdCard.ProductTitle"
            static let description = "Shopping.AdCard.Description"
            static let footer = "Shopping.AdCard.Footer"
            static let defaultImage = "Shopping.AdCard.DefaultImage"
            static let productImage = "Shopping.AdCard.ProductImage"
        }
    }

    struct TabTray {
        static let deleteCloseAllButton = "TabTrayController.deleteButton.closeAll"
        static let deleteCancelButton = "TabTrayController.deleteButton.cancel"
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
        static let closeButton = "badge mask"

        struct InactiveTabs {
            static let headerLabel = "InactiveTabs.headerLabel"
            static let headerButton = "InactiveTabs.headerButton"
            static let headerView = "InactiveTabs.header"
            static let cellLabel = "InactiveTabs.cell.label"
            static let footerView = "InactiveTabs.footer"
            static let deleteButton = "InactiveTabs.deleteButton"
        }
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
                static let recentVisited = "Recently Visited"
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
            static let disableSearchSuggestsInPrivateMode = "PrivateMode.DisableSearchSuggests"
            static let showSearchSuggestions = "FirefoxSuggestShowSearchSuggestions"
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

        struct SendData {
            static let sendTechnicalDataTitle = "SendTechnicalData"
            static let sendCrashReportsTitle = "SendCrashReports"
            static let sendDailyUsagePingTitle = "SendDailyUsagePing"
            static let studiesTitle = "StudiesToggle"
            static let sendTechnicalDataLearnMoreButton = "SendTechnicalDataLearnMoreButton"
            static let sendCrashReportsLearnMoreButton = "SendCrashReportsLearnMoreButton"
            static let sendDailyUsagePingLearnMoreButton = "SendDailyUsagePingLearnMoreButton"
            static let studiesLearnMoreButton = "StudiesLearnMoreButton"
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
            static let inactiveTabsSwitch = "Inactive Tabs"
            static let blockPopUps = "blockPopups"
            static let autoPlay = "AutoplaySettings"
            static let blockImages = "NoImageModeStatus"
        }

        struct Theme {
            static let title = "DisplayThemeOption"
        }

        struct BlockImages {
            static let title = "Block Images"
        }

        struct AutofillsPasswords {
            static let title = "AutofillsPasswordsSettings"
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
