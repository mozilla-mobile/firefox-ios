/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Strings {}

/// Return the main application bundle. Even if called from an extension. If for some reason we cannot find the
/// application bundle, the current bundle is returned, which will then result in an English base language string.
private func applicationBundle() -> Bundle {
    let bundle = Bundle.main
    guard bundle.bundleURL.pathExtension == "appex", let applicationBundleURL = (bundle.bundleURL as NSURL).deletingLastPathComponent?.deletingLastPathComponent() else {
        return bundle
    }
    return Bundle(url: applicationBundleURL) ?? bundle
}

// SendTo extension.
extension Strings {
    public static let SendToCancelButton = NSLocalizedString("SendTo.Cancel.Button", bundle: applicationBundle(), value: "Cancel", comment: "Button title for cancelling SendTo screen")
    public static let SendToErrorOKButton = NSLocalizedString("SendTo.Error.OK.Button", bundle: applicationBundle(), value: "OK", comment: "OK button to dismiss the error prompt.")
    public static let SendToErrorTitle = NSLocalizedString("SendTo.Error.Title", bundle: applicationBundle(), value: "The link you are trying to share cannot be shared.", comment: "Title of error prompt displayed when an invalid URL is shared.")
    public static let SendToErrorMessage = NSLocalizedString("SendTo.Error.Message", bundle: applicationBundle(), value: "Only HTTP and HTTPS links can be shared.", comment: "Message in error prompt explaining why the URL is invalid.")
}

// ShareTo extension.
extension Strings {
    public static let ShareToCancelButton = NSLocalizedString("ShareTo.Cancel.Button", bundle: applicationBundle(), value: "Cancel", comment: "Button title for cancelling Share screen")
}

// Top Sites.
extension Strings {
    public static let TopSitesEmptyStateDescription = NSLocalizedString("TopSites.EmptyState.Description", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.")
    public static let TopSitesEmptyStateTitle = NSLocalizedString("TopSites.EmptyState.Title", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state")
    public static let TopSitesRemoveButtonAccessibilityLabel = NSLocalizedString("TopSites.RemovePage.Button", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Activity Stream.
extension Strings {
    public static let HighlightIntroTitle = NSLocalizedString("ActivityStream.HighlightIntro.Title", value: "Be on the Lookout", comment: "The title that appears for the introduction to highlights in AS.")
    public static let HighlightIntroDescription = NSLocalizedString("ActivityStream.HighlightIntro.Description", value: "Firefox will place things here that you’ve discovered on the web so you can find your way back to the great articles, videos, bookmarks and other pages", comment: "The detailed text that explains what highlights are in AS.")
    public static let ASPageControlButton = NSLocalizedString("ActivityStream.PageControl.Button", value: "Next Page", comment: "The page control button that lets you switch between pages in top sites")
    public static let ASHighlightsTitle =  NSLocalizedString("ActivityStream.Highlights.Title", value: "Highlights", comment: "Section title label for the Highlights section")
    public static let ASPocketTitle = NSLocalizedString("ActivityStream.Pocket.SectionTitle", value: "Recommended by Pocket", comment: "Section title label for Recommended by Pocket section")
    public static let ASTopSitesTitle =  NSLocalizedString("ActivityStream.TopSites.SectionTitle", value: "Top Sites", comment: "Section title label for Top Sites")
    public static let HighlightVistedText = NSLocalizedString("ActivityStream.Highlights.Visited", value: "Visited", comment: "The description of a highlight if it is a site the user has visited")
    public static let HighlightBookmarkText = NSLocalizedString("ActivityStream.Highlights.Bookmark", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked")
    public static let PocketTrendingText = NSLocalizedString("ActivityStream.Pocket.Trending", value: "Trending", comment: "The description of a Pocket Story")
}

// Home Panel Context Menu.
extension Strings {
    public static let OpenInNewTabContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.OpenInNewTab", value: "Open in New Tab", comment: "The title for the Open in New Tab context menu action for sites in Home Panels")
    public static let OpenInNewPrivateTabContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.OpenInNewPrivateTab", value: "Open in New Private Tab", comment: "The title for the Open in New Private Tab context menu action for sites in Home Panels")
    public static let BookmarkContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.Bookmark", value: "Bookmark", comment: "The title for the Bookmark context menu action for sites in Home Panels")
    public static let RemoveBookmarkContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.RemoveBookmark", value: "Remove Bookmark", comment: "The title for the Remove Bookmark context menu action for sites in Home Panels")
    public static let DeleteFromHistoryContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.DeleteFromHistory", value: "Delete from History", comment: "The title for the Delete from History context menu action for sites in Home Panels")
    public static let ShareContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.Share", value: "Share", comment: "The title for the Share context menu action for sites in Home Panels")
    public static let RemoveContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.Remove", value: "Remove", comment: "The title for the Remove context menu action for sites in Home Panels")
    public static let PinTopsiteActionTitle = NSLocalizedString("ActivityStream.ContextMenu.PinTopsite", value: "Pin to Top Sites", comment: "The title for the pinning a topsite action")
    public static let RemovePinTopsiteActionTitle = NSLocalizedString("ActivityStream.ContextMenu.RemovePinTopsite", value: "Remove Pinned Site", comment: "The title for removing a pinned topsite action")
}

//  PhotonActionSheet Strings
extension Strings {
    public static let CancelButtonTitle = NSLocalizedString("PhotonMenu.cancel", value: "Cancel", comment: "Button for closing the menu action sheet")

}

// Settings.
extension Strings {
    public static let SettingsClearPrivateDataClearButton = NSLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = NSLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsClearPrivateDataTitle = NSLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
    public static let SettingsDisconnectSyncAlertTitle = NSLocalizedString("Settings.Disconnect.Title", value: "Disconnect Sync?", comment: "Title of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncButton = NSLocalizedString("Settings.Disconnect.Button", value: "Disconnect Sync", comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA")
    public static let SettingsDisconnectDestructiveAction = NSLocalizedString("Settings.Disconnect.DestructiveButton", value: "Disconnect", comment: "Destructive action button in alert when user is prompted for disconnect")
    public static let SettingsSearchDoneButton = NSLocalizedString("Settings.Search.Done.Button", value: "Done", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = NSLocalizedString("Settings.Search.Edit.Button", value: "Edit", comment: "Button displayed at the top of the search settings.")
    public static let UseTouchID = NSLocalizedString("Use Touch ID", tableName: "AuthenticationManager", comment: "List section title for when to use Touch ID")
    public static let UseFaceID = NSLocalizedString("Use Face ID", tableName: "AuthenticationManager", comment: "List section title for when to use Face ID")
}

// Error pages.
extension Strings {
    public static let ErrorPagesAdvancedButton = NSLocalizedString("ErrorPages.Advanced.Button", value: "Advanced", comment: "Label for button to perform advanced actions on the error page")
    public static let ErrorPagesAdvancedWarning1 = NSLocalizedString("ErrorPages.AdvancedWarning1.Text", value: "Warning: we can’t confirm your connection to this website is secure.", comment: "Warning text when clicking the Advanced button on error pages")
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
    public static let SyncedTabsTableViewCellTitle = NSLocalizedString("HistoryPanel.SyncedTabsCell.Title", value: "Synced Devices", comment: "Title for the Synced Tabs Cell in the History Panel")
    public static let HistoryBackButtonTitle = NSLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let EmptySyncedTabsPanelStateTitle = NSLocalizedString("HistoryPanel.EmptySyncedTabsState.Title", value: "Firefox Sync", comment: "Title for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsState.Description", value: "Sign in to view open tabs on your other devices.", comment: "Description for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelNullStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsNullState.Description", value: "Your tabs from other devices show up here.", comment: "Description for the empty synced tabs null state in the History Panel")
    public static let SyncedTabsTableViewCellDescription = NSLocalizedString("HistoryPanel.SyncedTabsCell.Description.Pluralized", value: "%d device(s) connected", comment: "Description that corresponds with a number of devices connected for the Synced Tabs Cell in the History Panel")
    public static let HistoryPanelEmptyStateTitle = NSLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.")
    public static let RecentlyClosedTabsButtonTitle = NSLocalizedString("HistoryPanel.RecentlyClosedTabsButton.Title", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel")
    public static let RecentlyClosedTabsPanelTitle = NSLocalizedString("RecentlyClosedTabsPanel.Title", value: "Recently Closed", comment: "Title for the Recently Closed Tabs Panel")
    public static let FirefoxHomePage = NSLocalizedString("Firefox.HomePage.Title", value: "Firefox Home Page", comment: "Title for firefox about:home page in tab history list")
}

// Syncing
extension Strings {
    public static let SyncingMessageWithEllipsis = NSLocalizedString("Sync.SyncingEllipsis.Label", value: "Syncing…", comment: "Message displayed when the user's account is syncing with ellipsis at the end")
    public static let SyncingMessageWithoutEllipsis = NSLocalizedString("Sync.Syncing.Label", value: "Syncing", comment: "Message displayed when the user's account is syncing with no ellipsis")

    public static let FirstTimeSyncLongTime = NSLocalizedString("Sync.FirstTimeMessage.Label", value: "Your first sync may take a while", comment: "Message displayed when the user syncs for the first time")

    public static let FirefoxSyncOfflineTitle = NSLocalizedString("SyncState.Offline.Title", value: "Sync is offline", comment: "Title for Sync status message when Sync failed due to being offline")
    public static let FirefoxSyncNotStartedTitle = NSLocalizedString("SyncState.NotStarted.Title", value: "Sync is unavailable", comment: "Title for Sync status message when Sync failed to start.")
    public static let FirefoxSyncPartialTitle = NSLocalizedString("SyncState.Partial.Title", value: "Sync is experiencing issues syncing %@", comment: "Title for Sync status message when a component of Sync failed to complete, where %@ represents the name of the component, i.e. Sync is experiencing issues syncing Bookmarks")
    public static let FirefoxSyncFailedTitle = NSLocalizedString("SyncState.Failed.Title", value: "Syncing has failed", comment: "Title for Sync status message when synchronization failed to complete")
    public static let FirefoxSyncTroubleshootTitle = NSLocalizedString("Settings.TroubleShootSync.Title", value: "Troubleshoot", comment: "Title of link to help page to find out how to solve Sync issues")

    public static let FirefoxSyncBookmarksEngine = NSLocalizedString("Bookmarks", comment: "Toggle bookmarks syncing setting")
    public static let FirefoxSyncHistoryEngine = NSLocalizedString("History", comment: "Toggle history syncing setting")
    public static let FirefoxSyncTabsEngine = NSLocalizedString("Open Tabs", comment: "Toggle tabs syncing setting")
    public static let FirefoxSyncLoginsEngine = NSLocalizedString("Logins", comment: "Toggle logins syncing setting")

    public static func localizedStringForSyncComponent(_ componentName: String) -> String? {
        switch componentName {
        case "bookmarks":
            return NSLocalizedString("SyncState.Bookmark.Title", value: "Bookmarks", comment: "The Bookmark sync component, used in SyncState.Partial.Title")
        case "clients":
            return NSLocalizedString("SyncState.Clients.Title", value: "Remote Clients", comment: "The Remote Clients sync component, used in SyncState.Partial.Title")
        case "tabs":
            return NSLocalizedString("SyncState.Tabs.Title", value: "Tabs", comment: "The Tabs sync component, used in SyncState.Partial.Title")
        case "logins":
            return NSLocalizedString("SyncState.Logins.Title", value: "Logins", comment: "The Logins sync component, used in SyncState.Partial.Title")
        case "history":
            return NSLocalizedString("SyncState.History.Title", value: "History", comment: "The History sync component, used in SyncState.Partial.Title")
        default: return nil
        }
    }
}

// Firefox Account
extension Strings {
    // Settings strings
    public static let FxAFirefoxAccount = NSLocalizedString("FxA.FirefoxAccount", value: "Firefox Account", comment: "Settings section title for Firefox Account")
    public static let FxASignIntoSync = NSLocalizedString("FxA.SignIntoSync", value: "Sign in to Sync", comment: "Button label to sign into Sync")
    public static let FxATakeYourWebWithYou = NSLocalizedString("FxA.TakeYourWebWithYou", value: "Take Your Web With You", comment: "Call to action for sign into sync button")
    public static let FxASyncUsageDetails = NSLocalizedString("FxA.SyncExplain", value: "Get your tabs, bookmarks, and passwords from your other devices.", comment: "Label explaining what sync does")
    public static let FxAAccountVerificationRequired = NSLocalizedString("FxA.AccountVerificationRequired", value: "Account Verification Required", comment: "Label stating your account is not verified")
    public static let FxAAccountVerificationDetails = NSLocalizedString("FxA.AccountVerificationDetails", value: "Wrong email? Disconnect below to start over.", comment: "Label stating how to disconnect account")
    public static let FxAManageAccount = NSLocalizedString("FxA.ManageAccount", value: "Manage Account", comment: "Button label to goto Firefox Account settings")
    public static let FxASyncNow = NSLocalizedString("FxA.SyncNow", value: "Sync Now", comment: "Button label to Sync your Firefox Account")
    public static let FxANoInternetConnection = NSLocalizedString("FxA.NoInternetConnection", value: "No Internet Connection", comment: "Label when no internet is present")
    public static let SettingsSyncSectionName = NSLocalizedString("Settings.Sync.SectionName", value: "Sync Options", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the sync options.")
    public static let SettingsSyncTitle = NSLocalizedString("Settings.Sync.Title", value: "Sync Options", comment: "Title displayed in header of the sync setting panel.")
    
    // Surface error strings
    public static let FxAAccountVerificationRequiredSurface = NSLocalizedString("FxA.AccountVerificationRequiredSurface", value: "You need to verify %@. Check your email for the verification link from Firefox.", comment: "Message explaining that user needs to check email for Firefox Account verfication link.")
    public static let FxAResendEmail = NSLocalizedString("FxA.ResendEmail", value: "Resend Email", comment: "Button label to resend email")
}

//Hotkey Titles
extension Strings {
    public static let ReloadPageTitle = NSLocalizedString("Hotkeys.Reload.DiscoveryTitle", value: "Reload Page", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let BackTitle = NSLocalizedString("Hotkeys.Back.DiscoveryTitle", value: "Back", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ForwardTitle = NSLocalizedString("Hotkeys.Forward.DiscoveryTitle", value: "Forward", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")

    public static let FindTitle = NSLocalizedString("Hotkeys.Find.DiscoveryTitle", value: "Find", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let SelectLocationBarTitle = NSLocalizedString("Hotkeys.SelectLocationBar.DiscoveryTitle", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewTabTitle = NSLocalizedString("Hotkeys.NewTab.DiscoveryTitle", value: "New Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewPrivateTabTitle = NSLocalizedString("Hotkeys.NewPrivateTab.DiscoveryTitle", value: "New Private Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let CloseTabTitle = NSLocalizedString("Hotkeys.CloseTab.DiscoveryTitle", value: "Close Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowNextTabTitle = NSLocalizedString("Hotkeys.ShowNextTab.DiscoveryTitle", value: "Show Next Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowPreviousTabTitle = NSLocalizedString("Hotkeys.ShowPreviousTab.DiscoveryTitle", value: "Show Previous Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
}

// Home page.
extension Strings {
    public static let SettingsHomePageSectionName = NSLocalizedString("Settings.HomePage.SectionName", value: "Homepage", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.")
    public static let SettingsHomePageTitle = NSLocalizedString("Settings.HomePage.Title", value: "Homepage Settings", comment: "Title displayed in header of the setting panel.")
    public static let SettingsHomePageURLSectionTitle = NSLocalizedString("Settings.HomePage.URL.Title", value: "Current Homepage", comment: "Title of the setting section containing the URL of the current home page.")
    public static let SettingsHomePageUseCurrentPage = NSLocalizedString("Settings.HomePage.UseCurrent.Button", value: "Use Current Page", comment: "Button in settings to use the current page as home page.")
    public static let SettingsHomePagePlaceholder = NSLocalizedString("Settings.HomePage.URL.Placeholder", value: "Enter a webpage", comment: "Placeholder text in the homepage setting when no homepage has been set.")
    public static let SettingsHomePageUseCopiedLink = NSLocalizedString("Settings.HomePage.UseCopiedLink.Button", value: "Use Copied Link", comment: "Button in settings to use the current link on the clipboard as home page.")
    public static let SettingsHomePageUseDefault = NSLocalizedString("Settings.HomePage.UseDefault.Button", value: "Use Default", comment: "Button in settings to use the default home page. If no default is set, then this button isn't shown.")
    public static let SettingsHomePageClear = NSLocalizedString("Settings.HomePage.Clear.Button", value: "Clear", comment: "Button in settings to clear the home page.")
    public static let SetHomePageDialogTitle = NSLocalizedString("HomePage.Set.Dialog.Title", value: "Do you want to use this web page as your home page?", comment: "Alert dialog title when the user opens the home page for the first time.")
    public static let SetHomePageDialogMessage = NSLocalizedString("HomePage.Set.Dialog.Message", value: "You can change this at any time in Settings", comment: "Alert dialog body when the user opens the home page for the first time.")
    public static let SetHomePageDialogYes = NSLocalizedString("HomePage.Set.Dialog.OK", value: "Set Homepage", comment: "Button accepting changes setting the home page for the first time.")
    public static let SetHomePageDialogNo = NSLocalizedString("HomePage.Set.Dialog.Cancel", value: "Cancel", comment: "Button cancelling changes setting the home page for the first time.")
}

// New tab choice settings
extension Strings {
    public static let SettingsNewTabSectionName = NSLocalizedString("Settings.NewTab.SectionName", value: "New Tab", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behaviour.")
    public static let SettingsNewTabTitle = NSLocalizedString("Settings.NewTab.Title", value: "New Tab Settings", comment: "Title displayed in header of the setting panel.")
    public static let SettingsNewTabTopSites = NSLocalizedString("Settings.NewTab.Option.TopSites", value: "Show your Top Sites", comment: "Option in settings to show top sites when you open a new tab")
    public static let SettingsNewTabBookmarks = NSLocalizedString("Settings.NewTab.Option.Bookmarks", value: "Show your Bookmarks", comment: "Option in settings to show bookmarks when you open a new tab")
    public static let SettingsNewTabHistory = NSLocalizedString("Settings.NewTab.Option.History", value: "Show your History", comment: "Option in settings to show history when you open a new tab")
    public static let SettingsNewTabReadingList = NSLocalizedString("Settings.NewTab.Option.ReadingList", value: "Show your Reading List", comment: "Option in settings to show reading list when you open a new tab")
    public static let SettingsNewTabBlankPage = NSLocalizedString("Settings.NewTab.Option.BlankPage", value: "Show a Blank Page", comment: "Option in settings to show a blank page when you open a new tab")
    public static let SettingsNewTabHomePage = NSLocalizedString("Settings.NewTab.Option.HomePage", value: "Show your Homepage", comment: "Option in settings to show your homepage when you open a new tab")
    public static let SettingsNewTabDescription = NSLocalizedString("Settings.NewTab.Description", value: "When you open a New Tab:", comment: "A description in settings of what the new tab choice means")
    // AS Panel settings
    public static let SettingsNewTabASTitle = NSLocalizedString("Settings.NewTab.Option.ASTitle", value: "Additional Content", comment: "The title of the section in newtab that lets you modify the topsites panel")
    public static let SettingsNewTabPocket = NSLocalizedString("Settings.NewTab.Option.Pocket", value: "Recommended by Pocket", comment: "Option in settings to turn on off pocket recommendations")
    public static let SettingsNewTabHiglightsHistory = NSLocalizedString("Settings.NewTab.Option.HighlightsHistory", value: "Visited", comment: "Option in settings to turn off history in the highlights section")
    public static let SettingsNewTabHighlightsBookmarks = NSLocalizedString("Settings.NewTab.Option.HighlightsBookmarks", value: "Recent Bookmarks", comment: "Option in the settings to turn off recent bookmarks in the Highlights section")
}

// Custom account settings - These strings did not make it for the v10 l10n deadline so we have turned them into regular strings. These strings will come back localized in a next version.

extension Strings {
    // Settings.AdvanceAccount.SectionName
    // Label used as an item in Settings. When touched it will open a dialog to setup advance Firefox account settings.
    public static let SettingsAdvanceAccountSectionName = "Account Settings"

    // Settings.AdvanceAccount.SectionFooter
    // Details for using custom Firefox Account service.
    public static let SettingsAdvanceAccountSectionFooter = "To use a custom Firefox Account and sync servers, specify the root Url of the Firefox Account site. This will download the configuration and setup this device to use the new service. After the new service has been set, you will need to create a new Firefox Account or login with an existing one."

    // Settings.AdvanceAccount.SectionName
    // Title displayed in header of the setting panel.
    public static let SettingsAdvanceAccountTitle = "Advance Account Settings"

    // Settings.AdvanceAccount.UrlPlaceholder
    // Title displayed in header of the setting panel.
    public static let SettingsAdvanceAccountUrlPlaceholder = "Custom Account Url"

    // Settings.AdvanceAccount.UpdatedAlertMessage
    // Messaged displayed when sync service has been successfully set.
    public static let SettingsAdvanceAccountUrlUpdatedAlertMessage = "Firefox account service updated. To begin using custom server, please log out and re-login."

    // Settings.AdvanceAccount.UpdatedAlertOk
    // Ok button on custom sync service updated alert
    public static let SettingsAdvanceAccountUrlUpdatedAlertOk = "OK"

    // Settings.AdvanceAccount.ErrorAlertTitle
    // Error alert message title.
    public static let SettingsAdvanceAccountUrlErrorAlertTitle = "Error"

    // Settings.AdvanceAccount.ErrorAlertMessage
    // Messaged displayed when sync service has an error setting a custom sync url.
    public static let SettingsAdvanceAccountUrlErrorAlertMessage = "There was an error while attempting to parse the url. Please make sure that it is a valid Firefox Account root url."

    // Settings.AdvanceAccount.ErrorAlertOk
    // Ok button on custom sync service error alert.
    public static let SettingsAdvanceAccountUrlErrorAlertOk = "OK"

    // Settings.AdvanceAccount.UseCustomAccountsServiceTitle
    // Toggle switch to use custom FxA server
    public static let SettingsAdvanceAccountUseCustomAccountsServiceTitle = "Use Custom Account Service"

    // Settings.AdvanceAccount.UrlEmptyErrorAlertMessage
    // No custom service set.
    public static let SettingsAdvanceAccountEmptyUrlErrorAlertMessage = "Please enter a custom account url before enabling."
}

// Open With Settings
extension Strings {
    public static let SettingsOpenWithSectionName = NSLocalizedString("Settings.OpenWith.SectionName", value: "Mail App", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behaviour.")
    public static let SettingsOpenWithPageTitle = NSLocalizedString("Settings.OpenWith.PageTitle", value: "Open mail links with", comment: "Title for Open With Settings")
}

// Third Party Search Engines
extension Strings {
    public static let ThirdPartySearchEngineAdded = NSLocalizedString("Search.ThirdPartyEngines.AddSuccess", value: "Added Search engine!", comment: "The success message that appears after a user sucessfully adds a new search engine")
    public static let ThirdPartySearchAddTitle = NSLocalizedString("Search.ThirdPartyEngines.AddTitle", value: "Add Search Provider?", comment: "The title that asks the user to Add the search provider")
    public static let ThirdPartySearchAddMessage = NSLocalizedString("Search.ThirdPartyEngines.AddMessage", value: "The new search engine will appear in the quick search bar.", comment: "The message that asks the user to Add the search provider explaining where the search engine will appear")
    public static let ThirdPartySearchCancelButton = NSLocalizedString("Search.ThirdPartyEngines.Cancel", value: "Cancel", comment: "The cancel button if you do not want to add a search engine.")
    public static let ThirdPartySearchOkayButton = NSLocalizedString("Search.ThirdPartyEngines.OK", value: "OK", comment: "The confirmation button")
    public static let ThirdPartySearchFailedTitle = NSLocalizedString("Search.ThirdPartyEngines.FailedTitle", value: "Failed", comment: "A title explaining that we failed to add a search engine")
    public static let ThirdPartySearchFailedMessage = NSLocalizedString("Search.ThirdPartyEngines.FailedMessage", value: "The search provider could not be added.", comment: "A title explaining that we failed to add a search engine")
    public static let CustomEngineFormErrorTitle = NSLocalizedString("Search.ThirdPartyEngines.FormErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineFormErrorMessage = NSLocalizedString("Search.ThirdPartyEngines.FormErrorMessage", value: "Please fill all fields correctly.", comment: "A message explaining fault in custom search engine form.")
    public static let CustomEngineDuplicateErrorTitle = NSLocalizedString("Search.ThirdPartyEngines.DuplicateErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineDuplicateErrorMessage = NSLocalizedString("Search.ThirdPartyEngines.DuplicateErrorMessage", value: "A search engine with this title or URL has already been added.", comment: "A message explaining fault in custom search engine form.")
}

// Bookmark Management
extension Strings {
    public static let BookmarksTitle = NSLocalizedString("Bookmarks.Title.Label", value: "Title", comment: "The label for the title of a bookmark")
    public static let BookmarksURL = NSLocalizedString("Bookmarks.URL.Label", value: "URL", comment: "The label for the URL of a bookmark")
    public static let BookmarksFolder = NSLocalizedString("Bookmarks.Folder.Label", value: "Folder", comment: "The label to show the location of the folder where the bookmark is located")
    public static let BookmarksNewFolder = NSLocalizedString("Bookmarks.NewFolder.Label", value: "New Folder", comment: "The button to create a new folder")
    public static let BookmarksFolderName = NSLocalizedString("Bookmarks.FolderName.Label", value: "Folder Name", comment: "The label for the title of the new folder")
    public static let BookmarksFolderLocation = NSLocalizedString("Bookmarks.FolderLocation.Label", value: "Location", comment: "The label for the location of the new folder")
}

// Tabs Delete All Undo Toast
extension Strings {
    public static let TabsDeleteAllUndoTitle = NSLocalizedString("Tabs.DeleteAllUndo.Title", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed")
    public static let TabsDeleteAllUndoAction = NSLocalizedString("Tabs.DeleteAllUndo.Button", value: "Undo", comment: "The button to undo the delete all tabs")
}

//Clipboard Toast
extension Strings {
    public static let GoToCopiedLink = NSLocalizedString("ClipboardToast.GoToCopiedLink.Title", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard")
    public static let GoButtonTittle = NSLocalizedString("ClipboardToast.GoToCopiedLink.Button", value: "Go", comment: "The button to open a new tab with the copied link")

    public static let SettingsOfferClipboardBarTitle = NSLocalizedString("Settings.OfferClipboardBar.Title", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
    public static let SettingsOfferClipboardBarStatus = NSLocalizedString("Settings.OfferClipboardBar.Status", value: "When Opening Firefox", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
}

// errors
extension Strings {
    public static let UnableToDownloadError = NSLocalizedString("Downloads.Error.Message", value: "Downloads aren’t supported in Firefox yet.", comment: "The message displayed to a user when they try and perform the download of an asset that Firefox cannot currently handle.")
    public static let UnableToAddPassErrorTitle = NSLocalizedString("AddPass.Error.Title", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorMessage = NSLocalizedString("AddPass.Error.Message", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorDismiss = NSLocalizedString("AddPass.Error.Dismiss", value: "OK", comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToOpenURLError = NSLocalizedString("OpenURL.Error.Message", value: "Firefox cannot open the page because it has an invalid address.", comment: "The message displayed to a user when they try to open a URL that cannot be handled by Firefox, or any external app.")
    public static let UnableToOpenURLErrorTitle = NSLocalizedString("OpenURL.Error.Title", value: "Cannot Open Page", comment: "Title of the message shown when the user attempts to navigate to an invalid link.")
}

// open in
extension Strings {
    public static let OpenInDownloadHelperAlertTitle = NSLocalizedString("Downloads.Alert.Title", value: "Firefox Downloads", comment: "The title of the alert box asking the user if they want to use another app to open a file.")
    public static let OpenInDownloadHelperAlertMessage = NSLocalizedString("Downloads.Alert.Message", value: "Firefox is unable to download or display this file. Would you like to open it in another app?", comment: "The message of the alert box asking the user if they want to use another app to open a file.")
    public static let OpenInDownloadHelperAlertConfirm = NSLocalizedString("Downloads.Alert.Confirm", value: "Yes", comment: "The label of the button the user will press to be presented with a list of other apps to open a file in")
    public static let OpenInDownloadHelperAlertCancel = NSLocalizedString("Downloads.Alert.Cancel", value: "No", comment: "The label of the button the user will press to reject the option to open a file in another application")
}

// Add Custom Search Engine
extension Strings {
    public static let SettingsAddCustomEngine = NSLocalizedString("Settings.AddCustomEngine", value: "Add Search Engine", comment: "The button text in Search Settings that opens the Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitle = NSLocalizedString("Settings.AddCustomEngine.Title", value: "Add Search Engine", comment: "The title of the  Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitleLabel = NSLocalizedString("Settings.AddCustomEngine.TitleLabel", value: "Title", comment: "The title for the field which sets the title for a custom search engine.")
    public static let SettingsAddCustomEngineURLLabel = NSLocalizedString("Settings.AddCustomEngine.URLLabel", value: "URL", comment: "The title for URL Field")
    public static let SettingsAddCustomEngineTitlePlaceholder = NSLocalizedString("Settings.AddCustomEngine.TitlePlaceholder", value: "Search Engine", comment: "The placeholder for Title Field when saving a custom search engine.")
    public static let SettingsAddCustomEngineURLPlaceholder = NSLocalizedString("Settings.AddCustomEngine.URLPlaceholder", value: "URL (Replace Query with %s)", comment: "The placeholder for URL Field when saving a custom search engine")
    public static let SettingsAddCustomEngineSaveButtonText = NSLocalizedString("Settings.AddCustomEngine.SaveButtonText", value: "Save", comment: "The text on the Save button when saving a custom search engine")
}

// Context menu ButtonToast instances.
extension Strings {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = NSLocalizedString("ContextMenu.ButtonToast.NewTabOpened.LabelText", value: "New Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewTabOpenedButtonText = NSLocalizedString("ContextMenu.ButtonToast.NewTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedLabelText = NSLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.LabelText", value: "New Private Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Private Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedButtonText = NSLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Private Tab.")
}

// Sent tabs notifications. These are displayed when the app is backgrounded or the device is locked.
extension Strings {
    // zero tabs
    public static let SentTab_NoTabArrivingNotification_title = NSLocalizedString("SentTab.NoTabArrivingNotification.title", value: "Firefox Sync", comment: "Title of notification received after a spurious message from FxA has been received.")
    public static let SentTab_NoTabArrivingNotification_body =
        NSLocalizedString("SentTab.NoTabArrivingNotification.body", value: "Tap to begin", comment: "Body of notification received after a spurious message from FxA has been received.")

    // one or more tabs
    public static let SentTab_TabArrivingNotification_NoDevice_title = NSLocalizedString("SentTab_TabArrivingNotification_NoDevice_title", value: "Tab received", comment: "Title of notification shown when the device is sent one or more tabs from an unnamed device.")
    public static let SentTab_TabArrivingNotification_NoDevice_body = NSLocalizedString("SentTab_TabArrivingNotification_NoDevice_body", value: "New tab arrived from another device.", comment: "Body of notification shown when the device is sent one or more tabs from an unnamed device.")
    public static let SentTab_TabArrivingNotification_WithDevice_title = NSLocalizedString("SentTab_TabArrivingNotification_WithDevice_title", value: "Tab received from %@", comment: "Title of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the device name. This device name will be localized by that device.")
    public static let SentTab_TabArrivingNotification_WithDevice_body = NSLocalizedString("SentTab_TabArrivingNotification_WithDevice_body", value: "New tab arrived in %@", comment: "Body of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the app name.")

    // Notification Actions
    public static let SentTabViewActionTitle = NSLocalizedString("SentTab.ViewAction.title", value: "View", comment: "Label for an action used to view one or more tabs from a notification.")
    public static let SentTabBookmarkActionTitle = NSLocalizedString("SentTab.BookmarkAction.title", value: "Bookmark", comment: "Label for an action used to bookmark one or more tabs from a notification.")
    public static let SentTabAddToReadingListActionTitle = NSLocalizedString("SentTab.AddToReadingListAction.Title", value: "Add to Reading List", comment: "Label for an action used to add one or more tabs recieved from a notification to the reading list.")
}

// Additional messages sent via Push from FxA
extension Strings {
    public static let FxAPush_DeviceDisconnected_ThisDevice_title = NSLocalizedString("FxAPush_DeviceDisconnected_ThisDevice_title", value: "Sync Disconnected", comment: "Title of a notification displayed when this device has been disconnected by another device.")
    public static let FxAPush_DeviceDisconnected_ThisDevice_body = NSLocalizedString("FxAPush_DeviceDisconnected_ThisDevice_body", value: "This device has been successfully disconnected from Firefox Sync.", comment: "Body of a notification displayed when this device has been disconnected from FxA by another device.")
    public static let FxAPush_DeviceDisconnected_title = NSLocalizedString("FxAPush_DeviceDisconnected_title", value: "Sync Disconnected", comment: "Title of a notification displayed when named device has been disconnected from FxA.")
    public static let FxAPush_DeviceDisconnected_body = NSLocalizedString("FxAPush_DeviceDisconnected_body", value: "%@ has been successfully disconnected.", comment: "Body of a notification displayed when named device has been disconnected from FxA. %@ refers to the name of the disconnected device.")

    public static let FxAPush_DeviceDisconnected_UnknownDevice_body = NSLocalizedString("FxAPush_DeviceDisconnected_UnknownDevice_body", value: "A device has disconnected from Firefox Sync", comment: "Body of a notification displayed when unnamed device has been disconnected from FxA.")

    public static let FxAPush_DeviceConnected_title = NSLocalizedString("FxAPush_DeviceConnected_title", value: "Sync Connected", comment: "Title of a notification displayed when another device has connected to FxA.")
    public static let FxAPush_DeviceConnected_body = NSLocalizedString("FxAPush_DeviceConnected_body", value: "Firefox Sync has connected to %@", comment: "Title of a notification displayed when another device has connected to FxA. %@ refers to the name of the newly connected device.")
}

// Reader Mode.
extension Strings {
    public static let ReaderModeAvailableVoiceOverAnnouncement = NSLocalizedString("ReaderMode.Available.VoiceOverAnnouncement", value: "Reader Mode available", comment: "Accessibility message e.g. spoken by VoiceOver when Reader Mode becomes available.")
    public static let ReaderModeResetFontSizeAccessibilityLabel = NSLocalizedString("Reset text size", comment: "Accessibility label for button resetting font size in display settings of reader mode")
}

// QR Code scanner.
extension Strings {
    public static let ScanQRCodeViewTitle = NSLocalizedString("ScanQRCode.View.Title", value: "Scan QR Code", comment: "Title for the QR code scanner view.")
    public static let ScanQRCodeInstructionsLabel = NSLocalizedString("ScanQRCode.Instructions.Label", value: "Align QR code within frame to scan", comment: "Text for the instructions label, displayed in the QR scanner view")
    public static let ScanQRCodeInvalidDataErrorMessage = NSLocalizedString("ScanQRCode.InvalidDataError.Message", value: "The data is invalid", comment: "Text of the prompt user the data is invalid")
    public static let ScanQRCodePermissionErrorMessage = NSLocalizedString("ScanQRCode.PermissionError.Message", value: "Please allow Firefox to access your device’s camera in ‘Settings’ -> ‘Privacy’ -> ‘Camera’.", comment: "Text of the prompt user to setup the camera authorization.")
    public static let ScanQRCodeErrorOKButton = NSLocalizedString("ScanQRCode.Error.OK.Button", value: "OK", comment: "OK button to dismiss the error prompt.")
}

// App menu.
extension Strings {
    public static let AppMenuAddToReadingListTitleString = NSLocalizedString("Menu.AddToReadingList.Title", tableName: "Menu", value: "Add to Reading List", comment: "Label for the button, displayed in the menu, used to add a page to the reading list.")
    public static let AppMenuShowTabsTitleString = NSLocalizedString("Menu.ShowTabs.Title", tableName: "Menu", value: "Show Tabs", comment: "Label for the button, displayed in the menu, used to open the tabs tray")
    public static let AppMenuSharePageTitleString = NSLocalizedString("Menu.SharePageAction.Title", tableName: "Menu", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    public static let AppMenuCopyURLTitleString = NSLocalizedString("Menu.CopyURL.Title", tableName: "Menu", value: "Copy URL", comment: "Label for the button, displayed in the menu, used to copy the page url to the clipboard.")
    public static let AppMenuNewTabTitleString = NSLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    public static let AppMenuNewPrivateTabTitleString = NSLocalizedString("Menu.NewPrivateTabAction.Title", tableName: "Menu", value: "Open New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.")
    public static let AppMenuAddBookmarkTitleString = NSLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuRemoveBookmarkTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    public static let AppMenuFindInPageTitleString = NSLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    public static let AppMenuViewDesktopSiteTitleString = NSLocalizedString("Menu.ViewDekstopSiteAction.Title", tableName: "Menu", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    public static let AppMenuViewMobileSiteTitleString = NSLocalizedString("Menu.ViewMobileSiteAction.Title", tableName: "Menu", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    public static let AppMenuScanQRCodeTitleString = NSLocalizedString("Menu.ScanQRCodeAction.Title", tableName: "Menu", value: "Scan QR Code", comment: "Label for the button, displayed in the menu, used to open the QR code scanner.")
    public static let AppMenuSettingsTitleString = NSLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    public static let AppMenuCloseAllTabsTitleString = NSLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    public static let AppMenuOpenHomePageTitleString = NSLocalizedString("Menu.OpenHomePageAction.Title", tableName: "Menu", value: "Open Homepage", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    public static let AppMenuTopSitesTitleString = NSLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    public static let AppMenuBookmarksTitleString = NSLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bbookmarks home panel.")
    public static let AppMenuHistoryTitleString = NSLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel.")
    public static let AppMenuReadingListTitleString = NSLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel", tableName: "Menu", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel.")
    public static let AppMenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
    public static let TabTrayDeleteMenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.CloseAllTabs", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.")
    public static let AppMenuNightModeEnable = NSLocalizedString("Menu.NightModeTurnOn.Label", value: "Enable Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.")
    public static let AppMenuNightModeDisable = NSLocalizedString("Menu.NightModeTurnOff.Label", value: "Disable Night Mode", comment: "Label for the button, displayed in the menu, turns off night mode")
    public static let AppMenuNoImageModeEnable = NSLocalizedString("Menu.NoImageModeHideImages.Label", value: "Hide Images", comment: "Label for the button, displayed in the menu, hides images on the webpage when pressed.")
    public static let AppMenuNoImageModeDisable = NSLocalizedString("Menu.NoImageModeShowImages.Label", value: "Show Images", comment: "Label for the button, displayed in the menu, shows images on the webpage when pressed")
    public static let AppMenuCopyURLConfirmMessage = NSLocalizedString("Menu.CopyURL.Confirm", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.")
    public static let AppMenuAddBookmarkConfirmMessage = NSLocalizedString("Menu.AddBookmark.Confirm", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.")
    public static let AppMenuRemoveBookmarkConfirmMessage = NSLocalizedString("Menu.RemoveBookmark.Confirm", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.")
    public static let AppMenuAddToReadingListConfirmMessage = NSLocalizedString("Menu.AddToReadingList.Confirm", value: "Added To Reading List", comment: "Toast displayed to the user after adding the item to their reading list.")
    public static let SendToDeviceTitle = NSLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device")
}

// Snackbar shown when tapping app store link
extension Strings {
    public static let ExternalLinkAppStoreConfirmationTitle = NSLocalizedString("ExternalLink.AppStore.ConfirmationTitle", value: "Open this link in the App Store app?", comment: "Question shown to user when tapping a link that opens the App Store app")
}

// ContentBlocker/TrackingProtection strings
extension Strings {
    public static let SettingsTrackingProtectionSectionName = NSLocalizedString("Settings.TrackingProtection.SectionName", value: "Tracking Protection", comment: "Row in top-level of settings that gets tapped to show the tracking protection settings detail view.")

    public static let TrackingProtectionOptionAlwaysOn = NSLocalizedString("Settings.TrackingProtectionOption.OnLabel", value: "Always On", comment: "Settings option to specify that Tracking Protection is always on.")
    public static let TrackingProtectionOptionAlwaysOff = NSLocalizedString("Settings.TrackingProtectionOption.OffLabel", value: "Never", comment: "Settings option to specify that Tracking Protection is always off.")
    public static let TrackingProtectionOptionOnInPrivateBrowsing = NSLocalizedString("Settings.TrackingProtectionOption.OnInPrivateBrowsingLabel", value: "Private Browsing Mode Only", comment: "Settings option to specify that Tracking Protection is on only in Private Browsing mode.")

    public static let TrackingProtectionOptionOnOffHeader = NSLocalizedString("Settings.TrackingProtectionOption.EnabledStateHeaderLabel", value: "Use Tracking Protection to Block Known Trackers", comment: "Description label shown at the top of tracking protection options screen.")
    public static let TrackingProtectionOptionOnOffFooter = NSLocalizedString("Settings.TrackingProtectionOption.EnabledStateFooterLabel", value: "Tracking is the collection of your browsing data across multiple websites. Tracking can be used to build a profile and display content based on your browsing and personal information.", comment: "Description label shown on tracking protection options screen.")
    public static let TrackingProtectionOptionBlockListsTitle = NSLocalizedString("Settings.TrackingProtection.BlockListsTitle", value: "Block Lists", comment: "Title for tracking protection options section where Basic/Strict block list can be selected")
    public static let TrackingProtectionOptionBlockListsHeader = NSLocalizedString("Settings.TrackingProtection.BlockListsHeader", value: "You can choose which list Firefox will use to block Web elements that may track your browsing activity.", comment: "Header description for tracking protection options section where Basic/Strict block list can be selected")

    public static let TrackingProtectionOptionBlockListTypeBasic = NSLocalizedString("Settings.TrackingProtectionOption.BlockListBasic", value: "Basic (Recommended)", comment: "Tracking protection settings option for using the basic blocklist.")
    public static let TrackingProtectionOptionBlockListTypeBasicDescription = NSLocalizedString("Settings.TrackingProtectionOption.BlockListBasicDescription", value: "Allows some trackers so websites function properly.", comment: "Tracking protection settings option description for using the basic blocklist.")
    public static let TrackingProtectionOptionBlockListTypeStrict = NSLocalizedString("Settings.TrackingProtectionOption.BlockListStrict", value: "Strict", comment: "Tracking protection settings option for using the strict blocklist.")
    public static let TrackingProtectionOptionBlockListTypeStrictDescription = NSLocalizedString("Settings.TrackingProtectionOption.BlockListStrictDescription", value: "Blocks known trackers. Some websites may not function properly.", comment: "Tracking protection settings option description for using the strict blocklist.")

    public static let TrackingProtectionReloadWithout = NSLocalizedString("Menu.ReloadWithoutTrackingProtection.Title", value: "Reload Without Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website without Tracking Protection")
    public static let TrackingProtectionReloadWith = NSLocalizedString("Menu.ReloadWithTrackingProtection.Title", value: "Reload With Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website with Tracking Protection enabled")
}

// Settings Home
extension Strings {
    public static let SendUsageSettingTitle = NSLocalizedString("Settings.SendUsage.Title", value: "Send Usage Data", comment: "The title for the setting to send usage data.")
    public static let SendUsageSettingLink = NSLocalizedString("Settings.SendUsage.Link", value: "Learn More.", comment: "title for a link that explains how mozilla collects telemetry")
    public static let SendUsageSettingMessage = NSLocalizedString("Settings.SendUsage.Message", value: "Mozilla strives to only collect what we need to provide and improve Firefox for everyone.", comment: "A short description that explains why mozilla collects usage data.")
}

// Do not track 
extension Strings {
    public static let SettingsDoNotTrackTitle = NSLocalizedString("Settings.DNT.Title", value: "Send websites a Do Not Track signal that you don’t want to be tracked", comment: "DNT Settings title")
    public static let SettingsDoNotTrackOptionOnWithTP = NSLocalizedString("Settings.DNT.OptionOnWithTP", value: "Only when using Tracking Protection", comment: "DNT Settings option for only turning on when Tracking Protection is also on")
    public static let SettingsDoNotTrackOptionAlwaysOn = NSLocalizedString("Settings.DNT.OptionAlwaysOn", value: "Always", comment: "DNT Settings option for always on")
}

// MARK: Deprecated Strings (to be removed in next version)
private let logOut = NSLocalizedString("Log Out", comment: "Button in settings screen to disconnect from your account")
private let logOutQuestion = NSLocalizedString("Log Out?", comment: "Title of the 'log out firefox account' alert")
private let logOutDestructive = NSLocalizedString("Log Out", comment: "Disconnect button in the 'log out firefox account' alert")
