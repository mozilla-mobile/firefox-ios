/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

struct UIConstants {
    
    static var ToolbarHeight: CGFloat = 46

    struct colors {
        static let background = UIConstants.Photon.Ink80
        static let buttonHighlight = UIColor(rgb: 0x333333)
        static let cellSelected = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        static let cellBackground = UIConstants.Photon.Ink70
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
        static let navigationButton = UIConstants.Photon.Grey10
        static let navigationTitle = UIConstants.Photon.Grey10
        static let overlayBackground = UIColor(white: 0, alpha: 0.8)
        static let progressBar = UIColor(rgb: 0xC86DD7)
        static let settingsButtonBorder = UIColor(rgb: 0x5F6368, alpha: 0.8)
        static let settingsTextLabel = UIConstants.Photon.Grey10
        static let settingsDetailLabel = UIConstants.Photon.Grey10.withAlphaComponent(0.6)
        static let settingsSeparator = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        static let settingsLink = UIConstants.Photon.Magenta60
        static let settingsDisabled = UIColor(rgb: 0xB2B2B2)
        static let siriTint = UIConstants.Photon.Magenta60
        static let tableSectionHeader = UIConstants.Photon.Grey10.withAlphaComponent(0.6)
        static let toastBackground = UIColor(rgb: 0x414146)
        static let toastText = UIColor.white
        static let toggleOn = UIConstants.Photon.Magenta70
        static let toggleOff = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        static let toolbarBorder = UIColor(rgb: 0x5F6368)
        static let toolbarButtonNormal = UIColor.darkGray
        static let urlTextBackground = UIColor(white: 1, alpha: 0.2)
        static let urlTextFont = UIConstants.Photon.Grey10
        static let urlTextHighlight = UIColor(rgb: 0xB5007F)
        static let urlTextPlaceholder = UIConstants.Photon.Grey10.withAlphaComponent(0.4)
        static let urlTextShadow = UIColor.black
        static let whatsNew = UIConstants.Photon.Teal50
        static let settingsNavBar = UIConstants.Photon.Ink70.withAlphaComponent(0.9)
        static let settingsNavBorder = UIConstants.Photon.Grey10.withAlphaComponent(0.5)

        static let inputPlaceholder = UIColor(rgb: 0xb2b2b2)

        static let trackingProtectionPrimary = UIColor(rgb: 0xFFFFFF)
        static let trackingProtectionSecondary = UIColor(rgb: 0xB2B2B2)
        static let trackingProtectionBreakdownBackground = UIColor(rgb: 0x414146)
        static let trackingProtectionLearnMore = UIColor(rgb: 0x0A84FF)
    }
    
    struct Photon {
        static let Magenta50 = UIColor(rgb: 0xff1ad9)
        static let Magenta60 = UIColor(rgb: 0xed00b5)
        static let Magenta70 = UIColor(rgb: 0xb5007f)
        static let Magenta80 = UIColor(rgb: 0x7d004f)
        static let Magenta90 = UIColor(rgb: 0x440027)
        
        static let Purple30 = UIColor(rgb: 0xc069ff)
        static let Purple40 = UIColor(rgb: 0xad3bff)
        static let Purple50 = UIColor(rgb: 0x9400ff)
        static let Purple60 = UIColor(rgb: 0x8000d7)
        static let Purple70 = UIColor(rgb: 0x6200a4)
        static let Purple80 = UIColor(rgb: 0x440071)
        static let Purple90 = UIColor(rgb: 0x25003e)
        
        static let Blue40 = UIColor(rgb: 0x45a1ff)
        static let Blue50 = UIColor(rgb: 0x0a84ff)
        static let Blue60 = UIColor(rgb: 0x0060df)
        static let Blue70 = UIColor(rgb: 0x003eaa)
        static let Blue80 = UIColor(rgb: 0x002275)
        static let Blue90 = UIColor(rgb: 0x000f40)
        
        static let Teal50 = UIColor(rgb: 0x00feff)
        static let Teal60 = UIColor(rgb: 0x00c8d7)
        static let Teal70 = UIColor(rgb: 0x008ea4)
        static let Teal80 = UIColor(rgb: 0x005a71)
        static let Teal90 = UIColor(rgb: 0x002d3e)
        
        static let Green50 = UIColor(rgb: 0x30e60b)
        static let Green60 = UIColor(rgb: 0x12bc00)
        static let Green70 = UIColor(rgb: 0x058b00)
        static let Green80 = UIColor(rgb: 0x006504)
        static let Green90 = UIColor(rgb: 0x003706)
        
        static let Yellow50 = UIColor(rgb: 0xffe900)
        static let Yellow60 = UIColor(rgb: 0xd7b600)
        static let Yellow70 = UIColor(rgb: 0xa47f00)
        static let Yellow80 = UIColor(rgb: 0x715100)
        static let Yellow90 = UIColor(rgb: 0x3e2800)
        
        static let Red50 = UIColor(rgb: 0xff0039)
        static let Red60 = UIColor(rgb: 0xd70022)
        static let Red70 = UIColor(rgb: 0xa4000f)
        static let Red80 = UIColor(rgb: 0x5a0002)
        static let Red90 = UIColor(rgb: 0x3e0200)
        
        static let Orange50 = UIColor(rgb: 0xff9400)
        static let Orange60 = UIColor(rgb: 0xd76e00)
        static let Orange70 = UIColor(rgb: 0xa44900)
        static let Orange80 = UIColor(rgb: 0x712b00)
        static let Orange90 = UIColor(rgb: 0x3e1300)
        
        static let Grey10 = UIColor(rgb: 0xf9f9fa)
        static let Grey20 = UIColor(rgb: 0xededf0)
        static let Grey30 = UIColor(rgb: 0xd7d7db)
        static let Grey40 = UIColor(rgb: 0xb1b1b3)
        static let Grey50 = UIColor(rgb: 0x737373)
        static let Grey60 = UIColor(rgb: 0x4a4a4f)
        static let Grey70 = UIColor(rgb: 0x38383d)
        static let Grey80 = UIColor(rgb: 0x2a2a2e)
        static let Grey90 = UIColor(rgb: 0x0c0c0d)
        
        static let Ink70 = UIColor(rgb: 0x363959)
        static let Ink80 = UIColor(rgb: 0x202340)
        static let Ink90 = UIColor(rgb: 0x0f1126)
        
        static let White100 = UIColor(rgb: 0xffffff)
        
    }

    struct fonts {
        static let aboutText = UIFont.systemFont(ofSize: 14)
        static let cancelButton = UIFont.systemFont(ofSize: 15)
        static let copyButton = UIFont.systemFont(ofSize: 16)
        static let copyButtonQuery = UIFont.boldSystemFont(ofSize: 16)
        static let deleteButton = UIFont.systemFont(ofSize: 11)
        static let firstRunDisclaimer = UIFont.systemFont(ofSize: 14)
        static let firstRunMessage = UIFont.systemFont(ofSize: 14)
        static let firstRunTitle = UIFont.systemFont(ofSize: 18)
        static let firstRunButton = UIFont.systemFont(ofSize: 16)
        static let homeLabel = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.ultraLight)
        static let safariInstruction = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
        static let searchButton = UIFont.systemFont(ofSize: 16)
        static let searchButtonQuery = UIFont.boldSystemFont(ofSize: 16)
        static let settingsHomeButton = UIFont.systemFont(ofSize: 15)
        static let settingsOverlayButton = UIFont.systemFont(ofSize: 13)
        static let tableSectionHeader = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        static let toast = UIFont.systemFont(ofSize: 12)
        static let urlText = UIFont.systemFont(ofSize: 16)
        static let truncatedUrlText = UIFont.systemFont(ofSize: 12)
        static let settingsInputLabel = UIFont.systemFont(ofSize: 18)
        static let settingsDescriptionText = UIFont.systemFont(ofSize: 12)
        static let shareTrackerStatsLabel = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.light)
        static let closeButtonTitle = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.bold)
        static let actionMenuItem = UIFont.systemFont(ofSize: 16)
        static let actionMenuTitle = UIFont.systemFont(ofSize: 12)
        static let actionMenuItemBold = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.bold)
    }

    struct layout {
        static let browserToolbarDisabledOpacity: CGFloat = 0.3
        static let browserToolbarHeight: CGFloat = 44
        static let copyButtonAnimationDuration: TimeInterval = 0.1
        static let deleteAnimationDuration: TimeInterval = 0.25
        static let alphaToZeroDeleteAnimationDuration: TimeInterval = deleteAnimationDuration * (2 / 3)
        static let displayKeyboardDeleteAnimationDuration: TimeInterval = deleteAnimationDuration * (1 / 3)
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
        static let urlBarCornerRadius: CGFloat = 4
        static let urlBarHeight: CGFloat = 54
        static let collapsedUrlBarHeight: CGFloat = 22
        static let urlBarTransitionAnimationDuration: TimeInterval = 0.2
        static let urlBarMargin: CGFloat = 8
        static let urlBarHeightInset: CGFloat = 10
        static let urlBarShadowOpacity: Float = 0.3
        static let urlBarShadowRadius: CGFloat = 2
        static let urlBarShadowOffset = CGSize(width: 0, height: 2)
        static let urlBarWidthInset: CGFloat = 8
        static let urlBarBorderInset: CGFloat = 4
        static let deleteButtonInset: CGFloat = -12
        static let urlBarIconInset: CGFloat = 8
        static let settingsDefaultTitleOffset = 3
        static let settingsFirstTitleOffset = 16
        static let urlBarToolsetOffset: CGFloat = 60
        static let textLogoOffset: CGFloat = -10 - browserToolbarHeight / 2
        static let urlBarButtonImageSize: CGFloat = 24
        static let urlBarButtonTargetSize: CGFloat = 40
        static let settingsTextPadding: CGFloat = 10
        static let siriUrlSectionPadding: CGFloat = 40
        static let settingsSectionHeight: CGFloat = 44
        static let separatorHeight: CGFloat = 0.5
        static let shareTrackersBottomOffset: CGFloat = -20
        static let shareTrackersHeight: CGFloat = 36
        static let homeViewTextOffset: CGFloat = 5
        static let homeViewLabelMinimumScale: CGFloat = 0.65
    }

    struct strings {
        static let aboutLearnMoreButton = NSLocalizedString("About.learnMoreButton", value: "Learn more", comment: "Button on About screen")
        static let aboutMissionLabel = NSLocalizedString("About.missionLabel", value: "%@ is produced by Mozilla. Our mission is to foster a healthy, open Internet.", comment: "Label on About screen")
        static let reloadDesktopTitle = NSLocalizedString("Request Desktop Site", comment: "Label for button that requests the desktop version of the currently loaded website.")
        static let aboutPrivateBulletHeader = NSLocalizedString("About.privateBulletHeader", value: "Use it as a private browser:", comment: "Label on About screen")
        static let aboutPrivateBullet1 = NSLocalizedString("About.privateBullet1", value: "Search and browse right in the app", comment: "Label on About screen")
        static let aboutPrivateBullet2 = NSLocalizedString("About.privateBullet2", value: "Block trackers (or update settings to allow trackers)", comment: "Label on About screen")
        static let aboutPrivateBullet3 = NSLocalizedString("About.privateBullet3", value: "Erase to delete cookies as well as search and browsing history", comment: "Label on About screen")
        static let aboutRowHelp = NSLocalizedString("About.rowHelp", value: "Help", comment: "Label for row in About screen")
        static let aboutRowRights = NSLocalizedString("About.rowRights", value: "Your Rights", comment: "Label for row in About screen")
        static let aboutRowPrivacy = NSLocalizedString("About.rowPrivacy", value: "Privacy Notice", comment: "Link to Privacy Notice in the About screen")
        static let aboutSafariBulletHeader = NSLocalizedString("About.safariBulletHeader", value: "Use it as a Safari extension:", comment: "Label on About screen")
        static let aboutTitle = NSLocalizedString("About.title", value: "About %@", comment: "%@ is the name of the app (Focus / Klar). Title displayed in the settings screen that, when tapped, takes the user to a page with information about the product. Also displayed as a header for the About page.")
        static let aboutSafariBullet1 = NSLocalizedString("About.safariBullet1", value: "Block trackers for improved privacy", comment: "Label on About screen")
        static let aboutSafariBullet2 = NSLocalizedString("About.safariBullet2", value: "Block Web fonts to reduce page size", comment: "Label on About screen")
        static let whatsNewTitle = NSLocalizedString("Settings.whatsNewTitle", value: "What’s New", comment: "Title for What's new screen")
        static let aboutTopLabel = NSLocalizedString("About.topLabel", value: "%@ puts you in control.", comment: "Label on About screen")
        static let biometricReason = NSLocalizedString("BiometricPrompt.reason", value: "Unlock %@ when re-opening in order to prevent unauthorized access.", comment: "%@ is app name. Explanation for why the app needs access to biometric information. Prompt is only shown once when the user first tries to enable Face ID to open the app.")
        static let touchIdReason = NSLocalizedString("touchId.reason", value: "Use Touch ID to return to %@", comment: "%@ is app name. Prompt shown to ask the user to use Touch ID to continue browsing after returning to the app.")
        static let authenticationReason = NSLocalizedString("Authentication.reason", value: "Authenticate to return to %@", comment: "%@ is app name. Prompt shown to ask the user to use Touch ID, Face ID, or passcode to continue browsing after returning to the app.")
        static let newSessionFromBiometricFailure = NSLocalizedString("BiometricPrompt.newSession", value: "New Session", comment: "Create a new session after failing a biometric check")
        static let browserBack = NSLocalizedString("Browser.backLabel", value: "Back", comment: "Accessibility label for the back button")
        static let browserForward = NSLocalizedString("Browser.forwardLabel", value: "Forward", comment: "Accessibility label for the forward button")
        static let browserReload = NSLocalizedString("Browser.reloadLabel", value: "Reload", comment: "Accessibility label for the reload button")
        static let browserSettings = NSLocalizedString("Browser.settingsLabel", value: "Settings", comment: "Accessibility label for the settings button")
        static let browserShare = NSLocalizedString("Browser.shareLabel", value: "Share", comment: "Accessibility label for the share button")
        static let browserStop = NSLocalizedString("Browser.stopLabel", value: "Stop", comment: "Accessibility label for the stop button")
        static let customURLMenuButton = NSLocalizedString("Browser.customURLMenuLabel", value: "Add Custom URL", comment: "Custom URL button in URL long press menu")
        static let copyAddressButton = NSLocalizedString("Browser.copyAddressLabel", value: "Copy Address", comment: "Copy URL button in URL long press menu")
        static let copyURLToast = NSLocalizedString("browser.copyAddressToast", value: "URL Copied To Clipboard", comment: "Toast displayed after a URL has been copied to the clipboard")
        static let copyMenuButton = NSLocalizedString("Browser.copyMenuLabel", value: "Copy", comment: "Copy URL button in URL long press menu")
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
        static let labelFaceIDLogin = NSLocalizedString("Settings.toggleFaceID", value: "Use Face ID to unlock app", comment: "Label for toggle on settings screen")
        static let labelFaceIDLoginDescription = NSLocalizedString("Settings.toggleFaceIDDescription", value: "Face ID can unlock %@ if a URL is already open in the app", comment: "%@ is the name of the app (Focus / Klar). Description for 'Enable Face ID' displayed under its respective toggle in the settings menu.")
        static let labelTouchIDLogin = NSLocalizedString("Settings.toggleTouchID", value: "Use Touch ID to unlock app", comment: "Label for toggle on settings screen")
        static let labelTouchIDLoginDescription = NSLocalizedString("Settings.toggleTouchIDDescription", value: "Touch ID can unlock %@ if a URL is already open in the app", comment: "%@ is the name of the app (Focus / Klar). Description for 'Enable Touch ID' displayed under its respective toggle in the settings menu.")
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
        static let findInPageButton = NSLocalizedString("URL.findOnPageLabel", value: "Find in page: %@", comment: "Label displayed for find in page button when typing in the URL Bar. %@ is any text the user has typed into the URL bar that they want to find on the current page.")
        static let settingsBlockOtherMessage = NSLocalizedString("Settings.blockOtherMessage", value: "Blocking other content trackers may break some videos and Web pages.", comment: "Alert message shown when toggling the Content blocker")
        static let settingsBlockOtherNo = NSLocalizedString("Settings.blockOtherNo", value: "No, Thanks", comment: "Button label for declining Content blocker alert")
        static let settingsBlockOtherYes = NSLocalizedString("Settings.blockOtherYes", value: "I Understand", comment: "Button label for accepting Content blocker alert")
        static let settingsSearchTitle = NSLocalizedString("Settings.searchTitle2", value: "SEARCH", comment: "Title for the search selection screen")
        static let settingsSearchLabel = NSLocalizedString("Settings.searchLabel", value: "Search Engine", comment: "Label for the search engine in the search screen")
        static let settingsAutocompleteSection = NSLocalizedString("Settings.autocompleteSection", value: "URL Autocomplete", comment: "Title for the URL Autocomplete row")
        static let settingsTitle = NSLocalizedString("Settings.screenTitle", value: "Settings", comment: "Title for settings screen")
        static let settingsToggleOtherSubtitle = NSLocalizedString("Settings.toggleOtherSubtitle", value: "May break some videos and Web pages", comment: "Label subtitle for toggle on main screen")
        static let learnMore = NSLocalizedString("Settings.learnMore", value: "Learn more.", comment: "Subtitle for Send Anonymous Usage Data toggle on main screen")
        static let toggleSectionIntegration = NSLocalizedString("Settings.sectionIntegration", value: "INTEGRATION", comment: "Label for Safari integration section") // deprecated
        static let toggleSectionSafari = NSLocalizedString("Settings.safariTitle", value: "SAFARI INTEGRATION", comment: "Label for Safari integration section")
        static let toggleSectionMozilla = NSLocalizedString("Settings.sectionMozilla", value: "MOZILLA", comment: "Section label for Mozilla toggles")
        static let toggleSectionPerformance = NSLocalizedString("Settings.sectionPerformance", value: "PERFORMANCE", comment: "Section label for performance toggles")
        static let toggleSectionPrivacy = NSLocalizedString("Settings.sectionPrivacy", value: "PRIVACY", comment: "Section label for privacy toggles")
        static let toggleSectionSecurity = NSLocalizedString("Settings.sectionSecurity", value: "SECURITY", comment: "Header label for security toggles displayed in the settings menu")
        static let toggleSafari = NSLocalizedString("Settings.toggleSafari", value: "Safari", comment: "Safari toggle label on settings screen")
        static let urlBarCancel = NSLocalizedString("URL.cancelLabel", value: "Cancel", comment: "Label for cancel button shown when entering a URL or search")
        static let urlTextPlaceholder = NSLocalizedString("URL.placeholderText", value: "Search or enter address", comment: "Placeholder text shown in the URL bar before the user navigates to a page")
        static let pageActionsTitle = NSLocalizedString("ShareMenu.PageActions", value: "Page Actions", comment: "Title for the share menu where users can take actions for the current website they are on.")
        static let sharePage = NSLocalizedString("ShareMenu.SharePage", value: "Share Page With...", comment: "Text for the share menu option when a user wants to share the current website they are on through another app.")
        static let shareOpenInFirefox = NSLocalizedString("ShareMenu.ShareOpenFirefox", value: "Open in Firefox", comment: "Text for the share menu option when a user wants to open the current website in the Firefox app.")
        static let shareOpenInChrome = NSLocalizedString("ShareMenu.ShareOpenChrome", value: "Open in Chrome", comment: "Text for the share menu option when a user wants to open the current website in the Chrome app.")
        static let shareOpenInSafari = NSLocalizedString("ShareMenu.ShareOpenSafari", value: "Open in Safari", comment: "Text for the share menu option when a user wants to open the current website in the Safari app.")
        static let shareMenuOpenInFocus = NSLocalizedString("ShareMenu.OpenInFocus", value: "Open in %@", comment: "Text for the share menu option when a user wants to open a page in Focus.")
        static let shareMenuRequestDesktop = NSLocalizedString("ShareMenu.RequestDesktop", value: "Request Desktop Site", comment: "Text for the share menu option when a user wants to reload the site as a desktop")
        static let shareMenuFindInPage = NSLocalizedString("ShareMenu.FindInPage", value: "Find in Page", comment: "Text for the share menu option when a user wants to open the find in page menu")
        static let shareMenuGetTheFirefoxApp = NSLocalizedString("ShareMenu.GetFirefox", value: "Get the Firefox App", comment: "Text for the share menu option when a user wants to open a page in Firefox but doesn’t have it installed. This string will not wrap in the interface. Instead, it will truncate. To prevent this, please keep the localized string to 18 or fewer characters. If your string runs longer than 18 characters, you can use 'Get Firefox' as the basis for your string. However, if at all possible, we’d like to signal to the user that they will be going to the App Store and installing the application from there. That is why we are using Get and App in the en-US string.")
        static let urlPaste = NSLocalizedString("URL.paste", value: "Paste", comment: "Text for a menu displayed from the bottom of the screen when a user long presses on the URL bar with clipboard contents.")
        static let urlPasteAndGo = NSLocalizedString("URL.contextMenu", value: "Paste & Go", comment: "Text for the URL context menu when a user long presses on the URL bar with clipboard contents.")
        static let saveImage = NSLocalizedString("contextMenu.saveImageTitle", value: "Save Image", comment: "Text for the context menu when a user wants to save an image after long pressing it.")
        static let copyImage = NSLocalizedString("contextMenu.copyImageTitle", value: "Copy Image", comment: "Text for the context menu when a user wants to copy an image after long pressing it.")
        static let copyAddress = NSLocalizedString("shareMenu.copyAddress", value: "Copy Address", comment: "Text for the share menu when a user wants to copy a URL.")
        static let shareLink = NSLocalizedString("contextMenu.shareLinkTitle", value: "Share Link", comment: "Text for the context menu when a user wants to share a link after long pressing it.")
        static let share = NSLocalizedString("share", value: "Share", comment: "Text for a share button")
        static let copyLink = NSLocalizedString("contextMenu.copyLink", value: "Copy Link", comment: "Text for the context menu when a user wants to copy a link after long pressing it.")
        static let trackersBlocked = NSLocalizedString("URL.trackersBlockedLabel", value: "Trackers blocked", comment: "Text for the URL bar showing the number of trackers blocked on a webpage.")
        static let externalAppLink = NSLocalizedString("ExternalAppLink.messageTitle", value: "%@ wants to open another App", comment: "Dialog title used for opening an external app from Focus. The placeholder string is the app name of either Focus or Klar.")
        static let externalAppLinkWithAppName = NSLocalizedString("externalAppLinkWithAppName.messageTitle", value: "%@ wants to open %@", comment: "Dialog title used for opening an external app from Focus. First placeholder string is the app name of either Focus or Klar and the second placeholder string specifies the app it wants to open.")
        static let open = NSLocalizedString("ExternalAppLink.openTitle", value: "Open", comment: "Button label for opening another app from Focus")
        static let cancel = NSLocalizedString("ExternalAppLink.cancelTitle", value: "Cancel", comment: "Button label used for cancelling to open another app from Focus")
        static let close = NSLocalizedString("Menu.Close", value: "Close", comment: "Button label used to close a menu that displays as a popup.")
        static let photosPermissionTitle = NSLocalizedString("photosPermission.title", value: "“%@” Would Like to Access Your Photos", comment: "Dialog title used for requesting a user to enable access to Photos. Placeholder is either Firefox Focus or Firefox Klar")
        static let photosPermissionDescription = NSLocalizedString("photosPermission.description", value: "This lets you save images to your Camera Roll", comment: "Description for dialog used for requesting a user to enable access to Photos.")
        static let openSettingsButtonTitle = NSLocalizedString("photosPermission.openSettings", value: "Open Settings", comment: "Title for button that takes the user to system settings")
        static let openIn = NSLocalizedString("actionSheet.openIn", value: "Open in %@", comment: "Title for action sheet item to open the current page in another application. Placeholder is the name of the application to open the current page.")
        static let handoffSyncing = NSLocalizedString("Focus.handoffSyncing", value: "Apple Handoff is syncing", comment: "Title for the loading screen when the handoff of clipboard delays Focus launch. “Handoff” should not be localized, see https://support.apple.com/HT204681")
        static let linkYouCopied = NSLocalizedString("contextMenu.clipboardLink", value: "Link you copied: %@", comment: "Text for the context menu when a user has a link on their clipboard.") // deprecated
        static let copiedLink = NSLocalizedString("contextMenu.linkCopied", value: "Link you copied: ", comment: "Text for the context menu when a user has a link on their clipboard.")
        static let trackingProtectionLabel = NSLocalizedString("trackingProtection.label", value: "Tracking Protection", comment: "Title for the tracking settings page to change what trackers are blocked.")
        static let trackingProtectionToggleLabel = NSLocalizedString("trackingProtection.toggleLabel", value: "Tracking Protection", comment: "Text for the toggle that temporarily disables tracking protection.") // deprecated
        static let trackingProtectionToggleDescription = NSLocalizedString("trackingProtection.toggleDescription1", value: "Disable until you close %@ or tap ERASE.", comment: "Description for the tracking protection toggle. Placeholder is either Firefox Focus or Firefox Klar")
        static let trackingProtectionDisabledLabel = NSLocalizedString("trackingProtection.disabledLabel", value: "Tracking Protection off", comment: "text showing the tracking protection is disabled.")
        static let adTrackerLabel = NSLocalizedString("trackingProtection.adTrackersLabel", value: "Ad trackers", comment: "Label for ad trackers.")
        static let analyticTrackerLabel = NSLocalizedString("trackingProtection.analyticTrackerLabel", value: "Analytic trackers", comment: "label for analytic trackers.")
        static let socialTrackerLabel = NSLocalizedString("trackingProtection.socialTrackerLabel", value: "Social trackers", comment: "label for social trackers.")
        static let contentTrackerLabel = NSLocalizedString("trackingProtection.contentTrackerLabel", value: "Content trackers", comment: "label for content trackers.")
        static let selectLocationBarTitle = NSLocalizedString("browserShortcutDescription.selectLocationBar", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
        static let trackersDescriptionLabel = NSLocalizedString("trackingProtection.trackerDescriptionLabel", value: "Choose whether %@ blocks ad, analytic, social, and other trackers.", comment: "General description of tracking protection settings, which is displayed underneath the trackers preferences in Settings. Placeholder is either Firefox Focus or Firefox Klar")
        static let trackingProtectionLearnMore = NSLocalizedString("trackingProtection.learnMore", value: "Learn More", comment: "Text for the button to learn more about Tracking Protection.")
        static let ratingSetting = NSLocalizedString("Settings.rate", value: "Rate %@", comment: "%@ is the name of the app (Focus / Klar). Title displayed in the settings screen that, when tapped, allows the user to leave a review for the app on the app store.")
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
        static let addSearchEngineError = NSLocalizedString("SearchEngine.addEngineError", value: "That didn't work. Try replacing the search term with this: %s.", comment: "Label for error state when entering an invalid search engine URL. %s is a search term in a URL.")

        static let autocompleteAddCustomUrlPlaceholder = NSLocalizedString("Autocomplete.addCustomUrlPlaceholder", value: "Paste or enter URL", comment: "Placeholder for the input field to add a custom URL")
        static let autocompleteAddCustomUrlLabel = NSLocalizedString("Autocomplete.addCustomUrlLabel", value: "URL to add", comment: "Label for the input to add a custom URL")
        static let autocompleteAddCustomUrlExample = NSLocalizedString("Autocomplete.addCustomUrlExample", value: "Example: example.com", comment: "A label displaying an example URL")
        static let autocompleteEmptyState = NSLocalizedString("Autocomplete.emptyState", value: "No Custom URLs to display", comment: "Label for button to add a custom URL")
        static let autocompleteCustomURLAdded = NSLocalizedString("Autocomplete.customUrlAdded", value: "New Custom URL added.", comment: "Label for toast alerting a custom URL has been added")

        static let findInPagePreviousLabel = NSLocalizedString("FindInPage.PreviousResult", value: "Find previous in page", comment: "Accessibility label for previous result button in Find in Page Toolbar.")
        static let findInPageNextLabel = NSLocalizedString("FindInPage.NextResult", value: "Find next in page", comment: "Accessibility label for next result button in Find in Page Toolbar.")
        static let findInPageDoneLabel = NSLocalizedString("FindInPage.Done", value: "Find in page done", comment: "Accessibility label for done button in Find in Page Toolbar.")
        
        static let siriShortcutsTitle = NSLocalizedString("Settinsg.siriShortcutsTitle", value: "SIRI SHORTCUTS", comment: "Title for settings section to enable different Siri Shortcuts.")
        static let eraseSiri = NSLocalizedString("Siri.erase", value: "Erase", comment: "Title of option in settings to set up Siri to erase")
        static let eraseAndOpenSiri = NSLocalizedString("Siri.eraseAndOpen", value: "Erase & Open", comment: "Title of option in settings to set up Siri to erase and then open the app.")
        static let openUrlSiri = NSLocalizedString("Siri.openURL", value: "Open Favorite Site", comment: "Title of option in settings to set up Siri to open a specified URL in Focus/Klar.")
        static let addToSiri = NSLocalizedString("Siri.addTo", value: "Add to Siri", comment: "Button to add a specified shortcut option to Siri.")
        static let favoriteUrlTitle = NSLocalizedString("Siri.favoriteUrl", value: "Open Favorite Site", comment: "Title for screen to add a favorite URL to Siri.")
        static let urlToOpen = NSLocalizedString("Siri.urlToOpen", value: "URL to open", comment: "Label for input to set a favorite URL to be opened by Siri.")
        static let editOpenUrl = NSLocalizedString("Siri.editOpenUrl", value: "Re-Record or Delete Shortcut", comment: "Label for button to edit the Siri phrase or delete the Siri functionality.")
        static let add = NSLocalizedString("Siri.add", value: "Add", comment: "Button to add a favorite URL to Siri.")
        
        static let userDefaultsLaunchThresholdKey = "launchThreshold"
        static let userDefaultsLaunchCountKey = "launchCount"
        static let userDefaultsLastReviewRequestDate = "lastReviewRequestDate"
        static let requestDesktopNotification = "Notification.requestDesktop"
        static let findInPageNotification = "Notification.findInPage"
        static let autocompleteTipTitle = "Autocomplete URLs for the sites you use most:"
        static let autocompleteTipDescription = "Long-press any URL in the address bar"
        static let sitesNotWorkingTipTitle = "Site acting strange?"
        static let sitesNotWorkingTipDescription = "Try turning off Tracking Protection"
        static let biometricTipTitle = String(format: "Lock %@ even when a site is open:", AppInfo.productName)
        static let biometricTipFaceIdDescription = "Turn on Face ID"
        static let biometricTipTouchIdDescription = "Turn on Touch ID"
        static let requestDesktopTipTitle = "Get the full desktop site instead:"
        static let requestDesktopTipDescription = "Page Actions > Request Desktop Site"
        static let siriFavoriteTipTitle = "Ask Siri to open a favorite site:"
        static let siriFavoriteTipDescription = "Add a site"
        static let siriEraseTipTitle = String(format: "Ask Siri to erase %@ history:", AppInfo.productName)
        static let siriEraseTipDescription = "Add Siri shortcut"
        static let shareTrackersTipTitle = "%@ trackers blocked so far"
    }
}
