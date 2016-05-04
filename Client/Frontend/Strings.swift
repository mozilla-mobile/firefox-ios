/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Strings {}

/// Return the main application bundle. Even if called from an extension. If for some reason we cannot find the
/// application bundle, the current bundle is returned, which will then result in an English base language string.
private func applicationBundle() -> NSBundle {
    let bundle = NSBundle.mainBundle()
    guard bundle.bundleURL.pathExtension == "appex", let applicationBundleURL = bundle.bundleURL.URLByDeletingLastPathComponent?.URLByDeletingLastPathComponent else {
        return bundle
    }
    return NSBundle(URL: applicationBundleURL) ?? bundle
}

// SendTo extension.
extension Strings {
    public static let SendToCancelButton = NSLocalizedString("SendTo.Cancel.Button", value: "Cancel", bundle: applicationBundle(), comment: "Button title for cancelling SendTo screen")
}

// ShareTo extension.
extension Strings {
    public static let ShareToCancelButton = NSLocalizedString("ShareTo.Cancel.Button", value: "Cancel", bundle: applicationBundle(), comment: "Button title for cancelling Share screen")
}

// Top Sites.
extension Strings {
    public static let TopSitesEmptyStateDescription = NSLocalizedString("TopSites.EmptyState.Description", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.")
    public static let TopSitesEmptyStateTitle = NSLocalizedString("TopSites.EmptyState.Title", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state")
    public static let TopSitesRemoveButtonAccessibilityLabel = NSLocalizedString("TopSites.RemovePage.Button", value: "Remove page - %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Settings.
extension Strings {
    public static let SettingsClearPrivateDataClearButton = NSLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = NSLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsClearPrivateDataTitle = NSLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
}

// Error pages.
extension Strings {
    public static let ErrorPagesAdvancedButton = NSLocalizedString("ErrorPages.Advanced.Button", value: "Advanced", comment: "Label for button to perform advanced actions on the error page")
    public static let ErrorPagesAdvancedWarning1 = NSLocalizedString("ErrorPages.AdvancedWarning1.Text", value: "Warning: we can't confirm your connection to this website is secure.", comment: "Warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesAdvancedWarning2 = NSLocalizedString("ErrorPages.AdvancedWarning2.Text", value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.", comment: "Additional warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesCertWarningDescription = NSLocalizedString("ErrorPages.CertWarning.Description", value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Firefox has not connected to this website.", comment: "Warning text on the certificate error page")
    public static let ErrorPagesCertWarningTitle = NSLocalizedString("ErrorPages.CertWarning.Title", value: "This Connection is Untrusted", comment: "Title on the certificate error page")
    public static let ErrorPagesGoBackButton = NSLocalizedString("ErrorPages.GoBack.Button", value: "Go Back", comment: "Label for button to go back from the error page")
    public static let ErrorPagesVisitOnceButton = NSLocalizedString("ErrorPages.VisitOnce.Button", value: "Visit site anyway", comment: "Button label to temporarily continue to the site from the certificate error page")
}

// Logins Helper.
extension Strings {
    public static let LoginsHelperSaveLoginButtonTitle = NSLocalizedString("LoginsHelper.SaveLogin.Button", value: "Save Login", comment: "Button to save the user's password")
    public static let LoginsHelperDontSaveButtonTitle = NSLocalizedString("LoginsHelper.DontSave.Button", value: "Don’t Save", comment: "Button to not save the user's password")
    public static let LoginsHelperUpdateButtonTitle = NSLocalizedString("LoginsHelper.Update.Button", value: "Update", comment: "Button to update the user's password")
}

// History Panel
extension Strings {
    public static let SyncedTabsTableViewCellTitle = NSLocalizedString("HistoryPanel.SyncedTabsCell.Title", value: "Synced devices", comment: "Title for the Synced Tabs Cell in the History Panel")
    public static let HistoryBackButtonTitle = NSLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let EmptySyncedTabsPanelStateTitle = NSLocalizedString("HistoryPanel.EmptySyncedTabsState.Title", value: "Firefox Sync", comment: "Title for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsState.Description", value: "Sign in to view open tabs on your other devices.", comment: "Description for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelNullStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsNullState.Description", value: "Your tabs from other devices show up here.", comment: "Description for the empty synced tabs null state in the History Panel")
    public static let SyncedTabsTableViewCellDescription = NSLocalizedString("HistoryPanel.SyncedTabsCell.Description", value: "devices connected", comment: "Description that corresponds with a number of devices connected for the Synced Tabs Cell in the History Panel")
    public static let HistoryPanelEmptyStateTitle = NSLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you've visited recently will show up here.", comment: "Title for the History Panel empty state.")
}

// Syncing
extension Strings {
    public static let SyncingMessageWithEllipsis = NSLocalizedString("Sync.SyncingEllipsis.Label", value: "Syncing…", comment: "Message displayed when the user's account is syncing with ellipsis at the end")
    public static let SyncingMessageWithoutEllipsis = NSLocalizedString("Sync.Syncing.Label", value: "Syncing", comment: "Message displayed when the user's account is syncing with no ellipsis")
}

// Home page.
extension Strings {
    public static let SettingsHomePageSectionName = NSLocalizedString("Settings.HomePage.SectionName", value: "Homepage", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.")
    public static let SettingsHomePageTitle = NSLocalizedString("Settings.HomePage.Title", value: "Homepage Settings", comment: "Title displayed in header of the setting panel.")
    public static let SettingsHomePageUIPositionTitle = NSLocalizedString("Settings.HomePage.UI.Toggle.Title", value: "Show Homepage icon in menu", comment: "Toggle setting to show home page button in menu, or on toolbar.")
    public static let SettingsHomePageUIPositionSubtitle = NSLocalizedString("Settings.HomePage.UI.Toggle.Subtitle", value: "Requires a restart to take effect", comment: "Toggle setting to show home page button in menu, or on toolbar.")
    public static let SettingsHomePageURLSectionTitle = NSLocalizedString("Settings.HomePage.URL.Title", value: "Current Homepage", comment: "Title of the setting section containing the URL of the current home page.")
    public static let SettingsHomePageUseCurrentPage = NSLocalizedString("Settings.HomePage.UseCurrent.Button", value: "Use Current Page", comment: "Button in settings to use the current page as home page.")
    public static let SettingsHomePagePlaceholder = NSLocalizedString("Settings.HomePage.URL.Placeholder", value: "Enter a webpage", comment: "Placeholder text in the homepage setting when no homepage has been set.")
    public static let SettingsHomePageUseCopiedLink = NSLocalizedString("Settings.HomePage.UseCopiedLink.Button", value: "Use Copied Link", comment: "Button in settings to use the current link on the clipboard as home page.")
    public static let SettingsHomePageUseDefault = NSLocalizedString("Settings.HomePage.UseDefault.Button", value: "Use Default", comment: "Button in settings to use the default home page. If no default is set, then this button isn't shown.")
    public static let SettingsHomePageClear = NSLocalizedString("Settings.HomePage.Clear.Button", value: "Clear", comment: "Button in settings to clear the home page.")

    public static let SetHomePageDialogTitle = NSLocalizedString("HomePage.Set.Dialog.Title", value: "Do you want to use this web page as your Homepage?", comment: "Alert dialog title when the user opens the home page for the first time.")
    public static let SetHomePageDialogMessage = NSLocalizedString("HomePage.Set.Dialog.Message", value: "You can change this at any time in the Settings", comment: "Alert dialog body when the user opens the home page for the first time.")
    public static let SetHomePageDialogYes = NSLocalizedString("HomePage.Set.Dialog.OK", value: "Yes Please", comment: "Button accepting changes setting the home page for the first time.")
    public static let SetHomePageDialogNo = NSLocalizedString("HomePage.Set.Dialog.Cancel", value: "No Thanks", comment: "Button cancelling changes setting the home page for the first time.")
}
