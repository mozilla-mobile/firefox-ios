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

extension Strings {
    public static let OKString = NSLocalizedString("OK", comment: "OK button")
    public static let CancelString = NSLocalizedString("Cancel", comment: "Label for Cancel button")
    public static let NotNowString = NSLocalizedString("Toasts.NotNow", value: "Not Now", comment: "label for Not Now button")
    public static let AppStoreString = NSLocalizedString("Toasts.OpenAppStore", value: "Open App Store", comment: "Open App Store button")
    public static let UndoString = NSLocalizedString("Toasts.Undo", value: "Undo", comment: "Label for button to undo the action just performed")
    public static let OpenSettingsString = NSLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7")
}

// Table date section titles.
extension Strings {
    public static let TableDateSectionTitleToday = NSLocalizedString("Today", comment: "History tableview section header")
    public static let TableDateSectionTitleYesterday = NSLocalizedString("Yesterday", comment: "History tableview section header")
    public static let TableDateSectionTitleLastWeek = NSLocalizedString("Last week", comment: "History tableview section header")
    public static let TableDateSectionTitleLastMonth = NSLocalizedString("Last month", comment: "History tableview section header")
}

// Top Sites.
extension Strings {
    public static let TopSitesEmptyStateDescription = NSLocalizedString("TopSites.EmptyState.Description", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.")
    public static let TopSitesEmptyStateTitle = NSLocalizedString("TopSites.EmptyState.Title", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state")
    public static let TopSitesRemoveButtonAccessibilityLabel = NSLocalizedString("TopSites.RemovePage.Button", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Activity Stream.
extension Strings {
    public static let ASPocketTitle = NSLocalizedString("ActivityStream.Pocket.SectionTitle", value: "Trending on Pocket", comment: "Section title label for Recommended by Pocket section")
    public static let ASTopSitesTitle =  NSLocalizedString("ActivityStream.TopSites.SectionTitle", value: "Top Sites", comment: "Section title label for Top Sites")
    public static let HighlightVistedText = NSLocalizedString("ActivityStream.Highlights.Visited", value: "Visited", comment: "The description of a highlight if it is a site the user has visited")
    public static let HighlightBookmarkText = NSLocalizedString("ActivityStream.Highlights.Bookmark", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked")
    public static let PocketTrendingText = NSLocalizedString("ActivityStream.Pocket.Trending", value: "Trending", comment: "The description of a Pocket Story")
    public static let PocketMoreStoriesText = NSLocalizedString("ActivityStream.Pocket.MoreLink", value: "More", comment: "The link that shows more Pocket trending stories")
    public static let TopSitesRowSettingFooter = NSLocalizedString("ActivityStream.TopSites.RowSettingFooter", value: "Set Rows", comment: "The title for the setting page which lets you select the number of top site rows")
    public static let TopSitesRowCount = NSLocalizedString("ActivityStream.TopSites.RowCount", value: "Rows: %d", comment: "label showing how many rows of topsites are shown. %d represents a number")
    public static let RecentlyBookmarkedTitle = NSLocalizedString("ActivityStream.NewRecentBookmarks.Title", value: "Recent Bookmarks", comment: "Section title label for recently bookmarked websites")
    public static let RecentlyVisitedTitle = NSLocalizedString("ActivityStream.RecentHistory.Title", value: "Recently Visited", comment: "Section title label for recently visited websites")
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
    public static let CloseButtonTitle = NSLocalizedString("PhotonMenu.close", value: "Close", comment: "Button for closing the menu action sheet")

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
    public static let ReopenLastTabAlertTitle = NSLocalizedString("ReopenAlert.Title", value: "Reopen Last Closed Tab", comment: "Reopen alert title shown at home page.")
    public static let ReopenLastTabButtonText = NSLocalizedString("ReopenAlert.Actions.Reopen", value: "Reopen", comment: "Reopen button text shown in reopen-alert at home page.")
    public static let ReopenLastTabCancelText = NSLocalizedString("ReopenAlert.Actions.Cancel", value: "Cancel", comment: "Cancel button text shown in reopen-alert at home page.")
}

// Settings.
extension Strings {
    public static let SettingsGeneralSectionTitle = NSLocalizedString("Settings.General.SectionName", value: "General", comment: "General settings section title")
    public static let SettingsClearPrivateDataClearButton = NSLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearAllWebsiteDataButton = NSLocalizedString("Settings.ClearAllWebsiteData.Clear.Button", value: "Clear All Website Data", comment: "Button in Data Management that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = NSLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsDataManagementSectionName = NSLocalizedString("Settings.DataManagement.SectionName", value: "Data Management", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsFilterSitesSearchLabel = NSLocalizedString("Settings.DataManagement.SearchLabel", value: "Filter Sites", comment: "Default text in search bar for Data Management")
    public static let SettingsClearPrivateDataTitle = NSLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
    public static let SettingsDataManagementTitle = NSLocalizedString("Settings.DataManagement.Title", value: "Data Management", comment: "Title displayed in header of the setting panel.")
    public static let SettingsWebsiteDataTitle = NSLocalizedString("Settings.WebsiteData.Title", value: "Website Data", comment: "Title displayed in header of the Data Management panel.")
    public static let SettingsWebsiteDataShowMoreButton = NSLocalizedString("Settings.WebsiteData.ButtonShowMore", value: "Show More", comment: "Button shows all websites on website data tableview")
    public static let SettingsClearWebsiteDataMessage = NSLocalizedString("Settings.WebsiteData.ConfirmPrompt", value: "This action will clear all of your website data. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.")
    public static let SettingsEditWebsiteSearchButton = NSLocalizedString("Settings.WebsiteData.ButtonEdit", value: "Edit", comment: "Button to edit website search results")
    public static let SettingsDeleteWebsiteSearchButton = NSLocalizedString("Settings.WebsiteData.ButtonDelete", value: "Delete", comment: "Button to delete website in search results")
    public static let SettingsDoneWebsiteSearchButton = NSLocalizedString("Settings.WebsiteData.ButtonDone", value: "Done", comment: "Button to exit edit website search results")
    public static let SettingsDisconnectSyncAlertTitle = NSLocalizedString("Settings.Disconnect.Title", value: "Disconnect Sync?", comment: "Title of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncAlertBody = NSLocalizedString("Settings.Disconnect.Body", value: "Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Body of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncButton = NSLocalizedString("Settings.Disconnect.Button", value: "Disconnect Sync", comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA")
    public static let SettingsDisconnectCancelAction = NSLocalizedString("Settings.Disconnect.CancelButton", value: "Cancel", comment: "Cancel action button in alert when user is prompted for disconnect")
    public static let SettingsDisconnectDestructiveAction = NSLocalizedString("Settings.Disconnect.DestructiveButton", value: "Disconnect", comment: "Destructive action button in alert when user is prompted for disconnect")
    public static let SettingsSearchDoneButton = NSLocalizedString("Settings.Search.Done.Button", value: "Done", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = NSLocalizedString("Settings.Search.Edit.Button", value: "Edit", comment: "Button displayed at the top of the search settings.")
    public static let UseTouchID = NSLocalizedString("Use Touch ID", tableName: "AuthenticationManager", comment: "List section title for when to use Touch ID")
    public static let UseFaceID = NSLocalizedString("Use Face ID", tableName: "AuthenticationManager", comment: "List section title for when to use Face ID")
    public static let SettingsCopyAppVersionAlertTitle = NSLocalizedString("Settings.CopyAppVersion.Title", value: "Copied to clipboard", comment: "Copy app version alert shown in settings.")
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
    public static let LoginsHelperDontUpdateButtonTitle = NSLocalizedString("LoginsHelper.DontUpdate.Button", value: "Don’t Update", comment: "Button to not update the user's password")
}

// Downloads Panel
extension Strings {
    public static let DownloadsPanelEmptyStateTitle = NSLocalizedString("DownloadsPanel.EmptyState.Title", value: "Downloaded files will show up here.", comment: "Title for the Downloads Panel empty state.")
    public static let DownloadsPanelDeleteTitle = NSLocalizedString("DownloadsPanel.Delete.Title", value: "Delete", comment: "Action button for deleting downloaded files in the Downloads panel.")
    public static let DownloadsPanelShareTitle = NSLocalizedString("DownloadsPanel.Share.Title", value: "Share", comment: "Action button for sharing downloaded files in the Downloads panel.")
}

// History Panel
extension Strings {
    public static let SyncedTabsTableViewCellTitle = NSLocalizedString("HistoryPanel.SyncedTabsCell.Title", value: "Synced Devices", comment: "Title for the Synced Tabs Cell in the History Panel")
    public static let HistoryBackButtonTitle = NSLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let EmptySyncedTabsPanelStateTitle = NSLocalizedString("HistoryPanel.EmptySyncedTabsState.Title", value: "Firefox Sync", comment: "Title for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelNotSignedInStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsPanelNotSignedInState.Description", value: "Sign in to view a list of tabs from your other devices.", comment: "Description for the empty synced tabs 'not signed in' state in the History Panel")
    public static let EmptySyncedTabsPanelNotYetVerifiedStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsPanelNotYetVerifiedState.Description", value: "Your account needs to be verified.", comment: "Description for the empty synced tabs 'not yet verified' state in the History Panel")
    public static let EmptySyncedTabsPanelSingleDeviceSyncStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsPanelSingleDeviceSyncState.Description", value: "Want to see your tabs from other devices here?", comment: "Description for the empty synced tabs 'single device Sync' state in the History Panel")
    public static let EmptySyncedTabsPanelTabSyncDisabledStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsPanelTabSyncDisabledState.Description", value: "Turn on tab syncing to view a list of tabs from your other devices.", comment: "Description for the empty synced tabs 'tab sync disabled' state in the History Panel")
    public static let EmptySyncedTabsPanelNullStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsNullState.Description", value: "Your tabs from other devices show up here.", comment: "Description for the empty synced tabs null state in the History Panel")
    public static let SyncedTabsTableViewCellDescription = NSLocalizedString("HistoryPanel.SyncedTabsCell.Description.Pluralized", value: "%d device(s) connected", comment: "Description that corresponds with a number of devices connected for the Synced Tabs Cell in the History Panel")
    public static let HistoryPanelEmptyStateTitle = NSLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.")
    public static let RecentlyClosedTabsButtonTitle = NSLocalizedString("HistoryPanel.RecentlyClosedTabsButton.Title", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel")
    public static let RecentlyClosedTabsPanelTitle = NSLocalizedString("RecentlyClosedTabsPanel.Title", value: "Recently Closed", comment: "Title for the Recently Closed Tabs Panel")
    public static let HistoryPanelClearHistoryButtonTitle = NSLocalizedString("HistoryPanel.ClearHistoryButtonTitle", value: "Clear Recent History…", comment: "Title for button in the history panel to clear recent history")
    public static let FirefoxHomePage = NSLocalizedString("Firefox.HomePage.Title", value: "Firefox Home Page", comment: "Title for firefox about:home page in tab history list")
}

// Clear recent history action menu
extension Strings {
    public static let ClearHistoryMenuTitle = NSLocalizedString("HistoryPanel.ClearHistoryMenuTitle", value: "Clearing Recent History will remove history, cookies, and other browser data.", comment: "Title for popup action menu to clear recent history.")
    public static let ClearHistoryMenuOptionTheLastHour = NSLocalizedString("HistoryPanel.ClearHistoryMenuOptionTheLastHour", value: "The Last Hour", comment: "Button to perform action to clear history for the last hour")
    public static let ClearHistoryMenuOptionToday = NSLocalizedString("HistoryPanel.ClearHistoryMenuOptionToday", value: "Today", comment: "Button to perform action to clear history for today only")
    public static let ClearHistoryMenuOptionTodayAndYesterday = NSLocalizedString("HistoryPanel.ClearHistoryMenuOptionTodayAndYesterday", value: "Today and Yesterday", comment: "Button to perform action to clear history for yesterday and today")
    public static let ClearHistoryMenuOptionEverything = NSLocalizedString("HistoryPanel.ClearHistoryMenuOptionEverything", value: "Everything", comment: "Option title to clear all browsing history.")
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

// Firefox Logins
extension Strings {
    public static let LoginsAndPasswordsTitle = NSLocalizedString("Settings.LoginsAndPasswordsTitle", value: "Logins & Passwords", comment: "Title for the logins and passwords screen. Translation could just use 'Logins' if the title is too long")

    // Prompts
    public static let SaveLoginUsernamePrompt = NSLocalizedString("LoginsHelper.PromptSaveLogin.Title", value: "Save login %@ for %@?", comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.")
    public static let SaveLoginPrompt = NSLocalizedString("LoginsHelper.PromptSavePassword.Title", value: "Save password for %@?", comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.")
    public static let UpdateLoginUsernamePrompt = NSLocalizedString("LoginsHelper.PromptUpdateLogin.Title.TwoArg", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
    public static let UpdateLoginPrompt = NSLocalizedString("LoginsHelper.PromptUpdateLogin.Title.OneArg", value: "Update login for %@?", comment: "Prompt for updating a login. The first parameter is the hostname for which the password will be updated for.")

    // Setting
    public static let SettingToSaveLogins = NSLocalizedString("Settings.SaveLogins.Title", value: "Save Logins", comment: "Setting to enable the built-in password manager")
    public static let SettingToShowLoginsInAppMenu = NSLocalizedString("Settings.ShowLoginsInAppMenu.Title", value: "Show in Application Menu", comment: "Setting to show Logins & Passwords quick access in the application menu")

    // List view
    public static let LoginsListTitle = NSLocalizedString("LoginsList.Title", value: "SAVED LOGINS", comment: "Title for the list of logins")
    public static let LoginsListSearchPlaceholder = NSLocalizedString("LoginsList.LoginsListSearchPlaceholder", value: "Filter", comment: "Placeholder test for search box in logins list view.")
    public static let LoginsFilterWebsite = NSLocalizedString("LoginsList.LoginsListFilterWebsite", value: "Website", comment: "For filtering the login list, search only the website names")
    public static let LoginsFilterLogin = NSLocalizedString("LoginsList.LoginsListFilterLogin", value: "Login", comment: "For filtering the login list, search only the login names")
    public static let LoginsFilterAll = NSLocalizedString("LoginsList.LoginsListFilterSearchAll", value: "All", comment: "For filtering the login list, search both website and login names.")

    // Detail view
    public static let LoginsDetailViewLoginTitle = NSLocalizedString("LoginsDetailView.LoginTitle", value: "Login", comment: "Title for the login detail view")
    public static let LoginsDetailViewLoginModified = NSLocalizedString("LoginsDetailView.LoginModified", value: "Modified", comment: "Login detail view field name for the last modified date")

    // Breach Alerts
    public static let BreachAlertsTitle = NSLocalizedString("BreachAlerts.Title", value: "Website Breach", comment: "Title for the Breached Login Detail View.")
    public static let BreachAlertsLearnMore = NSLocalizedString("BreachAlerts.LearnMoreButton", value: "Learn more", comment: "Link to monitor.firefox.com to learn more about breached passwords")
    public static let BreachAlertsBreachDate = NSLocalizedString("BreachAlerts.BreachDate", value: "This breach occurred on", comment: "Describes the date on which the breach occurred")
    public static let BreachAlertsDescription = NSLocalizedString("BreachAlerts.Description", value: "Passwords were leaked or stolen since you last changed your password. To protect this account, log in to the site and change your password.", comment: "Description of what a breach is")
    public static let BreachAlertsLink = NSLocalizedString("BreachAlerts.Link", value: "Go to", comment: "Leads to a link to the breached website")
}

// Firefox Account
extension Strings {
    // Settings strings
    public static let FxAFirefoxAccount = NSLocalizedString("FxA.FirefoxAccount", value: "Firefox Account", comment: "Settings section title for Firefox Account")
    public static let FxASignInToSync = NSLocalizedString("FxA.SignIntoSync", value: "Sign in to Sync", comment: "Button label to sign into Sync")
    public static let FxATakeYourWebWithYou = NSLocalizedString("FxA.TakeYourWebWithYou", value: "Take Your Web With You", comment: "Call to action for sign into sync button")
    public static let FxASyncUsageDetails = NSLocalizedString("FxA.SyncExplain", value: "Get your tabs, bookmarks, and passwords from your other devices.", comment: "Label explaining what sync does")
    public static let FxAAccountVerificationRequired = NSLocalizedString("FxA.AccountVerificationRequired", value: "Account Verification Required", comment: "Label stating your account is not verified")
    public static let FxAAccountVerificationDetails = NSLocalizedString("FxA.AccountVerificationDetails", value: "Wrong email? Disconnect below to start over.", comment: "Label stating how to disconnect account")
    public static let FxAManageAccount = NSLocalizedString("FxA.ManageAccount", value: "Manage Account & Devices", comment: "Button label to go to Firefox Account settings")
    public static let FxASyncNow = NSLocalizedString("FxA.SyncNow", value: "Sync Now", comment: "Button label to Sync your Firefox Account")
    public static let FxANoInternetConnection = NSLocalizedString("FxA.NoInternetConnection", value: "No Internet Connection", comment: "Label when no internet is present")
    public static let FxASettingsTitle = NSLocalizedString("Settings.FxA.Title", value: "Firefox Account", comment: "Title displayed in header of the FxA settings panel.")
    public static let FxASettingsSyncSettings = NSLocalizedString("Settings.FxA.Sync.SectionName", value: "Sync Settings", comment: "Label used as a section title in the Firefox Accounts Settings screen.")
    public static let FxASettingsDeviceName = NSLocalizedString("Settings.FxA.DeviceName", value: "Device Name", comment: "Label used for the device name settings section.")
    public static let FxAOpenSyncPreferences = NSLocalizedString("FxA.OpenSyncPreferences", value: "Open Sync Preferences", comment: "Button label to open Sync preferences")
    public static let FxAConnectAnotherDevice = NSLocalizedString("FxA.ConnectAnotherDevice", value: "Connect Another Device", comment: "Button label to connect another device to Sync")
    public static let FxARemoveAccountButton = NSLocalizedString("FxA.RemoveAccount", value: "Remove", comment: "Remove button is displayed on firefox account page under certain scenarios where user would like to remove their account.")
    public static let FxARemoveAccountAlertTitle = NSLocalizedString("FxA.RemoveAccountAlertTitle", value: "Remove Account", comment: "Remove account alert is the final confirmation before user removes their firefox account")
    public static let FxARemoveAccountAlertMessage = NSLocalizedString("FxA.RemoveAccountAlertMessage", value: "Remove the Firefox Account associated with this device to sign in as a different user.", comment: "Description string for alert view that gets presented when user tries to remove an account.")

    // Surface error strings
    public static let FxAAccountVerificationRequiredSurface = NSLocalizedString("FxA.AccountVerificationRequiredSurface", value: "You need to verify %@. Check your email for the verification link from Firefox.", comment: "Message explaining that user needs to check email for Firefox Account verfication link.")
    public static let FxAResendEmail = NSLocalizedString("FxA.ResendEmail", value: "Resend Email", comment: "Button label to resend email")
    public static let FxAAccountVerifyEmail = NSLocalizedString("Verify your email address", comment: "Text message in the settings table view")
    public static let FxAAccountVerifyPassword = NSLocalizedString("Enter your password to connect", comment: "Text message in the settings table view")
    public static let FxAAccountUpgradeFirefox = NSLocalizedString("Upgrade Firefox to connect", comment: "Text message in the settings table view")
}

//Hotkey Titles
extension Strings {
    public static let ReloadPageTitle = NSLocalizedString("Hotkeys.Reload.DiscoveryTitle", value: "Reload Page", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let BackTitle = NSLocalizedString("Hotkeys.Back.DiscoveryTitle", value: "Back", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ForwardTitle = NSLocalizedString("Hotkeys.Forward.DiscoveryTitle", value: "Forward", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")

    public static let FindTitle = NSLocalizedString("Hotkeys.Find.DiscoveryTitle", value: "Find", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let SelectLocationBarTitle = NSLocalizedString("Hotkeys.SelectLocationBar.DiscoveryTitle", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let privateBrowsingModeTitle = NSLocalizedString("Hotkeys.PrivateMode.DiscoveryTitle", value: "Private Browsing Mode", comment: "Label to switch to private browsing mode")
    public static let normalBrowsingModeTitle = NSLocalizedString("Hotkeys.NormalMode.DiscoveryTitle", value: "Normal Browsing Mode", comment: "Label to switch to normal browsing mode")
    public static let NewTabTitle = NSLocalizedString("Hotkeys.NewTab.DiscoveryTitle", value: "New Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewPrivateTabTitle = NSLocalizedString("Hotkeys.NewPrivateTab.DiscoveryTitle", value: "New Private Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let CloseTabTitle = NSLocalizedString("Hotkeys.CloseTab.DiscoveryTitle", value: "Close Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowNextTabTitle = NSLocalizedString("Hotkeys.ShowNextTab.DiscoveryTitle", value: "Show Next Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowPreviousTabTitle = NSLocalizedString("Hotkeys.ShowPreviousTab.DiscoveryTitle", value: "Show Previous Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
}

// New tab choice settings
extension Strings {
    public static let CustomNewPageURL = NSLocalizedString("Settings.NewTab.CustomURL", value: "Custom URL", comment: "Label used to set a custom url as the new tab option (homepage).")
    public static let SettingsNewTabSectionName = NSLocalizedString("Settings.NewTab.SectionName", value: "New Tab", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behavior.")
    public static let NewTabSectionName =
        NSLocalizedString("Settings.NewTab.TopSectionName", value: "Show", comment: "Label at the top of the New Tab screen after entering New Tab in settings")
    public static let SettingsNewTabTitle = NSLocalizedString("Settings.NewTab.Title", value: "New Tab", comment: "Title displayed in header of the setting panel.")
    public static let NewTabSectionNameFooter =
        NSLocalizedString("Settings.NewTab.TopSectionNameFooter", value: "Choose what to load when opening a new tab", comment: "Footer at the bottom of the New Tab screen after entering New Tab in settings")
    public static let SettingsNewTabTopSites = NSLocalizedString("Settings.NewTab.Option.FirefoxHome", value: "Firefox Home", comment: "Option in settings to show Firefox Home when you open a new tab")
    public static let SettingsNewTabBookmarks = NSLocalizedString("Settings.NewTab.Option.Bookmarks", value: "Bookmarks", comment: "Option in settings to show bookmarks when you open a new tab")
    public static let SettingsNewTabHistory = NSLocalizedString("Settings.NewTab.Option.History", value: "History", comment: "Option in settings to show history when you open a new tab")
    public static let SettingsNewTabReadingList = NSLocalizedString("Settings.NewTab.Option.ReadingList", value: "Show your Reading List", comment: "Option in settings to show reading list when you open a new tab")
    public static let SettingsNewTabBlankPage = NSLocalizedString("Settings.NewTab.Option.BlankPage", value: "Blank Page", comment: "Option in settings to show a blank page when you open a new tab")
    public static let SettingsNewTabHomePage = NSLocalizedString("Settings.NewTab.Option.HomePage", value: "Homepage", comment: "Option in settings to show your homepage when you open a new tab")
    public static let SettingsNewTabDescription = NSLocalizedString("Settings.NewTab.Description", value: "When you open a New Tab:", comment: "A description in settings of what the new tab choice means")
    // AS Panel settings
    public static let SettingsNewTabASTitle = NSLocalizedString("Settings.NewTab.Option.ASTitle", value: "Customize Top Sites", comment: "The title of the section in newtab that lets you modify the topsites panel")
    public static let SettingsNewTabPocket = NSLocalizedString("Settings.NewTab.Option.Pocket", value: "Trending on Pocket", comment: "Option in settings to turn on off pocket recommendations")
    public static let SettingsNewTabPocketFooter = NSLocalizedString("Settings.NewTab.Option.PocketFooter", value: "Great content from around the web.", comment: "Footer caption for pocket settings")
    public static let SettingsNewTabHiglightsHistory = NSLocalizedString("Settings.NewTab.Option.HighlightsHistory", value: "Visited", comment: "Option in settings to turn off history in the highlights section")
    public static let SettingsNewTabHighlightsBookmarks = NSLocalizedString("Settings.NewTab.Option.HighlightsBookmarks", value: "Recent Bookmarks", comment: "Option in the settings to turn off recent bookmarks in the Highlights section")
    public static let SettingsTopSitesCustomizeTitle = NSLocalizedString("Settings.NewTab.Option.CustomizeTitle", value: "Customize Firefox Home", comment: "The title for the section to customize top sites in the new tab settings page.")
    public static let SettingsTopSitesCustomizeFooter = NSLocalizedString("Settings.NewTab.Option.CustomizeFooter", value: "The sites you visit most", comment: "The footer for the section to customize top sites in the new tab settings page.")

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
    public static let SettingsOpenWithSectionName = NSLocalizedString("Settings.OpenWith.SectionName", value: "Mail App", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behavior.")
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

// Root Bookmarks folders
extension Strings {
    public static let BookmarksFolderTitleMobile = NSLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
    public static let BookmarksFolderTitleMenu = NSLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
    public static let BookmarksFolderTitleToolbar = NSLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
    public static let BookmarksFolderTitleUnsorted = NSLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")
}

// Bookmark Management
extension Strings {
    public static let BookmarksTitle = NSLocalizedString("Bookmarks.Title.Label", value: "Title", comment: "The label for the title of a bookmark")
    public static let BookmarksURL = NSLocalizedString("Bookmarks.URL.Label", value: "URL", comment: "The label for the URL of a bookmark")
    public static let BookmarksFolder = NSLocalizedString("Bookmarks.Folder.Label", value: "Folder", comment: "The label to show the location of the folder where the bookmark is located")
    public static let BookmarksNewBookmark = NSLocalizedString("Bookmarks.NewBookmark.Label", value: "New Bookmark", comment: "The button to create a new bookmark")
    public static let BookmarksNewFolder = NSLocalizedString("Bookmarks.NewFolder.Label", value: "New Folder", comment: "The button to create a new folder")
    public static let BookmarksNewSeparator = NSLocalizedString("Bookmarks.NewSeparator.Label", value: "New Separator", comment: "The button to create a new separator")
    public static let BookmarksEditBookmark = NSLocalizedString("Bookmarks.EditBookmark.Label", value: "Edit Bookmark", comment: "The button to edit a bookmark")
    public static let BookmarksEditFolder = NSLocalizedString("Bookmarks.EditFolder.Label", value: "Edit Folder", comment: "The button to edit a folder")
    public static let BookmarksFolderName = NSLocalizedString("Bookmarks.FolderName.Label", value: "Folder Name", comment: "The label for the title of the new folder")
    public static let BookmarksFolderLocation = NSLocalizedString("Bookmarks.FolderLocation.Label", value: "Location", comment: "The label for the location of the new folder")
    public static let BookmarksDeleteFolderWarningTitle = NSLocalizedString("Bookmarks.DeleteFolderWarning.Title", tableName: "BookmarkPanelDeleteConfirm", value: "This folder isn’t empty.", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderWarningDescription = NSLocalizedString("Bookmarks.DeleteFolderWarning.Description", tableName: "BookmarkPanelDeleteConfirm", value: "Are you sure you want to delete it and its contents?", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderCancelButtonLabel = NSLocalizedString("Bookmarks.DeleteFolderWarning.CancelButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Cancel", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
    public static let BookmarksDeleteFolderDeleteButtonLabel = NSLocalizedString("Bookmarks.DeleteFolderWarning.DeleteButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Delete", comment: "Button label for the button that deletes a folder and all of its children.")
    public static let BookmarksPanelEmptyStateTitle = NSLocalizedString("BookmarksPanel.EmptyState.Title", value: "Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.")
    public static let BookmarksPanelDeleteTableAction = NSLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.")
    public static let BookmarkDetailFieldTitle = NSLocalizedString("Bookmark.DetailFieldTitle.Label", value: "Title", comment: "The label for the Title field when editing a bookmark")
    public static let BookmarkDetailFieldURL = NSLocalizedString("Bookmark.DetailFieldURL.Label", value: "URL", comment: "The label for the URL field when editing a bookmark")
    public static let BookmarkDetailFieldsHeaderBookmarkTitle = NSLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Bookmark.Title", value: "Bookmark", comment: "The header title for the fields when editing a Bookmark")
    public static let BookmarkDetailFieldsHeaderFolderTitle = NSLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Folder.Title", value: "Folder", comment: "The header title for the fields when editing a Folder")
}

// Tabs Delete All Undo Toast
extension Strings {
    public static let TabsDeleteAllUndoTitle = NSLocalizedString("Tabs.DeleteAllUndo.Title", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed")
    public static let TabsDeleteAllUndoAction = NSLocalizedString("Tabs.DeleteAllUndo.Button", value: "Undo", comment: "The button to undo the delete all tabs")
    public static let TabSearchPlaceholderText = NSLocalizedString("Tabs.Search.PlaceholderText", value: "Search Tabs", comment: "The placeholder text for the tab search bar")
}

//Clipboard Toast
extension Strings {
    public static let GoToCopiedLink = NSLocalizedString("ClipboardToast.GoToCopiedLink.Title", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard")
    public static let GoButtonTittle = NSLocalizedString("ClipboardToast.GoToCopiedLink.Button", value: "Go", comment: "The button to open a new tab with the copied link")

    public static let SettingsOfferClipboardBarTitle = NSLocalizedString("Settings.OfferClipboardBar.Title", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
    public static let SettingsOfferClipboardBarStatus = NSLocalizedString("Settings.OfferClipboardBar.Status", value: "When Opening Firefox", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
}

// Link Previews
extension Strings {
    public static let SettingsShowLinkPreviewsTitle = NSLocalizedString("Settings.ShowLinkPreviews.Title", value: "Show Link Previews", comment: "Title of setting to enable link previews when long-pressing links.")
    public static let SettingsShowLinkPreviewsStatus = NSLocalizedString("Settings.ShowLinkPreviews.Status", value: "When Long-pressing Links", comment: "Description displayed under the ”Show Link Previews” option")
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

// Download Helper
extension Strings {
    public static let OpenInDownloadHelperAlertDownloadNow = NSLocalizedString("Downloads.Alert.DownloadNow", value: "Download Now", comment: "The label of the button the user will press to start downloading a file")
    public static let DownloadsButtonTitle = NSLocalizedString("Downloads.Toast.GoToDownloads.Button", value: "Downloads", comment: "The button to open a new tab with the Downloads home panel")
    public static let CancelDownloadDialogTitle = NSLocalizedString("Downloads.CancelDialog.Title", value: "Cancel Download", comment: "Alert dialog title when the user taps the cancel download icon.")
    public static let CancelDownloadDialogMessage = NSLocalizedString("Downloads.CancelDialog.Message", value: "Are you sure you want to cancel this download?", comment: "Alert dialog body when the user taps the cancel download icon.")
    public static let CancelDownloadDialogResume = NSLocalizedString("Downloads.CancelDialog.Resume", value: "Resume", comment: "Button declining the cancellation of the download.")
    public static let CancelDownloadDialogCancel = NSLocalizedString("Downloads.CancelDialog.Cancel", value: "Cancel", comment: "Button confirming the cancellation of the download.")
    public static let DownloadCancelledToastLabelText = NSLocalizedString("Downloads.Toast.Cancelled.LabelText", value: "Download Cancelled", comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.")
    public static let DownloadFailedToastLabelText = NSLocalizedString("Downloads.Toast.Failed.LabelText", value: "Download Failed", comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.")
    public static let DownloadFailedToastButtonTitled = NSLocalizedString("Downloads.Toast.Failed.RetryButton", value: "Retry", comment: "The button to retry a failed download from the Download Failed toast.")
    public static let DownloadMultipleFilesToastDescriptionText = NSLocalizedString("Downloads.Toast.MultipleFiles.DescriptionText", value: "1 of %d files", comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.")
    public static let DownloadProgressToastDescriptionText = NSLocalizedString("Downloads.Toast.Progress.DescriptionText", value: "%1$@/%2$@", comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).")
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = NSLocalizedString("Downloads.Toast.MultipleFilesAndProgress.DescriptionText", value: "%1$@ %2$@", comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.")
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

// Page context menu items (i.e. links and images).
extension Strings {
    public static let ContextMenuOpenInNewTab = NSLocalizedString("ContextMenu.OpenInNewTabButtonTitle", value: "Open in New Tab", comment: "Context menu item for opening a link in a new tab")
    public static let ContextMenuOpenInNewPrivateTab = NSLocalizedString("ContextMenu.OpenInNewPrivateTabButtonTitle", tableName: "PrivateBrowsing", value: "Open in New Private Tab", comment: "Context menu option for opening a link in a new private tab")
    public static let ContextMenuBookmarkLink = NSLocalizedString("ContextMenu.BookmarkLinkButtonTitle", value: "Bookmark Link", comment: "Context menu item for bookmarking a link URL")
    public static let ContextMenuDownloadLink = NSLocalizedString("ContextMenu.DownloadLinkButtonTitle", value: "Download Link", comment: "Context menu item for downloading a link URL")
    public static let ContextMenuCopyLink = NSLocalizedString("ContextMenu.CopyLinkButtonTitle", value: "Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
    public static let ContextMenuShareLink = NSLocalizedString("ContextMenu.ShareLinkButtonTitle", value: "Share Link", comment: "Context menu item for sharing a link URL")
    public static let ContextMenuSaveImage = NSLocalizedString("ContextMenu.SaveImageButtonTitle", value: "Save Image", comment: "Context menu item for saving an image")
    public static let ContextMenuCopyImage = NSLocalizedString("ContextMenu.CopyImageButtonTitle", value: "Copy Image", comment: "Context menu item for copying an image to the clipboard")
    public static let ContextMenuCopyImageLink = NSLocalizedString("ContextMenu.CopyImageLinkButtonTitle", value: "Copy Image Link", comment: "Context menu item for copying an image URL to the clipboard")
}

// Photo Library access.
extension Strings {
    public static let PhotoLibraryFirefoxWouldLikeAccessTitle = NSLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessTitle", value: "Firefox would like to access your Photos", comment: "See http://mzl.la/1G7uHo7")
    public static let PhotoLibraryFirefoxWouldLikeAccessMessage = NSLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessMessage", value: "This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7")
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
    public static let ScanQRCodeInvalidDataErrorMessage = NSLocalizedString("ScanQRCode.InvalidDataError.Message", value: "The data is invalid", comment: "Text of the prompt that is shown to the user when the data is invalid")
    public static let ScanQRCodePermissionErrorMessage = NSLocalizedString("ScanQRCode.PermissionError.Message", value: "Please allow Firefox to access your device’s camera in ‘Settings’ -> ‘Privacy’ -> ‘Camera’.", comment: "Text of the prompt user to setup the camera authorization.")
    public static let ScanQRCodeErrorOKButton = NSLocalizedString("ScanQRCode.Error.OK.Button", value: "OK", comment: "OK button to dismiss the error prompt.")
}

// App menu.
extension Strings {
    public static let AppMenuLibraryReloadString = NSLocalizedString("Menu.Library.Reload", tableName: "Menu", value: "Reload", comment: "Label for the button, displayed in the menu, used to Reload the webpage")
    public static let AppMenuLibraryTitleString = NSLocalizedString("Menu.Library.Title", tableName: "Menu", value: "Your Library", comment: "Label for the button, displayed in the menu, used to open the Library")
    public static let AppMenuAddToReadingListTitleString = NSLocalizedString("Menu.AddToReadingList.Title", tableName: "Menu", value: "Add to Reading List", comment: "Label for the button, displayed in the menu, used to add a page to the reading list.")
    public static let AppMenuShowTabsTitleString = NSLocalizedString("Menu.ShowTabs.Title", tableName: "Menu", value: "Show Tabs", comment: "Label for the button, displayed in the menu, used to open the tabs tray")
    public static let AppMenuSharePageTitleString = NSLocalizedString("Menu.SharePageAction.Title", tableName: "Menu", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    public static let AppMenuCopyURLTitleString = NSLocalizedString("Menu.CopyAddress.Title", tableName: "Menu", value: "Copy Address", comment: "Label for the button, displayed in the menu, used to copy the page url to the clipboard.")
    public static let AppMenuNewTabTitleString = NSLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    public static let AppMenuNewPrivateTabTitleString = NSLocalizedString("Menu.NewPrivateTabAction.Title", tableName: "Menu", value: "Open New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.")
    public static let AppMenuAddBookmarkTitleString = NSLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuRemoveBookmarkTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    public static let AppMenuFindInPageTitleString = NSLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    public static let AppMenuViewDesktopSiteTitleString = NSLocalizedString("Menu.ViewDekstopSiteAction.Title", tableName: "Menu", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    public static let AppMenuViewMobileSiteTitleString = NSLocalizedString("Menu.ViewMobileSiteAction.Title", tableName: "Menu", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    public static let AppMenuTranslatePageTitleString = NSLocalizedString("Menu.TranslatePageAction.Title", tableName: "Menu", value: "Translate Page", comment: "Label for the button, displayed in the menu, used to translate the current page.")
    public static let AppMenuScanQRCodeTitleString = NSLocalizedString("Menu.ScanQRCodeAction.Title", tableName: "Menu", value: "Scan QR Code", comment: "Label for the button, displayed in the menu, used to open the QR code scanner.")
    public static let AppMenuSettingsTitleString = NSLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    public static let AppMenuCloseAllTabsTitleString = NSLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    public static let AppMenuOpenHomePageTitleString = NSLocalizedString("Menu.OpenHomePageAction.Title", tableName: "Menu", value: "Home", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    public static let AppMenuTopSitesTitleString = NSLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    public static let AppMenuBookmarksTitleString = NSLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel.v2", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuReadingListTitleString = NSLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel.v2", tableName: "Menu", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuHistoryTitleString = NSLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel.v2", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuDownloadsTitleString = NSLocalizedString("Menu.OpenDownloadsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Downloads", comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuSyncedTabsTitleString = NSLocalizedString("Menu.OpenSyncedTabsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Synced Tabs", comment: "Accessibility label for the button, displayed in the menu, used to open the Synced Tabs home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuLibrarySeeAllTitleString = NSLocalizedString("Menu.SeeAllAction.Title", tableName: "Menu", value: "See All", comment: "Label for the button, displayed in Firefox Home, used to see all Library panels.")
    public static let AppMenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
    public static let TabTrayDeleteMenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.CloseAllTabs", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.")
    public static let AppMenuNightMode = NSLocalizedString("Menu.NightModeTurnOn.Label", value: "Enable Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.")
    public static let AppMenuNoImageMode = NSLocalizedString("Menu.NoImageModeBlockImages.Label", value: "Block Images", comment: "Label for the button, displayed in the menu, hides images on the webpage when pressed.")
    public static let AppMenuCopyURLConfirmMessage = NSLocalizedString("Menu.CopyURL.Confirm", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.")
    public static let AppMenuAddBookmarkConfirmMessage = NSLocalizedString("Menu.AddBookmark.Confirm", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.")
    public static let AppMenuTabSentConfirmMessage = NSLocalizedString("Menu.TabSent.Confirm", value: "Tab Sent", comment: "Toast displayed to the user after a tab has been sent successfully.")
    public static let AppMenuRemoveBookmarkConfirmMessage = NSLocalizedString("Menu.RemoveBookmark.Confirm", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.")
    public static let AppMenuAddPinToTopSitesConfirmMessage = NSLocalizedString("Menu.AddPin.Confirm", value: "Pinned To Top Sites", comment: "Toast displayed to the user after adding the item to the Top Sites.")
    public static let AppMenuRemovePinFromTopSitesConfirmMessage = NSLocalizedString("Menu.RemovePin.Confirm", value: "Removed From Top Sites", comment: "Toast displayed to the user after removing the item from the Top Sites.")
    public static let AppMenuAddToReadingListConfirmMessage = NSLocalizedString("Menu.AddToReadingList.Confirm", value: "Added To Reading List", comment: "Toast displayed to the user after adding the item to their reading list.")
    public static let SendToDeviceTitle = NSLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device")
    public static let PageActionMenuTitle = NSLocalizedString("Menu.PageActions.Title", value: "Page Actions", comment: "Label for title in page action menu.")
    public static let WhatsNewString = NSLocalizedString("Menu.WhatsNew.Title", value: "What's New", comment: "The title for the option to view the What's new page.")
    public static let AppMenuShowPageSourceString = NSLocalizedString("Menu.PageSourceAction.Title", tableName: "Menu", value: "View Page Source", comment: "Label for the button, displayed in the menu, used to show the html page source")
}

// Snackbar shown when tapping app store link
extension Strings {
    public static let ExternalLinkAppStoreConfirmationTitle = NSLocalizedString("ExternalLink.AppStore.ConfirmationTitle", value: "Open this link in the App Store?", comment: "Question shown to user when tapping a link that opens the App Store app")
    public static let ExternalLinkGenericConfirmation = NSLocalizedString("ExternalLink.AppStore.GenericConfirmationTitle", value: "Open this link in external app?", comment: "Question shown to user when tapping an SMS or MailTo link that opens the external app for those.")
}

// ContentBlocker/TrackingProtection strings
extension Strings {
    public static let SettingsTrackingProtectionSectionName = NSLocalizedString("Settings.TrackingProtection.SectionName", value: "Tracking Protection", comment: "Row in top-level of settings that gets tapped to show the tracking protection settings detail view.")

    public static let TrackingProtectionEnableTitle = NSLocalizedString("Settings.TrackingProtectionOption.NormalBrowsingLabelOn", value: "Enhanced Tracking Protection", comment: "Settings option to specify that Tracking Protection is on")

    public static let TrackingProtectionOptionOnOffFooter = NSLocalizedString("Settings.TrackingProtectionOption.EnabledStateFooterLabel", value: "Tracking is the collection of your browsing data across multiple websites.", comment: "Description label shown on tracking protection options screen.")
    public static let TrackingProtectionOptionProtectionLevelTitle = NSLocalizedString("Settings.TrackingProtection.ProtectionLevelTitle", value: "Protection Level", comment: "Title for tracking protection options section where level can be selected.")
    public static let TrackingProtectionOptionBlockListsHeader = NSLocalizedString("Settings.TrackingProtection.BlockListsHeader", value: "You can choose which list Firefox will use to block Web elements that may track your browsing activity.", comment: "Header description for tracking protection options section where Basic/Strict block list can be selected")
    public static let TrackingProtectionOptionBlockListLevelStandard = NSLocalizedString("Settings.TrackingProtectionOption.BasicBlockList", value: "Standard (default)", comment: "Tracking protection settings option for using the basic blocklist.")
   // public static let TrackingProtectionOptionBlockListLevelStandardDescription = NSLocalizedString("Settings.TrackingProtectionOption.BlockListBasicDescription", value: "Allows some trackers so websites function properly.", comment: "Tracking protection settings option description for using the basic blocklist.")
    public static let TrackingProtectionOptionBlockListLevelStrict = NSLocalizedString("Settings.TrackingProtectionOption.BlockListStrict", value: "Strict", comment: "Tracking protection settings option for using the strict blocklist.")
   // public static let TrackingProtectionOptionBlockListLevelStrictDescription = NSLocalizedString("Settings.TrackingProtectionOption.BlockListStrictDescription", value: "Blocks known trackers. Some websites may not function properly.", comment: "Tracking protection settings option description for using the strict blocklist.")
    public static let TrackingProtectionReloadWithout = NSLocalizedString("Menu.ReloadWithoutTrackingProtection.Title", value: "Reload Without Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website without Tracking Protection")
    public static let TrackingProtectionReloadWith = NSLocalizedString("Menu.ReloadWithTrackingProtection.Title", value: "Reload With Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website with Tracking Protection enabled")

    public static let TrackingProtectionProtectionStrictInfoFooter = NSLocalizedString("Settings.TrackingProtection.StrictLevelInfoFooter", value: "Blocking trackers could impact the functionality of some websites.", comment: "Additional information about the strict level setting")
    public static let TrackingProtectionCellFooter = NSLocalizedString("Settings.TrackingProtection.ProtectionCellFooter", value: "Reduces targeted ads and helps stop advertisers from tracking your browsing.", comment: "Additional information about your Enhanced Tracking Protection")
    public static let TrackingProtectionStandardLevelDescription = NSLocalizedString("Settings.TrackingProtection.ProtectionLevelStandard.Description", value: "Allows some ad tracking so websites function properly.", comment: "Description for standard level tracker protection")
    public static let TrackingProtectionStrictLevelDescription = NSLocalizedString("Settings.TrackingProtection.ProtectionLevelStrict.Description", value: "Blocks more trackers, ads, and popups. Pages load faster, but some functionality may not work.", comment: "Description for strict level tracker protection")
    public static let TrackingProtectionLevelFooter = NSLocalizedString("Settings.TrackingProtection.ProtectionLevel.Footer", value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.", comment: "Footer information for tracker protection level.")
    public static let TrackerProtectionLearnMore = NSLocalizedString("Settings.TrackingProtection.LearnMore", value: "Learn more", comment: "'Learn more' info link on the Tracking Protection settings screen.")
    public static let TrackerProtectionAlertTitle =  NSLocalizedString("Settings.TrackingProtection.Alert.Title", value: "Heads up!", comment: "Title for the tracker protection alert.")
    public static let TrackerProtectionAlertDescription =  NSLocalizedString("Settings.TrackingProtection.Alert.Description", value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.", comment: "Decription for the tracker protection alert.")
    public static let TrackerProtectionAlertButton =  NSLocalizedString("Settings.TrackingProtection.Alert.Button", value: "OK, Got It", comment: "Dismiss button for the tracker protection alert.")
}

// Tracking Protection menu
extension Strings {
    public static let TPBlockingDescription = NSLocalizedString("Menu.TrackingProtectionBlocking.Description", value: "Firefox is blocking parts of the page that may track your browsing.", comment: "Description of the Tracking protection menu when TP is blocking parts of the page")
    public static let TPNoBlockingDescription = NSLocalizedString("Menu.TrackingProtectionNoBlocking.Description", value: "No tracking elements detected on this page.", comment: "The description of the Tracking Protection menu item when no scripts are blocked but tracking protection is enabled.")
    public static let TPBlockingDisabledDescription = NSLocalizedString("Menu.TrackingProtectionBlockingDisabled.Description", value: "Block online trackers", comment: "The description of the Tracking Protection menu item when tracking is enabled")
    public static let TPBlockingMoreInfo = NSLocalizedString("Menu.TrackingProtectionMoreInfo.Description", value: "Learn more about how Tracking Protection blocks online trackers that collect your browsing data across multiple websites.", comment: "more info about what tracking protection is about")
    public static let EnableTPBlockingGlobally = NSLocalizedString("Menu.TrackingProtectionEnable.Title", value: "Enable Tracking Protection", comment: "A button to enable tracking protection inside the menu.")
    public static let TPBlockingSiteEnabled = NSLocalizedString("Menu.TrackingProtectionEnable1.Title", value: "Enabled for this site", comment: "A button to enable tracking protection inside the menu.")
    public static let TPEnabledConfirmed = NSLocalizedString("Menu.TrackingProtectionEnabled.Title", value: "Tracking Protection is now on for this site.", comment: "The confirmation toast once tracking protection has been enabled")
    public static let TPDisabledConfirmed = NSLocalizedString("Menu.TrackingProtectionDisabled.Title", value: "Tracking Protection is now off for this site.", comment: "The confirmation toast once tracking protection has been disabled")
    public static let TPBlockingSiteDisabled = NSLocalizedString("Menu.TrackingProtectionDisable1.Title", value: "Disabled for this site", comment: "The button that disabled TP for a site.")
    public static let ETPOn = NSLocalizedString("Menu.EnhancedTrackingProtectionOn.Title", value: "Enhanced Tracking Protection is ON for this site.", comment: "A switch to enable enhanced tracking protection inside the menu.")
    public static let ETPOff = NSLocalizedString("Menu.EnhancedTrackingProtectionOff.Title", value: "Enhanced Tracking Protection is OFF for this site.", comment: "A switch to disable enhanced tracking protection inside the menu.")

    // TP Page menu title
    public static let TPPageMenuTitle = NSLocalizedString("Menu.TrackingProtection.TitlePrefix", value: "Protections for %@", comment: "Title on tracking protection menu showing the domain. eg. Protections for mozilla.org")
    public static let TPPageMenuNoTrackersBlocked = NSLocalizedString("Menu.TrackingProtection.NoTrackersBlockedTitle", value: "No trackers known to Firefox were detected on this page.", comment: "Message in menu when no trackers blocked.")
    public static let TPPageMenuBlockedTitle = NSLocalizedString("Menu.TrackingProtection.BlockedTitle", value: "Blocked", comment: "Title on tracking protection menu for blocked items.")

    // Category Titles
    public static let TPCryptominersBlocked = NSLocalizedString("Menu.TrackingProtectionCryptominersBlocked.Title", value: "Cryptominers", comment: "The title that shows the number of cryptomining scripts blocked")
    public static let TPFingerprintersBlocked = NSLocalizedString("Menu.TrackingProtectionFingerprintersBlocked.Title", value: "Fingerprinters", comment: "The title that shows the number of fingerprinting scripts blocked")
    public static let TPCrossSiteCookiesBlocked = NSLocalizedString("Menu.TrackingProtectionCrossSiteCookies.Title", value: "Cross-Site Tracking Cookies", comment: "The title that shows the number of cross-site cookies blocked")
    public static let TPCrossSiteBlocked = NSLocalizedString("Menu.TrackingProtectionCrossSiteTrackers.Title", value: "Cross-Site Trackers", comment: "The title that shows the number of cross-site URLs blocked")
    public static let TPSocialBlocked = NSLocalizedString("Menu.TrackingProtectionBlockedSocial.Title", value: "Social Trackers", comment: "The title that shows the number of social URLs blocked")
    public static let TPContentBlocked = NSLocalizedString("Menu.TrackingProtectionBlockedContent.Title", value: "Tracking content", comment: "The title that shows the number of content cookies blocked")

    // Shortcut on bottom of TP page menu to get to settings.
    public static let TPProtectionSettings = NSLocalizedString("Menu.TrackingProtection.ProtectionSettings.Title", value: "Protection Settings", comment: "The title for tracking protection settings")

    // Remove if unused -->
    public static let TPListTitle_CrossSiteCookies = NSLocalizedString("Menu.TrackingProtectionListTitle.CrossSiteCookies", value: "Blocked Cross-Site Tracking Cookies", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`")
    public static let TPListTitle_Social = NSLocalizedString("Menu.TrackingProtectionListTitle.Social", value: "Blocked Social Trackers", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`")
    public static let TPListTitle_Fingerprinters = NSLocalizedString("Menu.TrackingProtectionListTitle.Fingerprinters", value: "Blocked Fingerprinters", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`")
    public static let TPListTitle_Cryptominer = NSLocalizedString("Menu.TrackingProtectionListTitle.Cryptominers", value: "Blocked Cryptominers", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`")
    /// <--

    public static let TPSafeListOn = NSLocalizedString("Menu.TrackingProtectionOption.WhiteListOnDescription", value: "The site includes elements that may track your browsing. You have disabled protection.", comment: "label for the menu item to show when the website is whitelisted from blocking trackers.")
    public static let TPSafeListRemove = NSLocalizedString("Menu.TrackingProtectionWhitelistRemove.Title", value: "Enable for this site", comment: "label for the menu item that lets you remove a website from the tracking protection whitelist")

    // Settings info
    public static let TPAccessoryInfoTitleStrict = NSLocalizedString("Settings.TrackingProtection.Info.StrictTitle", value: "Offers stronger protection, but may cause some sites to break.", comment: "Explanation of strict mode.")
    public static let TPAccessoryInfoTitleBasic = NSLocalizedString("Settings.TrackingProtection.Info.BasicTitle", value: "Balanced for protection and performance.", comment: "Explanation of basic mode.")
    public static let TPAccessoryInfoBlocksTitle = NSLocalizedString("Settings.TrackingProtection.Info.BlocksTitle", value: "BLOCKS", comment: "The Title on info view which shows a list of all blocked websites")

    // Category descriptions
    public static let TPCategoryDescriptionSocial = NSLocalizedString("Menu.TrackingProtectionDescription.SocialNetworksNew", value: "Social networks place trackers on other websites to build a more complete and targeted profile of you. Blocking these trackers reduces how much social media companies can see what do you online.", comment: "Description of social network trackers.")
    public static let TPCategoryDescriptionCrossSite = NSLocalizedString("Menu.TrackingProtectionDescription.CrossSiteNew", value: "These cookies follow you from site to site to gather data about what you do online. They are set by third parties such as advertisers and analytics companies.", comment: "Description of cross-site trackers.")
    public static let TPCategoryDescriptionCryptominers = NSLocalizedString("Menu.TrackingProtectionDescription.CryptominersNew", value: "Cryptominers secretly use your system’s computing power to mine digital money. Cryptomining scripts drain your battery, slow down your computer, and can increase your energy bill.", comment: "Description of cryptominers.")
    public static let TPCategoryDescriptionFingerprinters = NSLocalizedString("Menu.TrackingProtectionDescription.Fingerprinters", value: "The settings on your browser and computer are unique. Fingerprinters collect a variety of these unique settings to create a profile of you, which can be used to track you as you browse.", comment: "Description of fingerprinters.")
    public static let TPCategoryDescriptionContentTrackers = NSLocalizedString("Menu.TrackingProtectionDescription.ContentTrackers", value: "Websites may load outside ads, videos, and other content that contains hidden trackers. Blocking this can make websites load faster, but some buttons, forms, and login fields, might not work.", comment: "Description of content trackers.")

    public static let TPMoreInfo = NSLocalizedString("Settings.TrackingProtection.MoreInfo", value: "More Info…", comment: "'More Info' link on the Tracking Protection settings screen.")
}

// Location bar long press menu
extension Strings {
    public static let PasteAndGoTitle = NSLocalizedString("Menu.PasteAndGo.Title", value: "Paste & Go", comment: "The title for the button that lets you paste and go to a URL")
    public static let PasteTitle = NSLocalizedString("Menu.Paste.Title", value: "Paste", comment: "The title for the button that lets you paste into the location bar")
    public static let CopyAddressTitle = NSLocalizedString("Menu.Copy.Title", value: "Copy Address", comment: "The title for the button that lets you copy the url from the location bar.")
}

// Settings Home
extension Strings {
    public static let SendUsageSettingTitle = NSLocalizedString("Settings.SendUsage.Title", value: "Send Usage Data", comment: "The title for the setting to send usage data.")
    public static let SendUsageSettingLink = NSLocalizedString("Settings.SendUsage.Link", value: "Learn More.", comment: "title for a link that explains how mozilla collects telemetry")
    public static let SendUsageSettingMessage = NSLocalizedString("Settings.SendUsage.Message", value: "Mozilla strives to only collect what we need to provide and improve Firefox for everyone.", comment: "A short description that explains why mozilla collects usage data.")
    public static let SettingsSiriSectionName = NSLocalizedString("Settings.Siri.SectionName", value: "Siri Shortcuts", comment: "The option that takes you to the siri shortcuts settings page")
    public static let SettingsSiriSectionDescription = NSLocalizedString("Settings.Siri.SectionDescription", value: "Use Siri shortcuts to quickly open Firefox via Siri", comment: "The description that describes what siri shortcuts are")
    public static let SettingsSiriOpenURL = NSLocalizedString("Settings.Siri.OpenTabShortcut", value: "Open New Tab", comment: "The description of the open new tab siri shortcut")
}

// Do not track
extension Strings {
    public static let SettingsDoNotTrackTitle = NSLocalizedString("Settings.DNT.Title", value: "Send websites a Do Not Track signal that you don’t want to be tracked", comment: "DNT Settings title")
    public static let SettingsDoNotTrackOptionOnWithTP = NSLocalizedString("Settings.DNT.OptionOnWithTP", value: "Only when using Tracking Protection", comment: "DNT Settings option for only turning on when Tracking Protection is also on")
    public static let SettingsDoNotTrackOptionAlwaysOn = NSLocalizedString("Settings.DNT.OptionAlwaysOn", value: "Always", comment: "DNT Settings option for always on")
}

// Intro Onboarding slides
extension Strings {
    // First Card
    public static let CardTitleWelcome = NSLocalizedString("Intro.Slides.Welcome.Title.v2", tableName: "Intro", value: "Welcome to Firefox", comment: "Title for the first panel 'Welcome' in the First Run tour.")
    public static let CardTitleAutomaticPrivacy = NSLocalizedString("Intro.Slides.Automatic.Privacy.Title", tableName: "Intro", value: "Automatic Privacy", comment: "Title for the first item in the table related to automatic privacy")
    public static let CardDescriptionAutomaticPrivacy = NSLocalizedString("Intro.Slides.Automatic.Privacy.Description", tableName: "Intro", value: "Enhanced Tracking Protection blocks malware and stops trackers.", comment: "Description for the first item in the table related to automatic privacy")
    public static let CardTitleFastSearch = NSLocalizedString("Intro.Slides.Fast.Search.Title", tableName: "Intro", value: "Fast Search", comment: "Title for the second item in the table related to fast searching via address bar")
    public static let CardDescriptionFastSearch = NSLocalizedString("Intro.Slides.Fast.Search.Description", tableName: "Intro", value: "Search suggestions get you to websites faster.", comment: "Description for the second item in the table related to fast searching via address bar")
    public static let CardTitleSafeSync = NSLocalizedString("Intro.Slides.Safe.Sync.Title", tableName: "Intro", value: "Safe Sync", comment: "Title for the third item in the table related to safe syncing with a firefox account")
    public static let CardDescriptionSafeSync = NSLocalizedString("Intro.Slides.Safe.Sync.Description", tableName: "Intro", value: "Protect your logins and data everywhere you use Firefox.", comment: "Description for the third item in the table related to safe syncing with a firefox account")
    
    // Second Card
    public static let CardTitleFxASyncDevices = NSLocalizedString("Intro.Slides.Firefox.Account.Sync.Title", tableName: "Intro", value: "Sync Firefox Between Devices", comment: "Title for the first item in the table related to syncing data (bookmarks, history) via firefox account between devices")
    public static let CardDescriptionFxASyncDevices = NSLocalizedString("Intro.Slides.Firefox.Account.Sync.Description", tableName: "Intro", value: "Bring bookmarks, history, and passwords to Firefox on this device.", comment: "Description for the first item in the table related to syncing data (bookmarks, history) via firefox account between devices")
    
    //----Other----//
    public static let CardTitleSearch = NSLocalizedString("Intro.Slides.Search.Title", tableName: "Intro", value: "Your search, your way", comment: "Title for the second  panel 'Search' in the First Run tour.")
    public static let CardTitlePrivate = NSLocalizedString("Intro.Slides.Private.Title", tableName: "Intro", value: "Browse like no one’s watching", comment: "Title for the third panel 'Private Browsing' in the First Run tour.")
    public static let CardTitleMail = NSLocalizedString("Intro.Slides.Mail.Title", tableName: "Intro", value: "You’ve got mail… options", comment: "Title for the fourth panel 'Mail' in the First Run tour.")
    public static let CardTitleSync = NSLocalizedString("Intro.Slides.TrailheadSync.Title.v2", tableName: "Intro", value: "Sync your bookmarks, history, and passwords to your phone.", comment: "Title for the second panel 'Sync' in the First Run tour.")

    public static let CardTextWelcome = NSLocalizedString("Intro.Slides.Welcome.Description.v2", tableName: "Intro", value: "Fast, private, and on your side.", comment: "Description for the 'Welcome' panel in the First Run tour.")
    public static let CardTextSearch = NSLocalizedString("Intro.Slides.Search.Description", tableName: "Intro", value: "Searching for something different? Choose another default search engine (or add your own) in Settings.", comment: "Description for the 'Favorite Search Engine' panel in the First Run tour.")
    public static let CardTextPrivate = NSLocalizedString("Intro.Slides.Private.Description", tableName: "Intro", value: "Tap the mask icon to slip into Private Browsing mode.", comment: "Description for the 'Private Browsing' panel in the First Run tour.")
    public static let CardTextMail = NSLocalizedString("Intro.Slides.Mail.Description", tableName: "Intro", value: "Use any email app — not just Mail — with Firefox.", comment: "Description for the 'Mail' panel in the First Run tour.")
    public static let CardTextSync = NSLocalizedString("Intro.Slides.TrailheadSync.Description", tableName: "Intro", value: "Sign in to your account to sync and access more features.", comment: "Description for the 'Sync' panel in the First Run tour.")
    public static let SignInButtonTitle = NSLocalizedString("Turn on Sync…", tableName: "Intro", comment: "The button that opens the sign in page for sync. See http://mzl.la/1T8gxwo")
    public static let StartBrowsingButtonTitle = NSLocalizedString("Start Browsing", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    public static let IntroNextButtonTitle = NSLocalizedString("Intro.Slides.Button.Next", tableName: "Intro", value: "Next", comment: "Next button on the first intro screen.")
    public static let IntroSignInButtonTitle = NSLocalizedString("Intro.Slides.Button.SignIn", tableName: "Intro", value: "Sign In", comment: "Sign in to Firefox account button on second intro screen.")
    public static let IntroSignUpButtonTitle = NSLocalizedString("Intro.Slides.Button.SignUp", tableName: "Intro", value: "Sign Up", comment: "Sign up to Firefox account button on second intro screen.")
}

// Keyboard short cuts
extension Strings {
    public static let ShowTabTrayFromTabKeyCodeTitle = NSLocalizedString("Tab.ShowTabTray.KeyCodeTitle", value: "Show All Tabs", comment: "Hardware shortcut to open the tab tray from a tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTray.CloseTab.KeyCodeTitle", value: "Close Selected Tab", comment: "Hardware shortcut to close the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseAllTabsFromTabTrayKeyCodeTitle = NSLocalizedString("TabTray.CloseAllTabs.KeyCodeTitle", value: "Close All Tabs", comment: "Hardware shortcut to close all tabs from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenSelectedTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTray.OpenSelectedTab.KeyCodeTitle", value: "Open Selected Tab", comment: "Hardware shortcut open the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenNewTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTray.OpenNewTab.KeyCodeTitle", value: "Open New Tab", comment: "Hardware shortcut to open a new tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let ReopenClosedTabKeyCodeTitle = NSLocalizedString("ReopenClosedTab.KeyCodeTitle", value: "Reopen Closed Tab", comment: "Hardware shortcut to reopen the last closed tab, from the tab or the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToPBMKeyCodeTitle = NSLocalizedString("SwitchToPBM.KeyCodeTitle", value: "Private Browsing Mode", comment: "Hardware shortcut switch to the private browsing tab or tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToNonPBMKeyCodeTitle = NSLocalizedString("SwitchToNonPBM.KeyCodeTitle", value: "Normal Browsing Mode", comment: "Hardware shortcut for non-private tab or tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
}

// Share extension
extension Strings {
    public static let SendToCancelButton = NSLocalizedString("SendTo.Cancel.Button", bundle: applicationBundle(), value: "Cancel", comment: "Button title for cancelling share screen")
    public static let SendToErrorOKButton = NSLocalizedString("SendTo.Error.OK.Button", bundle: applicationBundle(), value: "OK", comment: "OK button to dismiss the error prompt.")
    public static let SendToErrorTitle = NSLocalizedString("SendTo.Error.Title", bundle: applicationBundle(), value: "The link you are trying to share cannot be shared.", comment: "Title of error prompt displayed when an invalid URL is shared.")
    public static let SendToErrorMessage = NSLocalizedString("SendTo.Error.Message", bundle: applicationBundle(), value: "Only HTTP and HTTPS links can be shared.", comment: "Message in error prompt explaining why the URL is invalid.")
    public static let SendToCloseButton = NSLocalizedString("SendTo.Cancel.Button", bundle: applicationBundle(), value: "Close", comment: "Close button in top navigation bar")
    public static let SendToNotSignedInText = NSLocalizedString("SendTo.NotSignedIn.Title", bundle: applicationBundle(), value: "You are not signed in to your Firefox Account.", comment: "See http://mzl.la/1ISlXnU")
    public static let SendToNotSignedInMessage = NSLocalizedString("SendTo.NotSignedIn.Message", bundle: applicationBundle(), value: "Please open Firefox, go to Settings and sign in to continue.", comment: "See http://mzl.la/1ISlXnU")
    public static let SendToNoDevicesFound = NSLocalizedString("SendTo.NoDevicesFound.Message", bundle: applicationBundle(), value: "You don’t have any other devices connected to this Firefox Account available to sync.", comment: "Error message shown in the remote tabs panel")
    public static let SendToTitle = NSLocalizedString("SendTo.NavBar.Title", bundle: applicationBundle(), value: "Send Tab", comment: "Title of the dialog that allows you to send a tab to a different device")
    public static let SendToSendButtonTitle = NSLocalizedString("SendTo.SendAction.Text", bundle: applicationBundle(), value: "Send", comment: "Navigation bar button to Send the current page to a device")
    public static let SendToDevicesListTitle = NSLocalizedString("SendTo.DeviceList.Text", bundle: applicationBundle(), value: "Available devices:", comment: "Header for the list of devices table")
    public static let ShareSendToDevice = Strings.SendToDeviceTitle

    // The above items are re-used strings from the old extension. New strings below.

    public static let ShareAddToReadingList = NSLocalizedString("ShareExtension.AddToReadingListAction.Title", value: "Add to Reading List", comment: "Action label on share extension to add page to the Firefox reading list.")
    public static let ShareAddToReadingListDone = NSLocalizedString("ShareExtension.AddToReadingListActionDone.Title", value: "Added to Reading List", comment: "Share extension label shown after user has performed 'Add to Reading List' action.")
    public static let ShareBookmarkThisPage = NSLocalizedString("ShareExtension.BookmarkThisPageAction.Title", value: "Bookmark This Page", comment: "Action label on share extension to bookmark the page in Firefox.")
    public static let ShareBookmarkThisPageDone = NSLocalizedString("ShareExtension.BookmarkThisPageActionDone.Title", value: "Bookmarked", comment: "Share extension label shown after user has performed 'Bookmark this Page' action.")

    public static let ShareOpenInFirefox = NSLocalizedString("ShareExtension.OpenInFirefoxAction.Title", value: "Open in Firefox", comment: "Action label on share extension to immediately open page in Firefox.")
    public static let ShareSearchInFirefox = NSLocalizedString("ShareExtension.SeachInFirefoxAction.Title", value: "Search in Firefox", comment: "Action label on share extension to search for the selected text in Firefox.")
    public static let ShareOpenInPrivateModeNow = NSLocalizedString("ShareExtension.OpenInPrivateModeAction.Title", value: "Open in Private Mode", comment: "Action label on share extension to immediately open page in Firefox in private mode.")

    public static let ShareLoadInBackground = NSLocalizedString("ShareExtension.LoadInBackgroundAction.Title", value: "Load in Background", comment: "Action label on share extension to load the page in Firefox when user switches apps to bring it to foreground.")
    public static let ShareLoadInBackgroundDone = NSLocalizedString("ShareExtension.LoadInBackgroundActionDone.Title", value: "Loading in Firefox", comment: "Share extension label shown after user has performed 'Load in Background' action.")

}

//passwordAutofill extension
extension Strings {
    public static let PasswordAutofillTitle = NSLocalizedString("PasswordAutoFill.SectionTitle", value: "Firefox Credentials", comment: "Title of the extension that shows firefox passwords")
    public static let CredentialProviderNoCredentialError = NSLocalizedString("PasswordAutoFill.NoPasswordsFoundTitle", value: "You don’t have any credentials synced from your Firefox Account", comment: "Error message shown in the remote tabs panel")
    public static let AvailableCredentialsHeader = NSLocalizedString("PasswordAutoFill.PasswordsListTitle", value: "Available Credentials:", comment: "Header for the list of credentials table")
}

// translation bar
extension Strings {
    public static let TranslateSnackBarPrompt = NSLocalizedString("TranslationToastHandler.PromptTranslate.Title", value: "This page appears to be in %1$@. Translate to %2$@ with %3$@?", comment: "Prompt for translation. The first parameter is the language the page is in. The second parameter is the name of our local language. The third is the name of the service.")
    public static let TranslateSnackBarYes = NSLocalizedString("TranslationToastHandler.PromptTranslate.OK", value: "Yes", comment: "Button to allow the page to be translated to the user locale language")
    public static let TranslateSnackBarNo = NSLocalizedString("TranslationToastHandler.PromptTranslate.Cancel", value: "No", comment: "Button to disallow the page to be translated to the user locale language")

    public static let SettingTranslateSnackBarSectionHeader = NSLocalizedString("Settings.TranslateSnackBar.SectionHeader", value: "Services", comment: "Translation settings section title")
    public static let SettingTranslateSnackBarSectionFooter = NSLocalizedString("Settings.TranslateSnackBar.SectionFooter", value: "The web page language is detected on the device, and a translation from a remote service is offered.", comment: "Translation settings footer describing how language detection and translation happens.")
    public static let SettingTranslateSnackBarTitle = NSLocalizedString("Settings.TranslateSnackBar.Title", value: "Translation", comment: "Title in main app settings for Translation toast settings")
    public static let SettingTranslateSnackBarSwitchTitle = NSLocalizedString("Settings.TranslateSnackBar.SwitchTitle", value: "Offer Translation", comment: "Switch to choose if the language of a page is detected and offer to translate.")
    public static let SettingTranslateSnackBarSwitchSubtitle = NSLocalizedString("Settings.TranslateSnackBar.SwitchSubtitle", value: "Offer to translate any site written in a language that is different from your default language.", comment: "Switch to choose if the language of a page is detected and offer to translate.")
}

// Display Theme
extension Strings {
    public static let SettingsDisplayThemeTitle = NSLocalizedString("Settings.DisplayTheme.Title.v2", value: "Theme", comment: "Title in main app settings for Theme settings")
    public static let DisplayThemeBrightnessThresholdSectionHeader = NSLocalizedString("Settings.DisplayTheme.BrightnessThreshold.SectionHeader", value: "Threshold", comment: "Section header for brightness slider.")
    public static let DisplayThemeSectionFooter = NSLocalizedString("Settings.DisplayTheme.SectionFooter", value: "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes. The circle indicates your display's current brightness.", comment: "Display (theme) settings footer describing how the brightness slider works.")
    public static let SystemThemeSectionHeader = NSLocalizedString("Settings.DisplayTheme.SystemTheme.SectionHeader", value: "System Theme", comment: "System theme settings section title")
    public static let SystemThemeSectionSwitchTitle = NSLocalizedString("Settings.DisplayTheme.SystemTheme.SwitchTitle", value: "Use System Light/Dark Mode", comment: "System theme settings switch to choose whether to use the same theme as the system")
    public static let ThemeSwitchModeSectionHeader = NSLocalizedString("Settings.DisplayTheme.SwitchMode.SectionHeader", value: "Switch Mode", comment: "Switch mode settings section title")
    public static let ThemePickerSectionHeader = NSLocalizedString("Settings.DisplayTheme.ThemePicker.SectionHeader", value: "Theme Picker", comment: "Theme picker settings section title")
    public static let DisplayThemeAutomaticSwitchTitle = NSLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatically", comment: "Display (theme) settings switch to choose whether to set the dark mode manually, or automatically based on the brightness slider.")
    public static let DisplayThemeAutomaticStatusLabel = NSLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatic", comment: "Display (theme) settings label to show if automatically switch theme is enabled.")
    public static let DisplayThemeAutomaticSwitchSubtitle = NSLocalizedString("Settings.DisplayTheme.SwitchSubtitle", value: "Switch automatically based on screen brightness", comment: "Display (theme) settings switch subtitle, explaining the title 'Automatically'.")
    public static let DisplayThemeManualSwitchTitle = NSLocalizedString("Settings.DisplayTheme.Manual.SwitchTitle", value: "Manually", comment: "Display (theme) setting to choose the theme manually.")
    public static let DisplayThemeManualSwitchSubtitle = NSLocalizedString("Settings.DisplayTheme.Manual.SwitchSubtitle", value: "Pick which theme you want", comment: "Display (theme) settings switch subtitle, explaining the title 'Manually'.")
    public static let DisplayThemeManualStatusLabel = NSLocalizedString("Settings.DisplayTheme.Manual.StatusLabel", value: "Manual", comment: "Display (theme) settings label to show if manually switch theme is enabled.")
    public static let DisplayThemeOptionLight = NSLocalizedString("Settings.DisplayTheme.OptionLight", value: "Light", comment: "Option choice in display theme settings for light theme")
    public static let DisplayThemeOptionDark = NSLocalizedString("Settings.DisplayTheme.OptionDark", value: "Dark", comment: "Option choice in display theme settings for dark theme")
}

extension Strings {
    public static let AddTabAccessibilityLabel = NSLocalizedString("TabTray.AddTab.Button", value: "Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
}

// Cover Sheet
extension Strings {
    // Dark Mode Cover Sheet
    public static let CoverSheetV22DarkModeTitle = NSLocalizedString("CoverSheet.v22.DarkMode.Title", value: "Dark theme now includes a dark keyboard and dark splash screen.", comment: "Title for the new dark mode change in the version 22 app release.")
    public static let CoverSheetV22DarkModeDescription = NSLocalizedString("CoverSheet.v22.DarkMode.Description", value: "For iOS 13 users, Firefox now automatically switches to a dark theme when your phone is set to Dark Mode. To change this behavior, go to Settings > Theme.", comment: "Description for the new dark mode change in the version 22 app release. It describes the new automatic dark theme and how to change the theme settings.")
    
    // ETP Cover Sheet
    public static let CoverSheetETPTitle = NSLocalizedString("CoverSheet.v24.ETP.Title", value: "Protection Against Ad Tracking", comment: "Title for the new ETP mode i.e. standard vs strict")
    public static let CoverSheetETPDescription = NSLocalizedString("CoverSheet.v24.ETP.Description", value: "Built-in Enhanced Tracking Protection helps stop ads from following you around. Turn on Strict to block even more trackers, ads, and popups. ", comment: "Description for the new ETP mode i.e. standard vs strict")
    public static let CoverSheetETPSettingsButton = NSLocalizedString("CoverSheet.v24.ETP.Settings.Button", value: "Go to Settings", comment: "Text for the new ETP settings button")
}

// FxA Signin screen
extension Strings {
    public static let FxASignin_Title = NSLocalizedString("fxa.signin.turn-on-sync", value: "Turn on Sync", comment: "FxA sign in view title")
    public static let FxASignin_Subtitle = NSLocalizedString("fxa.signin.camera-signin", value: "Sign In with Your Camera", comment: "FxA sign in view subtitle")
    public static let FxASignin_QRInstructions = NSLocalizedString("fxa.signin.qr-link-instruction", value: "On your computer open Firefox and go to firefox.com/pair", comment: "FxA sign in view qr code instructions")
    public static let FxASignin_QRScanSignin = NSLocalizedString("fxa.signin.ready-to-scan", value: "Ready to Scan", comment: "FxA sign in view qr code scan button")
    public static let FxASignin_EmailSignin = NSLocalizedString("fxa.signin.use-email-instead", value: "Use Email Instead", comment: "FxA sign in view email login button")
}

// FxA QR code scanning screen
extension String {
    public static let FxAQRCode_Instructions = NSLocalizedString("fxa.qr-scanning-view.instructions", value: "Scan the QR code shown at firefox.com/pair", comment: "Instructions shown on qr code scanning view")
}

//Today Widget Strings - [New Search - Private Search]
extension String {
    public static let NewPrivateTabButtonLabel = NSLocalizedString("TodayWidget.PrivateTabButtonLabelV1", tableName: "Today", value: "Private Search", comment: "Open New Private Tab button label")
    public static let NewTabButtonLabel = NSLocalizedString("TodayWidget.NewTabButtonLabelV1", tableName: "Today", value: "New Search", comment: "Open New Tab button label")
    public static let GoToCopiedLinkLabel = NSLocalizedString("TodayWidget.GoToCopiedLinkLabelV1", tableName: "Today", value: "Go to copied link", comment: "Go to link pasted on the clipboard")
    public static let GoToCopiedLinkLabelV2 = NSLocalizedString("TodayWidget.GoToCopiedLinkLabelV2", tableName: "Today", value: "Go To\nCopied Link", comment: "Go to link pasted on the clipboard")
    public static let CopiedLinkLabelFromPasteBoard = NSLocalizedString("TodayWidget.CopiedLinkLabelFromPasteBoardV1", tableName: "Today", value: "Copied Link from clipboard", comment: "Copied Link from clipboard displayed")
}
