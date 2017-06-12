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
    public static let TopSitesRemoveButtonAccessibilityLabel = NSLocalizedString("TopSites.RemovePage.Button", value: "Remove page - %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Activity Stream.
extension Strings {
    public static let HighlightIntroTitle = NSLocalizedString("ActivityStream.HighlightIntro.Title", value: "Be on the Lookout", comment: "The title that appears for the introduction to highlights in AS.")
    public static let HighlightIntroDescription = NSLocalizedString("ActivityStream.HighlightIntro.Description", value: "Firefox will place things here that you've discovered on the web so you can find your way back to the great articles, videos, bookmarks and other pages", comment: "The detailed text that explains what highlights are in AS.")
    public static let ASPageControlButton = NSLocalizedString("ActivityStream.PageControl.Button", value: "Next Page", comment: "The page control button that lets you switch between pages in top sites")
    public static let ASHighlightsTitle =  NSLocalizedString("ActivityStream.Highlights.SectionTitle", value: "Visit Again", comment: "Section title label for Visit again section")
    public static let ASTopSitesTitle =  NSLocalizedString("ActivityStream.TopSites.SectionTitle", value: "Top Sites", comment: "Section title label for Top Sites")
    public static let OpenInNewTabContextMenuTitle = NSLocalizedString("ActivityStream.ContextMenu.OpenInNewTab", value: "Open in New Tab", comment: "The title for the Open in New Tab context menu action for Activity Stream")
    public static let HighlightVistedText = NSLocalizedString("ActivityStream.Highlights.Visited", value: "Visited", comment: "The description of a highlight if it is a site the user has visited")
    public static let HighlightBookmarkText = NSLocalizedString("ActivityStream.Highlights.Bookmark", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked")

    public static let OpenInNewPrivateTabContextMenuTitle = NSLocalizedString("ActivityStream.ContextMenu.OpenInNewPrivateTab", value: "Open in New Private Tab", comment: "The title for the Open in New Private Tab context menu action for Activity Stream")
    public static let BookmarkContextMenuTitle = NSLocalizedString("ActivityStream.ContextMenu.Bookmark", value: "Bookmark", comment: "The title for the Bookmark context menu action for Activity Stream")
    public static let RemoveBookmarkContextMenuTitle = NSLocalizedString("ActivityStream.ContextMenu.RemoveBookmark", value: "Remove Bookmark", comment: "The title for the Remove Bookmark context menu action for Activity Stream")
    public static let DeleteFromHistoryContextMenuTitle = NSLocalizedString("ActivityStream.ContextMenu.DeleteFromHistory", value: "Delete from History", comment: "The title for the Delete from History context menu action for Activity Stream")
    public static let ShareContextMenuTitle = NSLocalizedString("ActivityStream.ContextMenu.Share", value: "Share", comment: "The title for the Share context menu action for Activity Stream")
    public static let RemoveFromASContextMenuTitle = NSLocalizedString("ActivityStream.ContextMenu.Remove", value: "Remove", comment: "The title for the Remove content from Activity Stream context menu item")
    public static let PinTopsiteActionTitle = NSLocalizedString("ActivityStream.ContextMenu.PinTopsite", value: "Pin to Top Sites", comment: "The title for the pinning a topsite action")
}

// Settings.
extension Strings {
    public static let SettingsClearPrivateDataClearButton = NSLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = NSLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsClearPrivateDataTitle = NSLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
    public static let SettingsSearchDoneButton = NSLocalizedString("Settings.Search.Done.Button", value: "Done", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = NSLocalizedString("Settings.Search.Edit.Button", value: "Edit", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSignOutButton = NSLocalizedString("Settings.SignOut.Button", value: "Sign Out", comment: "Button displayed at the bottom of settings page allowing users to Sign Out of FxA")
    public static let SettingsSignOutDestructiveAction = NSLocalizedString("Settings.SignOut.DestructiveButton", value: "Sign Out", comment: "Destructive action button in alert when user is prompted for signing out")
    public static let SettingsSignOutAlertTitle = NSLocalizedString("Settings.SignOut.Title", value: "Sign Out?", comment: "Title of the alert when prompting the user asking to sign out.")
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
    public static let SyncedTabsTableViewCellTitle = NSLocalizedString("HistoryPanel.SyncedTabsCell.Title", value: "Synced Devices", comment: "Title for the Synced Tabs Cell in the History Panel")
    public static let HistoryBackButtonTitle = NSLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let EmptySyncedTabsPanelStateTitle = NSLocalizedString("HistoryPanel.EmptySyncedTabsState.Title", value: "Firefox Sync", comment: "Title for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsState.Description", value: "Sign in to view open tabs on your other devices.", comment: "Description for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelNullStateDescription = NSLocalizedString("HistoryPanel.EmptySyncedTabsNullState.Description", value: "Your tabs from other devices show up here.", comment: "Description for the empty synced tabs null state in the History Panel")
    public static let SyncedTabsTableViewCellDescription = NSLocalizedString("HistoryPanel.SyncedTabsCell.Description.Pluralized", value: "%d device(s) connected", comment: "Description that corresponds with a number of devices connected for the Synced Tabs Cell in the History Panel")
    public static let HistoryPanelEmptyStateTitle = NSLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you've visited recently will show up here.", comment: "Title for the History Panel empty state.")
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
    public static let SettingsHomePageUIPositionTitle = NSLocalizedString("Settings.HomePage.UI.Toggle.Title", value: "Show Homepage Icon In Menu", comment: "Label used as an item in Settings. User can toggle this setting to show the home page button in menu, or on toolbar.")
    public static let SettingsHomePageUIPositionSubtitle = NSLocalizedString("Settings.HomePage.UI.Toggle.Subtitle", value: "Otherwise show in the toolbar", comment: "Label displayed under the 'Show Homepage Icon In Menu' option. It describes the effect of this setting when disabled.")
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
}

// Open With Settings
extension Strings {
    public static let SettingsOpenWithSectionName = NSLocalizedString("Settings.OpenWith.SectionName", value: "Open With", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behaviour.")
    public static let SettingsOpenWithPageTitle = NSLocalizedString("Settings.OpenWith.PageTitle", value: "Open mail links in", comment: "Title for Open With Settings")
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
}

// errors
extension Strings {
    public static let UnableToDownloadError = NSLocalizedString("Downloads.Error.Message", value: "Downloads aren't supported in Firefox yet.", comment: "The message displayed to a user when they try and perform the download of an asset that Firefox cannot currently handle.")
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

// Receiving tabs sent from other devices.
extension Strings {
    public static let SentTabViewActionTitle = NSLocalizedString("SentTab.ViewPage", value: "View", comment: "Button title displayed in a notification when a sent tab has been received. Tapping on the button will open the URL.")
    public static let SentTabBookmarkActionTitle = NSLocalizedString("SentTab.BookmarkPage", value: "Bookmark", comment: "Button title displayed in a notification when a sent tab has been received. Tapping on the button will add the URL as a bookmark.")
    public static let SentTabAddToReadingListActionTitle = NSLocalizedString("SentTab.AddToReadingList", value: "Add to Reading List", comment: "Button title displayed in a notification when a sent tab has been received. Tapping on the button will add the page to the reading list.")
}

// Sent tabs notifications. These are displayed when the app is backgrounded or the device is locked.
extension Strings {
    // zero tabs
    public static let SentTab_NoTabArrivingNotification_title = NSLocalizedString("SentTab.NoTabArrivingNotification.title", value: "Firefox Sync", comment: "Title of notification received after a spurious message from FxA has been received.")
    public static let SentTab_NoTabArrivingNotification_body =
        NSLocalizedString("SentTab.NoTabArrivingNotification.body", value: "Tap to begin", comment: "Body of notification received after a spurious message from FxA has been received.")

    // one tab, but on lockscreen
    public static let SentTab_UnnamedTabArrivingNotification_title = NSLocalizedString("SentTab.UnnamedTabArrivingNotification.title", value: "Tab received", comment: "Title of notification received after an unnamed tab has been sent from an unnamed connected device. This is likely to be displayed on the device lock screen.")
    public static let SentTab_UnnamedTabArrivingNotificationNoDevice_body = NSLocalizedString("SentTab.UnnamedTabArrivingNotificationNoDevice.body", value: "%1$i tab has arrived", comment: "Body of notification received after one tab has been received. %1$i is the number of tabs (1).")

    // one tab, on home screen
    public static let SentTab_TabArrivingNotificationNoDevice_title = NSLocalizedString("SentTab.TabArrivingNotification.title", value: "Tab received", comment: "Title of notification received after a tab has been sent from an unnamed connected device")
    public static let SentTab_TabArrivingNotificationWithDevice_title = NSLocalizedString("SentTab.TabArrivingNotificationWithDevice.title", value: "Tab from %@", comment: "Title of notification received after a tab has been sent from a named connected device. %@ is the name of the named device.")
    // body is the URL

    // multiple tabs.
    public static let SentTab_TabsArrivingNotification_title = NSLocalizedString("SentTab.TabsArrivingNotification.title", value: "Tabs received", comment: "Title of notification received after multiple tab have been sent from an unnamed connected device")
    public static let SentTab_TabsArrivingNotificationMultiple2_body = NSLocalizedString("SentTab.UnnamedTabsArrivingNotificationMultiple2.body", value: "%1$i tabs have arrived from your connected devices", comment: "Body of notification received after multiple tabs have been sent from an unnamed connected device. %1$i is the number of tabs.")
    public static let SentTab_TabsArrivingNotificationNoDevice_body = NSLocalizedString("SentTab.UnnamedTabsArrivingNotificationNoDevice.body", value: "%1$i tabs have arrived", comment: "Body of notification received after multiple tabs has been received. %1$i is the number of tabs.")
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
}

// App menu.
extension Strings {
    public static let AppMenuNewTabTitleString = NSLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    public static let AppMenuNewPrivateTabTitleString = NSLocalizedString("Menu.NewPrivateTabAction.Title", tableName: "Menu", value: "New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.")
    public static let AppMenuAddBookmarkTitleString = NSLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Add Bookmark", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuRemoveBookmarkTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    public static let AppMenuFindInPageTitleString = NSLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find In Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    public static let AppMenuViewDesktopSiteTitleString = NSLocalizedString("Menu.ViewDekstopSiteAction.Title", tableName: "Menu", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    public static let AppMenuViewMobileSiteTitleString = NSLocalizedString("Menu.ViewMobileSiteAction.Title", tableName: "Menu", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    public static let AppMenuScanQRCodeTitleString = NSLocalizedString("Menu.ScanQRCodeAction.Title", tableName: "Menu", value: "Scan QR Code", comment: "Label for the button, displayed in the menu, used to open the QR code scanner.")
    public static let AppMenuSettingsTitleString = NSLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    public static let AppMenuCloseAllTabsTitleString = NSLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    public static let AppMenuOpenHomePageTitleString = NSLocalizedString("Menu.OpenHomePageAction.Title", tableName: "Menu", value: "Home", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    public static let AppMenuSetHomePageTitleString = NSLocalizedString("Menu.SetHomePageAction.Title", tableName: "Menu", value: "Set Homepage", comment: "Label for the button, displayed in the menu, used to set the homepage if none is currently set.")
    public static let AppMenuSharePageTitleString = NSLocalizedString("Menu.SendPageAction.Title", tableName: "Menu", value: "Send", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    public static let AppMenuTopSitesTitleString = NSLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    public static let AppMenuBookmarksTitleString = NSLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bbookmarks home panel.")
    public static let AppMenuHistoryTitleString = NSLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel.")
    public static let AppMenuReadingListTitleString = NSLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel", tableName: "Menu", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel.")
    public static let AppMenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
    public static let AppMenuNightModeTurnOnLabel = NSLocalizedString("Menu.NightModeTurnOnAction.Label", value: "Night Mode", comment: "Label for the button, displayed in the menu, used to turn night mode on. 'Turn On' is an indication of state, and thus redundant.")
    public static let AppMenuNightModeTurnOffLabel = NSLocalizedString("Menu.NightModeTurnOffAction.Label", value: "Night Mode Off", comment: "Label for the button, displayed in the menu, used to turn night mode off. 'Off' is only displayed when the mode is on.")
    public static let AppMenuNoImageModeTurnOnLabel = NSLocalizedString("Menu.NoImageModeTurnOnAction.Label", value: "Hide Images", comment: "Label for the button, displayed in the menu, used to turn no image mode on.")
    public static let AppMenuNoImageModeTurnOffLabel = NSLocalizedString("Menu.NoImageModeTurnOffAction.Label", value: "Show Images", comment: "Label for the button, displayed in the menu, used to turn no image mode off.")
}

// MARK: Deprecated Strings (to be removed in next version)
private let logOut = NSLocalizedString("Log Out", comment: "Button in settings screen to disconnect from your account")
private let logOutQuestion = NSLocalizedString("Log Out?", comment: "Title of the 'log out firefox account' alert")
private let logOutDestructive = NSLocalizedString("Log Out", comment: "Disconnect button in the 'log out firefox account' alert")
