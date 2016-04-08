/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// These were supposed to be strings for prelanded features, but they've been sitting here for awhile.
/// We should audit and remove them (bug 1262956).
/// NOTE: DO NOT LAND NEW STRINGS HERE! Land them in Shared/Strings.swift instead.
private func prelandedStrings() {
    // Bug 1182303 - Checkbox to block alert spam.
    _ = NSLocalizedString("Disable additional page dialogs", comment: "Pending feature; currently unused string! Checkbox label shown after multiple alerts are shown")

    // Bug 1186013 - Prompt for going to clipboard URL
    _ = NSLocalizedString("Go to copied URL?", comment: "Pending feature; currently unused string! Prompt message shown when browser is opened with URL on the clipboard")
    _ = NSLocalizedString("Go", comment: "Pending feature; currently unused string! Button to browse to URL on the clipboard when browser is opened")

    // strings for lightweight themes
    _ = NSLocalizedString("Theme", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Settings row to enter theme settings")
    _ = NSLocalizedString("Themes", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! sub header for theme options in theme chooser")
    _ = NSLocalizedString("Photos", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Sub header for photo options in theme chooser")
    _ = NSLocalizedString("Preview", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Button to show preview of selected theme")
    _ = NSLocalizedString("Set", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Button to set selected theme as current theme")
    _ = NSLocalizedString("Allow Firefox to use my Photos", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Button shown when user wishes to view photos for theme but has not given Firefox permission to do so yet.")
    _ = NSLocalizedString("Choose", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Back button shown to return back to theme settings from photo picker")

    // accessibility strings for lightweight themes
    _ = NSLocalizedString("Choose Theme", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for settings row to enter theme settings")
    _ = NSLocalizedString("Default Themes", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for themes subheader")
    _ = NSLocalizedString("My Photos", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for photo viewer")
    _ = NSLocalizedString("Preview Theme", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for theme preview button")
    _ = NSLocalizedString("Set Theme", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for set theme button")
    _ = NSLocalizedString("Back to Themes", tableName: "LightweightThemes", comment: "Pending feature; currently unused string! Accessibility label for back button to theme chooser")

    // Bug 1198418 - Touch ID Passcode Strings
    _ = NSLocalizedString("Turn off your passcode.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when turning off passcode")
    _ = NSLocalizedString("Use your fingerprint to access Private Browsing now.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when accessing private browsing")
}

/// Old strings that will be removed in a future version. We keep these around for l10n backwards compatibility.
private func obsoleteStrings() {
    // v1.0
    _ = NSLocalizedString("Browse multiple Web pages at the same time with tabs.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    _ = NSLocalizedString("Personalize your Firefox just the way you like in Settings.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    _ = NSLocalizedString("Connect Firefox everywhere you use it.", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    _ = NSLocalizedString("Show search suggestions", comment: "Label for show search suggestions setting.")
    _ = NSLocalizedString("Sign in", comment: "Text message / button in the settings table view")

    // v3.0
    _ = NSLocalizedString("History will be removed from all your connected devices. This cannot be undone.", tableName: "ClearHistoryConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.")
    _ = NSLocalizedString("Remove history from your Firefox Account?", tableName: "ClearHistoryConfirm", comment: "Title of the confirmation dialog shown when a user tries to clear history that's synced to another device.")
    _ = NSLocalizedString("Clear", tableName: "ClearHistoryConfirm", comment: "The button that clears history even when Sync is connected.")
    _ = NSLocalizedString("Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    _ = NSLocalizedString("Clear Private Data", tableName: "ClearPrivateData", comment: "Navigation title in settings.")
    _ = NSLocalizedString("Clear Private Data", tableName: "ClearPrivateData", comment: "Button in settings that clears private data for the selected items.")
    _ = NSLocalizedString("Opening %@", comment:"Opening an external URL")
    _ = NSLocalizedString("This will open in another application", comment: "Opening an external app")
}