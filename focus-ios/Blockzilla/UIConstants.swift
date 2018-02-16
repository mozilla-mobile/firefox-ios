/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

struct UIConstants {
    struct colors {
        static let background = UIColor(rgb: 0x272727)
        static let buttonHighlight = UIColor(rgb: 0x333333)
        static let cellSelected = UIColor(rgb: 0x38383D)
        static let copyButtonBorder = UIColor(rgb: 0x5F6368, alpha: 0.8)
        static let defaultFont = UIColor(rgb: 0xE1E5EA)
        static let deleteButtonBackground = UIColor(white: 1, alpha: 0.2)
        static let deleteButtonBorder = UIColor(white: 1, alpha: 0.5)
        static let firstRunButton = UIColor.white
        static let firstRunNextButton = UIColor(rgb: 0x9400FF)
        static let firstRunButtonBackground = UIColor(white: 1, alpha: 0.2)
        static let firstRunButtonBorder = UIColor(white: 1, alpha: 0.3)
        static let firstRunDisclaimer = UIColor(white: 1, alpha: 0.5)
        static let firstRunMessage = UIColor(rgb: 0x737373)
        static let firstRunTitle = UIColor(rgb: 0x212121)
        static let focusLightBlue = UIColor(rgb: 0x00A7E0)
        static let focusDarkBlue = UIColor(rgb: 0x005DA5)
        static let focusBlue = UIColor(rgb: 0x00A7E0)
        static let focusGreen = UIColor(rgb: 0x7ED321)
        static let focusMaroon = UIColor(rgb: 0xE63D2F)
        static let focusOrange = UIColor(rgb: 0xF26C23)
        static let focusRed = UIColor(rgb: 0xE63D2F)
        static let focusViolet = UIColor(rgb: 0x95368C)
        static let gradientBackground = UIColor(rgb: 0x363B40)
        static let gradientLeft = UIColor(rgb: 0xD70022)
        static let gradientMiddle = UIColor(rgb: 0xB5007F)
        static let gradientRight = UIColor(rgb: 0x440071)
        static let navigationButton = UIColor(rgb: 0xFFFFFF)
        static let navigationTitle = UIColor(rgb: 0xFFFFFF)
        static let overlayBackground = UIColor(white: 0, alpha: 0.8)
        static let progressBar = UIColor(rgb: 0xC86DD7)
        static let settingsButtonBorder = UIColor(rgb: 0x5F6368, alpha: 0.8)
        static let settingsTextLabel = UIColor(rgb: 0xFFFFFF)
        static let settingsDetailLabel = UIColor(rgb: 0xB2B2B2)
        static let settingsSeparator = UIColor(rgb: 0x414146)
        static let settingsLink = UIColor(rgb: 0x0A84FF)
        static let settingsDisabled = UIColor(rgb: 0xB2B2B2)
        static let tableSectionHeader = UIColor(rgb: 0xFFFFFF)
        static let toastBackground = UIColor(rgb: 0x414146)
        static let toastText = UIColor.white
        static let toggleOn = UIColor(rgb: 0x0080FF)
        static let toggleOff = UIColor(rgb: 0x585E64)
        static let toolbarBorder = UIColor(rgb: 0x5F6368)
        static let toolbarButtonNormal = UIColor.darkGray
        static let urlTextBackground = UIColor(white: 1, alpha: 0.2)
        static let urlTextFont = UIColor.white
        static let urlTextHighlight = UIColor(rgb: 0xB5007F)
        static let urlTextPlaceholder = UIColor(white: 1, alpha: 0.4)
        static let urlTextShadow = UIColor.black

        static let inputPlaceholder = UIColor(rgb: 0xb2b2b2)

        static let trackingProtectionPrimary = UIColor(rgb: 0xFFFFFF)
        static let trackingProtectionSecondary = UIColor(rgb: 0xB2B2B2)
        static let trackingProtectionBreakdownBackground = UIColor(rgb: 0x414146)
        static let trackingProtectionLearnMore = UIColor(rgb: 0x0A84FF)
    }

    struct fonts {
        static let aboutText = UIFont.systemFont(ofSize: 14)
        static let cancelButton = UIFont.systemFont(ofSize: 15)
        static let copyButton = UIFont.systemFont(ofSize: 15)
        static let copyButtonQuery = UIFont.boldSystemFont(ofSize: 15)
        static let deleteButton = UIFont.systemFont(ofSize: 11)
        static let firstRunDisclaimer = UIFont.systemFont(ofSize: 14)
        static let firstRunMessage = UIFont.systemFont(ofSize: 14)
        static let firstRunTitle = UIFont.systemFont(ofSize: 18)
        static let firstRunButton = UIFont.systemFont(ofSize: 16)
        static let homeLabel = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.ultraLight)
        static let safariInstruction = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
        static let searchButton = UIFont.systemFont(ofSize: 15)
        static let searchButtonQuery = UIFont.boldSystemFont(ofSize: 15)
        static let settingsHomeButton = UIFont.systemFont(ofSize: 15)
        static let settingsOverlayButton = UIFont.systemFont(ofSize: 13)
        static let tableSectionHeader = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)
        static let toast = UIFont.systemFont(ofSize: 12)
        static let urlText = UIFont.systemFont(ofSize: 15)
        static let truncatedUrlText = UIFont.systemFont(ofSize: 12)
        static let settingsInputLabel = UIFont.systemFont(ofSize: 18)
        static let settingsDescriptionText = UIFont.systemFont(ofSize: 12)
        static let shareTrackerStatsLabel = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.light)
    }

    struct layout {
        static let browserToolbarDisabledOpacity: CGFloat = 0.3
        static let browserToolbarHeight: CGFloat = 44
        static let copyButtonAnimationDuration: TimeInterval = 0.1
        static let deleteAnimationDuration: TimeInterval = 0.15
        static let lockIconInset: Float = 4
        static let navigationDoneOffset: Float = -10
        static let overlayAnimationDuration: TimeInterval = 0.25
        static let progressVisibilityAnimationDuration: TimeInterval = 0.25
        static let searchButtonInset: CGFloat = 15
        static let searchButtonAnimationDuration: TimeInterval = 0.1
        static let toastAnimationDuration: TimeInterval = 0.3
        static let toastDuration: TimeInterval = 1.5
        static let toolbarFadeAnimationDuration = 0.25
        static let toolbarButtonInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        static let urlBarCornerRadius: CGFloat = 2
        static let urlBarHeight: CGFloat = 54
        static let collapsedUrlBarHeight: CGFloat = 22
        static let urlBarTransitionAnimationDuration: TimeInterval = 0.2
        static let urlBarMargin: CGFloat = 8
        static let urlBarHeightInset: CGFloat = 10
        static let urlBarShadowOpacity: Float = 0.3
        static let urlBarShadowRadius: CGFloat = 2
        static let urlBarShadowOffset = CGSize(width: 0, height: 2)
        static let urlBarWidthInset: CGFloat = 8
    }

    struct strings {
        static let aboutLearnMoreButton = NSLocalizedString("About.learnMoreButton", value: "Learn more", comment: "Button on About screen")
        static let aboutMissionLabel = NSLocalizedString("About.missionLabel", value: "%@ is produced by Mozilla. Our mission is to foster a healthy, open Internet.", comment: "Label on About screen")
        static let aboutPrivateBulletHeader = NSLocalizedString("About.privateBulletHeader", value: "Use it as a private browser:", comment: "Label on About screen")
        static let aboutPrivateBullet1 = NSLocalizedString("About.privateBullet1", value: "Search and browse right in the app", comment: "Label on About screen")
        static let aboutPrivateBullet2 = NSLocalizedString("About.privateBullet2", value: "Block trackers (or update settings to allow trackers)", comment: "Label on About screen")
        static let aboutPrivateBullet3 = NSLocalizedString("About.privateBullet3", value: "Erase to delete cookies as well as search and browsing history", comment: "Label on About screen")
        static let aboutRowHelp = NSLocalizedString("About.rowHelp", value: "Help", comment: "Label for row in About screen")
        static let aboutRowRights = NSLocalizedString("About.rowRights", value: "Your Rights", comment: "Label for row in About screen")
        static let aboutRowPrivacy = NSLocalizedString("About.rowPrivacy", value: "Privacy Notice", comment: "Link to Privacy Notice in the About screen")
        static let aboutSafariBulletHeader = NSLocalizedString("About.safariBulletHeader", value: "Use it as a Safari extension:", comment: "Label on About screen")
        static let aboutSafariBullet1 = NSLocalizedString("About.safariBullet1", value: "Block trackers for improved privacy", comment: "Label on About screen")
        static let aboutSafariBullet2 = NSLocalizedString("About.safariBullet2", value: "Block Web fonts to reduce page size", comment: "Label on About screen")
        static let aboutTitle = NSLocalizedString("About.screenTitle", value: "About Firefox Focus", comment: "Title for the About screen")
        static let whatsNewTitle = NSLocalizedString("Settings.whatsNewTitle", value: "What’s New", comment: "Title for What's new screen")
        static let aboutTopLabel = NSLocalizedString("About.topLabel", value: "%@ puts you in control.", comment: "Label on About screen")
        static let browserBack = NSLocalizedString("Browser.backLabel", value: "Back", comment: "Accessibility label for the back button")
        static let browserForward = NSLocalizedString("Browser.forwardLabel", value: "Forward", comment: "Accessibility label for the forward button")
        static let browserReload = NSLocalizedString("Browser.reloadLabel", value: "Reload", comment: "Accessibility label for the reload button")
        static let browserSettings = NSLocalizedString("Browser.settingsLabel", value: "Settings", comment: "Accessibility label for the settings button")
        static let browserShare = NSLocalizedString("Browser.shareLabel", value: "Share", comment: "Accessibility label for the share button")
        static let browserStop = NSLocalizedString("Browser.stopLabel", value: "Stop", comment: "Accessibility label for the stop button")
        static let eraseButton = NSLocalizedString("URL.eraseButtonLabel", value: "ERASE", comment: "Erase button in the URL bar")
        static let eraseMessage = NSLocalizedString("URL.eraseMessageLabel", value: "Your browsing history has been erased.", comment: "Message shown after pressing the Erase button")
        static let errorTryAgain = NSLocalizedString("Error.tryAgainButton", value: "Try again", comment: "Button label to reload the error page")
        static let externalLinkCall = NSLocalizedString("ExternalLink.callButton", value: "Call", comment: "Button label in tel: dialog to call a phone number. Test page: https://people-mozilla.org/~bnicholson/test/schemes.html")
        static let externalLinkCancel = NSLocalizedString("ExternalLink.cancelButton", value: "Cancel", comment: "Button label in external link dialog to cancel the dialog. Test page: https://people-mozilla.org/~bnicholson/test/schemes.html")
        static let externalLinkEmail = NSLocalizedString("ExternalLink.emailButton", value: "Email", comment: "Button label in mailto: dialog to send an email. Test page: https://people-mozilla.org/~bnicholson/test/schemes.html")
        static let externalLinkOpenAppStore = NSLocalizedString("ExternalLink.openAppStoreButton", value: "Open App Store", comment: "Button label in App Store URL dialog to open the App Store. Test page: https://people-mozilla.org/~bnicholson/test/schemes.html")
        static let externalLinkOpenMaps = NSLocalizedString("ExternalLink.openMapsButton", value: "Open Maps", comment: "Button label in Maps URL dialog to open Maps. Test page: https://people-mozilla.org/~bnicholson/test/schemes.html")
        static let externalLinkOpenAppStoreTitle = NSLocalizedString("ExternalLink.openAppStoreTitle", value: "%@ wants to open the App Store.", comment: "Dialog title used to open App Store links. The placeholder is replaced with the application name, which can be either Firefox Focus or Firefox Klar.")
        static let externalLinkTitle = NSLocalizedString("ExternalLink.messageTitleWithPlaceholder", value: "You are now leaving %@.", comment: "Dialog title used for Maps/App Store links. The placeholder is replaced with the application name, which can be either Firefox Focus or Firefox Klar. Test page: https://people-mozilla.org/~bnicholson/test/schemes.html")
        static let firstRunButton = NSLocalizedString("FirstRun.lastSlide.buttonLabel", value: "OK, Got It!", comment: "Label on button to dismiss first run UI")

        static let firstRunMessage = NSLocalizedString("FirstRun.messageLabelDescription", value: "Automatically block online trackers while you browse. Then tap to erase visited pages, searches, cookies and passwords from your device.", comment: "Message label on the first run screen")
        static let firstRunTitle = NSLocalizedString("FirstRun.messageLabelTagline", value: "Browse like no one’s watching.", comment: "Message label on the first run screen")
        static let homeLabel1 = NSLocalizedString("Home.descriptionLabel1", value: "Automatic private browsing.", comment: "First label for product description on the home screen")
        static let homeLabel2 = NSLocalizedString("Home.descriptionLabel2", value: "Browse. Erase. Repeat.", comment: "Second label for product description on the home screen")
        static let labelBlockAds = NSLocalizedString("Settings.toggleBlockAds", value: "Block ad trackers", comment: "Label for toggle on main screen")
        static let labelBlockAdsDescription = NSLocalizedString("Settings.toggleBlockAdsDescription", value: "Some ads track site visits, even if you don’t click the ads", comment: "Description for 'Block ad Trackers'")
        static let labelBlockAnalytics = NSLocalizedString("Settings.toggleBlockAnalytics", value: "Block analytics trackers", comment: "Label for toggle on main screen")
        static let labelBlockAnalyticsDescription = NSLocalizedString("Settings.toggleBlockAnalyticsDescription", value: "Used to collect, analyze and measure activities like tapping and scrolling", comment: "Description for 'Block analytics Trackers'")
        static let labelBlockSocial = NSLocalizedString("Settings.toggleBlockSocial", value: "Block social trackers", comment: "Label for toggle on main screen")
        static let labelBlockSocialDescription = NSLocalizedString("Settings.toggleBlockSocialDescription", value: "Embedded on sites to track your visits and to display functionality like share buttons", comment: "Description for 'Block social Trackers'")
        static let labelBlockOther = NSLocalizedString("Settings.toggleBlockOther", value: "Block other content trackers", comment: "Label for toggle on main screen")
        static let labelBlockOtherDescription = NSLocalizedString("Settings.toggleBlockOtherDescription", value: "Enabling may cause some pages to behave unexpectedly", comment: "Description for 'Block other content Trackers'")
        static let labelBlockFonts = NSLocalizedString("Settings.toggleBlockFonts", value: "Block Web fonts", comment: "Label for toggle on main screen")
        static let labelSendAnonymousUsageData = NSLocalizedString("Settings.toggleSendUsageData", value: "Send usage data", comment: "Label for Send Usage Data toggle on main screen")
        static let detailTextSendUsageData = NSLocalizedString("Settings.detailTextSendUsageData", value: "Mozilla strives to collect only what we need to provide and improve %@ for everyone.", comment: "Description associated to the Send Usage Data toggle on main screen. %@ is the app name (Focus/Klar)")
        static let openCancel = NSLocalizedString("Open.Cancel", value: "Cancel", comment: "Label in share alert to cancel the alert")
        static let openFirefox = NSLocalizedString("Open.Firefox", value: "Firefox (Private Browsing)", comment: "Label in share alert to open the URL in Firefox")
        static let openMore = NSLocalizedString("Open.More", value: "More", comment: "Label in share alert to open the full system share menu")
        static let openSafari = NSLocalizedString("Open.Safari", value: "Safari", comment: "Label in share alert to open the URL in Safari")
        static let safariInstructionsContentBlockers = NSLocalizedString("Safari.instructionsContentBlockers", value: "Tap Safari, then select Content Blockers", comment: "Label for instructions to enable Safari, shown when enabling Safari Integration in Settings")
        static let safariInstructionsEnable = NSLocalizedString("Safari.instructionsEnable", value: "Enable %@", comment: "Label for instructions to enable Safari, shown when enabling Safari Integration in Settings")
        static let safariInstructionsOpen = NSLocalizedString("Safari.instructionsOpen", value: "Open Settings App", comment: "Label for instructions to enable Safari, shown when enabling Safari Integration in Settings")
        static let safariInstructionsNotEnabled = String(format: NSLocalizedString("Safari.instructionsNotEnabled", value: "%@ is not enabled.", comment: "Error label when the blocker is not enabled, shown in the intro and main app when disabled"), AppInfo.productName)
        static let searchButton = NSLocalizedString("URL.searchLabel", value: "Search for %@", comment: "Label displayed for search button when typing in the URL bar")
        static let settingsBlockOtherMessage = NSLocalizedString("Settings.blockOtherMessage", value: "Blocking other content trackers may break some videos and Web pages.", comment: "Alert message shown when toggling the Content blocker")
        static let settingsBlockOtherNo = NSLocalizedString("Settings.blockOtherNo", value: "No, Thanks", comment: "Button label for declining Content blocker alert")
        static let settingsBlockOtherYes = NSLocalizedString("Settings.blockOtherYes", value: "I Understand", comment: "Button label for accepting Content blocker alert")
        static let settingsSearchTitle = NSLocalizedString("Settings.searchTitle2", value: "SEARCH", comment: "Title for the search selection screen")
        static let settingsSearchLabel = NSLocalizedString("Settings.searchLabel", value: "Search Engine", comment: "Label for the search engine in the search screen")
        static let settingsAutocompleteSection = NSLocalizedString("Settings.autocompleteSection", value: "URL Autocomplete", comment: "Title for the URL Autocomplete row")
        static let settingsTitle = NSLocalizedString("Settings.screenTitle", value: "Settings", comment: "Title for settings screen")
        static let settingsToggleOtherSubtitle = NSLocalizedString("Settings.toggleOtherSubtitle", value: "May break some videos and Web pages", comment: "Label subtitle for toggle on main screen")
        static let learnMore = NSLocalizedString("Settings.learnMore", value: "Learn more.", comment: "Subtitle for Send Anonymous Usage Data toggle on main screen")
        static let toggleSectionIntegration = NSLocalizedString("Settings.sectionIntegration", value: "INTEGRATION", comment: "Label for Safari integration section")
        static let toggleSectionMozilla = NSLocalizedString("Settings.sectionMozilla", value: "MOZILLA", comment: "Section label for Mozilla toggles")
        static let toggleSectionPerformance = NSLocalizedString("Settings.sectionPerformance", value: "PERFORMANCE", comment: "Section label for performance toggles")
        static let toggleSectionPrivacy = NSLocalizedString("Settings.sectionPrivacy", value: "PRIVACY", comment: "Section label for privacy toggles")
        static let toggleSafari = NSLocalizedString("Settings.toggleSafari", value: "Safari", comment: "Safari toggle label on settings screen")
        static let urlBarCancel = NSLocalizedString("URL.cancelLabel", value: "Cancel", comment: "Label for cancel button shown when entering a URL or search")
        static let urlTextPlaceholder = NSLocalizedString("URL.placeholderText", value: "Search or enter address", comment: "Placeholder text shown in the URL bar before the user navigates to a page")
        static let shareMenuOpenInFocus = NSLocalizedString("ShareMenu.OpenInFocus", value: "Open in %@", comment: "Text for the share menu option when a user wants to open a page in Focus.")
        static let shareMenuGetTheFirefoxApp = NSLocalizedString("ShareMenu.GetFirefox", value: "Get the Firefox App", comment: "Text for the share menu option when a user wants to open a page in Firefox but doesn’t have it installed. This string will not wrap in the interface. Instead, it will truncate. To prevent this, please keep the localized string to 18 or fewer characters. If your string runs longer than 18 characters, you can use 'Get Firefox' as the basis for your string. However, if at all possible, we’d like to signal to the user that they will be going to the App Store and installing the application from there. That is why we are using Get and App in the en-US string.")
        static let urlPasteAndGo = NSLocalizedString("URL.contextMenu", value: "Paste & Go", comment: "Text for the URL context menu when a user long presses on the URL bar with clipboard contents.")
        static let saveImage = NSLocalizedString("contextMenu.saveImageTitle", value: "Save Image", comment: "Text for the context menu when a user wants to save an image after long pressing it.")
        static let copyImage = NSLocalizedString("contextMenu.copyImageTitle", value: "Copy Image", comment: "Text for the context menu when a user wants to copy an image after long pressing it.")
        static let shareLink = NSLocalizedString("contextMenu.shareLinkTitle", value: "Share Link", comment: "Text for the context menu when a user wants to share a link after long pressing it.")
        static let share = NSLocalizedString("share", value: "Share", comment: "Text for a share button")
        static let copyLink = NSLocalizedString("contextMenu.copyLink", value: "Copy Link", comment: "Text for the context menu when a user wants to copy a link after long pressing it.")
        static let trackersBlocked = NSLocalizedString("URL.trackersBlockedLabel", value: "Trackers blocked", comment: "Text for the URL bar showing the number of trackers blocked on a webpage.")
        static let externalAppLink = NSLocalizedString("ExternalAppLink.messageTitle", value: "%@ wants to open another App", comment: "Dialog title used for opening an external app from Focus. The placeholder string is the app name of either Focus or Klar.")
        static let externalAppLinkWithAppName = NSLocalizedString("externalAppLinkWithAppName.messageTitle", value: "%@ wants to open %@", comment: "Dialog title used for opening an external app from Focus. First placeholder string is the app name of either Focus or Klar and the second placeholder string specifies the app it wants to open.")
        static let open = NSLocalizedString("ExternalAppLink.openTitle", value: "Open", comment: "Button label for opening another app from Focus")
        static let cancel = NSLocalizedString("ExternalAppLink.cancelTitle", value: "Cancel", comment: "Button label used for cancelling to open another app from Focus")
        static let photosPermissionTitle = NSLocalizedString("photosPermission.title", value: "“%@” Would Like to Access Your Photos", comment: "Dialog title used for requesting a user to enable access to Photos. Placeholder is either Firefox Focus or Firefox Klar")
        static let photosPermissionDescription = NSLocalizedString("photosPermission.description", value: "This lets you save images to your Camera Roll", comment: "Description for dialog used for requesting a user to enable access to Photos.")
        static let openSettingsButtonTitle = NSLocalizedString("photosPermission.openSettings", value: "Open Settings", comment: "Title for button that takes the user to system settings")
        static let openIn = NSLocalizedString("actionSheet.openIn", value: "Open in %@", comment: "Title for action sheet item to open the current page in another application. Placeholder is the name of the application to open the current page.")
        static let handoffSyncing = NSLocalizedString("Focus.handoffSyncing", value: "Apple Handoff is syncing", comment: "Title for the loading screen when the handoff of clipboard delays Focus launch. “Handoff” should not be localized, see https://support.apple.com/HT204681")
        static let linkYouCopied = NSLocalizedString("contextMenu.clipboardLink", value: "Link you copied: %@", comment: "Text for the context menu when a user has a link on their clipboard.")
        static let trackingProtectionToggleLabel = NSLocalizedString("trackingProtection.toggleLabel", value: "Tracking Protection", comment: "Text for the toggle that temporarily disables tracking protection.")
        static let trackingProtectionToggleDescription = NSLocalizedString("trackingProtection.toggleDescription1", value: "Disable until you close %@ or tap ERASE.", comment: "Description for the tracking protection toggle. Placeholder is either Firefox Focus or Firefox Klar")
        static let trackingProtectionDisabledLabel = NSLocalizedString("trackingProtection.disabledLabel", value: "Tracking Protection off", comment: "text showing the tracking protection is disabled.")
        static let adTrackerLabel = NSLocalizedString("trackingProtection.adTrackersLabel", value: "Ad trackers", comment: "Label for ad trackers.")
        static let analyticTrackerLabel = NSLocalizedString("trackingProtection.analyticTrackerLabel", value: "Analytic trackers", comment: "label for analytic trackers.")
        static let socialTrackerLabel = NSLocalizedString("trackingProtection.socialTrackerLabel", value: "Social trackers", comment: "label for social trackers.")
        static let contentTrackerLabel = NSLocalizedString("trackingProtection.contentTrackerLabel", value: "Content trackers", comment: "label for content trackers.")
        static let selectLocationBarTitle = NSLocalizedString("browserShortcutDescription.selectLocationBar", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
        static let trackersDescriptionLabel = NSLocalizedString("trackingProtection.trackerDescriptionLabel", value: "Choose whether %@ blocks ad, analytic, social, and other trackers.", comment: "General description of tracking protection settings, which is displayed underneath the trackers preferences in Settings. Placeholder is either Firefox Focus or Firefox Klar")
        static let trackingProtectionLearnMore = NSLocalizedString("trackingProtection.learnMore", value: "Learn More", comment: "Text for the button to learn more about Tracking Protection.")
        static let CardTitleWelcome = NSLocalizedString("Intro.Slides.Welcome.Title", tableName: "Intro", value: "Power up your privacy", comment: "Title for the first panel 'Welcome' in the First Run tour.")
        static let CardTitleSearch = NSLocalizedString("Intro.Slides.Search.Title", tableName: "Intro", value: "Your search, your way", comment: "Title for the second  panel 'Search' in the First Run tour.")
        static let CardTextWelcome = NSLocalizedString("Intro.Slides.Welcome.Description", tableName: "Intro", value: "Take private browsing to the next level. Block ads and other content that can track you across sites and bog down page load times.", comment: "Description for the 'Welcome' panel in the First Run tour.")
        static let CardTextSearch = NSLocalizedString("Intro.Slides.Search.Description", tableName: "Intro", value: "Searching for something different? Choose a different search engine.", comment: "Description for the 'Favorite Search Engine' panel in the First Run tour.")
        static let AddSearchEngineButton = NSLocalizedString("Settings.Search.AddSearchEngineButton", value: "+ Add Another Search Engine", comment: "Text for button to add another search engine in settings")
        static let AddSearchEngineTitle = NSLocalizedString("Settings.Search.AddSearchEngineTitle", value: "Add Search Engine", comment: "Title on add search engine settings screen")
        static let save = NSLocalizedString("Save", value: "Save", comment: "Save button label")
        static let NameToDisplay = NSLocalizedString("Settings.Search.NameToDisplay", value: "Name to display", comment: "Label for input field for the name of the search engine to be added")
        static let AddSearchEngineName = NSLocalizedString("Settings.Search.SearchEngineName", value: "Search engine name", comment: "Placeholder text for input of new search engine name")
        static let AddSearchEngineTemplate = NSLocalizedString("Settings.Search.SearchTemplate", value: "Search string to use", comment: "Label for input of search engine template")
        static let AddSearchEngineTemplatePlaceholder = NSLocalizedString("Settings.Search.SearchTemplatePlaceholder", value: "Paste or enter search string. If necessary, replace search term with: %s", comment: "Placeholder text for input of new search engine template")
        static let AddSearchEngineTemplateExample = NSLocalizedString("settings.Search.SearchTemplateExample", value: "Example: searchengineexample.com/search/?q=%s", comment: "Text displayed as an example of the template to add a search engine.")
        static let RestoreSearchEnginesLabel = NSLocalizedString("Settings.Search.RestoreEngine", value: "Restore Default Search Engines", comment: "Label for button to bring deleted default engines back")
        static let Edit = NSLocalizedString("Edit", value: "Edit", comment: "Label on button to allow edits")
        static let Done = NSLocalizedString("Done", value: "Done", comment: "Label on button to complete edits")
        static let InstalledSearchEngines = NSLocalizedString("Settings.Search.InstalledSearchEngines", value: "INSTALLED SEARCH ENGINES", comment: "Header for rows of installed search engines")
        static let NewSearchEngineAdded = NSLocalizedString("Settings.Search.NewSearchEngineAdded", value: "New Search Engine Added", comment: "Toast displayed after adding a search engine")
        static let SkipIntroButtonTitle = NSLocalizedString("Intro.Slides.Skip.Button", tableName: "Intro", value: "Skip", comment: "Button to skip onboarding in Focus")
        static let NextIntroButtonTitle = NSLocalizedString("Intro.Slides.Next.Button", tableName: "Intro", value: "Next", comment: "Button to go to the next card in Focus onboarding.")
        static let CardTitleHistory = NSLocalizedString("Intro.Slides.History.Title", tableName: "Intro", value: "Your history is history", comment: "Title for the third  panel 'History' in the First Run tour.")
        static let CardTextHistory = NSLocalizedString("Intro.Slides.History.Description", tableName: "Intro", value: "Clear your entire browsing session history, passwords, cookies anytime with a single tap.", comment: "Description for the 'History' panel in the First Run tour.")
        static let AddSearchEngineButtonWithPlus = NSLocalizedString("Settings.Search.AddSearchEngineButtonWithPlus", value: "+ Add Another Search Engine", comment: "Text for button to add another search engine in settings with the + prefix")
        static let enabled = NSLocalizedString("Enabled", value: "Enabled", comment: "label describing something as enabled")
        static let disabled = NSLocalizedString("Disabled", value: "Disabled", comment: "label describing something as disabled")
        static let edit = NSLocalizedString("Edit", value: "Edit", comment: "Label on button to allow edits")
        static let done = NSLocalizedString("Done", value: "Done", comment: "Label on button to complete edits")
        static let cancelLabel = NSLocalizedString("Cancel", value: "Cancel", comment: "Label on button to cancel edits")

        static let autocompleteLabel = NSLocalizedString("Autocomplete.defaultLabel", value: "Autocomplete", comment: "Label for enabling or disabling autocomplete")
        static let autocompleteDefaultSectionTitle = NSLocalizedString("Autocomplete.defaultTitle", value: "DEFAULT URL LIST", comment: "Title for the default URL list section")
        static let autocompleteDefaultDescription = NSLocalizedString("Autocomplete.defaultDescriptoin", value: "Enable to have %@ autocomplete over 450 popular URLs in the address bar.", comment: "Description for enabling or disabling the default list. The placeholder is replaced with the application name, which can be either Firefox Focus or Firefox Klar.")

        static let autocompleteCustomSectionTitle = NSLocalizedString("Autocomplete.customTitle", value: "CUSTOM URL LIST", comment: "Title for the default URL list section")
        static let autocompleteCustomSectionLabel = NSLocalizedString("Autocomplete.customLabel", value: "Custom URLs", comment: "Label for button taking you to your custom Autocomplete URL list")
        static let autocompleteCustomDescription = NSLocalizedString("Autocomplete.customDescriptoin", value: "Add and manage custom autocomplete URLs.", comment: "Description for adding and managing custom autocomplete URLs")
        static let autocompleteCustomEnabled = NSLocalizedString("Autocomplete.enabled", value: "Enabled", comment: "label describing URL Autocomplete as enabled")
        static let autocompleteCustomDisabled = NSLocalizedString("Autocomplete.disabled", value: "Disabled", comment: "label describing URL Autocomplete as disabled")

        static let autocompleteAddCustomUrlWithPlus = NSLocalizedString("Autocomplete.addCustomUrlWithPlus", value: "+ Add Custom URL", comment: "Label for button to add a custom URL with the + prefix")
        static let autocompleteAddCustomUrl = NSLocalizedString("Autocomplete.addCustomUrl", value: "Add Custom URL", comment: "Label for button to add a custom URL")
        static let autocompleteAddCustomUrlError = NSLocalizedString("Autocomplete.addCustomUrlError", value: "Double-check the URL you entered.", comment: "Label for error state when entering an invalid URL")

        static let autocompleteAddCustomUrlPlaceholder = NSLocalizedString("Autocomplete.addCustomUrlPlaceholder", value: "Paste or enter URL", comment: "Placeholder for the input field to add a custom URL")
        static let autocompleteAddCustomUrlLabel = NSLocalizedString("Autocomplete.addCustomUrlLabel", value: "URL to add", comment: "Label for the input to add a custom URL")
        static let autocompleteAddCustomUrlExample = NSLocalizedString("Autocomplete.addCustomUrlExample", value: "Example: example.com", comment: "A label displaying an example URL")
        static let autocompleteEmptyState = NSLocalizedString("Autocomplete.emptyState", value: "No Custom URLs to display", comment: "Label for button to add a custom URL")
        static let autocompleteCustomURLAdded = NSLocalizedString("Autocomplete.customUrlAdded", value: "New Custom URL added.", comment: "Label for toast alerting a custom URL has been added")
        static let shareTrackerStatsLabel = NSLocalizedString("share.trackerStatsLabel", value: "%@ trackers blocked so far", comment: "Text used when the user shares their trackers blocked stats")
        static let shareTrackerStatsText = NSLocalizedString("share.trackerStatsText", value: "%@, the privacy browser from Mozilla, has already blocked %@ trackers for me. Fewer ads and trackers following me around means faster browsing! Get Focus for yourself here", comment: "The text shared to users after the user chooses to share there tracker stats")
    }
}
