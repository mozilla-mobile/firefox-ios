/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Strings {}

// SendTo extension.
extension Strings {
    public static let SendToCancelButton = NSLocalizedString("SendTo.Cancel.Button", value: "Cancel", comment: "Button title for cancelling SendTo screen")
}

// ShareTo extension.
extension Strings {
    public static let ShareToCancelButton = NSLocalizedString("ShareTo.Cancel.Button", value: "Cancel", comment: "Button title for cancelling Share screen")
}

// Top Sites.
extension Strings {
    public static let TopSitesEmptyStateDescription = NSLocalizedString("TopSites.EmptyState.Description", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.")
    public static let TopSitesEmptyStateTitle = NSLocalizedString("TopSites.EmptyState.Title", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state")
}

// Settings.
extension Strings {
    public static let SettingsClearPrivateDataClearButton = NSLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = NSLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsClearPrivateDataTitle = NSLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
}