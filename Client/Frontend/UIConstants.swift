/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public struct UIConstants {
    static let DefaultHomePage = NSURL(string: "\(WebServer.sharedInstance.base)/about/home/#panel=0")!

    static let AppBackgroundColor = UIColor.blackColor()
    static let PrivateModePurple = UIColor(red: 207 / 255, green: 104 / 255, blue: 255 / 255, alpha: 1)
    static let PrivateModeLocationBackgroundColor = UIColor(red: 31 / 255, green: 31 / 255, blue: 31 / 255, alpha: 1)
    static let PrivateModeLocationBorderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.15)
    static let PrivateModeActionButtonTintColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8)
    static let PrivateModeTextHighlightColor = UIColor(red: 120 / 255, green: 120 / 255, blue: 165 / 255, alpha: 1)
    static let PrivateModeReaderModeBackgroundColor = UIColor(red: 89 / 255, green: 89 / 255, blue: 89 / 255, alpha: 1)

    static let ToolbarHeight: CGFloat = 44
    static let DefaultRowHeight: CGFloat = 58
    static let DefaultPadding: CGFloat = 10
    static let SnackbarButtonHeight: CGFloat = 48

    // Static fonts
    static let DefaultChromeSize: CGFloat = 14
    static let DefaultChromeSmallSize: CGFloat = 11
    static let DefaultChromeFont: UIFont = UIFont.systemFontOfSize(DefaultChromeSize, weight: UIFontWeightRegular)
    static let DefaultChromeBoldFont = UIFont.boldSystemFontOfSize(DefaultChromeSize)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFontOfSize(DefaultChromeSmallSize)

    // These highlight colors are currently only used on Snackbar buttons when they're pressed
    static let HighlightColor = UIColor(red: 205/255, green: 223/255, blue: 243/255, alpha: 0.9)
    static let HighlightText = UIColor(red: 42/255, green: 121/255, blue: 213/255, alpha: 1.0)

    static let PanelBackgroundColor = UIColor.whiteColor()
    static let SeparatorColor = UIColor(rgb: 0xcccccc)
    static let HighlightBlue = UIColor(red:76/255, green:158/255, blue:255/255, alpha:1)
    static let DestructiveRed = UIColor(red: 255/255, green: 64/255, blue: 0/255, alpha: 1.0)
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
    static let BackgroundColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)

    // settings
    static let TableViewHeaderBackgroundColor = UIColor(red: 242/255, green: 245/255, blue: 245/255, alpha: 1.0)
    static let TableViewHeaderTextColor = UIColor(red: 130/255, green: 135/255, blue: 153/255, alpha: 1.0)
    static let TableViewRowTextColor = UIColor(red: 53.55/255, green: 53.55/255, blue: 53.55/255, alpha: 1.0)
    static let TableViewSeparatorColor = UIColor(rgb: 0xD1D1D4)

    // Firefox Orange
    static let ControlTintColor = UIColor(red: 240.0 / 255, green: 105.0 / 255, blue: 31.0 / 255, alpha: 1)

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3
}

/// Strings that will be used for features that haven't yet landed.
private struct TempStrings {
    // Bug 1182303 - Checkbox to block alert spam.
    let disableAlerts = NSLocalizedString("Disable additional page dialogs", comment: "Pending feature; currently unused string! Checkbox label shown after multiple alerts are shown")

    // Bug 1186013 - Prompt for going to clipboard URL
    let goToCopiedURL = NSLocalizedString("Go to copied URL?", comment: "Pending feature; currently unused string! Prompt message shown when browser is opened with URL on the clipboard")
    let goToCopiedURLButton = NSLocalizedString("Go", comment: "Pending feature; currently unused string! Button to browse to URL on the clipboard when browser is opened")

    // strings for lightweight themes
    let themeSetting = NSLocalizedString("Theme", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Settings row to enter theme settings")
    let themesHeader = NSLocalizedString("Themes", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! sub header for theme options in theme chooser")
    let photosHeader = NSLocalizedString("Photos", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Sub header for photo options in theme chooser")
    let previewButton = NSLocalizedString("Preview", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Button to show preview of selected theme")
    let setButton = NSLocalizedString("Set", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Button to set selected theme as current theme")
    let allowButton = NSLocalizedString("Allow Firefox to use my Photos", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Button shown when user wishes to view photos for theme but has not given Firefox permission to do so yet.")
    let chooseButton = NSLocalizedString("Choose", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Back button shown to return back to theme settings from photo picker")

    // accessibility strings for lightweight themes
    let chooseThemeAccessibilityString = NSLocalizedString("Choose Theme", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for settings row to enter theme settings")
    let defaultThemeAccessibilityString = NSLocalizedString("Default Themes", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for themes subheader")
    let myPhotosAccessibilityString = NSLocalizedString("My Photos", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for photo viewer")
    let previewThemeAccessibilityString = NSLocalizedString("Preview Theme", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for theme preview button")
    let setThemeAccessibilityString = NSLocalizedString("Set Theme", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for set theme button")
    let backToThemesAccessibilityString = NSLocalizedString("Back to Themes", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for back button to theme chooser")

    // Bug 1198418 - Touch ID Passcode Strings
    let touchIDSetting          = NSLocalizedString("Touch ID & Passcode", tableName: "AuthenticationManager", comment: "Title for Touch ID/Passcode settings option")
    let turnPasscodeOn          = NSLocalizedString("Turn Passcode On", tableName: "AuthenticationManager", comment: "Title for setting to turn on passcode")
    let turnPasscodeOff         = NSLocalizedString("Turn Passcode Off", tableName: "AuthenticationManager", comment: "Title for setting to turn off passcode")
    let passcode                = NSLocalizedString("Passcode", tableName: "AuthenticationManager", comment: "List section title for passcode settings")
    let changePasscode          = NSLocalizedString("Change Passcode", tableName: "AuthenticationManager", comment: "Title for setting to change passcode")
    let requirePasscode         = NSLocalizedString("Require Passcode", tableName: "AuthenticationManager", comment: "Title for setting to require a passcode")
    let setPasscode             = NSLocalizedString("Set Passcode", tableName: "AuthenticationManager", comment: "Screen title for Set Passcode")
    let enterPasscode           = NSLocalizedString("Enter a passcode", tableName: "AuthenticationManager", comment: "Title for entering a passcode")
    let reenterPasscode         = NSLocalizedString("Re-enter passcode", tableName: "AuthenticationManager", comment: "Title for re-entering a passcode")
    let useTouchID              = NSLocalizedString("Use Touch ID for", tableName:  "AuthenticationManager", comment: "List section title for when to use Touch ID")
    let privateBrowsing         = NSLocalizedString("Private Browsing", tableName: "AuthenticationManager", comment: "List item for Private Browsing")
    let logins                  = NSLocalizedString("Logins", tableName: "AuthenticationManager", comment: "List item for Logins")
    let immediately             = NSLocalizedString("Immediately", tableName: "AuthenticationManager", comment: "'Immediately' interval item for selecting when to require passcode")
    let afterOneMinute          = NSLocalizedString("After 1 minute", tableName: "AuthenticationManager", comment: "'After 1 minute' interval item for selecting when to require passcode")
    let afterFiveMinutes        = NSLocalizedString("After 5 minutes", tableName: "AuthenticationManager", comment: "'After 5 minutes' interval item for selecting when to require passcode")
    let afterTenMinutes         = NSLocalizedString("After 10 minutes", tableName: "AuthenticationManager", comment: "'After 10 minutes' interval item for selecting when to require passcode")
    let afterFifteenMinutes     = NSLocalizedString("After 15 minutes", tableName: "AuthenticationManager", comment: "'After 15 minutes' interval item for selecting when to require passcode")
    let afterOneHour            = NSLocalizedString("After 1 hour", tableName: "AuthenticationManager", comment: "'After 1 hour' interval item for selecting when to require passcode")
    let turnOffYourPasscode     = NSLocalizedString("Turn off your passcode.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when turning off passcode")
    let accessLogins            = NSLocalizedString("Use your fingerprint to access Logins now.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when accessing logins")
    let accessPBMode            = NSLocalizedString("Use your fingerprint to access Private Browsing now.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when accessing private browsing")

    // Bug 1233418 - Login Manager Strings
    let loginsListTitle                 = NSLocalizedString("Logins", tableName: "LoginManager", comment: "Title for Logins List View screen")
    let loginSearchFieldTitle           = NSLocalizedString("Search", tableName: "LoginManager", comment: "Title for the search field at the top of the Logins list screen")
    let clearSearchAccessibilityLabel   = NSLocalizedString("Clear Search", tableName: "LoginManager", comment: "Clears the search input field and exits out of input mode")
    let searchOverlayAccessibilityLabel = NSLocalizedString("Enter Search Mode", tableName: "LoginManager", comment: "Accessibility label for entering search mode for logins")
    let detailUsernameRowTitle          = NSLocalizedString("username", tableName: "LoginManager", comment: "Title for username row in Login Detail View")
    let detailPasswordRowTitle          = NSLocalizedString("password", tableName: "LoginManager", comment: "Title for password row in Login Detail View")
    let detailWebsiteRowTitle           = NSLocalizedString("website", tableName: "LoginManager", comment: "Title for website row in Login Detail View")
    let deleteLoginDetail               = NSLocalizedString("Delete", tableName: "LoginManager", comment: "Button in login detail screen that deletes the current login")
    let lastLoginModified               = NSLocalizedString("Last modified %@", tableName: "LoginManager", comment: "Footer label describing when the login was last modified with the timestamp as the parameter")
    let revealPassword                  = NSLocalizedString("Reveal", tableName: "LoginManager", comment: "Reveal password text selection menu item")
    let openAndFill                     = NSLocalizedString("Open & Fill", tableName: "LoginManager", comment: "Open and Fill website text selection menu item")
    let deselectAll                     = NSLocalizedString("Deselect All", tableName: "LoginManager", comment: "Title for deselecting all selected logins")
    let selectAll                       = NSLocalizedString("Select All", tableName: "LoginManager", comment: "Title for selecting all logins")
    let areYouSure                      = NSLocalizedString("Are you sure?", tableName: "LoginManager", comment: "Prompt title when deleting logins")
    let deleteLocal                     = NSLocalizedString("Logins will be permanently removed.", tableName: "LoginManager", comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them")
    let deleteSyncedDevices             = NSLocalizedString("Logins will be removed from all connected devices.", tableName: "LoginManager", comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices")
    let noLoginsFound                   = NSLocalizedString("No logins found", tableName: "LoginManager", comment: "Title displayed when no logins are found after searching")
}

/// Old strings that will be removed when we kill 1.0. We need to keep them around for now for l10n export.
private struct ObsoleteStrings {
    let introMultiplePages = NSLocalizedString("Browse multiple Web pages at the same time with tabs.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    let introPersonalize = NSLocalizedString("Personalize your Firefox just the way you like in Settings.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    let introConnect = NSLocalizedString("Connect Firefox everywhere you use it.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    let settingsSearchSuggestions = NSLocalizedString("Show search suggestions", comment: "Label for show search suggestions setting.")
    let settingsSignIn = NSLocalizedString("Sign in", comment: "Text message / button in the settings table view")
}
