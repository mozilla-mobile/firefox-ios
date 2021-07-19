/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Strings Discussion
///
/// Strings constants in the FireFox iOS app are defined in this file. To make it easy for
/// localization, all strings are defined as `MZLocalizedString`. Strings should be separated
/// according to the feature/view they are a part of. For example, all strings relating to
/// time constants can be found under the `public struct TimeConstants` section.
///
/// For ease of identifying when a string was last updated, `MZLocalizedString` has a
/// `lastEditedIn` parameter that is of type `AppVersionTag`. When adding a new string, or
/// updating a string, an appropriate tag sholud be created in the `AppVersionTag` enum,
/// and that string should then be tagged accordingly. This allows easy identification of
/// new/updated strings during localization import/export. In the case that a string was
/// added/edited before the `AppVersionTag` was introduced, it is marked as `.unknown`.
/// This tag is ONLY used for identification purposes, and nothing else.
///
/// Finally, strings are aphabetized according to the first letter of the feature
/// name/category/view they're organized under.

public struct Strings {
    public static let bundle = Bundle(for: BundleClass.self)
}

class BundleClass {}

enum AppVersionTag {
    case v350
    case v360

    case unknown
}

fileprivate func MZLocalizedString(_ key: String, tableName: String? = nil, value: String = "", comment: String, lastEditedIn: AppVersionTag) -> String {
    return NSLocalizedString(key, tableName: tableName, bundle: Strings.bundle, value: value, comment: comment)
}

// MARK: - A

// MARK: - Activity Stream
extension String {
    public struct ActivityStream {
        public static let PocketTitle2 = MZLocalizedString("ActivityStream.Pocket.SectionTitle2", value: "Recommended by Pocket", comment: "Section title label for Recommended by Pocket section", lastEditedIn: .unknown)
        public static let TopSitesTitle =  MZLocalizedString("ActivityStream.TopSites.SectionTitle", value: "Top Sites", comment: "Section title label for Top Sites", lastEditedIn: .unknown)
        public static let ShortcutsTitle =  MZLocalizedString("ActivityStream.Shortcuts.SectionTitle", value: "Shortcuts", comment: "Section title label for Shortcuts", lastEditedIn: .unknown)
        public static let PocketMoreStoriesText = MZLocalizedString("ActivityStream.Pocket.MoreLink", value: "More", comment: "The link that shows more Pocket trending stories", lastEditedIn: .unknown)
        public static let TopSitesRowSettingFooter = MZLocalizedString("ActivityStream.TopSites.RowSettingFooter", value: "Set Rows", comment: "The title for the setting page which lets you select the number of top site rows", lastEditedIn: .unknown)
        public static let TopSitesRowCount = MZLocalizedString("ActivityStream.TopSites.RowCount", value: "Rows: %d", comment: "label showing how many rows of topsites are shown. %d represents a number", lastEditedIn: .unknown)
        public static let RecentlyBookmarkedTitle = MZLocalizedString("ActivityStream.NewRecentBookmarks.Title", value: "Recent Bookmarks", comment: "Section title label for recently bookmarked websites", lastEditedIn: .unknown)
        public static let RecentlyVisitedTitle = MZLocalizedString("ActivityStream.RecentHistory.Title", value: "Recently Visited", comment: "Section title label for recently visited websites", lastEditedIn: .unknown)
        public static let RecentlySavedSectionTitle = MZLocalizedString("ActivityStream.Library.Title", value: "Recently Saved", comment: "A string used to signify the start of the Recently Saved section in Home Screen.", lastEditedIn: .unknown)
        public static let RecentlySavedShowAllText = MZLocalizedString("RecentlySaved.Actions.More", value: "Show All", comment: "More button text for Recently Saved items at the home page.", lastEditedIn: .unknown)
    }
}


// MARK: - Alerts
extension String {
    public struct Alerts {
        public struct Breach {
            // Breach Alerts
            public static let Title = MZLocalizedString("BreachAlerts.Title", value: "Website Breach", comment: "Title for the Breached Login Detail View.", lastEditedIn: .unknown)
            public static let LearnMore = MZLocalizedString("BreachAlerts.LearnMoreButton", value: "Learn more", comment: "Link to monitor.firefox.com to learn more about breached passwords", lastEditedIn: .unknown)
            public static let BreachDate = MZLocalizedString("BreachAlerts.BreachDate", value: "This breach occurred on", comment: "Describes the date on which the breach occurred", lastEditedIn: .unknown)
            public static let Description = MZLocalizedString("BreachAlerts.Description", value: "Passwords were leaked or stolen since you last changed your password. To protect this account, log in to the site and change your password.", comment: "Description of what a breach is", lastEditedIn: .unknown)
            public static let Link = MZLocalizedString("BreachAlerts.Link", value: "Go to", comment: "Leads to a link to the breached website", lastEditedIn: .unknown)
        }

        public struct ClearPrivateData {
            public static let Message = MZLocalizedString("This action will clear all of your private data. It cannot be undone.", tableName: "ClearPrivateDataConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.", lastEditedIn: .unknown)
            public static let Cancel = MZLocalizedString("Cancel", tableName: "ClearPrivateDataConfirm", comment: "The cancel button when confirming clear private data.", lastEditedIn: .unknown)
            public static let Ok = MZLocalizedString("OK", tableName: "ClearPrivateDataConfirm", comment: "The button that clears private data.", lastEditedIn: .unknown)
        }

        public struct ClearSyncedHistoryData {
            public static let Message = MZLocalizedString("This action will clear all of your private data, including history from your synced devices.", tableName: "ClearHistoryConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.", lastEditedIn: .unknown)
            // TODO: these look like the same as in ClearPrivateDataAlert, I think we can remove them
            public static let Cancel = MZLocalizedString("Cancel", tableName: "ClearHistoryConfirm", comment: "The cancel button when confirming clear history.", lastEditedIn: .unknown)
            public static let Ok = MZLocalizedString("OK", tableName: "ClearHistoryConfirm", comment: "The confirmation button that clears history even when Sync is connected.", lastEditedIn: .unknown)
        }

        public struct ClearWebsiteData {
            public static let AllWebsiteDataMessage = MZLocalizedString("Settings.WebsiteData.ConfirmPrompt", value: "This action will clear all of your website data. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.", lastEditedIn: .unknown)
            public static let SelectedWebsiteDataMessage = MZLocalizedString("Settings.WebsiteData.SelectedConfirmPrompt", value: "This action will clear the selected items. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear some of their private data.", lastEditedIn: .unknown)
            // TODO: these look like the same as in ClearPrivateDataAlert, I think we can remove them
            public static let Cancel = MZLocalizedString("Cancel", tableName: "ClearPrivateDataConfirm", comment: "The cancel button when confirming clear private data.", lastEditedIn: .unknown)
            public static let Ok = MZLocalizedString("OK", tableName: "ClearPrivateDataConfirm", comment: "The button that clears private data.", lastEditedIn: .unknown)
        }

        public struct CrashOptIn {
            public static let Title = MZLocalizedString("Oops! Firefox crashed", comment: "Title for prompt displayed to user after the app crashes", lastEditedIn: .unknown)
            public static let Message = MZLocalizedString("Send a crash report so Mozilla can fix the problem?", comment: "Message displayed in the crash dialog above the buttons used to select when sending reports", lastEditedIn: .unknown)
            public static let Send = MZLocalizedString("Send Report", comment: "Used as a button label for crash dialog prompt", lastEditedIn: .unknown)
            public static let AlwaysSend = MZLocalizedString("Always Send", comment: "Used as a button label for crash dialog prompt", lastEditedIn: .unknown)
            public static let DontSend = MZLocalizedString("Don’t Send", comment: "Used as a button label for crash dialog prompt", lastEditedIn: .unknown)
        }

        public struct DeleteLogin {
            public static let Title = MZLocalizedString("Are you sure?", tableName: "LoginManager", comment: "Prompt title when deleting logins", lastEditedIn: .unknown)
            public static let SyncedMessage = MZLocalizedString("Logins will be removed from all connected devices.", tableName: "LoginManager", comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices", lastEditedIn: .unknown)
            public static let LocalMessage = MZLocalizedString("Logins will be permanently removed.", tableName: "LoginManager", comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them", lastEditedIn: .unknown)
            public static let Cancel = MZLocalizedString("Cancel", tableName: "LoginManager", comment: "Prompt option for cancelling out of deletion", lastEditedIn: .unknown)
            public static let Delete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.", lastEditedIn: .unknown)
        }

        public struct RestoreTabs {
            public static let Title = MZLocalizedString("Well, this is embarrassing.", comment: "Restore Tabs Prompt Title", lastEditedIn: .unknown)
            public static let Message = MZLocalizedString("Looks like Firefox crashed previously. Would you like to restore your tabs?", comment: "Restore Tabs Prompt Description", lastEditedIn: .unknown)
            public static let No = MZLocalizedString("No", comment: "Restore Tabs Negative Action", lastEditedIn: .unknown)
            public static let Okay = MZLocalizedString("Okay", comment: "Restore Tabs Affirmative Action", lastEditedIn: .unknown)
        }
        
        public struct ShakeToRestore {
            public static let AlertTitle = MZLocalizedString("ReopenAlert.Title", value: "Reopen Last Closed Tab", comment: "Reopen alert title shown at home page.", lastEditedIn: .unknown)
            public static let ButtonText = MZLocalizedString("ReopenAlert.Actions.Reopen", value: "Reopen", comment: "Reopen button text shown in reopen-alert at home page.", lastEditedIn: .unknown)
            public static let CancelText = MZLocalizedString("ReopenAlert.Actions.Cancel", value: "Cancel", comment: "Cancel button text shown in reopen-alert at home page.", lastEditedIn: .unknown)
        }
    }
}

// MARK: - App menu
extension String {
    public struct AppMenu {
        public static let ReportSiteIssueTitleString = MZLocalizedString("Menu.ReportSiteIssueAction.Title", tableName: "Menu", value: "Report Site Issue", comment: "Label for the button, displayed in the menu, used to report a compatibility issue with the current page.", lastEditedIn: .unknown)
        public static let StopReloadPageTitle = MZLocalizedString("Menu.Library.StopReload", value: "Stop", comment: "Label for the button displayed in the menu used to stop the reload of the webpage", lastEditedIn: .unknown)
        public static let LibraryTitleString = MZLocalizedString("Menu.Library.Title", tableName: "Menu", value: "Your Library", comment: "Label for the button, displayed in the menu, used to open the Library", lastEditedIn: .unknown)
        public static let AddToReadingListTitleString = MZLocalizedString("Menu.AddToReadingList.Title", tableName: "Menu", value: "Add to Reading List", comment: "Label for the button, displayed in the menu, used to add a page to the reading list.", lastEditedIn: .unknown)

        public static let SharePageTitleString = MZLocalizedString("Menu.SharePageAction.Title", tableName: "Menu", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.", lastEditedIn: .unknown)
        public static let CopyLinkTitleString = MZLocalizedString("Menu.CopyLink.Title", tableName: "Menu", value: "Copy Link", comment: "Label for the button, displayed in the menu, used to copy the current page link to the clipboard.", lastEditedIn: .unknown)
        public static let NewTabTitleString = MZLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab", lastEditedIn: .unknown)
        public static let AddBookmarkTitleString2 = MZLocalizedString("Menu.AddBookmarkAction2.Title", tableName: "Menu", value: "Add Bookmark", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.", lastEditedIn: .unknown)
        public static let RemoveBookmarkTitleString = MZLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.", lastEditedIn: .unknown)
        public static let FindInPageTitleString = MZLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.", lastEditedIn: .unknown)
        public static let ViewDesktopSiteTitleString = MZLocalizedString("Menu.ViewDekstopSiteAction.Title", tableName: "Menu", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.", lastEditedIn: .unknown)
        public static let ViewMobileSiteTitleString = MZLocalizedString("Menu.ViewMobileSiteAction.Title", tableName: "Menu", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.", lastEditedIn: .unknown)
        public static let SettingsTitleString = MZLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.", lastEditedIn: .unknown)
        public static let CloseAllTabsTitleString = MZLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.", lastEditedIn: .unknown)
        public static let OpenHomePageTitleString = MZLocalizedString("Menu.OpenHomePageAction.Title", tableName: "Menu", value: "Home", comment: "Label for the button, displayed in the menu, used to navigate to the home page.", lastEditedIn: .unknown)
        public static let TopSitesTitleString = MZLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.", lastEditedIn: .unknown)
        public static let BookmarksTitleString = MZLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel.v2", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel. Please keep as short as possible, <15 chars of space available.", lastEditedIn: .unknown)
        public static let ReadingListTitleString = MZLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel.v2", tableName: "Menu", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel. Please keep as short as possible, <15 chars of space available.", lastEditedIn: .unknown)
        public static let HistoryTitleString = MZLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel.v2", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel. Please keep as short as possible, <15 chars of space available.", lastEditedIn: .unknown)
        public static let DownloadsTitleString = MZLocalizedString("Menu.OpenDownloadsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Downloads", comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel. Please keep as short as possible, <15 chars of space available.", lastEditedIn: .unknown)
        public static let SyncedTabsTitleString = MZLocalizedString("Menu.OpenSyncedTabsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Synced Tabs", comment: "Accessibility label for the button, displayed in the menu, used to open the Synced Tabs home panel. Please keep as short as possible, <15 chars of space available.", lastEditedIn: .unknown)
        public static let ButtonAccessibilityLabel = MZLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.", lastEditedIn: .unknown)
        public static let TurnOnNightMode = MZLocalizedString("Menu.NightModeTurnOn.Label2", value: "Turn on Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.", lastEditedIn: .unknown)
        public static let TurnOffNightMode = MZLocalizedString("Menu.NightModeTurnOff.Label2", value: "Turn off Night Mode", comment: "Label for the button, displayed in the menu, turns off night mode.", lastEditedIn: .unknown)
        public static let NoImageMode = MZLocalizedString("Menu.NoImageModeBlockImages.Label", value: "Block Images", comment: "Label for the button, displayed in the menu, hides images on the webpage when pressed.", lastEditedIn: .unknown)
        public static let ShowImageMode = MZLocalizedString("Menu.NoImageModeShowImages.Label", value: "Show Images", comment: "Label for the button, displayed in the menu, shows images on the webpage when pressed.", lastEditedIn: .unknown)
        public static let Bookmarks = MZLocalizedString("Menu.Bookmarks.Label", value: "Bookmarks", comment: "Label for the button, displayed in the menu, takes you to to bookmarks screen when pressed.", lastEditedIn: .unknown)
        public static let History = MZLocalizedString("Menu.History.Label", value: "History", comment: "Label for the button, displayed in the menu, takes you to to History screen when pressed.", lastEditedIn: .unknown)
        public static let Downloads = MZLocalizedString("Menu.Downloads.Label", value: "Downloads", comment: "Label for the button, displayed in the menu, takes you to to Downloads screen when pressed.", lastEditedIn: .unknown)
        public static let ReadingList = MZLocalizedString("Menu.ReadingList.Label", value: "Reading List", comment: "Label for the button, displayed in the menu, takes you to to Reading List screen when pressed.", lastEditedIn: .unknown)
        public static let Passwords = MZLocalizedString("Menu.Passwords.Label", value: "Passwords", comment: "Label for the button, displayed in the menu, takes you to to passwords screen when pressed.", lastEditedIn: .unknown)
        public static let BackUpAndSyncData = MZLocalizedString("Menu.BackUpAndSync.Label", value: "Back up and Sync Data", comment: "Label for the button, displayed in the menu, takes you to sync sign in when pressed.", lastEditedIn: .unknown)
        public static let CopyURLConfirmMessage = MZLocalizedString("Menu.CopyURL.Confirm", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.", lastEditedIn: .unknown)

        public static let AddBookmarkConfirmMessage = MZLocalizedString("Menu.AddBookmark.Confirm", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.", lastEditedIn: .unknown)
        public static let TabSentConfirmMessage = MZLocalizedString("Menu.TabSent.Confirm", value: "Tab Sent", comment: "Toast displayed to the user after a tab has been sent successfully.", lastEditedIn: .unknown)
        public static let RemoveBookmarkConfirmMessage = MZLocalizedString("Menu.RemoveBookmark.Confirm", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.", lastEditedIn: .unknown)
        public static let AddPinToShortcutsConfirmMessage = MZLocalizedString("Menu.AddPin.Confirm2", value: "Added to Shortcuts", comment: "Toast displayed to the user after adding the item to the Shortcuts.", lastEditedIn: .unknown)
        public static let RemovePinFromShortcutsConfirmMessage = MZLocalizedString("Menu.RemovePin.Confirm2", value: "Removed from Shortcuts", comment: "Toast displayed to the user after removing the item to the Shortcuts.", lastEditedIn: .unknown)
        public static let AddToReadingListConfirmMessage = MZLocalizedString("Menu.AddToReadingList.Confirm", value: "Added To Reading List", comment: "Toast displayed to the user after adding the item to their reading list.", lastEditedIn: .unknown)
        public static let SendToDeviceTitle = MZLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device", lastEditedIn: .unknown)
        public static let SendLinkToDeviceTitle = MZLocalizedString("Menu.SendLinkToDevice", tableName: "3DTouchActions", value: "Send Link to Device", comment: "Label for preview action on Tab Tray Tab to send the current link to another device", lastEditedIn: .unknown)
        public static let WhatsNewString = MZLocalizedString("Menu.WhatsNew.Title", value: "What's New", comment: "The title for the option to view the What's new page.", lastEditedIn: .unknown)
    }
}

// MARK: - Authenticator strings
extension String {
    public struct Authenticator {
        public static let Cancel = MZLocalizedString("Cancel", comment: "Label for Cancel button", lastEditedIn: .unknown)
        public static let Login = MZLocalizedString("Log in", comment: "Authentication prompt log in button", lastEditedIn: .unknown)
        public static let PromptTitle = MZLocalizedString("Authentication required", comment: "Authentication prompt title", lastEditedIn: .unknown)
        public static let PromptRealmMessage = MZLocalizedString("A username and password are being requested by %@. The site says: %@", comment: "Authentication prompt message with a realm. First parameter is the hostname. Second is the realm string", lastEditedIn: .unknown)
        public static let PromptEmptyRealmMessage = MZLocalizedString("A username and password are being requested by %@.", comment: "Authentication prompt message with no realm. Parameter is the hostname of the site", lastEditedIn: .unknown)
        public static let UsernamePlaceholder = MZLocalizedString("Username", comment: "Username textbox in Authentication prompt", lastEditedIn: .unknown)
        public static let PasswordPlaceholder = MZLocalizedString("Password", comment: "Password textbox in Authentication prompt", lastEditedIn: .unknown)
    }

    public struct AuthenticationManager {
        public static let Passcode = MZLocalizedString("Passcode For Logins", tableName: "AuthenticationManager", comment: "Label for the Passcode item in Settings", lastEditedIn: .unknown)
        public static let TouchIDPasscodeSetting = MZLocalizedString("Touch ID & Passcode", tableName: "AuthenticationManager", comment: "Label for the Touch ID/Passcode item in Settings", lastEditedIn: .unknown)
        public static let FaceIDPasscodeSetting = MZLocalizedString("Face ID & Passcode", tableName: "AuthenticationManager", comment: "Label for the Face ID/Passcode item in Settings", lastEditedIn: .unknown)
        public static let RequirePasscode = MZLocalizedString("Require Passcode", tableName: "AuthenticationManager", comment: "Text displayed in the 'Interval' section, followed by the current interval setting, e.g. 'Immediately'", lastEditedIn: .unknown)
        public static let EnterAPasscode = MZLocalizedString("Enter a passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when entering a new passcode", lastEditedIn: .unknown)
        public static let EnterPasscodeTitle = MZLocalizedString("Enter Passcode", tableName: "AuthenticationManager", comment: "Title of the dialog used to request the passcode", lastEditedIn: .unknown)
        public static let EnterPasscode = MZLocalizedString("Enter passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when changing the existing passcode", lastEditedIn: .unknown)
        public static let ReenterPasscode = MZLocalizedString("Re-enter passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when confirming a passcode", lastEditedIn: .unknown)
        public static let SetPasscode = MZLocalizedString("Set Passcode", tableName: "AuthenticationManager", comment: "Title of the dialog used to set a passcode", lastEditedIn: .unknown)
        public static let TurnOffPasscode = MZLocalizedString("Turn Passcode Off", tableName: "AuthenticationManager", comment: "Label used as a setting item to turn off passcode", lastEditedIn: .unknown)
        public static let TurnOnPasscode = MZLocalizedString("Turn Passcode On", tableName: "AuthenticationManager", comment: "Label used as a setting item to turn on passcode", lastEditedIn: .unknown)
        public static let ChangePasscode = MZLocalizedString("Change Passcode", tableName: "AuthenticationManager", comment: "Label used as a setting item and title of the following screen to change the current passcode", lastEditedIn: .unknown)
        public static let EnterNewPasscode = MZLocalizedString("Enter a new passcode", tableName: "AuthenticationManager", comment: "Text displayed above the input field when changing the existing passcode", lastEditedIn: .unknown)
        public static let Immediately = MZLocalizedString("Immediately", tableName: "AuthenticationManager", comment: "'Immediately' interval item for selecting when to require passcode", lastEditedIn: .unknown)
        public static let OneMinute = MZLocalizedString("After 1 minute", tableName: "AuthenticationManager", comment: "'After 1 minute' interval item for selecting when to require passcode", lastEditedIn: .unknown)
        public static let FiveMinutes = MZLocalizedString("After 5 minutes", tableName: "AuthenticationManager", comment: "'After 5 minutes' interval item for selecting when to require passcode", lastEditedIn: .unknown)
        public static let TenMinutes = MZLocalizedString("After 10 minutes", tableName: "AuthenticationManager", comment: "'After 10 minutes' interval item for selecting when to require passcode", lastEditedIn: .unknown)
        public static let FifteenMinutes = MZLocalizedString("After 15 minutes", tableName: "AuthenticationManager", comment: "'After 15 minutes' interval item for selecting when to require passcode", lastEditedIn: .unknown)
        public static let OneHour = MZLocalizedString("After 1 hour", tableName: "AuthenticationManager", comment: "'After 1 hour' interval item for selecting when to require passcode", lastEditedIn: .unknown)
        public static let LoginsTouchReason = MZLocalizedString("Use your fingerprint to access Logins now.", tableName: "AuthenticationManager", comment: "Touch ID prompt subtitle when accessing logins", lastEditedIn: .unknown)
        public static let RequirePasscodeTouchReason = MZLocalizedString("touchid.require.passcode.reason.label", tableName: "AuthenticationManager", value: "Use your fingerprint to access configuring your required passcode interval.", comment: "Touch ID prompt subtitle when accessing the require passcode setting", lastEditedIn: .unknown)
        public static let DisableTouchReason = MZLocalizedString("touchid.disable.reason.label", tableName: "AuthenticationManager", value: "Use your fingerprint to disable Touch ID.", comment: "Touch ID prompt subtitle when disabling Touch ID", lastEditedIn: .unknown)
        public static let IncorrectAttemptsRemaining = MZLocalizedString("Incorrect passcode. Try again (Attempts remaining: %d).", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app with attempts remaining", lastEditedIn: .unknown)
        public static let MaximumAttemptsReachedNoTime = MZLocalizedString("Maximum attempts reached. Please try again later.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.", lastEditedIn: .unknown)
        public static let MismatchPasscodeError = MZLocalizedString("Passcodes didn’t match. Try again.", tableName: "AuthenticationManager", comment: "Error message displayed to user when their confirming passcode doesn't match the first code.", lastEditedIn: .unknown)
        public static let UseNewPasscodeError = MZLocalizedString("New passcode must be different than existing code.", tableName: "AuthenticationManager", comment: "Error message displayed when user tries to enter the same passcode as their existing code when changing it.", lastEditedIn: .unknown)
    }

}


// MARK: - B

// MARK: - Root Bookmarks folders
extension String {
    public struct Bookmarks {
        public struct FolderTitle {
            public static let Mobile = MZLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.", lastEditedIn: .unknown)
            public static let Menu = MZLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.", lastEditedIn: .unknown)
            public static let Toolbar = MZLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.", lastEditedIn: .unknown)
            public static let Unsorted = MZLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.", lastEditedIn: .unknown)
        }

        public struct Management {
            public static let NewBookmark = MZLocalizedString("Bookmarks.NewBookmark.Label", value: "New Bookmark", comment: "The button to create a new bookmark", lastEditedIn: .unknown)
            public static let NewFolder = MZLocalizedString("Bookmarks.NewFolder.Label", value: "New Folder", comment: "The button to create a new folder", lastEditedIn: .unknown)
            public static let NewSeparator = MZLocalizedString("Bookmarks.NewSeparator.Label", value: "New Separator", comment: "The button to create a new separator", lastEditedIn: .unknown)
            public static let EditBookmark = MZLocalizedString("Bookmarks.EditBookmark.Label", value: "Edit Bookmark", comment: "The button to edit a bookmark", lastEditedIn: .unknown)
            public static let Edit = MZLocalizedString("Bookmarks.Edit.Button", value: "Edit", comment: "The button on the snackbar to edit a bookmark after adding it.", lastEditedIn: .unknown)
            public static let EditFolder = MZLocalizedString("Bookmarks.EditFolder.Label", value: "Edit Folder", comment: "The button to edit a folder", lastEditedIn: .unknown)
            public static let DeleteFolderWarningTitle = MZLocalizedString("Bookmarks.DeleteFolderWarning.Title", tableName: "BookmarkPanelDeleteConfirm", value: "This folder isn’t empty.", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.", lastEditedIn: .unknown)
            public static let DeleteFolderWarningDescription = MZLocalizedString("Bookmarks.DeleteFolderWarning.Description", tableName: "BookmarkPanelDeleteConfirm", value: "Are you sure you want to delete it and its contents?", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.", lastEditedIn: .unknown)
            public static let DeleteFolderCancelButtonLabel = MZLocalizedString("Bookmarks.DeleteFolderWarning.CancelButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Cancel", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.", lastEditedIn: .unknown)
            public static let DeleteFolderDeleteButtonLabel = MZLocalizedString("Bookmarks.DeleteFolderWarning.DeleteButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Delete", comment: "Button label for the button that deletes a folder and all of its children.", lastEditedIn: .unknown)
            public static let PanelDeleteTableAction = MZLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.", lastEditedIn: .unknown)
            public static let DetailFieldTitle = MZLocalizedString("Bookmark.DetailFieldTitle.Label", value: "Title", comment: "The label for the Title field when editing a bookmark", lastEditedIn: .unknown)
            public static let DetailFieldURL = MZLocalizedString("Bookmark.DetailFieldURL.Label", value: "URL", comment: "The label for the URL field when editing a bookmark", lastEditedIn: .unknown)
        }
    }

}

// MARK: - BrowserViewController
extension String {
    public struct BrowserViewController {
        public struct ReaderMode {
            public static let AddPageGeneralErrorAccessibilityLabel = MZLocalizedString("Could not add page to Reading list", comment: "Accessibility message e.g. spoken by VoiceOver after adding current webpage to the Reading List failed.", lastEditedIn: .unknown)
            public static let AddPageSuccessAcessibilityLabel = MZLocalizedString("Added page to Reading List", comment: "Accessibility message e.g. spoken by VoiceOver after the current page gets added to the Reading List using the Reader View button, e.g. by long-pressing it or by its accessibility custom action.", lastEditedIn: .unknown)
            public static let AddPageMaybeExistsErrorAccessibilityLabel = MZLocalizedString("Could not add page to Reading List. Maybe it’s already there?", comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures.", lastEditedIn: .unknown)
        }

        public static let WebViewAccessibilityLabel = MZLocalizedString("Web content", comment: "Accessibility label for the main web content view", lastEditedIn: .unknown)
    }
}

// MARK: - C
// MARK: - Clear recent history action menu
extension String {
    public struct ClearHistoryMenu {
        public static let Title = MZLocalizedString("HistoryPanel.ClearHistoryMenuTitle", value: "Clearing Recent History will remove history, cookies, and other browser data.", comment: "Title for popup action menu to clear recent history.", lastEditedIn: .unknown)
        public static let OptionTheLastHour = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionTheLastHour", value: "The Last Hour", comment: "Button to perform action to clear history for the last hour", lastEditedIn: .unknown)
        public static let OptionToday = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionToday", value: "Today", comment: "Button to perform action to clear history for today only", lastEditedIn: .unknown)
        public static let OptionTodayAndYesterday = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionTodayAndYesterday", value: "Today and Yesterday", comment: "Button to perform action to clear history for yesterday and today", lastEditedIn: .unknown)
        public static let OptionEverything = MZLocalizedString("HistoryPanel.ClearHistoryMenuOptionEverything", value: "Everything", comment: "Option title to clear all browsing history.", lastEditedIn: .unknown)
    }
}

// MARK: - Clipboard Toast
extension String {
    public struct Clipboard {
        public struct Toast {
            public static let GoToCopiedLink = MZLocalizedString("ClipboardToast.GoToCopiedLink.Title", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard", lastEditedIn: .unknown)
            public static let GoButtonTittle = MZLocalizedString("ClipboardToast.GoToCopiedLink.Button", value: "Go", comment: "The button to open a new tab with the copied link", lastEditedIn: .unknown)
        }

    }

}

// MARK: - Credential Provider
extension String {
    struct CredetntialProvider {
        public static let LoginsWelcomeViewTitle = MZLocalizedString("Logins.WelcomeView.Title", value: "Take your passwords everywhere", comment: "Label displaying welcome view title", lastEditedIn: .unknown)
        public static let LoginsListSearchCancel = MZLocalizedString("LoginsList.Search.Cancel", value: "Cancel", comment: "Cancel button title", lastEditedIn: .unknown)
        public static let LoginsListSearchPlaceholder = MZLocalizedString("LoginsList.Search.Placeholder", value: "Search logins", comment: "Placeholder text for search field", lastEditedIn: .unknown)
        public static let LoginsListSelectPasswordTitle = MZLocalizedString("LoginsList.SelectPassword.Title", value: "Select a password to fill", comment: "Label displaying select a password to fill instruction", lastEditedIn: .unknown)
        public static let LoginsListNoMatchingResultTitle = MZLocalizedString("LoginsList.NoMatchingResult.Title", value: "No matching logins", comment: "Label displayed when a user searches and no matches can be found against the search query", lastEditedIn: .unknown)
        public static let LoginsListNoMatchingResultSubtitle = MZLocalizedString("LoginsList.NoMatchingResult.Subtitle", value: "There are no results matching your search.", comment: "Label that appears after the search if there are no logins matching the search", lastEditedIn: .unknown)
        public static let LoginsListNoLoginsFoundDescription = MZLocalizedString("LoginsList.NoLoginsFound.Description", value: "Saved logins will show up here. If you saved your logins to Firefox on a different device, sign in to your Firefox Account.", comment: "Label shown when there are no logins to list", lastEditedIn: .unknown)
    }
}

// MARK: - Context menu ButtonToast instances.
extension String {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = MZLocalizedString("ContextMenu.ButtonToast.NewTabOpened.LabelText", value: "New Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Tab.", lastEditedIn: .unknown)
    public static let ContextMenuButtonToastNewTabOpenedButtonText = MZLocalizedString("ContextMenu.ButtonToast.NewTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Tab.", lastEditedIn: .unknown)
    public static let ContextMenuButtonToastNewPrivateTabOpenedLabelText = MZLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.LabelText", value: "New Private Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Private Tab.", lastEditedIn: .unknown)
    public static let ContextMenuButtonToastNewPrivateTabOpenedButtonText = MZLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Private Tab.", lastEditedIn: .unknown)
}

// MARK: - Cover Sheet
extension String {
    // Dark Mode Cover Sheet
    public static let CoverSheetV22DarkModeTitle = MZLocalizedString("CoverSheet.v22.DarkMode.Title", value: "Dark theme now includes a dark keyboard and dark splash screen.", comment: "Title for the new dark mode change in the version 22 app release.", lastEditedIn: .unknown)
    public static let CoverSheetV22DarkModeDescription = MZLocalizedString("CoverSheet.v22.DarkMode.Description", value: "For iOS 13 users, Firefox now automatically switches to a dark theme when your phone is set to Dark Mode. To change this behavior, go to Settings > Theme.", comment: "Description for the new dark mode change in the version 22 app release. It describes the new automatic dark theme and how to change the theme settings.", lastEditedIn: .unknown)

    // ETP Cover Sheet
    public static let CoverSheetETPTitle = MZLocalizedString("CoverSheet.v24.ETP.Title", value: "Protection Against Ad Tracking", comment: "Title for the new ETP mode i.e. standard vs strict", lastEditedIn: .unknown)
    public static let CoverSheetETPDescription = MZLocalizedString("CoverSheet.v24.ETP.Description", value: "Built-in Enhanced Tracking Protection helps stop ads from following you around. Turn on Strict to block even more trackers, ads, and popups. ", comment: "Description for the new ETP mode i.e. standard vs strict", lastEditedIn: .unknown)
    public static let CoverSheetETPSettingsButton = MZLocalizedString("CoverSheet.v24.ETP.Settings.Button", value: "Go to Settings", comment: "Text for the new ETP settings button", lastEditedIn: .unknown)
}

// MARK: - Clearables
extension String {
    // Removed Clearables as part of Bug 1226654, but keeping the string around.
    private static let removedSavedLoginsLabel = MZLocalizedString("Saved Logins", tableName: "ClearPrivateData", comment: "Settings item for clearing passwords and login data", lastEditedIn: .unknown)

    public static let ClearableHistory = MZLocalizedString("Browsing History", tableName: "ClearPrivateData", comment: "Settings item for clearing browsing history", lastEditedIn: .unknown)
    public static let ClearableCache = MZLocalizedString("Cache", tableName: "ClearPrivateData", comment: "Settings item for clearing the cache", lastEditedIn: .unknown)
    public static let ClearableOfflineData = MZLocalizedString("Offline Website Data", tableName: "ClearPrivateData", comment: "Settings item for clearing website data", lastEditedIn: .unknown)
    public static let ClearableCookies = MZLocalizedString("Cookies", tableName: "ClearPrivateData", comment: "Settings item for clearing cookies", lastEditedIn: .unknown)
    public static let ClearableDownloads = MZLocalizedString("Downloaded Files", tableName: "ClearPrivateData", comment: "Settings item for deleting downloaded files", lastEditedIn: .unknown)
}

// MARK: - D
// MARK: - DeviceInfo
extension String {
    public struct DeviceInfo {
        public static let ClientNameDescription = MZLocalizedString("%@ on %@", tableName: "Shared", comment: "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs. The first argument is the app name. The second argument is the device name.", lastEditedIn: .unknown)
    }
}

// MARK: - Downloads Panel
extension String {
    public static let DownloadsPanelEmptyStateTitle = MZLocalizedString("DownloadsPanel.EmptyState.Title", value: "Downloaded files will show up here.", comment: "Title for the Downloads Panel empty state.", lastEditedIn: .unknown)
    public static let DownloadsPanelDeleteTitle = MZLocalizedString("DownloadsPanel.Delete.Title", value: "Delete", comment: "Action button for deleting downloaded files in the Downloads panel.", lastEditedIn: .unknown)
    public static let DownloadsPanelShareTitle = MZLocalizedString("DownloadsPanel.Share.Title", value: "Share", comment: "Action button for sharing downloaded files in the Downloads panel.", lastEditedIn: .unknown)
}

// MARK: - Download Helper
extension String {
    public static let OpenInDownloadHelperAlertDownloadNow = MZLocalizedString("Downloads.Alert.DownloadNow", value: "Download Now", comment: "The label of the button the user will press to start downloading a file", lastEditedIn: .unknown)
    public static let DownloadsButtonTitle = MZLocalizedString("Downloads.Toast.GoToDownloads.Button", value: "Downloads", comment: "The button to open a new tab with the Downloads home panel", lastEditedIn: .unknown)
    public static let CancelDownloadDialogTitle = MZLocalizedString("Downloads.CancelDialog.Title", value: "Cancel Download", comment: "Alert dialog title when the user taps the cancel download icon.", lastEditedIn: .unknown)
    public static let CancelDownloadDialogMessage = MZLocalizedString("Downloads.CancelDialog.Message", value: "Are you sure you want to cancel this download?", comment: "Alert dialog body when the user taps the cancel download icon.", lastEditedIn: .unknown)
    public static let CancelDownloadDialogResume = MZLocalizedString("Downloads.CancelDialog.Resume", value: "Resume", comment: "Button declining the cancellation of the download.", lastEditedIn: .unknown)
    public static let CancelDownloadDialogCancel = MZLocalizedString("Downloads.CancelDialog.Cancel", value: "Cancel", comment: "Button confirming the cancellation of the download.", lastEditedIn: .unknown)
    public static let DownloadCancelledToastLabelText = MZLocalizedString("Downloads.Toast.Cancelled.LabelText", value: "Download Cancelled", comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.", lastEditedIn: .unknown)
    public static let DownloadFailedToastLabelText = MZLocalizedString("Downloads.Toast.Failed.LabelText", value: "Download Failed", comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.", lastEditedIn: .unknown)
    public static let DownloadFailedToastButtonTitled = MZLocalizedString("Downloads.Toast.Failed.RetryButton", value: "Retry", comment: "The button to retry a failed download from the Download Failed toast.", lastEditedIn: .unknown)
    public static let DownloadMultipleFilesToastDescriptionText = MZLocalizedString("Downloads.Toast.MultipleFiles.DescriptionText", value: "1 of %d files", comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.", lastEditedIn: .unknown)
    public static let DownloadProgressToastDescriptionText = MZLocalizedString("Downloads.Toast.Progress.DescriptionText", value: "%1$@/%2$@", comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).", lastEditedIn: .unknown)
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = MZLocalizedString("Downloads.Toast.MultipleFilesAndProgress.DescriptionText", value: "%1$@ %2$@", comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.", lastEditedIn: .unknown)
}

// MARK: - Do not track
extension String {
    public static let SettingsDoNotTrackTitle = MZLocalizedString("Settings.DNT.Title", value: "Send websites a Do Not Track signal that you don’t want to be tracked", comment: "DNT Settings title", lastEditedIn: .unknown)
    public static let SettingsDoNotTrackOptionOnWithTP = MZLocalizedString("Settings.DNT.OptionOnWithTP", value: "Only when using Tracking Protection", comment: "DNT Settings option for only turning on when Tracking Protection is also on", lastEditedIn: .unknown)
    public static let SettingsDoNotTrackOptionAlwaysOn = MZLocalizedString("Settings.DNT.OptionAlwaysOn", value: "Always", comment: "DNT Settings option for always on", lastEditedIn: .unknown)
}

// MARK: - Display Theme
extension String {
    public static let SettingsDisplayThemeTitle = MZLocalizedString("Settings.DisplayTheme.Title.v2", value: "Theme", comment: "Title in main app settings for Theme settings", lastEditedIn: .unknown)
    public static let DisplayThemeBrightnessThresholdSectionHeader = MZLocalizedString("Settings.DisplayTheme.BrightnessThreshold.SectionHeader", value: "Threshold", comment: "Section header for brightness slider.", lastEditedIn: .unknown)
    public static let DisplayThemeSectionFooter = MZLocalizedString("Settings.DisplayTheme.SectionFooter", value: "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes. The circle indicates your display's current brightness.", comment: "Display (theme) settings footer describing how the brightness slider works.", lastEditedIn: .unknown)
    public static let SystemThemeSectionHeader = MZLocalizedString("Settings.DisplayTheme.SystemTheme.SectionHeader", value: "System Theme", comment: "System theme settings section title", lastEditedIn: .unknown)
    public static let SystemThemeSectionSwitchTitle = MZLocalizedString("Settings.DisplayTheme.SystemTheme.SwitchTitle", value: "Use System Light/Dark Mode", comment: "System theme settings switch to choose whether to use the same theme as the system", lastEditedIn: .unknown)
    public static let ThemeSwitchModeSectionHeader = MZLocalizedString("Settings.DisplayTheme.SwitchMode.SectionHeader", value: "Switch Mode", comment: "Switch mode settings section title", lastEditedIn: .unknown)
    public static let ThemePickerSectionHeader = MZLocalizedString("Settings.DisplayTheme.ThemePicker.SectionHeader", value: "Theme Picker", comment: "Theme picker settings section title", lastEditedIn: .unknown)
    public static let DisplayThemeAutomaticSwitchTitle = MZLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatically", comment: "Display (theme) settings switch to choose whether to set the dark mode manually, or automatically based on the brightness slider.", lastEditedIn: .unknown)
    public static let DisplayThemeAutomaticStatusLabel = MZLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatic", comment: "Display (theme) settings label to show if automatically switch theme is enabled.", lastEditedIn: .unknown)
    public static let DisplayThemeAutomaticSwitchSubtitle = MZLocalizedString("Settings.DisplayTheme.SwitchSubtitle", value: "Switch automatically based on screen brightness", comment: "Display (theme) settings switch subtitle, explaining the title 'Automatically'.", lastEditedIn: .unknown)
    public static let DisplayThemeManualSwitchTitle = MZLocalizedString("Settings.DisplayTheme.Manual.SwitchTitle", value: "Manually", comment: "Display (theme) setting to choose the theme manually.", lastEditedIn: .unknown)
    public static let DisplayThemeManualSwitchSubtitle = MZLocalizedString("Settings.DisplayTheme.Manual.SwitchSubtitle", value: "Pick which theme you want", comment: "Display (theme) settings switch subtitle, explaining the title 'Manually'.", lastEditedIn: .unknown)
    public static let DisplayThemeManualStatusLabel = MZLocalizedString("Settings.DisplayTheme.Manual.StatusLabel", value: "Manual", comment: "Display (theme) settings label to show if manually switch theme is enabled.", lastEditedIn: .unknown)
    public static let DisplayThemeOptionLight = MZLocalizedString("Settings.DisplayTheme.OptionLight", value: "Light", comment: "Option choice in display theme settings for light theme", lastEditedIn: .unknown)
    public static let DisplayThemeOptionDark = MZLocalizedString("Settings.DisplayTheme.OptionDark", value: "Dark", comment: "Option choice in display theme settings for dark theme", lastEditedIn: .unknown)
}

// MARK: - Default Browser
extension String {
    public static let DefaultBrowserCardTitle = MZLocalizedString("DefaultBrowserCard.Title", tableName: "Default Browser", value: "Switch Your Default Browser", comment: "Title for small card shown that allows user to switch their default browser to Firefox.", lastEditedIn: .unknown)
    public static let DefaultBrowserCardDescription = MZLocalizedString("DefaultBrowserCard.Description", tableName: "Default Browser", value: "Set links from websites, emails, and Messages to open automatically in Firefox.", comment: "Description for small card shown that allows user to switch their default browser to Firefox.", lastEditedIn: .unknown)
    public static let DefaultBrowserCardButton = MZLocalizedString("DefaultBrowserCard.Button.v2", tableName: "Default Browser", value: "Learn How", comment: "Button string to learn how to set your default browser.", lastEditedIn: .unknown)
    public static let DefaultBrowserMenuItem = MZLocalizedString("Settings.DefaultBrowserMenuItem", tableName: "Default Browser", value: "Set as Default Browser", comment: "Menu option for setting Firefox as default browser.", lastEditedIn: .unknown)
    public static let DefaultBrowserOnboardingScreenshot = MZLocalizedString("DefaultBrowserOnboarding.Screenshot", tableName: "Default Browser", value: "Default Browser App", comment: "Text for the screenshot of the iOS system settings page for Firefox.", lastEditedIn: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep1 = MZLocalizedString("DefaultBrowserOnboarding.Description1", tableName: "Default Browser", value: "1. Go to Settings", comment: "Description for default browser onboarding card.", lastEditedIn: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep2 = MZLocalizedString("DefaultBrowserOnboarding.Description2", tableName: "Default Browser", value: "2. Tap Default Browser App", comment: "Description for default browser onboarding card.", lastEditedIn: .unknown)
    public static let DefaultBrowserOnboardingDescriptionStep3 = MZLocalizedString("DefaultBrowserOnboarding.Description3", tableName: "Default Browser", value: "3. Select Firefox", comment: "Description for default browser onboarding card.", lastEditedIn: .unknown)
    public static let DefaultBrowserOnboardingButton = MZLocalizedString("DefaultBrowserOnboarding.Button", tableName: "Default Browser", value: "Go to Settings", comment: "Button string to open settings that allows user to switch their default browser to Firefox.", lastEditedIn: .unknown)
}

// MARK: - Default Suggested Site
extension String {
    public struct DefaultSuggestedSites {
        public static let Facebook = MZLocalizedString("Facebook", comment: "Tile title for Facebook", lastEditedIn: .unknown)
        public static let YouTube = MZLocalizedString("YouTube", comment: "Tile title for YouTube", lastEditedIn: .unknown)
        public static let Amazon = MZLocalizedString("Amazon", comment: "Tile title for Amazon", lastEditedIn: .unknown)
        public static let Wikipedia = MZLocalizedString("Wikipedia", comment: "Tile title for Wikipedia", lastEditedIn: .unknown)
        public static let Twitter = MZLocalizedString("Twitter", comment: "Tile title for Twitter", lastEditedIn: .unknown)
    }
}

// MARK: - E
// MARK: - Error pages
extension String {
    public struct ErrorPages {
        public static let AdvancedButton = MZLocalizedString("ErrorPages.Advanced.Button", value: "Advanced", comment: "Label for button to perform advanced actions on the error page", lastEditedIn: .unknown)
        public static let AdvancedWarning1 = MZLocalizedString("ErrorPages.AdvancedWarning1.Text", value: "Warning: we can’t confirm your connection to this website is secure.", comment: "Warning text when clicking the Advanced button on error pages", lastEditedIn: .unknown)
        public static let AdvancedWarning2 = MZLocalizedString("ErrorPages.AdvancedWarning2.Text", value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.", comment: "Additional warning text when clicking the Advanced button on error pages", lastEditedIn: .unknown)
        public static let CertWarningDescription = MZLocalizedString("ErrorPages.CertWarning.Description", value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Firefox has not connected to this website.", comment: "Warning text on the certificate error page", lastEditedIn: .unknown)
        public static let CertWarningTitle = MZLocalizedString("ErrorPages.CertWarning.Title", value: "This Connection is Untrusted", comment: "Title on the certificate error page", lastEditedIn: .unknown)
        public static let GoBackButton = MZLocalizedString("ErrorPages.GoBack.Button", value: "Go Back", comment: "Label for button to go back from the error page", lastEditedIn: .unknown)
        public static let VisitOnceButton = MZLocalizedString("ErrorPages.VisitOnce.Button", value: "Visit site anyway", comment: "Button label to temporarily continue to the site from the certificate error page", lastEditedIn: .unknown)
        public static let TryAgain = MZLocalizedString("Try again", tableName: "ErrorPages", comment: "Shown in error pages on a button that will try to load the page again", lastEditedIn: .unknown)
        public static let OpenInSafari = MZLocalizedString("Open in Safari", tableName: "ErrorPages", comment: "Shown in error pages for files that can't be shown and need to be downloaded.", lastEditedIn: .unknown)
    }
}

// MARK: - Errors
extension String {
    public static let UnableToDownloadError = MZLocalizedString("Downloads.Error.Message", value: "Downloads aren’t supported in Firefox yet.", comment: "The message displayed to a user when they try and perform the download of an asset that Firefox cannot currently handle.", lastEditedIn: .unknown)
    public static let UnableToAddPassErrorTitle = MZLocalizedString("AddPass.Error.Title", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.", lastEditedIn: .unknown)
    public static let UnableToAddPassErrorMessage = MZLocalizedString("AddPass.Error.Message", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.", lastEditedIn: .unknown)
    public static let UnableToAddPassErrorDismiss = MZLocalizedString("AddPass.Error.Dismiss", value: "OK", comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.", lastEditedIn: .unknown)
    public static let UnableToOpenURLError = MZLocalizedString("OpenURL.Error.Message", value: "Firefox cannot open the page because it has an invalid address.", comment: "The message displayed to a user when they try to open a URL that cannot be handled by Firefox, or any external app.", lastEditedIn: .unknown)
    public static let UnableToOpenURLErrorTitle = MZLocalizedString("OpenURL.Error.Title", value: "Cannot Open Page", comment: "Title of the message shown when the user attempts to navigate to an invalid link.", lastEditedIn: .unknown)
}

// MARK: - Empty Private tab view
extension String {
    public static let PrivateBrowsingLearnMore = MZLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode", lastEditedIn: .unknown)
    public static let PrivateBrowsingTitle = MZLocalizedString("Private Browsing", tableName: "PrivateBrowsing", comment: "Title displayed for when there are no open tabs while in private mode", lastEditedIn: .unknown)
    public static let PrivateBrowsingDescription = MZLocalizedString("Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.", tableName: "PrivateBrowsing", comment: "Description text displayed when there are no open tabs while in private mode", lastEditedIn: .unknown)
}


// MARK: - F
// MARK: - Firefox Logins
extension String {
    public static let LoginsAndPasswordsTitle = MZLocalizedString("Settings.LoginsAndPasswordsTitle", value: "Logins & Passwords", comment: "Title for the logins and passwords screen. Translation could just use 'Logins' if the title is too long", lastEditedIn: .unknown)

    // Prompts
    public static let SaveLoginUsernamePrompt = MZLocalizedString("LoginsHelper.PromptSaveLogin.Title", value: "Save login %@ for %@?", comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.", lastEditedIn: .unknown)
    public static let SaveLoginPrompt = MZLocalizedString("LoginsHelper.PromptSavePassword.Title", value: "Save password for %@?", comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.", lastEditedIn: .unknown)
    public static let UpdateLoginUsernamePrompt = MZLocalizedString("LoginsHelper.PromptUpdateLogin.Title.TwoArg", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.", lastEditedIn: .unknown)
    public static let UpdateLoginPrompt = MZLocalizedString("LoginsHelper.PromptUpdateLogin.Title.OneArg", value: "Update login for %@?", comment: "Prompt for updating a login. The first parameter is the hostname for which the password will be updated for.", lastEditedIn: .unknown)

    // Setting
    public static let SettingToSaveLogins = MZLocalizedString("Settings.SaveLogins.Title", value: "Save Logins", comment: "Setting to enable the built-in password manager", lastEditedIn: .unknown)
    public static let SettingToShowLoginsInAppMenu = MZLocalizedString("Settings.ShowLoginsInAppMenu.Title", value: "Show in Application Menu", comment: "Setting to show Logins & Passwords quick access in the application menu", lastEditedIn: .unknown)

    // List view
    public static let LoginsListTitle = MZLocalizedString("LoginsList.Title", value: "SAVED LOGINS", comment: "Title for the list of logins", lastEditedIn: .unknown)
    public static let LoginsListSearchPlaceholder = MZLocalizedString("LoginsList.LoginsListSearchPlaceholder", value: "Filter", comment: "Placeholder test for search box in logins list view.", lastEditedIn: .unknown)
    public static let LoginsFilterWebsite = MZLocalizedString("LoginsList.LoginsListFilterWebsite", value: "Website", comment: "For filtering the login list, search only the website names", lastEditedIn: .unknown)
    public static let LoginsFilterLogin = MZLocalizedString("LoginsList.LoginsListFilterLogin", value: "Login", comment: "For filtering the login list, search only the login names", lastEditedIn: .unknown)
    public static let LoginsFilterAll = MZLocalizedString("LoginsList.LoginsListFilterSearchAll", value: "All", comment: "For filtering the login list, search both website and login names.", lastEditedIn: .unknown)

    // Detail view
    public static let LoginsDetailViewLoginTitle = MZLocalizedString("LoginsDetailView.LoginTitle", value: "Login", comment: "Title for the login detail view", lastEditedIn: .unknown)
    public static let LoginsDetailViewLoginModified = MZLocalizedString("LoginsDetailView.LoginModified", value: "Modified", comment: "Login detail view field name for the last modified date", lastEditedIn: .unknown)

}

// MARK: - Firefox Account
extension String {
    // Settings strings
    public static let FxAFirefoxAccount = MZLocalizedString("FxA.FirefoxAccount", value: "Firefox Account", comment: "Settings section title for Firefox Account", lastEditedIn: .unknown)
    public static let FxASignInToSync = MZLocalizedString("FxA.SignIntoSync", value: "Sign in to Sync", comment: "Button label to sign into Sync", lastEditedIn: .unknown)
    public static let FxATakeYourWebWithYou = MZLocalizedString("FxA.TakeYourWebWithYou", value: "Take Your Web With You", comment: "Call to action for sign into sync button", lastEditedIn: .unknown)
    public static let FxASyncUsageDetails = MZLocalizedString("FxA.SyncExplain", value: "Get your tabs, bookmarks, and passwords from your other devices.", comment: "Label explaining what sync does", lastEditedIn: .unknown)
    public static let FxAAccountVerificationRequired = MZLocalizedString("FxA.AccountVerificationRequired", value: "Account Verification Required", comment: "Label stating your account is not verified", lastEditedIn: .unknown)
    public static let FxAAccountVerificationDetails = MZLocalizedString("FxA.AccountVerificationDetails", value: "Wrong email? Disconnect below to start over.", comment: "Label stating how to disconnect account", lastEditedIn: .unknown)
    public static let FxAManageAccount = MZLocalizedString("FxA.ManageAccount", value: "Manage Account & Devices", comment: "Button label to go to Firefox Account settings", lastEditedIn: .unknown)
    public static let FxASyncNow = MZLocalizedString("FxA.SyncNow", value: "Sync Now", comment: "Button label to Sync your Firefox Account", lastEditedIn: .unknown)
    public static let FxANoInternetConnection = MZLocalizedString("FxA.NoInternetConnection", value: "No Internet Connection", comment: "Label when no internet is present", lastEditedIn: .unknown)
    public static let FxASettingsTitle = MZLocalizedString("Settings.FxA.Title", value: "Firefox Account", comment: "Title displayed in header of the FxA settings panel.", lastEditedIn: .unknown)
    public static let FxASettingsSyncSettings = MZLocalizedString("Settings.FxA.Sync.SectionName", value: "Sync Settings", comment: "Label used as a section title in the Firefox Accounts Settings screen.", lastEditedIn: .unknown)
    public static let FxASettingsDeviceName = MZLocalizedString("Settings.FxA.DeviceName", value: "Device Name", comment: "Label used for the device name settings section.", lastEditedIn: .unknown)
    public static let FxAOpenSyncPreferences = MZLocalizedString("FxA.OpenSyncPreferences", value: "Open Sync Preferences", comment: "Button label to open Sync preferences", lastEditedIn: .unknown)
    public static let FxAConnectAnotherDevice = MZLocalizedString("FxA.ConnectAnotherDevice", value: "Connect Another Device", comment: "Button label to connect another device to Sync", lastEditedIn: .unknown)
    public static let FxARemoveAccountButton = MZLocalizedString("FxA.RemoveAccount", value: "Remove", comment: "Remove button is displayed on firefox account page under certain scenarios where user would like to remove their account.", lastEditedIn: .unknown)
    public static let FxARemoveAccountAlertTitle = MZLocalizedString("FxA.RemoveAccountAlertTitle", value: "Remove Account", comment: "Remove account alert is the final confirmation before user removes their firefox account", lastEditedIn: .unknown)
    public static let FxARemoveAccountAlertMessage = MZLocalizedString("FxA.RemoveAccountAlertMessage", value: "Remove the Firefox Account associated with this device to sign in as a different user.", comment: "Description string for alert view that gets presented when user tries to remove an account.", lastEditedIn: .unknown)

    // Surface error strings
    public static let FxAAccountVerificationRequiredSurface = MZLocalizedString("FxA.AccountVerificationRequiredSurface", value: "You need to verify %@. Check your email for the verification link from Firefox.", comment: "Message explaining that user needs to check email for Firefox Account verfication link.", lastEditedIn: .unknown)
    public static let FxAResendEmail = MZLocalizedString("FxA.ResendEmail", value: "Resend Email", comment: "Button label to resend email", lastEditedIn: .unknown)
    public static let FxAAccountVerifyEmail = MZLocalizedString("Verify your email address", comment: "Text message in the settings table view", lastEditedIn: .unknown)
    public static let FxAAccountVerifyPassword = MZLocalizedString("Enter your password to connect", comment: "Text message in the settings table view", lastEditedIn: .unknown)
    public static let FxAAccountUpgradeFirefox = MZLocalizedString("Upgrade Firefox to connect", comment: "Text message in the settings table view", lastEditedIn: .unknown)
}

// MARK: - FxA Signin screen
extension String {
    public struct FirefoxAccount {
        public struct Push {
            public struct DeviceDisconnected {
                public static let ThisDeviceTitle = MZLocalizedString("FxAPush_DeviceDisconnected_ThisDevice_title", value: "Sync Disconnected", comment: "Title of a notification displayed when this device has been disconnected by another device.", lastEditedIn: .unknown)
                public static let ThisDeviceBody = MZLocalizedString("FxAPush_DeviceDisconnected_ThisDevice_body", value: "This device has been successfully disconnected from Firefox Sync.", comment: "Body of a notification displayed when this device has been disconnected from FxA by another device.", lastEditedIn: .unknown)
                public static let NamedDeviceTitle = MZLocalizedString("FxAPush_DeviceDisconnected_title", value: "Sync Disconnected", comment: "Title of a notification displayed when named device has been disconnected from FxA.", lastEditedIn: .unknown)
                public static let NamedDeviceBody = MZLocalizedString("FxAPush_DeviceDisconnected_body", value: "%@ has been successfully disconnected.", comment: "Body of a notification displayed when named device has been disconnected from FxA. %@ refers to the name of the disconnected device.", lastEditedIn: .unknown)

                public static let UnknownDeviceBody = MZLocalizedString("FxAPush_DeviceDisconnected_UnknownDevice_body", value: "A device has disconnected from Firefox Sync", comment: "Body of a notification displayed when unnamed device has been disconnected from FxA.", lastEditedIn: .unknown)
            }

            public struct DeviceConnected {
                public static let Title = MZLocalizedString("FxAPush_DeviceConnected_title", value: "Sync Connected", comment: "Title of a notification displayed when another device has connected to FxA.", lastEditedIn: .unknown)
                public static let Body = MZLocalizedString("FxAPush_DeviceConnected_body", value: "Firefox Sync has connected to %@", comment: "Title of a notification displayed when another device has connected to FxA. %@ refers to the name of the newly connected device.", lastEditedIn: .unknown)
            }
        }
    }

    public struct SignIn {

    }

    public static let FxASignin_Title = MZLocalizedString("fxa.signin.turn-on-sync", value: "Turn on Sync", comment: "FxA sign in view title", lastEditedIn: .unknown)
    public static let FxASignin_Subtitle = MZLocalizedString("fxa.signin.camera-signin", value: "Sign In with Your Camera", comment: "FxA sign in view subtitle", lastEditedIn: .unknown)
    public static let FxASignin_QRInstructions = MZLocalizedString("fxa.signin.qr-link-instruction", value: "On your computer open Firefox and go to firefox.com/pair", comment: "FxA sign in view qr code instructions", lastEditedIn: .unknown)
    public static let FxASignin_QRScanSignin = MZLocalizedString("fxa.signin.ready-to-scan", value: "Ready to Scan", comment: "FxA sign in view qr code scan button", lastEditedIn: .unknown)
    public static let FxASignin_EmailSignin = MZLocalizedString("fxa.signin.use-email-instead", value: "Use Email Instead", comment: "FxA sign in view email login button", lastEditedIn: .unknown)
}

// MARK: - FxA QR code scanning screen
extension String {
    public static let FxAQRCode_Instructions = MZLocalizedString("fxa.qr-scanning-view.instructions", value: "Scan the QR code shown at firefox.com/pair", comment: "Instructions shown on qr code scanning view", lastEditedIn: .unknown)
}

// MARK: - FxAWebViewController
extension String {
    public static let FxAWebContentAccessibilityLabel = MZLocalizedString("Web content", comment: "Accessibility label for the main web content view", lastEditedIn: .unknown)
}

// MARK: - Find in page
extension String {
    public static let FindInPagePreviousAccessibilityLabel = MZLocalizedString("Previous in-page result", tableName: "FindInPage", comment: "Accessibility label for previous result button in Find in Page Toolbar.", lastEditedIn: .unknown)
    public static let FindInPageNextAccessibilityLabel = MZLocalizedString("Next in-page result", tableName: "FindInPage", comment: "Accessibility label for next result button in Find in Page Toolbar.", lastEditedIn: .unknown)
    public static let FindInPageDoneAccessibilityLabel = MZLocalizedString("Done", tableName: "FindInPage", comment: "Done button in Find in Page Toolbar.", lastEditedIn: .unknown)
}

// MARK: - G
// MARK: - General
extension String {
    public struct General {
        public static let OKString = MZLocalizedString("OK", comment: "OK button", lastEditedIn: .unknown)
        public static let CancelString = MZLocalizedString("Cancel", comment: "Label for Cancel button", lastEditedIn: .unknown)
        public static let NotNowString = MZLocalizedString("Toasts.NotNow", value: "Not Now", comment: "label for Not Now button", lastEditedIn: .unknown)
        public static let AppStoreString = MZLocalizedString("Toasts.OpenAppStore", value: "Open App Store", comment: "Open App Store button", lastEditedIn: .unknown)
        public static let UndoString = MZLocalizedString("Toasts.Undo", value: "Undo", comment: "Label for button to undo the action just performed", lastEditedIn: .unknown)
        public static let OpenSettingsString = MZLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7", lastEditedIn: .unknown)
    }
}

// MARK: - H
// MARK: - History Panel
extension String {
    public static let SyncedTabsTableViewCellTitle = MZLocalizedString("HistoryPanel.SyncedTabsCell.Title", value: "Synced Devices", comment: "Title for the Synced Tabs Cell in the History Panel", lastEditedIn: .unknown)
    public static let HistoryBackButtonTitle = MZLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel", lastEditedIn: .unknown)
    public static let EmptySyncedTabsPanelStateTitle = MZLocalizedString("HistoryPanel.EmptySyncedTabsState.Title", value: "Firefox Sync", comment: "Title for the empty synced tabs state in the History Panel", lastEditedIn: .unknown)
    public static let EmptySyncedTabsPanelNotSignedInStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelNotSignedInState.Description", value: "Sign in to view a list of tabs from your other devices.", comment: "Description for the empty synced tabs 'not signed in' state in the History Panel", lastEditedIn: .unknown)
    public static let EmptySyncedTabsPanelNotYetVerifiedStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelNotYetVerifiedState.Description", value: "Your account needs to be verified.", comment: "Description for the empty synced tabs 'not yet verified' state in the History Panel", lastEditedIn: .unknown)
    public static let EmptySyncedTabsPanelSingleDeviceSyncStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelSingleDeviceSyncState.Description", value: "Want to see your tabs from other devices here?", comment: "Description for the empty synced tabs 'single device Sync' state in the History Panel", lastEditedIn: .unknown)
    public static let EmptySyncedTabsPanelTabSyncDisabledStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsPanelTabSyncDisabledState.Description", value: "Turn on tab syncing to view a list of tabs from your other devices.", comment: "Description for the empty synced tabs 'tab sync disabled' state in the History Panel", lastEditedIn: .unknown)
    public static let EmptySyncedTabsPanelNullStateDescription = MZLocalizedString("HistoryPanel.EmptySyncedTabsNullState.Description", value: "Your tabs from other devices show up here.", comment: "Description for the empty synced tabs null state in the History Panel", lastEditedIn: .unknown)
    public static let SyncedTabsTableViewCellDescription = MZLocalizedString("HistoryPanel.SyncedTabsCell.Description.Pluralized", value: "%d device(s) connected", comment: "Description that corresponds with a number of devices connected for the Synced Tabs Cell in the History Panel", lastEditedIn: .unknown)
    public static let HistoryPanelEmptyStateTitle = MZLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.", lastEditedIn: .unknown)
    public static let RecentlyClosedTabsButtonTitle = MZLocalizedString("HistoryPanel.RecentlyClosedTabsButton.Title", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel", lastEditedIn: .unknown)
    public static let RecentlyClosedTabsPanelTitle = MZLocalizedString("RecentlyClosedTabsPanel.Title", value: "Recently Closed", comment: "Title for the Recently Closed Tabs Panel", lastEditedIn: .unknown)
    public static let HistoryPanelClearHistoryButtonTitle = MZLocalizedString("HistoryPanel.ClearHistoryButtonTitle", value: "Clear Recent History…", comment: "Title for button in the history panel to clear recent history", lastEditedIn: .unknown)
    public static let FirefoxHomePage = MZLocalizedString("Firefox.HomePage.Title", value: "Firefox Home Page", comment: "Title for firefox about:home page in tab history list", lastEditedIn: .unknown)
    public static let HistoryPanelDelete = MZLocalizedString("Delete", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the history panel.", lastEditedIn: .unknown)
}

// MARK: - Hotkey Titles
extension String {
    public static let ReloadPageTitle = MZLocalizedString("Hotkeys.Reload.DiscoveryTitle", value: "Reload Page", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
    public static let BackTitle = MZLocalizedString("Hotkeys.Back.DiscoveryTitle", value: "Back", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
    public static let ForwardTitle = MZLocalizedString("Hotkeys.Forward.DiscoveryTitle", value: "Forward", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)

    public static let FindTitle = MZLocalizedString("Hotkeys.Find.DiscoveryTitle", value: "Find", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
    public static let SelectLocationBarTitle = MZLocalizedString("Hotkeys.SelectLocationBar.DiscoveryTitle", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
    public static let privateBrowsingModeTitle = MZLocalizedString("Hotkeys.PrivateMode.DiscoveryTitle", value: "Private Browsing Mode", comment: "Label to switch to private browsing mode", lastEditedIn: .unknown)
    public static let normalBrowsingModeTitle = MZLocalizedString("Hotkeys.NormalMode.DiscoveryTitle", value: "Normal Browsing Mode", comment: "Label to switch to normal browsing mode", lastEditedIn: .unknown)
    public static let NewTabTitle = MZLocalizedString("Hotkeys.NewTab.DiscoveryTitle", value: "New Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
    public static let NewPrivateTabTitle = MZLocalizedString("Hotkeys.NewPrivateTab.DiscoveryTitle", value: "New Private Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
    public static let CloseTabTitle = MZLocalizedString("Hotkeys.CloseTab.DiscoveryTitle", value: "Close Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
    public static let ShowNextTabTitle = MZLocalizedString("Hotkeys.ShowNextTab.DiscoveryTitle", value: "Show Next Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
    public static let ShowPreviousTabTitle = MZLocalizedString("Hotkeys.ShowPreviousTab.DiscoveryTitle", value: "Show Previous Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts", lastEditedIn: .unknown)
}


// MARK: - Home Panel Context Menu
extension String {
    public static let OpenInNewTabContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.OpenInNewTab", value: "Open in New Tab", comment: "The title for the Open in New Tab context menu action for sites in Home Panels", lastEditedIn: .unknown)
    public static let OpenInNewPrivateTabContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.OpenInNewPrivateTab", value: "Open in New Private Tab", comment: "The title for the Open in New Private Tab context menu action for sites in Home Panels", lastEditedIn: .unknown)
    public static let BookmarkContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Bookmark", value: "Bookmark", comment: "The title for the Bookmark context menu action for sites in Home Panels", lastEditedIn: .unknown)
    public static let RemoveBookmarkContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.RemoveBookmark", value: "Remove Bookmark", comment: "The title for the Remove Bookmark context menu action for sites in Home Panels", lastEditedIn: .unknown)
    public static let DeleteFromHistoryContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.DeleteFromHistory", value: "Delete from History", comment: "The title for the Delete from History context menu action for sites in Home Panels", lastEditedIn: .unknown)
    public static let ShareContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Share", value: "Share", comment: "The title for the Share context menu action for sites in Home Panels", lastEditedIn: .unknown)
    public static let RemoveContextMenuTitle = MZLocalizedString("HomePanel.ContextMenu.Remove", value: "Remove", comment: "The title for the Remove context menu action for sites in Home Panels", lastEditedIn: .unknown)
    public static let PinTopsiteActionTitle = MZLocalizedString("ActivityStream.ContextMenu.PinTopsite", value: "Pin to Top Sites", comment: "The title for the pinning a topsite action", lastEditedIn: .unknown)
    public static let PinTopsiteActionTitle2 = MZLocalizedString("ActivityStream.ContextMenu.PinTopsite2", value: "Pin", comment: "The title for the pinning a topsite action", lastEditedIn: .unknown)
    public static let UnpinTopsiteActionTitle2 = MZLocalizedString("ActivityStream.ContextMenu.UnpinTopsite", value: "Unpin", comment: "The title for the unpinning a topsite action", lastEditedIn: .unknown)
    public static let AddToShortcutsActionTitle = MZLocalizedString("ActivityStream.ContextMenu.AddToShortcuts", value: "Add to Shortcuts", comment: "The title for the pinning a shortcut action", lastEditedIn: .unknown)
    public static let RemoveFromShortcutsActionTitle = MZLocalizedString("ActivityStream.ContextMenu.RemoveFromShortcuts", value: "Remove from Shortcuts", comment: "The title for removing a shortcut action", lastEditedIn: .unknown)
    public static let RemovePinTopsiteActionTitle = MZLocalizedString("ActivityStream.ContextMenu.RemovePinTopsite", value: "Remove Pinned Site", comment: "The title for removing a pinned topsite action", lastEditedIn: .unknown)
}


// MARK: - I
// MARK: - Intro Onboarding slides
extension String {
    // First Card
    public static let CardTitleWelcome = MZLocalizedString("Intro.Slides.Welcome.Title.v2", tableName: "Intro", value: "Welcome to Firefox", comment: "Title for the first panel 'Welcome' in the First Run tour.", lastEditedIn: .unknown)
    public static let CardTitleAutomaticPrivacy = MZLocalizedString("Intro.Slides.Automatic.Privacy.Title", tableName: "Intro", value: "Automatic Privacy", comment: "Title for the first item in the table related to automatic privacy", lastEditedIn: .unknown)
    public static let CardDescriptionAutomaticPrivacy = MZLocalizedString("Intro.Slides.Automatic.Privacy.Description", tableName: "Intro", value: "Enhanced Tracking Protection blocks malware and stops trackers.", comment: "Description for the first item in the table related to automatic privacy", lastEditedIn: .unknown)
    public static let CardTitleFastSearch = MZLocalizedString("Intro.Slides.Fast.Search.Title", tableName: "Intro", value: "Fast Search", comment: "Title for the second item in the table related to fast searching via address bar", lastEditedIn: .unknown)
    public static let CardDescriptionFastSearch = MZLocalizedString("Intro.Slides.Fast.Search.Description", tableName: "Intro", value: "Search suggestions get you to websites faster.", comment: "Description for the second item in the table related to fast searching via address bar", lastEditedIn: .unknown)
    public static let CardTitleSafeSync = MZLocalizedString("Intro.Slides.Safe.Sync.Title", tableName: "Intro", value: "Safe Sync", comment: "Title for the third item in the table related to safe syncing with a firefox account", lastEditedIn: .unknown)
    public static let CardDescriptionSafeSync = MZLocalizedString("Intro.Slides.Safe.Sync.Description", tableName: "Intro", value: "Protect your logins and data everywhere you use Firefox.", comment: "Description for the third item in the table related to safe syncing with a firefox account", lastEditedIn: .unknown)

    // Second Card
    public static let CardTitleFxASyncDevices = MZLocalizedString("Intro.Slides.Firefox.Account.Sync.Title", tableName: "Intro", value: "Sync Firefox Between Devices", comment: "Title for the first item in the table related to syncing data (bookmarks, history) via firefox account between devices", lastEditedIn: .unknown)
    public static let CardDescriptionFxASyncDevices = MZLocalizedString("Intro.Slides.Firefox.Account.Sync.Description", tableName: "Intro", value: "Bring bookmarks, history, and passwords to Firefox on this device.", comment: "Description for the first item in the table related to syncing data (bookmarks, history) via firefox account between devices", lastEditedIn: .unknown)

    //----Other----//
    public static let CardTitleSearch = MZLocalizedString("Intro.Slides.Search.Title", tableName: "Intro", value: "Your search, your way", comment: "Title for the second  panel 'Search' in the First Run tour.", lastEditedIn: .unknown)
    public static let CardTitlePrivate = MZLocalizedString("Intro.Slides.Private.Title", tableName: "Intro", value: "Browse like no one’s watching", comment: "Title for the third panel 'Private Browsing' in the First Run tour.", lastEditedIn: .unknown)
    public static let CardTitleMail = MZLocalizedString("Intro.Slides.Mail.Title", tableName: "Intro", value: "You’ve got mail… options", comment: "Title for the fourth panel 'Mail' in the First Run tour.", lastEditedIn: .unknown)
    public static let CardTitleSync = MZLocalizedString("Intro.Slides.TrailheadSync.Title.v2", tableName: "Intro", value: "Sync your bookmarks, history, and passwords to your phone.", comment: "Title for the second panel 'Sync' in the First Run tour.", lastEditedIn: .unknown)

    public static let CardTextWelcome = MZLocalizedString("Intro.Slides.Welcome.Description.v2", tableName: "Intro", value: "Fast, private, and on your side.", comment: "Description for the 'Welcome' panel in the First Run tour.", lastEditedIn: .unknown)
    public static let CardTextSearch = MZLocalizedString("Intro.Slides.Search.Description", tableName: "Intro", value: "Searching for something different? Choose another default search engine (or add your own) in Settings.", comment: "Description for the 'Favorite Search Engine' panel in the First Run tour.", lastEditedIn: .unknown)
    public static let CardTextPrivate = MZLocalizedString("Intro.Slides.Private.Description", tableName: "Intro", value: "Tap the mask icon to slip into Private Browsing mode.", comment: "Description for the 'Private Browsing' panel in the First Run tour.", lastEditedIn: .unknown)
    public static let CardTextMail = MZLocalizedString("Intro.Slides.Mail.Description", tableName: "Intro", value: "Use any email app — not just Mail — with Firefox.", comment: "Description for the 'Mail' panel in the First Run tour.", lastEditedIn: .unknown)
    public static let CardTextSync = MZLocalizedString("Intro.Slides.TrailheadSync.Description", tableName: "Intro", value: "Sign in to your account to sync and access more features.", comment: "Description for the 'Sync' panel in the First Run tour.", lastEditedIn: .unknown)
    public static let SignInButtonTitle = MZLocalizedString("Turn on Sync…", tableName: "Intro", comment: "The button that opens the sign in page for sync. See http://mzl.la/1T8gxwo", lastEditedIn: .unknown)
    public static let StartBrowsingButtonTitle = MZLocalizedString("Start Browsing", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo", lastEditedIn: .unknown)
    public static let IntroNextButtonTitle = MZLocalizedString("Intro.Slides.Button.Next", tableName: "Intro", value: "Next", comment: "Next button on the first intro screen.", lastEditedIn: .unknown)
    public static let IntroSignInButtonTitle = MZLocalizedString("Intro.Slides.Button.SignIn", tableName: "Intro", value: "Sign In", comment: "Sign in to Firefox account button on second intro screen.", lastEditedIn: .unknown)
    public static let IntroSignUpButtonTitle = MZLocalizedString("Intro.Slides.Button.SignUp", tableName: "Intro", value: "Sign Up", comment: "Sign up to Firefox account button on second intro screen.", lastEditedIn: .unknown)
}

// MARK: - J

// MARK: - K
// MARK: - Keyboard short cuts
extension String {
    public static let ShowTabTrayFromTabKeyCodeTitle = MZLocalizedString("Tab.ShowTabTray.KeyCodeTitle", value: "Show All Tabs", comment: "Hardware shortcut to open the tab tray from a tab. Shown in the Discoverability overlay when the hardware Command Key is held down.", lastEditedIn: .unknown)
    public static let CloseTabFromTabTrayKeyCodeTitle = MZLocalizedString("TabTray.CloseTab.KeyCodeTitle", value: "Close Selected Tab", comment: "Hardware shortcut to close the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.", lastEditedIn: .unknown)
    public static let CloseAllTabsFromTabTrayKeyCodeTitle = MZLocalizedString("TabTray.CloseAllTabs.KeyCodeTitle", value: "Close All Tabs", comment: "Hardware shortcut to close all tabs from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.", lastEditedIn: .unknown)
    public static let OpenSelectedTabFromTabTrayKeyCodeTitle = MZLocalizedString("TabTray.OpenSelectedTab.KeyCodeTitle", value: "Open Selected Tab", comment: "Hardware shortcut open the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.", lastEditedIn: .unknown)
    public static let OpenNewTabFromTabTrayKeyCodeTitle = MZLocalizedString("TabTray.OpenNewTab.KeyCodeTitle", value: "Open New Tab", comment: "Hardware shortcut to open a new tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.", lastEditedIn: .unknown)
    public static let ReopenClosedTabKeyCodeTitle = MZLocalizedString("ReopenClosedTab.KeyCodeTitle", value: "Reopen Closed Tab", comment: "Hardware shortcut to reopen the last closed tab, from the tab or the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.", lastEditedIn: .unknown)
    public static let SwitchToPBMKeyCodeTitle = MZLocalizedString("SwitchToPBM.KeyCodeTitle", value: "Private Browsing Mode", comment: "Hardware shortcut switch to the private browsing tab or tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.", lastEditedIn: .unknown)
    public static let SwitchToNonPBMKeyCodeTitle = MZLocalizedString("SwitchToNonPBM.KeyCodeTitle", value: "Normal Browsing Mode", comment: "Hardware shortcut for non-private tab or tab. Shown in the Discoverability overlay when the hardware Command Key is held down.", lastEditedIn: .unknown)
}


// MARK: - L
// MARK: - Logins Helper
extension String {
    public static let LoginsHelperSaveLoginButtonTitle = MZLocalizedString("LoginsHelper.SaveLogin.Button", value: "Save Login", comment: "Button to save the user's password", lastEditedIn: .unknown)
    public static let LoginsHelperDontSaveButtonTitle = MZLocalizedString("LoginsHelper.DontSave.Button", value: "Don’t Save", comment: "Button to not save the user's password", lastEditedIn: .unknown)
    public static let LoginsHelperUpdateButtonTitle = MZLocalizedString("LoginsHelper.Update.Button", value: "Update", comment: "Button to update the user's password", lastEditedIn: .unknown)
    public static let LoginsHelperDontUpdateButtonTitle = MZLocalizedString("LoginsHelper.DontUpdate.Button", value: "Don’t Update", comment: "Button to not update the user's password", lastEditedIn: .unknown)
}

// MARK: - Location bar long press menu
extension String {
    public static let PasteAndGoTitle = MZLocalizedString("Menu.PasteAndGo.Title", value: "Paste & Go", comment: "The title for the button that lets you paste and go to a URL", lastEditedIn: .unknown)
    public static let PasteTitle = MZLocalizedString("Menu.Paste.Title", value: "Paste", comment: "The title for the button that lets you paste into the location bar", lastEditedIn: .unknown)
    public static let CopyAddressTitle = MZLocalizedString("Menu.Copy.Title", value: "Copy Address", comment: "The title for the button that lets you copy the url from the location bar.", lastEditedIn: .unknown)
}

// MARK: - LibraryPanel
extension String {
    public struct LibraryPanel {
        public struct AccessibilityLabels {
            public static let Bookmarks = MZLocalizedString("Bookmarks", comment: "Panel accessibility label", lastEditedIn: .unknown)
            public static let History = MZLocalizedString("History", comment: "Panel accessibility label", lastEditedIn: .unknown)
            public static let ReadingList = MZLocalizedString("Reading list", comment: "Panel accessibility label", lastEditedIn: .unknown)
            public static let Downloads = MZLocalizedString("Downloads", comment: "Panel accessibility label", lastEditedIn: .unknown)
            public static let SyncedTabs = MZLocalizedString("Synced Tabs", comment: "Panel accessibility label", lastEditedIn: .unknown)
        }
    }
}

// MARK: - LibraryViewController
extension String {
    public static let LibraryPanelChooserAccessibilityLabel = MZLocalizedString("Panel Chooser", comment: "Accessibility label for the Library panel's bottom toolbar containing a list of the home panels (top sites, bookmarks, history, remote tabs, reading list).", lastEditedIn: .unknown)
}

// MARK: - Login
extension String {
    public struct Login {
        public static let NoLoginsFound = MZLocalizedString("No logins found", tableName: "LoginManager", comment: "Label displayed when no logins are found after searching.", lastEditedIn: .unknown)

        public struct List {
            public static let DeselctAll = MZLocalizedString("Deselect All", tableName: "LoginManager", comment: "Label for the button used to deselect all logins.", lastEditedIn: .unknown)
            public static let SelctAll = MZLocalizedString("Select All", tableName: "LoginManager", comment: "Label for the button used to select all logins.", lastEditedIn: .unknown)
            public static let Delete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.", lastEditedIn: .unknown)
        }

        public struct Detail {
            public static let Username = MZLocalizedString("Username", tableName: "LoginManager", comment: "Label displayed above the username row in Login Detail View.", lastEditedIn: .unknown)
            public static let Password = MZLocalizedString("Password", tableName: "LoginManager", comment: "Label displayed above the password row in Login Detail View.", lastEditedIn: .unknown)
            public static let Website = MZLocalizedString("Website", tableName: "LoginManager", comment: "Label displayed above the website row in Login Detail View.", lastEditedIn: .unknown)
            public static let CreatedAt =  MZLocalizedString("Created %@", tableName: "LoginManager", comment: "Label describing when the current login was created with the timestamp as the parameter.", lastEditedIn: .unknown)
            public static let ModifiedAt = MZLocalizedString("Modified %@", tableName: "LoginManager", comment: "Label describing when the current login was last modified with the timestamp as the parameter.", lastEditedIn: .unknown)
            public static let Delete = MZLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.", lastEditedIn: .unknown)
        }
    }
}

// MARK: - M
// MARK: - MenuHelper
extension String {
    public struct MenuHelper {
        public static let PasteAndGo = MZLocalizedString("UIMenuItem.PasteGo", value: "Paste & Go", comment: "The menu item that pastes the current contents of the clipboard into the URL bar and navigates to the page", lastEditedIn: .unknown)
        public static let Reveal = MZLocalizedString("Reveal", tableName: "LoginManager", comment: "Reveal password text selection menu item", lastEditedIn: .unknown)
        public static let Hide =  MZLocalizedString("Hide", tableName: "LoginManager", comment: "Hide password text selection menu item", lastEditedIn: .unknown)
        public static let Copy = MZLocalizedString("Copy", tableName: "LoginManager", comment: "Copy password text selection menu item", lastEditedIn: .unknown)
        public static let OpenAndFill = MZLocalizedString("Open & Fill", tableName: "LoginManager", comment: "Open and Fill website text selection menu item", lastEditedIn: .unknown)
        public static let FindInPage = MZLocalizedString("Find in Page", tableName: "FindInPage", comment: "Text selection menu item", lastEditedIn: .unknown)
        public static let SearchWithFirefox = MZLocalizedString("UIMenuItem.SearchWithFirefox", value: "Search with Firefox", comment: "Search in New Tab Text selection menu item", lastEditedIn: .unknown)
    }
}

// MARK: - MR1 Strings
extension String {
    public static let AwesomeBarSearchWithEngineButtonTitle = MZLocalizedString("Awesomebar.SearchWithEngine.Title", value: "Search with %@", comment: "Title for button to suggest searching with a search engine. First argument is the name of the search engine to select", lastEditedIn: .unknown)
    public static let AwesomeBarSearchWithEngineButtonDescription = MZLocalizedString("Awesomebar.SearchWithEngine.Description", value: "Search %@ directly from the address bar", comment: "Description for button to suggest searching with a search engine. First argument is the name of the search engine to select", lastEditedIn: .unknown)
}


// MARK: - N
// MARK: - New tab choice settings
extension String {
    public static let CustomNewPageURL = MZLocalizedString("Settings.NewTab.CustomURL", value: "Custom URL", comment: "Label used to set a custom url as the new tab option (homepage).", lastEditedIn: .unknown)
    public static let SettingsNewTabSectionName = MZLocalizedString("Settings.NewTab.SectionName", value: "New Tab", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behavior.", lastEditedIn: .unknown)
    public static let NewTabSectionName =
        MZLocalizedString("Settings.NewTab.TopSectionName", value: "Show", comment: "Label at the top of the New Tab screen after entering New Tab in settings", lastEditedIn: .unknown)
    public static let SettingsNewTabTitle = MZLocalizedString("Settings.NewTab.Title", value: "New Tab", comment: "Title displayed in header of the setting panel.", lastEditedIn: .unknown)
    public static let NewTabSectionNameFooter =
        MZLocalizedString("Settings.NewTab.TopSectionNameFooter", value: "Choose what to load when opening a new tab", comment: "Footer at the bottom of the New Tab screen after entering New Tab in settings", lastEditedIn: .unknown)
    public static let SettingsNewTabTopSites = MZLocalizedString("Settings.NewTab.Option.FirefoxHome", value: "Firefox Home", comment: "Option in settings to show Firefox Home when you open a new tab", lastEditedIn: .unknown)
    public static let SettingsNewTabBookmarks = MZLocalizedString("Settings.NewTab.Option.Bookmarks", value: "Bookmarks", comment: "Option in settings to show bookmarks when you open a new tab", lastEditedIn: .unknown)
    public static let SettingsNewTabHistory = MZLocalizedString("Settings.NewTab.Option.History", value: "History", comment: "Option in settings to show history when you open a new tab", lastEditedIn: .unknown)
    public static let SettingsNewTabReadingList = MZLocalizedString("Settings.NewTab.Option.ReadingList", value: "Show your Reading List", comment: "Option in settings to show reading list when you open a new tab", lastEditedIn: .unknown)
    public static let SettingsNewTabBlankPage = MZLocalizedString("Settings.NewTab.Option.BlankPage", value: "Blank Page", comment: "Option in settings to show a blank page when you open a new tab", lastEditedIn: .unknown)
    public static let SettingsNewTabHomePage = MZLocalizedString("Settings.NewTab.Option.HomePage", value: "Homepage", comment: "Option in settings to show your homepage when you open a new tab", lastEditedIn: .unknown)
    public static let SettingsNewTabDescription = MZLocalizedString("Settings.NewTab.Description", value: "When you open a New Tab:", comment: "A description in settings of what the new tab choice means", lastEditedIn: .unknown)
    // AS Panel settings
    public static let SettingsNewTabASTitle = MZLocalizedString("Settings.NewTab.Option.ASTitle", value: "Customize Top Sites", comment: "The title of the section in newtab that lets you modify the topsites panel", lastEditedIn: .unknown)
    public static let SettingsNewTabPocket = MZLocalizedString("Settings.NewTab.Option.Pocket", value: "Trending on Pocket", comment: "Option in settings to turn on off pocket recommendations", lastEditedIn: .unknown)
    public static let SettingsNewTabRecommendedByPocket = MZLocalizedString("Settings.NewTab.Option.RecommendedByPocket", value: "Recommended by %@", comment: "Option in settings to turn on off pocket recommendations First argument is the pocket brand name", lastEditedIn: .unknown)
    public static let SettingsNewTabRecommendedByPocketDescription = MZLocalizedString("Settings.NewTab.Option.RecommendedByPocketDescription", value: "Exceptional content curated by %@, part of the %@ family", comment: "Descriptoin for the option in settings to turn on off pocket recommendations. First argument is the pocket brand name, second argument is the pocket product name.", lastEditedIn: .unknown)
    public static let SettingsNewTabPocketFooter = MZLocalizedString("Settings.NewTab.Option.PocketFooter", value: "Great content from around the web.", comment: "Footer caption for pocket settings", lastEditedIn: .unknown)
    public static let SettingsNewTabHiglightsHistory = MZLocalizedString("Settings.NewTab.Option.HighlightsHistory", value: "Visited", comment: "Option in settings to turn off history in the highlights section", lastEditedIn: .unknown)
    public static let SettingsNewTabHighlightsBookmarks = MZLocalizedString("Settings.NewTab.Option.HighlightsBookmarks", value: "Recent Bookmarks", comment: "Option in the settings to turn off recent bookmarks in the Highlights section", lastEditedIn: .unknown)
    public static let SettingsTopSitesCustomizeTitle = MZLocalizedString("Settings.NewTab.Option.CustomizeTitle", value: "Customize Firefox Home", comment: "The title for the section to customize top sites in the new tab settings page.", lastEditedIn: .unknown)
    public static let SettingsTopSitesCustomizeFooter = MZLocalizedString("Settings.NewTab.Option.CustomizeFooter", value: "The sites you visit most", comment: "The footer for the section to customize top sites in the new tab settings page.", lastEditedIn: .unknown)
    public static let SettingsTopSitesCustomizeFooter2 = MZLocalizedString("Settings.NewTab.Option.CustomizeFooter2", value: "Sites you save or visit", comment: "The footer for the section to customize top sites in the new tab settings page.", lastEditedIn: .unknown)
}

// MARK: - Nimbus settings
extension String {
    public static let SettingsStudiesSectionName = MZLocalizedString("Settings.Studies.SectionName", value: "Studies", comment: "Title displayed in header of the Studies panel", lastEditedIn: .unknown)
    public static let SettingsStudiesActiveSectionTitle = MZLocalizedString("Settings.Studies.Active.SectionName", value: "Active", comment: "Section title for all studies that are currently active", lastEditedIn: .unknown)
    public static let SettingsStudiesCompletedSectionTitle = MZLocalizedString("Settings.Studies.Completed.SectionName", value: "Completed", comment: "Section title for all studies that are completed", lastEditedIn: .unknown)
    public static let SettingsStudiesRemoveButton = MZLocalizedString("Settings.Studies.Remove.Button", value: "Remove", comment: "Button title displayed next to each study allowing the user to opt-out of the study", lastEditedIn: .unknown)

    public static let SettingsStudiesToggleTitle = MZLocalizedString("Settings.Studies.Toggle.Title", value: "Studies", comment: "Label used as a toggle item in Settings. When this is off, the user is opting out of all studies.", lastEditedIn: .unknown)
    public static let SettingsStudiesToggleLink = MZLocalizedString("Settings.Studies.Toggle.Link", value: "Learn More.", comment: "Title for a link that explains what Mozilla means by Studies", lastEditedIn: .unknown)

    public static let SettingsStudiesToggleValueOn = MZLocalizedString("Settings.Studies.Toggle.On", value: "On", comment: "Toggled ON to participate in studies", lastEditedIn: .unknown)
    public static let SettingsStudiesToggleValueOff = MZLocalizedString("Settings.Studies.Toggle.Off", value: "Off", comment: "Toggled OFF to opt-out of studies", lastEditedIn: .unknown)
}

// MARK: - Notifications
// These are displayed when the app is backgrounded or the device is locked.
extension String {
    public struct Notifications {
        public struct SentTab {
            // zero tabs
            public static let NoTabArrivingTitle = MZLocalizedString("SentTab.NoTabArrivingNotification.title", value: "Firefox Sync", comment: "Title of notification received after a spurious message from FxA has been received.", lastEditedIn: .unknown)
            public static let NoTabArrivingBody =
                MZLocalizedString("SentTab.NoTabArrivingNotification.body", value: "Tap to begin", comment: "Body of notification received after a spurious message from FxA has been received.", lastEditedIn: .unknown)

            // one or more tabs
            public static let TabArrivingNoDeviceTitle = MZLocalizedString("SentTab_TabArrivingNotification_NoDevice_title", value: "Tab received", comment: "Title of notification shown when the device is sent one or more tabs from an unnamed device.", lastEditedIn: .unknown)
            public static let TabArrivingNoDeviceBody = MZLocalizedString("SentTab_TabArrivingNotification_NoDevice_body", value: "New tab arrived from another device.", comment: "Body of notification shown when the device is sent one or more tabs from an unnamed device.", lastEditedIn: .unknown)
            public static let TabArrivingWithDeviceTitle = MZLocalizedString("SentTab_TabArrivingNotification_WithDevice_title", value: "Tab received from %@", comment: "Title of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the device name. This device name will be localized by that device.", lastEditedIn: .unknown)
            public static let TabArrivingWithDeviceBody = MZLocalizedString("SentTab_TabArrivingNotification_WithDevice_body", value: "New tab arrived in %@", comment: "Body of notification shown when the device is sent one or more tabs from the named device. %@ is the placeholder for the app name.", lastEditedIn: .unknown)

            // Notification Actions
            public static let ViewActionTitle = MZLocalizedString("SentTab.ViewAction.title", value: "View", comment: "Label for an action used to view one or more tabs from a notification.", lastEditedIn: .unknown)
        }
    }
}


// MARK: - O
// MARK: - Open With Settings
extension String {
    public static let SettingsOpenWithSectionName = MZLocalizedString("Settings.OpenWith.SectionName", value: "Mail App", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behavior.", lastEditedIn: .unknown)
    public static let SettingsOpenWithPageTitle = MZLocalizedString("Settings.OpenWith.PageTitle", value: "Open mail links with", comment: "Title for Open With Settings", lastEditedIn: .unknown)
}


// MARK: - P
// MARK: - PhotonActionSheet String
extension String {
    public static let CloseButtonTitle = MZLocalizedString("PhotonMenu.close", value: "Close", comment: "Button for closing the menu action sheet", lastEditedIn: .unknown)
}

// MARK: - Page context menu items (i.e. links and images).
extension String {
    public static let ContextMenuOpenInNewTab = MZLocalizedString("ContextMenu.OpenInNewTabButtonTitle", value: "Open in New Tab", comment: "Context menu item for opening a link in a new tab", lastEditedIn: .unknown)
    public static let ContextMenuOpenInNewPrivateTab = MZLocalizedString("ContextMenu.OpenInNewPrivateTabButtonTitle", tableName: "PrivateBrowsing", value: "Open in New Private Tab", comment: "Context menu option for opening a link in a new private tab", lastEditedIn: .unknown)

    public static let ContextMenuOpenLinkInNewTab = MZLocalizedString("ContextMenu.OpenLinkInNewTabButtonTitle", value: "Open Link in New Tab", comment: "Context menu item for opening a link in a new tab", lastEditedIn: .unknown)
    public static let ContextMenuOpenLinkInNewPrivateTab = MZLocalizedString("ContextMenu.OpenLinkInNewPrivateTabButtonTitle", value: "Open Link in New Private Tab", comment: "Context menu item for opening a link in a new private tab", lastEditedIn: .unknown)

    public static let ContextMenuBookmarkLink = MZLocalizedString("ContextMenu.BookmarkLinkButtonTitle", value: "Bookmark Link", comment: "Context menu item for bookmarking a link URL", lastEditedIn: .unknown)
    public static let ContextMenuDownloadLink = MZLocalizedString("ContextMenu.DownloadLinkButtonTitle", value: "Download Link", comment: "Context menu item for downloading a link URL", lastEditedIn: .unknown)
    public static let ContextMenuCopyLink = MZLocalizedString("ContextMenu.CopyLinkButtonTitle", value: "Copy Link", comment: "Context menu item for copying a link URL to the clipboard", lastEditedIn: .unknown)
    public static let ContextMenuShareLink = MZLocalizedString("ContextMenu.ShareLinkButtonTitle", value: "Share Link", comment: "Context menu item for sharing a link URL", lastEditedIn: .unknown)
    public static let ContextMenuSaveImage = MZLocalizedString("ContextMenu.SaveImageButtonTitle", value: "Save Image", comment: "Context menu item for saving an image", lastEditedIn: .unknown)
    public static let ContextMenuCopyImage = MZLocalizedString("ContextMenu.CopyImageButtonTitle", value: "Copy Image", comment: "Context menu item for copying an image to the clipboard", lastEditedIn: .unknown)
    public static let ContextMenuCopyImageLink = MZLocalizedString("ContextMenu.CopyImageLinkButtonTitle", value: "Copy Image Link", comment: "Context menu item for copying an image URL to the clipboard", lastEditedIn: .unknown)
}

// MARK: - Photo Library access
extension String {
    public static let PhotoLibraryFirefoxWouldLikeAccessTitle = MZLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessTitle", value: "Firefox would like to access your Photos", comment: "See http://mzl.la/1G7uHo7", lastEditedIn: .unknown)
    public static let PhotoLibraryFirefoxWouldLikeAccessMessage = MZLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessMessage", value: "This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7", lastEditedIn: .unknown)
}

// MARK: - PasswordAutofill extension
extension String {
    public static let PasswordAutofillTitle = MZLocalizedString("PasswordAutoFill.SectionTitle", value: "Firefox Credentials", comment: "Title of the extension that shows firefox passwords", lastEditedIn: .unknown)
    public static let CredentialProviderNoCredentialError = MZLocalizedString("PasswordAutoFill.NoPasswordsFoundTitle", value: "You don’t have any credentials synced from your Firefox Account", comment: "Error message shown in the remote tabs panel", lastEditedIn: .unknown)
    public static let AvailableCredentialsHeader = MZLocalizedString("PasswordAutoFill.PasswordsListTitle", value: "Available Credentials:", comment: "Header for the list of credentials table", lastEditedIn: .unknown)
}


// MARK: - Q
// MARK: - QR Code scanner
extension String {
    public static let ScanQRCodeViewTitle = MZLocalizedString("ScanQRCode.View.Title", value: "Scan QR Code", comment: "Title for the QR code scanner view.", lastEditedIn: .unknown)
    public static let ScanQRCodeInstructionsLabel = MZLocalizedString("ScanQRCode.Instructions.Label", value: "Align QR code within frame to scan", comment: "Text for the instructions label, displayed in the QR scanner view", lastEditedIn: .unknown)
    public static let ScanQRCodeInvalidDataErrorMessage = MZLocalizedString("ScanQRCode.InvalidDataError.Message", value: "The data is invalid", comment: "Text of the prompt that is shown to the user when the data is invalid", lastEditedIn: .unknown)
    public static let ScanQRCodePermissionErrorMessage = MZLocalizedString("ScanQRCode.PermissionError.Message", value: "Please allow Firefox to access your device’s camera in ‘Settings’ -> ‘Privacy’ -> ‘Camera’.", comment: "Text of the prompt user to setup the camera authorization.", lastEditedIn: .unknown)
    public static let ScanQRCodeErrorOKButton = MZLocalizedString("ScanQRCode.Error.OK.Button", value: "OK", comment: "OK button to dismiss the error prompt.", lastEditedIn: .unknown)
}

// MARK: - QuickActions
extension String {
    public static let QuickActionsLastBookmarkTitle = MZLocalizedString("Open Last Bookmark", tableName: "3DTouchActions", comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch", lastEditedIn: .unknown)
}

// MARK: - R
// MARK: - Reader Mode
extension String {
    public struct ReaderMode {
        public static let AvailableVoiceOverAnnouncement = MZLocalizedString("ReaderMode.Available.VoiceOverAnnouncement", value: "Reader Mode available", comment: "Accessibility message e.g. spoken by VoiceOver when Reader Mode becomes available.", lastEditedIn: .unknown)
        public static let ResetFontSizeAccessibilityLabel = MZLocalizedString("Reset text size", comment: "Accessibility label for button resetting font size in display settings of reader mode", lastEditedIn: .unknown)

        public struct Bar {
            public static let MarkAsRead = MZLocalizedString("Mark as Read", comment: "Name for Mark as read button in reader mode", lastEditedIn: .unknown)
            public static let MarkAsUnread = MZLocalizedString("Mark as Unread", comment: "Name for Mark as unread button in reader mode", lastEditedIn: .unknown)
            public static let Settings = MZLocalizedString("Display Settings", comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.", lastEditedIn: .unknown)
            public static let AddToReadingList = MZLocalizedString("Add to Reading List", comment: "Name for button adding current article to reading list in reader mode", lastEditedIn: .unknown)
            public static let RemoveFromReadingList = MZLocalizedString("Remove from Reading List", comment: "Name for button removing current article from reading list in reader mode", lastEditedIn: .unknown)
        }
    }
}

// MARK: - ReaderPanel
extension String {
    public struct ReaderPanel {
        public static let Remove = MZLocalizedString("Remove", comment: "Title for the button that removes a reading list item", lastEditedIn: .unknown)
        public static let MarkAsRead = MZLocalizedString("Mark as Read", comment: "Title for the button that marks a reading list item as read", lastEditedIn: .unknown)
        public static let MarkAsUnread =  MZLocalizedString("Mark as Unread", comment: "Title for the button that marks a reading list item as unread", lastEditedIn: .unknown)
        public static let UnreadAccessibilityLabel = MZLocalizedString("unread", comment: "Accessibility label for unread article in reading list. It's a past participle - functions as an adjective.", lastEditedIn: .unknown)
        public static let ReadAccessibilityLabel = MZLocalizedString("read", comment: "Accessibility label for read article in reading list. It's a past participle - functions as an adjective.", lastEditedIn: .unknown)
        public static let Welcome = MZLocalizedString("Welcome to your Reading List", comment: "See http://mzl.la/1LXbDOL", lastEditedIn: .unknown)
        public static let ReadingModeDescription = MZLocalizedString("Open articles in Reader View by tapping the book icon when it appears in the title bar.", comment: "See http://mzl.la/1LXbDOL", lastEditedIn: .unknown)
        public static let ReadingListDescription = MZLocalizedString("Save pages to your Reading List by tapping the book plus icon in the Reader View controls.", comment: "See http://mzl.la/1LXbDOL", lastEditedIn: .unknown)
    }
}

// MARK: - Remote Tabs Panel
extension String {
    // Backup and active strings added in Bug 1205294.
    public static let RemoteTabEmptyStateInstructionsSyncTabsPasswordsBookmarksString = MZLocalizedString("Sync your tabs, bookmarks, passwords and more.", comment: "Text displayed when the Sync home panel is empty, describing the features provided by Sync to invite the user to log in.", lastEditedIn: .unknown)
    public static let RemoteTabEmptyStateInstructionsSyncTabsPasswordsString = MZLocalizedString("Sync your tabs, passwords and more.", comment: "Text displayed when the Sync home panel is empty, describing the features provided by Sync to invite the user to log in.", lastEditedIn: .unknown)
    public static let RemoteTabEmptyStateInstructionsGetTabsBookmarksPasswordsString = MZLocalizedString("Get your open tabs, bookmarks, and passwords from your other devices.", comment: "A re-worded offer about Sync, displayed when the Sync home panel is empty, that emphasizes one-way data transfer, not syncing.", lastEditedIn: .unknown)

    public static let RemoteTabErrorNoTabs = MZLocalizedString("You don’t have any tabs open in Firefox on your other devices.", comment: "Error message in the remote tabs panel", lastEditedIn: .unknown)
    public static let RemoteTabErrorFailedToSync = MZLocalizedString("There was a problem accessing tabs from your other devices. Try again in a few moments.", comment: "Error message in the remote tabs panel", lastEditedIn: .unknown)
    public static let RemoteTabLastSync = MZLocalizedString("Last synced: %@", comment: "Remote tabs last synced time. Argument is the relative date string.", lastEditedIn: .unknown)
    public static let RemoteTabComputerAccessibilityLabel = MZLocalizedString("computer", comment: "Accessibility label for Desktop Computer (PC) image in remote tabs list", lastEditedIn: .unknown)
    public static let RemoteTabMobileAccessibilityLabel =  MZLocalizedString("mobile device", comment: "Accessibility label for Mobile Device image in remote tabs list", lastEditedIn: .unknown)
    public static let RemoteTabCreateAccount = MZLocalizedString("Create an account", comment: "See http://mzl.la/1Qtkf0j", lastEditedIn: .unknown)
}


// MARK: - Reader Mode Handler
extension String {
    public static let ReaderModeHandlerLoadingContent = MZLocalizedString("Loading content…", comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Firefox reader mode from another app.", lastEditedIn: .unknown)
    public static let ReaderModeHandlerPageCantDisplay = MZLocalizedString("The page could not be displayed in Reader View.", comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.", lastEditedIn: .unknown)
    public static let ReaderModeHandlerLoadOriginalPage = MZLocalizedString("Load original page", comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.", lastEditedIn: .unknown)
    public static let ReaderModeHandlerError = MZLocalizedString("There was an error converting the page", comment: "Error displayed when reader mode cannot be enabled", lastEditedIn: .unknown)
}

// MARK: - ReaderModeStyle
extension String {
    public static let ReaderModeStyleBrightnessAccessibilityLabel = MZLocalizedString("Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings", lastEditedIn: .unknown)
    public static let ReaderModeStyleFontTypeAccessibilityLabel = MZLocalizedString("Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings", lastEditedIn: .unknown)
    public static let ReaderModeStyleSansSerifFontType = MZLocalizedString("Sans-serif", comment: "Font type setting in the reading view settings", lastEditedIn: .unknown)
    public static let ReaderModeStyleSerifFontType = MZLocalizedString("Serif", comment: "Font type setting in the reading view settings", lastEditedIn: .unknown)
    public static let ReaderModeStyleSmallerLabel = MZLocalizedString("-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.", lastEditedIn: .unknown)
    public static let ReaderModeStyleSmallerAccessibilityLabel = MZLocalizedString("Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode", lastEditedIn: .unknown)
    public static let ReaderModeStyleLargerLabel = MZLocalizedString("+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.", lastEditedIn: .unknown)
    public static let ReaderModeStyleLargerAccessibilityLabel = MZLocalizedString("Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode", lastEditedIn: .unknown)
    public static let ReaderModeStyleFontSize = MZLocalizedString("Aa", comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.", lastEditedIn: .unknown)
    public static let ReaderModeStyleChangeColorSchemeAccessibilityHint = MZLocalizedString("Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings", lastEditedIn: .unknown)
    public static let ReaderModeStyleLightLabel = MZLocalizedString("Light", comment: "Light theme setting in Reading View settings", lastEditedIn: .unknown)
    public static let ReaderModeStyleDarkLabel = MZLocalizedString("Dark", comment: "Dark theme setting in Reading View settings", lastEditedIn: .unknown)
    public static let ReaderModeStyleSepiaLabel = MZLocalizedString("Sepia", comment: "Sepia theme setting in Reading View settings", lastEditedIn: .unknown)
}


// MARK: - S

extension String {
    // MARK: - Settings
    public struct Settings {

        public struct SectionTitle {
            public static let Privacy = MZLocalizedString("Privacy", comment: "Privacy section title", lastEditedIn: .unknown)
            public static let Support = MZLocalizedString("Support", comment: "Support section title", lastEditedIn: .unknown)
            public static let About = MZLocalizedString("About", comment: "About settings section title", lastEditedIn: .unknown)
            public static let General = MZLocalizedString("Settings.General.SectionName", value: "General", comment: "General settings section title", lastEditedIn: .unknown)
        }

        public static let Title = MZLocalizedString("Settings", comment: "Title in the settings view controller title bar", lastEditedIn: .unknown)
        public static let Done = MZLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar", lastEditedIn: .unknown)

        public struct GeneralSection {
            public static let Search = MZLocalizedString("Search", comment: "Open search section of settings", lastEditedIn: .unknown)
            public static let SiriSectionName = MZLocalizedString("Settings.Siri.SectionName", value: "Siri Shortcuts", comment: "The option that takes you to the siri shortcuts settings page", lastEditedIn: .unknown)
            public static let BlockPopups = MZLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting", lastEditedIn: .unknown)
            public static let OfferClipboardBarTitle = MZLocalizedString("Settings.OfferClipboardBar.Title", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349", lastEditedIn: .unknown)
            public static let OfferClipboardBarStatus = MZLocalizedString("Settings.OfferClipboardBar.Status", value: "When Opening Firefox", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349", lastEditedIn: .unknown)
            public static let ShowLinkPreviewsTitle = MZLocalizedString("Settings.ShowLinkPreviews.Title", value: "Show Link Previews", comment: "Title of setting to enable link previews when long-pressing links.", lastEditedIn: .unknown)
            public static let ShowLinkPreviewsStatus = MZLocalizedString("Settings.ShowLinkPreviews.Status", value: "When Long-pressing Links", comment: "Description displayed under the ”Show Link Previews” option", lastEditedIn: .unknown)
        }

        public struct PrivacySection {
            public static let PrivacyPolicy = MZLocalizedString("Privacy Policy", comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/", lastEditedIn: .unknown)
            public static let ClosePrivateTabsTitle = MZLocalizedString("Close Private Tabs", tableName: "PrivateBrowsing", comment: "Setting for closing private tabs", lastEditedIn: .unknown)
            public static let ClosePrivateTabsDescription = MZLocalizedString("When Leaving Private Browsing", tableName: "PrivateBrowsing", comment: "Will be displayed in Settings under 'Close Private Tabs'", lastEditedIn: .unknown)
            public static let DataManagementSectionName = MZLocalizedString("Settings.DataManagement.SectionName", value: "Data Management", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.", lastEditedIn: .unknown)
        }

        public struct SupportSection {
            public static let SendUsageTitle = MZLocalizedString("Settings.SendUsage.Title", value: "Send Usage Data", comment: "The title for the setting to send usage data.", lastEditedIn: .unknown)
            public static let SendUsageMessage = MZLocalizedString("Settings.SendUsage.Message", value: "Mozilla strives to only collect what we need to provide and improve Firefox for everyone.", comment: "A short description that explains why mozilla collects usage data.", lastEditedIn: .unknown)
            public static let SendUsageLink = MZLocalizedString("Settings.SendUsage.Link", value: "Learn More.", comment: "title for a link that explains how mozilla collects telemetry", lastEditedIn: .unknown)
            public static let ShowTour = MZLocalizedString("Show Tour", comment: "Show the on-boarding screen again from the settings", lastEditedIn: .unknown)
            public static let StudiesTitle = MZLocalizedString("Settings.Studies.Title", value: "Studies", comment: "Label used as an item in Settings. Tapping on this item takes you to the Studies panel", lastEditedIn: .unknown)
            public static let StudiesToggleMessage = MZLocalizedString("Settings.Studies.Toggle.Message", value: "Firefox may install and run studies from time to time.", comment: "A short description that explains that Mozilla is running studies", lastEditedIn: .unknown)
            public static let SendFeedback = MZLocalizedString("Send Feedback", comment: "Menu item in settings used to open input.mozilla.org where people can submit feedback", lastEditedIn: .unknown)
            public static let Help = MZLocalizedString("Help", comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ", lastEditedIn: .unknown)
        }

        public struct AboutSection {
            public static let Licenses = MZLocalizedString("Licenses", comment: "Settings item that opens a tab containing the licenses. See http://mzl.la/1NSAWCG", lastEditedIn: .unknown)
            public static let YourRights = MZLocalizedString("Your Rights", comment: "Your Rights settings section title", lastEditedIn: .unknown)
        }

        public struct SiriShortcuts {
            public static let SiriSectionDescription = MZLocalizedString("Settings.Siri.SectionDescription", value: "Use Siri shortcuts to quickly open Firefox via Siri", comment: "The description that describes what siri shortcuts are", lastEditedIn: .unknown)
            public static let SiriOpenURL = MZLocalizedString("Settings.Siri.OpenTabShortcut", value: "Open New Tab", comment: "The description of the open new tab siri shortcut", lastEditedIn: .unknown)
        }

        // MARK: - Search
        public struct Search {
            public static let Title = MZLocalizedString("Search", comment: "Navigation title for search settings.", lastEditedIn: .unknown)
            public static let DefaultSearchEngineAccessibilityLabel = MZLocalizedString("Default Search Engine", comment: "Accessibility label for default search engine setting.", lastEditedIn: .unknown)
            public static let ShowSearchSuggestions = MZLocalizedString("Show Search Suggestions", comment: "Label for show search suggestions setting.", lastEditedIn: .unknown)
            public static let DefaultSearchEngineTitle = MZLocalizedString("Default Search Engine", comment: "Title for default search engine settings section.", lastEditedIn: .unknown)
            public static let QuickSearchEnginesTitle = MZLocalizedString("Quick-Search Engines", comment: "Title for quick-search engines settings section.", lastEditedIn: .unknown)

            // MARK: - SearchEngine Picker
            public struct EnginePicker {
                public static let Title = MZLocalizedString("Default Search Engine", comment: "Title for default search engine picker.", lastEditedIn: .unknown)
                public static let Cancel = MZLocalizedString("Cancel", comment: "Label for Cancel button", lastEditedIn: .unknown)
            }

            // MARK: - Add Custom Engine
            public struct AddCustomEngine {
                public static let AddCustomEngine = MZLocalizedString("Settings.AddCustomEngine", value: "Add Search Engine", comment: "The button text in Search Settings that opens the Custom Search Engine view.", lastEditedIn: .unknown)
                public static let Title = MZLocalizedString("Settings.AddCustomEngine.Title", value: "Add Search Engine", comment: "The title of the  Custom Search Engine view.", lastEditedIn: .unknown)
                public static let TitleLabel = MZLocalizedString("Settings.AddCustomEngine.TitleLabel", value: "Title", comment: "The title for the field which sets the title for a custom search engine.", lastEditedIn: .unknown)
                public static let URLLabel = MZLocalizedString("Settings.AddCustomEngine.URLLabel", value: "URL", comment: "The title for URL Field", lastEditedIn: .unknown)
                public static let TitlePlaceholder = MZLocalizedString("Settings.AddCustomEngine.TitlePlaceholder", value: "Search Engine", comment: "The placeholder for Title Field when saving a custom search engine.", lastEditedIn: .unknown)
                public static let URLPlaceholder = MZLocalizedString("Settings.AddCustomEngine.URLPlaceholder", value: "URL (Replace Query with %s)", comment: "The placeholder for URL Field when saving a custom search engine", lastEditedIn: .unknown)
                public static let SaveButtonText = MZLocalizedString("Settings.AddCustomEngine.SaveButtonText", value: "Save", comment: "The text on the Save button when saving a custom search engine", lastEditedIn: .unknown)
            }

            public struct ThirdPartyEngine {
                public static let EngineAdded = MZLocalizedString("Search.ThirdPartyEngines.AddSuccess", value: "Added Search engine!", comment: "The success message that appears after a user sucessfully adds a new search engine", lastEditedIn: .unknown)
                public static let AddTitle = MZLocalizedString("Search.ThirdPartyEngines.AddTitle", value: "Add Search Provider?", comment: "The title that asks the user to Add the search provider", lastEditedIn: .unknown)
                public static let AddMessage = MZLocalizedString("Search.ThirdPartyEngines.AddMessage", value: "The new search engine will appear in the quick search bar.", comment: "The message that asks the user to Add the search provider explaining where the search engine will appear", lastEditedIn: .unknown)
                public static let CancelButton = MZLocalizedString("Search.ThirdPartyEngines.Cancel", value: "Cancel", comment: "The cancel button if you do not want to add a search engine.", lastEditedIn: .unknown)
                public static let OkayButton = MZLocalizedString("Search.ThirdPartyEngines.OK", value: "OK", comment: "The confirmation button", lastEditedIn: .unknown)
                public static let FailedTitle = MZLocalizedString("Search.ThirdPartyEngines.FailedTitle", value: "Failed", comment: "A title explaining that we failed to add a search engine", lastEditedIn: .unknown)
                public static let FailedMessage = MZLocalizedString("Search.ThirdPartyEngines.FailedMessage", value: "The search provider could not be added.", comment: "A title explaining that we failed to add a search engine", lastEditedIn: .unknown)

                public static let FormErrorTitle = MZLocalizedString("Search.ThirdPartyEngines.FormErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.", lastEditedIn: .unknown)
                public static let FormErrorMessage = MZLocalizedString("Search.ThirdPartyEngines.FormErrorMessage", value: "Please fill all fields correctly.", comment: "A message explaining fault in custom search engine form.", lastEditedIn: .unknown)
                public static let DuplicateErrorTitle = MZLocalizedString("Search.ThirdPartyEngines.DuplicateErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.", lastEditedIn: .unknown)
                public static let DuplicateErrorMessage = MZLocalizedString("Search.ThirdPartyEngines.DuplicateErrorMessage", value: "A search engine with this title or URL has already been added.", comment: "A message explaining fault in custom search engine form.", lastEditedIn: .unknown)
            }
        }


        public static let ClearPrivateDataClearButton = MZLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.", lastEditedIn: .unknown)
        public static let ClearAllWebsiteDataButton = MZLocalizedString("Settings.ClearAllWebsiteData.Clear.Button", value: "Clear All Website Data", comment: "Button in Data Management that clears all items.", lastEditedIn: .unknown)
        public static let ClearSelectedWebsiteDataButton = MZLocalizedString("Settings.ClearSelectedWebsiteData.ClearSelected.Button", value: "Clear Items: %1$@", comment: "Button in Data Management that clears private data for the selected items. Parameter is the number of items to be cleared", lastEditedIn: .unknown)

        public static let FilterSitesSearchLabel = MZLocalizedString("Settings.DataManagement.SearchLabel", value: "Filter Sites", comment: "Default text in search bar for Data Management", lastEditedIn: .unknown)
        public static let ClearPrivateDataTitle = MZLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.", lastEditedIn: .unknown)
        public static let DataManagementTitle = MZLocalizedString("Settings.DataManagement.Title", value: "Data Management", comment: "Title displayed in header of the setting panel.", lastEditedIn: .unknown)
        public static let WebsiteDataTitle = MZLocalizedString("Settings.WebsiteData.Title", value: "Website Data", comment: "Title displayed in header of the Data Management panel.", lastEditedIn: .unknown)
        public static let WebsiteDataShowMoreButton = MZLocalizedString("Settings.WebsiteData.ButtonShowMore", value: "Show More", comment: "Button shows all websites on website data tableview", lastEditedIn: .unknown)
        public static let DisconnectSyncAlertTitle = MZLocalizedString("Settings.Disconnect.Title", value: "Disconnect Sync?", comment: "Title of the alert when prompting the user asking to disconnect.", lastEditedIn: .unknown)
        public static let DisconnectSyncAlertBody = MZLocalizedString("Settings.Disconnect.Body", value: "Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Body of the alert when prompting the user asking to disconnect.", lastEditedIn: .unknown)
        public static let DisconnectSyncButton = MZLocalizedString("Settings.Disconnect.Button", value: "Disconnect Sync", comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA", lastEditedIn: .unknown)
        public static let DisconnectCancelAction = MZLocalizedString("Settings.Disconnect.CancelButton", value: "Cancel", comment: "Cancel action button in alert when user is prompted for disconnect", lastEditedIn: .unknown)
        public static let DisconnectDestructiveAction = MZLocalizedString("Settings.Disconnect.DestructiveButton", value: "Disconnect", comment: "Destructive action button in alert when user is prompted for disconnect", lastEditedIn: .unknown)
        public static let SearchDoneButton = MZLocalizedString("Settings.Search.Done.Button", value: "Done", comment: "Button displayed at the top of the search settings.", lastEditedIn: .unknown)
        public static let SearchEditButton = MZLocalizedString("Settings.Search.Edit.Button", value: "Edit", comment: "Button displayed at the top of the search settings.", lastEditedIn: .unknown)
        public static let UseTouchID = MZLocalizedString("Use Touch ID", tableName: "AuthenticationManager", comment: "List section title for when to use Touch ID", lastEditedIn: .unknown)
        public static let UseFaceID = MZLocalizedString("Use Face ID", tableName: "AuthenticationManager", comment: "List section title for when to use Face ID", lastEditedIn: .unknown)
        public static let CopyAppVersionAlertTitle = MZLocalizedString("Settings.CopyAppVersion.Title", value: "Copied to clipboard", comment: "Copy app version alert shown in settings.", lastEditedIn: .unknown)
    }

// MARK: - Advanced Sync Settings (Debug)
// For 'Advanced Sync Settings' view, which is a debug setting. English only, there is little value in maintaining L10N strings for these.
    public static let SettingsAdvancedAccountTitle = "Advanced Sync Settings"
    public static let SettingsAdvancedAccountCustomFxAContentServerURI = "Custom Firefox Account Content Server URI"
    public static let SettingsAdvancedAccountUseCustomFxAContentServerURITitle = "Use Custom FxA Content Server"
    public static let SettingsAdvancedAccountCustomSyncTokenServerURI = "Custom Sync Token Server URI"
    public static let SettingsAdvancedAccountUseCustomSyncTokenServerTitle = "Use Custom Sync Token Server"

    public static let AdvancedAccountUseStageServer = MZLocalizedString("Use stage servers", comment: "Debug option", lastEditedIn: .unknown)
}


// MARK: - Syncing
extension String {
    public struct Syncing {
        public static let SyncingMessageWithEllipsis = MZLocalizedString("Sync.SyncingEllipsis.Label", value: "Syncing…", comment: "Message displayed when the user's account is syncing with ellipsis at the end", lastEditedIn: .unknown)

        public struct FirefoxSync {
            public static let OfflineTitle = MZLocalizedString("SyncState.Offline.Title", value: "Sync is offline", comment: "Title for Sync status message when Sync failed due to being offline", lastEditedIn: .unknown)
            public static let TroubleshootTitle = MZLocalizedString("Settings.TroubleShootSync.Title", value: "Troubleshoot", comment: "Title of link to help page to find out how to solve Sync issues", lastEditedIn: .unknown)
            public static let BookmarksEngine = MZLocalizedString("Bookmarks", comment: "Toggle bookmarks syncing setting", lastEditedIn: .unknown)
            public static let HistoryEngine = MZLocalizedString("History", comment: "Toggle history syncing setting", lastEditedIn: .unknown)
            public static let TabsEngine = MZLocalizedString("Open Tabs", comment: "Toggle tabs syncing setting", lastEditedIn: .unknown)
            public static let LoginsEngine = MZLocalizedString("Logins", comment: "Toggle logins syncing setting", lastEditedIn: .unknown)
        }
    }
}

// MARK: - Snackbar shown when tapping app store link
extension String {
    public struct Snackbar {
        public struct ExternalLinks {
            public static let AppStoreConfirmationTitle = MZLocalizedString("ExternalLink.AppStore.ConfirmationTitle", value: "Open this link in the App Store?", comment: "Question shown to user when tapping a link that opens the App Store app", lastEditedIn: .unknown)
            public static let GenericConfirmation = MZLocalizedString("ExternalLink.AppStore.GenericConfirmationTitle", value: "Open this link in external app?", comment: "Question shown to user when tapping an SMS or MailTo link that opens the external app for those.", lastEditedIn: .unknown)
        }
    }
}

// MARK: - Share extension
extension String {
    public struct ShareExtension {
        public struct SendTo {
            public static let CancelButton = MZLocalizedString("SendTo.Cancel.Button", value: "Cancel", comment: "Button title for cancelling share screen", lastEditedIn: .unknown)
            public static let ErrorOKButton = MZLocalizedString("SendTo.Error.OK.Button", value: "OK", comment: "OK button to dismiss the error prompt.", lastEditedIn: .unknown)
            public static let ErrorTitle = MZLocalizedString("SendTo.Error.Title", value: "The link you are trying to share cannot be shared.", comment: "Title of error prompt displayed when an invalid URL is shared.", lastEditedIn: .unknown)
            public static let ErrorMessage = MZLocalizedString("SendTo.Error.Message", value: "Only HTTP and HTTPS links can be shared.", comment: "Message in error prompt explaining why the URL is invalid.", lastEditedIn: .unknown)
            public static let CloseButton = MZLocalizedString("SendTo.Cancel.Button", value: "Close", comment: "Close button in top navigation bar", lastEditedIn: .unknown)
            public static let NotSignedInText = MZLocalizedString("SendTo.NotSignedIn.Title", value: "You are not signed in to your Firefox Account.", comment: "See http://mzl.la/1ISlXnU", lastEditedIn: .unknown)
            public static let NotSignedInMessage = MZLocalizedString("SendTo.NotSignedIn.Message", value: "Please open Firefox, go to Settings and sign in to continue.", comment: "See http://mzl.la/1ISlXnU", lastEditedIn: .unknown)
            public static let NoDevicesFound = MZLocalizedString("SendTo.NoDevicesFound.Message", value: "You don’t have any other devices connected to this Firefox Account available to sync.", comment: "Error message shown in the remote tabs panel", lastEditedIn: .unknown)
            public static let Title = MZLocalizedString("SendTo.NavBar.Title", value: "Send Tab", comment: "Title of the dialog that allows you to send a tab to a different device", lastEditedIn: .unknown)
            public static let SendButtonTitle = MZLocalizedString("SendTo.SendAction.Text", value: "Send", comment: "Navigation bar button to Send the current page to a device", lastEditedIn: .unknown)
            public static let DevicesListTitle = MZLocalizedString("SendTo.DeviceList.Text", value: "Available devices:", comment: "Header for the list of devices table", lastEditedIn: .unknown)
            public static let Device = String.AppMenu.SendToDeviceTitle
        }

        // The above items are re-used strings from the old extension. New strings below.
        public static let AddToReadingList = MZLocalizedString("ShareExtension.AddToReadingListAction.Title", value: "Add to Reading List", comment: "Action label on share extension to add page to the Firefox reading list.", lastEditedIn: .unknown)
        public static let AddToReadingListDone = MZLocalizedString("ShareExtension.AddToReadingListActionDone.Title", value: "Added to Reading List", comment: "Share extension label shown after user has performed 'Add to Reading List' action.", lastEditedIn: .unknown)
        public static let BookmarkThisPage = MZLocalizedString("ShareExtension.BookmarkThisPageAction.Title", value: "Bookmark This Page", comment: "Action label on share extension to bookmark the page in Firefox.", lastEditedIn: .unknown)
        public static let BookmarkThisPageDone = MZLocalizedString("ShareExtension.BookmarkThisPageActionDone.Title", value: "Bookmarked", comment: "Share extension label shown after user has performed 'Bookmark this Page' action.", lastEditedIn: .unknown)

        public static let OpenInFirefox = MZLocalizedString("ShareExtension.OpenInFirefoxAction.Title", value: "Open in Firefox", comment: "Action label on share extension to immediately open page in Firefox.", lastEditedIn: .unknown)
        public static let SearchInFirefox = MZLocalizedString("ShareExtension.SeachInFirefoxAction.Title", value: "Search in Firefox", comment: "Action label on share extension to search for the selected text in Firefox.", lastEditedIn: .unknown)

        public static let LoadInBackground = MZLocalizedString("ShareExtension.LoadInBackgroundAction.Title", value: "Load in Background", comment: "Action label on share extension to load the page in Firefox when user switches apps to bring it to foreground.", lastEditedIn: .unknown)
        public static let LoadInBackgroundDone = MZLocalizedString("ShareExtension.LoadInBackgroundActionDone.Title", value: "Loading in Firefox", comment: "Share extension label shown after user has performed 'Load in Background' action.", lastEditedIn: .unknown)
    }
}

// MARK: - SearchViewController
extension String {
    public struct SearchView {
        public static let SettingsAccessibilityLabel = MZLocalizedString("Search Settings", tableName: "Search", comment: "Label for search settings button.", lastEditedIn: .unknown)
        public static let SearchEngineAccessibilityLabel = MZLocalizedString("%@ search", tableName: "Search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine.", lastEditedIn: .unknown)
        public static let SuggestionCellSwitchToTabLabel = MZLocalizedString("Search.Awesomebar.SwitchToTab", value: "Switch to tab", comment: "Search suggestion cell label that allows user to switch to tab which they searched for in url bar", lastEditedIn: .unknown)
    }
}



// MARK: - SettingsContent
extension String {
    public static let SettingsContentPageLoadError = MZLocalizedString("Could not load page.", comment: "Error message that is shown in settings when there was a problem loading", lastEditedIn: .unknown)
}

// MARK: - SearchInput
extension String {
    public static let SearchInputAccessibilityLabel = MZLocalizedString("Search Input Field", tableName: "LoginManager", comment: "Accessibility label for the search input field in the Logins list", lastEditedIn: .unknown)
    public static let SearchInputTitle = MZLocalizedString("Search", tableName: "LoginManager", comment: "Title for the search field at the top of the Logins list screen", lastEditedIn: .unknown)
    public static let SearchInputClearAccessibilityLabel = MZLocalizedString("Clear Search", tableName: "LoginManager", comment: "Accessibility message e.g. spoken by VoiceOver after the user taps the close button in the search field to clear the search and exit search mode", lastEditedIn: .unknown)
    public static let SearchInputEnterSearchMode = MZLocalizedString("Enter Search Mode", tableName: "LoginManager", comment: "Accessibility label for entering search mode for logins", lastEditedIn: .unknown)
}

// MARK: - T
// MARK: - Table date section titles
extension String {
    public struct TableDateSectionTitles {
        public static let Today = MZLocalizedString("Today", comment: "History tableview section header", lastEditedIn: .unknown)
        public static let Yesterday = MZLocalizedString("Yesterday", comment: "History tableview section header", lastEditedIn: .unknown)
        public static let LastWeek = MZLocalizedString("Last week", comment: "History tableview section header", lastEditedIn: .unknown)
        public static let LastMonth = MZLocalizedString("Last month", comment: "History tableview section header", lastEditedIn: .unknown)
    }
}

// MARK: - Top Sites
extension String {
    public struct TopSites {
        public static let RemoveButtonAccessibilityLabel = MZLocalizedString("TopSites.RemovePage.Button", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.", lastEditedIn: .unknown)

        // Unused
        public static let EmptyStateDescription = MZLocalizedString("TopSites.EmptyState.Description", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.", lastEditedIn: .unknown)
        public static let EmptyStateTitle = MZLocalizedString("TopSites.EmptyState.Title", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state", lastEditedIn: .unknown)
    }
}

// MARK: - ContentBlocker/TrackingProtection string
extension String {
    public static let SettingsTrackingProtectionSectionName = MZLocalizedString("Settings.TrackingProtection.SectionName", value: "Tracking Protection", comment: "Row in top-level of settings that gets tapped to show the tracking protection settings detail view.", lastEditedIn: .unknown)

    public static let TrackingProtectionEnableTitle = MZLocalizedString("Settings.TrackingProtectionOption.NormalBrowsingLabelOn", value: "Enhanced Tracking Protection", comment: "Settings option to specify that Tracking Protection is on", lastEditedIn: .unknown)

    public static let TrackingProtectionOptionOnOffFooter = MZLocalizedString("Settings.TrackingProtectionOption.EnabledStateFooterLabel", value: "Tracking is the collection of your browsing data across multiple websites.", comment: "Description label shown on tracking protection options screen.", lastEditedIn: .unknown)
    public static let TrackingProtectionOptionProtectionLevelTitle = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelTitle", value: "Protection Level", comment: "Title for tracking protection options section where level can be selected.", lastEditedIn: .unknown)
    public static let TrackingProtectionOptionBlockListsHeader = MZLocalizedString("Settings.TrackingProtection.BlockListsHeader", value: "You can choose which list Firefox will use to block Web elements that may track your browsing activity.", comment: "Header description for tracking protection options section where Basic/Strict block list can be selected", lastEditedIn: .unknown)
    public static let TrackingProtectionOptionBlockListLevelStandard = MZLocalizedString("Settings.TrackingProtectionOption.BasicBlockList", value: "Standard (default)", comment: "Tracking protection settings option for using the basic blocklist.", lastEditedIn: .unknown)
    public static let TrackingProtectionOptionBlockListLevelStrict = MZLocalizedString("Settings.TrackingProtectionOption.BlockListStrict", value: "Strict", comment: "Tracking protection settings option for using the strict blocklist.", lastEditedIn: .unknown)
    public static let TrackingProtectionReloadWithout = MZLocalizedString("Menu.ReloadWithoutTrackingProtection.Title", value: "Reload Without Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website without Tracking Protection", lastEditedIn: .unknown)
    public static let TrackingProtectionReloadWith = MZLocalizedString("Menu.ReloadWithTrackingProtection.Title", value: "Reload With Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website with Tracking Protection enabled", lastEditedIn: .unknown)

    public static let TrackingProtectionProtectionStrictInfoFooter = MZLocalizedString("Settings.TrackingProtection.StrictLevelInfoFooter", value: "Blocking trackers could impact the functionality of some websites.", comment: "Additional information about the strict level setting", lastEditedIn: .unknown)
    public static let TrackingProtectionCellFooter = MZLocalizedString("Settings.TrackingProtection.ProtectionCellFooter", value: "Reduces targeted ads and helps stop advertisers from tracking your browsing.", comment: "Additional information about your Enhanced Tracking Protection", lastEditedIn: .unknown)
    public static let TrackingProtectionStandardLevelDescription = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelStandard.Description", value: "Allows some ad tracking so websites function properly.", comment: "Description for standard level tracker protection", lastEditedIn: .unknown)
    public static let TrackingProtectionStrictLevelDescription = MZLocalizedString("Settings.TrackingProtection.ProtectionLevelStrict.Description", value: "Blocks more trackers, ads, and popups. Pages load faster, but some functionality may not work.", comment: "Description for strict level tracker protection", lastEditedIn: .unknown)
    public static let TrackingProtectionLevelFooter = MZLocalizedString("Settings.TrackingProtection.ProtectionLevel.Footer", value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.", comment: "Footer information for tracker protection level.", lastEditedIn: .unknown)
    public static let TrackerProtectionLearnMore = MZLocalizedString("Settings.TrackingProtection.LearnMore", value: "Learn more", comment: "'Learn more' info link on the Tracking Protection settings screen.", lastEditedIn: .unknown)
    public static let TrackerProtectionAlertTitle =  MZLocalizedString("Settings.TrackingProtection.Alert.Title", value: "Heads up!", comment: "Title for the tracker protection alert.", lastEditedIn: .unknown)
    public static let TrackerProtectionAlertDescription =  MZLocalizedString("Settings.TrackingProtection.Alert.Description", value: "If a site doesn’t work as expected, tap the shield in the address bar and turn off Enhanced Tracking Protection for that page.", comment: "Decription for the tracker protection alert.", lastEditedIn: .unknown)
    public static let TrackerProtectionAlertButton =  MZLocalizedString("Settings.TrackingProtection.Alert.Button", value: "OK, Got It", comment: "Dismiss button for the tracker protection alert.", lastEditedIn: .unknown)
}

// MARK: - Tracking Protection menu
extension String {
    public struct TrackingProtection {
        public static let NoBlockingDescription = MZLocalizedString("Menu.TrackingProtectionNoBlocking.Description", value: "No tracking elements detected on this page.", comment: "The description of the Tracking Protection menu item when no scripts are blocked but tracking protection is enabled.", lastEditedIn: .unknown)
        public static let BlockingMoreInfo = MZLocalizedString("Menu.TrackingProtectionMoreInfo.Description", value: "Learn more about how Tracking Protection blocks online trackers that collect your browsing data across multiple websites.", comment: "more info about what tracking protection is about", lastEditedIn: .unknown)
        public static let EnableTPBlockingGlobally = MZLocalizedString("Menu.TrackingProtectionEnable.Title", value: "Enable Tracking Protection", comment: "A button to enable tracking protection inside the menu.", lastEditedIn: .unknown)
        public static let ETPOn = MZLocalizedString("Menu.EnhancedTrackingProtectionOn.Title", value: "Enhanced Tracking Protection is ON for this site.", comment: "A switch to enable enhanced tracking protection inside the menu.", lastEditedIn: .unknown)
        public static let ETPOff = MZLocalizedString("Menu.EnhancedTrackingProtectionOff.Title", value: "Enhanced Tracking Protection is OFF for this site.", comment: "A switch to disable enhanced tracking protection inside the menu.", lastEditedIn: .unknown)
        public static let StrictETPWithITP = MZLocalizedString("Menu.EnhancedTrackingProtectionStrictWithITP.Title", value: "Firefox blocks cross-site trackers, social trackers, cryptominers, fingerprinters, and tracking content.", comment: "Description for having strict ETP protection with ITP offered in iOS14+", lastEditedIn: .unknown)
        public static let StandardETPWithITP = MZLocalizedString("Menu.EnhancedTrackingProtectionStandardWithITP.Title", value: "Firefox blocks cross-site trackers, social trackers, cryptominers, and fingerprinters.", comment: "Description for having standard ETP protection with ITP offered in iOS14+", lastEditedIn: .unknown)

        public struct PageMenuTitles {
            public static let Title = MZLocalizedString("Menu.TrackingProtection.TitlePrefix", value: "Protections for %@", comment: "Title on tracking protection menu showing the domain. eg. Protections for mozilla.org", lastEditedIn: .unknown)
            public static let NoTrackersBlocked = MZLocalizedString("Menu.TrackingProtection.NoTrackersBlockedTitle", value: "No trackers known to Firefox were detected on this page.", comment: "Message in menu when no trackers blocked.", lastEditedIn: .unknown)
            public static let BlockedTitle = MZLocalizedString("Menu.TrackingProtection.BlockedTitle", value: "Blocked", comment: "Title on tracking protection menu for blocked items.", lastEditedIn: .unknown)
        }


        // Shortcut on bottom of TP page menu to get to settings.
        public static let ProtectionSettings = MZLocalizedString("Menu.TrackingProtection.ProtectionSettings.Title", value: "Protection Settings", comment: "The title for tracking protection settings", lastEditedIn: .unknown)
        public static let SafeListRemove = MZLocalizedString("Menu.TrackingProtectionWhitelistRemove.Title", value: "Enable for this site", comment: "label for the menu item that lets you remove a website from the tracking protection whitelist", lastEditedIn: .unknown)

        // Settings info
        public static let AccessoryInfoBlocksTitle = MZLocalizedString("Settings.TrackingProtection.Info.BlocksTitle", value: "BLOCKS", comment: "The Title on info view which shows a list of all blocked websites", lastEditedIn: .unknown)

        public struct Category {
            public struct Titles {
                public static let CryptominersBlocked = MZLocalizedString("Menu.TrackingProtectionCryptominersBlocked.Title", value: "Cryptominers", comment: "The title that shows the number of cryptomining scripts blocked", lastEditedIn: .unknown)
                public static let FingerprintersBlocked = MZLocalizedString("Menu.TrackingProtectionFingerprintersBlocked.Title", value: "Fingerprinters", comment: "The title that shows the number of fingerprinting scripts blocked", lastEditedIn: .unknown)
                public static let CrossSiteBlocked = MZLocalizedString("Menu.TrackingProtectionCrossSiteTrackers.Title", value: "Cross-Site Trackers", comment: "The title that shows the number of cross-site URLs blocked", lastEditedIn: .unknown)
                public static let SocialBlocked = MZLocalizedString("Menu.TrackingProtectionBlockedSocial.Title", value: "Social Trackers", comment: "The title that shows the number of social URLs blocked", lastEditedIn: .unknown)
                public static let ContentBlocked = MZLocalizedString("Menu.TrackingProtectionBlockedContent.Title", value: "Tracking content", comment: "The title that shows the number of content cookies blocked", lastEditedIn: .unknown)
            }

            public struct Descriptions {
                public static let Social = MZLocalizedString("Menu.TrackingProtectionDescription.SocialNetworksNew", value: "Social networks place trackers on other websites to build a more complete and targeted profile of you. Blocking these trackers reduces how much social media companies can see what do you online.", comment: "Description of social network trackers.", lastEditedIn: .unknown)
                public static let CrossSite = MZLocalizedString("Menu.TrackingProtectionDescription.CrossSiteNew", value: "These cookies follow you from site to site to gather data about what you do online. They are set by third parties such as advertisers and analytics companies.", comment: "Description of cross-site trackers.", lastEditedIn: .unknown)
                public static let Cryptominers = MZLocalizedString("Menu.TrackingProtectionDescription.CryptominersNew", value: "Cryptominers secretly use your system’s computing power to mine digital money. Cryptomining scripts drain your battery, slow down your computer, and can increase your energy bill.", comment: "Description of cryptominers.", lastEditedIn: .unknown)
                public static let Fingerprinters = MZLocalizedString("Menu.TrackingProtectionDescription.Fingerprinters", value: "The settings on your browser and computer are unique. Fingerprinters collect a variety of these unique settings to create a profile of you, which can be used to track you as you browse.", comment: "Description of fingerprinters.", lastEditedIn: .unknown)
                public static let ContentTrackers = MZLocalizedString("Menu.TrackingProtectionDescription.ContentTrackers", value: "Websites may load outside ads, videos, and other content that contains hidden trackers. Blocking this can make websites load faster, but some buttons, forms, and login fields, might not work.", comment: "Description of content trackers.", lastEditedIn: .unknown)
            }
        }
    }
}

// MARK: - Third Party Search Engines
extension String {
}

// MARK: - Tabs Delete All Undo Toast
extension String {
    public static let TabsDeleteAllUndoTitle = MZLocalizedString("Tabs.DeleteAllUndo.Title", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed", lastEditedIn: .unknown)
    public static let TabsDeleteAllUndoAction = MZLocalizedString("Tabs.DeleteAllUndo.Button", value: "Undo", comment: "The button to undo the delete all tabs", lastEditedIn: .unknown)
    public static let TabSearchPlaceholderText = MZLocalizedString("Tabs.Search.PlaceholderText", value: "Search Tabs", comment: "The placeholder text for the tab search bar", lastEditedIn: .unknown)
}

// MARK: - Tab tray (chronological tabs)
extension String {
    public static let TabTrayV2Title = MZLocalizedString("TabTray.Title", value: "Open Tabs", comment: "The title for the tab tray", lastEditedIn: .unknown)
    public static let TabTrayV2TodayHeader = MZLocalizedString("TabTray.Today.Header", value: "Today", comment: "The section header for tabs opened today", lastEditedIn: .unknown)
    public static let TabTrayV2YesterdayHeader = MZLocalizedString("TabTray.Yesterday.Header", value: "Yesterday", comment: "The section header for tabs opened yesterday", lastEditedIn: .unknown)
    public static let TabTrayV2LastWeekHeader = MZLocalizedString("TabTray.LastWeek.Header", value: "Last Week", comment: "The section header for tabs opened last week", lastEditedIn: .unknown)
    public static let TabTrayV2OlderHeader = MZLocalizedString("TabTray.Older.Header", value: "Older", comment: "The section header for tabs opened before last week", lastEditedIn: .unknown)
    public static let TabTraySwipeMenuMore = MZLocalizedString("TabTray.SwipeMenu.More", value: "More", comment: "The button title to see more options to perform on the tab.", lastEditedIn: .unknown)
    public static let TabTrayMoreMenuCopy = MZLocalizedString("TabTray.MoreMenu.Copy", value: "Copy", comment: "The title on the button to copy the tab address.", lastEditedIn: .unknown)
    public static let TabTrayV2PrivateTitle = MZLocalizedString("TabTray.PrivateTitle", value: "Private Tabs", comment: "The title for the tab tray in private mode", lastEditedIn: .unknown)

    // Segmented Control tites for iPad
    public static let TabTraySegmentedControlTitlesTabs = MZLocalizedString("TabTray.SegmentedControlTitles.Tabs", value: "Tabs", comment: "The title on the button to look at regular tabs.", lastEditedIn: .unknown)
    public static let TabTraySegmentedControlTitlesPrivateTabs = MZLocalizedString("TabTray.SegmentedControlTitles.PrivateTabs", value: "Private", comment: "The title on the button to look at private tabs.", lastEditedIn: .unknown)
    public static let TabTraySegmentedControlTitlesSyncedTabs = MZLocalizedString("TabTray.SegmentedControlTitles.SyncedTabs", value: "Synced", comment: "The title on the button to look at synced tabs.", lastEditedIn: .unknown)
}

// MARK: - Translation bar
extension String {
    public static let TranslateSnackBarPrompt = MZLocalizedString("TranslationToastHandler.PromptTranslate.Title", value: "This page appears to be in %1$@. Translate to %2$@ with %3$@?", comment: "Prompt for translation. The first parameter is the language the page is in. The second parameter is the name of our local language. The third is the name of the service.", lastEditedIn: .unknown)
    public static let TranslateSnackBarYes = MZLocalizedString("TranslationToastHandler.PromptTranslate.OK", value: "Yes", comment: "Button to allow the page to be translated to the user locale language", lastEditedIn: .unknown)
    public static let TranslateSnackBarNo = MZLocalizedString("TranslationToastHandler.PromptTranslate.Cancel", value: "No", comment: "Button to disallow the page to be translated to the user locale language", lastEditedIn: .unknown)

    public static let SettingTranslateSnackBarSectionHeader = MZLocalizedString("Settings.TranslateSnackBar.SectionHeader", value: "Services", comment: "Translation settings section title", lastEditedIn: .unknown)
    public static let SettingTranslateSnackBarSectionFooter = MZLocalizedString("Settings.TranslateSnackBar.SectionFooter", value: "The web page language is detected on the device, and a translation from a remote service is offered.", comment: "Translation settings footer describing how language detection and translation happens.", lastEditedIn: .unknown)
    public static let SettingTranslateSnackBarTitle = MZLocalizedString("Settings.TranslateSnackBar.Title", value: "Translation", comment: "Title in main app settings for Translation toast settings", lastEditedIn: .unknown)
    public static let SettingTranslateSnackBarSwitchTitle = MZLocalizedString("Settings.TranslateSnackBar.SwitchTitle", value: "Offer Translation", comment: "Switch to choose if the language of a page is detected and offer to translate.", lastEditedIn: .unknown)
    public static let SettingTranslateSnackBarSwitchSubtitle = MZLocalizedString("Settings.TranslateSnackBar.SwitchSubtitle", value: "Offer to translate any site written in a language that is different from your default language.", comment: "Switch to choose if the language of a page is detected and offer to translate.", lastEditedIn: .unknown)
}

// MARK: - Today Widget Strings - [New Search - Private Search]
extension String {
    public static let NewTabButtonLabel = MZLocalizedString("TodayWidget.NewTabButtonLabelV1", tableName: "Today", value: "New Search", comment: "Open New Tab button label", lastEditedIn: .unknown)
    public static let CopiedLinkLabelFromPasteBoard = MZLocalizedString("TodayWidget.CopiedLinkLabelFromPasteBoardV1", tableName: "Today", value: "Copied Link from clipboard", comment: "Copied Link from clipboard displayed", lastEditedIn: .unknown)
    public static let NewPrivateTabButtonLabel = MZLocalizedString("TodayWidget.PrivateTabButtonLabelV1", tableName: "Today", value: "Private Search", comment: "Open New Private Tab button label", lastEditedIn: .unknown)

    // Widget - Shared

    public static let QuickActionsGalleryTitle = MZLocalizedString("TodayWidget.QuickActionsGalleryTitle", tableName: "Today", value: "Quick Actions", comment: "Quick Actions title when widget enters edit mode", lastEditedIn: .unknown)
    public static let QuickActionsGalleryTitlev2 = MZLocalizedString("TodayWidget.QuickActionsGalleryTitleV2", tableName: "Today", value: "Firefox Shortcuts", comment: "Firefox shortcuts title when widget enters edit mode. Do not translate the word Firefox.", lastEditedIn: .unknown)

    // Quick View - Gallery View
    public static let QuickViewGalleryTile = MZLocalizedString("TodayWidget.QuickViewGalleryTitle", tableName: "Today", value: "Quick View", comment: "Quick View title user is picking a widget to add.", lastEditedIn: .unknown)

    // Quick Action - Medium Size Quick Action
    public static let QuickActionsSubLabel = MZLocalizedString("TodayWidget.QuickActionsSubLabel", tableName: "Today", value: "Firefox - Quick Actions", comment: "Sub label for medium size quick action widget", lastEditedIn: .unknown)
    public static let NewSearchButtonLabel = MZLocalizedString("TodayWidget.NewSearchButtonLabelV1", tableName: "Today", value: "Search in Firefox", comment: "Open New Tab button label", lastEditedIn: .unknown)
    public static let NewPrivateTabButtonLabelV2 = MZLocalizedString("TodayWidget.NewPrivateTabButtonLabelV2", tableName: "Today", value: "Search in Private Tab", comment: "Open New Private Tab button label for medium size action", lastEditedIn: .unknown)
    public static let GoToCopiedLinkLabel = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV1", tableName: "Today", value: "Go to copied link", comment: "Go to link pasted on the clipboard", lastEditedIn: .unknown)
    public static let GoToCopiedLinkLabelV2 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV2", tableName: "Today", value: "Go to\nCopied Link", comment: "Go to copied link", lastEditedIn: .unknown)
    public static let GoToCopiedLinkLabelV3 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV3", tableName: "Today", value: "Go to Copied Link", comment: "Go To Copied Link text pasted on the clipboard but this string doesn't have new line character", lastEditedIn: .unknown)
    public static let ClosePrivateTab = MZLocalizedString("TodayWidget.ClosePrivateTabsButton", tableName: "Today", value: "Close Private Tabs", comment: "Close Private Tabs button label", lastEditedIn: .unknown)

    // Quick Action - Medium Size - Gallery View
    public static let FirefoxShortcutGalleryDescription = MZLocalizedString("TodayWidget.FirefoxShortcutGalleryDescription", tableName: "Today", value: "Add Firefox shortcuts to your Home screen.", comment: "Description for medium size widget to add Firefox Shortcut to home screen", lastEditedIn: .unknown)

    // Quick Action - Small Size Widget
    public static let SearchInFirefoxTitle = MZLocalizedString("TodayWidget.SearchInFirefoxTitle", tableName: "Today", value: "Search in Firefox", comment: "Title for small size widget which allows users to search in Firefox. Do not translate the word Firefox.", lastEditedIn: .unknown)
    public static let SearchInPrivateTabLabelV2 = MZLocalizedString("TodayWidget.SearchInPrivateTabLabelV2", tableName: "Today", value: "Search in\nPrivate Tab", comment: "Search in private tab", lastEditedIn: .unknown)
    public static let SearchInFirefoxV2 = MZLocalizedString("TodayWidget.SearchInFirefoxV2", tableName: "Today", value: "Search in\nFirefox", comment: "Search in Firefox. Do not translate the word Firefox", lastEditedIn: .unknown)
    public static let ClosePrivateTabsLabelV2 = MZLocalizedString("TodayWidget.ClosePrivateTabsLabelV2", tableName: "Today", value: "Close\nPrivate Tabs", comment: "Close Private Tabs", lastEditedIn: .unknown)
    public static let ClosePrivateTabsLabelV3 = MZLocalizedString("TodayWidget.ClosePrivateTabsLabelV3", tableName: "Today", value: "Close\nPrivate\nTabs", comment: "Close Private Tabs", lastEditedIn: .unknown)
    public static let GoToCopiedLinkLabelV4 = MZLocalizedString("TodayWidget.GoToCopiedLinkLabelV4", tableName: "Today", value: "Go to\nCopied\nLink", comment: "Go to copied link", lastEditedIn: .unknown)

    // Quick Action - Small Size Widget - Edit Mode
    public static let QuickActionDescription = MZLocalizedString("TodayWidget.QuickActionDescription", tableName: "Today", value: "Select a Firefox shortcut to add to your Home screen.", comment: "Quick action description when widget enters edit mode", lastEditedIn: .unknown)
    public static let QuickActionDropDownMenu = MZLocalizedString("TodayWidget.QuickActionDropDownMenu", tableName: "Today", value: "Quick action", comment: "Quick Actions left label text for dropdown menu when widget enters edit mode", lastEditedIn: .unknown)
    public static let DropDownMenuItemNewSearch = MZLocalizedString("TodayWidget.DropDownMenuItemNewSearch", tableName: "Today", value: "New Search", comment: "Quick Actions drop down menu item for new search when widget enters edit mode and drop down menu expands", lastEditedIn: .unknown)
    public static let DropDownMenuItemNewPrivateSearch = MZLocalizedString("TodayWidget.DropDownMenuItemNewPrivateSearch", tableName: "Today", value: "New Private Search", comment: "Quick Actions drop down menu item for new private search when widget enters edit mode and drop down menu expands", lastEditedIn: .unknown)
    public static let DropDownMenuItemGoToCopiedLink = MZLocalizedString("TodayWidget.DropDownMenuItemGoToCopiedLink", tableName: "Today", value: "Go to Copied Link", comment: "Quick Actions drop down menu item for Go to Copied Link when widget enters edit mode and drop down menu expands", lastEditedIn: .unknown)
    public static let DropDownMenuItemClearPrivateTabs = MZLocalizedString("TodayWidget.DropDownMenuItemClearPrivateTabs", tableName: "Today", value: "Clear Private Tabs", comment: "Quick Actions drop down menu item for lear Private Tabs when widget enters edit mode and drop down menu expands", lastEditedIn: .unknown)

    // Quick Action - Small Size - Gallery View
    public static let QuickActionGalleryDescription = MZLocalizedString("TodayWidget.QuickActionGalleryDescription", tableName: "Today", value: "Add a Firefox shortcut to your Home screen. After adding the widget, touch and hold to edit it and select a different shortcut.", comment: "Description for small size widget to add it to home screen", lastEditedIn: .unknown)

    // Top Sites - Medium Size Widget
    public static let TopSitesSubLabel = MZLocalizedString("TodayWidget.TopSitesSubLabel", tableName: "Today", value: "Firefox - Top Sites", comment: "Sub label for Top Sites widget", lastEditedIn: .unknown)
    public static let TopSitesSubLabel2 = MZLocalizedString("TodayWidget.TopSitesSubLabel2", tableName: "Today", value: "Firefox - Website Shortcuts", comment: "Sub label for Shortcuts widget", lastEditedIn: .unknown)

    // Top Sites - Medium Size - Gallery View
    public static let TopSitesGalleryTitle = MZLocalizedString("TodayWidget.TopSitesGalleryTitle", tableName: "Today", value: "Top Sites", comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen", lastEditedIn: .unknown)
    public static let TopSitesGalleryTitleV2 = MZLocalizedString("TodayWidget.TopSitesGalleryTitleV2", tableName: "Today", value: "Website Shortcuts", comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen", lastEditedIn: .unknown)
    public static let TopSitesGalleryDescription = MZLocalizedString("TodayWidget.TopSitesGalleryDescription", tableName: "Today", value: "Add shortcuts to frequently and recently visited sites.", comment: "Description for top sites widget to add Firefox top sites shotcuts to home screen", lastEditedIn: .unknown)

    // Quick View Open Tabs - Medium Size Widget
    public static let QuickViewOpenTabsSubLabel = MZLocalizedString("TodayWidget.QuickViewOpenTabsSubLabel", tableName: "Today", value: "Firefox - Open Tabs", comment: "Sub label for Top Sites widget", lastEditedIn: .unknown)
    public static let MoreTabsLabel = MZLocalizedString("TodayWidget.MoreTabsLabel", tableName: "Today", value: "+%d More…", comment: "%d represents number and it becomes something like +5 more where 5 is the number of open tabs in tab tray beyond what is displayed in the widget", lastEditedIn: .unknown)
    public static let OpenFirefoxLabel = MZLocalizedString("TodayWidget.OpenFirefoxLabel", tableName: "Today", value: "Open Firefox", comment: "Open Firefox when there are no tabs opened in tab tray i.e. Empty State", lastEditedIn: .unknown)
    public static let NoOpenTabsLabel = MZLocalizedString("TodayWidget.NoOpenTabsLabel", tableName: "Today", value: "No open tabs.", comment: "Label that is shown when there are no tabs opened in tab tray i.e. Empty State", lastEditedIn: .unknown)
    public static let NoOpenTabsLabelV2 = MZLocalizedString("TodayWidget.NoOpenTabsLabelV2", tableName: "Today", value: "No Open Tabs", comment: "Label that is shown when there are no tabs opened in tab tray i.e. Empty State", lastEditedIn: .unknown)


    // Quick View Open Tabs - Medium Size - Gallery View
    public static let QuickViewGalleryTitle = MZLocalizedString("TodayWidget.QuickViewGalleryTitle", tableName: "Today", value: "Quick View", comment: "Title for Quick View widget in Gallery View where user can add it to home screen", lastEditedIn: .unknown)
    public static let QuickViewGalleryDescription = MZLocalizedString("TodayWidget.QuickViewGalleryDescription", tableName: "Today", value: "Access your open tabs directly on your homescreen.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen", lastEditedIn: .unknown)
    public static let QuickViewGalleryDescriptionV2 = MZLocalizedString("TodayWidget.QuickViewGalleryDescriptionV2", tableName: "Today", value: "Add shortcuts to your open tabs.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen", lastEditedIn: .unknown)
    public static let ViewMore = MZLocalizedString("TodayWidget.ViewMore", tableName: "Today", value: "View More", comment: "View More for Quick View widget in Gallery View where we don't know how many tabs might be opened", lastEditedIn: .unknown)

    // Quick View Open Tabs - Large Size - Gallery View
    public static let QuickViewLargeGalleryDescription = MZLocalizedString("TodayWidget.QuickViewLargeGalleryDescription", tableName: "Today", value: "Add shortcuts to your open tabs.", comment: "Description for Quick View widget in Gallery View where user can add it to home screen", lastEditedIn: .unknown)

    // Pocket - Large - Medium Size Widget
    public static let PocketWidgetSubLabel = MZLocalizedString("TodayWidget.PocketWidgetSubLabel", tableName: "Today", value: "Firefox - Recommended by Pocket", comment: "Sub label for medium size Firefox Pocket stories widge widget. Pocket is the name of another app.", lastEditedIn: .unknown)
    public static let ViewMoreDots = MZLocalizedString("TodayWidget.ViewMoreDots", tableName: "Today", value: "View More…", comment: "View More… for Firefox Pocket stories widget where we don't know how many articles are available.", lastEditedIn: .unknown)

    // Pocket - Large - Medium Size - Gallery View
    public static let PocketWidgetGalleryTitle = MZLocalizedString("TodayWidget.PocketWidgetTitle", tableName: "Today", value: "Recommended by Pocket", comment: "Title for Firefox Pocket stories widget in Gallery View where user can add it to home screen. Pocket is the name of another app.", lastEditedIn: .unknown)
    public static let PocketWidgetGalleryDescription = MZLocalizedString("TodayWidget.PocketWidgetGalleryDescription", tableName: "Today", value: "Discover fascinating and thought-provoking stories from across the web, curated by Pocket.", comment: "Description for Firefox Pocket stories widget in Gallery View where user can add it to home screen. Pocket is the name of another app.", lastEditedIn: .unknown)
}

// MARK: - Tab Location View
extension String {
    public static let TabLocationURLPlaceholder = MZLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home", lastEditedIn: .unknown)
    public static let TabLocationLockIconAccessibilityLabel = MZLocalizedString("Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure", lastEditedIn: .unknown)
    public static let TabLocationReaderModeAccessibilityLabel = MZLocalizedString("Reader View", comment: "Accessibility label for the Reader View button", lastEditedIn: .unknown)
    public static let TabLocationReaderModeAddToReadingListAccessibilityLabel = MZLocalizedString("Add to Reading List", comment: "Accessibility label for action adding current page to reading list.", lastEditedIn: .unknown)
    public static let TabLocationReloadAccessibilityLabel = MZLocalizedString("Reload page", comment: "Accessibility label for the reload button", lastEditedIn: .unknown)
    public static let TabLocationPageOptionsAccessibilityLabel = MZLocalizedString("Page Options Menu", comment: "Accessibility label for the Page Options menu button", lastEditedIn: .unknown)
}

// MARK: - TabPeekViewController
extension String {
    public static let TabPeekAddToBookmarks = MZLocalizedString("Add to Bookmarks", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks", lastEditedIn: .unknown)
    public static let TabPeekCopyUrl = MZLocalizedString("Copy URL", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard", lastEditedIn: .unknown)
    public static let TabPeekCloseTab = MZLocalizedString("Close Tab", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to close the current tab", lastEditedIn: .unknown)
    public static let TabPeekPreviewAccessibilityLabel = MZLocalizedString("Preview of %@", tableName: "3DTouchActions", comment: "Accessibility label, associated to the 3D Touch action on the current tab in the tab tray, used to display a larger preview of the tab.", lastEditedIn: .unknown)
}

// MARK: - Tab Toolbar
extension String {
    public static let TabToolbarReloadAccessibilityLabel = MZLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button", lastEditedIn: .unknown)
    public static let TabToolbarStopAccessibilityLabel = MZLocalizedString("Stop", comment: "Accessibility Label for the tab toolbar Stop button", lastEditedIn: .unknown)
    public static let TabToolbarSearchAccessibilityLabel = MZLocalizedString("Search", comment: "Accessibility Label for the tab toolbar Search button", lastEditedIn: .unknown)
    public static let TabToolbarNewTabAccessibilityLabel = MZLocalizedString("New Tab", comment: "Accessibility Label for the tab toolbar New tab button", lastEditedIn: .unknown)
    public static let TabToolbarBackAccessibilityLabel = MZLocalizedString("Back", comment: "Accessibility label for the Back button in the tab toolbar.", lastEditedIn: .unknown)
    public static let TabToolbarForwardAccessibilityLabel = MZLocalizedString("Forward", comment: "Accessibility Label for the tab toolbar Forward button", lastEditedIn: .unknown)
    public static let TabToolbarNavigationToolbarAccessibilityLabel = MZLocalizedString("Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.", lastEditedIn: .unknown)
    public static let AddTabAccessibilityLabel = MZLocalizedString("TabTray.AddTab.Button", value: "Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.", lastEditedIn: .unknown)
}

// MARK: - Tab Tray v1
extension String {
    public static let TabTrayToggleAccessibilityLabel = MZLocalizedString("Private Mode", tableName: "PrivateBrowsing", comment: "Accessibility label for toggling on/off private mode", lastEditedIn: .unknown)
    public static let TabTrayToggleAccessibilityHint = MZLocalizedString("Turns private mode on or off", tableName: "PrivateBrowsing", comment: "Accessiblity hint for toggling on/off private mode", lastEditedIn: .unknown)
    public static let TabTrayToggleAccessibilityValueOn = MZLocalizedString("On", tableName: "PrivateBrowsing", comment: "Toggled ON accessibility value", lastEditedIn: .unknown)
    public static let TabTrayToggleAccessibilityValueOff = MZLocalizedString("Off", tableName: "PrivateBrowsing", comment: "Toggled OFF accessibility value", lastEditedIn: .unknown)
    public static let TabTrayViewAccessibilityLabel = MZLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.", lastEditedIn: .unknown)
    public static let TabTrayNoTabsAccessibilityHint = MZLocalizedString("No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray", lastEditedIn: .unknown)
    public static let TabTrayVisibleTabRangeAccessibilityHint = MZLocalizedString("Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.", lastEditedIn: .unknown)
    public static let TabTrayVisiblePartialRangeAccessibilityHint = MZLocalizedString("Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.", lastEditedIn: .unknown)
    public static let TabTrayClosingTabAccessibilityMessage =  MZLocalizedString("Closing tab", comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed.", lastEditedIn: .unknown)
    public static let TabTrayCloseAllTabsPromptCancel = MZLocalizedString("Cancel", comment: "Label for Cancel button", lastEditedIn: .unknown)
    public static let TabTrayPrivateLearnMore = MZLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode", lastEditedIn: .unknown)
    public static let TabTrayPrivateBrowsingTitle = MZLocalizedString("Private Browsing", tableName: "PrivateBrowsing", comment: "Title displayed for when there are no open tabs while in private mode", lastEditedIn: .unknown)
    public static let TabTrayPrivateBrowsingDescription =  MZLocalizedString("Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.", tableName: "PrivateBrowsing", comment: "Description text displayed when there are no open tabs while in private mode", lastEditedIn: .unknown)
    public static let TabTrayAddTabAccessibilityLabel = MZLocalizedString("Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.", lastEditedIn: .unknown)
    public static let TabTrayCloseAccessibilityCustomAction = MZLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)", lastEditedIn: .unknown)
    public static let TabTraySwipeToCloseAccessibilityHint = MZLocalizedString("Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.", lastEditedIn: .unknown)
    public static let TabTrayCurrentlySelectedTabAccessibilityLabel = MZLocalizedString("TabTray.CurrentSelectedTab.A11Y", value: "Currently selected tab.", comment: "Accessibility label for the currently selected tab.", lastEditedIn: .unknown)
}

// MARK: - TabsButton
extension String {
    public static let TabsButtonShowTabsAccessibilityLabel = MZLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the (top) tab toolbar", lastEditedIn: .unknown)
}

// MARK: - TabTrayButtons
extension String {
    public static let TabTrayButtonNewTabAccessibilityLabel = MZLocalizedString("New Tab", comment: "Accessibility label for the New Tab button in the tab toolbar.", lastEditedIn: .unknown)
    public static let TabTrayButtonShowTabsAccessibilityLabel = MZLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the tab toolbar", lastEditedIn: .unknown)
}

// MARK: - TimeConstants
extension String {
    public struct TimeConstants {
        public static let MoreThanAMonth = MZLocalizedString("more than a month ago", comment: "Relative date for dates older than a month and less than two months.", lastEditedIn: .unknown)
        public static let MoreThanAWeek = MZLocalizedString("more than a week ago", comment: "Description for a date more than a week ago, but less than a month ago.", lastEditedIn: .unknown)
        public static let Yesterday = MZLocalizedString("yesterday", comment: "Relative date for yesterday.", lastEditedIn: .unknown)
        public static let ThisWeek = MZLocalizedString("this week", comment: "Relative date for date in past week.", lastEditedIn: .unknown)
        public static let RelativeToday = MZLocalizedString("today at %@", comment: "Relative date for date older than a minute.", lastEditedIn: .unknown)
        public static let JustNow = MZLocalizedString("just now", comment: "Relative time for a tab that was visited within the last few moments.", lastEditedIn: .unknown)
    }
}

// MARK: - U
// MARK: - URL Bar
extension String {
    public static let URLBarLocationAccessibilityLabel = MZLocalizedString("Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.", lastEditedIn: .unknown)
}

// MARK: - V
// MARK: - W
// MARK: - X
// MARK: - Y
// MARK: - Z







// MARK: - v35 Strings
extension String {
    public static let FirefoxHomeJumpBackInSectionTitle = MZLocalizedString("ActivityStream.JumpBackIn.SectionTitle", value: "Jump Back In", comment: "Title for the Jump Back In section. This section allows users to jump back in to a recently viewed tab", lastEditedIn: .v350)
    public static let FirefoxHomeRecentlySavedSectionTitle = MZLocalizedString("ActivityStream.RecentlySaved.SectionTitle", value: "Recently Saved", comment: "Section title for the Recently Saved section. This shows websites that have had a save action. Right now it is just bookmarks but it could be used for other things like the reading list in the future.", lastEditedIn: .v350)
    public static let FirefoxHomeShowAll = MZLocalizedString("ActivityStream.RecentlySaved.ShowAll", value: "Show all", comment: "This button will open the library showing all the users bookmarks", lastEditedIn: .v350)
    public static let TabsTrayInactiveTabsSectionTitle = MZLocalizedString("TabTray.InactiveTabs.SectionTitle", value: "Inactive Tabs", comment: "Title for the inactive tabs section. This section groups all tabs that haven't been used in a while.", lastEditedIn: .v350)
    public static let TabsTrayRecentlyCloseTabsSectionTitle = MZLocalizedString("TabTray.RecentlyClosed.SectionTitle", value: "Recently closed", comment: "Title for the recently closed tabs section. This section shows a list of all the tabs that have been recently closed.", lastEditedIn: .v350)
    public static let TabsTrayRecentlyClosedTabsDescritpion = MZLocalizedString("TabTray.RecentlyClosed.Description", value: "Tabs are available here for 30 days. After that time, tabs will be automatically closed.", comment: "Describes what the Recently Closed tabs behavior is for users unfamiliar with it.", lastEditedIn: .v350)
}

// MARK: - v36 Strings
extension String {
    public static let ProtectionStatusSheetConnectionSecure = MZLocalizedString("ProtectionStatusSheet.SecureConnection", value: "Secure Connection", comment: "value for label to indicate user is on a secure ssl connection", lastEditedIn: .v360)
    public static let ProtectionStatusSheetConnectionInsecure = MZLocalizedString("ProtectionStatusSheet.InsecureConnection", value: "Insecure Connection", comment: "value for label to indicate user is on an unencrypted website", lastEditedIn: .v360)
}

// MARK: - Deprecated Strings
// These strings are no longer used but are being kept around for localization.
extension String {
    public struct Deprecated {

        public static let ASPocketTitle = MZLocalizedString("ActivityStream.Pocket.SectionTitle", value: "Trending on Pocket", comment: "Section title label for Recommended by Pocket section", lastEditedIn: .unknown)
        public static let HighlightVistedText = MZLocalizedString("ActivityStream.Highlights.Visited", value: "Visited", comment: "The description of a highlight if it is a site the user has visited", lastEditedIn: .unknown)
        public static let HighlightBookmarkText = MZLocalizedString("ActivityStream.Highlights.Bookmark", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked", lastEditedIn: .unknown)
        public static let PocketTrendingText = MZLocalizedString("ActivityStream.Pocket.Trending", value: "Trending", comment: "The description of a Pocket Story", lastEditedIn: .unknown)

        public static let SettingsHomePageSectionName = MZLocalizedString("Settings.HomePage.SectionName", value: "Homepage", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.", lastEditedIn: .unknown)
        public static let SettingsHomePageTitle = MZLocalizedString("Settings.HomePage.Title", value: "Homepage Settings", comment: "Title displayed in header of the setting panel.", lastEditedIn: .unknown)
        public static let SettingsHomePageURLSectionTitle = MZLocalizedString("Settings.HomePage.URL.Title", value: "Current Homepage", comment: "Title of the setting section containing the URL of the current home page.", lastEditedIn: .unknown)
        public static let SettingsHomePageUseCurrentPage = MZLocalizedString("Settings.HomePage.UseCurrent.Button", value: "Use Current Page", comment: "Button in settings to use the current page as home page.", lastEditedIn: .unknown)
        public static let SettingsHomePageTextPlaceholder = MZLocalizedString("Settings.HomePage.URL.Placeholder", value: "Enter a webpage", comment: "Placeholder text in the homepage setting when no homepage has been set.", lastEditedIn: .unknown)
        public static let SettingsHomePageUseCopiedLink = MZLocalizedString("Settings.HomePage.UseCopiedLink.Button", value: "Use Copied Link", comment: "Button in settings to use the current link on the clipboard as home page.", lastEditedIn: .unknown)
        public static let SettingsHomePageUseDefault = MZLocalizedString("Settings.HomePage.UseDefault.Button", value: "Use Default", comment: "Button in settings to use the default home page. If no default is set, then this button isn't shown.", lastEditedIn: .unknown)
        public static let SettingsHomePageClear = MZLocalizedString("Settings.HomePage.Clear.Button", value: "Clear", comment: "Button in settings to clear the home page.", lastEditedIn: .unknown)

        public static let SetHomePageDialogTitle = MZLocalizedString("HomePage.Set.Dialog.Title", value: "Do you want to use this web page as your home page?", comment: "Alert dialog title when the user opens the home page for the first time.", lastEditedIn: .unknown)
        public static let SetHomePageDialogMessage = MZLocalizedString("HomePage.Set.Dialog.Message", value: "You can change this at any time in Settings", comment: "Alert dialog body when the user opens the home page for the first time.", lastEditedIn: .unknown)
        public static let SetHomePageDialogYes = MZLocalizedString("HomePage.Set.Dialog.OK", value: "Set Homepage", comment: "Button accepting changes setting the home page for the first time.", lastEditedIn: .unknown)
        public static let SetHomePageDialogNo = MZLocalizedString("HomePage.Set.Dialog.Cancel", value: "Cancel", comment: "Button cancelling changes setting the home page for the first time.", lastEditedIn: .unknown)

        public static let FxASignin_CreateAccountPt1 = MZLocalizedString("fxa.signin.create-account-pt-1", value: "Sync Firefox between devices with an account.", comment: "FxA sign in create account label.", lastEditedIn: .unknown)
        public static let FxASignin_CreateAccountPt2 = MZLocalizedString("fxa.signin.create-account-pt-2", value: "Create Firefox account.", comment: "FxA sign in create account label. This will be linked to the site to create an account.", lastEditedIn: .unknown)

        public static let AppMenuLibraryReloadString = MZLocalizedString("Menu.Library.Reload", tableName: "Menu", value: "Reload", comment: "Label for the button, displayed in the menu, used to Reload the webpage", lastEditedIn: .unknown)
        public static let AppMenuRecentlySavedTitle = MZLocalizedString("Menu.RecentlySaved.Title", tableName: "Menu", value: "Recently Saved", comment: "A string used to signify the start of the Recently Saved section in Home Screen.", lastEditedIn: .unknown)
        public static let AppMenuShowTabsTitleString = MZLocalizedString("Menu.ShowTabs.Title", tableName: "Menu", value: "Show Tabs", comment: "Label for the button, displayed in the menu, used to open the tabs tray", lastEditedIn: .unknown)
        public static let AppMenuCopyURLTitleString = MZLocalizedString("Menu.CopyAddress.Title", tableName: "Menu", value: "Copy Address", comment: "Label for the button, displayed in the menu, used to copy the page url to the clipboard.", lastEditedIn: .unknown)
        public static let AppMenuNewPrivateTabTitleString = MZLocalizedString("Menu.NewPrivateTabAction.Title", tableName: "Menu", value: "Open New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.", lastEditedIn: .unknown)
        public static let AppMenuAddBookmarkTitleString = MZLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.", lastEditedIn: .unknown)
        public static let AppMenuTranslatePageTitleString = MZLocalizedString("Menu.TranslatePageAction.Title", tableName: "Menu", value: "Translate Page", comment: "Label for the button, displayed in the menu, used to translate the current page.", lastEditedIn: .unknown)
        public static let AppMenuScanQRCodeTitleString = MZLocalizedString("Menu.ScanQRCodeAction.Title", tableName: "Menu", value: "Scan QR Code", comment: "Label for the button, displayed in the menu, used to open the QR code scanner.", lastEditedIn: .unknown)
        public static let AppMenuLibrarySeeAllTitleString = MZLocalizedString("Menu.SeeAllAction.Title", tableName: "Menu", value: "See All", comment: "Label for the button, displayed in Firefox Home, used to see all Library panels.", lastEditedIn: .unknown)
        public static let TabTrayDeleteMenuButtonAccessibilityLabel = MZLocalizedString("Toolbar.Menu.CloseAllTabs", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.", lastEditedIn: .unknown)
        public static let AppMenuNightMode = MZLocalizedString("Menu.NightModeTurnOn.Label", value: "Enable Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.", lastEditedIn: .unknown)
        public static let AppMenuManageAccount = MZLocalizedString("Menu.ManageAccount.Label", value: "Manage Account %@", comment: "Label for the button, displayed in the menu, takes you to screen to manage account when pressed. First argument is the display name for the current account", lastEditedIn: .unknown)
        public static let AppMenuAddPinToTopSitesConfirmMessage = MZLocalizedString("Menu.AddPin.Confirm", value: "Pinned To Top Sites", comment: "Toast displayed to the user after adding the item to the Top Sites.", lastEditedIn: .unknown)
        public static let AppMenuRemovePinFromTopSitesConfirmMessage = MZLocalizedString("Menu.RemovePin.Confirm", value: "Removed From Top Sites", comment: "Toast displayed to the user after removing the item from the Top Sites.", lastEditedIn: .unknown)
        public static let PageActionMenuTitle = MZLocalizedString("Menu.PageActions.Title", value: "Page Actions", comment: "Label for title in page action menu.", lastEditedIn: .unknown)
        public static let AppMenuShowPageSourceString = MZLocalizedString("Menu.PageSourceAction.Title", tableName: "Menu", value: "View Page Source", comment: "Label for the button, displayed in the menu, used to show the html page source", lastEditedIn: .unknown)


        public static let BookmarksTitle = MZLocalizedString("Bookmarks.Title.Label", value: "Title", comment: "The label for the title of a bookmark", lastEditedIn: .unknown)
        public static let BookmarksURL = MZLocalizedString("Bookmarks.URL.Label", value: "URL", comment: "The label for the URL of a bookmark", lastEditedIn: .unknown)
        public static let BookmarksFolder = MZLocalizedString("Bookmarks.Folder.Label", value: "Folder", comment: "The label to show the location of the folder where the bookmark is located", lastEditedIn: .unknown)
        public static let BookmarksFolderName = MZLocalizedString("Bookmarks.FolderName.Label", value: "Folder Name", comment: "The label for the title of the new folder", lastEditedIn: .unknown)
        public static let BookmarksFolderLocation = MZLocalizedString("Bookmarks.FolderLocation.Label", value: "Location", comment: "The label for the location of the new folder", lastEditedIn: .unknown)
        public static let BookmarksPanelEmptyStateTitle = MZLocalizedString("BookmarksPanel.EmptyState.Title", value: "Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.", lastEditedIn: .unknown)
        public static let BookmarkDetailFieldsHeaderBookmarkTitle = MZLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Bookmark.Title", value: "Bookmark", comment: "The header title for the fields when editing a Bookmark", lastEditedIn: .unknown)
        public static let BookmarkDetailFieldsHeaderFolderTitle = MZLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Folder.Title", value: "Folder", comment: "The header title for the fields when editing a Folder", lastEditedIn: .unknown)


        public static let SettingsClearPrivateDataSectionName = MZLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.", lastEditedIn: .unknown)
        public static let SettingsEditWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonEdit", value: "Edit", comment: "Button to edit website search results", lastEditedIn: .unknown)
        public static let SettingsDeleteWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonDelete", value: "Delete", comment: "Button to delete website in search results", lastEditedIn: .unknown)
        public static let SettingsDoneWebsiteSearchButton = MZLocalizedString("Settings.WebsiteData.ButtonDone", value: "Done", comment: "Button to exit edit website search results", lastEditedIn: .unknown)


        public static let SyncingMessageWithoutEllipsis = MZLocalizedString("Sync.Syncing.Label", value: "Syncing", comment: "Message displayed when the user's account is syncing with no ellipsis", lastEditedIn: .unknown)
        public static let FirstTimeSyncLongTime = MZLocalizedString("Sync.FirstTimeMessage.Label", value: "Your first sync may take a while", comment: "Message displayed when the user syncs for the first time", lastEditedIn: .unknown)
        public static let FirefoxSyncNotStartedTitle = MZLocalizedString("SyncState.NotStarted.Title", value: "Sync is unavailable", comment: "Title for Sync status message when Sync failed to start.", lastEditedIn: .unknown)
        public static let FirefoxSyncPartialTitle = MZLocalizedString("SyncState.Partial.Title", value: "Sync is experiencing issues syncing %@", comment: "Title for Sync status message when a component of Sync failed to complete, where %@ represents the name of the component, i.e. Sync is experiencing issues syncing Bookmarks", lastEditedIn: .unknown)
        public static let FirefoxSyncFailedTitle = MZLocalizedString("SyncState.Failed.Title", value: "Syncing has failed", comment: "Title for Sync status message when synchronization failed to complete", lastEditedIn: .unknown)
        public static let FirefoxSyncCreateAccount = MZLocalizedString("Sync.NoAccount.Description", value: "No account? Create one to sync Firefox between devices.", comment: "String displayed on Sign In to Sync page that allows the user to create a new account.", lastEditedIn: .unknown)

        public static func localizedStringForSyncComponent(_ componentName: String) -> String? {
            switch componentName {
            case "bookmarks":
                return MZLocalizedString("SyncState.Bookmark.Title", value: "Bookmarks", comment: "The Bookmark sync component, used in SyncState.Partial.Title", lastEditedIn: .unknown)
            case "clients":
                return MZLocalizedString("SyncState.Clients.Title", value: "Remote Clients", comment: "The Remote Clients sync component, used in SyncState.Partial.Title", lastEditedIn: .unknown)
            case "tabs":
                return MZLocalizedString("SyncState.Tabs.Title", value: "Tabs", comment: "The Tabs sync component, used in SyncState.Partial.Title", lastEditedIn: .unknown)
            case "logins":
                return MZLocalizedString("SyncState.Logins.Title", value: "Logins", comment: "The Logins sync component, used in SyncState.Partial.Title", lastEditedIn: .unknown)
            case "history":
                return MZLocalizedString("SyncState.History.Title", value: "History", comment: "The History sync component, used in SyncState.Partial.Title", lastEditedIn: .unknown)
            default: return nil
            }
        }


        public static let SentTabBookmarkActionTitle = MZLocalizedString("SentTab.BookmarkAction.title", value: "Bookmark", comment: "Label for an action used to bookmark one or more tabs from a notification.", lastEditedIn: .unknown)
        public static let SentTabAddToReadingListActionTitle = MZLocalizedString("SentTab.AddToReadingListAction.Title", value: "Add to Reading List", comment: "Label for an action used to add one or more tabs recieved from a notification to the reading list.", lastEditedIn: .unknown)


        public static let SendToSignInButton = MZLocalizedString("SendTo.SignIn.Button", value: "Sign In to Firefox", comment: "The text for the button on the Send to Device page if you are not signed in to Firefox Accounts.", lastEditedIn: .unknown)
        public static let ShareOpenInPrivateModeNow = MZLocalizedString("ShareExtension.OpenInPrivateModeAction.Title", value: "Open in Private Mode", comment: "Action label on share extension to immediately open page in Firefox in private mode.", lastEditedIn: .unknown)


        public static let AuthenticationWrongPasscodeError = MZLocalizedString("Incorrect passcode. Try again.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app", lastEditedIn: .unknown)
        public static let AuthenticationMaximumAttemptsReached = MZLocalizedString("Maximum attempts reached. Please try again in an hour.", tableName: "AuthenticationManager", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.", lastEditedIn: .unknown)


        public static let SearchSearchEngineSuggestionAccessibilityLabel = MZLocalizedString("Search suggestions from %@", tableName: "Search", comment: "Accessibility label for image of default search engine displayed left to the actual search suggestions from the engine. The parameter substituted for \"%@\" is the name of the search engine. E.g.: Search suggestions from Google", lastEditedIn: .unknown)
        public static let SearchSearchSuggestionTapAccessibilityHint = MZLocalizedString("Searches for the suggestion", comment: "Accessibility hint describing the action performed when a search suggestion is clicked", lastEditedIn: .unknown)


        public static let TPBlockingDescription = MZLocalizedString("Menu.TrackingProtectionBlocking.Description", value: "Firefox is blocking parts of the page that may track your browsing.", comment: "Description of the Tracking protection menu when TP is blocking parts of the page", lastEditedIn: .unknown)
        public static let TPBlockingDisabledDescription = MZLocalizedString("Menu.TrackingProtectionBlockingDisabled.Description", value: "Block online trackers", comment: "The description of the Tracking Protection menu item when tracking is enabled", lastEditedIn: .unknown)
        public static let TPBlockingSiteEnabled = MZLocalizedString("Menu.TrackingProtectionEnable1.Title", value: "Enabled for this site", comment: "A button to enable tracking protection inside the menu.", lastEditedIn: .unknown)
        public static let TPEnabledConfirmed = MZLocalizedString("Menu.TrackingProtectionEnabled.Title", value: "Tracking Protection is now on for this site.", comment: "The confirmation toast once tracking protection has been enabled", lastEditedIn: .unknown)
        public static let TPDisabledConfirmed = MZLocalizedString("Menu.TrackingProtectionDisabled.Title", value: "Tracking Protection is now off for this site.", comment: "The confirmation toast once tracking protection has been disabled", lastEditedIn: .unknown)
        public static let TPBlockingSiteDisabled = MZLocalizedString("Menu.TrackingProtectionDisable1.Title", value: "Disabled for this site", comment: "The button that disabled TP for a site.", lastEditedIn: .unknown)
        public static let TPCrossSiteCookiesBlocked = MZLocalizedString("Menu.TrackingProtectionCrossSiteCookies.Title", value: "Cross-Site Tracking Cookies", comment: "The title that shows the number of cross-site cookies blocked", lastEditedIn: .unknown)
        public static let TPListTitle_CrossSiteCookies = MZLocalizedString("Menu.TrackingProtectionListTitle.CrossSiteCookies", value: "Blocked Cross-Site Tracking Cookies", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`", lastEditedIn: .unknown)
        public static let TPListTitle_Social = MZLocalizedString("Menu.TrackingProtectionListTitle.Social", value: "Blocked Social Trackers", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`", lastEditedIn: .unknown)
        public static let TPListTitle_Fingerprinters = MZLocalizedString("Menu.TrackingProtectionListTitle.Fingerprinters", value: "Blocked Fingerprinters", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`", lastEditedIn: .unknown)
        public static let TPListTitle_Cryptominer = MZLocalizedString("Menu.TrackingProtectionListTitle.Cryptominers", value: "Blocked Cryptominers", comment: "Title for list of domains blocked by category type. eg.  Blocked `CryptoMiners`", lastEditedIn: .unknown)
        public static let TPSafeListOn = MZLocalizedString("Menu.TrackingProtectionOption.WhiteListOnDescription", value: "The site includes elements that may track your browsing. You have disabled protection.", comment: "label for the menu item to show when the website is whitelisted from blocking trackers.", lastEditedIn: .unknown)
        public static let TPAccessoryInfoTitleStrict = MZLocalizedString("Settings.TrackingProtection.Info.StrictTitle", value: "Offers stronger protection, but may cause some sites to break.", comment: "Explanation of strict mode.", lastEditedIn: .unknown)
        public static let TPAccessoryInfoTitleBasic = MZLocalizedString("Settings.TrackingProtection.Info.BasicTitle", value: "Balanced for protection and performance.", comment: "Explanation of basic mode.", lastEditedIn: .unknown)
        public static let TPMoreInfo = MZLocalizedString("Settings.TrackingProtection.MoreInfo", value: "More Info…", comment: "'More Info' link on the Tracking Protection settings screen.", lastEditedIn: .unknown)
    }
}
