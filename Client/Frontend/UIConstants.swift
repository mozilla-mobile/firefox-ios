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
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont: UIFont = UIFont.systemFontOfSize(DefaultChromeSize, weight: UIFontWeightRegular)
    static let DefaultChromeBoldFont = UIFont.boldSystemFontOfSize(DefaultChromeSize)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFontOfSize(DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFontOfSize(PasscodeEntryFontSize, weight: UIFontWeightBold)

    // These highlight colors are currently only used on Snackbar buttons when they're pressed
    static let HighlightColor = UIColor(red: 205/255, green: 223/255, blue: 243/255, alpha: 0.9)
    static let HighlightText = UIColor(red: 42/255, green: 121/255, blue: 213/255, alpha: 1.0)

    static let PanelBackgroundColor = UIColor.whiteColor()
    static let SeparatorColor = UIColor(rgb: 0xcccccc)
    static let HighlightBlue = UIColor(red:76/255, green:158/255, blue:255/255, alpha:1)
    static let DestructiveRed = UIColor(red: 255/255, green: 64/255, blue: 0/255, alpha: 1.0)
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
    static let BackgroundColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)

    // These colours are used on the Menu
    static let MenuToolbarBackgroundColorNormal = UIColor(red: 241/255, green: 241/255, blue: 241/255, alpha: 1.0)
    static let MenuToolbarBackgroundColorPrivate = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1.0)
    static let MenuToolbarTintColorNormal = BackgroundColor
    static let MenuToolbarTintColorPrivate = UIColor.whiteColor()
    static let MenuBackgroundColorNormal = UIColor(red: 223/255, green: 223/255, blue: 223/255, alpha: 1.0)
    static let MenuBackgroundColorPrivate = UIColor(red: 59/255, green: 59/255, blue: 59/255, alpha: 1.0)
    static let MenuSelectedItemTintColor = UIColor(red: 0.30, green: 0.62, blue: 1.0, alpha: 1.0)

    // settings
    static let TableViewHeaderBackgroundColor = UIColor(red: 242/255, green: 245/255, blue: 245/255, alpha: 1.0)
    static let TableViewHeaderTextColor = UIColor(red: 130/255, green: 135/255, blue: 153/255, alpha: 1.0)
    static let TableViewRowTextColor = UIColor(red: 53.55/255, green: 53.55/255, blue: 53.55/255, alpha: 1.0)
    static let TableViewDisabledRowTextColor = UIColor.lightGrayColor()
    static let TableViewSeparatorColor = UIColor(rgb: 0xD1D1D4)
    static let TableViewHeaderFooterHeight = CGFloat(44)

    // Firefox Orange
    static let ControlTintColor = UIColor(red: 240.0 / 255, green: 105.0 / 255, blue: 31.0 / 255, alpha: 1)

    // Passcode dot gray
    static let PasscodeDotColor = UIColor(rgb: 0x4A4A4A)

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3

    static let OKString = NSLocalizedString("OK", comment: "OK button")
    static let CancelString = NSLocalizedString("Cancel", comment: "Cancel button")
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
    let turnOffYourPasscode     = NSLocalizedString("Turn off your passcode.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when turning off passcode")
    let accessPBMode            = NSLocalizedString("Use your fingerprint to access Private Browsing now.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when accessing private browsing")
}

/// Old strings that will be removed when we kill 1.0. We need to keep them around for now for l10n export.
private struct ObsoleteStrings {
    let introMultiplePages = NSLocalizedString("Browse multiple Web pages at the same time with tabs.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    let introPersonalize = NSLocalizedString("Personalize your Firefox just the way you like in Settings.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    let introConnect = NSLocalizedString("Connect Firefox everywhere you use it.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    let settingsSearchSuggestions = NSLocalizedString("Show search suggestions", comment: "Label for show search suggestions setting.")
    let settingsSignIn = NSLocalizedString("Sign in", comment: "Text message / button in the settings table view")
    let clearPrivateHistoryData =  NSLocalizedString("History will be removed from all your connected devices. This cannot be undone.", tableName: "ClearHistoryConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.")
    let clearPrivateHistoryTitle = NSLocalizedString("Remove history from your Firefox Account?", tableName: "ClearHistoryConfirm", comment: "Title of the confirmation dialog shown when a user tries to clear history that's synced to another device.")
    let clearButtonPrivateHistory = NSLocalizedString("Clear", tableName: "ClearHistoryConfirm", comment: "The button that clears history even when Sync is connected.")
}
