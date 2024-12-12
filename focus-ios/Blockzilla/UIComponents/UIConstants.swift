/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct UIConstants {
    struct layout {
        static let browserToolbarDisabledOpacity: CGFloat = 0.4
        static let browserToolbarHeight: CGFloat = 44
        static let deleteAnimationDuration: TimeInterval = 0.25
        static let shieldIconInset: Float = 9
        static let shieldIconIPadInset: Float = 15
        static let urlButtonSize: Float = 24
        static let overlayAnimationDuration: TimeInterval = 0.25
        static let autocompleteAnimationDuration: TimeInterval = 0.2
        static let autocompleteAfterDelayDuration: TimeInterval = 0.5
        static let overlayButtonHeight: Int = 56
        static let smallDeviceMaxNumSuggestions: Int = 4
        static let largeDeviceMaxNumSuggestions: Int = 5
        static let searchButtonInset: CGFloat = 15
        static let toastAnimationDuration: TimeInterval = 0.3
        static let toastDuration: TimeInterval = 1.5
        static let toolbarFadeAnimationDuration = 0.25
        static let toolbarButtonInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        static let urlTextOffset: Float = 15
        static let urlBarCornerRadius: CGFloat = 10
        static let urlBarHeight: CGFloat = 54
        static let collapsedUrlBarHeight: CGFloat = 22
        static let urlBarTransitionAnimationDuration: TimeInterval = 0.2
        static let urlBarMargin: CGFloat = 10
        static let urlBarHeightInset: CGFloat = 0
        static let urlBarContainerHeightInset: CGFloat = 10
        static let urlBarTextInset: CGFloat = 30
        static let urlBarWidthInset: CGFloat = 8
        static let urlBarBorderInset: CGFloat = 0
        static let urlBarBorderHeight: CGFloat = 36
        static let urlBarClearButtonWidth: CGFloat = 20
        static let urlBarClearButtonHeight: CGFloat = 20
        static let urlBarLayoutPriorityRawValue: Float = 1000
        static let deleteButtonOffset: CGFloat = -5
        static let urlBarIconInset: CGFloat = 8
        static let settingsItemInset: CGFloat = 16
        static let settingsItemOffset: CGFloat = 26
        static let settingsPadding: CGFloat = 24
        static let settingsViewOffset: CGFloat = 50
        static let settingsVerticalOffset: CGFloat = 8
        static let settingsHorizontalOffset: CGFloat = 20
        static let settingsAboutFooterViewOffset: CGFloat = 1
        static let settingsAboutViewWidth: CGFloat = 315
        static let settingsAddCustomDomainOffset: CGFloat = 10
        static let settingsAddCustomDomainInputTopOffset: CGFloat = 40
        static let settingsSafariViewImageSize: CGFloat = 650/7
        static let settingsInstructionViewWidth: CGFloat = 250
        static let settingsSearchViewImageOffset: CGFloat = 10
        static let settingsCellCornerRadius: CGFloat = 8
        static let urlBarToolsetOffset: CGFloat = 60
        static let urlBarIPadToolsetOffset: CGFloat = 110
        static let textLogoOffset: CGFloat = -10 - browserToolbarHeight / 2
        static let textLogoOffsetSmallDevice: CGFloat = 10 - browserToolbarHeight / 4
        static let textLogoMargin: CGFloat = 44
        static let tipViewHeight: CGFloat = 148
        static let tipViewBottomOffset: CGFloat = 6
        static let tipViewPadding: CGFloat = 16
        static let urlBarButtonImageSize: CGFloat = 20
        static let urlBarButtonTargetSize: CGFloat = 40
        static let settingsTextPadding: CGFloat = 10
        static let settingsInstructionImageViewWidth: CGFloat = 40
        static let settingsInstructionImageViewHeight: CGFloat = 30
        static let siriUrlSectionPadding: CGFloat = 40
        static let settingsSectionHeight: CGFloat = 44
        static let suggestionViewCornerRadius: CGFloat = 10
        static let suggestionViewHeightMultiplier: CGFloat = 0.25
        static let suggestionViewWidthMultiplier: CGFloat = 0.75
        static let separatorHeight: CGFloat = 0.5
        static let homeViewLabelMinimumScale: CGFloat = 0.65
        static let findInPageSearchTextInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        static let findInPagePreviousButtonOffset: CGFloat = 16
        static let progressBarHeight: CGFloat = 1.5
        static let trackingProtectionHeight: CGFloat = 18
        static let trackingProtectionTableViewTopInset: CGFloat = 54
        static let trackingProtectionHeaderHeight: CGFloat = 72
        static let trackingProtectionHeaderTopOffset: CGFloat = 18
        static let collapsedProtectionBadgeOffset: CGFloat = 10
        static let truncatedUrlTextOffset: CGFloat = 5
        static let addSearchEngineInputHeight: CGFloat = 44
        static let addSearchEngineInputOffset: CGFloat = 16
        static let addSearchEngineTemplateContainerHeight: CGFloat = 88
        static let addSearchEngineExampleLabelOffset: CGFloat = 2
        static let promptTitleOffset: CGFloat = 16
        static let promptTitlePadding: CGFloat = 10
        static let promptMessageOffset: CGFloat = 18
        static let promptMessagePadding: CGFloat = 32
        static let promptButtonWidth: CGFloat = 66
        static let promptButtonHeight: CGFloat = 34
        static let promptButtonTopOffset: CGFloat = 38
        static let promptButtonBottomInset: CGFloat = 32
        static let promptButtonCenterOffset: CGFloat = 8
        static let autocompleteCustomURLLabelOffset: CGFloat = 50
        static let introViewOffset: CGFloat = 24
        static let introViewCardButtonOffset: CGFloat = 5
        static let introViewButtonFrame = CGRect(x: 0, y: 0, width: 6, height: 6)
        static let introViewPageControlOffset: CGFloat = 24
        static let introViewSkipButtonOffset: CGFloat = 24
        static let introViewCornerRadius: CGFloat = 6
        static let introViewShadowOpacity: Float = 0.2
        static let introViewShadowRadius: CGFloat = 12
        static let introViewImageWidth: CGFloat = 280
        static let introViewImageHeight: CGFloat = 212
        static let introViewTitleLabelOffset: CGFloat = 24
        static let introViewTitleLabelInset: CGFloat = 24
        static let introViewTextLabelOffset: CGFloat = 16
        static let introViewTextLabelPadding: CGFloat = 24
        static let introViewTextLabelInset: CGFloat = 24
        static let pageControlSpacing: CGFloat = 2
        static let toastMessageHeight: CGFloat = 48
        static let shortcutsContainerWidth: CGFloat = 326
        static let shortcutsContainerWidthIPad: CGFloat = 440
        static let shortcutsContainerOffset: CGFloat = 24
        static let shortcutsContainerOffsetIPad: CGFloat = 36
        static let shortcutsContainerSpacing: CGFloat = 28
        static let shortcutsContainerSpacingIPad: CGFloat = 40
        static let shortcutsContainerSpacingSmallestSplitView: CGFloat = 20
        static let shortcutsBackgroundHeight: CGFloat = 140
        static let shortcutsBackgroundHeightIPad: CGFloat = 176
        static let shortcutsBackgroundWidthIPad: CGFloat = 676
        static let smallestSplitViewMaxWidthLimit: CGFloat = UIScreen.main.bounds.width * 0.45
        static let iPhoneSEHeight: CGFloat = 568
        static let searchSuggestionsArrowButtonWidth: CGFloat = 30
        static var toolbarHeight: CGFloat = 46
        static let introScreenWidth = 302
        static let introScreenHeight = UIScreen.main.bounds.width <= 320 ? 420 : 460
        static let introScreenMinimumFontScale: CGFloat = 0.5
        static let pagerCenterOffsetFromScrollViewBottom = UIScreen.main.bounds.width <= 320 ? 16 : 24
        static let cardTextLineHeight: CGFloat = UIScreen.main.bounds.width <= 320 ? 2 : 6
        static let actionSheetCellPadding: CGFloat = 16
        static let actionSheetCellHorizontalPadding: CGFloat = 10
        static let actionSheetCellVerticalPadding: CGFloat = 2
        static let actionSheetCellCornerRadius: CGFloat = 3
        static let actionSheetPadding: CGFloat = 10
        static let actionSheetHeaderFooterHeight: CGFloat = 0
        static let actionSheetRowHeight: CGFloat = 50
        static let actionSheetCornerRadius: CGFloat = 10
        static let actionSheetIconSize = CGSize(width: 24, height: 24)
        static let actionSheetTablePadding: CGFloat = 6
        static let actionSheetTitleHeaderHeight: CGFloat = 36
        static let actionSheetSeparatorHeaderHeight: CGFloat = 12
        static let settingsCellLeftInset: CGFloat = 20
        static let contextMenuButtonSize: CGFloat = 36
        static let contextMenuButtonMargin: CGFloat = 14
        static let contextMenuIconSize: CGFloat = 28
        static let deleteButtonMarginContextMenu: CGFloat = -16
        static let toastLabelOffset: CGFloat = 20
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
        static let aboutTitle = NSLocalizedString("About.title", value: "About %@", comment: "%@ is the name of the app (Focus / Klar). Title displayed in the settings screen that, when tapped, takes the user to a page with information about the product. Also displayed as a header for the About page.")
        static let aboutSafariBullet1 = NSLocalizedString("About.safariBullet1", value: "Block trackers for improved privacy", comment: "Label on About screen")
        static let aboutSafariBullet2 = NSLocalizedString("About.safariBullet2", value: "Block web fonts to reduce page size", comment: "Label on About screen")
        static let aboutTopLabel = NSLocalizedString("About.topLabel", value: "%@ puts you in control.", comment: "Label on About screen")
        static let addPassErrorAlertTitle = NSLocalizedString("AddPass.Error.Title", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert.")
        static let addPassErrorAlertMessage = NSLocalizedString("AddPass.Error.Message", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Message of the 'Add Pass Failed' alert.")
        static let addPassErrorAlertDismiss = NSLocalizedString("AddPass.Error.Dismiss", value: "Ok", comment: "Button to dismiss the 'Add Pass Failed' alert.")
        static let authenticationReason = NSLocalizedString("Authentication.reason", value: "Authenticate to return to %@", comment: "%@ is app name. Prompt shown to ask the user to use Touch ID, Face ID, or passcode to continue browsing after returning to the app.")
        static let newSessionFromBiometricFailure = NSLocalizedString("BiometricPrompt.newSession", value: "New Session", comment: "Create a new session after failing a biometric check")
        static let browserBack = NSLocalizedString("Browser.backLabel", value: "Back", comment: "Accessibility label for the back button")
        static let browserForward = NSLocalizedString("Browser.forwardLabel", value: "Forward", comment: "Accessibility label for the forward button")
        static let browserReload = NSLocalizedString("Browser.reloadLabel", value: "Reload", comment: "Accessibility label for the reload button")
        static let browserSettings = NSLocalizedString("Browser.settingsLabel", value: "Settings", comment: "Accessibility label for the settings button")
        static let browserStop = NSLocalizedString("Browser.stopLabel", value: "Stop", comment: "Accessibility label for the stop button")
        static let copyURLToast = NSLocalizedString("browser.copyAddressToast", value: "URL Copied To Clipboard", comment: "Toast displayed after a URL has been copied to the clipboard")
        static let copyMenuButton = NSLocalizedString("Browser.copyMenuLabel", value: "Copy", comment: "Copy URL button in URL long press menu")
        static let eraseButton = NSLocalizedString("URL.eraseButtonLabel", value: "ERASE", comment: "Erase button in the URL bar")
        static let eraseMessage = NSLocalizedString("URL.eraseMessageLabel2", value: "Browsing history cleared", comment: "Message shown after pressing the Erase button")
        static let errorTryAgain = NSLocalizedString("Error.tryAgainButton", value: "Try again", comment: "Button label to reload the error page")
        static let externalLinkCancel = NSLocalizedString("ExternalLink.cancelButton", value: "Cancel", comment: "Button label in external link dialog to cancel the dialog. Test page: https://people-mozilla.org/~bnicholson/test/schemes.html")
        static let externalLinkEmail = NSLocalizedString("ExternalLink.emailButton", value: "Email", comment: "Button label in mailto: dialog to send an email. Test page: https://people-mozilla.org/~bnicholson/test/schemes.html")
        static let firstRunButton = NSLocalizedString("FirstRun.lastSlide.buttonLabel", value: "OK, Got It!", comment: "Label on button to dismiss first run UI")

        static let firstRunTitle = NSLocalizedString("FirstRun.messageLabelTagline", value: "Browse like no one’s watching.", comment: "Message label on the first run screen")
        static let labelBlockAds2 = NSLocalizedString("Settings.toggleBlockAds2", value: "Advertising", comment: "Label for the checkbox to toggle Advertising trackers")
        static let labelFaceIDLogin = NSLocalizedString("Settings.toggleFaceID", value: "Use Face ID to unlock app", comment: "Label for toggle on settings screen")
        static let labelFaceIDLoginDescription = NSLocalizedString("Settings.toggleFaceIDDescription", value: "Face ID can unlock %@ if a URL is already open in the app", comment: "%@ is the name of the app (Focus / Klar). Description for 'Enable Face ID' displayed under its respective toggle in the settings menu.")
        static let labelTouchIDLogin = NSLocalizedString("Settings.toggleTouchID", value: "Use Touch ID to unlock app", comment: "Label for toggle on settings screen")
        static let labelTouchIDLoginDescription = NSLocalizedString("Settings.toggleTouchIDDescription", value: "Touch ID can unlock %@ if a URL is already open in the app", comment: "%@ is the name of the app (Focus / Klar). Description for 'Enable Touch ID' displayed under its respective toggle in the settings menu.")
        static let labelBlockAnalytics = NSLocalizedString("Settings.toggleBlockAnalytics2", value: "Analytics", comment: "Label for the checkbox to toggle Analytics trackers")
        static let labelBlockSocial = NSLocalizedString("Settings.toggleBlockSocial2", value: "Social", comment: "Label for the checkbox to toggle Social trackers")
        static let labelBlockOther = NSLocalizedString("Settings.toggleBlockOther2", value: "Content", comment: "Label for the checkbox to toggle Other trackers")
        static let labelBlockFonts = NSLocalizedString("Settings.toggleBlockFonts", value: "Block web fonts", comment: "Label for toggle on main screen")
        static let labelSendAnonymousUsageData = NSLocalizedString("Settings.toggleSendUsageData", value: "Send usage data", comment: "Label for Send Usage Data toggle on main screen")
        static let detailTextSendUsageData = NSLocalizedString("Settings.detailTextSendUsageData", value: "Mozilla strives to collect only what we need to provide and improve %@ for everyone.", comment: "Description associated to the Send Usage Data toggle on main screen. %@ is the app name (Focus/Klar)")

        static let labelStudies = NSLocalizedString("Settings.toggleStudies", value: "Studies", comment: "Label for Studies toggle on the settings screen")
        static let detailTextStudies = NSLocalizedString("Settings.detailTextStudies", value: "%@ may install and run studies from time to time.", comment: "Description associated to the Studies toggle on the settings screen. %@ is the app name (Focus/Klar)")
        
        static let labelTechnicalAndInteractionData = NSLocalizedString(
            "Settings.toggleTechnicalInteractionData",
            value: "Technical and Interaction Data",
            comment: "Label for Technical and Interaction Data toggle on settings screen"
        )
        static let detailTextTechnicalAndInteractionData = NSLocalizedString(
            "Settings.detailTextTechnicalInteractionData",
            value: "Mozilla strives to collect only what we need to provide and improve %@ for everyone.",
            comment: "Description associated with the Technical and Interaction Data toggle on settings screen. %@ is the app name (Focus/Klar)"
        )
        
        static let labelCrashReports = NSLocalizedString(
            "Settings.toggleCrashReports",
            value: "Crash Reports",
            comment: "Label for Crash Reports toggle on settings screen"
        )
        static let detailTextCrashReports = NSLocalizedString(
            "Settings.detailTextCrashReports",
            value: "Automatically send crash reports to Mozilla to diagnose and fix issues with the browser. Reports may include personal or sensitive data.",
            comment: "Description associated with the Crash Reports toggle on settings screen"
        )

        static let labelDailyUsagePing = NSLocalizedString(
            "Settings.toggleDailyUsagePing",
            value: "Daily Usage Ping",
            comment: "Label for Daily Usage Ping toggle on settings screen"
        )
        static let detailTextDailyUsagePing = NSLocalizedString(
            "Settings.detailTextDailyUsagePing",
            value: "This helps Mozilla to estimate active users.",
            comment: "Description associated with the Daily Usage Ping toggle on settings screen"
        )

        static let general = NSLocalizedString("Settings.general", value: "General", comment: "Title for section in settings menu")
        static let theme = NSLocalizedString("Settings.theme", value: "Theme", comment: "Theme section in settings menu")
        static let systemTheme = NSLocalizedString("Settings.systemTheme", value: "System Theme", comment: "System value for theme section in settings menu")
        static let useSystemTheme = NSLocalizedString("Settings.useSystemTheme", value: "Use System Light/Dark Mode", comment: "Value for theme toggle in settings menu")
        static let themePicker = NSLocalizedString("Settings.themePicker", value: "Theme Picker", comment: "Header for manual theme section in settings menu")
        static let light = NSLocalizedString("Settings.lightTheme", value: "Light", comment: "Light theme option in settings menu")
        static let dark = NSLocalizedString("Settings.darkTheme", value: "Dark", comment: "Dark theme option in settings menu")
        static let licenses = NSLocalizedString("Settings.licenses", value: "Licenses", comment: "Lincese option in settings menu. Tapping the cell will take the user to a list of licences for the 3rd parties used in the app.")
        static let safariInstructionsContentBlockers = NSLocalizedString("Safari.instructionsContentBlockers", value: "Tap Safari, then select Content Blockers", comment: "Label for instructions to enable Safari, shown when enabling Safari Integration in Settings")
        static let safariInstructionsExtensions = NSLocalizedString("Safari.instructionsExtentions", value: "Select Safari, then select Extensions", comment: "Label for instructions to enable extensions in Safari, shown when enabling Safari Integration in Settings")
        static let safariInstructionsEnable = NSLocalizedString("Safari.instructionsEnable", value: "Enable %@", comment: "Label for instructions to enable Safari, shown when enabling Safari Integration in Settings")
        static let safariInstructionsOpen = NSLocalizedString("Safari.instructionsOpen", value: "Open Settings App", comment: "Label for instructions to enable Safari, shown when enabling Safari Integration in Settings")
        static let instructionToOpenSafari = NSLocalizedString("Safari.openInstruction", value: "Open device settings", comment: "Label for instructions to enable extensions in Safari, shown when enabling Safari Integration in Settings")
        static let safariInstructionsNotEnabled = String(format: NSLocalizedString("Safari.instructionsNotEnabled", value: "%@ is not enabled.", comment: "Error label when the blocker is not enabled, shown in the intro and main app when disabled"), AppInfo.productName)
        static let searchButton = NSLocalizedString("URL.searchLabel", value: "Search for %@", comment: "Label displayed for search button when typing in the URL bar")
        static let findInPageButton = NSLocalizedString("URL.findOnPageLabel", value: "Find in page: %@", comment: "Label displayed for find in page button when typing in the URL Bar. %@ is any text the user has typed into the URL bar that they want to find on the current page.")
        static let searchSuggestionsPromptMessage = NSLocalizedString("SearchSuggestions.promptMessage", value: "To get suggestions, %@ needs to send what you type in the address bar to the search engine.", comment: "%@ is the name of the app (Focus / Klar). Label for search suggestions prompt message")
        static let searchSuggestionsPromptTitle = NSLocalizedString("SearchSuggestions.promptTitle", value: "Show Search Suggestions?", comment: "Title for search suggestions prompt")
        static let searchSuggestionsPromptDisable = NSLocalizedString("SearchSuggestions.promptDisable", value: "No", comment: "Label for disable option on search suggestions prompt")
        static let searchSuggestionsPromptEnable = NSLocalizedString("SearchSuggestions.promptEnable", value: "Yes", comment: "Label for enable option on search suggestions prompt")
        static let addToAutocompleteButton = NSLocalizedString("URL.addToAutocompleteLabel", value: "Add link to autocomplete", comment: "Label displayed for button used as a shortcut to add a link to the list of URLs to autocomplete.")
        static let settingsBlockOtherMessage = NSLocalizedString("Settings.blockOtherMessage", value: "Blocking other content trackers may break some videos and web pages.", comment: "Alert message shown when toggling the Content blocker")
        static let settingsBlockOtherNo = NSLocalizedString("Settings.blockOtherNo2", value: "Cancel", comment: "Button label for declining Content blocker alert")
        static let settingsBlockOtherYes = NSLocalizedString("Settings.blockOtherYes2", value: "Block Content Trackers", comment: "Button label for accepting Content blocker alert")
        static let settingsSearchTitle = NSLocalizedString("Settings.searchTitle2", value: "SEARCH", comment: "Title for the search selection screen")
        static let settingsSearchLabel = NSLocalizedString("Settings.searchLabel", value: "Search Engine", comment: "Label for the search engine in the search screen")
        static let settingsSearchSuggestions = NSLocalizedString("Settings.searchSuggestions", value: "Get Search Suggestions", comment: "Label for the Search Suggestions toggle row")
        static let detailTextSearchSuggestion = NSLocalizedString("Settings.detailTextSearchSuggestion", value: "%@ will send what you type in the address bar to your search engine.", comment: "Description associated to the Search Suggestions toggle on main screen. %@ is the app name (Focus/Klar)")
        static let settingsAutocompleteSection = NSLocalizedString("Settings.autocompleteSection", value: "URL Autocomplete", comment: "Title for the URL Autocomplete row")
        static let settingsTitle = NSLocalizedString("Settings.screenTitle", value: "Settings", comment: "Title for settings screen")
        static let settingsTrackingProtectionOn = NSLocalizedString("Settings.trackingProtectionOn", value: "On", comment: "Status on for tracking protection in settings screen")
        static let settingsTrackingProtectionOff = NSLocalizedString("Settings.trackingProtectionOff", value: "Off", comment: "Status off for tracking protection in settings screen")
        static let setAsDefaultBrowserLabel = NSLocalizedString("Settings.setAsDefaultBrowser", value: "Set as Default Browser", comment: "Label title for set as default browser row")
        static let setAsDefaultBrowserDescriptionLabel = NSLocalizedString("Settings.setAsDefaultBrowserDescription", value: "Set links from websites, emails and messages to open automatically in %@.", comment: "%@ is the name of the app. Description for set as default browser option")
        static let learnMore = NSLocalizedString("Settings.learnMore", value: "Learn more.", comment: "Subtitle for Send Anonymous Usage Data toggle on main screen")
        static let toggleHomeScreenTips = NSLocalizedString("Settings.toggleHomeScreenTips", value: "Show home screen tips", comment: "Show home screen tips toggle label on settings screen")
        static let toggleSectionSafari = NSLocalizedString("Settings.safariTitle", value: "SAFARI INTEGRATION", comment: "Label for Safari integration section")
        static let toggleSectionMozilla = NSLocalizedString("Settings.sectionMozilla", value: "MOZILLA", comment: "Section label for Mozilla toggles")
        static let toggleSectionPrivacy = NSLocalizedString("Settings.sectionPrivacy", value: "PRIVACY", comment: "Section label for privacy toggles")
        static let toggleSafari = NSLocalizedString("Settings.toggleSafari", value: "Safari", comment: "Safari toggle label on settings screen")
        static let urlTextPlaceholder = NSLocalizedString("URL.placeholderText", value: "Search or enter address", comment: "Placeholder text shown in the URL bar before the user navigates to a page")
        static let sharePage = NSLocalizedString("ShareMenu.SharePage", value: "Share Page With…", comment: "Text for the share menu option when a user wants to share the current website they are on through another app.")
        static let shareOpenInFirefox = NSLocalizedString("ShareMenu.ShareOpenFirefox", value: "Open in Firefox", comment: "Text for the share menu option when a user wants to open the current website in the Firefox app.")
        static let shareOpenInChrome = NSLocalizedString("ShareMenu.ShareOpenChrome", value: "Open in Chrome", comment: "Text for the share menu option when a user wants to open the current website in the Chrome app.")
        static let shareOpenLink = NSLocalizedString("ShareMenu.ShareOpenLink", value: "Open Link", comment: "Text for the share menu option when a user wants to open the current website inside the app.")
        static let shareOpenInDefaultBrowser = NSLocalizedString("ShareMenu.ShareOpenDefaultBrowser", value: "Open in Default Browser", comment: "Text for the share menu option when a user wants to open the current website in the default browser.")
        static let shareMenuRequestDesktop = NSLocalizedString("ShareMenu.RequestDesktop", value: "Request Desktop Site", comment: "Text for the share menu option when a user wants to reload the site as a desktop")
        static let shareMenuRequestMobile = NSLocalizedString("ShareMenu.RequestMobile", value: "Request Mobile Site", comment: "Text for the share menu option when a user wants to reload the site as a mobile device")
        static let shareMenuFindInPage = NSLocalizedString("ShareMenu.FindInPage", value: "Find in Page", comment: "Text for the share menu option when a user wants to open the find in page menu")
        static let shareMenuAddToShortcuts = NSLocalizedString("ShareMenu.AddToShortcuts", value: "Add to Shortcuts", comment: "Text for the share menu option when a user wants to add the site to Shortcuts")
        static let shareMenuAddToShortcutsConfirmMessage = NSLocalizedString("ShareMenu.AddToShortcuts.Confirm", value: "Added to Shortcuts", comment: "Toast displayed to the user after adding the item to the Shortcuts.")
        static let shareMenuRemoveShortcutConfirmMessage = NSLocalizedString("ShareMenu.RemoveShortcut.Confirm", value: "Shortcut removed", comment: "Toast displayed to the user after removing the item from the Shortcuts.")
        static let shareMenuRemoveFromShortcuts = NSLocalizedString("ShareMenu.RemoveFromShortcuts", value: "Remove from Shortcuts", comment: "Text for the share menu option when a user wants to remove the site from Shortcuts")
        static let removeFromShortcuts = NSLocalizedString("ShortcutView.RemoveFromShortcuts", value: "Remove from Shortcuts", comment: "Text for the long press on a shortcut option in context menu.")
        static let renameShortcut = NSLocalizedString("ShortcutView.Rename", value: "Rename Shortcut", comment: "Text for the long press on a shortcut rename option in context menu.")
        static let renameShortcutAlertPlaceholder = NSLocalizedString("ShortcutView.RenameShortcutAlertPlaceholder", value: "Shortcut name", comment: "Text for the placeholder textfield on rename shortcut alert.")
        static let renameShortcutAlertPrimaryAction = NSLocalizedString("ShortcutView.RenameShortcutAlertPrimaryAction", value: "Save", comment: "Text for the rename shortcut alert primary action.")
        static let renameShortcutAlertSecondaryAction = NSLocalizedString("ShortcutView.RenameShortcutAlertSecondaryAction", value: "Cancel", comment: "Text for the rename shortcut alert secondary action.")
        static let urlPaste = NSLocalizedString("URL.paste", value: "Paste", comment: "Text for a menu displayed from the bottom of the screen when a user long presses on the URL bar with clipboard contents.")
        static let urlPasteAndGo = NSLocalizedString("URL.contextMenu", value: "Paste & Go", comment: "Text for the URL context menu when a user long presses on the URL bar with clipboard contents.")
        static let copyAddress = NSLocalizedString("shareMenu.copyAddress", value: "Copy Address", comment: "Text for the share menu when a user wants to copy a URL.")
        static let share = NSLocalizedString("share", value: "Share", comment: "Text for a share button")
        static let trackersBlocked = NSLocalizedString("URL.trackersBlockedLabel", value: "Trackers blocked", comment: "Text for the URL bar showing the number of trackers blocked on a webpage.")
        static let connectionSecure = NSLocalizedString("trackingProtection.connectionSecureLabel", value: "Connection is secure", comment: "Text for tracking protection screen showing the connection is secure")
        static let connectionNotSecure = NSLocalizedString("trackingProtection.connectionNotSecureLabel", value: "Connection is not secure", comment: "Text for tracking protection screen showing the connection is not secure")
        static let trackersBlockedSince = NSLocalizedString("trackingProtection.trackersBlockedLabel", value: "Trackers blocked since %@", comment: "Text for tracking protection screen showing the number of trackers blocked since the app install. The placeholder is replaced with the install date of the application.")
        static let externalAppLink = NSLocalizedString("ExternalAppLink.messageTitle", value: "%@ wants to open another App", comment: "Dialog title used for opening an external app from Focus. The placeholder string is the app name of either Focus or Klar.")
        static let externalAppLinkWithAppName = NSLocalizedString("externalAppLinkWithAppName.messageTitle", value: "%@ wants to open %@", comment: "Dialog title used for opening an external app from Focus. First placeholder string is the app name of either Focus or Klar and the second placeholder string specifies the app it wants to open.")
        static let open = NSLocalizedString("ExternalAppLink.openTitle", value: "Open", comment: "Button label for opening another app from Focus")
        static let cancel = NSLocalizedString("ExternalAppLink.cancelTitle", value: "Cancel", comment: "Button label used for cancelling to open another app from Focus")
        static let close = NSLocalizedString("Menu.Close", value: "Close", comment: "Button label used to close a menu that displays as a popup.")
        static let openIn = NSLocalizedString("actionSheet.openIn", value: "Open in %@", comment: "Title for action sheet item to open the current page in another application. Placeholder is the name of the application to open the current page.")
        static let trackingProtectionLabel = NSLocalizedString("trackingProtection.label", value: "Tracking Protection", comment: "Title for the tracking settings page to change what trackers are blocked.")
        static let trackingProtectionToggleLabel = NSLocalizedString("trackingProtection.toggleLabel2", value: "Enhanced Tracking Protection", comment: "Text for the toggle that enables/disables tracking protection.")
        static let trackersHeader = NSLocalizedString("trackingProtection.trackersHeader", value: "Trackers and scripts to block", comment: "Text for the header of trackers section from Tracking Protection.")
        static let trackingProtectionOn = NSLocalizedString("trackingProtection.statusOn", value: "Protections are ON for this session", comment: "Text for the status on from Tracking Protection.")
        static let trackingProtectionOff = NSLocalizedString("trackingProtection.statusOff", value: "Protections are OFF for this session", comment: "Text for the status off from Tracking Protection.")
        static let selectLocationBarTitle = NSLocalizedString("browserShortcutDescription.selectLocationBar", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
        static let ratingSetting = NSLocalizedString("Settings.rate", value: "Rate %@", comment: "%@ is the name of the app (Focus / Klar). Title displayed in the settings screen that, when tapped, allows the user to leave a review for the app on the app store.")
        static let CardTitleWelcome = NSLocalizedString("Intro.Slides.Welcome.Title", tableName: "Intro", value: "Power up your privacy", comment: "Title for the first panel 'Welcome' in the First Run tour.")
        static let CardTitleSearch = NSLocalizedString("Intro.Slides.Search.Title", tableName: "Intro", value: "Your search, your way", comment: "Title for the second  panel 'Search' in the First Run tour.")
        static let CardTextWelcome = NSLocalizedString("Intro.Slides.Welcome.Description", tableName: "Intro", value: "Take private browsing to the next level. Block ads and other content that can track you across sites and bog down page load times.", comment: "Description for the 'Welcome' panel in the First Run tour.")
        static let CardTextSearch = NSLocalizedString("Intro.Slides.Search.Description", tableName: "Intro", value: "Searching for something different? Choose a different search engine.", comment: "Description for the 'Favorite Search Engine' panel in the First Run tour.")
        static let AddSearchEngineButton = NSLocalizedString("Settings.Search.AddSearchEngineButton", value: "Add Another Search Engine", comment: "Text for button to add another search engine in settings")
        static let AddSearchEngineTitle = NSLocalizedString("Settings.Search.AddSearchEngineTitle", value: "Add Search Engine", comment: "Title on add search engine settings screen")
        static let save = NSLocalizedString("Save", value: "Save", comment: "Save button label")
        static let NameToDisplay = NSLocalizedString("Settings.Search.NameToDisplay", value: "Name to display", comment: "Label for input field for the name of the search engine to be added")
        static let AddSearchEngineName = NSLocalizedString("Settings.Search.SearchEngineName", value: "Search engine name", comment: "Placeholder text for input of new search engine name")
        static let AddSearchEngineTemplate = NSLocalizedString("Settings.Search.SearchTemplate", value: "Search string to use", comment: "Label for input of search engine template")
        static let AddSearchEngineTemplatePlaceholder = NSLocalizedString("Settings.Search.SearchTemplatePlaceholder", value: "Paste or enter search string. If necessary, replace search term with: %s.", comment: "Placeholder text for input of new search engine template")
        static let AddSearchEngineTemplateExample2 = NSLocalizedString("settings.Search.SearchTemplateExample", value: "Example: searchengine.example.com/search/?q=%s", comment: "Text displayed as an example of the template to add a search engine.")
        static let RestoreSearchEnginesLabel = NSLocalizedString("Settings.Search.RestoreEngine", value: "Restore Default Search Engines", comment: "Label for button to bring deleted default engines back")
        static let Edit = NSLocalizedString("Edit", value: "Edit", comment: "Label on button to allow edits")
        static let Done = NSLocalizedString("Done", value: "Done", comment: "Label on button to complete edits")
        static let InstalledSearchEngines = NSLocalizedString("Settings.Search.InstalledSearchEngines", value: "INSTALLED SEARCH ENGINES", comment: "Header for rows of installed search engines")
        static let NewSearchEngineAdded = NSLocalizedString("Settings.Search.NewSearchEngineAdded", value: "New Search Engine Added.", comment: "Toast displayed after adding a search engine")
        static let SkipIntroButtonTitle = NSLocalizedString("Intro.Slides.Skip.Button", tableName: "Intro", value: "Skip", comment: "Button to skip onboarding in Focus")
        static let NextIntroButtonTitle = NSLocalizedString("Intro.Slides.Next.Button", tableName: "Intro", value: "Next", comment: "Button to go to the next card in Focus onboarding.")
        static let CardTitleHistory = NSLocalizedString("Intro.Slides.History.Title", tableName: "Intro", value: "Your history is history", comment: "Title for the third  panel 'History' in the First Run tour.")
        static let CardTextHistory = NSLocalizedString("Intro.Slides.History.Description", tableName: "Intro", value: "Clear your entire browsing session history, passwords, cookies anytime with a single tap.", comment: "Description for the 'History' panel in the First Run tour.")
        static let edit = NSLocalizedString("Edit", value: "Edit", comment: "Label on button to allow edits")
        static let done = NSLocalizedString("Done", value: "Done", comment: "Label on button to complete edits")

        static let autocompleteMySites = NSLocalizedString("Autocomplete.mySites", value: "My Sites", comment: "Label for enabling or disabling autocomplete")
        static let autocompleteTopSites = NSLocalizedString("Autocomplete.topSites", value: "Top Sites", comment: "Label for enabling or disabling top sites")
        static let autocompleteTopSitesDesc = NSLocalizedString("Autocomplete.defaultDescriptoin", value: "Enable to have %@ autocomplete over 450 popular URLs in the address bar.", comment: "Description for enabling or disabling the default list. The placeholder is replaced with the application name, which can be either Firefox Focus or Firefox Klar.")

        static let autocompleteManageSitesLabel = NSLocalizedString("Autocomplete.manageSites", value: "Manage Sites", comment: "Label for button taking you to your custom Autocomplete URL list")
        static let autocompleteManageSitesDesc = NSLocalizedString("Autocomplete.mySitesDesc", value: "Enable to have %@ autocomplete your favorite URLs.", comment: "Description for adding and managing custom autocomplete URLs. The placeholder is replaced with the application name, which can be either Firefox Focus or Firefox Klar.")
        static let autocompleteCustomEnabled = NSLocalizedString("Autocomplete.enabled", value: "Enabled", comment: "label describing URL Autocomplete as enabled")
        static let autocompleteCustomDisabled = NSLocalizedString("Autocomplete.disabled", value: "Disabled", comment: "label describing URL Autocomplete as disabled")

        static let autocompleteAddCustomUrlWithPlus = NSLocalizedString("Autocomplete.addCustomUrlWithPlus", value: "+ Add Custom URL", comment: "Label for button to add a custom URL with the + prefix")
        static let autocompleteAddCustomUrl = NSLocalizedString("Autocomplete.addCustomUrl", value: "Add Custom URL", comment: "Label for button to add a custom URL")
        static let autocompleteAddCustomUrlError = NSLocalizedString("Autocomplete.addCustomUrlError", value: "Double-check the URL you entered.", comment: "Label for error state when entering an invalid URL")
        static let addSearchEngineError = NSLocalizedString("SearchEngine.addEngineError", value: "That didn’t work. Try replacing the search term with this: %s.", comment: "Label for error state when entering an invalid search engine URL. %s is a search term in a URL.")

        static let autocompleteAddCustomUrlPlaceholder = NSLocalizedString("Autocomplete.addCustomUrlPlaceholder", value: "Paste or enter URL", comment: "Placeholder for the input field to add a custom URL")
        static let autocompleteAddCustomUrlLabel = NSLocalizedString("Autocomplete.addCustomUrlLabel", value: "URL to add", comment: "Label for the input to add a custom URL")
        static let autocompleteAddCustomUrlExample = NSLocalizedString("Autocomplete.addCustomUrlExample", value: "Example: example.com", comment: "A label displaying an example URL")
        static let autocompleteEmptyState = NSLocalizedString("Autocomplete.emptyState", value: "No Custom URLs to display", comment: "Label for button to add a custom URL")
        static let autocompleteCustomURLAdded = NSLocalizedString("Autocomplete.customUrlAdded", value: "New Custom URL added.", comment: "Label for toast alerting a custom URL has been added")
        static let autocompleteCustomURLDuplicate = NSLocalizedString("Autocomplete.duplicateUrl", value: "URL already exists", comment: "Label for toast alerting that the custom URL being added is a duplicate")

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
        static let tooltipBodyTextForShieldIcon = String(format: NSLocalizedString("TooltipBodyText.ShieldIcon", value: "%@ stopped this site from spying on you. Tap the shield for info on what we blocked.", comment: "This is the body text that is displayed for the Shield icon tooltip. Where placeholder can be (Focus or Klar)."), AppInfo.productName)
        static let tooltipBodyTextForShieldIconV2 = NSLocalizedString("TooltipBodyText.ShieldIconTrackerBlocked.V2", value: "Got ‘em! We stopped this site from spying on you. Tap the shield any time to see what we’re blocking.", comment: "This is the body text that is displayed for the Shield icon tooltip when we block trackers for the first time on a website")
        static let tooltipTitleTextForPrivacy = NSLocalizedString("TooltipTitleText.Privacy", value: "You’re protected! ", comment: "This is the title text that is displayed for the Privacy tooltip")
        static let tooltipBodyTextForPrivacy = NSLocalizedString("TooltipBodyText.Privacy", value: "These default settings offer strong protection. But it’s easy to tweak the settings to meet your specific needs.", comment: "This is the body text that is displayed for the Privacy tooltip")
        static let tootipBodyTextForContextMenuIcon = NSLocalizedString("TooltipBodyText.ContextMenu", value: "Go to Settings to manage specific privacy & security options.", comment: "This is the body text that is displayed for the Context Menu icon tooltip")
        static let tooltipBodyTextStartPrivateBrowsing = NSLocalizedString("TooltipBodyText.SearchBar", value: "Start your private browsing session, and we’ll block trackers and other bad stuff as you go.", comment: "This is the body text that is displayed for the Search Bar tooltip")
        static let tooltipBodyTextForTrashIcon = NSLocalizedString("TooltipBodyText.TrashIcon", value: "Tap the trash anytime to remove all traces of your current session.", comment: "This is the body text that is displayed for the Trash icon tooltip")
        static let tooltipBodyTextForTrashIconV2 = NSLocalizedString("TooltipBodyText.TrashIcon.V2", value: "Tap here to trash it all — history, cookies, everything — and start fresh on a new tab.", comment: "This is the body text that is displayed for the Trash icon tooltip")
        static let titleShowMeHowOnboardingV2 = String(format: NSLocalizedString("ShowMeHowOnboarding.Title.V2", value: "Add a %@ Widget", comment: "This is the title text that is displayed in the Show Me How Onboarding Screen. %@ is the name of the app (Focus/Klar)"), AppInfo.shortProductName)
        static let subtitleStepOneShowMeHowOnboardingV2 = NSLocalizedString("ShowMeHowOnboarding.SubtitleStepOne.V2", value: "Long press on the Home screen until the icons start to jiggle.", comment: "This is the subtitle text for step one that is displayed in the Show Me How Onboarding Screen")
        static let subtitleStepTwoShowMeHowOnboardingV2 = NSLocalizedString("ShowMeHowOnboarding.SubtitleStepTwo.V2", value: "Tap on the plus icon.", comment: "This is the subtitle text for step two that is displayed in the Show Me How Onboarding Screen")
        static let subtitleStepThreeShowMeHowOnboardingV2 = String(format: NSLocalizedString("ShowMeHowOnboarding.SubtitleStepThree.V2", value: "Search for %@. Then choose a widget.", comment: "This is the subtitle text for step three that is displayed in the Show Me How onboarding screen. %@ is the name of the app (Focus/Klar)"), AppInfo.shortProductName)
        static let buttonTextShowMeHowOnboardingV2 = NSLocalizedString("ShowMeHowOnboarding.ButtonText.V2", value: "Done", comment: "This is the button text that is displayed in the Show Me How Onboarding Screen")

        static let searchInAppFormatInstruction = NSLocalizedString(
            "TodayWidget.SearchInApp.Instruction",
            value: "Search in %@",
            comment: "Text shown on quick action widget inviting the user to browse in the app. %@ is the name of the app (Focus/Klar).")
        static let searchInAppInstruction = String(format: searchInAppFormatInstruction, AppInfo.shortProductName)

        public static let widgetOnboardingCardTitle = NSLocalizedString(
                "WidgetOnboardingCard.Title",
                value: "Browsing history cleared! 🎉",
                comment: "Title shown on card view explaining the app has a widget option")

        public static let widgetOnboardingCardSubtitle = String(format: NSLocalizedString(
                "WidgetOnboardingCard.Subtitle",
                value: "We’ll leave you to your private browsing, but get a quicker start next time with the %@ widget on your Home screen.",
                comment: "Subtitle shown on card view explaining the app has a widget option. %@ is the name of the app (Focus/Klar)."), AppInfo.shortProductName)

        public static let widgetOnboardingCardActionButton = NSLocalizedString(
                "WidgetOnboardingCard.ActionButton",
                value: "Show Me How",
                comment: "Title for the action button shown on card view that will take the user to a tutorial explaining the user how to add an widget")

        public static let unlockWithBiometricsActionButton = NSLocalizedString(
            "BiometricAuthentication.UnlockButton.Title",
            value: "Unlock",
            comment: "Title for the action button shown on the Splash Screen which gives the user the ability to log in with biometrics.")

        static let userDefaultsLaunchThresholdKey = "launchThreshold"
        static let userDefaultsLaunchCountKey = "launchCount"
        static let userDefaultsLastReviewRequestDate = "lastReviewRequestDate"
        static let requestDesktopNotification = "Notification.requestDesktop"
        static let requestMobileNotification = "Notification.requestMobile"
        static let findInPageNotification = "Notification.findInPage"

        static let encodingNameUTF8 = "utf-8"
        static let googleAmpURLPrefix = "https://www.google.com/amp/s/"
        static let truncateLeader = "..."
    }
}
