/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Strings {}

class BundleClass {}

func MZLocalizedString(_ key: String, tableName: String? = nil, value: String = "", comment: String) -> String {
    let bundle = Bundle(for: BundleClass.self)
    return NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value, comment: comment)
}

extension Strings {
    public static let OKString = MZLocalizedString("OK", comment: "OK button")
    public static let CancelString = MZLocalizedString("Cancel", comment: "Label for Cancel button")
    public static let NotNowString = MZLocalizedString("Toasts.NotNow", value: "Not Now", comment: "label for Not Now button")
    public static let AppStoreString = MZLocalizedString("Toasts.OpenAppStore", value: "Open App Store", comment: "Open App Store button")
    public static let UndoString = MZLocalizedString("Toasts.Undo", value: "Undo", comment: "Label for button to undo the action just performed")
    public static let OpenSettingsString = MZLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7")
}

// Table date section titles.
extension Strings {
    public static let TableDateSectionTitleToday = MZLocalizedString("Today", comment: "History tableview section header")
    public static let TableDateSectionTitleYesterday = MZLocalizedString("Yesterday", comment: "History tableview section header")
    public static let TableDateSectionTitleLastWeek = MZLocalizedString("Last week", comment: "History tableview section header")
    public static let TableDateSectionTitleLastMonth = MZLocalizedString("Last month", comment: "History tableview section header")
}

// Top Sites.
extension Strings {
    public static let TopSitesEmptyStateDescription = MZLocalizedString("TopSites.EmptyState.Description", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.")
    public static let TopSitesEmptyStateTitle = MZLocalizedString("TopSites.EmptyState.Title", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state")
    public static let TopSitesRemoveButtonAccessibilityLabel = MZLocalizedString("TopSites.RemovePage.Button", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Activity Stream.
extension Strings {
    public static let ASPocketTitle = MZLocalizedString("ActivityStream.Pocket.SectionTitle", value: "Trending on Pocket", comment: "Section title label for Recommended by Pocket section")
    public static let ASPocketTitle2 = MZLocalizedString("ActivityStream.Pocket.SectionTitle2", value: "Recommended by Pocket", comment: "Section title label for Recommended by Pocket section")
    public static let ASTopSitesTitle =  MZLocalizedString("ActivityStream.TopSites.SectionTitle", value: "Top Sites", comment: "Section title label for Top Sites")
    public static let ASShortcutsTitle =  MZLocalizedString("ActivityStream.Shortcuts.SectionTitle", value: "Shortcuts", comment: "Section title label for Shortcuts")
    public static let HighlightVistedText = MZLocalizedString("ActivityStream.Highlights.Visited", value: "Visited", comment: "The description of a highlight if it is a site the user has visited")
    public static let HighlightBookmarkText = MZLocalizedString("ActivityStream.Highlights.Bookmark", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked")
    public static let PocketTrendingText = MZLocalizedString("ActivityStream.Pocket.Trending", value: "Trending", comment: "The description of a Pocket Story")
    public static let PocketMoreStoriesText = MZLocalizedString("ActivityStream.Pocket.MoreLink", value: "More", comment: "The link that shows more Pocket trending stories")
    public static let TopSitesRowSettingFooter = MZLocalizedString("ActivityStream.TopSites.RowSettingFooter", value: "Set Rows", comment: "The title for the setting page which lets you select the number of top site rows")
    public static let TopSitesRowCount = MZLocalizedString("ActivityStream.TopSites.RowCount", value: "Rows: %d", comment: "label showing how many rows of topsites are shown. %d represents a number")
    public static let RecentlyBookmarkedTitle = MZLocalizedString("ActivityStream.NewRecentBookmarks.Title", value: "Recent Bookmarks", comment: "Section title label for recently bookmarked websites")
    public static let RecentlyVisitedTitle = MZLocalizedString("ActivityStream.RecentHistory.Title", value: "Recently Visited", comment: "Section title label for recently visited websites")
}

// Home Panel Context Menu.
extension Strings {
    public static let OpenInNewTabContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.OpenInNewTab", value: "Open in New Tab", comment: "The title for the Open in New Tab context menu action for sites in Home Panels")
    public static let OpenInNewPrivateTabContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.OpenInNewPrivateTab", value: "Open in New Private Tab", comment: "The title for the Open in New Private Tab context menu action for sites in Home Panels")
    public static let BookmarkContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Bookmark", value: "Bookmark", comment: "The title for the Bookmark context menu action for sites in Home Panels")
    public static let RemoveBookmarkContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.RemoveBookmark", value: "Remove Bookmark", comment: "The title for the Remove Bookmark context menu action for sites in Home Panels")
    public static let DeleteFromHistoryContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.DeleteFromHistory", value: "Delete from History", comment: "The title for the Delete from History context menu action for sites in Home Panels")
    public static let ShareContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Share", value: "Share", comment: "The title for the Share context menu action for sites in Home Panels")
    public static let RemoveContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Remove", value: "Remove", comment: "The title for the Remove context menu action for sites in Home Panels")
    public static let PinTopsiteActionTitle = MZLocalizedString("ActivityStream.ContextMenu.PinTopsite", value: "Pin to Top Sites", comment: "The title for the pinning a topsite action")
    public static let PinTopsiteActionTitle2 = MZLocalizedString("ActivityStream.ContextMenu.PinTopsite2", value: "Pin", comment: "The title for the pinning a topsite action")
    public static let UnpinTopsiteActionTitle2 = MZLocalizedString("ActivityStream.ContextMenu.UnpinTopsite", value: "Unpin", comment: "The title for the unpinning a topsite action")
    public static let AddToShortcutsActionTitle = MZLocalizedString("ActivityStream.ContextMenu.AddToShortcuts", value: "Add to Shortcuts", comment: "The title for the pinning a shortcut action")
    public static let RemovePinTopsiteActionTitle = MZLocalizedString("ActivityStream.ContextMenu.RemovePinTopsite", value: "Remove Pinned Site", comment: "The title for removing a pinned topsite action")
}

//  PhotonActionSheet Strings
extension Strings {
    public static let CloseButtonTitle = MZLocalizedString("PhotonMenu.close", value: "Close", comment: "Button for closing the menu action sheet")

}

// Home page.
extension Strings {
    public static let SettingsHomePageSectionName = MZLocalizedString("Settings.HomePage.SectionName", value: "Homepage", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.")
    public static let SettingsHomePageTitle = MZLocalizedString("Settings.HomePage.Title", value: "Homepage Settings", comment: "Title displayed in header of the setting panel.")
    public static let SettingsHomePageURLSectionTitle = MZLocalizedString("Settings.HomePage.URL.Title", value: "Current Homepage", comment: "Title of the setting section containing the URL of the current home page.")
    public static let SettingsHomePageUseCurrentPage = MZLocalizedString("Settings.HomePage.UseCurrent.Button", value: "Use Current Page", comment: "Button in settings to use the current page as home page.")
    public static let SettingsHomePagePlaceholder = MZLocalizedString("Settings.HomePage.URL.Placeholder", value: "Enter a webpage", comment: "Placeholder text in the homepage setting when no homepage has been set.")
    public static let SettingsHomePageUseCopiedLink = MZLocalizedString("Settings.HomePage.UseCopiedLink.Button", value: "Use Copied Link", comment: "Button in settings to use the current link on the clipboard as home page.")
    public static let SettingsHomePageUseDefault = MZLocalizedString("Settings.HomePage.UseDefault.Button", value: "Use Default", comment: "Button in settings to use the default home page. If no default is set, then this button isn't shown.")
    public static let SettingsHomePageClear = MZLocalizedString("Settings.HomePage.Clear.Button", value: "Clear", comment: "Button in settings to clear the home page.")
    public static let SetHomePageDialogTitle = MZLocalizedString("HomePage.Set.Dialog.Title", value: "Do you want to use this web page as your home page?", comment: "Alert dialog title when the user opens the home page for the first time.")
    public static let SetHomePageDialogMessage = MZLocalizedString("HomePage.Set.Dialog.Message", value: "You can change this at any time in Settings", comment: "Alert dialog body when the user opens the home page for the first time.")
    public static let SetHomePageDialogYes = MZLocalizedString("HomePage.Set.Dialog.OK", value: "Set Homepage", comment: "Button accepting changes setting the home page for the first time.")
    public static let SetHomePageDialogNo = MZLocalizedString("HomePage.Set.Dialog.Cancel", value: "Cancel", comment: "Button cancelling changes setting the home page for the first time.")
    public static let ReopenLastTabAlertTitle = MZLocalizedString("ReopenAlert.Title", value: "Reopen Last Closed Tab", comment: "Reopen alert title shown at home page.")
    public static let ReopenLastTabButtonText = MZLocalizedString("ReopenAlert.Actions.Reopen", value: "Reopen", comment: "Reopen button text shown in reopen-alert at home page.")
    public static let ReopenLastTabCancelText = MZLocalizedString("ReopenAlert.Actions.Cancel", value: "Cancel", comment: "Cancel button text shown in reopen-alert at home page.")
}

// Settings.
extension Strings {
    public static let SettingsGeneralSectionTitle = MZLocalizedString("Settings.General.SectionName", value: "General", comment: "General settings section title")
    public static let SettingsClearPrivateDataClearButton = MZLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearAllWebsiteDataButton = MZLocalizedString("Settings.ClearAllWebsiteData.Clear.Button", value: "Clear All Website Data", comment: "Button in Data Management that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = MZLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsDataManagementSectionName = MZLocalizedString("Settings.DataManagement.SectionName", value: "Data Management", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsFilterSitesSearchLabel = MZLocalizedString("Settings.DataManagement.SearchLabel", value: "Filter Sites", comment: "Default text in search bar for Data Management")
    public static let SettingsClearPrivateDataTitle = MZLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
    public static let SettingsDataManagementTitle = MZLocalizedString("Settings.DataManagement.Title", value: "Data Management", comment: "Title displayed in header of the setting panel.")
    public static let SettingsWebsiteDataTitle = MZLocalizedString("Settings.WebsiteData.Title", value: "Website Data", comment: "Title displayed in header of the Data Management panel.")
    public static let SettingsWebsiteDataShowMoreButton = MZLocalizedString("Settings.WebsiteData.ButtonShowMore", value: "Show More", comment: "Button shows all websites on website data tableview")
    public static let SettingsEditWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonEdit", value: "Edit", comment: "Button to edit website search results")
    public static let SettingsDeleteWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonDelete", value: "Delete", comment: "Button to delete website in search results")
    public static let SettingsDoneWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonDone", value: "Done", comment: "Button to exit edit website search results")
    public static let SettingsDisconnectSyncAlertTitle = MZLocalizedString("Settings.Disconnect.Title", value: "Disconnect Sync?", comment: "Title of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncAlertBody = MZLocalizedString("Settings.Disconnect.Body", value: "Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Body of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncButton = MZLocalizedString("Settings.Disconnect.Button", value: "Disconnect Sync", comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA")
    public static let SettingsDisconnectCancelAction = MZLocalizedString("Settings.Disconnect.CancelButton", value: "Cancel", comment: "Cancel action button in alert when user is prompted for disconnect")
    public static let SettingsDisconnectDestructiveAction = MZLocalizedString("Settings.Disconnect.DestructiveButton", value: "Disconnect", comment: "Destructive action button in alert when user is prompted for disconnect")
    public static let SettingsSearchDoneButton = MZLocalizedString("Settings.Search.Done.Button", value: "Done", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = MZLocalizedString("Settings.Search.Edit.Button", value: "Edit", comment: "Button displayed at the top of the search settings.")
    public static let UseTouchID = MZLocalizedString("Use Touch ID", tableName: "AuthenticationManager", comment: "List section title for when to use Touch ID")
    public static let UseFaceID = MZLocalizedString("Use Face ID", tableName: "AuthenticationManager", comment: "List section title for when to use Face ID")
    public static let SettingsCopyAppVersionAlertTitle = MZLocalizedString("Settings.CopyAppVersion.Title", value: "Copied to clipboard", comment: "Copy app version alert shown in settings.")
}

// Error pages.
extension Strings {
    public static let ErrorPagesAdvancedButton = MZLocalizedString("ErrorPages.Advanced.Button", value: "Advanced", comment: "Label for button to perform advanced actions on the error page")
    public static let ErrorPagesAdvancedWarning1 = MZLocalizedString("ErrorPages.AdvancedWarning1.Text", value: "Warning: we can’t confirm your connection to this website is secure.", comment: "Warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesAdvancedWarning2 = MZLocalizedString("ErrorPages.AdvancedWarning2.Text", value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.", comment: "Additional warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesCertWarningDescription = MZLocalizedString("ErrorPages.CertWarning.Description", value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Firefox has not connected to this website.", comment: "Warning text on the certificate error page")
    public static let ErrorPagesCertWarningTitle = MZLocalizedString("ErrorPages.CertWarning.Title", value: "This Connection is Untrusted", comment: "Title on the certificate error page")
    public static let ErrorPagesGoBackButton = MZLocalizedString("ErrorPages.GoBack.Button", value: "Go Back", comment: "Label for button to go back from the error page")
    public static let ErrorPagesVisitOnceButton = MZLocalizedString("ErrorPages.VisitOnce.Button", value: "Visit site anyway", comment: "Button label to temporarily continue to the site from the certificate error page")
}

// Logins Helper.
extension Strings {
    public static let LoginsHelperSaveLoginButtonTitle = MZLocalizedString("LoginsHelper.SaveLogin.Button", value: "Save Login", comment: "Button to save the user's password")
    public static let LoginsHelperDontSaveButtonTitle = MZLocalizedString("LoginsHelper.DontSave.Button", value: "Don’t Save", comment: "Button to not save the user's password")
    public static let LoginsHelperUpdateButtonTitle = MZLocalizedString("LoginsHelper.Update.Button", value: "Update", comment: "Button to update the user's password")
    public static let LoginsHelperDontUpdateButtonTitle = MZLocalizedString("LoginsHelper.DontUpdate.Button", value: "Don’t Update", comment: "Button to not update the user's password")
}

// Downloads Panel
extension Strings {
    public static let DownloadsPanelEmptyStateTitle = MZLocalizedString("DownloadsPanel.EmptyState.Title", value: "Downloaded files will show up here.", comment: "Title for the Downloads Panel empty state.")
    public static let DownloadsPanelDeleteTitle = MZLocalizedString("DownloadsPanel.Delete.Title", value: "Delete", comment: "Action button for deleting downloaded files in the Downloads panel.")
    public static let DownloadsPanelShareTitle = MZLocalizedString("DownloadsPanel.Share.Title", value: "Share", comment: "Action button for sharing downloaded files in the Downloads panel.")
}

// History Panel
extension Strings {
    public static let SyncedTabsTableViewCellTitle = MZLocalizedString("HistoryPanel.SyncedTabsCell.Title", value: "Synced Devices", comment: "Title for the Synced Tabs Cell in the History Panel")
    public static let HistoryBackButtonTitle = MZLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let EmptySyncedTabsPanelStateTitle = MZLocalizedString("HistoryPanel.EmptySyncedTabsState.Title", value: "Firefox Sync", comment: "Title for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelNotSignedInStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelNotSignedInState.Description", value: "Sign in to view a list of tabs from your other devices.", comment: "Description for the empty synced tabs 'not signed in' state in the History Panel")
    public static let EmptySyncedTabsPanelNotYetVerifiedStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelNotYetVerifiedState.Description", value: "Your account needs to be verified.", comment: "Description for the empty synced tabs 'not yet verified' state in the History Panel")
    public static let EmptySyncedTabsPanelSingleDeviceSyncStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelSingleDeviceSyncState.Description", value: "Want to see your tabs from other devices here?", comment: "Description for the empty synced tabs 'single device Sync' state in the History Panel")
    public static let EmptySyncedTabsPanelTabSyncDisabledStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelTabSyncDisabledState.Description", value: "Turn on tab syncing to view a list of tabs from your other devices.", comment: "Description for the empty synced tabs 'tab sync disabled' state in the History Panel")
    public static let EmptySyncedTabsPanelNullStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsNullState.Description", value: "Your tabs from other devices show up here.", comment: "Description for the empty synced tabs null state in the History Panel")
    public static let SyncedTabsTableViewCellDescription = MZLocalizedString("HistoryPanel.SyncedTabsCell.Description.Pluralized", value: "%d device(s) connected", comment: "Description that corresponds with a number of devices connected for the Synced Tabs Cell in the History Panel")
    public static let HistoryPanelEmptyStateTitle = MZLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.")
    public static let RecentlyClosedTabsButtonTitle = MZLocalizedString("HistoryPanel.RecentlyClosedTabsButton.Title", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel")
    public static let RecentlyClosedTabsPanelTitle = MZLocalizedString("RecentlyClosedTabsPanel.Title", value: "Recently Closed", comment: "Title for the Recently Closed Tabs Panel")
    public static let HistoryPanelClearHistoryButtonTitle = MZLocalizedString("HistoryPanel.ClearHistoryButtonTitle", value: "Clear Recent History…", comment: "Title for button in the history panel to clear recent history")
    public static let FirefoxHomePage = MZLocalizedString("Firefox.HomePage.Title", value: "Firefox Home Page", comment: "Title for firefox about:home page in tab history list")
}

extension String {
    public static let HistoryPanelDelete = MZLocalizedString("Delete", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the history panel.")
}

// Clear recent history action menu
extension Strings {
    public static let ClearHistoryMenuTitle = MZLocalizedString("HistoryPanel.ClearHistoryMenuTitle", value: "Clearing Recent History will remove history, cookies, and other browser data.", comment: "Title for popup action menu to clear recent history.")
    public static let ClearHistoryMenuOptionTheLastHour = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionTheLastHour", value: "The Last Hour", comment: "Button to perform action to clear history for the last hour")
    public static let ClearHistoryMenuOptionToday = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionToday", value: "Today", comment: "Button to perform action to clear history for today only")
    public static let ClearHistoryMenuOptionTodayAndYesterday = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionTodayAndYesterday", value: "Today and Yesterday", comment: "Button to perform action to clear history for yesterday and today")
    public static let ClearHistoryMenuOptionEverything = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionEverything", value: "Everything", comment: "Option title to clear all browsing history.")
}

// Syncing
extension Strings {
    public static let SyncingMessageWithEllipsis = MZLocalizedString("Sync.SyncingEllipsis.Label", value: "Syncing…", comment: "Message displayed when the user's account is syncing with ellipsis at the end")
    public static let SyncingMessageWithoutEllipsis = MZLocalizedString("Sync.Syncing.Label", value: "Syncing", comment: "Message displayed when the user's account is syncing with no ellipsis")

    public static let FirstTimeSyncLongTime = MZLocalizedString("Sync.FirstTimeMessage.Label", value: "Your first sync may take a while", comment: "Message displayed when the user syncs for the first time")

    public static let FirefoxSyncOfflineTitle = MZLocalizedString("SyncState.Offline.Title", value: "Sync is offline", comment: "Title for Sync status message when Sync failed due to being offline")
    public static let FirefoxSyncNotStartedTitle = MZLocalizedString("SyncState.NotStarted.Title", value: "Sync is unavailable", comment: "Title for Sync status message when Sync failed to start.")
    public static let FirefoxSyncPartialTitle = MZLocalizedString("SyncState.Partial.Title", value: "Sync is experiencing issues syncing %@", comment: "Title for Sync status message when a component of Sync failed to complete, where %@ represents the name of the component, i.e. Sync is experiencing issues syncing Bookmarks")
    public static let FirefoxSyncFailedTitle = MZLocalizedString("SyncState.Failed.Title", value: "Syncing has failed", comment: "Title for Sync status message when synchronization failed to complete")
    public static let FirefoxSyncTroubleshootTitle = MZLocalizedString("Settings.TroubleShootSync.Title", value: "Troubleshoot", comment: "Title of link to help page to find out how to solve Sync issues")
    public static let FirefoxSyncCreateAccount = MZLocalizedString("Sync.NoAccount.Description", value: "No account? Create one to sync Firefox between devices.", comment: "String displayed on Sign In to Sync page that allows the user to create a new account.")

    public static let FirefoxSyncBookmarksEngine = MZLocalizedString("Bookmarks", comment: "Toggle bookmarks syncing setting")
    public static let FirefoxSyncHistoryEngine = MZLocalizedString("History", comment: "Toggle history syncing setting")
    public static let FirefoxSyncTabsEngine = MZLocalizedString("Open Tabs", comment: "Toggle tabs syncing setting")
    public static let FirefoxSyncLoginsEngine = MZLocalizedString("Logins", comment: "Toggle logins syncing setting")

    public static func localizedStringForSyncComponent(_ componentName: String) -> String? {
        switch componentName {
        case "bookmarks":
            return MZLocalizedString("SyncState.Bookmark.Title", value: "Bookmarks", comment: "The Bookmark sync component, used in SyncState.Partial.Title")
        case "clients":
            return MZLocalizedString("SyncState.Clients.Title", value: "Remote Clients", comment: "The Remote Clients sync component, used in SyncState.Partial.Title")
        case "tabs":
            return MZLocalizedString("SyncState.Tabs.Title", value: "Tabs", comment: "The Tabs sync component, used in SyncState.Partial.Title")
        case "logins":
            return MZLocalizedString("SyncState.Logins.Title", value: "Logins", comment: "The Logins sync component, used in SyncState.Partial.Title")
        case "history":
            return MZLocalizedString("SyncState.History.Title", value: "History", comment: "The History sync component, used in SyncState.Partial.Title")
        default: return nil
        }
    }
}

// Firefox Logins
extension Strings {
    public static let LoginsAndPasswordsTitle = MZLocalizedString("Settings.LoginsAndPasswordsTitle", value: "Logins & Passwords", comment: "Title for the logins and passwords screen. Translation could just use 'Logins' if the title is too long")

    // Prompts
    public static let SaveLoginUsernamePrompt = MZLocalizedString("LoginsHelper.PromptSaveLogin.Title", value: "Save login %@ for %@?", comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.")
    public static let SaveLoginPrompt = MZLocalizedString("LoginsHelper.PromptSavePassword.Title", value: "Save password for %@?", comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.")
    public static let UpdateLoginUsernamePrompt = MZLocalizedString("LoginsHelper.PromptUpdateLogin.Title.TwoArg", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
    public static let UpdateLoginPrompt = MZLocalizedString("LoginsHelper.PromptUpdateLogin.Title.OneArg", value: "Update login for %@?", comment: "Prompt for updating a login. The first parameter is the hostname for which the password will be updated for.")

    // Setting
    public static let SettingToSaveLogins = MZLocalizedString("Settings.SaveLogins.Title", value: "Save Logins", comment: "Setting to enable the built-in password manager")
    public static let SettingToShowLoginsInAppMenu = MZLocalizedString("Settings.ShowLoginsInAppMenu.Title", value: "Show in Application Menu", comment: "Setting to show Logins & Passwords quick access in the application menu")

    // List view
    public static let LoginsListTitle = MZLocalizedString("LoginsList.Title", value: "SAVED LOGINS", comment: "Title for the list of logins")
    public static let LoginsListSearchPlaceholder = MZLocalizedString("LoginsList.LoginsListSearchPlaceholder", value: "Filter", comment: "Placeholder test for search box in logins list view.")
    public static let LoginsFilterWebsite = MZLocalizedString("LoginsList.LoginsListFilterWebsite", value: "Website", comment: "For filtering the login list, search only the website names")
    public static let LoginsFilterLogin = MZLocalizedString("LoginsList.LoginsListFilterLogin", value: "Login", comment: "For filtering the login list, search only the login names")
    public static let LoginsFilterAll = MZLocalizedString("LoginsList.LoginsListFilterSearchAll", value: "All", comment: "For filtering the login list, search both website and login names.")

    // Detail view
    public static let LoginsDetailViewLoginTitle = MZLocalizedString("LoginsDetailView.LoginTitle", value: "Login", comment: "Title for the login detail view")
    public static let LoginsDetailViewLoginModified = MZLocalizedString("LoginsDetailView.LoginModified", value: "Modified", comment: "Login detail view field name for the last modified date")

    // Breach Alerts
    public static let BreachAlertsTitle = MZLocalizedString("BreachAlerts.Title", value: "Website Breach", comment: "Title for the Breached Login Detail View.")
    public static let BreachAlertsLearnMore = MZLocalizedString("BreachAlerts.LearnMoreButton", value: "Learn more", comment: "Link to monitor.firefox.com to learn more about breached passwords")
    public static let BreachAlertsBreachDate = MZLocalizedString("BreachAlerts.BreachDate", value: "This breach occurred on", comment: "Describes the date on which the breach occurred")
    public static let BreachAlertsDescription = MZLocalizedString("BreachAlerts.Description", value: "Passwords were leaked or stolen since you last changed your password. To protect this account, log in to the site and change your password.", comment: "Description of what a breach is")
    public static let BreachAlertsLink = MZLocalizedString("BreachAlerts.Link", value: "Go to", comment: "Leads to a link to the breached website")
}

// Firefox Account
extension Strings {
    // Settings strings
    public static let FxAFirefoxAccount = MZLocalizedString("FxA.FirefoxAccount", value: "Firefox Account", comment: "Settings section title for Firefox Account")
    public static let FxASignInToSync = MZLocalizedString("FxA.SignIntoSync", value: "Sign in to Sync", comment: "Button label to sign into Sync")
    public static let FxATakeYourWebWithYou = MZLocalizedString("FxA.TakeYourWebWithYou", value: "Take Your Web With You", comment: "Call to action for sign into sync button")
    public static let FxASyncUsageDetails = MZLocalizedString("FxA.SyncExplain", value: "Get your tabs, bookmarks, and passwords from your other devices.", comment: "Label explaining what sync does")
    public static let FxAAccountVerificationRequired = MZLocalizedString("FxA.AccountVerificationRequired", value: "Account Verification Required", comment: "Label stating your account is not verified")
    public static let FxAAccountVerificationDetails = MZLocalizedString("FxA.AccountVerificationDetails", value: "Wrong email? Disconnect below to start over.", comment: "Label stating how to disconnect account")
    public static let FxAManageAccount = MZLocalizedString("FxA.ManageAccount", value: "Manage Account & Devices", comment: "Button label to go to Firefox Account settings")
    public static let FxASyncNow = MZLocalizedString("FxA.SyncNow", value: "Sync Now", comment: "Button label to Sync your Firefox Account")
    public static let FxANoInternetConnection = MZLocalizedString("FxA.NoInternetConnection", value: "No Internet Connection", comment: "Label when no internet is present")
    public static let FxASettingsTitle = MZLocalizedString("Settings.FxA.Title", value: "Firefox Account", comment: "Title displayed in header of the FxA settings panel.")
    public static let FxASettingsSyncSettings = MZLocalizedString("Settings.FxA.Sync.SectionName", value: "Sync Settings", comment: "Label used as a section title in the Firefox Accounts Settings screen.")
    public static let FxASettingsDeviceName = MZLocalizedString("Settings.FxA.DeviceName", value: "Device Name", comment: "Label used for the device name settings section.")
    public static let FxAOpenSyncPreferences = MZLocalizedString("FxA.OpenSyncPreferences", value: "Open Sync Preferences", comment: "Button label to open Sync preferences")
    public static let FxAConnectAnotherDevice = MZLocalizedString("FxA.ConnectAnotherDevice", value: "Connect Another Device", comment: "Button label to connect another device to Sync")
    public static let FxARemoveAccountButton = MZLocalizedString("FxA.RemoveAccount", value: "Remove", comment: "Remove button is displayed on firefox account page under certain scenarios where user would like to remove their account.")
    public static let FxARemoveAccountAlertTitle = MZLocalizedString("FxA.RemoveAccountAlertTitle", value: "Remove Account", comment: "Remove account alert is the final confirmation before user removes their firefox account")
    public static let FxARemoveAccountAlertMessage = MZLocalizedString("FxA.RemoveAccountAlertMessage", value: "Remove the Firefox Account associated with this device to sign in as a different user.", comment: "Description string for alert view that gets presented when user tries to remove an account.")

    // Surface error strings
    public static let FxAAccountVerificationRequiredSurface = MZLocalizedString("FxA.AccountVerificationRequiredSurface", value: "You need to verify %@. Check your email for the verification link from Firefox.", comment: "Message explaining that user needs to check email for Firefox Account verfication link.")
    public static let FxAResendEmail = MZLocalizedString("FxA.ResendEmail", value: "Resend Email", comment: "Button label to resend email")
    public static let FxAAccountVerifyEmail = MZLocalizedString("Verify your email address", comment: "Text message in the settings table view")
    public static let FxAAccountVerifyPassword = MZLocalizedString("Enter your password to connect", comment: "Text message in the settings table view")
    public static let FxAAccountUpgradeFirefox = MZLocalizedString("Upgrade Firefox to connect", comment: "Text message in the settings table view")
}

//Hotkey Titles
extension Strings {
    public static let ReloadPageTitle = MZLocalizedString("Hotkeys.Reload.DiscoveryTitle", value: "Reload Page", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let BackTitle = MZLocalizedString("Hotkeys.Back.DiscoveryTitle", value: "Back", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ForwardTitle = MZLocalizedString("Hotkeys.Forward.DiscoveryTitle", value: "Forward", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")

    public static let FindTitle = MZLocalizedString("Hotkeys.Find.DiscoveryTitle", value: "Find", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let SelectLocationBarTitle = MZLocalizedString("Hotkeys.SelectLocationBar.DiscoveryTitle", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let privateBrowsingModeTitle = MZLocalizedString("Hotkeys.PrivateMode.DiscoveryTitle", value: "Private Browsing Mode", comment: "Label to switch to private browsing mode")
    public static let normalBrowsingModeTitle = MZLocalizedString("Hotkeys.NormalMode.DiscoveryTitle", value: "Normal Browsing Mode", comment: "Label to switch to normal browsing mode")
    public static let NewTabTitle = MZLocalizedString("Hotkeys.NewTab.DiscoveryTitle", value: "New Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewPrivateTabTitle = MZLocalizedString("Hotkeys.NewPrivateTab.DiscoveryTitle", value: "New Private Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let CloseTabTitle = MZLocalizedString("Hotkeys.CloseTab.DiscoveryTitle", value: "Close Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowNextTabTitle = MZLocalizedString("Hotkeys.ShowNextTab.DiscoveryTitle", value: "Show Next Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowPreviousTabTitle = MZLocalizedString("Hotkeys.ShowPreviousTab.DiscoveryTitle", value: "Show Previous Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
}

// New tab choice settings
extension Strings {
    public static let CustomNewPageURL = MZLocalizedString("Settings.NewTab.CustomURL", value: "Custom URL", comment: "Label used to set a custom url as the new tab option (homepage).")
    public static let SettingsNewTabSectionName = MZLocalizedString("Settings.NewTab.SectionName", value: "New Tab", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behavior.")
    public static let NewTabSectionName =
        MZLocalizedString("Settings.NewTab.TopSectionName", value: "Show", comment: "Label at the top of the New Tab screen after entering New Tab in settings")
    public static let SettingsNewTabTitle = MZLocalizedString("Settings.NewTab.Title", value: "New Tab", comment: "Title displayed in header of the setting panel.")
    public static let NewTabSectionNameFooter =
        MZLocalizedString("Settings.NewTab.TopSectionNameFooter", value: "Choose what to load when opening a new tab", comment: "Footer at the bottom of the New Tab screen after entering New Tab in settings")
    public static let SettingsNewTabTopSites = MZLocalizedString("Settings.NewTab.Option.FirefoxHome", value: "Firefox Home", comment: "Option in settings to show Firefox Home when you open a new tab")
    public static let SettingsNewTabBookmarks = MZLocalizedString("Settings.NewTab.Option.Bookmarks", value: "Bookmarks", comment: "Option in settings to show bookmarks when you open a new tab")
    public static let SettingsNewTabHistory = MZLocalizedString("Settings.NewTab.Option.History", value: "History", comment: "Option in settings to show history when you open a new tab")
    public static let SettingsNewTabReadingList = MZLocalizedString("Settings.NewTab.Option.ReadingList", value: "Show your Reading List", comment: "Option in settings to show reading list when you open a new tab")
    public static let SettingsNewTabBlankPage = MZLocalizedString("Settings.NewTab.Option.BlankPage", value: "Blank Page", comment: "Option in settings to show a blank page when you open a new tab")
    public static let SettingsNewTabHomePage = MZLocalizedString("Settings.NewTab.Option.HomePage", value: "Homepage", comment: "Option in settings to show your homepage when you open a new tab")
    public static let SettingsNewTabDescription = MZLocalizedString("Settings.NewTab.Description", value: "When you open a New Tab:", comment: "A description in settings of what the new tab choice means")
    // AS Panel settings
    public static let SettingsNewTabASTitle = MZLocalizedString("Settings.NewTab.Option.ASTitle", value: "Customize Top Sites", comment: "The title of the section in newtab that lets you modify the topsites panel")
    public static let SettingsNewTabPocket = MZLocalizedString("Settings.NewTab.Option.Pocket", value: "Trending on Pocket", comment: "Option in settings to turn on off pocket recommendations")
    public static let SettingsNewTabRecommendedByPocket = MZLocalizedString("Settings.NewTab.Option.RecommendedByPocket", value: "Recommended by %@", comment: "Option in settings to turn on off pocket recommendations First argument is the pocket brand name")
    public static let SettingsNewTabRecommendedByPocketDescription = MZLocalizedString("Settings.NewTab.Option.RecommendedByPocketDescription", value: "Exceptional content curated by %@, part of the %@ family", comment: "Descriptoin for the option in settings to turn on off pocket recommendations. First argument is the pocket brand name, second argument is the pocket product name.")
    public static let SettingsNewTabPocketFooter = MZLocalizedString("Settings.NewTab.Option.PocketFooter", value: "Great content from around the web.", comment: "Footer caption for pocket settings")
    public static let SettingsNewTabHiglightsHistory = MZLocalizedString("Settings.NewTab.Option.HighlightsHistory", value: "Visited", comment: "Option in settings to turn off history in the highlights section")
    public static let SettingsNewTabHighlightsBookmarks = MZLocalizedString("Settings.NewTab.Option.HighlightsBookmarks", value: "Recent Bookmarks", comment: "Option in the settings to turn off recent bookmarks in the Highlights section")
    public static let SettingsTopSitesCustomizeTitle = MZLocalizedString("Settings.NewTab.Option.CustomizeTitle", value: "Customize Firefox Home", comment: "The title for the section to customize top sites in the new tab settings page.")
    public static let SettingsTopSitesCustomizeFooter = MZLocalizedString("Settings.NewTab.Option.CustomizeFooter", value: "The sites you visit most", comment: "The footer for the section to customize top sites in the new tab settings page.")
    public static let SettingsTopSitesCustomizeFooter2 = MZLocalizedString("Settings.NewTab.Option.CustomizeFooter2", value: "Sites you save or visit", comment: "The footer for the section to customize top sites in the new tab settings page.")

}

// For 'Advanced Sync Settings' view, which is a debug setting. English only, there is little value in maintaining L10N strings for these.
extension Strings {
    public static let SettingsAdvancedAccountTitle = "Advanced Sync Settings"
    public static let SettingsAdvancedAccountCustomFxAContentServerURI = "Custom Firefox Account Content Server URI"
    public static let SettingsAdvancedAccountUseCustomFxAContentServerURITitle = "Use Custom FxA Content Server"
    public static let SettingsAdvancedAccountCustomSyncTokenServerURI = "Custom Sync Token Server URI"
    public static let SettingsAdvancedAccountUseCustomSyncTokenServerTitle = "Use Custom Sync Token Server"
}

// Open With Settings
extension Strings {
    public static let SettingsOpenWithSectionName = MZLocalizedString("Settings.OpenWith.SectionName", value: "Mail App", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behavior.")
    public static let SettingsOpenWithPageTitle = MZLocalizedString("Settings.OpenWith.PageTitle", value: "Open mail links with", comment: "Title for Open With Settings")
}

// Third Party Search Engines
extension Strings {
    public static let ThirdPartySearchEngineAdded = MZLocalizedString("Search.ThirdPartyEngines.AddSuccess", value: "Added Search engine!", comment: "The success message that appears after a user sucessfully adds a new search engine")
    public static let ThirdPartySearchAddTitle = MZLocalizedString("Search.ThirdPartyEngines.AddTitle", value: "Add Search Provider?", comment: "The title that asks the user to Add the search provider")
    public static let ThirdPartySearchAddMessage = MZLocalizedString("Search.ThirdPartyEngines.AddMessage", value: "The new search engine will appear in the quick search bar.", comment: "The message that asks the user to Add the search provider explaining where the search engine will appear")
    public static let ThirdPartySearchCancelButton = MZLocalizedString("Search.ThirdPartyEngines.Cancel", value: "Cancel", comment: "The cancel button if you do not want to add a search engine.")
    public static let ThirdPartySearchOkayButton = MZLocalizedString("Search.ThirdPartyEngines.OK", value: "OK", comment: "The confirmation button")
    public static let ThirdPartySearchFailedTitle = MZLocalizedString("Search.ThirdPartyEngines.FailedTitle", value: "Failed", comment: "A title explaining that we failed to add a search engine")
    public static let ThirdPartySearchFailedMessage = MZLocalizedString("Search.ThirdPartyEngines.FailedMessage", value: "The search provider could not be added.", comment: "A title explaining that we failed to add a search engine")
    public static let CustomEngineFormErrorTitle = MZLocalizedString("Search.ThirdPartyEngines.FormErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineFormErrorMessage = MZLocalizedString("Search.ThirdPartyEngines.FormErrorMessage", value: "Please fill all fields correctly.", comment: "A message explaining fault in custom search engine form.")
    public static let CustomEngineDuplicateErrorTitle = MZLocalizedString("Search.ThirdPartyEngines.DuplicateErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineDuplicateErrorMessage = MZLocalizedString("Search.ThirdPartyEngines.DuplicateErrorMessage", value: "A search engine with this title or URL has already been added.", comment: "A message explaining fault in custom search engine form.")
}

// Root Bookmarks folders
extension Strings {
    public static let BookmarksFolderTitleMobile = MZLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
    public static let BookmarksFolderTitleMenu = MZLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
    public static let BookmarksFolderTitleToolbar = MZLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
    public static let BookmarksFolderTitleUnsorted = MZLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")
}

// Bookmark Management
extension Strings {
    public static let BookmarksTitle = MZLocalizedString("Bookmarks.Title.Label", value: "Title", comment: "The label for the title of a bookmark")
    public static let BookmarksURL = MZLocalizedString("Bookmarks.URL.Label", value: "URL", comment: "The label for the URL of a bookmark")
    public static let BookmarksFolder = MZLocalizedString("Bookmarks.Folder.Label", value: "Folder", comment: "The label to show the location of the folder where the bookmark is located")
    public static let BookmarksNewBookmark = MZLocalizedString("Bookmarks.NewBookmark.Label", value: "New Bookmark", comment: "The button to create a new bookmark")
    public static let BookmarksNewFolder = MZLocalizedString("Bookmarks.NewFolder.Label", value: "New Folder", comment: "The button to create a new folder")
    public static let BookmarksNewSeparator = MZLocalizedString("Bookmarks.NewSeparator.Label", value: "New Separator", comment: "The button to create a new separator")
    public static let BookmarksEditBookmark = MZLocalizedString("Bookmarks.EditBookmark.Label", value: "Edit Bookmark", comment: "The button to edit a bookmark")
    public static let BookmarksEdit = MZLocalizedString("Bookmarks.Edit.Button", value: "Edit", comment: "The button on the snackbar to edit a bookmark after adding it.")
    public static let BookmarksEditFolder = MZLocalizedString("Bookmarks.EditFolder.Label", value: "Edit Folder", comment: "The button to edit a folder")
    public static let BookmarksFolderName = MZLocalizedString("Bookmarks.FolderName.Label", value: "Folder Name", comment: "The label for the title of the new folder")
    public static let BookmarksFolderLocation = MZLocalizedString("Bookmarks.FolderLocation.Label", value: "Location", comment: "The label for the location of the new folder")
    public static let BookmarksDeleteFolderWarningTitle = MZLocalizedString("Bookmarks.DeleteFolderWarning.Title", tableName: "BookmarkPanelDeleteConfirm", value: "This folder isn’t empty.", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderWarningDescription = MZLocalizedString("Bookmarks.DeleteFolderWarning.Description", tableName: "BookmarkPanelDeleteConfirm", value: "Are you sure you want to delete it and its contents?", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderCancelButtonLabel = MZLocalizedString("Bookmarks.DeleteFolderWarning.CancelButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Cancel", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
    public static let BookmarksDeleteFolderDeleteButtonLabel = MZLocalizedString("Bookmarks.DeleteFolderWarning.DeleteButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Delete", comment: "Button label for the button that deletes a folder and all of its children.")
    public static let BookmarksPanelEmptyStateTitle = MZLocalizedString("BookmarksPanel.EmptyState.Title", value: "Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.")
    public static let BookmarksPanelDeleteTableAction = MZLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.")
    public static let BookmarkDetailFieldTitle = MZLocalizedString("Bookmark.DetailFieldTitle.Label", value: "Title", comment: "The label for the Title field when editing a bookmark")
    public static let BookmarkDetailFieldURL = MZLocalizedString("Bookmark.DetailFieldURL.Label", value: "URL", comment: "The label for the URL field when editing a bookmark")
    public static let BookmarkDetailFieldsHeaderBookmarkTitle = MZLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Bookmark.Title", value: "Bookmark", comment: "The header title for the fields when editing a Bookmark")
    public static let BookmarkDetailFieldsHeaderFolderTitle = MZLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Folder.Title", value: "Folder", comment: "The header title for the fields when editing a Folder")
}

// Tabs Delete All Undo Toast
extension Strings {
    public static let TabsDeleteAllUndoTitle = MZLocalizedString("Tabs.DeleteAllUndo.Title", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed")
    public static let TabsDeleteAllUndoAction = MZLocalizedString("Tabs.DeleteAllUndo.Button", value: "Undo", comment: "The button to undo the delete all tabs")
    public static let TabSearchPlaceholderText = MZLocalizedString("Tabs.Search.PlaceholderText", value: "Search Tabs", comment: "The placeholder text for the tab search bar")
}

// Tab tray (chronological tabs)
extension Strings {
    public static let TabTrayV2Title = MZLocalizedString("TabTray.Title", value: "Open Tabs", comment: "The title for the tab tray")
    public static let TabTrayV2TodayHeader = MZLocalizedString("TabTray.Today.Header", value: "Today", comment: "The section header for tabs opened today")
    public static let TabTrayV2YesterdayHeader = MZLocalizedString("TabTray.Yesterday.Header", value: "Yesterday", comment: "The section header for tabs opened yesterday")
    public static let TabTrayV2LastWeekHeader = MZLocalizedString("TabTray.LastWeek.Header", value: "Last Week", comment: "The section header for tabs opened last week")
    public static let TabTrayV2OlderHeader = MZLocalizedString("TabTray.Older.Header", value: "Older", comment: "The section header for tabs opened before last week")
    public static let TabTraySwipeMenuMore = MZLocalizedString("TabTray.SwipeMenu.More", value: "More", comment: "The button title to see more options to perform on the tab.")
    public static let TabTrayMoreMenuCopy = MZLocalizedString("TabTray.MoreMenu.Copy", value: "Copy", comment: "The title on the button to copy the tab address.")
    public static let TabTrayV2PrivateTitle = MZLocalizedString("TabTray.PrivateTitle", value: "Private Tabs", comment: "The title for the tab tray in private mode")

    // Segmented Control tites for iPad
    public static let TabTraySegmentedControlTitlesTabs = MZLocalizedString("TabTray.SegmentedControlTitles.Tabs", value: "Tabs", comment: "The title on the button to look at regular tabs.")
    public static let TabTraySegmentedControlTitlesPrivateTabs = MZLocalizedString("TabTray.SegmentedControlTitles.PrivateTabs", value: "Private", comment: "The title on the button to look at private tabs.")
    public static let TabTraySegmentedControlTitlesSyncedTabs = MZLocalizedString("TabTray.SegmentedControlTitles.SyncedTabs", value: "Synced", comment: "The title on the button to look at synced tabs.")
}

//Clipboard Toast
extension Strings {
    public static let GoToCopiedLink = MZLocalizedString("ClipboardToast.GoToCopiedLink.Title", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard")
    public static let GoButtonTittle = MZLocalizedString("ClipboardToast.GoToCopiedLink.Button", value: "Go", comment: "The button to open a new tab with the copied link")

    public static let SettingsOfferClipboardBarTitle = MZLocalizedString("Settings.OfferClipboardBar.Title", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
    public static let SettingsOfferClipboardBarStatus = MZLocalizedString("Settings.OfferClipboardBar.Status", value: "When Opening Firefox", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
}

// Link Previews
extension Strings {
    public static let SettingsShowLinkPreviewsTitle = MZLocalizedString("Settings.ShowLinkPreviews.Title", value: "Show Link Previews", comment: "Title of setting to enable link previews when long-pressing links.")
    public static let SettingsShowLinkPreviewsStatus = MZLocalizedString("Settings.ShowLinkPreviews.Status", value: "When Long-pressing Links", comment: "Description displayed under the ”Show Link Previews” option")
}

// errors
extension Strings {
    public static let UnableToDownloadError = MZLocalizedString("Downloads.Error.Message", value: "Downloads aren’t supported in Firefox yet.", comment: "The message displayed to a user when they try and perform the download of an asset that Firefox cannot currently handle.")
    public static let UnableToAddPassErrorTitle = MZLocalizedString("AddPass.Error.Title", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorMessage = MZLocalizedString("AddPass.Error.Message", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorDismiss = MZLocalizedString("AddPass.Error.Dismiss", value: "OK", comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToOpenURLError = MZLocalizedString("OpenURL.Error.Message", value: "Firefox cannot open the page because it has an invalid address.", comment: "The message displayed to a user when they try to open a URL that cannot be handled by Firefox, or any external app.")
    public static let UnableToOpenURLErrorTitle = MZLocalizedString("OpenURL.Error.Title", value: "Cannot Open Page", comment: "Title of the message shown when the user attempts to navigate to an invalid link.")
}

// Download Helper
extension Strings {
    public static let OpenInDownloadHelperAlertDownloadNow = MZLocalizedString("Downloads.Alert.DownloadNow", value: "Download Now", comment: "The label of the button the user will press to start downloading a file")
    public static let DownloadsButtonTitle = MZLocalizedString("Downloads.Toast.GoToDownloads.Button", value: "Downloads", comment: "The button to open a new tab with the Downloads home panel")
    public static let CancelDownloadDialogTitle = MZLocalizedString("Downloads.CancelDialog.Title", value: "Cancel Download", comment: "Alert dialog title when the user taps the cancel download icon.")
    public static let CancelDownloadDialogMessage = MZLocalizedString("Downloads.CancelDialog.Message", value: "Are you sure you want to cancel this download?", comment: "Alert dialog body when the user taps the cancel download icon.")
    public static let CancelDownloadDialogResume = MZLocalizedString("Downloads.CancelDialog.Resume", value: "Resume", comment: "Button declining the cancellation of the download.")
    public static let CancelDownloadDialogCancel = MZLocalizedString("Downloads.CancelDialog.Cancel", value: "Cancel", comment: "Button confirming the cancellation of the download.")
    public static let DownloadCancelledToastLabelText = MZLocalizedString("Downloads.Toast.Cancelled.LabelText", value: "Download Cancelled", comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.")
    public static let DownloadFailedToastLabelText = MZLocalizedString("Downloads.Toast.Failed.LabelText", value: "Download Failed", comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.")
    public static let DownloadFailedToastButtonTitled = MZLocalizedString("Downloads.Toast.Failed.RetryButton", value: "Retry", comment: "The button to retry a failed download from the Download Failed toast.")
    public static let DownloadMultipleFilesToastDescriptionText = MZLocalizedString("Downloads.Toast.MultipleFiles.DescriptionText", value: "1 of %d files", comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.")
    public static let DownloadProgressToastDescriptionText = MZLocalizedString("Downloads.Toast.Progress.DescriptionText", value: "%1$@/%2$@", comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).")
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = MZLocalizedString("Downloads.Toast.MultipleFilesAndProgress.DescriptionText", value: "%1$@ %2$@", comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.")
}

// Add Custom Search Engine
extension Strings {
    public static let SettingsAddCustomEngine = MZLocalizedString("Settings.AddCustomEngine", value: "Add Search Engine", comment: "The button text in Search Settings that opens the Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitle = MZLocalizedString("Settings.AddCustomEngine.Title", value: "Add Search Engine", comment: "The title of the  Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitleLabel = MZLocalizedString("Settings.AddCustomEngine.TitleLabel", value: "Title", comment: "The title for the field which sets the title for a custom search engine.")
    public static let SettingsAddCustomEngineURLLabel = MZLocalizedString("Settings.AddCustomEngine.URLLabel", value: "URL", comment: "The title for URL Field")
    public static let SettingsAddCustomEngineTitlePlaceholder = MZLocalizedString("Settings.AddCustomEngine.TitlePlaceholder", value: "Search Engine", comment: "The placeholder for Title Field when saving a custom search engine.")
    public static let SettingsAddCustomEngineURLPlaceholder = MZLocalizedString("Settings.AddCustomEngine.URLPlaceholder", value: "URL (Replace Query with %s)", comment: "The placeholder for URL Field when saving a custom search engine")
    public static let SettingsAddCustomEngineSaveButtonText = MZLocalizedString("Settings.AddCustomEngine.SaveButtonText", value: "Save", comment: "The text on the Save button when saving a custom search engine")
}

// Context menu ButtonToast instances.
extension Strings {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = MZLocalizedString("ContextMenu.ButtonToast.NewTabOpened.LabelText", value: "New Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewTabOpenedButtonText = MZLocalizedString("ContextMenu.ButtonToast.NewTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedLabelText = MZLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.LabelText", value: "New Private Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Private Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedButtonText = MZLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Private Tab.")
}

// Page context menu items (i.e. links and images).
extension Strings {
    public static let ContextMenuOpenInNewTab = MZLocalizedString("ContextMenu.OpenInNewTabButtonTitle", value: "Open in New Tab", comment: "Context menu item for opening a link in a new tab")
    public static let ContextMenuOpenInNewPrivateTab = MZLocalizedString("ContextMenu.OpenInNewPrivateTabButtonTitle", tableName: "PrivateBrowsing", value: "Open in New Private Tab", comment: "Context menu option for opening a link in a new private tab")

    public static let ContextMenuOpenLinkInNewTab = MZLocalizedString("ContextMenu.OpenLinkInNewTabButtonTitle", value: "Open Link in New Tab", comment: "Context menu item for opening a link in a new tab")
    public static let ContextMenuOpenLinkInNewPrivateTab = MZLocalizedString("ContextMenu.OpenLinkInNewPrivateTabButtonTitle", value: "Open Link in New Private Tab", comment: "Context menu item for opening a link in a new private tab")

    public static let ContextMenuBookmarkLink = MZLocalizedString("ContextMenu.BookmarkLinkButtonTitle", value: "Bookmark Link", comment: "Context menu item for bookmarking a link URL")
    public static let ContextMenuDownloadLink = MZLocalizedString("ContextMenu.DownloadLinkButtonTitle", value: "Download Link", comment: "Context menu item for downloading a link URL")
    public static let ContextMenuCopyLink = MZLocalizedString("ContextMenu.CopyLinkButtonTitle", value: "Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
    public static let ContextMenuShareLink = MZLocalizedString("ContextMenu.ShareLinkButtonTitle", value: "Share Link", comment: "Context menu item for sharing a link URL")
    public static let ContextMenuSaveImage = MZLocalizedString("ContextMenu.SaveImageButtonTitle", value: "Save Image", comment: "Context menu item for saving an image")
    public static let ContextMenuCopyImage = MZLocalizedString("ContextMenu.CopyImageButtonTitle", value: "Copy Image", comment: "Context menu item for copying an image to the clipboard")
    public static let ContextMenuCopyImageLink = MZLocalizedString("ContextMenu.CopyImageLinkButtonTitle", value: "Copy Image Link", comment: "Context menu item for copying an image URL to the clipboard")
}

// Photo Library access.
extension Strings {
    public static let PhotoLibraryFirefoxWouldLikeAccessTitle = MZLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessTitle", value: "Firefox would like to access your Photos", comment: "See http://mzl.la/1G7uHo7")
    public static let PhotoLibraryFirefoxWouldLikeAccessMessage = MZLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessMessage", value: "This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7")
}

// Sent tabs notifications. These are displayed when the app is backgrounded or the device is locked.
extension Strings {
    // zero tabs
    public static let SentTab_NoTabArrivingNotification_title = MZLocalizedString("SentTab.NoTabArrivingNotification.title", value: "Firefox Sync", comment: "Title of notification received after a spurious message from FxA has been received.")
    public static let SentTab_NoTabArrivingNotification_body =
        MZLocalizedString("SentTab.NoTabArrivingNotification.body", value: "Tap to begin", comment: "Body of notification received after a spurious message from FxA has been received.")

    // one or more tabs
    public static let SentTab_TabArrivingNotification_NoDevice_title = MZLocalizedString("SentTab_TabArrivingNotification_NoDevice_title", value: "Tab received", comment: "Title of notification shown when the device is sent one or more tabs from an unnamed device.")
    public static let SentTab_TabArrivingNotification_NoDevice_body = MZLocalizedString("SentTab_TabArrivingNotification_NoDevice_body", value: "New tab arrived from another device.", comment: "Body of notification shown when the device is sent one or more tabs from an unnamed device.")
    public static let SentTab_TabArrivingNotification_WithDevice_title = MZLocalizedString("SentTab_TabArrivingNotification_WithDevice_title", value: "Tab received from %@", comment: "Title of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the device name. This device name will be localized by that device.")
    public static let SentTab_TabArrivingNotification_WithDevice_body = MZLocalizedString("SentTab_TabArrivingNotification_WithDevice_body", value: "New tab arrived in %@", comment: "Body of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the app name.")

    // Notification Actions
    public static let SentTabViewActionTitle = MZLocalizedString("SentTab.ViewAction.title", value: "View", comment: "Label for an action used to view one or more tabs from a notification.")
    public static let SentTabBookmarkActionTitle = MZLocalizedString("SentTab.BookmarkAction.title", value: "Bookmark", comment: "Label for an action used to bookmark one or more tabs from a notification.")
    public static let SentTabAddToReadingListActionTitle = MZLocalizedString("SentTab.AddToReadingListAction.Title", value: "Add to Reading List", comment: "Label for an action used to add one or more tabs recieved from a notification to the reading list.")
}

// Additional messages sent via Push from FxA
extension Strings {
    public static let FxAPush_DeviceDisconnected_ThisDevice_title = MZLocalizedString("FxAPush_DeviceDisconnected_ThisDevice_title", value: "Sync Disconnected", comment: "Title of a notification displayed when this device has been disconnected by another device.")
    public static let FxAPush_DeviceDisconnected_ThisDevice_body = MZLocalizedString("FxAPush_DeviceDisconnected_ThisDevice_body", value: "This device has been successfully disconnected from Firefox Sync.", comment: "Body of a notification displayed when this device has been disconnected from FxA by another device.")
    public static let FxAPush_DeviceDisconnected_title = MZLocalizedString("FxAPush_DeviceDisconnected_title", value: "Sync Disconnected", comment: "Title of a notification displayed when named device has been disconnected from FxA.")
    public static let FxAPush_DeviceDisconnected_body = MZLocalizedString("FxAPush_DeviceDisconnected_body", value: "%@ has been successfully disconnected.", comment: "Body of a notification displayed when named device has been disconnected from FxA. %@ refers to the name of the disconnected device.")

    public static let FxAPush_DeviceDisconnected_UnknownDevice_body = MZLocalizedString("FxAPush_DeviceDisconnected_UnknownDevice_body", value: "A device has disconnected from Firefox Sync", comment: "Body of a notification displayed when unnamed device has been disconnected from FxA.")

    public static let FxAPush_DeviceConnected_title = MZLocalizedString("FxAPush_DeviceConnected_title", value: "Sync Connected", comment: "Title of a notification displayed when another device has connected to FxA.")
    public static let FxAPush_DeviceConnected_body = MZLocalizedString("FxAPush_DeviceConnected_body", value: "Firefox Sync has connected to %@", comment: "Title of a notification displayed when another device has connected to FxA. %@ refers to the name of the newly connected device.")
}

// Reader Mode.
extension Strings {
    public static let ReaderModeAvailableVoiceOverAnnouncement = MZLocalizedString("ReaderMode.Available.VoiceOverAnnouncement", value: "Reader Mode available", comment: "Accessibility message e.g. spoken by VoiceOver when Reader Mode becomes available.")
    public static let ReaderModeResetFontSizeAccessibilityLabel = MZLocalizedString("Reset text size", comment: "Accessibility label for button resetting font size in display settings of reader mode")
}

// QR Code scanner.
extension Strings {
    public static let ScanQRCodeViewTitle = MZLocalizedString("ScanQRCode.View.Title", value: "Scan QR Code", comment: "Title for the QR code scanner view.")
    public static let ScanQRCodeInstructionsLabel = MZLocalizedString("ScanQRCode.Instructions.Label", value: "Align QR code within frame to scan", comment: "Text for the instructions label, displayed in the QR scanner view")
    public static let ScanQRCodeInvalidDataErrorMessage = MZLocalizedString("ScanQRCode.InvalidDataError.Message", value: "The data is invalid", comment: "Text of the prompt that is shown to the user when the data is invalid")
    public static let ScanQRCodePermissionErrorMessage = MZLocalizedString("ScanQRCode.PermissionError.Message", value: "Please allow Firefox to access your device’s camera in ‘Settings’ -> ‘Privacy’ -> ‘Camera’.", comment: "Text of the prompt user to setup the camera authorization.")
    public static let ScanQRCodeErrorOKButton = MZLocalizedString("ScanQRCode.Error.OK.Button", value: "OK", comment: "OK button to dismiss the error prompt.")
}

// App menu.
extension Strings {
    public static let AppMenuReportSiteIssueTitleString = NSLocalizedString("Menu.ReportSiteIssueAction.Title", tableName: "Menu", value: "Report Site Issue", comment: "Label for the button, displayed in the menu, used to report a compatibility issue with the current page.")
    public static let AppMenuLibraryReloadString = MZLocalizedString("Menu.Library.Reload", tableName: "Menu", value: "Reload", comment: "Label for the button, displayed in the menu, used to Reload the webpage")
    public static let StopReloadPageTitle = MZLocalizedString("Menu.Library.StopReload", value: "Stop", comment: "Label for the button displayed in the menu used to stop the reload of the webpage")
    public static let AppMenuLibraryTitleString = MZLocalizedString("Menu.Library.Title", tableName: "Menu", value: "Your Library", comment: "Label for the button, displayed in the menu, used to open the Library")
    public static let AppMenuAddToReadingListTitleString = MZLocalizedString("Menu.AddToReadingList.Title", tableName: "Menu", value: "Add to Reading List", comment: "Label for the button, displayed in the menu, used to add a page to the reading list.")
    public static let AppMenuShowTabsTitleString = MZLocalizedString("Menu.ShowTabs.Title", tableName: "Menu", value: "Show Tabs", comment: "Label for the button, displayed in the menu, used to open the tabs tray")
    public static let AppMenuSharePageTitleString = MZLocalizedString("Menu.SharePageAction.Title", tableName: "Menu", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    public static let AppMenuCopyURLTitleString = MZLocalizedString("Menu.CopyAddress.Title", tableName: "Menu", value: "Copy Address", comment: "Label for the button, displayed in the menu, used to copy the page url to the clipboard.")
    public static let AppMenuCopyLinkTitleString = MZLocalizedString("Menu.CopyLink.Title", tableName: "Menu", value: "Copy Link", comment: "Label for the button, displayed in the menu, used to copy the current page link to the clipboard.")
    public static let AppMenuNewTabTitleString = MZLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    public static let AppMenuNewPrivateTabTitleString = MZLocalizedString("Menu.NewPrivateTabAction.Title", tableName: "Menu", value: "Open New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.")
    public static let AppMenuAddBookmarkTitleString = MZLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuAddBookmarkTitleString2 = MZLocalizedString("Menu.AddBookmarkAction2.Title", tableName: "Menu", value: "Add Bookmark", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuRemoveBookmarkTitleString = MZLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    public static let AppMenuFindInPageTitleString = MZLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    public static let AppMenuViewDesktopSiteTitleString = MZLocalizedString("Menu.ViewDekstopSiteAction.Title", tableName: "Menu", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    public static let AppMenuViewMobileSiteTitleString = MZLocalizedString("Menu.ViewMobileSiteAction.Title", tableName: "Menu", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    public static let AppMenuTranslatePageTitleString = MZLocalizedString("Menu.TranslatePageAction.Title", tableName: "Menu", value: "Translate Page", comment: "Label for the button, displayed in the menu, used to translate the current page.")
    public static let AppMenuScanQRCodeTitleString = MZLocalizedString("Menu.ScanQRCodeAction.Title", tableName: "Menu", value: "Scan QR Code", comment: "Label for the button, displayed in the menu, used to open the QR code scanner.")
    public static let AppMenuSettingsTitleString = MZLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    public static let AppMenuCloseAllTabsTitleString = MZLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    public static let AppMenuOpenHomePageTitleString = MZLocalizedString("Menu.OpenHomePageAction.Title", tableName: "Menu", value: "Home", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    public static let AppMenuTopSitesTitleString = MZLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    public static let AppMenuBookmarksTitleString = MZLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel.v2", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuReadingListTitleString = MZLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel.v2", tableName: "Menu", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuHistoryTitleString = MZLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel.v2", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuDownloadsTitleString = MZLocalizedString("Menu.OpenDownloadsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Downloads", comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuSyncedTabsTitleString = MZLocalizedString("Menu.OpenSyncedTabsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Synced Tabs", comment: "Accessibility label for the button, displayed in the menu, used to open the Synced Tabs home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuLibrarySeeAllTitleString = MZLocalizedString("Menu.SeeAllAction.Title", tableName: "Menu", value: "See All", comment: "Label for the button, displayed in Firefox Home, used to see all Library panels.")
    public static let AppMenuButtonAccessibilityLabel = MZLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
    public static let TabTrayDeleteMenuButtonAccessibilityLabel = MZLocalizedString("Toolbar.Menu.CloseAllTabs", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.")
    public static let AppMenuNightMode = MZLocalizedString("Menu.NightModeTurnOn.Label", value: "Enable Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.")
    public static let AppMenuTurnOnNightMode = MZLocalizedString("Menu.NightModeTurnOn.Label2", value: "Turn on Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.")
    public static let AppMenuTurnOffNightMode = MZLocalizedString("Menu.NightModeTurnOff.Label2", value: "Turn off Night Mode", comment: "Label for the button, displayed in the menu, turns off night mode.")
    public static let AppMenuNoImageMode = MZLocalizedString("Menu.NoImageModeBlockImages.Label", value: "Block Images", comment: "Label for the button, displayed in the menu, hides images on the webpage when pressed.")
    public static let AppMenuShowImageMode = MZLocalizedString("Menu.NoImageModeShowImages.Label", value: "Show Images", comment: "Label for the button, displayed in the menu, shows images on the webpage when pressed.")
    public static let AppMenuBookmarks = MZLocalizedString("Menu.Bookmarks.Label", value: "Bookmarks", comment: "Label for the button, displayed in the menu, takes you to to bookmarks screen when pressed.")
    public static let AppMenuHistory = MZLocalizedString("Menu.History.Label", value: "History", comment: "Label for the button, displayed in the menu, takes you to to History screen when pressed.")
    public static let AppMenuDownloads = MZLocalizedString("Menu.Downloads.Label", value: "Downloads", comment: "Label for the button, displayed in the menu, takes you to to Downloads screen when pressed.")
    public static let AppMenuReadingList = MZLocalizedString("Menu.ReadingList.Label", value: "Reading List", comment: "Label for the button, displayed in the menu, takes you to to Reading List screen when pressed.")
    public static let AppMenuPasswords = MZLocalizedString("Menu.Passwords.Label", value: "Passwords", comment: "Label for the button, displayed in the menu, takes you to to passwords screen when pressed.")
    public static let AppMenuBackUpAndSyncData = MZLocalizedString("Menu.BackUpAndSync.Label", value: "Back up and Sync Data", comment: "Label for the button, displayed in the menu, takes you to sync sign in when pressed.")
    public static let AppMenuManageAccount = MZLocalizedString("Menu.ManageAccount.Label", value: "Manage Account %@", comment: "Label for the button, displayed in the menu, takes you to screen to manage account when pressed. First argument is the display name for the current account")
    public static let AppMenuCopyURLConfirmMessage = MZLocalizedString("Menu.CopyURL.Confirm", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.")
    
    public static let AppMenuAddBookmarkConfirmMessage = MZLocalizedString("Menu.AddBookmark.Confirm", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.")
    public static let AppMenuTabSentConfirmMessage = MZLocalizedString("Menu.TabSent.Confirm", value: "Tab Sent", comment: "Toast displayed to the user after a tab has been sent successfully.")
    public static let AppMenuRemoveBookmarkConfirmMessage = MZLocalizedString("Menu.RemoveBookmark.Confirm", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.")
    public static let AppMenuAddPinToTopSitesConfirmMessage = MZLocalizedString("Menu.AddPin.Confirm", value: "Pinned To Top Sites", comment: "Toast displayed to the user after adding the item to the Top Sites.")
    public static let AppMenuAddPinToShortcutsConfirmMessage = MZLocalizedString("Menu.AddPin.Confirm2", value: "Added to Shortcuts", comment: "Toast displayed to the user after adding the item to the Shortcuts.")
    public static let AppMenuRemovePinFromShortcutsConfirmMessage = MZLocalizedString("Menu.RemovePin.Confirm2", value: "Removed from Shortcuts", comment: "Toast displayed to the user after removing the item to the Shortcuts.")
    public static let AppMenuRemovePinFromTopSitesConfirmMessage = MZLocalizedString("Menu.RemovePin.Confirm", value: "Removed From Top Sites", comment: "Toast displayed to the user after removing the item from the Top Sites.")
    public static let AppMenuAddToReadingListConfirmMessage = MZLocalizedString("Menu.AddToReadingList.Confirm", value: "Added To Reading List", comment: "Toast displayed to the user after adding the item to their reading list.")
    public static let SendToDeviceTitle = MZLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device")
    public static let SendLinkToDeviceTitle = MZLocalizedString("Menu.SendLinkToDevice", tableName: "3DTouchActions", value: "Send Link to Device", comment: "Label for preview action on Tab Tray Tab to send the current link to another device")
    public static let PageActionMenuTitle = MZLocalizedString("Menu.PageActions.Title", value: "Page Actions", comment: "Label for title in page action menu.")
    public static let WhatsNewString = MZLocalizedString("Menu.WhatsNew.Title", value: "What's New", comment: "The title for the option to view the What's new page.")
    public static let AppMenuShowPageSourceString = MZLocalizedString("Menu.PageSourceAction.Title", tableName: "Menu", value: "View Page Source", comment: "Label for the button, displayed in the menu, used to show the html page source")
}

// Snackbar shown when tapping app store link
extension Strings {
    public static let ExternalLinkAppStoreConfirmationTitle = MZLocalizedString("ExternalLink.AppStore.ConfirmationTitle", value: "Open this link in the App Store?", comment: "Question shown to user when tapping a link that opens the App Store app")
    public static let ExternalLinkGenericConfirmation = MZLocalizedString("ExternalLink.AppStore.GenericConfirmationTitle", value: "Open this link in external app?", comment: "Question shown to user when tapping an SMS or MailTo link that opens the external app for those.")
}

// ContentBlocker/TrackingProtection strings
extension Strings {
    public static let SettingsTrackingProtectionSectionName = MZLocalizedString("Settings.TrackingProtection.SectionName", value: "Tracking Protection", comment: "Row in top-level of settings that gets tapped to show the tracking protection settings detail view.")

    public static let TrackingProtectionEnableTitle = MZLocalizedString("Settings.TrackingProtectionOption.NormalBrowsingLabelOn", value: "Enhanced Tracking Protection", comment: "Settings option to specify that Tracking Protection is on")

    public static let TrackingProtectionOptionOnOffFooter = MZLocalizedString("Settings.TrackingProtectionOption.EnabledStateFooterLabel", value: "Tracking is the collection of your browsing data across multiple websites.", comment: "Description label shown on tracking protection options screen.")
    public static let TrackingProtectionOptionProtectionLevelTitle = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelTitle", value: "Protection Level", comment: "Title for tracking protection options section where level can be selected.")
    public static let TrackingProtectionOptionBlockListsHeader = MZLocalizedString("Settings.TrackingProtection.BlockListsHeader", value: "You can choose which list Firefox will use to block Web elements that may track your browsing activity.", comment: "Header description for tracking protection options section where Basic/Strict block list can be selected")
    public static let TrackingProtectionOptionBlockListLevelStandard = MZLocalizedString("Settings.TrackingProtectionOption.BasicBlockList", value: "Standard (default)", comment: "Tracking protection settings option for using the basic blocklist.")
    public static let TrackingProtectionOptionBlockListLevelStrict = MZLocalizedString("Settings.TrackingProtectionOption.BlockListStrict", value: "Strict", comment: "Tracking protection settings option for using the strict blocklist.")
    public static let TrackingProtectionReloadWithout = MZLocalizedString("Menu.ReloadWithoutTrackingProtection.Title", value: "Reload Without Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website without Tracking Protection")
    public static let TrackingProtectionReloadWith = MZLocalizedString("Menu.ReloadWithTrackingProtection.Title", value: "Reload With Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website with Tracking Protection enabled")

    public static let TrackingProtectionProtectionStrictInfoFooter = MZLocalizedString("Settings.TrackingProtection.StrictLevelInfoFooter", value: "Blocking trackers could impact the functionality of some websites.", comment: "Additional information about the strict level setting")
    public static let TrackingProtectionCellFooter = MZLocalizedString("Settings.TrackingProtection.ProtectionCellFooter", value: "Reduces targeted ads and helps stop advertisers from tracking your browsing.", comment: "Additional information about your Enhanced Tracking Protection")
    public static let TrackingProtectionStandardLevelDescription = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelStandard.Description", value: "Allows some ad tracking so websites function properly.", comment: "Description for standard level tracker protection")
    public static let TrackingProtectionStrictLevelDescription = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelStrict.Description", value: "Blocks more trackers, ads, and popups. Pages load faster, but some functionality may not work.", comment: "Description for strict level tracker protection")
    public static let TrackingProtectionLevelFooter = MZLocalizedString("Settings.TrackingProtection.ProtectionLevel.Footer", value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.", comment: "Footer information for tracker protection level.")
    public static let TrackerProtectionLearnMore = MZLocalizedString("Settings.TrackingProtection.LearnMore", value: "Learn more", comment: "'Learn more' info link on the Tracking Protection settings screen.")
    public static let TrackerProtectionAlertTitle =  MZLocalizedString("Settings.TrackingProtection.Alert.Title", value: "Heads up!", comment: "Title for the tracker protection alert.")
    public static let TrackerProtectionAlertDescription =  MZLocalizedString("Settings.TrackingProtection.Alert.Description", value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.", comment: "Decription for the tracker protection alert.")
    public static let TrackerProtectionAlertButton =  MZLocalizedString("Settings.TrackingProtection.Alert.Button", value: "OK, Got It", comment: "Dismiss button for the tracker protection alert.")
}

// Tracking Protection menu
extension Strings {
    public static let TPBlockingDescription = MZLocalizedString("Menu.TrackingProtectionBlocking.Description", value: "Firefox is blocking parts of the page that may track your browsing.", comment: "Description of the Tracking protection menu when TP is blocking parts of the page")
    public static let TPNoBlockingDescription = MZLocalizedString("Menu.TrackingProtectionNoBlocking.Description", value: "No tracking elements detected on this page.", comment: "The description of the Tracking Protection menu item when no scripts are blocked but tracking protection is enabled.")
    public static let TPBlockingDisabledDescription = MZLocalizedString("Menu.TrackingProtectionBlockingDisabled.Description", value: "Block online trackers", comment: "The description of the Tracking Protection menu item when tracking is enabled")
    public static let TPBlockingMoreInfo = MZLocalizedString("Menu.TrackingProtectionMoreInfo.Description", value: "Learn more about how Tracking Protection blocks online trackers that collect your browsing data across multiple websites.", comment: "more info about what tracking protection is about")
    public static let EnableTPBlockingGlobally = MZLocalizedString("Menu.TrackingProtectionEnable.Title", value: "Enable Tracking Protection", comment: "A button to enable tracking protection inside the menu.")
    public static let TPBlockingSiteEnabled = MZLocalizedString("Menu.TrackingProtectionEnable1.Title", value: "Enabled for this site", comment: "A button to enable tracking protection inside the menu.")
    public static let TPEnabledConfirmed = MZLocalizedString("Menu.TrackingProtectionEnabled.Title", value: "Tracking Protection is now on for this site.", comment: "The confirmation toast once tracking protection has been enabled")
    public static let TPDisabledConfirmed = MZLocalizedString("Menu.TrackingProtectionDisabled.Title", value: "Tracking Protection is now off for this site.", comment: "The confirmation toast once tracking protection has been disabled")
    public static let TPBlockingSiteDisabled = MZLocalizedString("Menu.TrackingProtectionDisable1.Title", value: "Disabled for this site", comment: "The button that disabled TP for a site.")
    public static let ETPOn = MZLocalizedString("Menu.EnhancedTrackingProtectionOn.Title", value: "Enhanced Tracking Protection is ON for this site.", comment: "A switch to enable enhanced tracking protection inside the menu.")
    public static let ETPOff = MZLocalizedString("Menu.EnhancedTrackingProtectionOff.Title", value: "Enhanced Tracking Protection is OFF for this site.", comment: "A switch to disable enhanced tracking protection inside the menu.")
    public static let StrictETPWithITP = MZLocalizedString("Menu.EnhancedTrackingProtectionStrictWithITP.Title", value: "Firefox blocks cross-site trackers, social trackers, cryptominers, fingerprinters, and tracking content.", comment: "Description for having strict ETP protection with ITP offered in iOS14+")
    public static let StandardETPWithITP = MZLocalizedString("Menu.EnhancedTrackingProtectionStandardWithITP.Title", value: "Firefox blocks cross-site trackers, social trackers, cryptominers, and fingerprinters.", comment: "Description for having standard ETP protection with ITP offered in iOS14+")

    // TP Page menu title
    public static let TPPageMenuTitle = MZLocalizedString("Menu.TrackingProtection.TitlePrefix", value: "Protections for %@", comment: "Title on tracking protection menu showing the domain. eg. Protections for mozilla.org")
    public static let TPPageMenuNoTrackersBlocked = MZLocalizedString("Menu.TrackingProtection.NoTrackersBlockedTitle", value: "No trackers known to Firefox were detected on this page.", comment: "Message in menu when no trackers blocked.")
    public static let TPPageMenuBlockedTitle = MZLocalizedString("Menu.TrackingProtection.BlockedTitle", value: "Blocked", comment: "Title on tracking protection menu for blocked items.")

    // Category Titles
    public static let TPCryptominersBlocked = MZLocalizedString("Menu.TrackingProtectionCryptominersBlocked.Title", value: "Cryptominers", comment: "The title that shows the number of cryptomining scripts blocked")
    public static let TPFingerprintersBlocked = MZLocalizedString("Menu.TrackingProtectionFingerprintersBlocked.Title", value: "Fingerprinters", comment: "The title that shows the number of fingerprinting scripts blocked")
    public static let TPCrossSiteCookiesBlocked = MZLocalizedString("Menu.TrackingProtectionCrossSiteCookies.Title", value: "Cross-Site Tracking Cookies", comment: "The title that shows the number of cross-site cookies blocked")
    public static let TPCrossSiteBlocked = MZLocalizedString("Menu.TrackingProtectionCrossSiteTrackers.Title", value: "Cross-Site Trackers", comment: "The title that shows the number of cross-site URLs blocked")
    public static let TPSocialBlocked = MZLocalizedString("Menu.TrackingProtectionBlockedSocial.Title", value: "Social Trackers", comment: "The title that shows the number of social URLs blocked")
    public static let TPContentBlocked = MZLocalizedString("Menu.TrackingProtectionBlockedContent.Title", value: "Tracking content", comment: "The title that shows the number of content cookies blocked")

    // Shortcut on bottom of TP page menu to get to settings.
    public static let TPProtectionSettings = MZLocalizedString("Menu.TrackingProtection.ProtectionSettings.Title", value: "Protection Settings", comment: "The title for tracking protection settings")

    // Remove if unused -->
    public static let TPListTitle_CrossSiteCookies = MZLocalizedString("Menu.TrackingProtectionListTitle.CrossSiteCookies", value: "Blocked Cross-Site Tracking Cookies", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`")
    public static let TPListTitle_Social = MZLocalizedString("Menu.TrackingProtectionListTitle.Social", value: "Blocked Social Trackers", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`")
    public static let TPListTitle_Fingerprinters = MZLocalizedString("Menu.TrackingProtectionListTitle.Fingerprinters", value: "Blocked Fingerprinters", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`")
    public static let TPListTitle_Cryptominer = MZLocalizedString("Menu.TrackingProtectionListTitle.Cryptominers", value: "Blocked Cryptominers", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`")
    /// <--

    public static let TPSafeListOn = MZLocalizedString("Menu.TrackingProtectionOption.WhiteListOnDescription", value: "The site includes elements that may track your browsing. You have disabled protection.", comment: "label for the menu item to show when the website is whitelisted from blocking trackers.")
    public static let TPSafeListRemove = MZLocalizedString("Menu.TrackingProtectionWhitelistRemove.Title", value: "Enable for this site", comment: "label for the menu item that lets you remove a website from the tracking protection whitelist")

    // Settings info
    public static let TPAccessoryInfoTitleStrict = MZLocalizedString("Settings.TrackingProtection.Info.StrictTitle", value: "Offers stronger protection, but may cause some sites to break.", comment: "Explanation of strict mode.")
    public static let TPAccessoryInfoTitleBasic = MZLocalizedString("Settings.TrackingProtection.Info.BasicTitle", value: "Balanced for protection and performance.", comment: "Explanation of basic mode.")
    public static let TPAccessoryInfoBlocksTitle = MZLocalizedString("Settings.TrackingProtection.Info.BlocksTitle", value: "BLOCKS", comment: "The Title on info view which shows a list of all blocked websites")

    // Category descriptions
    public static let TPCategoryDescriptionSocial = MZLocalizedString("Menu.TrackingProtectionDescription.SocialNetworksNew", value: "Social networks place trackers on other websites to build a more complete and targeted profile of you. Blocking these trackers reduces how much social media companies can see what do you online.", comment: "Description of social network trackers.")
    public static let TPCategoryDescriptionCrossSite = MZLocalizedString("Menu.TrackingProtectionDescription.CrossSiteNew", value: "These cookies follow you from site to site to gather data about what you do online. They are set by third parties such as advertisers and analytics companies.", comment: "Description of cross-site trackers.")
    public static let TPCategoryDescriptionCryptominers = MZLocalizedString("Menu.TrackingProtectionDescription.CryptominersNew", value: "Cryptominers secretly use your system’s computing power to mine digital money. Cryptomining scripts drain your battery, slow down your computer, and can increase your energy bill.", comment: "Description of cryptominers.")
    public static let TPCategoryDescriptionFingerprinters = MZLocalizedString("Menu.TrackingProtectionDescription.Fingerprinters", value: "The settings on your browser and computer are unique. Fingerprinters collect a variety of these unique settings to create a profile of you, which can be used to track you as you browse.", comment: "Description of fingerprinters.")
    public static let TPCategoryDescriptionContentTrackers = MZLocalizedString("Menu.TrackingProtectionDescription.ContentTrackers", value: "Websites may load outside ads, videos, and other content that contains hidden trackers. Blocking this can make websites load faster, but some buttons, forms, and login fields, might not work.", comment: "Description of content trackers.")

    public static let TPMoreInfo = MZLocalizedString("Settings.TrackingProtection.MoreInfo", value: "More Info…", comment: "'More Info' link on the Tracking Protection settings screen.")
}

// Location bar long press menu
extension Strings {
    public static let PasteAndGoTitle = MZLocalizedString("Menu.PasteAndGo.Title", value: "Paste & Go", comment: "The title for the button that lets you paste and go to a URL")
    public static let PasteTitle = MZLocalizedString("Menu.Paste.Title", value: "Paste", comment: "The title for the button that lets you paste into the location bar")
    public static let CopyAddressTitle = MZLocalizedString("Menu.Copy.Title", value: "Copy Address", comment: "The title for the button that lets you copy the url from the location bar.")
}

// Settings Home
extension Strings {
    public static let SendUsageSettingTitle = MZLocalizedString("Settings.SendUsage.Title", value: "Send Usage Data", comment: "The title for the setting to send usage data.")
    public static let SendUsageSettingLink = MZLocalizedString("Settings.SendUsage.Link", value: "Learn More.", comment: "title for a link that explains how mozilla collects telemetry")
    public static let SendUsageSettingMessage = MZLocalizedString("Settings.SendUsage.Message", value: "Mozilla strives to only collect what we need to provide and improve Firefox for everyone.", comment: "A short description that explains why mozilla collects usage data.")
    public static let SettingsSiriSectionName = MZLocalizedString("Settings.Siri.SectionName", value: "Siri Shortcuts", comment: "The option that takes you to the siri shortcuts settings page")
    public static let SettingsSiriSectionDescription = MZLocalizedString("Settings.Siri.SectionDescription", value: "Use Siri shortcuts to quickly open Firefox via Siri", comment: "The description that describes what siri shortcuts are")
    public static let SettingsSiriOpenURL = MZLocalizedString("Settings.Siri.OpenTabShortcut", value: "Open New Tab", comment: "The description of the open new tab siri shortcut")
}

// Nimbus settings
extension Strings {
    public static let SettingsStudiesTitle = MZLocalizedString("Settings.Studies.Title", value: "Studies", comment: "Label used as an item in Settings. Tapping on this item takes you to the Studies panel")
    public static let SettingsStudiesSectionName = MZLocalizedString("Settings.Studies.SectionName", value: "Studies", comment: "Title displayed in header of the Studies panel")
    public static let SettingsStudiesActiveSectionTitle = MZLocalizedString("Settings.Studies.Active.SectionName", value: "Active", comment: "Section title for all studies that are currently active")
    public static let SettingsStudiesCompletedSectionTitle = MZLocalizedString("Settings.Studies.Completed.SectionName", value: "Completed", comment: "Section title for all studies that are completed")
    public static let SettingsStudiesRemoveButton = MZLocalizedString("Settings.Studies.Remove.Button", value: "Remove", comment: "Button title displayed next to each study allowing the user to opt-out of the study")

    public static let SettingsStudiesToggleTitle = MZLocalizedString("Settings.Studies.Toggle.Title", value: "Studies", comment: "Label used as a toggle item in Settings. When this is off, the user is opting out of all studies.")
    public static let SettingsStudiesToggleLink = MZLocalizedString("Settings.Studies.Toggle.Link", value: "Learn More.", comment: "Title for a link that explains what Mozilla means by Studies")
    public static let SettingsStudiesToggleMessage = MZLocalizedString("Settings.Studies.Toggle.Message", value: "Firefox may install and run studies from time to time.", comment: "A short description that explains that Mozilla is running studies")

    public static let SettingsStudiesToggleValueOn = MZLocalizedString("Settings.Studies.Toggle.On", value: "On", comment: "Toggled ON to participate in studies")
    public static let SettingsStudiesToggleValueOff = MZLocalizedString("Settings.Studies.Toggle.Off", value: "Off", comment: "Toggled OFF to opt-out of studies")
}

// Do not track
extension Strings {
    public static let SettingsDoNotTrackTitle = MZLocalizedString("Settings.DNT.Title", value: "Send websites a Do Not Track signal that you don’t want to be tracked", comment: "DNT Settings title")
    public static let SettingsDoNotTrackOptionOnWithTP = MZLocalizedString("Settings.DNT.OptionOnWithTP", value: "Only when using Tracking Protection", comment: "DNT Settings option for only turning on when Tracking Protection is also on")
    public static let SettingsDoNotTrackOptionAlwaysOn = MZLocalizedString("Settings.DNT.OptionAlwaysOn", value: "Always", comment: "DNT Settings option for always on")
}

// Intro Onboarding slides
extension Strings {
    // First Card
    public static let CardTitleWelcome = MZLocalizedString("Intro.Slides.Welcome.Title.v2", tableName: "Intro", value: "Welcome to Firefox", comment: "Title for the first panel 'Welcome' in the First Run tour.")
    public static let CardTitleAutomaticPrivacy = MZLocalizedString("Intro.Slides.Automatic.Privacy.Title", tableName: "Intro", value: "Automatic Privacy", comment: "Title for the first item in the table related to automatic privacy")
    public static let CardDescriptionAutomaticPrivacy = MZLocalizedString("Intro.Slides.Automatic.Privacy.Description", tableName: "Intro", value: "Enhanced Tracking Protection blocks malware and stops trackers.", comment: "Description for the first item in the table related to automatic privacy")
    public static let CardTitleFastSearch = MZLocalizedString("Intro.Slides.Fast.Search.Title", tableName: "Intro", value: "Fast Search", comment: "Title for the second item in the table related to fast searching via address bar")
    public static let CardDescriptionFastSearch = MZLocalizedString("Intro.Slides.Fast.Search.Description", tableName: "Intro", value: "Search suggestions get you to websites faster.", comment: "Description for the second item in the table related to fast searching via address bar")
    public static let CardTitleSafeSync = MZLocalizedString("Intro.Slides.Safe.Sync.Title", tableName: "Intro", value: "Safe Sync", comment: "Title for the third item in the table related to safe syncing with a firefox account")
    public static let CardDescriptionSafeSync = MZLocalizedString("Intro.Slides.Safe.Sync.Description", tableName: "Intro", value: "Protect your logins and data everywhere you use Firefox.", comment: "Description for the third item in the table related to safe syncing with a firefox account")
    
    // Second Card
    public static let CardTitleFxASyncDevices = MZLocalizedString("Intro.Slides.Firefox.Account.Sync.Title", tableName: "Intro", value: "Sync Firefox Between Devices", comment: "Title for the first item in the table related to syncing data (bookmarks, history) via firefox account between devices")
    public static let CardDescriptionFxASyncDevices = MZLocalizedString("Intro.Slides.Firefox.Account.Sync.Description", tableName: "Intro", value: "Bring bookmarks, history, and passwords to Firefox on this device.", comment: "Description for the first item in the table related to syncing data (bookmarks, history) via firefox account between devices")
    
    //----Other----//
    public static let CardTitleSearch = MZLocalizedString("Intro.Slides.Search.Title", tableName: "Intro", value: "Your search, your way", comment: "Title for the second  panel 'Search' in the First Run tour.")
    public static let CardTitlePrivate = MZLocalizedString("Intro.Slides.Private.Title", tableName: "Intro", value: "Browse like no one’s watching", comment: "Title for the third panel 'Private Browsing' in the First Run tour.")
    public static let CardTitleMail = MZLocalizedString("Intro.Slides.Mail.Title", tableName: "Intro", value: "You’ve got mail… options", comment: "Title for the fourth panel 'Mail' in the First Run tour.")
    public static let CardTitleSync = MZLocalizedString("Intro.Slides.TrailheadSync.Title.v2", tableName: "Intro", value: "Sync your bookmarks, history, and passwords to your phone.", comment: "Title for the second panel 'Sync' in the First Run tour.")

    public static let CardTextWelcome = MZLocalizedString("Intro.Slides.Welcome.Description.v2", tableName: "Intro", value: "Fast, private, and on your side.", comment: "Description for the 'Welcome' panel in the First Run tour.")
    public static let CardTextSearch = MZLocalizedString("Intro.Slides.Search.Description", tableName: "Intro", value: "Searching for something different? Choose another default search engine (or add your own) in Settings.", comment: "Description for the 'Favorite Search Engine' panel in the First Run tour.")
    public static let CardTextPrivate = MZLocalizedString("Intro.Slides.Private.Description", tableName: "Intro", value: "Tap the mask icon to slip into Private Browsing mode.", comment: "Description for the 'Private Browsing' panel in the First Run tour.")
    public static let CardTextMail = MZLocalizedString("Intro.Slides.Mail.Description", tableName: "Intro", value: "Use any email app — not just Mail — with Firefox.", comment: "Description for the 'Mail' panel in the First Run tour.")
    public static let CardTextSync = MZLocalizedString("Intro.Slides.TrailheadSync.Description", tableName: "Intro", value: "Sign in to your account to sync and access more features.", comment: "Description for the 'Sync' panel in the First Run tour.")
    public static let SignInButtonTitle = MZLocalizedString("Turn on Sync…", tableName: "Intro", comment: "The button that opens the sign in page for sync. See http://mzl.la/1T8gxwo")
    public static let StartBrowsingButtonTitle = MZLocalizedString("Start Browsing", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    public static let IntroNextButtonTitle = MZLocalizedString("Intro.Slides.Button.Next", tableName: "Intro", value: "Next", comment: "Next button on the first intro screen.")
    public static let IntroSignInButtonTitle = MZLocalizedString("Intro.Slides.Button.SignIn", tableName: "Intro", value: "Sign In", comment: "Sign in to Firefox account button on second intro screen.")
    public static let IntroSignUpButtonTitle = MZLocalizedString("Intro.Slides.Button.SignUp", tableName: "Intro", value: "Sign Up", comment: "Sign up to Firefox account button on second intro screen.")
}

// Keyboard short cuts
extension Strings {
    public static let ShowTabTrayFromTabKeyCodeTitle = MZLocalizedString("Tab.ShowTabTray.KeyCodeTitle", value: "Show All Tabs", comment: "Hardware shortcut to open the tab tray from a tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseTabFromTabTrayKeyCodeTitle = MZLocalizedString("TabTray.CloseTab.KeyCodeTitle", value: "Close Selected Tab", comment: "Hardware shortcut to close the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseAllTabsFromTabTrayKeyCodeTitle = MZLocalizedString("TabTray.CloseAllTabs.KeyCodeTitle", value: "Close All Tabs", comment: "Hardware shortcut to close all tabs from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenSelectedTabFromTabTrayKeyCodeTitle = MZLocalizedString("TabTray.OpenSelectedTab.KeyCodeTitle", value: "Open Selected Tab", comment: "Hardware shortcut open the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenNewTabFromTabTrayKeyCodeTitle = MZLocalizedString("TabTray.OpenNewTab.KeyCodeTitle", value: "Open New Tab", comment: "Hardware shortcut to open a new tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let ReopenClosedTabKeyCodeTitle = MZLocalizedString("ReopenClosedTab.KeyCodeTitle", value: "Reopen Closed Tab", comment: "Hardware shortcut to reopen the last closed tab, from the tab or the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToPBMKeyCodeTitle = MZLocalizedString("SwitchToPBM.KeyCodeTitle", value: "Private Browsing Mode", comment: "Hardware shortcut switch to the private browsing tab or tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToNonPBMKeyCodeTitle = MZLocalizedString("SwitchToNonPBM.KeyCodeTitle", value: "Normal Browsing Mode", comment: "Hardware shortcut for non-private tab or tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
}

// Share extension
extension Strings {
    public static let SendToCancelButton = MZLocalizedString("SendTo.Cancel.Button", value: "Cancel", comment: "Button title for cancelling share screen")
    public static let SendToErrorOKButton = MZLocalizedString("SendTo.Error.OK.Button", value: "OK", comment: "OK button to dismiss the error prompt.")
    public static let SendToErrorTitle = MZLocalizedString("SendTo.Error.Title", value: "The link you are trying to share cannot be shared.", comment: "Title of error prompt displayed when an invalid URL is shared.")
    public static let SendToErrorMessage = MZLocalizedString("SendTo.Error.Message", value: "Only HTTP and HTTPS links can be shared.", comment: "Message in error prompt explaining why the URL is invalid.")
    public static let SendToCloseButton = MZLocalizedString("SendTo.Cancel.Button", value: "Close", comment: "Close button in top navigation bar")
    public static let SendToNotSignedInText = MZLocalizedString("SendTo.NotSignedIn.Title", value: "You are not signed in to your Firefox Account.", comment: "See http://mzl.la/1ISlXnU")
    public static let SendToNotSignedInMessage = MZLocalizedString("SendTo.NotSignedIn.Message", value: "Please open Firefox, go to Settings and sign in to continue.", comment: "See http://mzl.la/1ISlXnU")
    public static let SendToSignInButton = MZLocalizedString("SendTo.SignIn.Button", value: "Sign In to Firefox", comment: "The text for the button on the Send to Device page if you are not signed in to Firefox Accounts.")
    public static let SendToNoDevicesFound = MZLocalizedString("SendTo.NoDevicesFound.Message", value: "You don’t have any other devices connected to this Firefox Account available to sync.", comment: "Error message shown in the remote tabs panel")
    public static let SendToTitle = MZLocalizedString("SendTo.NavBar.Title", value: "Send Tab", comment: "Title of the dialog that allows you to send a tab to a different device")
    public static let SendToSendButtonTitle = MZLocalizedString("SendTo.SendAction.Text", value: "Send", comment: "Navigation bar button to Send the current page to a device")
    public static let SendToDevicesListTitle = MZLocalizedString("SendTo.DeviceList.Text", value: "Available devices:", comment: "Header for the list of devices table")
    public static let ShareSendToDevice = Strings.SendToDeviceTitle

    // The above items are re-used strings from the old extension. New strings below.

    public static let ShareAddToReadingList = MZLocalizedString("ShareExtension.AddToReadingListAction.Title", value: "Add to Reading List", comment: "Action label on share extension to add page to the Firefox reading list.")
    public static let ShareAddToReadingListDone = MZLocalizedString("ShareExtension.AddToReadingListActionDone.Title", value: "Added to Reading List", comment: "Share extension label shown after user has performed 'Add to Reading List' action.")
    public static let ShareBookmarkThisPage = MZLocalizedString("ShareExtension.BookmarkThisPageAction.Title", value: "Bookmark This Page", comment: "Action label on share extension to bookmark the page in Firefox.")
    public static let ShareBookmarkThisPageDone = MZLocalizedString("ShareExtension.BookmarkThisPageActionDone.Title", value: "Bookmarked", comment: "Share extension label shown after user has performed 'Bookmark this Page' action.")

    public static let ShareOpenInFirefox = MZLocalizedString("ShareExtension.OpenInFirefoxAction.Title", value: "Open in Firefox", comment: "Action label on share extension to immediately open page in Firefox.")
    public static let ShareSearchInFirefox = MZLocalizedString("ShareExtension.SeachInFirefoxAction.Title", value: "Search in Firefox", comment: "Action label on share extension to search for the selected text in Firefox.")
    public static let ShareOpenInPrivateModeNow = MZLocalizedString("ShareExtension.OpenInPrivateModeAction.Title", value: "Open in Private Mode", comment: "Action label on share extension to immediately open page in Firefox in private mode.")

    public static let ShareLoadInBackground = MZLocalizedString("ShareExtension.LoadInBackgroundAction.Title", value: "Load in Background", comment: "Action label on share extension to load the page in Firefox when user switches apps to bring it to foreground.")
    public static let ShareLoadInBackgroundDone = MZLocalizedString("ShareExtension.LoadInBackgroundActionDone.Title", value: "Loading in Firefox", comment: "Share extension label shown after user has performed 'Load in Background' action.")

}

//passwordAutofill extension
extension Strings {
    public static let PasswordAutofillTitle = MZLocalizedString("PasswordAutoFill.SectionTitle", value: "Firefox Credentials", comment: "Title of the extension that shows firefox passwords")
    public static let CredentialProviderNoCredentialError = MZLocalizedString("PasswordAutoFill.NoPasswordsFoundTitle", value: "You don’t have any credentials synced from your Firefox Account", comment: "Error message shown in the remote tabs panel")
    public static let AvailableCredentialsHeader = MZLocalizedString("PasswordAutoFill.PasswordsListTitle", value: "Available Credentials:", comment: "Header for the list of credentials table")
}

// translation bar
extension Strings {
    public static let TranslateSnackBarPrompt = MZLocalizedString("TranslationToastHandler.PromptTranslate.Title", value: "This page appears to be in %1$@. Translate to %2$@ with %3$@?", comment: "Prompt for translation. The first parameter is the language the page is in. The second parameter is the name of our local language. The third is the name of the service.")
    public static let TranslateSnackBarYes = MZLocalizedString("TranslationToastHandler.PromptTranslate.OK", value: "Yes", comment: "Button to allow the page to be translated to the user locale language")
    public static let TranslateSnackBarNo = MZLocalizedString("TranslationToastHandler.PromptTranslate.Cancel", value: "No", comment: "Button to disallow the page to be translated to the user locale language")

    public static let SettingTranslateSnackBarSectionHeader = MZLocalizedString("Settings.TranslateSnackBar.SectionHeader", value: "Services", comment: "Translation settings section title")
    public static let SettingTranslateSnackBarSectionFooter = MZLocalizedString("Settings.TranslateSnackBar.SectionFooter", value: "The web page language is detected on the device, and a translation from a remote service is offered.", comment: "Translation settings footer describing how language detection and translation happens.")
    public static let SettingTranslateSnackBarTitle = MZLocalizedString("Settings.TranslateSnackBar.Title", value: "Translation", comment: "Title in main app settings for Translation toast settings")
    public static let SettingTranslateSnackBarSwitchTitle = MZLocalizedString("Settings.TranslateSnackBar.SwitchTitle", value: "Offer Translation", comment: "Switch to choose if the language of a page is detected and offer to translate.")
    public static let SettingTranslateSnackBarSwitchSubtitle = MZLocalizedString("Settings.TranslateSnackBar.SwitchSubtitle", value: "Offer to translate any site written in a language that is different from your default language.", comment: "Switch to choose if the language of a page is detected and offer to translate.")
}

// Display Theme
extension Strings {
    public static let SettingsDisplayThemeTitle = MZLocalizedString("Settings.DisplayTheme.Title.v2", value: "Theme", comment: "Title in main app settings for Theme settings")
    public static let DisplayThemeBrightnessThresholdSectionHeader = MZLocalizedString("Settings.DisplayTheme.BrightnessThreshold.SectionHeader", value: "Threshold", comment: "Section header for brightness slider.")
    public static let DisplayThemeSectionFooter = MZLocalizedString("Settings.DisplayTheme.SectionFooter", value: "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes. The circle indicates your display's current brightness.", comment: "Display (theme) settings footer describing how the brightness slider works.")
    public static let SystemThemeSectionHeader = MZLocalizedString("Settings.DisplayTheme.SystemTheme.SectionHeader", value: "System Theme", comment: "System theme settings section title")
    public static let SystemThemeSectionSwitchTitle = MZLocalizedString("Settings.DisplayTheme.SystemTheme.SwitchTitle", value: "Use System Light/Dark Mode", comment: "System theme settings switch to choose whether to use the same theme as the system")
    public static let ThemeSwitchModeSectionHeader = MZLocalizedString("Settings.DisplayTheme.SwitchMode.SectionHeader", value: "Switch Mode", comment: "Switch mode settings section title")
    public static let ThemePickerSectionHeader = MZLocalizedString("Settings.DisplayTheme.ThemePicker.SectionHeader", value: "Theme Picker", comment: "Theme picker settings section title")
    public static let DisplayThemeAutomaticSwitchTitle = MZLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatically", comment: "Display (theme) settings switch to choose whether to set the dark mode manually, or automatically based on the brightness slider.")
    public static let DisplayThemeAutomaticStatusLabel = MZLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatic", comment: "Display (theme) settings label to show if automatically switch theme is enabled.")
    public static let DisplayThemeAutomaticSwitchSubtitle = MZLocalizedString("Settings.DisplayTheme.SwitchSubtitle", value: "Switch automatically based on screen brightness", comment: "Display (theme) settings switch subtitle, explaining the title 'Automatically'.")
    public static let DisplayThemeManualSwitchTitle = MZLocalizedString("Settings.DisplayTheme.Manual.SwitchTitle", value: "Manually", comment: "Display (theme) setting to choose the theme manually.")
    public static let DisplayThemeManualSwitchSubtitle = MZLocalizedString("Settings.DisplayTheme.Manual.SwitchSubtitle", value: "Pick which theme you want", comment: "Display (theme) settings switch subtitle, explaining the title 'Manually'.")
    public static let DisplayThemeManualStatusLabel = MZLocalizedString("Settings.DisplayTheme.Manual.StatusLabel", value: "Manual", comment: "Display (theme) settings label to show if manually switch theme is enabled.")
    public static let DisplayThemeOptionLight = MZLocalizedString("Settings.DisplayTheme.OptionLight", value: "Light", comment: "Option choice in display theme settings for light theme")
    public static let DisplayThemeOptionDark = MZLocalizedString("Settings.DisplayTheme.OptionDark", value: "Dark", comment: "Option choice in display theme settings for dark theme")
}

extension Strings {
    public static let AddTabAccessibilityLabel = MZLocalizedString("TabTray.AddTab.Button", value: "Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
}

// Cover Sheet
extension Strings {
    // Dark Mode Cover Sheet
    public static let CoverSheetV22DarkModeTitle = MZLocalizedString("CoverSheet.v22.DarkMode.Title", value: "Dark theme now includes a dark keyboard and dark splash screen.", comment: "Title for the new dark mode change in the version 22 app release.")
    public static let CoverSheetV22DarkModeDescription = MZLocalizedString("CoverSheet.v22.DarkMode.Description", value: "For iOS 13 users, Firefox now automatically switches to a dark theme when your phone is set to Dark Mode. To change this behavior, go to Settings > Theme.", comment: "Description for the new dark mode change in the version 22 app release. It describes the new automatic dark theme and how to change the theme settings.")
    
    // ETP Cover Sheet
    public static let CoverSheetETPTitle = MZLocalizedString("CoverSheet.v24.ETP.Title", value: "Protection Against Ad Tracking", comment: "Title for the new ETP mode i.e. standard vs strict")
    public static let CoverSheetETPDescription = MZLocalizedString("CoverSheet.v24.ETP.Description", value: "Built-in Enhanced Tracking Protection helps stop ads from following you around. Turn on Strict to block even more trackers, ads, and popups. ", comment: "Description for the new ETP mode i.e. standard vs strict")
    public static let CoverSheetETPSettingsButton = MZLocalizedString("CoverSheet.v24.ETP.Settings.Button", value: "Go to Settings", comment: "Text for the new ETP settings button")
}

// FxA Signin screen
extension Strings {
    public static let FxASignin_Title = MZLocalizedString("fxa.signin.turn-on-sync", value: "Turn on Sync", comment: "FxA sign in view title")
    public static let FxASignin_Subtitle = MZLocalizedString("fxa.signin.camera-signin", value: "Sign In with Your Camera", comment: "FxA sign in view subtitle")
    public static let FxASignin_QRInstructions = MZLocalizedString("fxa.signin.qr-link-instruction", value: "On your computer open Firefox and go to firefox.com/pair", comment: "FxA sign in view qr code instructions")
    public static let FxASignin_QRScanSignin = MZLocalizedString("fxa.signin.ready-to-scan", value: "Ready to Scan", comment: "FxA sign in view qr code scan button")
    public static let FxASignin_EmailSignin = MZLocalizedString("fxa.signin.use-email-instead", value: "Use Email Instead", comment: "FxA sign in view email login button")
    public static let FxASignin_CreateAccountPt1 = MZLocalizedString("fxa.signin.create-account-pt-1", value: "Sync Firefox between devices with an account.", comment: "FxA sign in create account label.")
    public static let FxASignin_CreateAccountPt2 = MZLocalizedString("fxa.signin.create-account-pt-2", value: "Create Firefox account.", comment: "FxA sign in create account label. This will be linked to the site to create an account.")
}

// FxA QR code scanning screen
extension String {
    public static let FxAQRCode_Instructions = MZLocalizedString("fxa.qr-scanning-view.instructions", value: "Scan the QR code shown at firefox.com/pair", comment: "Instructions shown on qr code scanning view")
}

//Today Widget Strings - [New Search - Private Search]
extension String {
    public static let NewTabButtonLabel = MZLocalizedString("TodayWidget.NewTabButtonLabelV1", tableName: "Today", value: "New Search", comment: "Open New Tab button label")
    public static let CopiedLinkLabelFromPasteBoard = MZLocalizedString("TodayWidget.CopiedLinkLabelFromPasteBoardV1", tableName: "Today", value: "Copied Link from clipboard", comment: "Copied Link from clipboard displayed")
    public static let NewPrivateTabButtonLabel = MZLocalizedString("TodayWidget.PrivateTabButtonLabelV1", tableName: "Today", value: "Private Search", comment: "Open New Private Tab button label")
    
    // Widget - Shared

    public static let QuickActionsGalleryTitle = MZLocalizedString("TodayWidget.QuickActionsGalleryTitle", tableName: "Today", value: "Quick Actions", comment: "Quick Actions title when widget enters edit mode")
    public static let QuickActionsGalleryTitlev2 = MZLocalizedString("TodayWidget.QuickActionsGalleryTitleV2", tableName: "Today", value: "Firefox Shortcuts", comment: "Firefox shortcuts title when widget enters edit mode. Do not translate the word Firefox.")
    
    // Quick View - Gallery View
    public static let QuickViewGalleryTile = MZLocalizedString("TodayWidget.QuickViewGalleryTitle", tableName: "Today", value: "Quick View", comment: "Quick View title user is picking a widget to add.")
    
    // Quick Action - Medium Size Quick Action
    public static let QuickActionsSubLabel = MZLocalizedString("TodayWidget.QuickActionsSubLabel", tableName: "Today", value: "Firefox - Quick Actions", comment: "Sub label for medium size quick action widget")
    public static let NewSearchButtonLabel = MZLocalizedString("TodayWidget.NewSearchButtonLabelV1", tableName: "Today", value: "Search in Firefox", comment: "Open New Tab button label")
    public static let NewPrivateTabButtonLabelV2 = MZLocalizedString("TodayWidget.NewPrivateTabButtonLabelV2", tableName: "Today", value: "Search in Private Tab", comment: "Open New Private Tab button label for medium size action")
    public static let GoToCopiedLinkLabel = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV1", tableName: "Today", value: "Go to copied link", comment: "Go to link pasted on the clipboard")
    public static let GoToCopiedLinkLabelV2 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV2", tableName: "Today", value: "Go to\nCopied Link", comment: "Go to copied link")
    public static let GoToCopiedLinkLabelV3 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV3", tableName: "Today", value: "Go to Copied Link", comment: "Go To Copied Link text pasted on the clipboard but this string doesn't have new line character")
    public static let ClosePrivateTab = MZLocalizedString("TodayWidget.ClosePrivateTabsButton", tableName: "Today", value: "Close Private Tabs", comment: "Close Private Tabs button label")
    
    // Quick Action - Medium Size - Gallery View
    public static let FirefoxShortcutGalleryDescription = MZLocalizedString("TodayWidget.FirefoxShortcutGalleryDescription", tableName: "Today", value: "Add Firefox shortcuts to your Home screen.", comment: "Description for medium size widget to add Firefox Shortcut to home screen")
    
    // Quick Action - Small Size Widget
    public static let SearchInFirefoxTitle = MZLocalizedString("TodayWidget.SearchInFirefoxTitle", tableName: "Today", value: "Search in Firefox", comment: "Title for small size widget which allows users to search in Firefox. Do not translate the word Firefox.")
    public static let SearchInPrivateTabLabelV2 = MZLocalizedString("TodayWidget.SearchInPrivateTabLabelV2", tableName: "Today", value: "Search in\nPrivate Tab", comment: "Search in private tab")
    public static let SearchInFirefoxV2 = MZLocalizedString("TodayWidget.SearchInFirefoxV2", tableName: "Today", value: "Search in\nFirefox", comment: "Search in Firefox. Do not translate the word Firefox")
    public static let ClosePrivateTabsLabelV2 = MZLocalizedString("TodayWidget.ClosePrivateTabsLabelV2", tableName: "Today", value: "Close\nPrivate Tabs", comment: "Close Private Tabs")
    public static let ClosePrivateTabsLabelV3 = MZLocalizedString("TodayWidget.ClosePrivateTabsLabelV3", tableName: "Today", value: "Close\nPrivate\nTabs", comment: "Close Private Tabs")
    public static let GoToCopiedLinkLabelV4 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV4", tableName: "Today", value: "Go to\nCopied\nLink", comment: "Go to copied link")
    
    // Quick Action - Small Size Widget - Edit Mode
    public static let QuickActionDescription = MZLocalizedString("TodayWidget.QuickActionDescription", tableName: "Today", value: "Select a Firefox shortcut to add to your Home screen.", comment: "Quick action description when widget enters edit mode")
    public static let QuickActionDropDownMenu = MZLocalizedString("TodayWidget.QuickActionDropDownMenu", tableName: "Today", value: "Quick action", comment: "Quick Actions left label text for dropdown menu when widget enters edit mode")
    public static let DropDownMenuItemNewSearch = MZLocalizedString("TodayWidget.DropDownMenuItemNewSearch", tableName: "Today", value: "New Search", comment: "Quick Actions drop down menu item for new search when widget enters edit mode and drop down menu expands")
    public static let DropDownMenuItemNewPrivateSearch = MZLocalizedString("TodayWidget.DropDownMenuItemNewPrivateSearch", tableName: "Today", value: "New Private Search", comment: "Quick Actions drop down menu item for new private search when widget enters edit mode and drop down menu expands")
    public static let DropDownMenuItemGoToCopiedLink = MZLocalizedString("TodayWidget.DropDownMenuItemGoToCopiedLink", tableName: "Today", value: "Go to Copied Link", comment: "Quick Actions drop down menu item for Go to Copied Link when widget enters edit mode and drop down menu expands")
    public static let DropDownMenuItemClearPrivateTabs = MZLocalizedString("TodayWidget.DropDownMenuItemClearPrivateTabs", tableName: "Today", value: "Clear Private Tabs", comment: "Quick Actions drop down menu item for lear Private Tabs when widget enters edit mode and drop down menu expands")
    
    // Quick Action - Small Size - Gallery View
    public static let QuickActionGalleryDescription = MZLocalizedString("TodayWidget.QuickActionGalleryDescription", tableName: "Today", value: "Add a Firefox shortcut to your Home screen. After adding the widget, touch and hold to edit it and select a different shortcut.", comment: "Description for small size widget to add it to home screen")
    
    // Top Sites - Medium Size Widget
    public static let TopSitesSubLabel = MZLocalizedString("TodayWidget.TopSitesSubLabel", tableName: "Today", value: "Firefox - Top Sites", comment: "Sub label for Top Sites widget")
    public static let TopSitesSubLabel2 = MZLocalizedString("TodayWidget.TopSitesSubLabel2", tableName: "Today", value: "Firefox - Website Shortcuts", comment: "Sub label for Shortcuts widget")
    
    // Top Sites - Medium Size - Gallery View
    public static let TopSitesGalleryTitle = MZLocalizedString("TodayWidget.TopSitesGalleryTitle", tableName: "Today", value: "Top Sites", comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen")
    public static let TopSitesGalleryDescription = MZLocalizedString("TodayWidget.TopSitesGalleryDescription", tableName: "Today", value: "Add shortcuts to frequently and recently visited sites.", comment: "Description for top sites widget to add Firefox top sites shotcuts to home screen")

    // Quick View Open Tabs - Medium Size Widget
    public static let QuickViewOpenTabsSubLabel = MZLocalizedString("TodayWidget.QuickViewOpenTabsSubLabel", tableName: "Today", value: "Firefox - Open Tabs", comment: "Sub label for Top Sites widget")
    public static let MoreTabsLabel = MZLocalizedString("TodayWidget.MoreTabsLabel", tableName: "Today", value: "+%d More…", comment: "%d represents number and it becomes something like +5 more where 5 is the number of open tabs in tab tray beyond what is displayed in the widget")
    public static let OpenFirefoxLabel = MZLocalizedString("TodayWidget.OpenFirefoxLabel", tableName: "Today", value: "Open Firefox", comment: "Open Firefox when there are no tabs opened in tab tray i.e. Empty State")
    public static let NoOpenTabsLabel = MZLocalizedString("TodayWidget.NoOpenTabsLabel", tableName: "Today", value: "No open tabs.", comment: "Label that is shown when there are no tabs opened in tab tray i.e. Empty State")
    public static let NoOpenTabsLabelV2 = MZLocalizedString("TodayWidget.NoOpenTabsLabelV2", tableName: "Today", value: "No Open Tabs", comment: "Label that is shown when there are no tabs opened in tab tray i.e. Empty State")
    
    
    // Quick View Open Tabs - Medium Size - Gallery View
    public static let QuickViewGalleryTitle = MZLocalizedString("TodayWidget.QuickViewGalleryTitle", tableName: "Today", value: "Quick View", comment: "Title for Quick View widget in Gallery View where user can add it to home screen")
    public static let QuickViewGalleryDescription = MZLocalizedString("TodayWidget.QuickViewGalleryDescription", tableName: "Today", value: "Access your open tabs directly on your homescreen.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen")
    public static let QuickViewGalleryDescriptionV2 = MZLocalizedString("TodayWidget.QuickViewGalleryDescriptionV2", tableName: "Today", value: "Add shortcuts to your open tabs.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen")
    public static let ViewMore = MZLocalizedString("TodayWidget.ViewMore", tableName: "Today", value: "View More", comment: "View More for Quick View widget in Gallery View where we don't know how many tabs might be opened")
    
    // Quick View Open Tabs - Large Size - Gallery View
    public static let QuickViewLargeGalleryDescription = MZLocalizedString("TodayWidget.QuickViewLargeGalleryDescription", tableName: "Today", value: "Add shortcuts to your open tabs.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen")

    // Pocket - Large - Medium Size Widget
    public static let PocketWidgetSubLabel = MZLocalizedString("TodayWidget.PocketWidgetSubLabel", tableName: "Today", value: "Firefox - Recommended by Pocket", comment: "Sub label for medium size Firefox Pocket stories widge widget. Pocket is the name of another app.")
    public static let ViewMoreDots = MZLocalizedString("TodayWidget.ViewMoreDots", tableName: "Today", value: "View More…", comment: "View More… for Firefox Pocket stories widget where we don't know how many articles are available.")

    // Pocket - Large - Medium Size - Gallery View
    public static let PocketWidgetGalleryTitle = MZLocalizedString("TodayWidget.PocketWidgetTitle", tableName: "Today", value: "Recommended by Pocket", comment: "Title for Firefox Pocket stories widget in Gallery View where user can add it to home screen. Pocket is the name of another app.")
    public static let PocketWidgetGalleryDescription = MZLocalizedString("TodayWidget.PocketWidgetGalleryDescription", tableName: "Today", value: "Discover fascinating and thought-provoking stories from across the web, curated by Pocket.", comment: "Description for Firefox Pocket stories widget in Gallery View where user can add it to home screen. Pocket is the name of another app.")
}

// Default Browser
extension String {
    public static let DefaultBrowserCardTitle = MZLocalizedString("DefaultBrowserCard.Title", tableName: "Default Browser", value: "Switch Your Default Browser", comment: "Title for small card shown that allows user to switch their default browser to Firefox.")
    public static let DefaultBrowserCardDescription = MZLocalizedString("DefaultBrowserCard.Description", tableName: "Default Browser", value: "Set links from websites, emails, and Messages to open automatically in Firefox.", comment: "Description for small card shown that allows user to switch their default browser to Firefox.")
    public static let DefaultBrowserCardButton = MZLocalizedString("DefaultBrowserCard.Button.v2", tableName: "Default Browser", value: "Learn How", comment: "Button string to learn how to set your default browser.")
    public static let DefaultBrowserMenuItem = MZLocalizedString("Settings.DefaultBrowserMenuItem", tableName: "Default Browser", value: "Set as Default Browser", comment: "Menu option for setting Firefox as default browser.")
    public static let DefaultBrowserOnboardingScreenshot = MZLocalizedString("DefaultBrowserOnboarding.Screenshot", tableName: "Default Browser", value: "Default Browser App", comment: "Text for the screenshot of the iOS system settings page for Firefox.")
    public static let DefaultBrowserOnboardingDescriptionStep1 = MZLocalizedString("DefaultBrowserOnboarding.Description1", tableName: "Default Browser", value: "1. Go to Settings", comment: "Description for default browser onboarding card.")
    public static let DefaultBrowserOnboardingDescriptionStep2 = MZLocalizedString("DefaultBrowserOnboarding.Description2", tableName: "Default Browser", value: "2. Tap Default Browser App", comment: "Description for default browser onboarding card.")
    public static let DefaultBrowserOnboardingDescriptionStep3 = MZLocalizedString("DefaultBrowserOnboarding.Description3", tableName: "Default Browser", value: "3. Select Firefox", comment: "Description for default browser onboarding card.")
    public static let DefaultBrowserOnboardingButton = MZLocalizedString("DefaultBrowserOnboarding.Button", tableName: "Default Browser", value: "Go to Settings", comment: "Button string to open settings that allows user to switch their default browser to Firefox.")
}

// FxAWebViewController
extension String {
    public static let FxAWebContentAccessibilityLabel = MZLocalizedString("Web content", comment: "Accessibility label for the main web content view")
}

// QuickActions
extension String {
    public static let QuickActionsLastBookmarkTitle = MZLocalizedString("Open Last Bookmark", tableName: "3DTouchActions", comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch")
}

// CrashOptInAlert
extension String {
    public static let CrashOptInAlertTitle = MZLocalizedString("Oops! Firefox crashed", comment: "Title for prompt displayed to user after the app crashes")
    public static let CrashOptInAlertMessage = MZLocalizedString("Send a crash report so Mozilla can fix the problem?", comment: "Message displayed in the crash dialog above the buttons used to select when sending reports")
    public static let CrashOptInAlertSend = MZLocalizedString("Send Report", comment: "Used as a button label for crash dialog prompt")
    public static let CrashOptInAlertAlwaysSend = MZLocalizedString("Always Send", comment: "Used as a button label for crash dialog prompt")
    public static let CrashOptInAlertDontSend = MZLocalizedString("Don’t Send", comment: "Used as a button label for crash dialog prompt")
}

// RestoreTabsAlert
extension String {
    public static let RestoreTabsAlertTitle = MZLocalizedString("Well, this is embarrassing.", comment: "Restore Tabs Prompt Title")
    public static let RestoreTabsAlertMessage = MZLocalizedString("Looks like Firefox crashed previously. Would you like to restore your tabs?", comment: "Restore Tabs Prompt Description")
    public static let RestoreTabsAlertNo = MZLocalizedString("No", comment: "Restore Tabs Negative Action")
    public static let RestoreTabsAlertOkay = MZLocalizedString("Okay", comment: "Restore Tabs Affirmative Action")
}

// ClearPrivateDataAlert
extension String {
    public static let ClearPrivateDataAlertMessage = MZLocalizedString("This action will clear all of your private data. It cannot be undone.", tableName: "ClearPrivateDataConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.")
    public static let ClearPrivateDataAlertCancel = MZLocalizedString("Cancel", tableName: "ClearPrivateDataConfirm", comment: "The cancel button when confirming clear private data.")
    public static let ClearPrivateDataAlertOk = MZLocalizedString("OK", tableName: "ClearPrivateDataConfirm", comment: "The button that clears private data.")
}

// ClearWebsiteDataAlert
extension String {
    public static let ClearWebsiteDataAlertMessage = MZLocalizedString("Settings.WebsiteData.ConfirmPrompt", value: "This action will clear all of your website data. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.")
    // TODO: these look like the same as in ClearPrivateDataAlert, I think we can remove them
    public static let ClearWebsiteDataAlertCancel = MZLocalizedString("Cancel", tableName: "ClearPrivateDataConfirm", comment: "The cancel button when confirming clear private data.")
    public static let ClearWebsiteDataAlertOk = MZLocalizedString("OK", tableName: "ClearPrivateDataConfirm", comment: "The button that clears private data.")
}

// ClearSyncedHistoryAlert
extension String {
    public static let ClearSyncedHistoryAlertMessage = MZLocalizedString("This action will clear all of your private data, including history from your synced devices.", tableName: "ClearHistoryConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.")
    // TODO: these look like the same as in ClearPrivateDataAlert, I think we can remove them
    public static let ClearSyncedHistoryAlertCancel = MZLocalizedString("Cancel", tableName: "ClearHistoryConfirm", comment: "The cancel button when confirming clear history.")
    public static let ClearSyncedHistoryAlertOk = MZLocalizedString("OK", tableName: "ClearHistoryConfirm", comment: "The confirmation button that clears history even when Sync is connected.")
}

// DeleteLoginAlert
extension String {
    public static let DeleteLoginAlertTitle = MZLocalizedString("Are you sure?", tableName: "LoginManager", comment: "Prompt title when deleting logins")
    public static let DeleteLoginAlertSyncedMessage = MZLocalizedString("Logins will be removed from all connected devices.", tableName: "LoginManager", comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices")
    public static let DeleteLoginAlertLocalMessage = MZLocalizedString("Logins will be permanently removed.", tableName: "LoginManager", comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them")
    public static let DeleteLoginAlertCancel = MZLocalizedString("Cancel", tableName: "LoginManager", comment: "Prompt option for cancelling out of deletion")
    public static let DeleteLoginAlertDelete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.")
}

// Strings used in multiple areas within the Authentication Manager
extension String {
    public static let AuthenticationPasscode = MZLocalizedString("Passcode For Logins", tableName: "AuthenticationManager", comment: "Label for the Passcode item in Settings")
    public static let AuthenticationTouchIDPasscodeSetting = MZLocalizedString("Touch ID & Passcode", tableName: "AuthenticationManager", comment: "Label for the Touch ID/Passcode item in Settings")
    public static let AuthenticationFaceIDPasscodeSetting = MZLocalizedString("Face ID & Passcode", tableName: "AuthenticationManager", comment: "Label for the Face ID/Passcode item in Settings")
    public static let AuthenticationRequirePasscode = MZLocalizedString("Require Passcode", tableName: "AuthenticationManager", comment: "Text displayed in the 'Interval' section, followed by the current interval setting, e.g. 'Immediately'")
    public static let AuthenticationEnterAPasscode = MZLocalizedString("Enter a passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when entering a new passcode")
    public static let AuthenticationEnterPasscodeTitle = MZLocalizedString("Enter Passcode", tableName: "AuthenticationManager", comment: "Title of the dialog used to request the passcode")
    public static let AuthenticationEnterPasscode = MZLocalizedString("Enter passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when changing the existing passcode")
    public static let AuthenticationReenterPasscode = MZLocalizedString("Re-enter passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when confirming a passcode")
    public static let AuthenticationSetPasscode = MZLocalizedString("Set Passcode", tableName: "AuthenticationManager", comment: "Title of the dialog used to set a passcode")
    public static let AuthenticationTurnOffPasscode = MZLocalizedString("Turn Passcode Off", tableName: "AuthenticationManager", comment: "Label used as a setting item to turn off passcode")
    public static let AuthenticationTurnOnPasscode = MZLocalizedString("Turn Passcode On", tableName: "AuthenticationManager", comment: "Label used as a setting item to turn on passcode")
    public static let AuthenticationChangePasscode = MZLocalizedString("Change Passcode", tableName: "AuthenticationManager", comment: "Label used as a setting item and title of the following screen to change the current passcode")
    public static let AuthenticationEnterNewPasscode = MZLocalizedString("Enter a new passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when changing the existing passcode")
    public static let AuthenticationImmediately = MZLocalizedString("Immediately", tableName: "AuthenticationManager", comment: "'Immediately' interval item for selecting when to require passcode")
    public static let AuthenticationOneMinute = MZLocalizedString("After 1 minute", tableName: "AuthenticationManager", comment: "'After 1 minute' interval item for selecting when to require passcode")
    public static let AuthenticationFiveMinutes = MZLocalizedString("After 5 minutes", tableName: "AuthenticationManager", comment: "'After 5 minutes' interval item for selecting when to require passcode")
    public static let AuthenticationTenMinutes = MZLocalizedString("After 10 minutes", tableName: "AuthenticationManager", comment: "'After 10 minutes' interval item for selecting when to require passcode")
    public static let AuthenticationFifteenMinutes = MZLocalizedString("After 15 minutes", tableName: "AuthenticationManager", comment: "'After 15 minutes' interval item for selecting when to require passcode")
    public static let AuthenticationOneHour = MZLocalizedString("After 1 hour", tableName: "AuthenticationManager", comment: "'After 1 hour' interval item for selecting when to require passcode")
    public static let AuthenticationLoginsTouchReason = MZLocalizedString("Use your fingerprint to access Logins now.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when accessing logins")
    public static let AuthenticationRequirePasscodeTouchReason = MZLocalizedString("touchid.require.passcode.reason.label", tableName: "AuthenticationManager", value: "Use your fingerprint to access configuring your required passcode interval.", comment: "Touch ID prompt subtitle when accessing the require passcode setting")
    public static let AuthenticationDisableTouchReason = MZLocalizedString("touchid.disable.reason.label", tableName: "AuthenticationManager", value: "Use your fingerprint to disable Touch ID.", comment: "Touch ID prompt subtitle when disabling Touch ID")
    public static let AuthenticationWrongPasscodeError = MZLocalizedString("Incorrect passcode. Try again.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app")
    public static let AuthenticationIncorrectAttemptsRemaining = MZLocalizedString("Incorrect passcode. Try again (Attempts remaining: %d).", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app with attempts remaining")
    public static let AuthenticationMaximumAttemptsReached = MZLocalizedString("Maximum attempts reached. Please try again in an hour.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.")
    public static let AuthenticationMaximumAttemptsReachedNoTime = MZLocalizedString("Maximum attempts reached. Please try again later.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.")
    public static let AuthenticationMismatchPasscodeError = MZLocalizedString("Passcodes didn’t match. Try again.", tableName: "AuthenticationManager", comment: "Error message displayed to user when their confirming passcode doesn't match the first code.")
    public static let AuthenticationUseNewPasscodeError = MZLocalizedString("New passcode must be different than existing code.", tableName: "AuthenticationManager", comment: "Error message displayed when user tries to enter the same passcode as their existing code when changing it.")
}

// Authenticator strings
extension String {
    public static let AuthenticatorCancel = MZLocalizedString("Cancel", comment: "Label for Cancel button")
    public static let AuthenticatorLogin = MZLocalizedString("Log in", comment: "Authentication prompt log in button")
    public static let AuthenticatorPromptTitle = MZLocalizedString("Authentication required", comment: "Authentication prompt title")
    public static let AuthenticatorPromptRealmMessage = MZLocalizedString("A username and password are being requested by %@. The site says: %@", comment: "Authentication prompt message with a realm. First parameter is the hostname. Second is the realm string")
    public static let AuthenticatorPromptEmptyRealmMessage = MZLocalizedString("A username and password are being requested by %@.", comment: "Authentication prompt message with no realm. Parameter is the hostname of the site")
    public static let AuthenticatorUsernamePlaceholder = MZLocalizedString("Username", comment: "Username textbox in Authentication prompt")
    public static let AuthenticatorPasswordPlaceholder = MZLocalizedString("Password", comment: "Password textbox in Authentication prompt")
}

// BrowserViewController
extension String {
    public static let ReaderModeAddPageGeneralErrorAccessibilityLabel = MZLocalizedString("Could not add page to Reading list", comment: "Accessibility message e.g. spoken by VoiceOver after adding current webpage to the Reading List failed.")
    public static let ReaderModeAddPageSuccessAcessibilityLabel = MZLocalizedString("Added page to Reading List", comment: "Accessibility message e.g. spoken by VoiceOver after the current page gets added to the Reading List using the Reader View button, e.g. by long-pressing it or by its accessibility custom action.")
    public static let ReaderModeAddPageMaybeExistsErrorAccessibilityLabel = MZLocalizedString("Could not add page to Reading List. Maybe it’s already there?", comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures.")
    public static let WebViewAccessibilityLabel = MZLocalizedString("Web content", comment: "Accessibility label for the main web content view")
}

// Find in page
extension String {
    public static let FindInPagePreviousAccessibilityLabel = MZLocalizedString("Previous in-page result", tableName: "FindInPage", comment: "Accessibility label for previous result button in Find in Page Toolbar.")
    public static let FindInPageNextAccessibilityLabel = MZLocalizedString("Next in-page result", tableName: "FindInPage", comment: "Accessibility label for next result button in Find in Page Toolbar.")
    public static let FindInPageDoneAccessibilityLabel = MZLocalizedString("Done", tableName: "FindInPage", comment: "Done button in Find in Page Toolbar.")
}

// Reader Mode Bar
extension String {
    public static let ReaderModeBarMarkAsRead = MZLocalizedString("Mark as Read", comment: "Name for Mark as read button in reader mode")
    public static let ReaderModeBarMarkAsUnread = MZLocalizedString("Mark as Unread", comment: "Name for Mark as unread button in reader mode")
    public static let ReaderModeBarSettings = MZLocalizedString("Display Settings", comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.")
    public static let ReaderModeBarAddToReadingList = MZLocalizedString("Add to Reading List", comment: "Name for button adding current article to reading list in reader mode")
    public static let ReaderModeBarRemoveFromReadingList = MZLocalizedString("Remove from Reading List", comment: "Name for button removing current article from reading list in reader mode")
}

// SearchViewController
extension String {
    public static let SearchSettingsAccessibilityLabel = MZLocalizedString("Search Settings", tableName: "Search", comment: "Label for search settings button.")
    public static let SearchSearchEngineAccessibilityLabel = MZLocalizedString("%@ search", tableName: "Search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine.")
    public static let SearchSearchEngineSuggestionAccessibilityLabel = MZLocalizedString("Search suggestions from %@", tableName: "Search", comment: "Accessibility label for image of default search engine displayed left to the actual search suggestions from the engine. The parameter substituted for \"%@\" is the name of the search engine. E.g.: Search suggestions from Google")
    public static let SearchSearchSuggestionTapAccessibilityHint = MZLocalizedString("Searches for the suggestion", comment: "Accessibility hint describing the action performed when a search suggestion is clicked")
    public static let SearchSuggestionCellSwitchToTabLabel = MZLocalizedString("Search.Awesomebar.SwitchToTab", value: "Switch to tab", comment: "Search suggestion cell label that allows user to switch to tab which they searched for in url bar")
}

// Tab Location View
extension String {
    public static let TabLocationURLPlaceholder = MZLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
    public static let TabLocationLockIconAccessibilityLabel = MZLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
    public static let TabLocationReaderModeAccessibilityLabel = MZLocalizedString("Reader View", comment: "Accessibility label for the Reader View button")
    public static let TabLocationReaderModeAddToReadingListAccessibilityLabel = MZLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list.")
    public static let TabLocationReloadAccessibilityLabel = MZLocalizedString("Reload page", comment: "Accessibility label for the reload button")
    public static let TabLocationPageOptionsAccessibilityLabel = MZLocalizedString("Page Options Menu", comment: "Accessibility label for the Page Options menu button")
}

// TabPeekViewController
extension String {
    public static let TabPeekAddToBookmarks = MZLocalizedString("Add to Bookmarks", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks")
    public static let TabPeekCopyUrl = MZLocalizedString("Copy URL", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard")
    public static let TabPeekCloseTab = MZLocalizedString("Close Tab", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to close the current tab")
    public static let TabPeekPreviewAccessibilityLabel = MZLocalizedString("Preview of %@", tableName: "3DTouchActions", comment: "Accessibility label, associated to the 3D Touch action on the current tab in the tab tray, used to display a larger preview of the tab.")
}

// Tab Toolbar

extension String {
    public static let TabToolbarReloadAccessibilityLabel = MZLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
    public static let TabToolbarStopAccessibilityLabel = MZLocalizedString("Stop", comment: "Accessibility Label for the tab toolbar Stop button")
    public static let TabToolbarSearchAccessibilityLabel = MZLocalizedString("Search", comment: "Accessibility Label for the tab toolbar Search button")
    public static let TabToolbarNewTabAccessibilityLabel = MZLocalizedString("New Tab", comment: "Accessibility Label for the tab toolbar New tab button")
    public static let TabToolbarBackAccessibilityLabel = MZLocalizedString("Back", comment: "Accessibility label for the Back button in the tab toolbar.")
    public static let TabToolbarForwardAccessibilityLabel = MZLocalizedString("Forward", comment: "Accessibility Label for the tab toolbar Forward button")
    public static let TabToolbarNavigationToolbarAccessibilityLabel = MZLocalizedString("Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
}

// Tab Tray v1
extension String {
    public static let TabTrayToggleAccessibilityLabel = MZLocalizedString("Private Mode", tableName: "PrivateBrowsing", comment: "Accessibility label for toggling on/off private mode")
    public static let TabTrayToggleAccessibilityHint = MZLocalizedString("Turns private mode on or off", tableName: "PrivateBrowsing", comment: "Accessiblity hint for toggling on/off private mode")
    public static let TabTrayToggleAccessibilityValueOn = MZLocalizedString("On", tableName: "PrivateBrowsing", comment: "Toggled ON accessibility value")
    public static let TabTrayToggleAccessibilityValueOff = MZLocalizedString("Off", tableName: "PrivateBrowsing", comment: "Toggled OFF accessibility value")
    public static let TabTrayViewAccessibilityLabel = MZLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")
    public static let TabTrayNoTabsAccessibilityHint = MZLocalizedString("No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray")
    public static let TabTrayVisibleTabRangeAccessibilityHint = MZLocalizedString("Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
    public static let TabTrayVisiblePartialRangeAccessibilityHint = MZLocalizedString("Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
    public static let TabTrayClosingTabAccessibilityMessage =  MZLocalizedString("Closing tab", comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed.")
    public static let TabTrayCloseAllTabsPromptCancel = MZLocalizedString("Cancel", comment: "Label for Cancel button")
    public static let TabTrayPrivateLearnMore = MZLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode")
    public static let TabTrayPrivateBrowsingTitle = MZLocalizedString("Private Browsing", tableName: "PrivateBrowsing", comment: "Title displayed for when there are no open tabs while in private mode")
    public static let TabTrayPrivateBrowsingDescription =  MZLocalizedString("Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.", tableName: "PrivateBrowsing", comment: "Description text displayed when there are no open tabs while in private mode")
    public static let TabTrayAddTabAccessibilityLabel = MZLocalizedString("Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
    public static let TabTrayCloseAccessibilityCustomAction = MZLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)")
    public static let TabTraySwipeToCloseAccessibilityHint = MZLocalizedString("Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.")
    public static let TabTrayCurrentlySelectedTabAccessibilityLabel = MZLocalizedString("TabTray.CurrentSelectedTab.A11Y", value: "Currently selected tab.", comment: "Accessibility label for the currently selected tab.")
}

// URL Bar
extension String {
    public static let URLBarLocationAccessibilityLabel = MZLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
}

// Error Pages
extension String {
    public static let ErrorPageTryAgain = MZLocalizedString("Try again", tableName: "ErrorPages", comment: "Shown in error pages on a button that will try to load the page again")
    public static let ErrorPageOpenInSafari = MZLocalizedString("Open in Safari", tableName: "ErrorPages", comment: "Shown in error pages for files that can't be shown and need to be downloaded.")
}

// LibraryPanel
extension String {
    public static let LibraryPanelBookmarksAccessibilityLabel = MZLocalizedString("Bookmarks", comment: "Panel accessibility label")
    public static let LibraryPanelHistoryAccessibilityLabel = MZLocalizedString("History", comment: "Panel accessibility label")
    public static let LibraryPanelReadingListAccessibilityLabel = MZLocalizedString("Reading list", comment: "Panel accessibility label")
    public static let LibraryPanelDownloadsAccessibilityLabel = MZLocalizedString("Downloads", comment: "Panel accessibility label")
    public static let LibraryPanelSyncedTabsAccessibilityLabel = MZLocalizedString("Synced Tabs", comment: "Panel accessibility label")
}

// LibraryViewController
extension String {
    public static let LibraryPanelChooserAccessibilityLabel = MZLocalizedString("Panel Chooser", comment: "Accessibility label for the Library panel's bottom toolbar containing a list of the home panels (top sites, bookmarks, history, remote tabs, reading list).")
}

// ReaderPanel
extension String {
    public static let ReaderPanelRemove = MZLocalizedString("Remove", comment: "Title for the button that removes a reading list item")
    public static let ReaderPanelMarkAsRead = MZLocalizedString("Mark as Read", comment: "Title for the button that marks a reading list item as read")
    public static let ReaderPanelMarkAsUnread =  MZLocalizedString("Mark as Unread", comment: "Title for the button that marks a reading list item as unread")
    public static let ReaderPanelUnreadAccessibilityLabel = MZLocalizedString("unread", comment: "Accessibility label for unread article in reading list. It's a past participle - functions as an adjective.")
    public static let ReaderPanelReadAccessibilityLabel = MZLocalizedString("read", comment: "Accessibility label for read article in reading list. It's a past participle - functions as an adjective.")
    public static let ReaderPanelWelcome = MZLocalizedString("Welcome to your Reading List", comment: "See http://mzl.la/1LXbDOL")
    public static let ReaderPanelReadingModeDescription = MZLocalizedString("Open articles in Reader View by tapping the book icon when it appears in the title bar.", comment: "See http://mzl.la/1LXbDOL")
    public static let ReaderPanelReadingListDescription = MZLocalizedString("Save pages to your Reading List by tapping the book plus icon in the Reader View controls.", comment: "See http://mzl.la/1LXbDOL")
}

// Remote Tabs Panel
extension String {
    // Backup and active strings added in Bug 1205294.
    public static let RemoteTabEmptyStateInstructionsSyncTabsPasswordsBookmarksString = MZLocalizedString("Sync your tabs, bookmarks, passwords and more.", comment: "Text displayed when the Sync home panel is empty, describing the features provided by Sync to invite the user to log in.")
    public static let RemoteTabEmptyStateInstructionsSyncTabsPasswordsString = MZLocalizedString("Sync your tabs, passwords and more.", comment: "Text displayed when the Sync home panel is empty, describing the features provided by Sync to invite the user to log in.")
    public static let RemoteTabEmptyStateInstructionsGetTabsBookmarksPasswordsString = MZLocalizedString("Get your open tabs, bookmarks, and passwords from your other devices.", comment: "A re-worded offer about Sync, displayed when the Sync home panel is empty, that emphasizes one-way data transfer, not syncing.")

    public static let RemoteTabErrorNoTabs = MZLocalizedString("You don’t have any tabs open in Firefox on your other devices.", comment: "Error message in the remote tabs panel")
    public static let RemoteTabErrorFailedToSync = MZLocalizedString("There was a problem accessing tabs from your other devices. Try again in a few moments.", comment: "Error message in the remote tabs panel")
    public static let RemoteTabLastSync = MZLocalizedString("Last synced: %@", comment: "Remote tabs last synced time. Argument is the relative date string.")
    public static let RemoteTabComputerAccessibilityLabel = MZLocalizedString("computer", comment: "Accessibility label for Desktop Computer (PC) image in remote tabs list")
    public static let RemoteTabMobileAccessibilityLabel =  MZLocalizedString("mobile device", comment: "Accessibility label for Mobile Device image in remote tabs list")
    public static let RemoteTabCreateAccount = MZLocalizedString("Create an account", comment: "See http://mzl.la/1Qtkf0j")
}

// Login list
extension String {
    public static let LoginListDeselctAll = MZLocalizedString("Deselect All", tableName: "LoginManager", comment: "Label for the button used to deselect all logins.")
    public static let LoginListSelctAll = MZLocalizedString("Select All", tableName: "LoginManager", comment: "Label for the button used to select all logins.")
    public static let LoginListDelete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.")
}

// Login Detail
extension String {
    public static let LoginDetailUsername = MZLocalizedString("Username", tableName: "LoginManager", comment: "Label displayed above the username row in Login Detail View.")
    public static let LoginDetailPassword = MZLocalizedString("Password", tableName: "LoginManager", comment: "Label displayed above the password row in Login Detail View.")
    public static let LoginDetailWebsite = MZLocalizedString("Website", tableName: "LoginManager", comment: "Label displayed above the website row in Login Detail View.")
    public static let LoginDetailCreatedAt =  MZLocalizedString("Created %@", tableName: "LoginManager", comment: "Label describing when the current login was created with the timestamp as the parameter.")
    public static let LoginDetailModifiedAt = MZLocalizedString("Modified %@", tableName: "LoginManager", comment: "Label describing when the current login was last modified with the timestamp as the parameter.")
    public static let LoginDetailDelete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.")
}

// No Logins View
extension String {
    public static let NoLoginsFound = MZLocalizedString("No logins found", tableName: "LoginManager", comment: "Label displayed when no logins are found after searching.")
}

// Reader Mode Handler
extension String {
    public static let ReaderModeHandlerLoadingContent = MZLocalizedString("Loading content…", comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModeHandlerPageCantDisplay = MZLocalizedString("The page could not be displayed in Reader View.", comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModeHandlerLoadOriginalPage = MZLocalizedString("Load original page", comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModeHandlerError = MZLocalizedString("There was an error converting the page", comment: "Error displayed when reader mode cannot be enabled")
}

// ReaderModeStyle
extension String {
    public static let ReaderModeStyleBrightnessAccessibilityLabel = MZLocalizedString("Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings")
    public static let ReaderModeStyleFontTypeAccessibilityLabel = MZLocalizedString("Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings")
    public static let ReaderModeStyleSansSerifFontType = MZLocalizedString("Sans-serif", comment: "Font type setting in the reading view settings")
    public static let ReaderModeStyleSerifFontType = MZLocalizedString("Serif", comment: "Font type setting in the reading view settings")
    public static let ReaderModeStyleSmallerLabel = MZLocalizedString("-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeStyleSmallerAccessibilityLabel = MZLocalizedString("Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode")
    public static let ReaderModeStyleLargerLabel = MZLocalizedString("+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeStyleLargerAccessibilityLabel = MZLocalizedString("Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode")
    public static let ReaderModeStyleFontSize = MZLocalizedString("Aa", comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeStyleChangeColorSchemeAccessibilityHint = MZLocalizedString("Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings")
    public static let ReaderModeStyleLightLabel = MZLocalizedString("Light", comment: "Light theme setting in Reading View settings")
    public static let ReaderModeStyleDarkLabel = MZLocalizedString("Dark", comment: "Dark theme setting in Reading View settings")
    public static let ReaderModeStyleSepiaLabel = MZLocalizedString("Sepia", comment: "Sepia theme setting in Reading View settings")
}

// Empty Private tab view
extension String {
    public static let PrivateBrowsingLearnMore = MZLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode")
    public static let PrivateBrowsingTitle = MZLocalizedString("Private Browsing", tableName: "PrivateBrowsing", comment: "Title displayed for when there are no open tabs while in private mode")
    public static let PrivateBrowsingDescription = MZLocalizedString("Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.", tableName: "PrivateBrowsing", comment: "Description text displayed when there are no open tabs while in private mode")
}

// Advanced Account Setting
extension String {
    public static let AdvancedAccountUseStageServer = MZLocalizedString("Use stage servers", comment: "Debug option")
}

// App Settings
extension String {
    public static let AppSettingsLicenses = MZLocalizedString("Licenses", comment: "Settings item that opens a tab containing the licenses. See http://mzl.la/1NSAWCG")
    public static let AppSettingsYourRights = MZLocalizedString("Your Rights", comment: "Your Rights settings section title")
    public static let AppSettingsShowTour = MZLocalizedString("Show Tour", comment: "Show the on-boarding screen again from the settings")
    public static let AppSettingsSendFeedback = MZLocalizedString("Send Feedback", comment: "Menu item in settings used to open input.mozilla.org where people can submit feedback")
    public static let AppSettingsHelp = MZLocalizedString("Help", comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ")
    public static let AppSettingsSearch = MZLocalizedString("Search", comment: "Open search section of settings")
    public static let AppSettingsPrivacyPolicy = MZLocalizedString("Privacy Policy", comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/")
    
    public static let AppSettingsTitle = MZLocalizedString("Settings", comment: "Title in the settings view controller title bar")
    public static let AppSettingsDone = MZLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar")
    public static let AppSettingsPrivacyTitle = MZLocalizedString("Privacy", comment: "Privacy section title")
    public static let AppSettingsBlockPopups = MZLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting")
    public static let AppSettingsClosePrivateTabsTitle = MZLocalizedString("Close Private Tabs", tableName: "PrivateBrowsing", comment: "Setting for closing private tabs")
    public static let AppSettingsClosePrivateTabsDescription = MZLocalizedString("When Leaving Private Browsing", tableName: "PrivateBrowsing", comment: "Will be displayed in Settings under 'Close Private Tabs'")
    public static let AppSettingsSupport = MZLocalizedString("Support", comment: "Support section title")
    public static let AppSettingsAbout = MZLocalizedString("About", comment: "About settings section title")
}

// Clearables
extension String {
    // Removed Clearables as part of Bug 1226654, but keeping the string around.
    private static let removedSavedLoginsLabel = MZLocalizedString("Saved Logins", tableName: "ClearPrivateData", comment: "Settings item for clearing passwords and login data")
    
    public static let ClearableHistory = MZLocalizedString("Browsing History", tableName: "ClearPrivateData", comment: "Settings item for clearing browsing history")
    public static let ClearableCache = MZLocalizedString("Cache", tableName: "ClearPrivateData", comment: "Settings item for clearing the cache")
    public static let ClearableOfflineData = MZLocalizedString("Offline Website Data", tableName: "ClearPrivateData", comment: "Settings item for clearing website data")
    public static let ClearableCookies = MZLocalizedString("Cookies", tableName: "ClearPrivateData", comment: "Settings item for clearing cookies")
    public static let ClearableDownloads = MZLocalizedString("Downloaded Files", tableName: "ClearPrivateData", comment: "Settings item for deleting downloaded files")
}

// SearchEngine Picker
extension String {
    public static let SearchEnginePickerTitle = MZLocalizedString("Default Search Engine", comment: "Title for default search engine picker.")
    public static let SearchEnginePickerCancel = MZLocalizedString("Cancel", comment: "Label for Cancel button")
}

// SearchSettings
extension String {
    public static let SearchSettingsTitle = MZLocalizedString("Search", comment: "Navigation title for search settings.")
    public static let SearchSettingsDefaultSearchEngineAccessibilityLabel = MZLocalizedString("Default Search Engine", comment: "Accessibility label for default search engine setting.")
    public static let SearchSettingsShowSearchSuggestions = MZLocalizedString("Show Search Suggestions", comment: "Label for show search suggestions setting.")
    public static let SearchSettingsDefaultSearchEngineTitle = MZLocalizedString("Default Search Engine", comment: "Title for default search engine settings section.")
    public static let SearchSettingsQuickSearchEnginesTitle = MZLocalizedString("Quick-Search Engines", comment: "Title for quick-search engines settings section.")
}

// SettingsContent
extension String {
    public static let SettingsContentPageLoadError = MZLocalizedString("Could not load page.", comment: "Error message that is shown in settings when there was a problem loading")
}

// SearchInput
extension String {
    public static let SearchInputAccessibilityLabel = MZLocalizedString("Search Input Field", tableName: "LoginManager", comment: "Accessibility label for the search input field in the Logins list")
    public static let SearchInputTitle = MZLocalizedString("Search", tableName: "LoginManager", comment: "Title for the search field at the top of the Logins list screen")
    public static let SearchInputClearAccessibilityLabel = MZLocalizedString("Clear Search", tableName: "LoginManager", comment: "Accessibility message e.g. spoken by VoiceOver after the user taps the close button in the search field to clear the search and exit search mode")
    public static let SearchInputEnterSearchMode = MZLocalizedString("Enter Search Mode", tableName: "LoginManager", comment: "Accessibility label for entering search mode for logins")
}

// TabsButton
extension String {
    public static let TabsButtonShowTabsAccessibilityLabel = MZLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the (top) tab toolbar")
}

// TabTrayButtons
extension String {
    public static let TabTrayButtonNewTabAccessibilityLabel = MZLocalizedString("New Tab", comment: "Accessibility label for the New Tab button in the tab toolbar.")
    public static let TabTrayButtonShowTabsAccessibilityLabel = MZLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the tab toolbar")
}

// MenuHelper
extension String {
    public static let MenuHelperPasteAndGo = MZLocalizedString("UIMenuItem.PasteGo", value: "Paste & Go", comment: "The menu item that pastes the current contents of the clipboard into the URL bar and navigates to the page")
    public static let MenuHelperReveal = MZLocalizedString("Reveal", tableName: "LoginManager", comment: "Reveal password text selection menu item")
    public static let MenuHelperHide =  MZLocalizedString("Hide", tableName: "LoginManager", comment: "Hide password text selection menu item")
    public static let MenuHelperCopy = MZLocalizedString("Copy", tableName: "LoginManager", comment: "Copy password text selection menu item")
    public static let MenuHelperOpenAndFill = MZLocalizedString("Open & Fill", tableName: "LoginManager", comment: "Open and Fill website text selection menu item")
    public static let MenuHelperFindInPage = MZLocalizedString("Find in Page", tableName: "FindInPage", comment: "Text selection menu item")
    public static let MenuHelperSearchWithFirefox = MZLocalizedString("UIMenuItem.SearchWithFirefox", value: "Search with Firefox", comment: "Search in New Tab Text selection menu item")
}

// DeviceInfo
extension String {
    public static let DeviceInfoClientNameDescription = MZLocalizedString("%@ on %@", tableName: "Shared", comment: "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs. The first argument is the app name. The second argument is the device name.")
}

// TimeConstants
extension String {
    public static let TimeConstantMoreThanAMonth = MZLocalizedString("more than a month ago", comment: "Relative date for dates older than a month and less than two months.")
    public static let TimeConstantMoreThanAWeek = MZLocalizedString("more than a week ago", comment: "Description for a date more than a week ago, but less than a month ago.")
    public static let TimeConstantYesterday = MZLocalizedString("yesterday", comment: "Relative date for yesterday.")
    public static let TimeConstantThisWeek = MZLocalizedString("this week", comment: "Relative date for date in past week.")
    public static let TimeConstantRelativeToday = MZLocalizedString("today at %@", comment: "Relative date for date older than a minute.")
    public static let TimeConstantJustNow = MZLocalizedString("just now", comment: "Relative time for a tab that was visited within the last few moments.")
}

// Default Suggested Site
extension String {
    public static let DefaultSuggestedFacebook = MZLocalizedString("Facebook", comment: "Tile title for Facebook")
    public static let DefaultSuggestedYouTube = MZLocalizedString("YouTube", comment: "Tile title for YouTube")
    public static let DefaultSuggestedAmazon = MZLocalizedString("Amazon", comment: "Tile title for Amazon")
    public static let DefaultSuggestedWikipedia = MZLocalizedString("Wikipedia", comment: "Tile title for Wikipedia")
    public static let DefaultSuggestedTwitter = MZLocalizedString("Twitter", comment: "Tile title for Twitter")
}

// MR1 Strings
extension String {
    public static let AwesomeBarSearchWithEngineButtonTitle = MZLocalizedString("Awesomebar.SearchWithEngine.Title", value: "Search with %@", comment: "Title for button to suggest searching with a search engine. First argument is the name of the search engine to select")
    public static let AwesomeBarSearchWithEngineButtonDescription = MZLocalizedString("Awesomebar.SearchWithEngine.Description", value: "Search %@ directly from the address bar", comment: "Description for button to suggest searching with a search engine. First argument is the name of the search engine to select")
}
