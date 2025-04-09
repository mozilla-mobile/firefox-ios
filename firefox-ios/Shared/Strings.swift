// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// swiftlint:disable line_length
import Foundation

// MARK: - Localization bundle setup
class BundleClass {}

public struct Strings {
    public static let bundle = Bundle(for: BundleClass.self)
}

// MARK: - Localization helper function

/// Full documentation available in
///
/// Used to define a new string into the project
/// - Parameters:
///   - key: The key should be unique and composed of a relevant name, ended with the version the string was included in.
///   Example: `"FirefoxHomepage.Pocket.Sponsored.v103"` is a string that lives under the homepage for the sponsored content in the pocket
///   section, added in v103. The name is clear and explicit.
///   - tableName: The tablename defines the name of the table containing the localized string.
///   This specifically need to be defined for any strings that is part of the messaging framework, but since any string can be part of messaging in the
///   future all strings should have a tablename. This can be nil for existing strings, `new string shouldn't have a nil tableName`.
///   - value: The value is always the text that needs to be localized.  This can be nil for existing strings, `new string shouldn't have a nil value`.
///   - comment: The comment is an explanation aimed towards people that will translate the string value. Make sure it follow the l10n documentation
///   https://mozilla-l10n.github.io/documentation/localization/dev_best_practices.html#add-localization-notes
private func MZLocalizedString(
    key: String,
    tableName: String?,
    value: String?,
    comment: String
) -> String {
    return NSLocalizedString(key,
                             tableName: tableName,
                             bundle: Strings.bundle,
                             value: value ?? "",
                             comment: comment)
}

// This file contains all strings for Firefox iOS.
//
// To preserve a clean structure of this string file, we should organize them alphabetically,
// according to specific screens or feature, on that screen. Each string should
// be under a struct giving a clear indication as to where it is being used.
// In this case we will prefer verbosity for the sake of accuracy, over brevity.
// Sub structs may, and should, also be used to separate functionality where it makes
// sense, but efforts should be made to keep structs two levels deep unless there are
// good reasons for doing otherwise. As we continue to update strings, old strings may
// be present at the bottom of this file.
//
// Note that strings shouldn't be reused in multiple places in the application. Depending
// on the Locale we can't guarantee one string will be translated the same even if its value is the same.

// MARK: - Alerts
extension String {
    public struct Alerts {
        public struct FeltDeletion {
            public static let Title = MZLocalizedString(
                key: "Alerts.FeltDeletion.Title.v122",
                tableName: "Alerts",
                value: "End your private session?",
                comment: "When tapping the fire icon in private mode, an alert comes up asking to confirm if you want to delete all browsing data and end your private session. This is the title for the alert.")
            public static let Body = MZLocalizedString(
                key: "Alerts.FeltDeletion.Body.v122",
                tableName: "Alerts",
                value: "Close all private tabs and delete history, cookies, and all other site data.",
                comment: "When tapping the fire icon in private mode, an alert comes up asking to confirm if you want to delete all browsing data and end your private session. This is the body text for the alert.")
            public static let ConfirmButton = MZLocalizedString(
                key: "Alerts.FeltDeletion.Button.Confirm.v122",
                tableName: "Alerts",
                value: "Delete session data",
                comment: "When tapping the fire icon in private mode, an alert comes up asking to confirm if you want to delete all browsing data and end your private session. This is the affirmative action for the alert, confirming that you do want to do that.")
            public static let CancelButton = MZLocalizedString(
                key: "Alerts.FeltDeletion.Button.Cancel.v122",
                tableName: "Alerts",
                value: "Cancel",
                comment: "When tapping the fire icon in private mode, an alert comes up asking to confirm if you want to delete all browsing data and end your private session. This is the cancel action for the alert, cancelling ending your session.")
        }

        public struct AddToCalendar {
            public static let Title = MZLocalizedString(
                key: "Alerts.AddToCalendar.Title.v134",
                tableName: "Alerts",
                value: "Add to calendar?",
                comment: "When tapping on a link, on a website in order to download a file and that file is a calendar file, an alert comes up asking to confirm if you want to add the event to the device calendar. This is the title for the alert.")
            public static let Body = MZLocalizedString(
                key: "Alerts.AddToCalendar.Body.v134",
                tableName: "Alerts",
                value: "%@ is asking to download a file and add an event to your calendar.",
                comment: "When tapping on a link, on a website in order to download a file and that file is a calendar file, an alert comes up asking to confirm if you want to add the event to the device calendar. This is the body message for the alert. %@ is the name/domain of the website, for example 'google.com'")
            public static let BodyDefault = MZLocalizedString(
                key: "Alerts.AddToCalendar.BodyDefault.v134",
                tableName: "Alerts",
                value: "This site is asking to download a file and add an event to your calendar.",
                comment: "When tapping on a link, on a website in order to download a file and that file is a calendar file, an alert comes up asking to confirm if you want to add the event to the device calendar. This is the body message for the alert in case the website doesn't have a base domain.")
            public static let AddButton = MZLocalizedString(
                key: "Alerts.AddToCalendar.Button.Add.v134",
                tableName: "Alerts",
                value: "Add",
                comment: "When tapping on a link, on a website in order to download a file and that file is a calendar file, an alert comes up asking to confirm if you want to add the event to the device calendar. This is the affirmative action for the alert, confirming that you do want to add the event to the calendar.")
            public static let CancelButton = MZLocalizedString(
                key: "Alerts.FeltDeletion.Button.Cancel.v134",
                tableName: "Alerts",
                value: "Cancel",
                comment: "When tapping on a link, on a website in order to download a file and that file is a calendar file, an alert comes up asking to confirm if you want to add the event to the device calendar. This is the cancel action for the alert, cancelling the action to add the event to the calendar.")
        }
    }
}

// MARK: - Biometric Authentication
extension String {
    public struct Biometry {
        public struct Screen {
            public static let UniversalAuthenticationReason = MZLocalizedString(
                key: "Biometry.Screen.UniversalAuthenticationReason.v115",
                tableName: "BiometricAuthentication",
                value: "Authenticate to access passwords.",
                comment: "Biometric authentication is when the system prompts users for Face ID or fingerprint before accessing protected information. This string asks the user to enter their device passcode to access the protected screen.")
            public static let UniversalAuthenticationReasonV2 = MZLocalizedString(
                key: "Biometry.Screen.UniversalAuthenticationReason.v122",
                tableName: "BiometricAuthentication",
                value: "Authenticate to access your saved passwords and payment methods.",
                comment: "Biometric authentication is when the system prompts users for Face ID or fingerprint before accessing protected information. This string asks the user to enter their device passcode to access the protected screen for logins and encrypted cards.")
        }
    }
}

// MARK: - Bookmarks Panel
extension String {
    public struct Bookmarks {
        public struct Menu {
            public static let DesktopBookmarks = MZLocalizedString(
                key: "Bookmarks.Menu.DesktopBookmarks",
                tableName: nil,
                value: "Desktop Bookmarks",
                comment: "A label indicating all bookmarks grouped under the category 'Desktop Bookmarks'.")
            public static let EditBookmark = MZLocalizedString(
                key: "Bookmarks.Menu.EditBookmark.v131",
                tableName: "Bookmarks",
                value: "Edit Bookmark",
                comment: "When a bookmark is longpressed in the bookmarks menu, an `Edit Bookmark` button is present.")
            public static let EditFolder = MZLocalizedString(
                key: "Bookmarks.Menu.EditFolder.v131",
                tableName: "Bookmarks",
                value: "Edit Folder",
                comment: "When a folder is longpressed in the bookmarks menu, an `Edit Folder` button is present.")
            public static let DeleteFolder = MZLocalizedString(
                key: "Bookmarks.Menu.DeleteFolder.v131",
                tableName: "Bookmarks",
                value: "Delete Folder",
                comment: "When a folder is longpressed in the bookmarks menu, a `Delete Folder` button is present.")
            public static let AllBookmarks = MZLocalizedString(
                key: "Bookmarks.Menu.AllBookmarks.v131",
                tableName: "Bookmarks",
                value: "All",
                comment: "When navigating through the bookmarks menu and bookmark folders, a back button with an `All` (bookmarks) label is present to take the user to the top level bookmarks menu.")
            public static let EditBookmarkSaveIn = MZLocalizedString(
                key: "Bookmarks.Menu.EditBookmarkSaveIn.v131",
                tableName: "Bookmarks",
                value: "Save in",
                comment: "When editing a bookmark, you can select the folder that the bookmark will be saved in. The label for this section of the view is `Save in`.")
            public static let EditBookmarkSave = MZLocalizedString(
                key: "Bookmarks.Menu.EditBookmarkSave.v135",
                tableName: "Bookmarks",
                value: "Save",
                comment: "When editing a bookmark, the right button in the navigation bar indicating that the edited bookmark will be saved.")
            public static let EditBookmarkTitle = MZLocalizedString(
                key: "Bookmarks.Menu.EditBookmarkTitle.v131",
                tableName: "Bookmarks",
                value: "Edit Bookmark",
                comment: "Label on the top of the `Edit Bookmarks` screen.")
            public static let EditBookmarkDesktopBookmarksLabel = MZLocalizedString(
                key: "Bookmarks.Menu.EditBookmarkDesktopBookmarksLabel.v136",
                tableName: "Bookmarks",
                value: "DESKTOP BOOKMARKS",
                comment: "Header denoting that the proceeding folders in the parent folder selector table of the Edit Bookmarks Screen are folders shared with desktop.")
            public static let DeletedBookmark = MZLocalizedString(
                key: "Bookmarks.Menu.DeletedBookmark.v131",
                tableName: "Bookmarks",
                value: "Deleted “%@”",
                comment: "Label of toast displayed after a bookmark is deleted in the Bookmarks menu. %@ is the name of the bookmark.")
            public static let DeleteBookmark = MZLocalizedString(
                key: "Bookmarks.Menu.DeleteBookmark.v132",
                tableName: "Bookmarks",
                value: "Delete Bookmark",
                comment: "The title for the Delete Bookmark button, in the Edit Bookmark popup screen which is summoned from the main menu's Save submenu, which will delete the currently bookmarked site from the user's bookmarks.")
            public static let SavedBookmarkToastLabel = MZLocalizedString(
                key: "Bookmarks.Menu.SavedBookmarkToastLabel.v136",
                tableName: "Bookmarks",
                value: "Saved in “%@”",
                comment: "The label displayed in the toast notification when saving a bookmark via the menu to a custom folder. %@ represents the custom name of the folder, created by the user, where the bookmark will be saved to.")
            public static let SavedBookmarkToastDefaultFolderLabel = MZLocalizedString(
                key: "Bookmarks.Menu.SavedBookmarkToastDefaultFolderLabel.v136",
                tableName: "Bookmarks",
                value: "Saved in “Bookmarks”",
                comment: "The label displayed in the toast notification when saving a bookmark via the menu to the default folder. \"Bookmarks\" is the name of the default folder where the bookmark will be saved to.")
            public static let MoreOptionsA11yLabel = MZLocalizedString(
                key: "Bookmarks.Menu.MoreOptionsA11yLabel.v136",
                tableName: "Bookmarks",
                value: "More options",
                comment: "Accessibility label for the \"...\" disclosure button located within every bookmark site cell in the bookmarks panel. Pressing this button opens a modal with more actions.")
            public static let ClearTextFieldButtonA11yLabel = MZLocalizedString(
                key: "Bookmarks.Menu.ClearTextFieldButtonA11yLabel.v139",
                tableName: "Bookmarks",
                value: "Clear",
                comment: "Accessibility label for the clear button located within every bookmark cell text field in the bookmarks panel. Pressing this button will clear the text field's text")
            public static let RemoveFromShortcutsTitle = MZLocalizedString(
                key: "Bookmarks.Menu.RemoveFromShortcutsTitle.v139",
                tableName: "Bookmarks",
                value: "Remove from Shortcuts",
                comment: "The title for the unpinning shortcut action in the context menu when tapping on the bookmark's item menu button")
        }

        public struct EmptyState {
            public struct Root {
                public static let Title = MZLocalizedString(
                    key: "Bookmarks.EmptyState.Root.Title.v135",
                    tableName: "Bookmarks",
                    value: "No bookmarks yet",
                    comment: "The title for the placeholder screen shown when there are no saved bookmarks, located at the root level of the bookmarks panel within the library modal.")
                public static let BodySignedIn = MZLocalizedString(
                    key: "Bookmarks.EmptyState.Root.Body.v135",
                    tableName: "Bookmarks",
                    value: "Save sites as you browse. We’ll also grab bookmarks from other synced devices.",
                    comment: "The body text for the placeholder screen shown when there are no saved bookmarks, located at the root level of the bookmarks panel within the library modal.")
                public static let BodySignedOut = MZLocalizedString(
                    key: "Bookmarks.EmptyState.Root.BodySignedOut.v135",
                    tableName: "Bookmarks",
                    value: "Save sites as you browse. Sign in to grab bookmarks from other synced devices.",
                    comment: "The body text for the placeholder screen shown when the user is signed out and there are no saved bookmarks, located at the root level of the bookmarks panel within the library modal.")
                public static let ButtonTitle = MZLocalizedString(
                    key: "Bookmarks.EmptyState.Root.ButtonTitle.v136",
                    tableName: "Bookmarks",
                    value: "Sign in to Sync",
                    comment: "The button title for the sign in button on the placeholder screen shown when there are no saved bookmarks, located at the root level of the bookmarks panel within the library modal. This button triggers the sign in flow, allowing users to sign in to their Mozilla Account to sync data. In this string, \"Sync\" is used as a verb, and is capitalized as per convention to title case text for buttons in iOS")
            }
            public struct Nested {
                public static let Title = MZLocalizedString(
                    key: "Bookmarks.EmptyState.Nested.Title.v135",
                    tableName: "Bookmarks",
                    value: "This folder is empty",
                    comment: "The title for the placeholder screen shown when there are no saved bookmarks, located within a nested subfolder of the bookmarks panel within the library modal.")
                public static let Body = MZLocalizedString(
                    key: "Bookmarks.EmptyState.Nested.Body.v135",
                    tableName: "Bookmarks",
                    value: "Add bookmarks as you browse so you can find your favorite sites later.",
                    comment: "The body text for the placeholder screen shown when there are no saved bookmarks, located within a nested subfolder of the bookmarks panel within the library modal.")
            }
        }
    }
}

// MARK: - Contextual Hints
extension String {
    public struct ContextualHints {
        public static let ContextualHintsCloseAccessibility = MZLocalizedString(
            key: "ContextualHintsCloseButtonAccessibility.v105",
            tableName: nil,
            value: "Close",
            comment: "Accessibility label for action denoting closing contextual hint.")

        public struct FirefoxHomepage {
            public struct JumpBackIn {
                public static let PersonalizedHome = MZLocalizedString(
                    key: "ContextualHints.FirefoxHomepage.JumpBackIn.PersonalizedHome",
                    tableName: "JumpBackIn",
                    value: "Meet your personalized homepage. Recent tabs, bookmarks, and search results will appear here.",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. This one talks about additions to the Firefox homepage regarding a more personalized experience.")
                public static let SyncedTab = MZLocalizedString(
                    key: "ContextualHints.FirefoxHomepage.JumpBackIn.SyncedTab.v106",
                    tableName: "JumpBackIn",
                    value: "Your tabs are syncing! Pick up where you left off on your other device.",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. When a user is logged in and has a tab synced from desktop, this popup indicates which tab that is within the Jump Back In section.")
            }
        }

        public struct MainMenu {
            public struct NewMenu {
                public static let Title = MZLocalizedString(
                    key: "ContextualHints.MainMenu.NewMenu.Title.v132",
                    tableName: "MainMenu",
                    value: "New: streamlined menu",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. When a user opens the new menu design for the first time, this contextual hint appears. This is the title for the hint.")
                public static let Body = MZLocalizedString(
                    key: "ContextualHints.MainMenu.NewMenu.Body.v132",
                    tableName: "MainMenu",
                    value: "Find what you need faster, from private browsing to save actions.",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. When a user opens the new menu design for the first time, this contextual hint appears. This is the body text for the hint.")
            }
        }

        public struct TabsTray {
            public struct InactiveTabs {
                public static let Action = MZLocalizedString(
                    key: "ContextualHints.TabTray.InactiveTabs.CallToAction",
                    tableName: nil,
                    value: "Turn off in settings",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. This one is the call to action for the inactive tabs contextual popup.")
                public static let Body = MZLocalizedString(
                    key: "ContextualHints.TabTray.InactiveTabs",
                    tableName: nil,
                    value: "Tabs you haven’t viewed for two weeks get moved here.",
                    comment: "Contextual hints are little popups that appear for the users informing them of new features. This one talks about the inactive tabs feature.")
            }
        }

        public struct Toolbar {
            public static let SearchBarPlacementButtonText = MZLocalizedString(
                key: "ContextualHints.SearchBarPlacement.CallToAction",
                tableName: nil,
                value: "Toolbar Settings",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one is a call to action for the popup describing search bar placement. It indicates a user can navigate to the settings page that allows them to customize the placement of the search bar.")
            public static let SearchBarTopPlacement = MZLocalizedString(
                key: "ContextualHints.Toolbar.Top.Description.v107",
                tableName: "ToolbarLocation",
                value: "Move the toolbar to the bottom if that’s more your style.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one indicates a user can navigate to the Settings page to move the search bar to the bottom.")
            public static let SearchBarBottomPlacement = MZLocalizedString(
                key: "ContextualHints.Toolbar.Bottom.Description.v107",
                tableName: "ToolbarLocation",
                value: "Move the toolbar to the top if that’s more your style.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one indicates a user can navigate to the Settings page to move the search bar to the top.")
            public static let NavigationButtonsBody = MZLocalizedString(
                key: "ContextualHints.Toolbar.Navigation.Description.v132",
                tableName: "ToolbarLocation",
                value: "Tap and hold the arrows to jump between pages in this tab’s history.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one indicates a user can press and hold either the back or forward web navigation buttons to quickly navigate their back/forward history")
        }

        public struct Shopping {
            public static let NotOptedInBody = MZLocalizedString(
                key: "ContextualHints.Shopping.NotOptedIn.v120",
                tableName: "Shopping",
                value: "Find out if you can trust this product’s reviews — before you buy.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one indicates that a user can tap on the shopping button to start using the Shopping feature.")
            public static let NotOptedInAction = MZLocalizedString(
                key: "ContextualHints.Shopping.NotOptedInAction.v120",
                tableName: "Shopping",
                value: "Try Review Checker",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one is a call to action for the popup describing the Shopping feature. It indicates that a user can go directly to the Shopping feature by tapping the text of the action.")
            public static let OptedInBody = MZLocalizedString(
                key: "ContextualHints.Shopping.OptedInBody.v120",
                tableName: "Shopping",
                value: "Are these reviews reliable? Check now to see an adjusted rating.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This one appears after the user has opted in and informs him if he wants use the review checker by tapping the Shopping button.")
            public static let OptedInAction = MZLocalizedString(
                key: "ContextualHints.Shopping.OptedInAction.v120",
                tableName: "Shopping",
                value: "Open Review Checker",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This is a call to action for the popup that appears after the user has opted in for the Shopping feature. It indicates that a user can directly open the review checker by tapping the text of the action.")
        }

        public struct FeltDeletion {
            public static let Body = MZLocalizedString(
                key: "ContextualHints.FeltDeletion.Body.v122",
                tableName: "ContextualHints",
                value: "Tap here to start a fresh private session. Delete your history, cookies — everything.",
                comment: "Contextual hints are little popups that appear for the users informing them of new features. This is a call to action for the popup that appears to educate users about what the fire button in the toolbar does, when in private mode.")
        }
    }
}

// MARK: - Keyboard Accessory View
extension String {
    public struct KeyboardAccessory {
        public static let NextButtonA11yLabel = MZLocalizedString(
            key: "KeyboardAccessory.NextButton.Accessibility.Label.v124",
            tableName: "KeyboardAccessory",
            value: "Next form field",
            comment: "Accessibility label for next button that is displayed above the keyboard when a form field on a website was tapped.")
        public static let PreviousButtonA11yLabel = MZLocalizedString(
            key: "KeyboardAccessory.PreviousButton.Accessibility.Label.v124",
            tableName: "KeyboardAccessory",
            value: "Previous form field",
            comment: "Accessibility label for previous button that is displayed above the keyboard when a form field on a website was tapped.")
    }
}

// MARK: - Address Autofill
extension String {
    public struct Addresses {
        public struct Settings {
            public static let SwitchTitle = MZLocalizedString(
                key: "Addresses.Settings.Switch.Title.v124",
                tableName: "Settings",
                value: "Save and Fill Addresses",
                comment: "Title label for user to use the toggle settings to allow saving and autofilling of addresses for webpages.")
            public static let SwitchDescription = MZLocalizedString(
                key: "Addresses.Settings.Switch.Description.v124",
                tableName: "Settings",
                value: "Includes phone numbers and email addresses",
                comment: "On the autofill settings screen, a label under the title label to add additional context for user in regards to what the toggle switch that allow saving and autofilling of addresses for webpages does, letting users know that this action includes phone numbers and email addresses.")
            public static let SavedAddressesSectionTitle = MZLocalizedString(
                key: "Addresses.Settings.SavedAddressesSectionTitle.v124",
                tableName: "Settings",
                value: "SAVED ADDRESSES",
                comment: "On the autofill settings screen, a label for the section that displays the list of saved addresses. This label adds additional context for users regarding the toggle switch that allows saving and autofilling of addresses for webpages.")
            public static let UseSavedAddressFromKeyboard = MZLocalizedString(
                key: "Addresses.Settings.UseSavedAddressFromKeyboard.v124",
                tableName: "Settings",
                value: "Use saved address",
                comment: "Displayed inside the keyboard hint when a user is entering their address and has at least one saved address. Indicates that there are stored addresses available for use in filling out a form.")
            public static let SaveAddressesToFirefox = MZLocalizedString(
                key: "Addresses.Settings.SaveToFirefox.Title.v130",
                tableName: "Settings",
                value: "Save Addresses to %@",
                comment: "Title text for the content unavailable view informing users they can create or add new addresses. %@ is the name of the app.")
            public static let SecureSaveInfo = MZLocalizedString(
                key: "Addresses.Settings.SecureSaveInfo.Description.v130",
                tableName: "Settings",
                value: "Securely save your information to get quick access to it later.",
                comment: "Description text for the content unavailable view informing users they can create or add new addresses.")
            public static let ListItemA11y = MZLocalizedString(
                key: "Addresses.Settings.ListItemA11y.v130",
                tableName: "Settings",
                value: "Address for %@",
                comment: "Accessibility label for an address list item in autofill settings screen. The %@ parameter is the address of the user that will read the name, street, city, state, postal code if available.")
            public struct Edit {
                public static let AddressRemovedConfirmation = MZLocalizedString(
                    key: "Addresses.Toast.AddressRemovedConfirmation.v129",
                    tableName: "EditAddress",
                    value: "Address Removed",
                    comment: "Toast message confirming that an address has been successfully removed."
                )
                public static let AddressSavedConfirmation = MZLocalizedString(
                    key: "Addresses.Toast.AddressSavedConfirmation.v129",
                    tableName: "EditAddress",
                    value: "Address Saved",
                    comment: "Toast message confirming that an address has been successfully saved."
                )
                public static let AddressRemoveError = MZLocalizedString(
                    key: "Addresses.Toast.AddressSaveError.v130",
                    tableName: "EditAddress",
                    value: "Address Couldn’t Be Removed",
                    comment: "Toast message indicating an error occurred while trying to remove an address."
                )
                public static let AddressSaveError = MZLocalizedString(
                    key: "Addresses.Toast.AddressSaveError.v129",
                    tableName: "EditAddress",
                    value: "Address Couldn’t Be Saved",
                    comment: "Toast message indicating an error occurred while trying to save an address."
                )
                public static let AddressSaveRetrySuggestion = MZLocalizedString(
                    key: "Addresses.Toast.AddressSaveRetrySuggestion.v129",
                    tableName: "EditAddress",
                    value: "Try again",
                    comment: "Suggestion to try again after an error occurred while trying to save an address."
                )
                public static let AddressUpdatedConfirmation = MZLocalizedString(
                    key: "Addresses.Toast.AddressUpdatedConfirmation.v129",
                    tableName: "EditAddress",
                    value: "Address Information Updated",
                    comment: "Toast message confirming that an address has been successfully updated."
                )
                 public static let AddressUpdatedConfirmationV2 = MZLocalizedString(
                    key: "Addresses.Toast.AddressUpdatedConfirmation.v132.v2",
                    tableName: "EditAddress",
                    value: "Address Saved",
                    comment: "Toast message confirming that an address has been successfully updated."
                )
                public static let RemoveAddressTitle = MZLocalizedString(
                    key: "Addresses.EditAddress.Alert.Title.v129",
                    tableName: "EditAddress",
                    value: "Remove Address",
                    comment: "Title for the alert indicating the action to remove an address."
                )
                public static let CancelButtonTitle = MZLocalizedString(
                    key: "Addresses.EditAddress.Alert.CancelButton.v129",
                    tableName: "EditAddress",
                    value: "Cancel",
                    comment: "Title for the cancel button in the remove address alert."
                )
                public static let RemoveButtonTitle = MZLocalizedString(
                    key: "Addresses.EditAddress.Alert.RemoveButton.v129",
                    tableName: "EditAddress",
                    value: "Remove",
                    comment: "Title for the remove button in the remove address alert."
                )
                public static let RemoveAddressMessage = MZLocalizedString(
                    key: "Addresses.EditAddress.Alert.Message.v129",
                    tableName: "EditAddress",
                    value: "The address will be removed from all of your synced devices.",
                    comment: "Message explaining the consequences of removing an address from all synced devices."
                )
                public static let RemoveAddressButtonTitle = MZLocalizedString(
                    key: "Addresses.EditAddress.RemoveAddressButtonTitle.v129",
                    tableName: "EditAddress",
                    value: "Remove Address",
                    comment: "Title for button that offers the user the option to remove an address."
                )
                public static let AutofillAddAddressTitle = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddAddressTitle.v129",
                    tableName: "EditAddress",
                    value: "Add address",
                    comment: "Title for the interface option where users can add a new address for autofill purposes. This facilitates quicker form completion by automatically filling in the user's address information."
                )
                public static let AutofillEditStreetAddressTitle = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillEditStreetAddressTitle.v129",
                    tableName: "EditAddress",
                    value: "Street Address",
                    comment: "Title for the input field where users can enter their street address. This is used within the settings for autofill, allowing users to provide their street address for accurate form autofilling."
                )
                public static let AutofillEditAddressTitle = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillEditAddressTitle.v129",
                    tableName: "EditAddress",
                    value: "Edit address",
                    comment: "Title for the option allowing users to edit an existing saved address. This is used within the settings for autofill, enabling users to update their address details for accurate form autofilling."
                )
                public static let AutofillViewAddressTitle = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillViewAddressTitle.v129",
                    tableName: "EditAddress",
                    value: "View address",
                    comment: "Title for the option allowing users to view an existing saved address. This is used within the settings for autofill, enabling users to see their address details for accurate form autofilling."
                )
                public static let AutofillAddressName = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressName.v129",
                    tableName: "EditAddress",
                    value: "Name",
                    comment: "Label for the field where the user inputs their full name as part of an address form. Essential for personalized form submissions and ensuring information accuracy in autofilled forms."
                )
                public static let AutofillAddressOrganization = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressOrganization.v129",
                    tableName: "EditAddress",
                    value: "Organization",
                    comment: "Label for the input field designated for the organization's name related to the address. Helps in distinguishing addresses used for business or personal purposes in autofill settings."
                )
                public static let AutofillAddressNeighborhood = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressNeighborhood.v129",
                    tableName: "EditAddress",
                    value: "Neighborhood",
                    comment: "Label for the field where users can input the name of their neighborhood. This detail adds precision to addresses, especially in densely populated areas, improving the accuracy of autofill."
                )
                public static let AutofillAddressVillageTownship = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressVillageTownship.v129",
                    tableName: "EditAddress",
                    value: "Village or Township",
                    comment: "Label for the field to input the name of a village or township. This is crucial for addresses in rural areas, ensuring the autofill feature accurately captures all necessary geographical details."
                )
                public static let AutofillAddressIsland = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressIsland.v129",
                    tableName: "EditAddress",
                    value: "Island",
                    comment: "Label for the field where users specify the name of an island, if applicable. Important for addresses in archipelagic regions, aiding in precise location identification during autofill."
                )
                public static let AutofillAddressTownland = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressTownland.v129",
                    tableName: "EditAddress",
                    value: "Townland",
                    comment: "Label for the input field for the townland, a specific type of land division used in rural areas. Enhances address detail for users in regions where townlands are a common addressing component."
                )
                public static let AutofillAddressCity = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressCity.v129",
                    tableName: "EditAddress",
                    value: "City",
                    comment: "Label for the field where users input the city part of their address. This information is crucial for mail delivery and service provision, ensuring accurate city identification in autofill settings."
                )
                public static let AutofillAddressDistrict = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressDistrict.v129",
                    tableName: "EditAddress",
                    value: "District",
                    comment: "Label for the district field in the address form, allowing users to specify their district for more precise location identification. This aids in refining address details for accurate autofill."
                )
                public static let AutofillAddressPostTown = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressPostTown.v129",
                    tableName: "EditAddress",
                    value: "Post town",
                    comment: "Label for the post town field, used primarily in the UK and some other regions for mail sorting. Essential for users in applicable areas to specify for correct mail delivery through autofill."
                )
                public static let AutofillAddressSuburb = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressSuburb.v129",
                    tableName: "EditAddress",
                    value: "Suburb",
                    comment: "Label for the suburb field, enabling users to add suburb details to their address. This is important for accurate delivery and services in suburban areas, enhancing autofill functionality."
                )
                public static let AutofillAddressProvince = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressProvince.v129",
                    tableName: "EditAddress",
                    value: "Province",
                    comment: "Label for the province field, required in countries where provinces are a primary administrative division. Helps in pinpointing the user's location more accurately for autofill purposes."
                )
                public static let AutofillAddressState = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressState.v129",
                    tableName: "EditAddress",
                    value: "State",
                    comment: "Label for the state field, a necessary component of addresses in many countries, especially the USA. It ensures that state-specific details are correctly filled in forms using autofill."
                )
                public static let AutofillAddressCounty = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressCounty.v129",
                    tableName: "EditAddress",
                    value: "County",
                    comment: "Label for the county field, crucial for addressing in regions where county lines play a key role in postal services. Enhances autofill accuracy by including county information."
                )
                public static let AutofillAddressParish = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressParish.v129",
                    tableName: "EditAddress",
                    value: "Parish",
                    comment: "Label for the parish field, significant in places where parishes are used for local administration and addressing. Ensures users can specify parish details for better autofill accuracy."
                )
                public static let AutofillAddressPrefecture = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressPrefecture.v129",
                    tableName: "EditAddress",
                    value: "Prefecture",
                    comment: "Label for the prefecture field, essential for addresses in countries like Japan where prefectures are a major administrative division. Aids in precise location specification for autofill."
                )
                public static let AutofillAddressArea = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressArea.v129",
                    tableName: "EditAddress",
                    value: "Area",
                    comment: "Label for the area field, allowing users to specify a particular area within a city or region. This detail can improve the specificity and accuracy of autofilled addresses."
                )
                public static let AutofillAddressDoSi = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressDoSi.v129",
                    tableName: "EditAddress",
                    value: "Do/Si",
                    comment: "Label for the Do/Si field, pertinent to addresses in South Korea. Do/Si refers to provincial level divisions, and specifying this enhances address accuracy in autofill settings."
                )
                public static let AutofillAddressDepartment = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressDepartment.v129",
                    tableName: "EditAddress",
                    value: "Department",
                    comment: "Label for the department field, used in countries like France and Colombia where departments are a key administrative division. Ensures correct departmental information is autofilled."
                )
                public static let AutofillAddressEmirate = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressEmirate.v129",
                    tableName: "EditAddress",
                    value: "Emirate",
                    comment: "Label for the emirate field, essential for addresses in the United Arab Emirates. Including emirate details ensures the autofill feature accurately represents user addresses."
                )
                public static let AutofillAddressOblast = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressOblast.v129",
                    tableName: "EditAddress",
                    value: "Oblast",
                    comment: "Label for the oblast field, relevant for addresses in countries like Russia and Ukraine. Oblasts are a significant administrative division, and their specification aids in autofill accuracy."
                )
                public static let AutofillAddressPin = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressPin.v129",
                    tableName: "EditAddress",
                    value: "Pin",
                    comment: "Label for the PIN (Postal Index Number) field, used in India. It's a code representing a specific area, crucial for accurate mail delivery and autofill functionality."
                )
                public static let AutofillAddressPostalCode = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressPostalCode.v129",
                    tableName: "EditAddress",
                    value: "Postal Code",
                    comment: "Label for the postal code field, universally used in address forms to specify the area code for mail sorting. Essential for autofill to ensure mail and services are accurately routed."
                )
                public static let AutofillAddressZip = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressZip.v129",
                    tableName: "EditAddress",
                    value: "ZIP Code",
                    comment: "Label for the ZIP code field, primarily used in the United States for mail sorting. Key for autofill to accurately complete addresses for shipping, billing, and service provision."
                )
                public static let AutofillAddressEircode = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressEircode.v129",
                    tableName: "EditAddress",
                    value: "Eircode",
                    comment: "Label for the Eircode field, specific to Ireland. It's a unique postal code system that helps in precise location identification, enhancing the effectiveness of autofill."
                )
                public static let AutofillAddressCountryRegion = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressCountryRegion.v129",
                    tableName: "EditAddress",
                    value: "Country or Region",
                    comment: "Label for the country or region field in address forms, allowing users to specify their country or territorial region. This is fundamental for international mail and services, ensuring autofill accuracy across borders."
                )
                public static let AutofillAddressCountryOnly = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressCountryOnly.v129",
                    tableName: "EditAddress",
                    value: "Country",
                    comment: "Label for the field where users can specify just the country, used in contexts where full address details are not required. Simplifies autofill when only country information is necessary."
                )
                public static let AutofillAddressTel = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressTel.v129",
                    tableName: "EditAddress",
                    value: "Phone",
                    comment: "Label for the telephone number field, allowing users to input their contact number. This is essential for communication and service provision, ensuring contact details are autofilled correctly."
                )
                public static let AutofillAddressEmail = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillAddressEmail.v129",
                    tableName: "EditAddress",
                    value: "Email",
                    comment: "Label for the email address field, where users input their email. Critical for digital communication and account verification, this ensures email addresses are autofilled accurately."
                )
                public static let AutofillCancelButton = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillCancelButton.v129",
                    tableName: "EditAddress",
                    value: "Cancel",
                    comment: "Label for the button to cancel the current autofill operation or exit the form without saving changes. Provides users with an option to back out of a process without making any modifications."
                )
                public static let AutofillSaveButton = MZLocalizedString(
                    key: "Addresses.EditAddress.AutofillSaveButton.v129",
                    tableName: "EditAddress",
                    value: "Save",
                    comment: "Label for the button to save the current address details entered or edited by the user. This action confirms the user's changes and updates their autofill settings accordingly."
                )
                public static let CloseNavBarButtonLabel = MZLocalizedString(
                    key: "Addresses.EditAddress.CloseNavBarButtonLabel.v129",
                    tableName: "EditAddress",
                    value: "Close",
                    comment: "Button label for closing the view where user can view their address info."
                )
                public static let EditNavBarButtonLabel = MZLocalizedString(
                    key: "Addresses.EditAddress.EditNavBarButtonLabel.v129",
                    tableName: "EditAddress",
                    value: "Edit",
                    comment: "Button label for editing the address details shown in the form."
                )
            }
        }
        public struct BottomSheet {
            public static let UseASavedAddress = MZLocalizedString(
                key: "Addresses.BottomSheet.UseSavedAddressBottomSheet.v124",
                tableName: "BottomSheet",
                value: "Use a saved address?",
                comment: "When a user is in the process of entering an address, a screen pops up prompting the user if they want to use a saved address. This string is used as the title label of the screen.")
            public static let ManageAddressesButton = MZLocalizedString(
                key: "Addresses.ManageAddressesButton.v130",
                tableName: "Settings",
                value: "Manage addresses",
                comment: "This label is used for a button in the address list screen allowing users to manage their saved addresses. It's meant to direct users to where they can add, remove, or edit their saved addresses.")
        }
    }
}

// MARK: - Credit card
extension String {
    public struct CreditCard {
        // Settings / Empty State / Keyboard input accessory view
        public struct Settings {
            public static let AddCardAccessibilityLabel = MZLocalizedString(
                key: "CreditCard.Settings.AddCard.AccessibilityLabel.v121",
                tableName: "Settings",
                value: "Add Card",
                comment: "Accessibility label for the add button in autofill settings screen. Pressing this button presents a modal that allows users to add a card by entering the credit card information.")
            public static let EmptyListTitle = MZLocalizedString(
                key: "CreditCard.Settings.EmptyListTitle.v122",
                tableName: "Settings",
                value: "Save Cards to %@",
                comment: "Title label for when there are no credit cards shown in credit card list in autofill settings screen. %@ is the product name and should not be altered.")
            public static let EmptyListDescription = MZLocalizedString(
                key: "CreditCard.Settings.EmptyListDescription.v112",
                tableName: "Settings",
                value: "Save your card information securely to check out faster next time.",
                comment: "Description label for when there are no credit cards shown in credit card list in autofill settings screen.")
            public static let RememberThisCard = MZLocalizedString(
                key: "CreditCard.Settings.RememberThisCard.v122",
                tableName: "Settings",
                value: "Securely save this card?",
                comment: "When a user is in the process or has finished making a purchase with a card not saved in Firefox's list of stored cards, we ask the user if they would like to save this card for future purchases. This string is a title string of the overall message that asks the user if they would like Firefox to remember the card that is being used.")
            public static let Yes = MZLocalizedString(
                key: "CreditCard.Settings.Yes.v122",
                tableName: "Settings",
                value: "Update",
                comment: "When a user is in the process or has finished making a purchase with a card not saved in Firefox's list of stored cards, we ask the user if they would like to save this card for future purchases. This string asks users to confirm if they would like Firefox to remember the card that is being used.")
            public static let NotNow = MZLocalizedString(
                key: "CreditCard.Settings.NotNow.v122",
                tableName: "Settings",
                value: "Not Now",
                comment: "When a user is in the process or has finished making a purchase with a card not saved in Firefox's list of stored cards, we ask the user if they would like to save this card for future purchases. This string indicates to users that they can deny Firefox from remembering the card that is being used.")
            public static let UpdateThisCard = MZLocalizedString(
                key: "CreditCard.Settings.UpdateThisCard.v122",
                tableName: "Settings",
                value: "Update card?",
                comment: "When a user is in the process or has finished making a purchase with a remembered card, and if the credit card information doesn't match the contents of the stored information of that card, we show this string. We ask this user if they would like Firefox update the staled information of that credit card.")
            public static let ManageCards = MZLocalizedString(
                key: "CreditCards.Settings.ManageCards.v112",
                tableName: "Settings",
                value: "Manage cards",
                comment: "When a user is in the process or has finished making a purchase, and has at least one card saved, we show this tappable string. This indicates to users that they can navigate to their list of stored credit cards in the app's credit card list screen.")
            public static let UseASavedCard = MZLocalizedString(
                key: "CreditCards.Settings.UseASavedCard.v122",
                tableName: "Settings",
                value: "Use saved card",
                comment: "When a user is in the process of making a purchase, and has at least one saved card, we show this label used as a title. This indicates to the user that there are stored cards available for use on this pending purchase.")
            public static let UseSavedCardFromKeyboard = MZLocalizedString(
                key: "CreditCards.Settings.UseSavedCardFromKeyboard.v112",
                tableName: "Settings",
                value: "Use saved card",
                comment: "When a user is in the process of making a purchase, and has at least one saved card, we show this label inside the keyboard hint. This indicates to the user that there are stored cards available for use on this pending purchase.")
            public static let Done = MZLocalizedString(
                key: "CreditCards.Settings.Done.v114",
                tableName: "Settings",
                value: "Done",
                comment: "When a user is in the process of making a purchase and has at least one saved credit card, a view above the keyboard shows actions a user can take. When tapping this label, the keyboard will dismiss from view.")
            public static let ListItemA11y = MZLocalizedString(
                key: "CreditCard.Settings.ListItemA11y.v118",
                tableName: "Settings",
                value: "%1$@, issued to %2$@, ending in %3$@, expires %4$@",
                comment: "Accessibility label for a credit card list item in autofill settings screen. %1$@ is the credit card issuer (e.g. Visa), %2$@ is the name of the credit card holder, %3$@ is the last 4 digits of the credit card, %4$@ is the card's expiration date.")
        }

        // Displaying a credit card
        public struct DisplayCard {
            public static let ExpiresLabel = MZLocalizedString(
                key: "CreditCard.DisplayCard.ExpiresLabel.v115",
                tableName: "DisplayCard",
                value: "Expires",
                comment: "Label for the expiry date of the credit card.")
        }

        // Editing and saving credit card
        public struct EditCard {
            public static let RevealLabel = MZLocalizedString(
                key: "CreditCard.EditCard.RevealLabel.v114",
                tableName: "EditCard",
                value: "Reveal",
                comment: "Label for revealing the contents of the credit card number")
            public static let ConcealLabel = MZLocalizedString(
                key: "CreditCard.EditCard.ConcealLabel.v114",
                tableName: "EditCard",
                value: "Conceal",
                comment: "Label for concealing contents of the credit card number")
            public static let CopyLabel = MZLocalizedString(
                key: "CreditCard.EditCard.CopyLabel.v113",
                tableName: "EditCard",
                value: "Copy",
                comment: "Label for copying contents of the form")
            public static let CloseNavBarButtonLabel = MZLocalizedString(
                key: "CreditCard.EditCard.CloseNavBarButtonLabel.v113",
                tableName: "EditCard",
                value: "Close",
                comment: "Button label for closing the view where user can view their credit card info")
            public static let SaveNavBarButtonLabel = MZLocalizedString(
                key: "CreditCard.EditCard.SaveNavBarButtonLabel.v113",
                tableName: "EditCard",
                value: "Save",
                comment: "Button label for saving the credit card details user entered in the form")
            public static let EditNavBarButtonLabel = MZLocalizedString(
                key: "CreditCard.EditCard.EditNavBarButtonLabel.v113",
                tableName: "EditCard",
                value: "Edit",
                comment: "Button label for editing the credit card details shown in the form")
            public static let CancelNavBarButtonLabel = MZLocalizedString(
                key: "CreditCard.EditCard.CancelNavBarButtonLabel.v113",
                tableName: "EditCard",
                value: "Cancel",
                comment: "Button label for cancelling editing of the credit card details shown in the form")
            public static let ViewCreditCardTitle = MZLocalizedString(
                key: "CreditCard.EditCard.ViewCreditCardTitle.v116",
                tableName: "EditCard",
                value: "View Card",
                comment: "Title label for the view where user can view their credit card info")
            public static let AddCreditCardTitle = MZLocalizedString(
                key: "CreditCard.EditCard.AddCreditCardTitle.v122",
                tableName: "EditCard",
                value: "Add Card",
                comment: "Title label for the view where user can add their credit card info")
            public static let EditCreditCardTitle = MZLocalizedString(
                key: "CreditCard.EditCard.EditCreditCardTitle.v122",
                tableName: "Edit Card",
                value: "Edit Card",
                comment: "Title label for the view where user can edit their credit card info")
            public static let NameOnCardTitle = MZLocalizedString(
                key: "CreditCard.EditCard.NameOnCardTitle.v112",
                tableName: "EditCard",
                value: "Name on Card",
                comment: "Title label for user to input their name printed on their credit card in the text box below.")
            public static let CardNumberTitle = MZLocalizedString(
                key: "CreditCard.EditCard.CardNumberTitle.v112",
                tableName: "EditCard",
                value: "Card Number",
                comment: "Title label for user to input their credit card number printed on their credit card in the text box below.")
            public static let CardExpirationDateTitle = MZLocalizedString(
                key: "CreditCard.EditCard.CardExpirationDateTitle.v112",
                tableName: "EditCard",
                value: "Expiration MM / YY",
                comment: "Title label for user to input their credit card Expiration date in the format MM / YY printed on their credit card in the text box below.")
            public static let RemoveCardButtonTitle = MZLocalizedString(
                key: "CreditCard.EditCard.RemoveCardButtonTitle.v112",
                tableName: "EditCard",
                value: "Remove Card",
                comment: "Title label for button that allows user to remove their saved credit card.")
            public static let ToggleToAllowAutofillTitle = MZLocalizedString(
                key: "CreditCard.EditCard.ToggleToAllowAutofillTitle.v122",
                tableName: "EditCard",
                value: "Save and Fill Payment Methods",
                comment: "Title label for user to use the toggle settings to allow saving and autofilling of credit cards for webpages.")
            public static let SavedCardListTitle = MZLocalizedString(
                key: "CreditCard.EditCard.SavedCardListTitle.v112",
                tableName: "EditCard",
                value: "SAVED CARDS",
                comment: "Title label for user to pick a credit card from the list below to be updated.")
            public static let ExpiredDateTitle = MZLocalizedString(
                key: "CreditCard.EditCard.ExpiredDateTitle.v112",
                tableName: "EditCard",
                value: "Expires %@",
                comment: "Label for credit card expiration date. The %@ will be replaced by the actual date and thus doesn't need translation.")
            public static let NavButtonSaveTitle = MZLocalizedString(
                key: "CreditCard.EditCard.NavButtonSaveTitle.v112",
                tableName: "EditCard",
                value: "Save",
                comment: "Button title which, when tapped, will allow the user to save valid credit card details.")
        }

        // Remember Card
        public struct RememberCreditCard {
            public static let MainTitle = MZLocalizedString(
                key: "CreditCard.RememberCard.MainTitle.v122",
                tableName: "RememberCard",
                value: "Securely save this card?",
                comment: "This value is used as the title for the remember credit card page")
            public static let Header = MZLocalizedString(
                key: "CreditCard.RememberCard.Header.v122",
                tableName: "RememberCard",
                value: "%@ encrypts your card number. Your security code won’t be saved.",
                comment: "This value is used as the header for the remember card page. %@ is the app name (e.g. Firefox).")
            public static let MainButtonTitle = MZLocalizedString(
                key: "CreditCard.RememberCard.MainButtonTitle.v122",
                tableName: "RememberCard",
                value: "Save",
                comment: "This value is used as the title for the Yes button in the remember credit card page")
            public static let SecondaryButtonTitle = MZLocalizedString(
                key: "CreditCard.RememberCard.SecondaryButtonTitle.v115",
                tableName: "RememberCard",
                value: "Not Now",
                comment: "This value is used as the title for the Not Now button in the remember credit card page")
            public static let CreditCardSaveSuccessToastMessage = MZLocalizedString(
                key: "CreditCard.RememberCard.SecondaryButtonTitle.v116",
                tableName: "RememberCard",
                value: "New Card Saved",
                comment: "This value is used as the toast message for the saving success alert in the remember credit card page")
        }

        // Update Card
        public struct UpdateCreditCard {
            public static let MainTitle = MZLocalizedString(
                key: "CreditCard.UpdateCard.MainTitle.v122",
                tableName: "UpdateCard",
                value: "Update card?",
                comment: "This value is used as the title for the update card page")
            public static let ManageCardsButtonTitle = MZLocalizedString(
                key: "CreditCard.UpdateCard.ManageCardsButtonTitle.v115",
                tableName: "UpdateCard",
                value: "Manage cards",
                comment: "This value is used as the title for the Manage Cards button from the update credit card page")
            public static let MainButtonTitle = MZLocalizedString(
                key: "CreditCard.UpdateCard.YesButtonTitle.v122",
                tableName: "UpdateCard",
                value: "Update",
                comment: "This value is used as the title for the button in the update credit card page. It indicates the action to update the details f9 the card.")
            public static let SecondaryButtonTitle = MZLocalizedString(
                key: "CreditCard.UpdateCard.NotNowButtonTitle.v115",
                tableName: "UpdateCard",
                value: "Not Now",
                comment: "This value is used as the title for the Not Now button in the update credit card page")
            public static let CreditCardUpdateSuccessToastMessage = MZLocalizedString(
                key: "CreditCard.RememberCard.SecondaryButtonTitle.v116",
                tableName: "UpdateCard",
                value: "Card Information Updated",
                comment: "This value is used as the toast message for the saving success alert in the remember credit card page")
        }

        // Select Credit Card
        public struct SelectCreditCard {
            public static let MainTitle = MZLocalizedString(
                key: "CreditCard.SelectCreditCard.MainTitle.v122",
                tableName: "SelectCreditCard",
                value: "Use saved card",
                comment: "This value is used as the title for the select a credit card from list of available cards.")
        }

        // Error States for wrong input while editing credit card
        public struct ErrorState {
            public static let NameOnCardSublabel = MZLocalizedString(
                key: "CreditCard.ErrorState.NameOnCardSublabel.v112",
                tableName: "ErrorState",
                value: "Add a name",
                comment: "Sub label error string that gets shown when user enters incorrect input for their name printed on their credit card in the text box.")
            public static let CardNumberSublabel = MZLocalizedString(
                key: "CreditCard.ErrorState.CardNumberSublabel.v112",
                tableName: "ErrorState",
                value: "Enter a valid card number",
                comment: "Sub label error string that gets shown when user enters incorrect input for their number printed on their credit card in the text box.")
            public static let CardExpirationDateSublabel = MZLocalizedString(
                key: "CreditCard.ErrorState.CardExpirationDateSublabel.v112",
                tableName: "ErrorState",
                value: "Enter a valid expiration date",
                comment: "Sub label error string that gets shown when user enters incorrect input for their expiration date on their credit card in the text box.")
        }

        // Snackbar / toast
        public struct SnackBar {
            public static let SavedCardLabel = MZLocalizedString(
                key: "CreditCard.SnackBar.SavedCardLabel.v112",
                tableName: "SnackBar",
                value: "New Card Saved",
                comment: "Label text that gets presented as a confirmation at the bottom of screen when credit card information gets saved successfully")
            public static let UpdatedCardLabel = MZLocalizedString(
                key: "CreditCard.SnackBar.UpdatedCardLabel.v122",
                tableName: "SnackBar",
                value: "Card Information Updated",
                comment: "Label text that gets presented as a confirmation at the bottom of screen when credit card information gets updated successfully")
            public static let RemovedCardLabel = MZLocalizedString(
                key: "CreditCard.SnackBar.RemovedCardLabel.v112",
                tableName: "SnackBar",
                value: "Card Removed",
                comment: "Label text that gets presented as a confirmation at the bottom of screen when the credit card is successfully removed.")
        }

        // System alert actions and descriptions
        public struct Alert {
            public static let RemoveCardTitle = MZLocalizedString(
                key: "CreditCard.SnackBar.RemoveCardTitle.v122",
                tableName: "Alert",
                value: "Remove Card?",
                comment: "Title label for the dialog box that gets presented as a confirmation to ask user if they would like to remove the saved credit card")

            public static let RemoveCardSublabel = MZLocalizedString(
                key: "CreditCard.SnackBar.RemoveCardSublabel.v112",
                tableName: "Alert",
                value: "This will remove the card from all of your synced devices.",
                comment: "Sub label for the dialog box that gets presented as a confirmation to ask user if they would like to remove the saved credit card from local as well as all their synced devices")

            public static let CancelRemoveCardButton = MZLocalizedString(
                key: "CreditCard.SnackBar.CancelRemoveCardButton.v112",
                tableName: "Alert",
                value: "Cancel",
                comment: "Button text to dismiss the dialog box that gets presented as a confirmation to remove card and cancel the operation.")

            public static let RemovedCardLabel = MZLocalizedString(
                key: "CreditCard.SnackBar.RemovedCardButton.v112",
                tableName: "Alert",
                value: "Remove",
                comment: "Button text to dismiss the dialog box that gets presented as a confirmation to remove card and perform the operation of removing the credit card.")
        }
    }
}

// MARK: - Firefox Homepage
extension String {
    /// Identifiers of all new strings should begin with `FirefoxHome.`
    public struct FirefoxHomepage {
        public struct Common {
            public static let PagesCount = MZLocalizedString(
                key: "FirefoxHomepage.Common.PagesCount.v112",
                tableName: nil,
                value: "Pages: %d",
                comment: "Label showing how many pages there is in a search group. %d represents a number")
        }

        public struct CustomizeHomepage {
            public static let ButtonTitle = MZLocalizedString(
                key: "FirefoxHome.CustomizeHomeButton.Title",
                tableName: nil,
                value: "Customize Homepage",
                comment: "A button at bottom of the Firefox homepage that, when clicked, takes users straight to the settings options, where they can customize the Firefox Home page")
        }

        public struct HomeTabBanner {
            public struct EvergreenMessage {
                public static let HomeTabBannerTitle = MZLocalizedString(
                    key: "DefaultBrowserCard.Title",
                    tableName: "Default Browser",
                    value: "Switch Your Default Browser",
                    comment: "Title for small home tab banner that allows the user to switch their default browser to Firefox.")
                public static let HomeTabBannerDescription = MZLocalizedString(
                    key: "DefaultBrowserCard.Description",
                    tableName: "Default Browser",
                    value: "Set links from websites, emails, and Messages to open automatically in Firefox.",
                    comment: "Description for small home tab banner that allows the user to switch their default browser to Firefox.")
                public static let HomeTabBannerButton = MZLocalizedString(
                    key: "DefaultBrowserCard.Button.v2",
                    tableName: "Default Browser",
                    value: "Learn How",
                    comment: "Button string to learn how to set your default browser.")
                public static let HomeTabBannerCloseAccessibility = MZLocalizedString(
                    key: "DefaultBrowserCloseButtonAccessibility.v102",
                    tableName: nil,
                    value: "Close",
                    comment: "Accessibility label for action denoting closing default browser home tab banner.")
                public static let PeaceOfMindTitle = MZLocalizedString(
                    key: "DefaultBrowserCard.PeaceOfMind.Title.v108",
                    tableName: "Default Browser",
                    value: "Firefox Has Privacy Covered",
                    comment: "Title for small home tab banner that allows the user to switch their default browser to Firefox.")
                public static let PeaceOfMindDescription = MZLocalizedString(
                    key: "DefaultBrowserCard.PeaceOfMind.Description.v108",
                    tableName: "Default Browser",
                    value: "Firefox blocks 3,000+ trackers per user each month on average. Make us your default browser for privacy peace of mind.",
                    comment: "Description for small home tab banner that allows the user to switch their default browser to Firefox.")
                public static let BetterInternetTitle = MZLocalizedString(
                    key: "DefaultBrowserCard.BetterInternet.Title.v108",
                    tableName: "Default Browser",
                    value: "Default to a Better Internet",
                    comment: "Title for small home tab banner that allows the user to switch their default browser to Firefox.")
                public static let BetterInternetDescription = MZLocalizedString(
                    key: "DefaultBrowserCard.BetterInternet.Description.v108",
                    tableName: "Default Browser",
                    value: "Making Firefox your default browser is a vote for an open, accessible internet.",
                    comment: "Description for small home tab banner that allows the user to switch their default browser to Firefox.")
                public static let NextLevelTitle = MZLocalizedString(
                    key: "DefaultBrowserCard.NextLevel.Title.v108",
                    tableName: "Default Browser",
                    value: "Elevate Everyday Browsing",
                    comment: "Title for small home tab banner that allows the user to switch their default browser to Firefox.")
                public static let NextLevelDescription = MZLocalizedString(
                    key: "DefaultBrowserCard.NextLevel.Description.v108",
                    tableName: "Default Browser",
                    value: "Choose Firefox as your default browser to make speed, safety, and privacy automatic.",
                    comment: "Description for small home tab banner that allows the user to switch their default browser to Firefox.")
            }
        }

        public struct JumpBackIn {
            public static let GroupSiteCount = MZLocalizedString(
                key: "ActivityStream.JumpBackIn.TabGroup.SiteCount",
                tableName: nil,
                value: "Tabs: %d",
                comment: "On the Firefox homepage in the Jump Back In section, if a Tab group item - a collection of grouped tabs from a related search - exists underneath the search term for the tab group, there will be a subtitle with a number for how many tabs are in that group. %d is the number of tabs. It will read 'Tabs: 5' or similar.")
            public static let SyncedTabTitle = MZLocalizedString(
                key: "FirefoxHomepage.JumpBackIn.TabPickup.v104",
                tableName: nil,
                value: "Tab pickup",
                comment: "If a user is signed in, and a sync has been performed to collect their recent tabs from other signed in devices, their most recent tab from another device can now appear in the Jump Back In section. This label specifically points out which cell inside the Jump Back In section shows that synced tab.")
            public static let SyncedTabShowAllButtonTitle = MZLocalizedString(
                key: "FirefoxHomepage.JumpBackIn.TabPickup.ShowAll.ButtonTitle.v104",
                tableName: nil,
                value: "See all synced tabs",
                comment: "Button title shown for tab pickup on the Firefox homepage in the Jump Back In section.")
            public static let SyncedTabOpenTabA11y = MZLocalizedString(
                key: "FirefoxHomepage.JumpBackIn.TabPickup.OpenTab.A11y.v106",
                tableName: nil,
                value: "Open synced tab",
                comment: "Accessibility action title to open the synced tab for tab pickup on the Firefox homepage in the Jump Back In section.")
        }

        public struct Pocket {
            public static let SectionTitle = MZLocalizedString(
                key: "FirefoxHome.Pocket.SectionTitle",
                tableName: nil,
                value: "Thought-Provoking Stories",
                comment: "This is the title of the Pocket section on Firefox Homepage.")
            public static let DiscoverMore = MZLocalizedString(
                key: "FirefoxHome.Pocket.DiscoverMore",
                tableName: nil,
                value: "Discover more",
                comment: "At the end of the Pocket section on the Firefox Homepage, this button appears and indicates tapping it will navigate the user to more Pocket Stories.")
            public static let NumberOfMinutes = MZLocalizedString(
                key: "FirefoxHome.Pocket.Minutes.v99",
                tableName: nil,
                value: "%d min",
                comment: "On each Pocket Stories on the Firefox Homepage, this label appears and indicates the number of minutes to read an article. Minutes should be abbreviated due to space constraints. %d represents the number of minutes")
            public static let Sponsored = MZLocalizedString(
                key: "FirefoxHomepage.Pocket.Sponsored.v103",
                tableName: nil,
                value: "Sponsored",
                comment: "This string will show under the description on pocket story, indicating that the story is sponsored.")
            public struct Footer {
                public static let Title = MZLocalizedString(
                    key: "FirefoxHomepage.Pocket.Footer.Title.v116",
                    tableName: "Footer",
                    value: "Powered by %1$@. Part of the %2$@ family.",
                    comment: "This is the title of the Pocket footer on Firefox Homepage. %1$@ is Pocket, %2$@ is the app name (e.g. Firefox).")
                public static let LearnMore = MZLocalizedString(
                    key: "FirefoxHomepage.Pocket.Footer.LearnMore.v115",
                    tableName: "Footer",
                    value: "Learn more",
                    comment: "This is the learn more text of the Pocket footer on Firefox Homepage.")
            }
        }

        public struct RecentlySaved { }

        public struct HistoryHighlights {
            public static let Title = MZLocalizedString(
                key: "ActivityStream.RecentHistory.Title",
                tableName: nil,
                value: "Recently Visited",
                comment: "Section title label for recently visited websites")
            public static let Remove = MZLocalizedString(
                key: "FirefoxHome.RecentHistory.Remove",
                tableName: nil,
                value: "Remove",
                comment: "When a user taps and holds on an item from the Recently Visited section, this label will appear indicating the option to remove that item.")
        }

        public struct Shortcuts {
            public static let Sponsored = MZLocalizedString(
                key: "FirefoxHomepage.Shortcuts.Sponsored.v100",
                tableName: nil,
                value: "Sponsored",
                comment: "This string will show under a shortcuts tile on the firefox home page, indicating that the tile is a sponsored tile. Space is limited, please keep as short as possible.")

            public static let PinnedAccessibilityLabel = MZLocalizedString(
                key: "FirefoxHomepage.Shortcuts.Pinned.AccessibilityLabel.v139",
                tableName: "FirefoxHomepage",
                value: "Pinned: %@",
                comment: "Accessibility label for shortcuts tile on the Firefox home page, indicating that the tile is a pinned tile. %@ is the title of the website."
            )
        }

        public struct YourLibrary { }

        public struct ContextualMenu {
            public static let Settings = MZLocalizedString(
                key: "FirefoxHomepage.ContextualMenu.Settings.v101",
                tableName: nil,
                value: "Settings",
                comment: "The title for the Settings context menu action for sponsored tiles in the Firefox home page shortcuts section. Clicking this brings the users to the Shortcuts Settings.")
            public static let SponsoredContent = MZLocalizedString(
                key: "FirefoxHomepage.ContextualMenu.SponsoredContent.v101",
                tableName: nil,
                value: "Our Sponsors & Your Privacy",
                comment: "The title for the Sponsored Content context menu action for sponsored tiles in the Firefox home page shortcuts section. Clicking this brings the users to a support page where users can learn more about Sponsored content and how it works.")
        }

        public struct FeltPrivacyUI {
            public static let Title = MZLocalizedString(
                key: "FirefoxHomepage.FeltPrivacyUI.Title.v122",
                tableName: "FirefoxHomepage",
                value: "Leave no traces on this device",
                comment: "The title for the card that educates users about how private mode works. The card shows up on the homepage when in the new privacy mode.")

            public static let Body = MZLocalizedString(
                key: "FirefoxHomepage.FeltPrivacyUI.Body.v122",
                tableName: "FirefoxHomepage",
                value: "%@ deletes your cookies, history, and site data when you close all your private tabs.",
                comment: "The body of the message for the card that educates users about how private mode works. The card shows up on the homepage when in the new privacy mode. %@ is the app name (e.g. Firefox).")

            public static let Link = MZLocalizedString(
                key: "FirefoxHomepage.FeltPrivacyUI.Link.v122",
                tableName: "FirefoxHomepage",
                value: "Who might be able to see my activity?",
                comment: "The link for the card that educates users about how private mode works. The link redirects to an external site for more information. The card shows up on the homepage when in the new privacy mode.")
        }

        public struct FeltDeletion {
            public static let ToastTitle = MZLocalizedString(
                key: "FirefoxHomepage.FeltDeletion.Link.v122",
                tableName: "FirefoxHomepage",
                value: "Private Browsing Data Erased",
                comment: "When the user ends their private session, they are returned to the private mode homepage, and a toastbar popups confirming that their data has been erased. This is the label for that toast.")
        }
    }
}

// MARK: - Keyboard shortcuts/"hotkeys"
extension String {
    /// Identifiers of all new strings should begin with `Keyboard.Shortcuts.`
    public struct KeyboardShortcuts {
        public static let ActualSize = MZLocalizedString(
            key: "Keyboard.Shortcuts.ActualSize",
            tableName: nil,
            value: "Actual Size",
            comment: "A label indicating the keyboard shortcut of resetting a web page's view to the standard viewing size. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let AddBookmark = MZLocalizedString(
            key: "Keyboard.Shortcuts.AddBookmark",
            tableName: nil,
            value: "Add Bookmark",
            comment: "A label indicating the keyboard shortcut of adding the currently viewing web page as a bookmark. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let Back = MZLocalizedString(
            key: "Hotkeys.Back.DiscoveryTitle",
            tableName: nil,
            value: "Back",
            comment: "A label indicating the keyboard shortcut to navigate backwards, through session history, inside the current tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ClearRecentHistory = MZLocalizedString(
            key: "Keyboard.Shortcuts.ClearRecentHistory",
            tableName: nil,
            value: "Clear Recent History",
            comment: "A label indicating the keyboard shortcut of clearing recent history. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let CloseAllTabsInTabTray = MZLocalizedString(
            key: "TabTray.CloseAllTabs.KeyCodeTitle",
            tableName: nil,
            value: "Close All Tabs",
            comment: "A label indicating the keyboard shortcut of closing all tabs from the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let CloseCurrentTab = MZLocalizedString(
            key: "Hotkeys.CloseTab.DiscoveryTitle",
            tableName: nil,
            value: "Close Tab",
            comment: "A label indicating the keyboard shortcut of closing the current tab a user is in. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let Find = MZLocalizedString(
            key: "Hotkeys.Find.DiscoveryTitle",
            tableName: nil,
            value: "Find",
            comment: "A label indicating the keyboard shortcut of finding text a user desires within a page. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let FindAgain = MZLocalizedString(
            key: "Keyboard.Shortcuts.FindAgain",
            tableName: nil,
            value: "Find Again",
            comment: "A label indicating the keyboard shortcut of finding text a user desires within a page again. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let Forward = MZLocalizedString(
            key: "Hotkeys.Forward.DiscoveryTitle",
            tableName: nil,
            value: "Forward",
            comment: "A label indicating the keyboard shortcut of switching to a subsequent tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let NewPrivateTab = MZLocalizedString(
            key: "Hotkeys.NewPrivateTab.DiscoveryTitle",
            tableName: nil,
            value: "New Private Tab",
            comment: "A label indicating the keyboard shortcut of creating a new private tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let NewTab = MZLocalizedString(
            key: "Hotkeys.NewTab.DiscoveryTitle",
            tableName: nil,
            value: "New Tab",
            comment: "A label indicating the keyboard shortcut of creating a new tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let NormalBrowsingMode = MZLocalizedString(
            key: "Hotkeys.NormalMode.DiscoveryTitle",
            tableName: nil,
            value: "Normal Browsing Mode",
            comment: "A label indicating the keyboard shortcut of switching from Private Browsing to Normal Browsing Mode. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let OpenNewTabInTabTray = MZLocalizedString(
            key: "TabTray.OpenNewTab.KeyCodeTitle",
            tableName: nil,
            value: "Open New Tab",
            comment: "A label indicating the keyboard shortcut of opening a new tab in the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let PrivateBrowsingMode = MZLocalizedString(
            key: "Hotkeys.PrivateMode.DiscoveryTitle",
            tableName: nil,
            value: "Private Browsing Mode",
            comment: "A label indicating the keyboard shortcut of switching from Normal Browsing mode to Private Browsing Mode. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ReloadPage = MZLocalizedString(
            key: "Hotkeys.Reload.DiscoveryTitle",
            tableName: nil,
            value: "Reload Page",
            comment: "A label indicating the keyboard shortcut of reloading the current page. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ReloadWithoutCache = MZLocalizedString(
            key: "Keyboard.Shortcuts.RefreshWithoutCache.v108",
            tableName: nil,
            value: "Reload Ignoring Cache",
            comment: "A label indicating the keyboard shortcut to reload a tab without it's cache. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad.")
        public static let SelectLocationBar = MZLocalizedString(
            key: "Hotkeys.SelectLocationBar.DiscoveryTitle",
            tableName: nil,
            value: "Select Location Bar",
            comment: "A label indicating the keyboard shortcut of directly accessing the URL, location, bar. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let Settings = MZLocalizedString(
            key: "Keyboard.Shortcuts.Settings",
            tableName: nil,
            value: "Settings",
            comment: "A label indicating the keyboard shortcut of opening the application's settings menu. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ShowBookmarks = MZLocalizedString(
            key: "Keyboard.Shortcuts.ShowBookmarks",
            tableName: nil,
            value: "Show Bookmarks",
            comment: "A label indicating the keyboard shortcut of showing all bookmarks. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ShowDownloads = MZLocalizedString(
            key: "Keyboard.Shortcuts.ShowDownloads",
            tableName: nil,
            value: "Show Downloads",
            comment: "A label indcating the keyboard shortcut of showing all downloads. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ShowFirstTab = MZLocalizedString(
            key: "Keyboard.Shortcuts.ShowFirstTab",
            tableName: nil,
            value: "Show First Tab",
            comment: "A label indicating the keyboard shortcut to switch from the current tab to the first tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ShowHistory = MZLocalizedString(
            key: "Keyboard.Shortcuts.ShowHistory",
            tableName: nil,
            value: "Show History",
            comment: "A label indicating the keyboard shortcut of showing all history. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ShowLastTab = MZLocalizedString(
            key: "Keyboard.Shortcuts.ShowLastTab",
            tableName: nil,
            value: "Show Last Tab",
            comment: "A label indicating the keyboard shortcut switch from your current tab to the last tab. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ShowNextTab = MZLocalizedString(
            key: "Hotkeys.ShowNextTab.DiscoveryTitle",
            tableName: nil,
            value: "Show Next Tab",
            comment: "A label indicating the keyboard shortcut of switching to a subsequent tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ShowPreviousTab = MZLocalizedString(
            key: "Hotkeys.ShowPreviousTab.DiscoveryTitle",
            tableName: nil,
            value: "Show Previous Tab",
            comment: "A label indicating the keyboard shortcut of switching to a tab immediately preceding to the currently selected tab. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ShowTabTray = MZLocalizedString(
            key: "Tab.ShowTabTray.KeyCodeTitle",
            tableName: nil,
            value: "Show All Tabs",
            comment: "A label indicating the keyboard shortcut of showing the tab tray. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ZoomIn = MZLocalizedString(
            key: "Keyboard.Shortcuts.ZoomIn",
            tableName: nil,
            value: "Zoom In",
            comment: "A label indicating the keyboard shortcut of enlarging the view of the current web page. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        public static let ZoomOut = MZLocalizedString(
            key: "Keyboard.Shortcuts.ZoomOut",
            tableName: nil,
            value: "Zoom Out",
            comment: "A label indicating the keyboard shortcut of shrinking the view of the current web page. This label is displayed in the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")

        public struct Sections {
            public static let Bookmarks = MZLocalizedString(
                key: "Keyboard.Shortcuts.Section.Bookmark",
                tableName: nil,
                value: "Bookmarks",
                comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with Bookmarks. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
            public static let History = MZLocalizedString(
                key: "Keyboard.Shortcuts.Section.History",
                tableName: nil,
                value: "History",
                comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with History. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
            public static let Tools = MZLocalizedString(
                key: "Keyboard.Shortcuts.Section.Tools",
                tableName: nil,
                value: "Tools",
                comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can do with locally saved items. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
            public static let Window = MZLocalizedString(
                key: "Keyboard.Shortcuts.Section.Window",
                tableName: nil,
                value: "Window",
                comment: "A label indicating a grouping of related keyboard shortcuts describing actions a user can take when navigating between their availale set of tabs. This label is displayed inside the Discoverability overlay when a user presses the Command key. The Discoverability overlay and shortcut become available only when a user has connected a hardware keyboard to an iPad. See https://drive.google.com/file/d/1gH3tbvDceg7yG5N67NIHS-AXgDgCzBHN/view?usp=sharing for more details.")
        }
    }
}

// MARK: - Library Panel
extension String {
    /// Identifiers of all new strings should begin with `LibraryPanel.{PanelName}.`
    public struct LibraryPanel {
        public struct Sections {
            public static let LastHour = MZLocalizedString(
                key: "LibraryPanel.Sections.LastHour.v134",
                tableName: "LibraryPanel",
                value: "Last Hour",
                comment: "This label is meant to signify the section containing a group of items from the past hour. This is primarily used in the history library panel when grouping sites that have been visited in the last hour.")
            public static let LastTwentyFourHours = MZLocalizedString(
                key: "LibraryPanel.Sections.LastTwentyFourHours.v138",
                tableName: "LibraryPanel",
                value: "Last 24 Hours",
                comment: "Section title that, when expanded, shows all web browsing history entries for the last 24 hours beneath it (not including entries from the less inclusive sections)")
            public static let LastSevenDays = MZLocalizedString(
                key: "LibraryPanel.Sections.LastSevenDays.v138",
                tableName: "LibraryPanel",
                value: "Last 7 Days",
                comment: "Section title that, when expanded, shows all web browsing history entries for the last 7 days beneath it (not including entries from the less inclusve sections)")
            public static let LastFourWeeks = MZLocalizedString(
                key: "LibraryPanel.Sections.LastFourWeeks.v138",
                tableName: "LibraryPanel",
                value: "Last 4 Weeks",
                comment: "Section title that, when expanded, shows all web browsing history entries for the last 4 weeks beneath it (not including entries from the less inclusive sections)")
            public static let Older = MZLocalizedString(
                key: "LibraryPanel.Section.Older",
                tableName: "LibraryPanel",
                value: "Older",
                comment: "This label is meant to signify the section containing a group of items that are older than thirty days.")
        }

        public struct Bookmarks { }

        public struct History {
            public static let HistoryPanelClearHistoryButtonTitle = MZLocalizedString(
                key: "HistoryPanel.ClearHistoryButtonTitle",
                tableName: nil,
                value: "Clear Recent History…",
                comment: "Title for button in the history panel to clear recent history")
            public static let SearchHistoryPlaceholder = MZLocalizedString(
                key: "LibraryPanel.History.SearchHistoryPlaceholder.v99",
                tableName: nil,
                value: "Enter search terms",
                comment: "In the history panel, users will be able to search terms in their browsing history. This placeholder text inside the search component will indicate that a user can search through their browsing history.")
            public static let NoHistoryResult = MZLocalizedString(
                key: "LibraryPanel.History.NoHistoryFound.v99",
                tableName: nil,
                value: "No history found",
                comment: "In the history panel, users will be able to search terms in their browsing history. This label is shown when there is no results after querying the search terms in the user's history.")
            public static let RecentlyClosedTabs = MZLocalizedString(
                key: "LibraryPanel.History.RecentlyClosedTabs.v99",
                tableName: nil,
                value: "Recently Closed Tabs",
                comment: "In the history panel, this is the title on the button that navigates the user to a screen showing their recently closed tabs.")
            public static let RecentlyClosedTabsButtonTitle = MZLocalizedString(
                key: "HistoryPanel.RecentlyClosedTabsButton.Title",
                tableName: nil,
                value: "Recently Closed",
                comment: "Title for the Recently Closed button in the History Panel")
            public static let SyncedHistory = MZLocalizedString(
                key: "LibraryPanel.History.SyncedHistory.v100",
                tableName: nil,
                value: "Synced History",
                comment: "Within the History Panel, users can see the option of viewing their history from synced tabs.")
            public static let ClearGroupedTabsTitle = MZLocalizedString(
                key: "LibraryPanel.History.ClearGroupedTabsTitle.v100",
                tableName: nil,
                value: "Delete all sites in %@?",
                comment: "Within the History Panel, users can delete search group sites history. %@ represents the search group name.")
            public static let ClearGroupedTabsCancel = MZLocalizedString(
                key: "LibraryPanel.History.ClearGroupedTabsCancel.v100",
                tableName: nil,
                value: "Cancel",
                comment: "Within the History Panel, users can delete search group sites history. They can cancel this action by pressing a cancel button.")
            public static let ClearGroupedTabsDelete = MZLocalizedString(
                key: "LibraryPanel.History.ClearGroupedTabsDelete.v100",
                tableName: nil,
                value: "Delete",
                comment: "Within the History Panel, users can delete search group sites history. They need to confirm the action by pressing the delete button.")
            public static let Delete = MZLocalizedString(
                key: "LibraryPanel.History.DeleteGroupedItem.v104",
                tableName: nil,
                value: "Delete",
                comment: "Within the history panel, a user can navigate into a screen with only grouped history items. Within that screen, a user can now swipe to delete a single item in the list. This label informs the user of a deletion action on the item.")

            public struct ClearHistorySheet {
                public static let Title = MZLocalizedString(
                    key: "LibraryPanel.History.Title.v138",
                    tableName: "HistoryPanel",
                    value: "Deletes history (including synced history from other devices), cookies, and other browsing data.",
                    comment: "Title of the “Clear browsing history“ action sheet")
                public static let LastHourOption = MZLocalizedString(
                    key: "LibraryPanel.History.LastHourOption.v138",
                    tableName: "HistoryPanel",
                    value: "Last Hour",
                    comment: "Destructive action button on the “Clear browsing history“ action sheet used to clear browsing history for the last hour")
                public static let LastTwentyFourHoursOption = MZLocalizedString(
                    key: "LibraryPanel.History.LastTwentyFourHoursOption.v138",
                    tableName: "HistoryPanel",
                    value: "Last 24 Hours",
                    comment: "Destructive action button on the “Clear browsing history“ action sheet used to clear browsing history for the last 24 hours")
                public static let LastSevenDaysOption = MZLocalizedString(
                    key: "LibraryPanel.History.LastSevenDaysOption.v138",
                    tableName: "HistoryPanel",
                    value: "Last 7 Days",
                    comment: "Destructive action button on the “Clear browsing history“ action sheet used to clear browsing history for the last 7 days")
                public static let LastFourWeeksOption = MZLocalizedString(
                    key: "LibraryPanel.History.LastFourWeeksOption.v138",
                    tableName: "HistoryPanel",
                    value: "Last 4 Weeks",
                    comment: "Destructive action button on the “Clear browsing history“ action sheet used to clear browsing history for the last 4 weeks")
                public static let AllTimeOption = MZLocalizedString(
                    key: "LibraryPanel.History.AllTimeOption.v138",
                    tableName: "HistoryPanel",
                    value: "All Time",
                    comment: "Destructive action button on the “Clear browsing history“ action sheet used to clear all browsing history")
            }
        }

        public struct ReadingList { }

        public struct Downloads { }
    }
}

// MARK: - Micro survey
extension String {
    public struct Microsurvey {
        public struct Prompt {
            public static let LogoImageA11yLabel = MZLocalizedString(
                key: "Microsurvey.Prompt.LogoImage.AccessibilityLabel.v129",
                tableName: "Microsurvey",
                value: "%@ Logo",
                comment: "On top of the bottom toolbar, there can be a microsurvey prompt, this is the logo image that appears on the prompt to inform the prompt is coming from the app specifically. %@ is the app name (e.g. Firefox).")
            public static let TitleLabel = MZLocalizedString(
                key: "Microsurvey.Prompt.TitleLabel.v127",
                tableName: "Microsurvey",
                value: "Help us make %@ better. It only takes a minute.",
                comment: "On top of the bottom toolbar, there can be a microsurvey prompt, this is the title for the text that appears on the prompt to inform the user that this is a prompt to take a survey. %@ is the app name (e.g. Firefox).")
            public static let TakeSurveyButton = MZLocalizedString(
                key: "Microsurvey.Prompt.Button.v127",
                tableName: "Microsurvey",
                value: "Continue",
                comment: "On top of the bottom toolbar, there can be a microsurvey prompt, this is the title for the button that appears on the prompt that allows the user to tap on and navigates them to the microsurvey to respond to.")
            public static let CloseButtonAccessibilityLabel = MZLocalizedString(
                key: "Microsurvey.Prompt.Close.Button.AccessibilityLabel.v127",
                tableName: "Microsurvey",
                value: "Close",
                comment: "On top of the bottom toolbar, there can be a microsurvey prompt, this is the accessibility label for the close button that appears on the prompt that allows the user to dismiss the microsurvey prompt.")
        }

        public struct Survey {
            public static let SurveyA11yLabel = MZLocalizedString(
                key: "Microsurvey.Survey.Sheet.AccessibilityLabel.v130",
                tableName: "Microsurvey",
                value: "Survey",
                comment: "After engaging with the microsurvey prompt, the microsurvey pops up as a bottom sheet for the user to answer, this is the accessibility label used to announce that the sheet has appeared.")
            public static let LogoImageA11yLabel = MZLocalizedString(
                key: "Microsurvey.Survey.LogoImage.AccessibilityLabel.v129",
                tableName: "Microsurvey",
                value: "%@ Logo",
                comment: "After engaging with the microsurvey prompt, the microsurvey pops up as a bottom sheet for the user to answer, this is the logo image that appears on the bottom sheet that informs the user that it is coming from the app specifically. %@ is the app name (e.g. Firefox).")
            public static let HeaderLabel = MZLocalizedString(
                key: "Microsurvey.Survey.HeaderLabel.v129",
                tableName: "Microsurvey",
                value: "Please complete survey",
                comment: "After engaging with the microsurvey prompt, the microsurvey pops up as a bottom sheet for the user to answer, this is the title for the header on the screen.")
            public static let CloseButtonAccessibilityLabel = MZLocalizedString(
                key: "Microsurvey.Survey.Close.Button.AccessibilityLabel.v127",
                tableName: "Microsurvey",
                value: "Close",
                comment: "After engaging with the microsurvey prompt, the microsurvey pops up as a bottom sheet for the user to answer, this is the accessibility label for close button that dismisses the sheet.")
            public static let UnselectedRadioButtonAccessibilityLabel = MZLocalizedString(
                key: "Microsurvey.Survey.RadioButton.Unselected.AccessibilityLabel.v129",
                tableName: "Microsurvey",
                value: "Unselected",
                comment: "After engaging with the microsurvey prompt, the microsurvey pops up as a bottom sheet for the user to answer, this is the accessibility label that states whether the survey option was not selected.")
            public static let OptionsOrderAccessibilityLabel = MZLocalizedString(
                key: "Microsurvey.Survey.OptionsOrder.AccessibilityLabel.v129",
                tableName: "Microsurvey",
                value: "%1$@ out of %2$@",
                comment: "After engaging with the microsurvey prompt, the microsurvey pops up as a bottom sheet for the user to answer, this is the accessibility label that states the order of the current option in the list of options. %1$@ is the number the option is in the list, %2$@ is the total number of options. An example of output is “1 out of 6”.")
            public static let PrivacyPolicyLinkButtonTitle = MZLocalizedString(
                key: "Microsurvey.Survey.PrivacyPolicyLink.v127",
                tableName: "Microsurvey",
                value: "Privacy notice",
                comment: "After engaging with the microsurvey prompt, the microsurvey pops up as a bottom sheet for the user to answer, this the title of a link on the survey and allows the user to navigate to our privacy policy details.")
            public static let SubmitSurveyButton = MZLocalizedString(
                key: "Microsurvey.Survey.Button.v127",
                tableName: "Microsurvey",
                value: "Submit",
                comment: "After engaging with the microsurvey prompt, the microsurvey pops up as a bottom sheet for the user to answer, this the title of button on the survey that a user can tap on to submit their responses.")

            public struct Options {
                public static let LikertScaleOption1 = MZLocalizedString(
                    key: "Microsurvey.Survey.Options.VerySatisfied.v132",
                    tableName: "Microsurvey",
                    value: "Very satisfied",
                    comment: "On the microsurvey, this is the title for one of the options that the user can select to answer the survey.")
                public static let LikertScaleOption2 = MZLocalizedString(
                    key: "Microsurvey.Survey.Options.Satisfied.v132",
                    tableName: "Microsurvey",
                    value: "Satisfied",
                    comment: "On the microsurvey, this is the title for one of the options that the user can select to answer the survey.")
                public static let LikertScaleOption3 = MZLocalizedString(
                    key: "Microsurvey.Survey.Options.Neutral.v132",
                    tableName: "Microsurvey",
                    value: "Neutral",
                    comment: "On the microsurvey, this is the title for one of the options that the user can select to answer the survey.")
                public static let LikertScaleOption4 = MZLocalizedString(
                    key: "Microsurvey.Survey.Options.Dissatisfied.v132",
                    tableName: "Microsurvey",
                    value: "Dissatisfied",
                    comment: "On the microsurvey, this is the title for one of the options that the user can select to answer the survey.")
                public static let LikertScaleOption5 = MZLocalizedString(
                    key: "Microsurvey.Survey.Options.VeryDissatisfied.v132",
                    tableName: "Microsurvey",
                    value: "Very dissatisfied",
                    comment: "On the microsurvey, this is the title for one of the options that the user can select to answer the survey.")
                public static let LikertScaleOption6 = MZLocalizedString(
                    key: "Microsurvey.Survey.Options.NotApplicable.v132",
                    tableName: "Microsurvey",
                    value: "I don’t use it",
                    comment: "On the microsurvey, this is the title for one of the options that the user can select to answer the survey. It indicates that the user has not use the feature that the survey is inquiring about.")
            }

            public struct ConfirmationPage {
                public static let HeaderLabel = MZLocalizedString(
                    key: "Microsurvey.Survey.ConfirmationPage.HeaderLabel.v127",
                    tableName: "Microsurvey",
                    value: "Survey complete",
                    comment: "On the microsurvey, which is a bottom sheet that pops up with a survey question and options, this is the title for the header on the microsurvey when the user has completed the survey.")
                public static let ConfirmationLabel = MZLocalizedString(
                    key: "Microsurvey.Survey.ConfirmationPage.ConfirmationLabel.v127",
                    tableName: "Microsurvey",
                    value: "Thanks for your feedback!",
                    comment: "On the microsurvey, which is a bottom sheet that pops up with a survey question and options, this is the text shown on the confirmation page when the user has completed the survey.")
            }
        }
    }
}

// MARK: - Native Error Page
extension String {
    public struct NativeErrorPage {
        public static let ButtonLabel = MZLocalizedString(
            key: "NativeErrorPage.ButtonLabel.v131",
            tableName: "NativeErrorPage",
            value: "Reload",
            comment: "On error page, this is the text on a button that will try to load the page again.")
        public struct NoInternetConnection {
            public static let TitleLabel = MZLocalizedString(
                key: "NativeErrorPage.NoInternetConnection.TitleLabel.v131",
                tableName: "NativeErrorPage",
                value: "Looks like there’s a problem with your internet connection.",
                comment: "On error page, this is the title for no internet connection")
            public static let Description = MZLocalizedString(
                key: "NativeErrorPage.NoInternetConnection.Description.v131",
                tableName: "NativeErrorPage",
                value: "Try connecting on a different device. Check your modem or router. Disconnect and reconnect to Wi-Fi.",
                comment: "On error page, this is the description for no internet connection.")
        }
        public struct GenericError {
            public static let TitleLabel = MZLocalizedString(
                key: "NativeErrorPage.GenericError.TitleLabel.v131",
                tableName: "NativeErrorPage",
                value: "Be careful. Something doesn’t look right.",
                comment: "On error page, this is the title for generic error.")
            public static let Description = MZLocalizedString(
                key: "NativeErrorPage.GenericError.Description.v134",
                tableName: "NativeErrorPage",
                value: "The owner of %@ hasn’t set it up properly and a secure connection can’t be created.",
                comment: "On error page, this is the description for a generic error. %@ is the site url.")
        }
    }
}

// MARK: - Onboarding screens
extension String {
    public struct Onboarding {
        public static let PrivacyPolicyLinkButtonTitle = MZLocalizedString(
            key: "Onboarding.Welcome.Link.Action.v114",
            tableName: "Onboarding",
            value: "Learn more in our privacy notice",
            comment: "String used to describe the title of link button is on the welcome onboarding page for current version in our Onboarding screens.")
        public static let LaterAction = MZLocalizedString(
            key: "Onboarding.LaterAction.v115",
            tableName: "Onboarding",
            value: "Skip",
            comment: "Describes an action on some of the Onboarding screen, including the wallpaper onboarding screen. This string will be on a button so user can skip that onboarding page.")

        public struct TermsOfService {
            public static let Title = MZLocalizedString(
                key: "Onboarding.TermsOfService.Title.v135",
                tableName: "Onboarding",
                value: "Welcome to %@",
                comment: "Title for the Terms of Service screen in the onboarding process. %@ is the app name (e.g. Firefox).")
            public static let Subtitle = MZLocalizedString(
                key: "Onboarding.TermsOfService.Subtitle.v136",
                tableName: "Onboarding",
                value: "Fast and secure web browsing",
                comment: "Subtitle for the Terms of Service screen in the onboarding process.")
            public static let AgreementButtonTitleV2 = MZLocalizedString(
                key: "Onboarding.TermsOfService.AgreementButtonTitle.v136",
                tableName: "Onboarding",
                value: "Agree and Continue",
                comment: "Title for the confirmation button for Terms of Service agreement, in the Terms of Service screen.")
            public static let TermsOfServiceAgreement = MZLocalizedString(
                key: "Onboarding.TermsOfService.TermsOfServiceAgreement.v135",
                tableName: "Onboarding",
                value: "By continuing, you agree to the %@",
                comment: "Agreement text for Terms of Service in the Terms of Service screen. %@ is the Terms of Service link button that redirect the user to the Terms of Service page.")
            public static let PrivacyNoticeAgreement = MZLocalizedString(
                key: "Onboarding.TermsOfService.PrivacyNoticeAgreement.v135",
                tableName: "Onboarding",
                value: "%@ cares about your privacy. Read more in our %@",
                comment: "Agreement text for Privacy Notice in the Terms of Service screen. %1$@ is the app name (e.g. Firefox), %2$@ is for the Privacy Notice link button that redirect the user to the Privacy Notice page.")
            public static let ManagePreferenceAgreement = MZLocalizedString(
                key: "Onboarding.TermsOfService.ManagePreferenceAgreement.v135",
                tableName: "Onboarding",
                value: "To help improve the browser, %1$@ sends diagnostic and interaction data to %2$@. %3$@",
                comment: "Agreement text for sending diagnostic and interaction data to Mozilla in the Terms of Service screen. %1$@ is the app name (e.g. Firefox), %2$@ is company name (e.g. Mozilla), %3$@ is a Manage link button which redirect the user to another screen in order to manage the data collection preferences.")
            public static let TermsOfUseLink = MZLocalizedString(
                key: "Onboarding.TermsOfUse.TermsOfUseLink.v136",
                tableName: "Onboarding",
                value: "%@ Terms of Use.",
                comment: "Title for the Terms of Use button link, in the Terms of Use screen for redirecting the user to the Terms of Use page. %@ is the app name (e.g. Firefox).")
            public static let PrivacyNoticeLink = MZLocalizedString(
                key: "Onboarding.TermsOfService.PrivacyNoticeLink.v135",
                tableName: "Onboarding",
                value: "Privacy Notice.",
                comment: "Title for the Privacy Notice button link, in the Terms of Service screen for redirecting the user to the Privacy Notice page.")
            public static let ManageLink = MZLocalizedString(
                key: "Onboarding.TermsOfService.ManageLink.v135",
                tableName: "Onboarding",
                value: "Manage",
                comment: "Title for the Manage button link, in the Terms of Service screen for redirecting the user to the Manage data collection preferences screen.")

            public struct PrivacyPreferences {
                public static let Title = MZLocalizedString(
                    key: "Onboarding.TermsOfService.PrivacyPreferences.Title.v135",
                    tableName: "Onboarding",
                    value: "Help us make %@ better",
                    comment: "Title for the Manage Privacy Preferences screen, where user can choose from the option to send data to Firefox or not. Data like crash reports or technical and interaction data. %@ is the app name (e.g. Firefox).")
                public static let SendCrashReportsTitle = MZLocalizedString(
                    key: "Onboarding.TermsOfService.PrivacyPreferences.SendCrashReportsTitle.v135",
                    tableName: "Onboarding",
                    value: "Automatically send crash reports",
                    comment: "Title for the send crash reports switch option in Manage Privacy Preferences screen, where user can choose from the option to send data to Firefox or not.")
                public static let SendCrashReportsDescription = MZLocalizedString(
                    key: "Onboarding.TermsOfService.PrivacyPreferences.SendCrashReportsDescription.v135",
                    tableName: "Onboarding",
                    value: "Crash reports allow us to diagnose and fix issues with the browser. %@",
                    comment: "Description for the send crash reports switch option in Manage Privacy Preferences screen, where user can choose from the option to send data to Firefox or not. %@ is for the Learn more button link, to open a link where user can find more information about this send crash reports option.")
                public static let SendTechnicalDataTitle = MZLocalizedString(
                    key: "Onboarding.TermsOfService.PrivacyPreferences.SendTechnicalDataTitle.v135",
                    tableName: "Onboarding",
                    value: "Send technical and interaction data to %@",
                    comment: "Title for the send technical and interaction data switch option in Manage Privacy Preferences screen, where user can choose from the option to send data to Firefox or not. %@ is the company name (e.g. Mozilla).")
                public static let SendTechnicalDataDescription = MZLocalizedString(
                    key: "Onboarding.TermsOfService.PrivacyPreferences.SendTechnicalDataDescription.v135",
                    tableName: "Onboarding",
                    value: "Data about your device, hardware configuration, and how you use %@ helps improve features, performance, and stability for everyone. %@",
                    comment: "Description for the technical and interaction data switch option in Manage Privacy Preferences screen, where user can choose from the option to send data to Firefox or not. %1$@ is the app name (e.g. Firefox), %2$@ is for the Learn more button link, to open a link where user can find more information about this send technical and interaction data option.")
                public static let LearnMore = MZLocalizedString(
                    key: "Onboarding.TermsOfService.PrivacyPreferences.LearnMore.v136",
                    tableName: "Onboarding",
                    value: "Learn more",
                    comment: "A text that indicate to the user, a link button is available to be clicked for reading more information about the option that is going to choose in Manage Privacy Preferences screen, where user can choose from the option to send data to Firefox or not.")
            }
        }

        public struct Intro {
            public static let DescriptionPart1 = MZLocalizedString(
                key: "Onboarding.IntroDescriptionPart1.v114",
                tableName: "Onboarding",
                value: "Indie. Non-profit. For good.",
                comment: "String used to describes what Firefox is on the first onboarding page in our Onboarding screens. Indie means small independant.")
            public static let DescriptionPart2 = MZLocalizedString(
                key: "Onboarding.IntroDescriptionPart2.v114",
                tableName: "Onboarding",
                value: "Committed to the promise of a better Internet for everyone.",
                comment: "String used to describes what Firefox is on the first onboarding page in our Onboarding screens.")
        }

        public struct Wallpaper {
            public static let Title = MZLocalizedString(
                key: "Onboarding.Wallpaper.Title.v114",
                tableName: "Onboarding",
                value: "Choose a %@ Wallpaper",
                comment: "Title for the wallpaper onboarding page in our Onboarding screens. This describes to the user that they can choose different wallpapers. %@ is the app name (e.g. Firefox).")
            public static let Action = MZLocalizedString(
                key: "Onboarding.Wallpaper.Action.v114",
                tableName: "Onboarding",
                value: "Set Wallpaper",
                comment: "Description for the wallpaper onboarding page in our Onboarding screens. This describes to the user that they can set a wallpaper.")
            public static let SelectorTitle = MZLocalizedString(
                key: "Onboarding.Wallpaper.SelectorTitle.v114",
                tableName: "Onboarding",
                value: "Try a splash of color",
                comment: "Title for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that they can choose different wallpapers.")
            public static let SelectorDescription = MZLocalizedString(
                key: "Onboarding.Wallpaper.Description.v114",
                tableName: "Onboarding",
                value: "Choose a wallpaper that speaks to you.",
                comment: "Description for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that they can choose different wallpapers.")
            public static let ClassicWallpaper = MZLocalizedString(
                key: "Onboarding.Wallpaper.Accessibility.Classic.v114",
                tableName: "Onboarding",
                value: "Classic Wallpaper",
                comment: "Accessibility label for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that which type of wallpaper they are seeing.")
            public static let LimitedEditionWallpaper = MZLocalizedString(
                key: "Onboarding.Wallpaper.Accessibility.LimitedEdition.v114",
                tableName: "Onboarding",
                value: "Limited Edition Wallpaper",
                comment: "Accessibility label for the wallpaper onboarding modal displayed on top of the homepage. This describes to the user that which type of wallpaper they are seeing.")
        }

        public struct Welcome {
            public static let CloseButtonAccessibilityLabel = MZLocalizedString(
                key: "Onboarding.Welcome.Close.AccessibilityLabel.v121",
                tableName: "Onboarding",
                value: "Close and exit %@ onboarding",
                comment: "Accessibility label for close button that dismisses the welcome onboarding screen. %@ is the app name (e.g. Firefox).")
            public static let Title = MZLocalizedString(
                key: "Onboarding.Welcome.Title.v114",
                tableName: "Onboarding",
                value: "Welcome to an independent internet",
                comment: "String used to describes the title of what Firefox is on the welcome onboarding page for current version in our Onboarding screens.")
            public static let Description = MZLocalizedString(
                key: "Onboarding.Welcome.Description.v120",
                tableName: "Onboarding",
                value: "Our non-profit backed browser helps stop companies from secretly following you around the web.",
                comment: "String used to describes the description of what Firefox is on the welcome onboarding page for current version in our Onboarding screens. %@ is the app name (e.g. Firefox).")
            public static let TitleTreatmentA = MZLocalizedString(
                key: "Onboarding.Welcome.Title.TreatementA.v120",
                tableName: "Onboarding",
                value: "We love keeping you safe",
                comment: "String used to describes the title of what Firefox is on the welcome onboarding page for current version in our Onboarding screens.")
            public static let DescriptionTreatementA = MZLocalizedString(
                key: "Onboarding.Welcome.Description.TreatementA.v120",
                tableName: "Onboarding",
                value: "Our non-profit backed browser helps stop companies from secretly following you around the web.",
                comment: "String used to describes the description of what Firefox is on the welcome onboarding page for current version in our Onboarding screens.")
            public static let GetStartedAction = MZLocalizedString(
                key: "Onboarding.Welcome.Action.v114",
                tableName: "Onboarding",
                value: "Get Started",
                comment: "Describes the action on the first onboarding page in our Onboarding screen. This string will be on a button so user can continue the onboarding.")
            public static let ActionTreatementA = MZLocalizedString(
                key: "Onboarding.Welcome.ActionTreatementA.v114",
                tableName: "Onboarding",
                value: "Set as Default Browser",
                comment: "Describes the action on the first onboarding page in our Onboarding screen. This indicates that the user will set their default browser to Firefox.")
            public static let Skip = MZLocalizedString(
                key: "Onboarding.Welcome.Skip.v114",
                tableName: "Onboarding",
                value: "Skip",
                comment: "Describes the action on the first onboarding page in our Onboarding screen. This string will be on a button so user can skip this onboarding card.")
        }

        public struct Sync {
            public static let Title = MZLocalizedString(
                key: "Onboarding.Sync.Title.v120",
                tableName: "Onboarding",
                value: "Stay encrypted when you hop between devices",
                comment: "String used to describes the title of what Firefox is on the Sync onboarding page for current version in our Onboarding screens.")
            public static let Description = MZLocalizedString(
                key: "Onboarding.Sync.Description.v123",
                tableName: "Onboarding",
                value: "%@ encrypts your passwords, bookmarks, and more when you’re synced.",
                comment: "String used to describes the description of what Firefox is on the Sync onboarding page for current version in our Onboarding screens. %@ is the app name (e.g. Firefox).")
            public static let SignInAction = MZLocalizedString(
                key: "Onboarding.Sync.SignIn.Action.v114",
                tableName: "Onboarding",
                value: "Sign In",
                comment: "String used to describes the option to skip the Sync sign in during onboarding for the current version in Firefox Onboarding screens.")
            public static let SkipAction = MZLocalizedString(
                key: "Onboarding.Sync.Skip.Action.v114",
                tableName: "Onboarding",
                value: "Skip",
                comment: "String used to describes the option to skip the Sync sign in during onboarding for the current version in Firefox Onboarding screens.")
        }

        public struct Notification {
            public static let Title = MZLocalizedString(
                key: "Onboarding.Notification.Title.v120",
                tableName: "Onboarding",
                value: "Notifications help you stay safer with %@",
                comment: "String used to describe the title of the notification onboarding page in our Onboarding screens. %@ is the app name (e.g. Firefox).")
            public static let Description = MZLocalizedString(
                key: "Onboarding.Notification.Description.v120",
                tableName: "Onboarding",
                value: "Securely send tabs between your devices and discover other privacy features in %@.",
                comment: "String used to describe the description of the notification onboarding page in our Onboarding screens. %@ is the app name (e.g. Firefox).")
            public static let ContinueAction = MZLocalizedString(
                key: "Onboarding.Notification.Continue.Action.v114",
                tableName: "Onboarding",
                value: "Continue",
                comment: "String used to describe the option to continue to ask for the notification permission in Firefox Onboarding screens.")
            public static let TurnOnNotificationsAction = MZLocalizedString(
                key: "Onboarding.Notification.TurnOnNotifications.Action.v114",
                tableName: "Onboarding",
                value: "Turn On Notifications",
                comment: "String used to describe the option to continue to ask for the notification permission in Firefox Onboarding screens.")
            public static let SkipAction = MZLocalizedString(
                key: "Onboarding.Notification.Skip.Action.v115",
                tableName: "Onboarding",
                value: "Skip",
                comment: "String used to describe the option to skip the notification permission in Firefox Onboarding screens.")
        }

        public struct DefaultBrowserPopup {
            public static let Title = MZLocalizedString(
                key: "DefaultBrowserPopup.Title.v114",
                tableName: "Onboarding",
                value: "Switch Your Default Browser",
                comment: "The title on the Default Browser Popup, which is a card with instructions telling the user how to set Firefox as their default browser.")
            public static let FirstInstruction = MZLocalizedString(
                key: "DefaultBrowserPopup.FirstLabel.v114",
                tableName: "Onboarding",
                value: "1. Go to *Settings*",
                comment: "The first label on the Default Browser Popup, which is a card with instructions telling the user how to set Firefox as their default browser. The *text inside asterisks* denotes part of the string to bold, please leave the text inside the '*' so that it is bolded correctly.")
            public static let SecondInstruction = MZLocalizedString(
                key: "DefaultBrowserPopup.SecondLabel.v114",
                tableName: "Onboarding",
                value: "2. Tap *Default Browser App*",
                comment: "The second label on the Default Browser Popup, which is a card with instructions telling the user how to set Firefox as their default browser. The *text inside asterisks* denotes part of the string to bold, please leave the text inside the '*' so that it is bolded correctly.")
            public static let ThirdInstruction = MZLocalizedString(
                key: "DefaultBrowserPopup.ThirdLabel.v114",
                tableName: "Onboarding",
                value: "3. Select *%@*",
                comment: "The third label on the Default Browser Popup, which is a card with instructions telling the user how to set Firefox as their default browser. %@ is the app name (e.g. Firefox). The *text inside asterisks* denotes part of the string to bold, please leave the text inside the '*' so that it is bolded correctly.")
            public static let DescriptionFooter = MZLocalizedString(
                key: "DefaultBrowserPopup.DescriptionFooter.v124",
                tableName: "Onboarding",
                value: "*Is %@ already your default?* Close this message and tap Skip.",
                comment: "The footer label on the Default Browser Popup, which is below all the instructions asking the users if their browser is the default browser. %@ is the app name (e.g. Firefox). If it is then close this message and tap skip. The *text inside asterisks* denotes part of the string to bold, please leave the text inside the '*' so that it is bolded correctly.")
            public static let ButtonTitle = MZLocalizedString(
                key: "DefaultBrowserPopup.ButtonTitle.v114",
                tableName: "Onboarding",
                value: "Go to Settings",
                comment: "The title of the button on the Default Browser Popup, which is a card with instructions telling the user how to set Firefox as their default browser.")
        }

        public struct Customization {
            public struct Intro {
                public static let Title = MZLocalizedString(
                    key: "Onboarding.Customization.Intro.Title.v123",
                    tableName: "Onboarding",
                    value: "%@ puts you in control",
                    comment: "String used to describe the title of the customization onboarding page in our Onboarding screens. %@ is the app name (e.g. Firefox).")
                public static let Description = MZLocalizedString(
                    key: "Onboarding.Customization.Intro.Description.v123",
                    tableName: "Onboarding",
                    value: "Set your theme and toolbar to match your unique browsing style.",
                    comment: "String used to describe the description label of the customization onboarding page in our Onboarding screens.")
                public static let ContinueAction = MZLocalizedString(
                    key: "Onboarding.Customization.Intro.Continue.Action.v123",
                    tableName: "Onboarding",
                    value: "Customize %@",
                    comment: "String used to describe the option to continue to the next onboarding card in Firefox Onboarding screens. %@ is the app name (e.g. Firefox).")
                public static let SkipAction = MZLocalizedString(
                    key: "Onboarding.Customization.Intro.Skip.Action.v123",
                    tableName: "Onboarding",
                    value: "Start Browsing",
                    comment: "String used to describe the option to skip the customization cards in Firefox Onboarding screens and start browsing.")
            }

            public struct Theme {
                public static let Title = MZLocalizedString(
                    key: "Onboarding.Customization.Theme.Title.v123",
                    tableName: "Onboarding",
                    value: "Pick a theme",
                    comment: "String used to describe the title of the theme customization onboarding page in our Onboarding screens.")
                public static let Description = MZLocalizedString(
                    key: "Onboarding.Customization.Theme.Description.v123",
                    tableName: "Onboarding",
                    value: "See the web in the best light.",
                    comment: "String used to describe the description label of the theme customization onboarding page in our Onboarding screens.")
                public static let SystemAction = MZLocalizedString(
                    key: "Onboarding.Customization.Theme.System.Action.v123",
                    tableName: "Onboarding",
                    value: "System Auto",
                    comment: "On the theme customization onboarding card, the string used to describe the option to set the theme to system theme from the available choices.")
                public static let LightAction = MZLocalizedString(
                    key: "Onboarding.Customization.Theme.Light.Action.v123",
                    tableName: "Onboarding",
                    value: "Light",
                    comment: "On the theme customization onboarding card, the string used to describe the option to set the theme to light theme from the available choices.")
                public static let DarkAction = MZLocalizedString(
                    key: "Onboarding.Customization.Theme.Dark.Action.v123",
                    tableName: "Onboarding",
                    value: "Dark",
                    comment: "On the theme customization onboarding card, the string used to describe the option to set the theme to dark theme from the available choices.")
                public static let ContinueAction = MZLocalizedString(
                    key: "Onboarding.Customization.Theme.Continue.Action.v123",
                    tableName: "Onboarding",
                    value: "Save and Continue",
                    comment: "String used to describe the option to save the user setting and continue to the next onboarding in Firefox Onboarding screens.")
                public static let SkipAction = MZLocalizedString(
                    key: "Onboarding.Customization.Theme.Skip.Action.v123",
                    tableName: "Onboarding",
                    value: "Skip",
                    comment: "String used to describe the option to skip the theme customization in Firefox Onboarding screens.")
            }

            public struct Toolbar {
                public static let Title = MZLocalizedString(
                    key: "Onboarding.Customization.Toolbar.Title.v123",
                    tableName: "Onboarding",
                    value: "Pick a toolbar placement",
                    comment: "String used to describe the title of the toolbar customization onboarding page in our Onboarding screens.")
                public static let Description = MZLocalizedString(
                    key: "Onboarding.Customization.Toolbar.Description.v123",
                    tableName: "Onboarding",
                    value: "Keep searches within reach.",
                    comment: "String used to describe the description label of the toolbar customization onboarding page in our Onboarding screens.")
                public static let TopAction = MZLocalizedString(
                    key: "Onboarding.Customization.Toolbar.Top.Action.v123",
                    tableName: "Onboarding",
                    value: "Top",
                    comment: "On the toolbar customization onboarding card, the string used to describe the option to set the toolbar at the top of the screen.")
                public static let BottomAction = MZLocalizedString(
                    key: "Onboarding.Customization.Toolbar.Bottom.Action.v123",
                    tableName: "Onboarding",
                    value: "Bottom",
                    comment: "On the toolbar customization onboarding card, the string used to describe the option to set the toolbar at the bottom of the screen.")
                public static let ContinueAction = MZLocalizedString(
                    key: "Onboarding.Customization.Toolbar.Continue.Action.v123",
                    tableName: "Onboarding",
                    value: "Save and Start Browsing",
                    comment: "String used to describe the option to save set preferences and leave onboarding to start browsing in the app.")
                public static let SkipAction = MZLocalizedString(
                    key: "Onboarding.Customization.Toolbar.Skip.Action.v123",
                    tableName: "Onboarding",
                    value: "Skip",
                    comment: "String used to describe the option to skip the toolbar customization in Firefox Onboarding screens and start browisg in the app.")
            }
        }
    }
}

// MARK: - Upgrade CoverSheet
extension String {
    public struct Upgrade {
        public struct Welcome {
            public static let Title = MZLocalizedString(
                key: "Upgrade.Welcome.Title.v114",
                tableName: "Upgrade",
                value: "Welcome to a more personal internet",
                comment: "Title string used to welcome back users in the Upgrade screens. This screen is shown after user upgrades Firefox version.")
            public static let Description = MZLocalizedString(
                key: "Upgrade.Welcome.Description.v114",
                tableName: "Upgrade",
                value: "New colors. New convenience. Same commitment to people over profits.",
                comment: "Description string used to welcome back users in the Upgrade screens. This screen is shown after user upgrades Firefox version.")
            public static let Action = MZLocalizedString(
                key: "Upgrade.Welcome.Action.v114",
                tableName: "Upgrade",
                value: "Set as Default Browser",
                comment: "Describes the action on the first upgrade page in the Upgrade screen. This string will be on a button so user can continue the Upgrade.")
        }

        public struct Sync {
            public static let Title = MZLocalizedString(
                key: "Upgrade.SyncSign.Title.v114",
                tableName: "Upgrade",
                value: "Switching screens is easier than ever",
                comment: "Title string used to sign in to sync in the Upgrade screens. This screen is shown after user upgrades Firefox version.")
            public static let Description = MZLocalizedString(
                key: "Upgrade.SyncSign.Description.v114",
                tableName: "Upgrade",
                value: "Pick up where you left off with tabs from other devices now on your homepage.",
                comment: "Description string used to sign in to sync in the Upgrade screens. This screen is shown after user upgrades Firefox version.")
            public static let Action = MZLocalizedString(
                key: "Upgrade.SyncSign.Action.v114",
                tableName: "Upgrade",
                value: "Sign In",
                comment: "Describes an action on the sync upgrade page in our Upgrade screens. This string will be on a button so user can sign up or login directly in the upgrade.")
        }
    }
}

// MARK: - Research Surface
extension String {
    public struct ResearchSurface {
        public static let BodyText = MZLocalizedString(
            key: "Body.Text.v112",
            tableName: "ResearchSurface",
            value: "Please help make %@ better by taking a short survey.",
            comment: "On the Research Survey popup, the text that explains what the screen is about. %@ is the app name (e.g. Firefox).")
        public static let TakeSurveyButtonLabel = MZLocalizedString(
            key: "PrimaryButton.Label.v112",
            tableName: "ResearchSurface",
            value: "Take Survey",
            comment: "On the Research Survey popup, the text for the button that, when tapped, will dismiss the popup and take the user to a survey.")
        public static let DismissButtonLabel = MZLocalizedString(
            key: "SecondaryButton.Label.v112",
            tableName: "ResearchSurface",
            value: "No Thanks",
            comment: "On the Research Survey popup, the text for the button that, when tapped, will dismiss this screen, and the user will not be taken to the survey.")
    }
}

// MARK: - Search
extension String {
    public struct Search {
        public static let SuggestSectionTitle = MZLocalizedString(
            key: "Search.SuggestSectionTitle.v102",
            tableName: nil,
            value: "Firefox Suggest",
            comment: "When making a new search from the awesome bar, suggestions appear to the user as they write new letters in their search. Different types of suggestions can appear. This string will be used as a header to separate Firefox suggestions from normal suggestions.")
        public static let SponsoredSuggestionDescription = MZLocalizedString(
            key: "Search.SponsoredSuggestionDescription.v119",
            tableName: "Search",
            value: "Sponsored",
            comment: "When making a new search from the awesome bar, suggestions appear to the user as they write new letters in their search. Different types of suggestions can appear. This string will be used as a label for sponsored Firefox suggestions.")
        public static let EngineSectionTitle = MZLocalizedString(
            key: "Search.EngineSection.Title.v108",
            tableName: "SearchHeaderTitle",
            value: "%@ search",
            comment: "When making a new search from the awesome bar, search results appear as the user write new letters in their search. Different sections with results from the selected search engine will appear. This string will be used as a header to separate the selected engine search results from current search query. %@ is the search engine name.")
        public static let GoogleEngineSectionTitle = MZLocalizedString(
            key: "Search.Google.Title.v108",
            tableName: "SearchHeaderTitle",
            value: "Google Search",
            comment: "When making a new search from the awesome bar, search results appear as the user write new letters in their search. This string will be used as a header for Google search results listed as suggestions.")
    }
}

// MARK: - Settings screen
extension String {
    public struct Settings {
        public struct About {
            public static let RateOnAppStore = MZLocalizedString(
                key: "Ratings.Settings.RateOnAppStore",
                tableName: nil,
                value: "Rate on App Store",
                comment: "A label indicating the action that a user can rate the Firefox app in the App store.")
        }

        public struct General {
            public struct ScrollToHideTabAndAddressBar {
                public static let Title = MZLocalizedString(
                    key: "Settings.ScrollToHideTabAndAddressBar.Title.v138",
                    tableName: "Settings",
                    value: "Scroll to Hide Tab and Address Bar",
                    comment: "In the settings menu, in the General section, this is the title for the option that allows user to disable the autohide feature of the tab and address bar."
                )
            }
        }

        public struct Homepage {
            public struct Current {
                public static let Description = MZLocalizedString(
                    key: "Settings.Home.Current.Description.v101",
                    tableName: nil,
                    value: "Choose what displays as the homepage.",
                    comment: "This is the description below the settings section located in the menu under customize current homepage. It describes what the options in the section are for.")
            }

            public struct CustomizeFirefoxHome {
                public static let JumpBackIn = MZLocalizedString(
                    key: "Settings.Home.Option.JumpBackIn",
                    tableName: nil,
                    value: "Jump Back In",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle the Jump Back In section on homepage on or off")
                public static let RecentlyVisited = MZLocalizedString(
                    key: "Settings.Home.Option.RecentlyVisited",
                    tableName: nil,
                    value: "Recently Visited",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Recently Visited section on the Firfox homepage on or off")
                public static let RecentlySaved = MZLocalizedString(
                    key: "Settings.Home.Option.RecentlySaved",
                    tableName: nil,
                    value: "Recently Saved",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Recently Saved section on the Firefox homepage on or off")
                public static let Bookmarks = MZLocalizedString(
                    key: "Settings.Home.Option.Bookmarks.v128",
                    tableName: "CustomizeFirefoxHome",
                    value: "Bookmarks",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Bookmarks section on the Firefox homepage on or off")
                public static let Shortcuts = MZLocalizedString(
                    key: "Settings.Home.Option.Shortcuts",
                    tableName: nil,
                    value: "Shortcuts",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to toggle Shortcuts section on the Firefox homepage on or off")
                public static let Pocket = MZLocalizedString(
                    key: "Settings.Home.Option.Pocket",
                    tableName: nil,
                    value: "Recommended by Pocket",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to turn the Pocket Recommendations section on the Firefox homepage on or off")
                public static let ThoughtProvokingStories = MZLocalizedString(
                    key: "Settings.Home.Option.ThoughtProvokingStories.v116",
                    tableName: "CustomizeFirefoxHome",
                    value: "Thought-Provoking Stories",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the title for the option that allows users to turn the Pocket Recommendations section on the Firefox homepage on or off")
                public static let ThoughtProvokingStoriesSubtitle = MZLocalizedString(
                    key: "Settings.Home.Option.ThoughtProvokingStories.subtitle.v116",
                    tableName: "CustomizeFirefoxHome",
                    value: "Articles powered by %@",
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the subtitle for the option that allows users to turn the Pocket Recommendations section on the Firefox homepage on or off. %@ is Pocket.")
                public static let Title = MZLocalizedString(
                    key: "Settings.Home.Option.Title.v101",
                    tableName: nil,
                    value: "Include on Homepage",
                    comment: "In the settings menu, this is the title of the Firefox Homepage customization settings section")
                public static let Description = MZLocalizedString(
                    key: "Settings.Home.Option.Description.v101",
                    tableName: nil,
                    value: "Choose what’s included on the Firefox homepage.",
                    comment: "In the settings menu, on the Firefox homepage customization section, this is the description below the section, describing what the options in the section are for.")
                public static let Wallpaper = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper",
                    tableName: nil,
                    value: "Wallpaper",
                    comment: "In the settings menu, on the Firefox homepage customization section, this is the title for the option that allows users to access the wallpaper settings for the application.")
            }

            public struct Shortcuts {
                public static let RowSettingFooter = MZLocalizedString(
                    key: "ActivityStream.TopSites.RowSettingFooter",
                    tableName: nil,
                    value: "Set Rows",
                    comment: "The title for the setting page which lets you select the number of top site rows")
                public static let ToggleOn = MZLocalizedString(
                    key: "Settings.Homepage.Shortcuts.ToggleOn.v100",
                    tableName: nil,
                    value: "On",
                    comment: "Toggled ON to show the shortcuts section")
                public static let ToggleOff = MZLocalizedString(
                    key: "Settings.Homepage.Shortcuts.ToggleOff.v100",
                    tableName: nil,
                    value: "Off",
                    comment: "Toggled OFF to hide the shortcuts section")
                public static let ShortcutsPageTitle = MZLocalizedString(
                    key: "Settings.Homepage.Shortcuts.ShortcutsPageTitle.v100",
                    tableName: nil,
                    value: "Shortcuts",
                    comment: "Users can disable or enable shortcuts related settings. This string is the title of the page to change your shortcuts settings.")
                public static let ShortcutsToggle = MZLocalizedString(
                    key: "Settings.Homepage.Shortcuts.ShortcutsToggle.v100",
                    tableName: nil,
                    value: "Shortcuts",
                    comment: "This string is the title of the toggle to disable the shortcuts section in the settings page.")
                public static let SponsoredShortcutsToggle = MZLocalizedString(
                    key: "Settings.Homepage.Shortcuts.SponsoredShortcutsToggle.v100",
                    tableName: nil,
                    value: "Sponsored Shortcuts",
                    comment: "This string is the title of the toggle to disable the sponsored shortcuts functionnality which can be enabled in the shortcut sections. This toggle is in the settings page.")
                public static let Rows = MZLocalizedString(
                    key: "Settings.Homepage.Shortcuts.Rows.v100",
                    tableName: nil,
                    value: "Rows",
                    comment: "This string is the title of the setting button which can be clicked to open a page to customize the number of rows in the shortcuts section")
                public static let RowsPageTitle = MZLocalizedString(
                    key: "Settings.Homepage.Shortcuts.RowsPageTitle.v100",
                    tableName: nil,
                    value: "Rows",
                    comment: "This string is the title of the page to customize the number of rows in the shortcuts section")
            }

            public struct StartAtHome {
                public static let SectionTitle = MZLocalizedString(
                    key: "Settings.Home.Option.StartAtHome.Title",
                    tableName: nil,
                    value: "Opening screen",
                    comment: "Title for the section in the settings menu where users can configure the behaviour of the Start at Home feature on the Firefox Homepage.")
                public static let SectionDescription = MZLocalizedString(
                    key: "Settings.Home.Option.StartAtHome.Description",
                    tableName: nil,
                    value: "Choose what you see when you return to Firefox.",
                    comment: "In the settings menu, in the Start at Home customization options, this is text that appears below the section, describing what the section settings do.")
                public static let AfterFourHours = MZLocalizedString(
                    key: "Settings.Home.Option.StartAtHome.AfterFourHours",
                    tableName: nil,
                    value: "Homepage after four hours of inactivity",
                    comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the Homepage after four hours of inactivity.")
                public static let Always = MZLocalizedString(
                    key: "Settings.Home.Option.StartAtHome.Always",
                    tableName: nil,
                    value: "Homepage",
                    comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the Homepage every time they open up Firefox")
                public static let Never = MZLocalizedString(
                    key: "Settings.Home.Option.StartAtHome.Never",
                    tableName: nil,
                    value: "Last tab",
                    comment: "In the settings menu, on the Start at Home homepage customization option, this allows users to set this setting to return to the last tab they were on, every time they open up Firefox")
            }

            public struct Wallpaper {
                public static let PageTitle = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.Title",
                    tableName: nil,
                    value: "Wallpaper",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of that screen, which allows users to change the wallpaper settings for the application.")
                public static let CollectionTitle = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.CollectionTitle",
                    tableName: nil,
                    value: "OPENING SCREEN",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of the section that allows users to change the wallpaper settings for the application.")
                public static let SwitchTitle = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.SwitchTitle.v99",
                    tableName: nil,
                    value: "Change wallpaper by tapping Firefox homepage logo",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the string titling the switch button's function, which allows a user to toggle wallpaper switching from the homepage logo on or off.")
                public static let WallpaperUpdatedToastLabel = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.UpdatedToast",
                    tableName: nil,
                    value: "Wallpaper Updated!",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of toast that comes up when the user changes wallpaper, which lets them know that the wallpaper has been updated.")
                public static let WallpaperUpdatedToastButton = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.UpdatedToastButton",
                    tableName: nil,
                    value: "View",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of the button found on the toast that comes up once the user changes wallpaper, and allows users to dismiss the settings page. In this case, consider View as a verb - the action of dismissing settings and seeing the wallpaper.")

                public static let ClassicWallpaper = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.Classic.Title.v106",
                    tableName: nil,
                    value: "Classic %@",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of the group of wallpapers that are always available to the user. The %@ will be replaced by the app name and thus doesn't need translation.")
                public static let LimitedEditionWallpaper = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.LimitedEdition.Title.v106",
                    tableName: nil,
                    value: "Limited Edition",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title of the group of wallpapers that are seasonally available to the user.")
                public static let IndependentVoicesDescription = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.LimitedEdition.IndependentVoices.Description.v106",
                    tableName: nil,
                    value: "The new Independent Voices collection.",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the description of the group of wallpapers that are seasonally available to the user.")
                public static let LimitedEditionDefaultDescription = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.LimitedEdition.Default.Description.v106",
                    tableName: nil,
                    value: "Try the new collection.",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the default description of the group of wallpapers that are seasonally available to the user.")
                public static let LearnMoreButton = MZLocalizedString(
                    key: "Settings.Home.Option.Wallpaper.LearnMore.v106",
                    tableName: nil,
                    value: "Learn more",
                    comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the button title of the group of wallpapers that are seasonally available to the user.")

                // Accessibility
                public struct AccessibilityLabels {
                    public static let FxHomepageWallpaperButton = MZLocalizedString(
                        key: "FxHomepage.Wallpaper.ButtonLabel.v99",
                        tableName: nil,
                        value: "Firefox logo, change the wallpaper.",
                        comment: "On the firefox homepage, the string read by the voice over prompt for accessibility, for the button which changes the wallpaper")
                    public static let ToggleButton = MZLocalizedString(
                        key: "Settings.Home.Option.Wallpaper.Accessibility.ToggleButton",
                        tableName: nil,
                        value: "Homepage wallpaper cycle toggle",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the accessibility string of the toggle for turning wallpaper cycling shortcut on or off on the homepage.")
                    public static let DefaultWallpaper = MZLocalizedString(
                        key: "Settings.Home.Option.Wallpaper.Accessibility.DefaultWallpaper.v99",
                        tableName: nil,
                        value: "Default clear wallpaper.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the accessibility string for the default wallpaper.")
                    public static let FxAmethystWallpaper = MZLocalizedString(
                        key: "Settings.Home.Option.Wallpaper.Accessibility.AmethystWallpaper.v99",
                        tableName: nil,
                        value: "Firefox wallpaper, amethyst pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the accessibility string for the amethyst firefox wallpaper.")
                    public static let FxSunriseWallpaper = MZLocalizedString(
                        key: "Settings.Home.Option.Wallpaper.Accessibility.SunriseWallpaper.v99",
                        tableName: nil,
                        value: "Firefox wallpaper, sunrise pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title accessibility string for the sunrise firefox wallpaper.")
                    public static let FxCeruleanWallpaper = MZLocalizedString(
                        key: "Settings.Home.Option.Wallpaper.Accessibility.CeruleanWallpaper.v99",
                        tableName: nil,
                        value: "Firefox wallpaper, cerulean pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title accessibility string for the cerulean firefox wallpaper.")
                    public static let FxBeachHillsWallpaper = MZLocalizedString(
                        key: "Settings.Home.Option.Wallpaper.Accessibility.BeachHillsWallpaper.v100",
                        tableName: nil,
                        value: "Firefox wallpaper, beach hills pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title accessibility string for the beach hills firefox wallpaper.")
                    public static let FxTwilightHillsWallpaper = MZLocalizedString(
                        key: "Settings.Home.Option.Wallpaper.Accessibility.TwilightHillsWallpaper.v100",
                        tableName: nil,
                        value: "Firefox wallpaper, twilight hills pattern.",
                        comment: "In the settings menu, on the Firefox wallpaper customization screen, this is the title accessibility string for the twilight hills firefox wallpaper.")
                }
            }
        }

        public struct Tabs {
            public static let TabsSectionTitle = MZLocalizedString(
                key: "Settings.Tabs.CustomizeTabsSection.Title",
                tableName: nil,
                value: "Customize Tab Tray",
                comment: "In the settings menu, in the Tabs customization section, this is the title for the Tabs Tray customization section. The tabs tray is accessed from firefox hompage")
            public static let InactiveTabs = MZLocalizedString(
                key: "Settings.Tabs.CustomizeTabsSection.InactiveTabs",
                tableName: nil,
                value: "Inactive Tabs",
                comment: "This is the description for the setting that toggles the Inactive Tabs feature in the settings menu under the Tabs customization section. Inactive tabs are a separate section of tabs that appears in the Tab Tray, which can be enabled or not")
            public static let InactiveTabsDescription = MZLocalizedString(
                key: "Settings.Tabs.CustomizeTabsSection.InactiveTabsDescription.v101",
                tableName: nil,
                value: "Tabs you haven’t viewed for two weeks get moved to the inactive section.",
                comment: "This is the description for the setting that toggles the Inactive Tabs feature in the settings menu under the Tabs customization section. Inactive tabs are a separate section of tabs that appears in the Tab Tray, which can be enabled or not")
            public static let TabGroups = MZLocalizedString(
                key: "Settings.Tabs.CustomizeTabsSection.TabGroups",
                tableName: nil,
                value: "Tab Groups",
                comment: "In the settings menu, in the Tabs customization section, this is the title for the setting that toggles the Tab Groups feature - where tabs from related searches are grouped - on or off")
        }

        public struct Browsing {
            public static let Title = MZLocalizedString(
                key: "Settings.Browsing.Title.v137",
                tableName: "Settings",
                value: "Browsing",
                comment: "In the settings menu, in the General section, this is the title for Browsing customization section."
            )
            public static let Tabs = MZLocalizedString(
                key: "Settings.Browsing.Tabs.v137",
                tableName: "Settings",
                value: "Tabs",
                comment: "This is the title for Tabs customization under the Browsing settings section."
            )
            public static let Links = MZLocalizedString(
                key: "Settings.Browsing.Links.v137",
                tableName: "Settings",
                value: "Links",
                comment: "This is the title for Links customization under the Browsing settings section."
            )
            public static let Media = MZLocalizedString(
                key: "Settings.Browsing.Media.v137",
                tableName: "Settings",
                value: "Media",
                comment: "This is the title for Media customization under the Browsing settings section."
            )
        }

        public struct AutofillAndPassword {
            public static let Title = MZLocalizedString(
                key: "Settings.AutofillAndPassword.Title.v137",
                tableName: "Settings",
                value: "Autofills & Passwords",
                comment: "In the settings menu, in the General section, this is the title for Autofills & Passwords customization section."
            )
        }

        public struct Notifications {
            public static let Title = MZLocalizedString(
                key: "Settings.Notifications.Title.v112",
                tableName: "Settings",
                value: "Notifications",
                comment: "In the settings menu, in the Privacy section, this is the title for Notifications customization section."
            )
            public static let SyncNotificationsTitle = MZLocalizedString(
                key: "Settings.Notifications.SyncNotificationsTitle.v112",
                tableName: "Settings",
                value: "Sync",
                comment: "This is the title for the setting that toggles Sync related notifications in the settings menu under the Notifications section."
            )
            public static let SyncNotificationsStatus = MZLocalizedString(
                key: "Settings.Notifications.SyncNotificationsStatus.v112",
                tableName: "Settings",
                value: "This must be turned on to receive tabs and get notified when you sign in on another device.",
                comment: "This is the description for the setting that toggles Sync related notifications in the settings menu under the Notifications section."
            )
            public static let TipsAndFeaturesNotificationsTitle = MZLocalizedString(
                key: "Settings.Notifications.TipsAndFeaturesNotificationsTitle.v112",
                tableName: "Settings",
                value: "Tips and Features",
                comment: "This is the title for the setting that toggles Tips and Features feature in the settings menu under the Notifications section."
            )
            public static let TipsAndFeaturesNotificationsStatus = MZLocalizedString(
                key: "Settings.Notifications.TipsAndFeaturesNotificationsStatus.v112",
                tableName: "Settings",
                value: "Learn about useful features and how to get the most out of %@.",
                comment: "This is the description for the setting that toggles Tips and Features feature in the settings menu under the Notifications section. %@ is the app name (e.g. Firefox)."
            )
            public static let TurnOnNotificationsTitle = MZLocalizedString(
                key: "Settings.Notifications.TurnOnNotificationsTitle.v112",
                tableName: "Settings",
                value: "Turn on Notifications",
                comment: "This is the title informing the user that they need to turn on notifications in iOS Settings."
            )
            public static let TurnOnNotificationsMessage = MZLocalizedString(
                key: "Settings.Notifications.TurnOnNotificationsMessage.v112",
                tableName: "Settings",
                value: "Go to your device Settings to turn on notifications in %@",
                comment: "This is the title informing the user that they need to turn on notifications in iOS Settings. %@ is the app name (e.g. Firefox)."
            )
            public static let systemNotificationsDisabledMessage = MZLocalizedString(
                key: "Settings.Notifications.SystemNotificationsDisabledMessage.v112",
                tableName: "Settings",
                value: "You turned off all %1$@ notifications. Turn them on by going to device Settings > Notifications > %2$@",
                comment: "This is the footer title informing the user needs to turn on notifications in iOS Settings. Both %1$@ and %2$@ are the app name (e.g. Firefox)."
            )
        }

        public struct Toolbar {
            public static let Toolbar = MZLocalizedString(
                key: "Settings.Toolbar.SettingsTitle",
                tableName: nil,
                value: "Toolbar",
                comment: "In the settings menu, this label indicates that there is an option of customizing the Toolbar appearance.")
            public static let Top = MZLocalizedString(
                key: "Settings.Toolbar.Top",
                tableName: nil,
                value: "Top",
                comment: "In the settings menu, in the Toolbar customization section, this label indicates that selecting this will make the toolbar appear at the top of the screen.")
            public static let Bottom = MZLocalizedString(
                key: "Settings.Toolbar.Bottom",
                tableName: nil,
                value: "Bottom",
                comment: "In the settings menu, in the Toolbar customization section, this label indicates that selecting this will make the toolbar appear at the bottom of the screen.")
        }

        public struct AppIconSelection {
            public static let SettingsOptionName = MZLocalizedString(
                key: "Settings.AppIconSelection.SettingsOptionName.v136",
                tableName: "AppIconSelection",
                value: "App Icon",
                comment: "On the Settings screen, the name of the row that opens app icon selection options.")

            public static let ScreenTitle = MZLocalizedString(
                key: "Settings.AppIconSelection.ScreenTitle.v136",
                tableName: "AppIconSelection",
                value: "App Icon",
                comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the title displayed at the top of the screen.")

            public struct Errors {
                public static let SelectErrorMessage = MZLocalizedString(
                    key: "Settings.AppIconSelection.Errors.SelectErrorMessage.v136",
                    tableName: "AppIconSelection",
                    value: "Sorry, there was an error setting your app icon.",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the message displayed when the app fails to set the user's selected app icon.")

                public static let SelectErrorConfirmation = MZLocalizedString(
                    key: "Settings.AppIconSelection.Errors.SelectErrorConfirmation.v136",
                    tableName: "AppIconSelection",
                    value: "OK",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the label for the button to acknowledge that an error setting the app icon has occurred.")
            }

            public struct AppIconNames {
                public static let Regular = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Regular.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Default",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the default Firefox for iOS icon.")

                public static let DarkPurple = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.DarkPurple.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Dark Purple",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS icon with a dark purple background.")

                public static let Blue = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Blue.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Blue",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox icon with a blue background.")

                public static let Cyan = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Cyan.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Cyan",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox icon with a cyan background.")

                public static let Green = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Green.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Green",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox icon with a green background.")

                public static let Hug = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Hug.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Hug",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the artsy Firefox for iOS icon of a character hugging the Firefox logo.")

                public static let Lazy = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Lazy.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Lazy",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the artsy Firefox for iOS icon of a funny fox lying on top of a globe.")

                public static let Orange = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Orange.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Orange",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox icon with a orange background.")

                public static let Pink = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Pink.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Pink",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox icon with a pink background.")

                public static let Pixelated = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Pixelated.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Pixelated",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of a pixelated version of the regular Firefox for iOS app icon.")

                public static let Pride = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Pride.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Pride",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of a LGBT+ pride fox logo.")

                public static let Purple = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Purple.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Purple",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox icon with a purple background.")

                public static let Red = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Red.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Red",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox icon with a red background.")

                public static let Retro = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Retro.Title.v136",
                    tableName: "AppIconSelection",
                    value: "Retro",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of a retro version of the regular Firefox for iOS app icon.")

                public static let Yellow = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Yellow.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Yellow",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox icon with a yellow background.")

                public static let Sunrise = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Sunrise.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Sunrise",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS app icon with a background gradient of light blue fading to yellow.")

                public static let Midday = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Midday.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Midday",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS app icon with a background gradient of light blue fading to light purple.")

                public static let GoldenHour = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.GoldenHour.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Golden Hour",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS app icon with a background gradient of yellow fading to orange.")

                public static let Sunset = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Sunset.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Sunset",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS app icon with a background gradient of purple fading to pink.")

                public static let BlueHour = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.BlueHour.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Blue Hour",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS app icon with a background gradient of blue fading to purple.")

                public static let Twilight = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Twilight.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Twilight",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS app icon with a background gradient of dark blue fading to light blue.")

                public static let Midnight = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.Midnight.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Midnight",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS app icon with a background gradient of black fading to dark purple.")

                public static let NorthernLights = MZLocalizedString(
                    key: "Settings.AppIconSelection.AppIconNames.NorthernLights.Title.v137",
                    tableName: "AppIconSelection",
                    value: "Northern Lights",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the name of the Firefox for iOS app icon with a background gradient of black fading to blue fading to green.")
            }

            public struct Accessibility {
                public static let AppIconSelectedLabel = MZLocalizedString(
                    key: "Settings.AppIconSelection.Accessibility.AppIconSelectedLabel.v136",
                    tableName: "AppIconSelection",
                    value: "Selected",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the accessibility label describing the filled checkbox on the currently selected app icon option.")

                public static let AppIconUnselectedLabel = MZLocalizedString(
                    key: "Settings.AppIconSelection.Accessibility.AppIconUnselectedLabel.v136",
                    tableName: "AppIconSelection",
                    value: "Deselected",
                    comment: "On the app icon customization screen where you can select an alternate icon for the app, this is the accessibility label describing an unfilled checkbox for an unselected app icon option.")

                public static let AppIconSelectionHint = MZLocalizedString(
                    key: "Settings.AppIconSelection.Accessibility.AppIconSelectionHint.v136",
                    tableName: "AppIconSelection",
                    value: "Select the %@ app icon",
                    comment: "On the app icon customization screen, where you can select an alternate icon for the app, this is the accessibility hint describing what happens when you select an app icon row. %@ is the app name.")
            }
        }

        public struct Autoplay {
            public static let Autoplay = MZLocalizedString(
                key: "Settings.Autoplay.SettingsTitle.v137",
                tableName: "Settings",
                value: "Autoplay",
                comment: "In the settings menu, this label indicates that there is an option of customizing the Autoplay behaviour.")
            public static let AllowAudioAndVideo = MZLocalizedString(
                key: "Settings.Autoplay.AllowAudioAndVideo.v137",
                tableName: "Settings",
                value: "Allow Audio and Video",
                comment: "In the settings menu, in the Autoplay customization section, this label indicates that selecting this will allow audio and video content to autoplay.")
            public static let BlockAudio = MZLocalizedString(
                key: "Settings.Autoplay.BlockAudio.v137",
                tableName: "Settings",
                value: "Block Audio",
                comment: "In the settings menu, in the Autoplay customization section, this label indicates that selecting this will block audio from autoplaying.")
            public static let BlockAudioAndVideo = MZLocalizedString(
                key: "Settings.Autoplay.BlockAudioAndVideo.v137",
                tableName: "Settings",
                value: "Block Audio and Video",
                comment: "In the settings menu, in the Autoplay customization section, this label indicates that selecting this will block audio and video content from autoplaying.")
            public static let Footer = MZLocalizedString(
                key: "Settings.Autoplay.Footer.v137",
                tableName: "Settings",
                value: "Autoplay settings will only apply to newly opened tabs. Changes cannot be applied to existing tabs unless the application is restarted.",
                comment: "In the settings menu, in the Autoplay customization section, this label indicates that selecting this will block audio and video content from autoplaying.")
        }

        public struct Toggle {
            public static let NoImageMode = MZLocalizedString(
                key: "Settings.NoImageModeBlockImages.Label.v99",
                tableName: nil,
                value: "Block Images",
                comment: "Label for the block images toggle displayed in the settings menu. Enabling this toggle will hide images on any webpage the user visits.")
        }

        public struct Passwords {
            public static let Title = MZLocalizedString(
                key: "Settings.Passwords.Title.v103",
                tableName: nil,
                value: "Passwords",
                comment: "Title for the passwords screen.")
            public static let SavePasswords = MZLocalizedString(
                key: "Settings.Passwords.SavePasswords.v103",
                tableName: nil,
                value: "Save Passwords",
                comment: "Setting that appears in the Passwords screen to enable the built-in password manager so users can save their passwords.")
            public static let OnboardingMessage = MZLocalizedString(
                key: "Settings.Passwords.OnboardingMessage.v103",
                tableName: nil,
                value: "Your passwords are now protected by Face ID, Touch ID or a device passcode.",
                comment: "Message shown when you enter Passwords screen for the first time. It explains how password are protected in the Firefox for iOS application.")
            public static let FingerPrintReason = MZLocalizedString(
                key: "Settings.Passwords.FingerPrintReason.v103",
                tableName: nil,
                value: "Use your fingerprint to access passwords now.",
                comment: "Touch ID prompt subtitle when accessing logins and passwords")
        }

        public struct Sync {
            public static let ButtonTitle = MZLocalizedString(
                key: "Settings.Sync.ButtonTitle.v103",
                tableName: nil,
                value: "Sync and Save Data",
                comment: "Button label that appears in the settings to prompt the user to sign in to Firefox for iOS sync service to sync and save data.")
            public static let ButtonDescription = MZLocalizedString(
                key: "Settings.Sync.ButtonDescription.v103",
                tableName: nil,
                value: "Sign in to sync tabs, bookmarks, passwords, and more.",
                comment: "Ddescription that appears in the settings screen to explain what Firefox Sync is useful for.")

            public struct SignInView {
                public static let Title = MZLocalizedString(
                    key: "Settings.Sync.SignInView.Title.v103",
                    tableName: nil,
                    value: "Sync and Save Data",
                    comment: "Title for the page where the user sign in to their Firefox Sync account.")
            }
        }

        public struct Search {
            public static let Title = MZLocalizedString(
                key: "Settings.Search.PageTitle.v121",
                tableName: "Settings",
                value: "Search",
                comment: "Navigation title for search page in the Settings menu.")
            public static let ShowSearchSuggestions = MZLocalizedString(
                key: "Settings.Search.ShowSuggestions.v121",
                tableName: "Settings",
                value: "Show Search Suggestions",
                comment: "Label for the `show search suggestions` setting, in the Search Settings page.")
            public static let DefaultSearchEngineTitle = MZLocalizedString(
                key: "Settings.Search.DefaultSearchEngine.Title.v121",
                tableName: "Settings",
                value: "Default Search Engine",
                comment: "Title for the `default search engine` settings section in the Search page in the Settings menu.")
            public static let AlternateSearchEnginesTitle = MZLocalizedString(
                key: "Settings.Search.AlternateSearchEngines.Title.v124.v2",
                tableName: "Settings",
                value: "Alternative Search Engines",
                comment: "Title for alternate search engines settings section in the Search page in the Settings menu.")
            public static let EnginesSuggestionsTitle = MZLocalizedString(
                key: "Settings.Search.EnginesSuggestions.Title.v124",
                tableName: "Settings",
                value: "Suggestions from Search Engines",
                comment: "Title for the `Suggestions from Search Engines` settings section in the Search page in the Settings menu.")
            public static let PrivateSessionSetting = MZLocalizedString(
                key: "Settings.Search.PrivateSession.Setting.v124",
                tableName: "Settings",
                value: "Show in Private Sessions",
                comment: "Label for toggle. Explains that in private browsing mode, the search suggestions which appears at the top of the search bar, can be toggled on or off. Located in `Suggestions from Search Engines` and `Address Bar - Firefox Suggest` sections in the Search page in the Settings menu.")
            public static let PrivateSessionDescription = MZLocalizedString(
                key: "Settings.Search.PrivateSession.Description.v125",
                tableName: "Settings",
                value: "Show suggestions from search engines in private sessions",
                comment: "Description for `Show in Private Sessions` toggle, located in `Suggestions from Search Engines` section in the Search page in the Settings menu.")
            public struct AccessibilityLabels {
                public static let DefaultSearchEngine = MZLocalizedString(
                    key: "Settings.Search.Accessibility.DefaultSearchEngine.v121",
                    tableName: "Settings",
                    value: "Default Search Engine",
                    comment: "Accessibility label for default search engine setting.")
                public static let LearnAboutSuggestions = MZLocalizedString(
                    key: "Settings.Search.Accessibility.LearnAboutSuggestions.v124",
                    tableName: "Settings",
                    value: "Learn more about Firefox Suggest",
                    comment: "Accessibility label for Learn more about Firefox Suggest.")
            }

            public struct Suggest {
                public static let AddressBarSettingsTitle = MZLocalizedString(
                    key: "Settings.Search.Suggest.AddressBarSetting.Title.v124",
                    tableName: "Settings",
                    value: "Address bar - Firefox Suggest",
                    comment: "In the Search page of the Settings menu, the title for the Firefox Suggest settings section.")
                public static let ShowNonSponsoredSuggestionsTitle = MZLocalizedString(
                    key: "Settings.Search.Suggest.ShowNonSponsoredSuggestions.Title.v124.v2",
                    tableName: "Settings",
                    value: "Suggestions from the Web",
                    comment: "In the Search page of the Settings menu, the title for setting to enable Suggestions from the web in Firefox.")
                public static let ShowNonSponsoredSuggestionsDescription = MZLocalizedString(
                    key: "Settings.Search.Suggest.ShowNonSponsoredSuggestions.Description.v124.v2",
                    tableName: "Settings",
                    value: "Get suggestions from %@ related to your search",
                    comment: "In the Search page of the Settings menu, the description for the setting to enable Suggestions from Firefox. %@ is the app name (e.g. Firefox). - Firefox.")
                public static let ShowSponsoredSuggestionsTitle = MZLocalizedString(
                    key: "Settings.Search.Suggest.ShowSponsoredSuggestions.Title.v124",
                    tableName: "Settings",
                    value: "Suggestions from Sponsors",
                    comment: "In the Search page of the Settings menu, the title for the setting to enable Suggestions from sponsors.")
                public static let ShowSponsoredSuggestionsDescription = MZLocalizedString(
                    key: "Settings.Search.Suggest.ShowSponsoredSuggestions.Description.v124",
                    tableName: "Settings",
                    value: "Support %@ with occasional sponsored suggestions",
                    comment: "In the Search page of the Settings menu, the description for the setting to enable Suggestions from sponsors. %@ is the app name (e.g. Firefox). - Firefox.")
                public static let SearchBrowsingHistory = MZLocalizedString(
                    key: "Settings.Search.Suggest.SearchBrowsingHistory.Title.v124",
                    tableName: "Settings",
                    value: "Search Browsing History",
                    comment: "In the Search page of the Settings menu, the title for the setting to enable search browsing history.")
                public static let SearchBookmarks = MZLocalizedString(
                    key: "Settings.Search.Suggest.SearchSearchBookmarks.Title.v124",
                    tableName: "Settings",
                    value: "Search Bookmarks",
                    comment: "In the Search page of the Settings menu, the title for the setting to enable search bookmarks.")
                public static let SearchSyncedTabs = MZLocalizedString(
                    key: "Settings.Search.Suggest.SearchSyncedTabs.Title.v124",
                    tableName: "Settings",
                    value: "Search Synced Tabs",
                    comment: "In the Search page of the Settings menu, the title for the setting to enable synced tabs.")
                public static let PrivateSessionDescription = MZLocalizedString(
                    key: "Settings.Search.Suggest.PrivateSession.Description.v125",
                    tableName: "Settings",
                    value: "Show suggestions from Firefox Suggest in private sessions",
                    comment: "Description for `Show in Private Sessions` toggle, located in `Address Bar - Firefox Suggest` section in the Search page in the Settings menu.")
                public static let LearnAboutSuggestions = MZLocalizedString(
                    key: "Settings.Search.Suggest.LearnAboutSuggestions.v124",
                    tableName: "Settings",
                    value: "Learn more about Firefox Suggest",
                    comment: "In the search page of the Settings menu, the title for the link to the SUMO Page about Firefox Suggest."
                )
            }
        }
    }
}

// MARK: - Share Sheet
extension String {
    public struct ShareSheet {
        public static let CopyButtonTitle = MZLocalizedString(
            key: "ShareSheet.Copy.Title.v108",
            tableName: nil,
            value: "Copy",
            comment: "Button in share sheet to copy the url of the current tab.")
        public static let SendToDeviceButtonTitle = MZLocalizedString(
            key: "ShareSheet.SendToDevice.Title.v108",
            tableName: nil,
            value: "Send Link to Device",
            comment: "Button in the share sheet to send the current link to another device.")
    }
}

// MARK: - Tabs Tray
extension String {
    public struct TabsTray {
        public struct InactiveTabs {
            public static let TabsTrayInactiveTabsSectionClosedAccessibilityTitle = MZLocalizedString(
                key: "TabsTray.InactiveTabs.SectionTitle.Closed.Accessibility.v103",
                tableName: nil,
                value: "View Inactive Tabs",
                comment: "Accessibility title for the inactive tabs section button when section is closed. This section groups all tabs that haven't been used in a while.")
            public static let TabsTrayInactiveTabsSectionOpenedAccessibilityTitle = MZLocalizedString(
                key: "TabsTray.InactiveTabs.SectionTitle.Opened.Accessibility.v103",
                tableName: nil,
                value: "Hide Inactive Tabs",
                comment: "Accessibility title for the inactive tabs section button when section is open. This section groups all tabs that haven't been used in a while.")
            public static let CloseAllInactiveTabsButton = MZLocalizedString(
                key: "InactiveTabs.TabTray.CloseButtonTitle",
                tableName: nil,
                value: "Close All Inactive Tabs",
                comment: "In the Tabs Tray, in the Inactive Tabs section, this is the button the user must tap in order to close all inactive tabs.")
            public static let CloseInactiveTabSwipeActionTitle = MZLocalizedString(
                key: "InactiveTabs.TabTray.CloseSwipeActionTitle.v115",
                tableName: "TabsTray",
                value: "Close",
                comment: "This is the swipe action title for closing an inactive tab by swiping, located in the Inactive Tabs section of the Tabs Tray")
        }

        public struct CloseTabsToast {
            public static let Title = MZLocalizedString(
                key: "CloseTabsToast.Title.v113",
                tableName: "TabsTray",
                value: "Tabs Closed: %d",
                comment: "When the user closes tabs in the tab tray, a popup will appear informing them how many tabs were closed. This is the text for the popup. %d is the number of tabs. ")
            public static let SingleTabTitle = MZLocalizedString(
                key: "CloseTabsToast.SingleTabTitle.v113",
                tableName: "TabsTray",
                value: "Tab Closed",
                comment: "When the user closes an individual tab in the tab tray, a popup will appear informing them the tab was closed. This is the text for the popup.")
            public static let Action = MZLocalizedString(
                key: "CloseTabsToast.Button.v113",
                tableName: "TabsTray",
                value: "Undo",
                comment: "When the user closes tabs in the tab tray, a popup will appear. This is the title for the button to undo the deletion of those tabs")
        }

        public struct Sync {
            public static let SyncTabs = MZLocalizedString(
                key: "TabsTray.SyncTabs.SyncTabsButton.Title.v119",
                tableName: "TabsTray",
                value: "Sync Tabs",
                comment: "Button label to sync tabs in your account")
            public static let SyncTabsDisabled = MZLocalizedString(
                key: "TabsTray.Sync.SyncTabsDisabled.v116",
                tableName: "TabsTray",
                value: "Turn on tab syncing to view a list of tabs from your other devices.",
                comment: "Users can disable syncing tabs from other devices. In the Sync Tabs panel of the Tab Tray, we inform the user tab syncing can be switched back on to view those tabs.")
        }

        public struct DownloadsPanel {
            public static let EmptyStateTitle = MZLocalizedString(
                key: "DownloadsPanel.EmptyState.Title",
                tableName: nil,
                value: "Downloaded files will show up here.",
                comment: "Title for the Downloads Panel empty state.")
            public static let DeleteTitle = MZLocalizedString(
                key: "DownloadsPanel.Delete.Title",
                tableName: nil,
                value: "Delete",
                comment: "Action button for deleting downloaded files in the Downloads panel.")
            public static let ShareTitle = MZLocalizedString(
                key: "DownloadsPanel.Share.Title",
                tableName: nil,
                value: "Share",
                comment: "Action button for sharing downloaded files in the Downloads panel.")
        }

        public static let TabTraySelectorAccessibilityHint = MZLocalizedString(
            key: "TabTraySelectorAccessibilityHint.v139",
            tableName: "TabsTray",
            value: "%1$@ of %2$@",
            comment: "Message spoken by VoiceOver saying the position of the currently selected page in the tab tray selector (%1$@), along with the total number of selector (%2$@). E.g. “1 of 3” says that page 1 is visible, out of 3 pages total.")
    }
}

// MARK: - What's New
extension String {
    /// The text for the What's New onboarding card
    public struct WhatsNew {
        public static let RecentButtonTitle = MZLocalizedString(
            key: "Onboarding.WhatsNew.Button.Title",
            tableName: nil,
            value: "Start Browsing",
            comment: "On the onboarding card letting users know what's new in this version of Firefox, this is the title for the button, on the bottom of the card, used to get back to browsing on Firefox by dismissing the onboarding card")
    }

    /// The localizations for the custom implemented content on the WebView
    public struct WebView {
        public static let DocumentLoadingLabel = MZLocalizedString(
            key: "WebView.DocumentLoadingLabel.v137",
            tableName: "WebView",
            value: "Loading…",
            comment: "The label shown while loading a document in the web view's custom document loading UI"
        )
        public static let DocumentLoadingAccessibilityLabel = MZLocalizedString(
            key: "WebView.DocumentLoadingAccessibilityLabel.v137",
            tableName: "WebView",
            value: "Loading Document",
            comment: "The accessibility label read when loading a document in the web view's custom document loading UI."
        )
    }
}

// MARK: - Strings: unorganized & unchecked for use
// Here we have the original strings. What follows below is unorganized. As
// the team continues to work on new updates to strings, or to work on a view,
// these strings should be checked if in use, still. If not, they should be
// removed; if used, they should be added to the organized section of this
// file, for easier classification and use.

// MARK: - General
extension String {
    public static let OKString = MZLocalizedString(
        key: "OK",
        tableName: nil,
        value: nil,
        comment: "OK button")
    public static let CancelString = MZLocalizedString(
        key: "Cancel",
        tableName: nil,
        value: nil,
        comment: "Label for Cancel button")
    public static let NotNowString = MZLocalizedString(
        key: "Toasts.NotNow",
        tableName: nil,
        value: "Not Now",
        comment: "label for Not Now button")
    public static let AppStoreString = MZLocalizedString(
        key: "Toasts.OpenAppStore",
        tableName: nil,
        value: "Open App Store",
        comment: "Open App Store button")
    public static let UndoString = MZLocalizedString(
        key: "Toasts.Undo",
        tableName: nil,
        value: "Undo",
        comment: "Label for button to undo the action just performed")
    public static let OpenSettingsString = MZLocalizedString(
        key: "Open Settings",
        tableName: nil,
        value: nil,
        comment: "See http://mzl.la/1G7uHo7")
}

// MARK: - Top Sites
extension String {
    public static let TopSitesRemoveButtonAccessibilityLabel = MZLocalizedString(
        key: "TopSites.RemovePage.Button",
        tableName: nil,
        value: "Remove page — %@",
        comment: "Button shown in editing mode to remove this site from the top sites panel. %@ is the title of the site.")
    public static let TopSitesRemoveButtonLargeContentTitle = MZLocalizedString(
        key: "TopSites.RemoveButton.LargeContentTitle.v122",
        tableName: "TabLocation",
        value: "Remove page",
        comment: "Large content title for the button shown in editing mode to remove this site from the top sites panel.")
}

// MARK: - Activity Stream
extension String {
    public static let RecentlySavedSectionTitle = MZLocalizedString(
        key: "ActivityStream.Library.Title",
        tableName: nil,
        value: "Recently Saved",
        comment: "A string used to signify the start of the Recently Saved section in Home Screen.")
    public static let RecentlySavedShowAllText = MZLocalizedString(
        key: "RecentlySaved.Actions.More",
        tableName: nil,
        value: "Show All",
        comment: "More button text for Recently Saved items at the home page.")
    public static let BookmarksSectionTitle = MZLocalizedString(
        key: "ActivityStream.Bookmarks.Title.v128",
        tableName: "ActivityStream",
        value: "Bookmarks",
        comment: "String used in the section title of the Bookmarks section on Home Screen.")
    public static let BookmarksSavedShowAllText = MZLocalizedString(
        key: "Bookmarks.Actions.More.v128",
        tableName: "ActivityStream",
        value: "Show All",
        comment: "Show all button text for Bookmarks items on the home page, which opens the Bookmarks panel when tapped.")
}

// MARK: - Home Panel Context Menu
extension String {
    public static let OpenInNewTabContextMenuTitle = MZLocalizedString(
        key: "HomePanel.ContextMenu.OpenInNewTab",
        tableName: nil,
        value: "Open in New Tab",
        comment: "The title for the Open in New Tab context menu action for sites in Home Panels")
    public static let OpenInNewPrivateTabContextMenuTitle = MZLocalizedString(
        key: "HomePanel.ContextMenu.OpenInNewPrivateTab.v101",
        tableName: nil,
        value: "Open in a Private Tab",
        comment: "The title for the Open in New Private Tab context menu action for sites in Home Panels")
    public static let BookmarkContextMenuTitle = MZLocalizedString(
        key: "HomePanel.ContextMenu.Bookmark",
        tableName: nil,
        value: "Bookmark",
        comment: "The title for the Bookmark context menu action for sites in Home Panels")
    public static let RemoveBookmarkContextMenuTitle = MZLocalizedString(
        key: "HomePanel.ContextMenu.RemoveBookmark",
        tableName: nil,
        value: "Remove Bookmark",
        comment: "The title for the Remove Bookmark context menu action for sites in Home Panels")
    public static let DeleteFromHistoryContextMenuTitle = MZLocalizedString(
        key: "HomePanel.ContextMenu.DeleteFromHistory",
        tableName: nil,
        value: "Delete from History",
        comment: "The title for the Delete from History context menu action for sites in Home Panels")
    public static let ShareContextMenuTitle = MZLocalizedString(
        key: "HomePanel.ContextMenu.Share",
        tableName: nil,
        value: "Share",
        comment: "The title for the Share context menu action for sites in Home Panels")
    public static let RemoveContextMenuTitle = MZLocalizedString(
        key: "HomePanel.ContextMenu.Remove",
        tableName: nil,
        value: "Remove",
        comment: "The title for the Remove context menu action for sites in Home Panels")
    public static let EditContextMenuTitle = MZLocalizedString(
        key: "HomePanel.ContextMenu.Edit.v131",
        tableName: "Bookmarks",
        value: "Edit",
        comment: "The title for the Edit context menu action for sites in Home Panels")
    public static let PinTopsiteActionTitle2 = MZLocalizedString(
        key: "ActivityStream.ContextMenu.PinTopsite2",
        tableName: nil,
        value: "Pin",
        comment: "The title for the pinning a topsite action")
    public static let UnpinTopsiteActionTitle2 = MZLocalizedString(
        key: "ActivityStream.ContextMenu.UnpinTopsite",
        tableName: nil,
        value: "Unpin",
        comment: "The title for the unpinning a topsite action")
    public static let AddToShortcutsActionTitle = MZLocalizedString(
        key: "ActivityStream.ContextMenu.AddToShortcuts",
        tableName: nil,
        value: "Add to Shortcuts",
        comment: "The title for the pinning a shortcut action")
}

// MARK: - PhotonActionSheet String
extension String {
    public static let CloseButtonTitle = MZLocalizedString(
        key: "PhotonMenu.close",
        tableName: nil,
        value: "Close",
        comment: "Button for closing the menu action sheet")
}

// MARK: - Home page
extension String {
    public static let SettingsHomePageSectionName = MZLocalizedString(
        key: "Settings.HomePage.SectionName",
        tableName: nil,
        value: "Homepage",
        comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.")
    public static let SettingsHomePageURLSectionTitle = MZLocalizedString(
        key: "Settings.HomePage.URL.Title",
        tableName: nil,
        value: "Current Homepage",
        comment: "Title of the setting section containing the URL of the current home page.")
}

// MARK: - Settings
extension String {
    public static let SettingsGeneralSectionTitle = MZLocalizedString(
        key: "Settings.General.SectionName",
        tableName: nil,
        value: "General",
        comment: "General settings section title")
    public static let SettingsClearPrivateDataClearButton = MZLocalizedString(
        key: "Settings.ClearPrivateData.Clear.Button",
        tableName: nil,
        value: "Clear Private Data",
        comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearAllWebsiteDataButton = MZLocalizedString(
        key: "Settings.ClearAllWebsiteData.Clear.Button",
        tableName: nil,
        value: "Clear All Website Data",
        comment: "Button in Data Management that clears all items.")
    public static let SettingsClearSelectedWebsiteDataButton = MZLocalizedString(
        key: "Settings.ClearSelectedWebsiteData.ClearSelected.Button",
        tableName: nil,
        value: "Clear Items: %1$@",
        comment: "Button in Data Management that clears private data for the selected items. %1$@ is the number of items to be cleared.")
    public static let SettingsClearPrivateDataSectionName = MZLocalizedString(
        key: "Settings.ClearPrivateData.SectionName",
        tableName: nil,
        value: "Clear Private Data",
        comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsDataManagementSectionName = MZLocalizedString(
        key: "Settings.DataManagement.SectionName",
        tableName: nil,
        value: "Data Management",
        comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsFilterSitesSearchLabel = MZLocalizedString(
        key: "Settings.DataManagement.SearchLabel",
        tableName: nil,
        value: "Filter Sites",
        comment: "Default text in search bar for Data Management")
    public static let SettingsDataManagementTitle = MZLocalizedString(
        key: "Settings.DataManagement.Title",
        tableName: nil,
        value: "Data Management",
        comment: "Title displayed in header of the setting panel.")
    public static let SettingsWebsiteDataTitle = MZLocalizedString(
        key: "Settings.WebsiteData.Title",
        tableName: nil,
        value: "Website Data",
        comment: "Title displayed in header of the Data Management panel.")
    public static let SettingsWebsiteDataShowMoreButton = MZLocalizedString(
        key: "Settings.WebsiteData.ButtonShowMore",
        tableName: nil,
        value: "Show More",
        comment: "Button shows all websites on website data tableview")
    public static let SettingsDisconnectSyncAlertTitle = MZLocalizedString(
        key: "Settings.Disconnect.Title",
        tableName: nil,
        value: "Disconnect Sync?",
        comment: "Title of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncAlertBody = MZLocalizedString(
        key: "Settings.Disconnect.Body",
        tableName: nil,
        value: "Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.",
        comment: "Body of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncButton = MZLocalizedString(
        key: "Settings.Disconnect.Button",
        tableName: nil,
        value: "Disconnect Sync",
        comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA")
    public static let SettingsDisconnectCancelAction = MZLocalizedString(
        key: "Settings.Disconnect.CancelButton",
        tableName: nil,
        value: "Cancel",
        comment: "Cancel action button in alert when user is prompted for disconnect")
    public static let SettingsDisconnectDestructiveAction = MZLocalizedString(
        key: "Settings.Disconnect.DestructiveButton",
        tableName: nil,
        value: "Disconnect",
        comment: "Destructive action button in alert when user is prompted for disconnect")
    public static let SettingsSearchDoneButton = MZLocalizedString(
        key: "Settings.Search.Done.Button",
        tableName: nil,
        value: "Done",
        comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = MZLocalizedString(
        key: "Settings.Search.Edit.Button",
        tableName: nil,
        value: "Edit",
        comment: "Button displayed at the top of the search settings.")
    public static let SettingsCopyAppVersionAlertTitle = MZLocalizedString(
        key: "Settings.CopyAppVersion.Title",
        tableName: nil,
        value: "Copied to clipboard",
        comment: "Copy app version alert shown in settings.")
    public static let SettingsAutofillCreditCard = MZLocalizedString(
        key: "Settings.AutofillCreditCard.Title.v122",
        tableName: "Settings",
        value: "Payment Methods",
        comment: "Label used as an item in Settings screen. When touched, it will take user to credit card settings page to that will allows to add or modify saved credit cards to allow for autofill in a webpage.")
    public static let SettingsAddressAutofill = MZLocalizedString(
        key: "Settings.AddressAutofill.Title.v126",
        tableName: "Settings",
        value: "Addresses",
        comment: "Label used as an item in Settings screen. When touched, it will take user to address autofill settings page to that will allow user to add or modify saved addresses to allow for autofill in a webpage.")
}

// MARK: - Error pages
extension String {
    public static let ErrorPagesAdvancedButton = MZLocalizedString(
        key: "ErrorPages.Advanced.Button",
        tableName: nil,
        value: "Advanced",
        comment: "Label for button to perform advanced actions on the error page")
    public static let ErrorPagesAdvancedWarning1 = MZLocalizedString(
        key: "ErrorPages.AdvancedWarning1.Text",
        tableName: nil,
        value: "Warning: we can’t confirm your connection to this website is secure.",
        comment: "Warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesAdvancedWarning2 = MZLocalizedString(
        key: "ErrorPages.AdvancedWarning2.Text",
        tableName: nil,
        value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.",
        comment: "Additional warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesCertWarningDescription = MZLocalizedString(
        key: "ErrorPages.CertWarning.Description",
        tableName: nil,
        value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Firefox has not connected to this website.",
        comment: "Warning text on the certificate error page. %@ is the domain of the website.")
    public static let ErrorPagesCertWarningTitle = MZLocalizedString(
        key: "ErrorPages.CertWarning.Title",
        tableName: nil,
        value: "This Connection is Untrusted",
        comment: "Title on the certificate error page")
    public static let ErrorPagesGoBackButton = MZLocalizedString(
        key: "ErrorPages.GoBack.Button",
        tableName: nil,
        value: "Go Back",
        comment: "Label for button to go back from the error page")
    public static let ErrorPagesVisitOnceButton = MZLocalizedString(
        key: "ErrorPages.VisitOnce.Button",
        tableName: nil,
        value: "Visit site anyway",
        comment: "Button label to temporarily continue to the site from the certificate error page")
}

// MARK: - Logins Helper
extension String {
    public static let LoginsHelperSaveLoginButtonTitle = MZLocalizedString(
        key: "LoginsHelper.SaveLogin.Button.v122",
        tableName: "LoginsHelper",
        value: "Save",
        comment: "Button to save the user's password")
    public static let LoginsHelperDontSaveButtonTitle = MZLocalizedString(
        key: "LoginsHelper.DontSave.Button.v122",
        tableName: "LoginsHelper",
        value: "Not Now",
        comment: "Button to not save the user's password in the logins helper")
    public static let LoginsHelperUpdateButtonTitle = MZLocalizedString(
        key: "LoginsHelper.Update.Button",
        tableName: nil,
        value: "Update",
        comment: "Button to update the user's password")
    public static let LoginsHelperDontUpdateButtonTitle = MZLocalizedString(
        key: "LoginsHelper.DontUpdate.Button.v122",
        tableName: "LoginsHelper",
        value: "Not Now",
        comment: "Button to not update the user's password in the logins helper")
}

// MARK: - History Panel
extension String {
    public static let HistoryBackButtonTitle = MZLocalizedString(
        key: "HistoryPanel.HistoryBackButton.Title",
        tableName: nil,
        value: "History",
        comment: "Title for the Back to History button in the History Panel")
    public static let EmptySyncedTabsPanelStateTitle = MZLocalizedString(
        key: "HistoryPanel.EmptySyncedTabsState.Title",
        tableName: nil,
        value: "Firefox Sync",
        comment: "Title for the empty synced tabs state in the History Panel")
    public static let EmptySyncedTabsPanelNotSignedInStateDescription = MZLocalizedString(
        key: "HistoryPanel.EmptySyncedTabsPanelNotSignedInState.Description",
        tableName: nil,
        value: "Sign in to view a list of tabs from your other devices.",
        comment: "Description for the empty synced tabs 'not signed in' state in the History Panel")
    public static let EmptySyncedTabsPanelNullStateDescription = MZLocalizedString(
        key: "HistoryPanel.EmptySyncedTabsNullState.Description",
        tableName: nil,
        value: "Your tabs from other devices show up here.",
        comment: "Description for the empty synced tabs null state in the History Panel")
    public static let HistoryPanelEmptyStateTitle = MZLocalizedString(
        key: "HistoryPanel.EmptyState.Title",
        tableName: nil,
        value: "Websites you’ve visited recently will show up here.",
        comment: "Title for the History Panel empty state.")
    public static let RecentlyClosedTabsPanelTitle = MZLocalizedString(
        key: "RecentlyClosedTabsPanel.Title",
        tableName: nil,
        value: "Recently Closed",
        comment: "Title for the Recently Closed Tabs Panel")
    public static let FirefoxHomePage = MZLocalizedString(
        key: "Firefox.HomePage.Title",
        tableName: nil,
        value: "Firefox Home Page",
        comment: "Title for firefox about:home page in tab history list")
    public static let HistoryPanelDelete = MZLocalizedString(
        key: "Delete",
        tableName: "HistoryPanel",
        value: nil,
        comment: "Action button for deleting history entries in the history panel.")
}

// MARK: - Syncing
extension String {
    public static let SyncingMessageWithEllipsis = MZLocalizedString(
        key: "Sync.SyncingEllipsis.Label",
        tableName: nil,
        value: "Syncing…",
        comment: "Message displayed when the user's account is syncing with ellipsis at the end")

    public static let FirefoxSyncOfflineTitle = MZLocalizedString(
        key: "SyncState.Offline.Title",
        tableName: nil,
        value: "Sync is offline",
        comment: "Title for Sync status message when Sync failed due to being offline")
    public static let FirefoxSyncTroubleshootTitle = MZLocalizedString(
        key: "Settings.TroubleShootSync.Title",
        tableName: nil,
        value: "Troubleshoot",
        comment: "Title of link to help page to find out how to solve Sync issues")

    public static let FirefoxSyncBookmarksEngine = MZLocalizedString(
        key: "Bookmarks",
        tableName: nil,
        value: nil,
        comment: "Toggle bookmarks syncing setting")
    public static let FirefoxSyncHistoryEngine = MZLocalizedString(
        key: "History",
        tableName: nil,
        value: nil,
        comment: "Toggle history syncing setting")
    public static let FirefoxSyncTabsEngine = MZLocalizedString(
        key: "Open Tabs",
        tableName: nil,
        value: nil,
        comment: "Toggle tabs syncing setting")
    public static let FirefoxSyncLoginsEngine = MZLocalizedString(
        key: "Sync.LoginsEngine.Title.v122",
        tableName: "FirefoxSync",
        value: "Passwords",
        comment: "Toggle passwords syncing setting, in the Settings > Sync Data menu of the app.")
    public static let FirefoxSyncCreditCardsEngine = MZLocalizedString(
        key: "FirefoxSync.CreditCardsEngine.v122",
        tableName: "FirefoxSync",
        value: "Payment Methods",
        comment: "Toggle for credit cards syncing setting")
    public static let FirefoxSyncAddressesEngine = MZLocalizedString(
        key: "FirefoxSync.AddressAutofillEngine.v124",
        tableName: "FirefoxSync",
        value: "Addresses",
        comment: "Toggle for address autofill syncing setting")
}

// MARK: - Firefox Logins
extension String {
    // Prompts
    public static let SaveLoginUsernamePrompt = MZLocalizedString(
        key: "LoginsHelper.PromptSaveLogin.Title.v122",
        tableName: "FirefoxLogins",
        value: "Save username?",
        comment: "Prompt for saving the username in the Save Logins prompt.")
    public static let SaveLoginPrompt = MZLocalizedString(
        key: "LoginsHelper.PromptSavePassword.Title.v122",
        tableName: "FirefoxLogins",
        value: "Save password?",
        comment: "Prompt for saving a password in the Save Logins prompt.")
    public static let UpdateLoginUsernamePrompt = MZLocalizedString(
        key: "LoginsHelper.PromptUpdateLogin.Title.TwoArg.v122",
        tableName: "FirefoxLogins",
        value: "Update password?",
        comment: "Prompt for updating a password in the Update Password prompt.")
    public static let UpdateLoginPrompt = MZLocalizedString(
        key: "LoginsHelper.PromptUpdateLogin.Title.OneArg.v122",
        tableName: "FirefoxLogins",
        value: "Update password?",
        comment: "Prompt for updating the password in the Update Password prompt.")

    // Setting
    public static let SettingToShowLoginsInAppMenu = MZLocalizedString(
        key: "Settings.ShowLoginsInAppMenu.Title",
        tableName: nil,
        value: "Show in Application Menu",
        comment: "Setting to show Logins & Passwords quick access in the application menu")

    // List view
    public static let LoginsListTitle = MZLocalizedString(
        key: "LoginsList.Title.v122",
        tableName: "FirefoxLogins",
        value: "SAVED PASSWORDS",
        comment: "Title for the list of logins saved by the app")
    public static let LoginsListSearchPlaceholder = MZLocalizedString(
        key: "LoginsList.LoginsListSearchPlaceholder.v122",
        tableName: "FirefoxLogins",
        value: "Search passwords",
        comment: "Placeholder text for search box in logins list view.")

    // Breach Alerts
    public static let BreachAlertsTitle = MZLocalizedString(
        key: "BreachAlerts.Title",
        tableName: nil,
        value: "Website Breach",
        comment: "Title for the Breached Login Detail View.")
    public static let BreachAlertsLearnMore = MZLocalizedString(
        key: "BreachAlerts.LearnMoreButton",
        tableName: nil,
        value: "Learn more",
        comment: "Link to monitor.firefox.com to learn more about breached passwords")
    public static let BreachAlertsBreachDate = MZLocalizedString(
        key: "BreachAlerts.BreachDate",
        tableName: nil,
        value: "This breach occurred on",
        comment: "Describes the date on which the breach occurred")
    public static let BreachAlertsDescription = MZLocalizedString(
        key: "BreachAlerts.Description",
        tableName: nil,
        value: "Passwords were leaked or stolen since you last changed your password. To protect this account, log in to the site and change your password.",
        comment: "Description of what a breach is")
    public static let BreachAlertsLink = MZLocalizedString(
        key: "BreachAlerts.Link",
        tableName: nil,
        value: "Go to",
        comment: "Leads to a link to the breached website")

    // For the DevicePasscodeRequiredViewController
    public static let LoginsDevicePasscodeRequiredMessage = MZLocalizedString(
        key: "Logins.DevicePasscodeRequired.Message.v122",
        tableName: "Credentials",
        value: "To save and automatically fill passwords, enable Face ID, Touch ID, or a device passcode.",
        comment: "Message shown when you enter Logins & Passwords without having a device passcode set.")
    public static let PaymentMethodsDevicePasscodeRequiredMessage = MZLocalizedString(
        key: "Logins.PaymentMethods.DevicePasscodeRequired.Message.v124.v2",
        tableName: "Credentials",
        value: "To save and autofill credit cards, enable Face ID, Touch ID, or a device passcode.",
        comment: "Message shown when you enter Payment Methods without having a device passcode set.")
    public static let LoginsDevicePasscodeRequiredLearnMoreButtonTitle = MZLocalizedString(
        key: "Logins.DevicePasscodeRequired.LearnMoreButtonTitle",
        tableName: nil,
        value: "Learn More",
        comment: "Title of the Learn More button that links to a support page about device passcode requirements.")

    // For the LoginOnboardingViewController
    public static let LoginsOnboardingLearnMoreButtonTitle = MZLocalizedString(
        key: "Logins.Onboarding.LearnMoreButtonTitle",
        tableName: nil,
        value: "Learn More",
        comment: "Title of the Learn More button that links to a support page about device passcode requirements.")
    public static let LoginsOnboardingContinueButtonTitle = MZLocalizedString(
        key: "Logins.Onboarding.ContinueButtonTitle",
        tableName: nil,
        value: "Continue",
        comment: "Title of the Continue button.")
}

// MARK: - Firefox Account
extension String {
    // Settings strings
    public static let FxAFirefoxAccount = MZLocalizedString(
        key: "FxA.FirefoxAccount.v119",
        tableName: "Settings",
        value: "Account",
        comment: "Settings section title for the old Firefox account")
    public static let FxAManageAccount = MZLocalizedString(
        key: "FxA.ManageAccount",
        tableName: nil,
        value: "Manage Account & Devices",
        comment: "Button label to go to Firefox Account settings")
    public static let FxASyncNow = MZLocalizedString(
        key: "FxA.SyncNow",
        tableName: nil,
        value: "Sync Now",
        comment: "Button label to Sync your Firefox Account")
    public static let FxANoInternetConnection = MZLocalizedString(
        key: "FxA.NoInternetConnection",
        tableName: nil,
        value: "No Internet Connection",
        comment: "Label when no internet is present")
    public static let FxASettingsTitle = MZLocalizedString(
        key: "Settings.FxA.Title.v119",
        tableName: "Settings",
        value: "Account",
        comment: "Title displayed in header of the FxA settings panel.")
    public static let FxASettingsSyncSettings = MZLocalizedString(
        key: "Settings.FxA.Sync.SectionName",
        tableName: nil,
        value: "Sync Settings",
        comment: "Label used as a section title in the Firefox Accounts Settings screen.")
    public static let FxASettingsDeviceName = MZLocalizedString(
        key: "Settings.FxA.DeviceName",
        tableName: nil,
        value: "Device Name",
        comment: "Label used for the device name settings section.")

    // Surface error strings
    public static let FxAAccountVerifyPassword = MZLocalizedString(
        key: "Enter your password to connect",
        tableName: nil,
        value: nil,
        comment: "Text message in the settings table view")
}

// MARK: - New tab choice settings
extension String {
    public static let CustomNewPageURL = MZLocalizedString(
        key: "Settings.NewTab.CustomURL",
        tableName: nil,
        value: "Custom URL",
        comment: "Label used to set a custom url as the new tab option (homepage).")
    public static let SettingsNewTabSectionName = MZLocalizedString(
        key: "Settings.NewTab.SectionName",
        tableName: nil,
        value: "New Tab",
        comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behavior.")
    public static let NewTabSectionName =
    MZLocalizedString(
        key: "Settings.NewTab.TopSectionName",
        tableName: nil,
        value: "Show",
        comment: "Label at the top of the New Tab screen after entering New Tab in settings")
    public static let SettingsNewTabTitle = MZLocalizedString(
        key: "Settings.NewTab.Title",
        tableName: nil,
        value: "New Tab",
        comment: "Title displayed in header of the setting panel.")
    public static let NewTabSectionNameFooter = MZLocalizedString(
        key: "Settings.NewTab.TopSectionNameFooter",
        tableName: nil,
        value: "Choose what to load when opening a new tab",
        comment: "Footer at the bottom of the New Tab screen after entering New Tab in settings")
    public static let SettingsNewTabTopSites = MZLocalizedString(
        key: "Settings.NewTab.Option.FirefoxHome",
        tableName: nil,
        value: "Firefox Home",
        comment: "Option in settings to show Firefox Home when you open a new tab")
    public static let SettingsNewTabBlankPage = MZLocalizedString(
        key: "Settings.NewTab.Option.BlankPage",
        tableName: nil,
        value: "Blank Page",
        comment: "Option in settings to show a blank page when you open a new tab")
    public static let SettingsNewTabCustom = MZLocalizedString(
        key: "Settings.NewTab.Option.Custom",
        tableName: nil,
        value: "Custom",
        comment: "Option in settings to show your homepage when you open a new tab")
}

// MARK: - Advanced Sync Settings (Debug)
// For 'Advanced Sync Settings' view, which is a debug setting. English only, there is little value in maintaining L10N strings for these.
extension String {
    public static let SettingsAdvancedAccountTitle = "Advanced Sync Settings"
    public static let SettingsAdvancedAccountCustomFxAContentServerURI = "Custom Account Content Server URI"
    public static let SettingsAdvancedAccountUseCustomFxAContentServerURITitle = "Use Custom FxA Content Server"
    public static let SettingsAdvancedAccountUseReactContentServer = "Use React Content Server"
    public static let SettingsAdvancedAccountCustomSyncTokenServerURI = "Custom Sync Token Server URI"
    public static let SettingsAdvancedAccountUseCustomSyncTokenServerTitle = "Use Custom Sync Token Server"
}

// MARK: - Open With Settings
extension String {
    public static let SettingsOpenWithSectionName = MZLocalizedString(
        key: "Settings.OpenWith.SectionName",
        tableName: nil,
        value: "Mail App",
        comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behavior.")
    public static let SettingsOpenWithPageTitle = MZLocalizedString(
        key: "Settings.OpenWith.PageTitle",
        tableName: nil,
        value: "Open mail links with",
        comment: "Title for Open With Settings")
}

// MARK: - Third Party Search Engines
extension String {
    public static let ThirdPartySearchEngineAdded = MZLocalizedString(
        key: "Search.ThirdPartyEngines.AddSuccess",
        tableName: nil,
        value: "Added Search engine!",
        comment: "The success message that appears after a user sucessfully adds a new search engine")
    public static let ThirdPartySearchAddTitle = MZLocalizedString(
        key: "Search.ThirdPartyEngines.AddTitle",
        tableName: nil,
        value: "Add Search Provider?",
        comment: "The title that asks the user to Add the search provider")
    public static let ThirdPartySearchAddMessage = MZLocalizedString(
        key: "Search.ThirdPartyEngines.AddMessage",
        tableName: nil,
        value: "The new search engine will appear in the quick search bar.",
        comment: "The message that asks the user to Add the search provider explaining where the search engine will appear")
    public static let ThirdPartySearchCancelButton = MZLocalizedString(
        key: "Search.ThirdPartyEngines.Cancel",
        tableName: nil,
        value: "Cancel",
        comment: "The cancel button if you do not want to add a search engine.")
    public static let ThirdPartySearchOkayButton = MZLocalizedString(
        key: "Search.ThirdPartyEngines.OK",
        tableName: nil,
        value: "OK",
        comment: "The confirmation button")
    public static let ThirdPartySearchFailedTitle = MZLocalizedString(
        key: "Search.ThirdPartyEngines.FailedTitle",
        tableName: nil,
        value: "Failed",
        comment: "A title explaining that we failed to add a search engine")
    public static let ThirdPartySearchFailedMessage = MZLocalizedString(
        key: "Search.ThirdPartyEngines.FailedMessage",
        tableName: nil,
        value: "The search provider could not be added.",
        comment: "A title explaining that we failed to add a search engine")
    public static let CustomEngineFormErrorTitle = MZLocalizedString(
        key: "Search.ThirdPartyEngines.FormErrorTitle",
        tableName: nil,
        value: "Failed",
        comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineFormErrorMessage = MZLocalizedString(
        key: "Search.ThirdPartyEngines.FormErrorMessage",
        tableName: nil,
        value: "Please fill all fields correctly.",
        comment: "A message explaining fault in custom search engine form.")
    public static let CustomEngineDuplicateErrorTitle = MZLocalizedString(
        key: "Search.ThirdPartyEngines.DuplicateErrorTitle",
        tableName: nil,
        value: "Failed",
        comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineDuplicateErrorMessage = MZLocalizedString(
        key: "Search.ThirdPartyEngines.DuplicateErrorMessage",
        tableName: nil,
        value: "A search engine with this title or URL has already been added.",
        comment: "A message explaining fault in custom search engine form.")
}

// MARK: - Root Bookmarks folders
extension String {
    public static let LegacyBookmarksFolderTitleMobile = MZLocalizedString(
        key: "Mobile Bookmarks",
        tableName: "Storage",
        value: nil,
        comment: "The legacy title of the folder that contains mobile bookmarks.")
    public static let BookmarksFolderTitleMobile = MZLocalizedString(
        key: "Bookmarks",
        tableName: "Storage",
        value: nil,
        comment: "The title of the folder that contains mobile bookmarks.")
    public static let BookmarksFolderTitleMenu = MZLocalizedString(
        key: "Bookmarks Menu",
        tableName: "Storage",
        value: nil,
        comment: "The name of the folder that contains desktop bookmarks in the menu.")
    public static let BookmarksFolderTitleToolbar = MZLocalizedString(
        key: "Bookmarks Toolbar",
        tableName: "Storage",
        value: nil,
        comment: "The name of the folder that contains desktop bookmarks in the toolbar.")
    public static let BookmarksFolderTitleUnsorted = MZLocalizedString(
        key: "Unsorted Bookmarks",
        tableName: "Storage",
        value: nil,
        comment: "The name of the folder that contains unsorted desktop bookmarks.")
}

// MARK: - Bookmark Management
extension String {
    public static let BookmarksFolder = MZLocalizedString(
        key: "Bookmarks.Folder.Label",
        tableName: nil,
        value: "Folder",
        comment: "The label to show the location of the folder where the bookmark is located")
    public static let BookmarksNewBookmark = MZLocalizedString(
        key: "Bookmarks.NewBookmark.Label",
        tableName: nil,
        value: "New Bookmark",
        comment: "The button to create a new bookmark")
    public static let BookmarksNewFolder = MZLocalizedString(
        key: "Bookmarks.NewFolder.Label",
        tableName: nil,
        value: "New Folder",
        comment: "The button to create a new folder")
    public static let BookmarksNewSeparator = MZLocalizedString(
        key: "Bookmarks.NewSeparator.Label",
        tableName: nil,
        value: "New Separator",
        comment: "The button to create a new separator")
    public static let BookmarksEditBookmark = MZLocalizedString(
        key: "Bookmarks.EditBookmark.Label",
        tableName: nil,
        value: "Edit Bookmark",
        comment: "The button to edit a bookmark")
    public static let BookmarksEdit = MZLocalizedString(
        key: "Bookmarks.Edit.Button",
        tableName: nil,
        value: "Edit",
        comment: "The button on the snackbar to edit a bookmark after adding it.")
    public static let BookmarksEditFolder = MZLocalizedString(
        key: "Bookmarks.EditFolder.Label",
        tableName: nil,
        value: "Edit Folder",
        comment: "The button to edit a folder")
    public static let BookmarksDeleteFolderWarningTitle = MZLocalizedString(
        key: "Bookmarks.DeleteFolderWarning.Title",
        tableName: "BookmarkPanelDeleteConfirm",
        value: "This folder isn’t empty.",
        comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderWarningDescription = MZLocalizedString(
        key: "Bookmarks.DeleteFolderWarning.Description",
        tableName: "BookmarkPanelDeleteConfirm",
        value: "Are you sure you want to delete it and its contents?",
        comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderCancelButtonLabel = MZLocalizedString(
        key: "Bookmarks.DeleteFolderWarning.CancelButton.Label",
        tableName: "BookmarkPanelDeleteConfirm",
        value: "Cancel",
        comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
    public static let BookmarksDeleteFolderDeleteButtonLabel = MZLocalizedString(
        key: "Bookmarks.DeleteFolderWarning.DeleteButton.Label",
        tableName: "BookmarkPanelDeleteConfirm",
        value: "Delete",
        comment: "Button label for the button that deletes a folder and all of its children.")
    public static let BookmarksPanelDeleteTableAction = MZLocalizedString(
        key: "Delete",
        tableName: "BookmarkPanel",
        value: nil,
        comment: "Action button for deleting bookmarks in the bookmarks panel.")
    public static let BookmarkDetailFieldTitle = MZLocalizedString(
        key: "Bookmark.DetailFieldTitle.Label",
        tableName: nil,
        value: "Title",
        comment: "The label for the Title field when editing a bookmark")
    public static let BookmarkDetailFieldURL = MZLocalizedString(
        key: "Bookmark.DetailFieldURL.Label",
        tableName: nil,
        value: "URL",
        comment: "The label for the URL field when editing a bookmark")
}

// MARK: - Tab tray (chronological tabs)
extension String {
    public static let TabTrayV2Title = MZLocalizedString(
        key: "TabTray.Title",
        tableName: nil,
        value: "Open Tabs",
        comment: "The title for the tab tray")

    // Segmented Control tites for iPad
    public static let TabTraySegmentedControlTitlesTabs = MZLocalizedString(
        key: "TabTray.SegmentedControlTitles.Tabs",
        tableName: nil,
        value: "Tabs",
        comment: "The title on the button to look at regular tabs.")
    public static let TabTraySegmentedControlTitlesPrivateTabs = MZLocalizedString(
        key: "TabTray.SegmentedControlTitles.PrivateTabs",
        tableName: nil,
        value: "Private",
        comment: "The title on the button to look at private tabs.")
    public static let TabTraySegmentedControlTitlesSyncedTabs = MZLocalizedString(
        key: "TabTray.SegmentedControlTitles.SyncedTabs",
        tableName: nil,
        value: "Synced",
        comment: "The title on the button to look at synced tabs.")
}

// MARK: - Clipboard Toast
extension String {
    public static let GoToCopiedLink = MZLocalizedString(
        key: "ClipboardToast.GoToCopiedLink.Title",
        tableName: nil,
        value: "Go to copied link?",
        comment: "Message displayed when the user has a copied link on the clipboard")
    public static let GoButtonTittle = MZLocalizedString(
        key: "ClipboardToast.GoToCopiedLink.Button",
        tableName: nil,
        value: "Go",
        comment: "The button to open a new tab with the copied link")

    public static let SettingsOfferClipboardBarTitle = MZLocalizedString(
        key: "Settings.OfferClipboardBar.Title",
        tableName: nil,
        value: "Offer to Open Copied Links",
        comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
    public static let SettingsOfferClipboardBarStatus = MZLocalizedString(
        key: "Settings.OfferClipboardBar.Status.v128",
        tableName: nil,
        value: "When opening %@",
        comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349. %@ is for the app name.")
}

// MARK: - Link Previews
extension String {
    public static let SettingsShowLinkPreviewsTitle = MZLocalizedString(
        key: "Settings.ShowLinkPreviews.Title",
        tableName: nil,
        value: "Show Link Previews",
        comment: "Title of setting to enable link previews when long-pressing links.")
    public static let SettingsShowLinkPreviewsStatus = MZLocalizedString(
        key: "Settings.ShowLinkPreviews.StatusV2",
        tableName: nil,
        value: "When long-pressing links",
        comment: "Description displayed under the ”Show Link Previews” option")
}

// MARK: - Block Opening External Apps
extension String {
    public static let SettingsBlockOpeningExternalAppsTitle = MZLocalizedString(
        key: "Settings.BlockOpeningExternalApps.Title",
        tableName: nil,
        value: "Block Opening External Apps",
        comment: "Title of setting to block opening external apps when pressing links.")
}

// MARK: - Errors
extension String {
    public static let UnableToAddPassErrorTitle = MZLocalizedString(
        key: "AddPass.Error.Title",
        tableName: nil,
        value: "Failed to Add Pass",
        comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorMessage = MZLocalizedString(
        key: "AddPass.Error.Message",
        tableName: nil,
        value: "An error occured while adding the pass to Wallet. Please try again later.",
        comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorDismiss = MZLocalizedString(
        key: "AddPass.Error.Dismiss",
        tableName: nil,
        value: "OK",
        comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToOpenURLError = MZLocalizedString(
        key: "OpenURL.Error.Message",
        tableName: nil,
        value: "Firefox cannot open the page because it has an invalid address.",
        comment: "The message displayed to a user when they try to open a URL that cannot be handled by Firefox, or any external app.")
    public static let UnableToOpenURLErrorTitle = MZLocalizedString(
        key: "OpenURL.Error.Title",
        tableName: nil,
        value: "Cannot Open Page",
        comment: "Title of the message shown when the user attempts to navigate to an invalid link.")
    public static let CouldntDownloadWallpaperErrorTitle = MZLocalizedString(
        key: "Wallpaper.Download.Error.Title.v106",
        tableName: nil,
        value: "Couldn’t Download Wallpaper",
        comment: "The title of the error displayed if download fails when changing a wallpaper.")
    public static let CouldntDownloadWallpaperErrorBody = MZLocalizedString(
        key: "Wallpaper.Download.Error.Body.v106",
        tableName: nil,
        value: "Something went wrong with your download.",
        comment: "The message of the error displayed to a user when they try change a wallpaper that failed downloading.")
    public static let CouldntChangeWallpaperErrorTitle = MZLocalizedString(
        key: "Wallpaper.Change.Error.Title.v106",
        tableName: nil,
        value: "Couldn’t Change Wallpaper",
        comment: "The title of the error displayed when changing wallpaper fails.")
    public static let CouldntChangeWallpaperErrorBody = MZLocalizedString(
        key: "Wallpaper.Change.Error.Body.v106",
        tableName: nil,
        value: "Something went wrong with this wallpaper.",
        comment: "The message of the error displayed to a user when they trying to change a wallpaper failed.")
    public static let WallpaperErrorTryAgain = MZLocalizedString(
        key: "Wallpaper.Error.TryAgain.v106",
        tableName: nil,
        value: "Try Again",
        comment: "Action displayed when changing wallpaper fails.")
    public static let WallpaperErrorDismiss = MZLocalizedString(
        key: "Wallpaper.Error.Dismiss.v106",
        tableName: nil,
        value: "Cancel",
        comment: "An action for the error displayed to a user when they trying to change a wallpaper failed.")
}

// MARK: - Download Helper
extension String {
    public static let OpenInDownloadHelperAlertDownloadNow = MZLocalizedString(
        key: "Downloads.Alert.DownloadNow",
        tableName: nil,
        value: "Download Now",
        comment: "The label of the button the user will press to start downloading a file")
    public static let DownloadsButtonTitle = MZLocalizedString(
        key: "Downloads.Toast.GoToDownloads.Button",
        tableName: nil,
        value: "Downloads",
        comment: "The button to open a new tab with the Downloads home panel")
    public static let CancelDownloadDialogTitle = MZLocalizedString(
        key: "Downloads.CancelDialog.Title",
        tableName: nil,
        value: "Cancel Download",
        comment: "Alert dialog title when the user taps the cancel download icon.")
    public static let CancelDownloadDialogMessage = MZLocalizedString(
        key: "Downloads.CancelDialog.Message",
        tableName: nil,
        value: "Are you sure you want to cancel this download?",
        comment: "Alert dialog body when the user taps the cancel download icon.")
    public static let CancelDownloadDialogResume = MZLocalizedString(
        key: "Downloads.CancelDialog.Resume",
        tableName: nil,
        value: "Resume",
        comment: "Button declining the cancellation of the download.")
    public static let CancelDownloadDialogCancel = MZLocalizedString(
        key: "Downloads.CancelDialog.Cancel",
        tableName: nil,
        value: "Cancel",
        comment: "Button confirming the cancellation of the download.")
    public static let DownloadCancelledToastLabelText = MZLocalizedString(
        key: "Downloads.Toast.Cancelled.LabelText",
        tableName: nil,
        value: "Download Cancelled",
        comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.")
    public static let DownloadFailedToastLabelText = MZLocalizedString(
        key: "Downloads.Toast.Failed.LabelText",
        tableName: nil,
        value: "Download Failed",
        comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.")
    public static let DownloadMultipleFilesToastDescriptionText = MZLocalizedString(
        key: "Downloads.Toast.MultipleFiles.DescriptionText",
        tableName: nil,
        value: "1 of %d files",
        comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading. %d is the total number of files.")
    public static let DownloadProgressToastDescriptionText = MZLocalizedString(
        key: "Downloads.Toast.Progress.DescriptionText",
        tableName: nil,
        value: "%1$@/%2$@",
        comment: "The description text in the Download progress toast for showing the downloaded file size (%1$@) out of the total expected file size (%2$@).")
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = MZLocalizedString(
        key: "Downloads.Toast.MultipleFilesAndProgress.DescriptionText",
        tableName: nil,
        value: "%1$@ %2$@",
        comment: "The description text in the Download progress toast for showing the number of files (%1$@) and download progress (%2$@). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where %1$@ is Downloads.Toast.MultipleFiles.DescriptionText and %2$@ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and %1$@ should come before %2$@ everywhere except for right-to-left locales.")
}

// MARK: - Add Custom Search Engine
extension String {
    public static let SettingsAddCustomEngine = MZLocalizedString(
        key: "Settings.AddCustomEngine",
        tableName: nil,
        value: "Add Search Engine",
        comment: "The button text in Search Settings that opens the Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitle = MZLocalizedString(
        key: "Settings.AddCustomEngine.Title",
        tableName: nil,
        value: "Add Search Engine",
        comment: "The title of the  Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitleLabel = MZLocalizedString(
        key: "Settings.AddCustomEngine.TitleLabel",
        tableName: nil,
        value: "Title",
        comment: "The title for the field which sets the title for a custom search engine.")
    public static let SettingsAddCustomEngineURLLabel = MZLocalizedString(
        key: "Settings.AddCustomEngine.URLLabel",
        tableName: nil,
        value: "URL",
        comment: "The title for URL Field")
    public static let SettingsAddCustomEngineTitlePlaceholder = MZLocalizedString(
        key: "Settings.AddCustomEngine.TitlePlaceholder",
        tableName: nil,
        value: "Search Engine",
        comment: "The placeholder for Title Field when saving a custom search engine.")
    public static let SettingsAddCustomEngineURLPlaceholder = MZLocalizedString(
        key: "Settings.AddCustomEngine.URLPlaceholder",
        tableName: nil,
        value: "URL (Replace Query with %s)",
        comment: "The placeholder for URL Field when saving a custom search engine")
    public static let SettingsAddCustomEngineSaveButtonText = MZLocalizedString(
        key: "Settings.AddCustomEngine.SaveButtonText",
        tableName: nil,
        value: "Save",
        comment: "The text on the Save button when saving a custom search engine")
}

// MARK: - Context menu ButtonToast instances.
extension String {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = MZLocalizedString(
        key: "ContextMenu.ButtonToast.NewTabOpened.LabelText.v114",
        tableName: nil,
        value: "New Tab Opened",
        comment: "The label text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewTabOpenedButtonText = MZLocalizedString(
        key: "ContextMenu.ButtonToast.NewTabOpened.ButtonText",
        tableName: nil,
        value: "Switch",
        comment: "The button text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedLabelText = MZLocalizedString(
        key: "ContextMenu.ButtonToast.NewPrivateTabOpened.LabelText.v113",
        tableName: nil,
        value: "New Private Tab Opened",
        comment: "The label text in the Button Toast for switching to a fresh New Private Tab.")
}

// MARK: - Page context menu items (i.e. links and images).
extension String {
    public static let ContextMenuOpenInNewTab = MZLocalizedString(
        key: "ContextMenu.OpenInNewTabButtonTitle",
        tableName: nil,
        value: "Open in New Tab",
        comment: "Context menu item for opening a link in a new tab")
    public static let ContextMenuOpenInNewPrivateTab = MZLocalizedString(
        key: "ContextMenu.OpenInNewPrivateTabButtonTitle",
        tableName: "PrivateBrowsing",
        value: "Open in New Private Tab",
        comment: "Context menu option for opening a link in a new private tab")

    public static let ContextMenuBookmarkLink = MZLocalizedString(
        key: "ContextMenu.BookmarkLinkButtonTitle",
        tableName: nil,
        value: "Bookmark Link",
        comment: "Context menu item for bookmarking a link URL")
    public static let ContextMenuDownloadLink = MZLocalizedString(
        key: "ContextMenu.DownloadLinkButtonTitle",
        tableName: nil,
        value: "Download Link",
        comment: "Context menu item for downloading a link URL")
    public static let ContextMenuCopyLink = MZLocalizedString(
        key: "ContextMenu.CopyLinkButtonTitle",
        tableName: nil,
        value: "Copy Link",
        comment: "Context menu item for copying a link URL to the clipboard")
    public static let ContextMenuShareLink = MZLocalizedString(
        key: "ContextMenu.ShareLinkButtonTitle",
        tableName: nil,
        value: "Share Link",
        comment: "Context menu item for sharing a link URL")
    public static let ContextMenuSaveImage = MZLocalizedString(
        key: "ContextMenu.SaveImageButtonTitle",
        tableName: nil,
        value: "Save Image",
        comment: "Context menu item for saving an image")
    public static let ContextMenuCopyImage = MZLocalizedString(
        key: "ContextMenu.CopyImageButtonTitle",
        tableName: nil,
        value: "Copy Image",
        comment: "Context menu item for copying an image to the clipboard")
    public static let ContextMenuCopyImageLink = MZLocalizedString(
        key: "ContextMenu.CopyImageLinkButtonTitle",
        tableName: nil,
        value: "Copy Image Link",
        comment: "Context menu item for copying an image URL to the clipboard")
}

// MARK: - Photo Library access
extension String {
    public static let PhotoLibraryFirefoxWouldLikeAccessTitle = MZLocalizedString(
        key: "PhotoLibrary.FirefoxWouldLikeAccessTitle",
        tableName: nil,
        value: "Firefox would like to access your Photos",
        comment: "See http://mzl.la/1G7uHo7")
    public static let PhotoLibraryFirefoxWouldLikeAccessMessage = MZLocalizedString(
        key: "PhotoLibrary.FirefoxWouldLikeAccessMessage",
        tableName: nil,
        value: "This allows you to save the image to your Camera Roll.",
        comment: "See http://mzl.la/1G7uHo7")
}

// MARK: - Sent tabs notifications
// These are displayed when the app is backgrounded or the device is locked.
extension String {
    // zero tabs
    public static let SentTab_NoTabArrivingNotification_title = MZLocalizedString(
        key: "SentTab.NoTabArrivingNotification.title",
        tableName: nil,
        value: "Firefox Sync",
        comment: "Title of notification received after a spurious message from FxA has been received.")
    public static let SentTab_NoTabArrivingNotification_body =
    MZLocalizedString(
        key: "SentTab.NoTabArrivingNotification.body",
        tableName: nil,
        value: "Tap to begin",
        comment: "Body of notification received after a spurious message from FxA has been received.")

    // one or more tabs
    public static let SentTab_TabArrivingNotification_NoDevice_title = MZLocalizedString(
        key: "SentTab_TabArrivingNotification_NoDevice_title",
        tableName: nil,
        value: "Tab received",
        comment: "Title of notification shown when the device is sent one or more tabs from an unnamed device.")

    // Notification Actions
    public static let SentTabViewActionTitle = MZLocalizedString(
        key: "SentTab.ViewAction.title",
        tableName: nil,
        value: "View",
        comment: "Label for an action used to view one or more tabs from a notification.")

// MARK: - Close tab notifications
    public static let CloseTab_ArrivingNotification_title = MZLocalizedString(
        key: "CloseTab.ArrivingNotification.title.v133",
        tableName: "FxANotification",
        value: "%1$@ tabs closed: %2$@",
        comment: "Title of notification shown when a remote device has requested to close a number of tabs. %1$@ is the app name (e.g. Firefox). %2$@ is the number of tabs.")

    // Notification Actions
    public static let CloseTabViewActionTitle = MZLocalizedString(
        key: "CloseTab.ViewAction.title.v133",
        tableName: "FxANotification",
        value: "View recently closed tabs",
        comment: "Label for an action used to view recently closed tabs.")
}

// MARK: - Engagement notification
extension String {
    public struct EngagementNotification {
        public static let Title = MZLocalizedString(
            key: "Engagement.Notification.Title.v112",
            tableName: "EngagementNotification",
            value: "Start your first search",
            comment: "Title of notification sent to user after inactivity to encourage them to use the search feature.")
        public static let Body = MZLocalizedString(
            key: "Engagement.Notification.Body.v112",
            tableName: "EngagementNotification",
            value: "Find something nearby. Or discover something fun.",
            comment: "Body of notification sent to user after inactivity to encourage them to use the search feature.")

        public static let TitleTreatmentA = MZLocalizedString(
            key: "Engagement.Notification.Treatment.A.Title.v114",
            tableName: "EngagementNotification",
            value: "Browse without a trace",
            comment: "Title of notification sent to user after inactivity to encourage them to use the private browsing feature.")
        public static let BodyTreatmentA = MZLocalizedString(
            key: "Engagement.Notification.Treatment.A.Body.v114",
            tableName: "EngagementNotification",
            value: "Private browsing in %@ doesn’t save your info and blocks hidden trackers.",
            comment: "Body of notification sent to user after inactivity to encourage them to use the private browsing feature. %@ is the app name (e.g. Firefox).")

        public static let TitleTreatmentB = MZLocalizedString(
            key: "Engagement.Notification.Treatment.B.Title.v114",
            tableName: "EngagementNotification",
            value: "Try private browsing",
            comment: "Title of notification sent to user after inactivity to encourage them to use the private browsing feature.")
        public static let BodyTreatmentB = MZLocalizedString(
            key: "Engagement.Notification.Treatment.B.Body.v114",
            tableName: "EngagementNotification",
            value: "Browse with no saved cookies or history in %@.",
            comment: "Body of notification sent to user after inactivity to encourage them to use the private browsing feature. %@ is the app name (e.g. Firefox).")
    }
}

// MARK: - Notification
extension String {
    public struct Notification {
        public static let FallbackTitle = MZLocalizedString(
            key: "Notification.Fallback.Title.v113",
            tableName: "Notification",
            value: "%@ Tip",
            comment: "Fallback Title of notification if no notification title was configured. The notification is an advise to the user. %@ is the app name (e.g. Firefox).")
    }
}

// MARK: - Additional messages sent via Push from FxA
extension String {
    public static let FxAPush_DeviceDisconnected_ThisDevice_title = MZLocalizedString(
        key: "FxAPush_DeviceDisconnected_ThisDevice_title",
        tableName: nil,
        value: "Sync Disconnected",
        comment: "Title of a notification displayed when this device has been disconnected by another device.")
    public static let FxAPush_DeviceDisconnected_ThisDevice_body = MZLocalizedString(
        key: "FxAPush_DeviceDisconnected_ThisDevice_body",
        tableName: nil,
        value: "This device has been successfully disconnected from Firefox Sync.",
        comment: "Body of a notification displayed when this device has been disconnected from FxA by another device.")
    public static let FxAPush_DeviceDisconnected_title = MZLocalizedString(
        key: "FxAPush_DeviceDisconnected_title",
        tableName: nil,
        value: "Sync Disconnected",
        comment: "Title of a notification displayed when named device has been disconnected from FxA.")

    public static let FxAPush_DeviceDisconnected_UnknownDevice_body = MZLocalizedString(
        key: "FxAPush_DeviceDisconnected_UnknownDevice_body",
        tableName: nil,
        value: "A device has disconnected from Firefox Sync",
        comment: "Body of a notification displayed when unnamed device has been disconnected from FxA.")

    public static let FxAPush_DeviceConnected_title = MZLocalizedString(
        key: "FxAPush_DeviceConnected_title",
        tableName: nil,
        value: "Sync Connected",
        comment: "Title of a notification displayed when another device has connected to FxA.")
    public static let FxAPush_DeviceConnected_body = MZLocalizedString(
        key: "FxAPush_DeviceConnected_body",
        tableName: nil,
        value: "Firefox Sync has connected to %@",
        comment: "Title of a notification displayed when another device has connected to FxA. %@ refers to the name of the newly connected device.")
}

// MARK: - Reader Mode
extension String {
    public static let ReaderModeAvailableVoiceOverAnnouncement = MZLocalizedString(
        key: "ReaderMode.Available.VoiceOverAnnouncement",
        tableName: nil,
        value: "Reader Mode available",
        comment: "Accessibility message e.g. spoken by VoiceOver when Reader Mode becomes available.")
    public static let ReaderModeResetFontSizeAccessibilityLabel = MZLocalizedString(
        key: "Reset text size",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for button resetting font size in display settings of reader mode")
}

// MARK: - QR Code scanner
extension String {
    public static let ScanQRCodeViewTitle = MZLocalizedString(
        key: "ScanQRCode.View.Title",
        tableName: nil,
        value: "Scan QR Code",
        comment: "Title for the QR code scanner view.")
    public static let ScanQRCodeInstructionsLabel = MZLocalizedString(
        key: "ScanQRCode.Instructions.Label",
        tableName: nil,
        value: "Align QR code within frame to scan",
        comment: "Text for the instructions label, displayed in the QR scanner view")
    public static let ScanQRCodeInvalidDataErrorMessage = MZLocalizedString(
        key: "ScanQRCode.InvalidDataError.Message",
        tableName: nil,
        value: "The data is invalid",
        comment: "Text of the prompt that is shown to the user when the data is invalid")
    public static let ScanQRCodePermissionErrorMessage = MZLocalizedString(
        key: "ScanQRCode.PermissionError.Message.v100",
        tableName: nil,
        value: "Go to device ‘Settings’ > ‘Firefox’. Allow Firefox to access camera.",
        comment: "Text of the prompt to setup the camera authorization for the Scan QR Code feature.")
    public static let ScanQRCodeErrorOKButton = MZLocalizedString(
        key: "ScanQRCode.Error.OK.Button",
        tableName: nil,
        value: "OK",
        comment: "OK button to dismiss the error prompt.")
    public static let ScanQRCodeConfirmOpenURLMessage = MZLocalizedString(
        key: "ScanQRCode.ConfirmOpenURL.Message.v129",
        tableName: "ScanQRCode",
        value: "Allow %@ to open?",
        comment: "Text of the prompt to ask user permission to open a URL from a scanned QR code. %@ is the app name (e.g. Firefox).")
    public static let ScanQRCodeURLPromptAllowButton = MZLocalizedString(
        key: "ScanQRCode.ConfirmOpenURL.AllowButton.v129",
        tableName: "ScanQRCode",
        value: "Allow",
        comment: "Allow button to open URL from scanned QR Code")
    public static let ScanQRCodeURLPromptDenyButton = MZLocalizedString(
        key: "ScanQRCode.ConfirmOpenURL.DenyButton.v129",
        tableName: "ScanQRCode",
        value: "Deny",
        comment: "Deny button to cancel opening URL from scanned QR Code")

    public struct QRCode {
        public static let ToolbarButtonA11yLabel = MZLocalizedString(
            key: "QRCode.Toolbar.Button.A11y.Title.v128",
            tableName: "QRCode",
            value: "Scan QR code",
            comment: "Accessibility label of the QR code button in the toolbar")
    }
}

// MARK: - Main Menu
extension String {
    public struct MainMenu {
        public struct AccessibilityLabels {
            public static let OptionDisabledHint = MZLocalizedString(
                key: "MainMenu.AccessibilityLabels.OptionDisabled.Hint.v133",
                tableName: "MainMenu",
                value: "Dimmed",
                comment: "On the main menu, the accessibility label hint for any action/option inside the menu, that is disabled. For example: 'Save to Reading List' option, from Menu, in some cases is disabled and the voice over should indicate that. 'Save To Reading List dimmed'")
        }

        public struct Account {
            public static let SignedOutTitle = MZLocalizedString(
                key: "MainMenu.Account.SignedOut.Title.v131",
                tableName: "MainMenu",
                value: "Sign In",
                comment: "On the main menu, at the top, when the user is signed out. The title for the sign in action")
            public static let SignedOutDescription = MZLocalizedString(
                key: "MainMenu.Account.SignedOut.Description.v131",
                tableName: "MainMenu",
                value: "Sync passwords, tabs, and more",
                comment: "On the main menu, at the top, when the user is signed out. The description for the sign in action")
            public static let SyncErrorTitle = MZLocalizedString(
                key: "MainMenu.Account.SyncError.Title.v131",
                tableName: "MainMenu",
                value: "Sign back in to sync",
                comment: "On the main menu, at the top, when the user is signed in but there was an error syncing. The title for this state.")
            public static let SyncErrorDescription = MZLocalizedString(
                key: "MainMenu.Account.SyncError.Description.v131",
                tableName: "MainMenu",
                value: "Syncing paused",
                comment: "On the main menu, at the top, when the user is signed in but there was an error syncing. The description subtitle for the sync error state.")

            public struct AccessibilityLabels {
                public static let CloseButton = MZLocalizedString(
                    key: "MainMenu.Account.AccessibilityLabels.CloseButton.v132",
                    tableName: "MainMenu",
                    value: "Close",
                    comment: "The accessibility label for the close button in the Main menu.")
                public static let MainButton = MZLocalizedString(
                    key: "MainMenu.Account.AccessibilityLabels.MainButton.v132",
                    tableName: "MainMenu",
                    value: "Sign in to sync passwords, tabs, and more",
                    comment: "The accessibility label for the sign in button in the Main menu header view.")
                public static let BackButton = MZLocalizedString(
                    key: "MainMenu.Account.AccessibilityLabels.BackButton.v132",
                    tableName: "MainMenu",
                    value: "Back",
                    comment: "The accessibility label for the back button in the Main menu header navigation view.")
            }
        }

        public struct TabsSection {
            public static let NewTab = MZLocalizedString(
                key: "MainMenu.TabsSection.NewTab.Title.v131",
                tableName: "MainMenu",
                value: "New Tab",
                comment: "On the main menu, the title for the action that will create a new, non-private, tab.")
            public static let NewPrivateTab = MZLocalizedString(
                key: "MainMenu.TabsSection.NewPrivateTab.Title.v131",
                tableName: "MainMenu",
                value: "New Private Tab",
                comment: "On the main menu, the title for the action that will create a new private tab.")

            public struct AccessibilityLabels {
                public static let MainMenu = MZLocalizedString(
                    key: "MainMenu.TabsSection.AccessibilityLabels.MainMenu.v132",
                    tableName: "MainMenu",
                    value: "Main Menu",
                    comment: "The accessibility label for the Main Menu.")
                public static let NewTab = MZLocalizedString(
                    key: "MainMenu.TabsSection.AccessibilityLabels.NewTab.v132",
                    tableName: "MainMenu",
                    value: "New tab",
                    comment: "On the main menu, the accessibility label for the action that will create a new, non-private, tab.")
                public static let NewPrivateTab = MZLocalizedString(
                    key: "MainMenu.TabsSection.AccessibilityLabels.NewPrivateTab.v132",
                    tableName: "MainMenu",
                    value: "New private tab",
                    comment: "On the main menu, the accessibility label for the action that will create a new private tab.")
            }
        }

        public struct ToolsSection {
            public static let SwitchToDesktopSite = MZLocalizedString(
                key: "MainMenu.ToolsSection.SwitchToDesktopSite.Title.v131",
                tableName: "MainMenu",
                value: "Switch to Desktop Site",
                comment: "On the main menu, the title for the action that will switch a site from mobile version to the desktop version, if available.")
            public static let SwitchToMobileSite = MZLocalizedString(
                key: "MainMenu.ToolsSection.SwitchToMobileSite.Title.v131",
                tableName: "MainMenu",
                value: "Switch to Mobile Site",
                comment: "On the main menu, the title for the action that will switch a site from the desktop version to the mobile version.")
            public static let FindInPage = MZLocalizedString(
                key: "MainMenu.ToolsSection.FindInPage.Title.v131",
                tableName: "MainMenu",
                value: "Find in Page…",
                comment: "On the main menu, the title for the action that will bring up the Search menu, so the user can search for a word or a pharse on the current page.")
            public static let Tools = MZLocalizedString(
                key: "MainMenu.ToolsSection.ToolsSubmenu.Title.v131",
                tableName: "MainMenu",
                value: "Tools",
                comment: "On the main menu, the title for the action that will take the user to the Tools submenu in the menu.")
            public static let Save = MZLocalizedString(
                key: "MainMenu.ToolsSection.SaveSubmenu.Title.v131",
                tableName: "MainMenu",
                value: "Save",
                comment: "On the main menu, the title for the action that will take the user to the Save submenu in the menu.")

            public struct AccessibilityLabels {
                public static let SwitchToDesktopSite = MZLocalizedString(
                    key: "MainMenu.ToolsSection.AccessibilityLabels.SwitchToDesktopSite.v132",
                    tableName: "MainMenu",
                    value: "Switch to desktop site",
                    comment: "On the main menu, the accessibility label for the action that will switch a site from mobile version to the desktop version, if available.")
                public static let SwitchToMobileSite = MZLocalizedString(
                    key: "MainMenu.ToolsSection.AccessibilityLabels.SwitchToMobileSite.v132",
                    tableName: "MainMenu",
                    value: "Switch to mobile site",
                    comment: "On the main menu, the accessibility label for the action that will switch a site from the desktop version to the mobile version.")
                public static let FindInPage = MZLocalizedString(
                    key: "MainMenu.ToolsSection.AccessibilityLabels.FindInPage.v132",
                    tableName: "MainMenu",
                    value: "Find in page",
                    comment: "On the main menu, the accessibility label for the action that will bring up the Search menu, so the user can search for a word or a pharse on the current page.")
                public static let Tools = MZLocalizedString(
                    key: "MainMenu.ToolsSection.AccessibilityLabels.Tools.v133",
                    tableName: "MainMenu",
                    value: "Tools submenu",
                    comment: "On the main menu, the accessibility label for the action that will take the user to the Tools submenu in the menu.")
                public static let Save = MZLocalizedString(
                    key: "MainMenu.ToolsSection.AccessibilityLabels.Save.v133",
                    tableName: "MainMenu",
                    value: "Save submenu",
                    comment: "On the main menu, the accessibility label for the action that will take the user to the Save submenu in the menu. In the main menu, there is an option called Save that is taking the user to the Save submenu where user can share, bookmark the page and so on.")
            }
        }

        public struct PanelLinkSection {
            public static let Bookmarks = MZLocalizedString(
                key: "MainMenu.PanelLinkSection.Bookmarks.Title.v131",
                tableName: "MainMenu",
                value: "Bookmarks",
                comment: "On the main menu, the title for the action that will take the user to the Bookmarks panel.")
            public static let History = MZLocalizedString(
                key: "MainMenu.PanelLinkSection.History.Title.v131",
                tableName: "MainMenu",
                value: "History",
                comment: "On the main menu, the title for the action that will take the user to the History panel.")
            public static let Downloads = MZLocalizedString(
                key: "MainMenu.PanelLinkSection.Downloads.Title.v131",
                tableName: "MainMenu",
                value: "Downloads",
                comment: "On the main menu, the title for the action that will take the user to the Downloads panel.")
            public static let Passwords = MZLocalizedString(
                key: "MainMenu.PanelLinkSection.Passwords.Title.v131",
                tableName: "MainMenu",
                value: "Passwords",
                comment: "On the main menu, the title for the action that will take the user to the Passwords panel in the settings screen.")

            public struct AccessibilityLabels {
                 public static let Bookmarks = MZLocalizedString(
                     key: "MainMenu.PanelLinkSection.AccessibilityLabels.Bookmarks.v132",
                     tableName: "MainMenu",
                     value: "Bookmarks",
                     comment: "On the main menu, the accessibility label for the action that will take the user to the Bookmarks panel.")
                 public static let History = MZLocalizedString(
                     key: "MainMenu.PanelLinkSection.AccessibilityLabels.History.v132",
                     tableName: "MainMenu",
                     value: "History",
                     comment: "On the main menu, the accessibility label for the action that will take the user to the History panel.")
                 public static let Downloads = MZLocalizedString(
                     key: "MainMenu.PanelLinkSection.AccessibilityLabels.Downloads.v132",
                     tableName: "MainMenu",
                     value: "Downloads",
                     comment: "On the main menu, the accessibility label for the action that will take the user to the Downloads panel.")
                 public static let Passwords = MZLocalizedString(
                     key: "MainMenu.PanelLinkSection.AccessibilityLabels.Passwords.v132",
                     tableName: "MainMenu",
                     value: "Passwords",
                     comment: "On the main menu, the accessibility label for the action that will take the user to the Passwords panel in the settings screen.")
            }
        }

        public struct OtherToolsSection {
            public static let CustomizeHomepage = MZLocalizedString(
                key: "MainMenu.SettingsSection.CustomizeHomepage.Title.v131",
                tableName: "MainMenu",
                value: "Customize Homepage",
                comment: "On the main menu, the title for the action that will take the user to the Customize Hopegape section in the settings screen.")
            public static let WhatsNew = MZLocalizedString(
                key: "MainMenu.SettingsSection.WhatsNew.Title.v131",
                tableName: "MainMenu",
                value: "New in %@",
                comment: "On the main menu, the title for the action that will take the user to a What's New in Firefox popup. %@ is the app name (e.g. Firefox).")
            public static let Settings = MZLocalizedString(
                key: "MainMenu.SettingsSection.Settings.Title.v131",
                tableName: "MainMenu",
                value: "Settings",
                comment: "On the main menu, the title for the action that will take the user to the Settings menu.")
            public static let GetHelp = MZLocalizedString(
                key: "MainMenu.SettingsSection.GetHelp.Title.v131",
                tableName: "MainMenu",
                value: "Get Help",
                comment: "On the main menu, the title for the action that will take the user to a website to get help from Mozilla.")

            public struct AccessibilityLabels {
                public static let CustomizeHomepage = MZLocalizedString(
                    key: "MainMenu.SettingsSection.AccessibilityLabels.CustomizeHomepage.v132",
                    tableName: "MainMenu",
                    value: "Customize Homepage",
                    comment: "On the main menu, the accessibility labels for the action that will take the user to the Customize Homepage section in the settings screen.")
                public static let WhatsNew = MZLocalizedString(
                    key: "MainMenu.SettingsSection.AccessibilityLabels.WhatsNew.v132",
                    tableName: "MainMenu",
                    value: "New in %@",
                    comment: "On the main menu, the accessibility labels for the action that will take the user to a What's New in Firefox popup. %@ is the app name (e.g. Firefox).")
                public static let Settings = MZLocalizedString(
                    key: "MainMenu.SettingsSection.AccessibilityLabels.Settings.v132",
                    tableName: "MainMenu",
                    value: "Settings",
                    comment: "On the main menu, the accessibility labels for the action that will take the user to the Settings menu.")
                public static let GetHelp = MZLocalizedString(
                    key: "MainMenu.SettingsSection.AccessibilityLabels.GetHelp.v132",
                    tableName: "MainMenu",
                    value: "Get Help",
                    comment: "On the main menu, the accessibility labels for the action that will take the user to a website to get help from Mozilla.")
            }
        }

        public struct Submenus {
            public struct Tools {
                public static let Zoom = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.Zoom.Title.v131",
                    tableName: "MainMenu",
                    value: "Zoom (%@)",
                    comment: "On the main menu, in the tools submenu, the title for the menu component that indicates the current zoom level. %@ is the current zoom level percentage. ")
                public static let ZoomSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.Zoom.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Zoom",
                    comment: "On the main menu, a string below the Tool submenu title, indicating what kind of tools are available in that menu. This string is for the Zoom tool.")
                public static let ZoomNegativeSymbol = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.Zoom.NegativeSymbol.v137",
                    tableName: "MainMenu",
                    value: "-",
                    comment: "This string is for the Zoom tool, when Zoom value is negative. (-50%)")
                public static let ZoomPositiveSymbol = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.Zoom.PositiveSymbol.v137",
                    tableName: "MainMenu",
                    value: "+",
                    comment: "This string is for the Zoom tool, when Zoom value is positive. (+125%)")
                public static let ReaderViewOn = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.ReaderView.On.Title.v131",
                    tableName: "MainMenu",
                    value: "Turn on Reader View",
                    comment: "On the main menu, the title for the action that will turn the reader view on for the current website.")
                public static let ReaderViewOff = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.ReaderView.Off.Title.v131",
                    tableName: "MainMenu",
                    value: "Turn off Reader View",
                    comment: "On the main menu, the title for the action that will turn the reader view on for the current website.")
                public static let ReaderViewSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.ReaderView.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Reader View",
                    comment: "On the main menu, a string below the Tool submenu tiitle, indicating what kind of tools are available in that menu. This string is for the Reader View tool.")

                public static let WebsiteDarkModeOn = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.WebsiteDarkMode.On.Title.v137",
                    tableName: "MainMenu",
                    value: "Turn on Website Dark Mode",
                    comment: "On the main menu, the title for the action that will turn Website's Dark Mode on in the application.")
                public static let WebsiteDarkModeOff = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.WebsiteDarkMode.Off.Title.v137",
                    tableName: "MainMenu",
                    value: "Turn off Website Dark Mode",
                    comment: "On the main menu, the title for the action that will turn Website's Dark Mode off in the application.")

                public static let NightModeOn = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.NightMode.On.Title.v131",
                    tableName: "MainMenu",
                    value: "Turn on Night Mode",
                    comment: "On the main menu, the title for the action that will turn Night Mode on in the application.")
                public static let NightModeOff = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.NightMode.Off.Title.v131",
                    tableName: "MainMenu",
                    value: "Turn off Night Mode",
                    comment: "On the main menu, the title for the action that will turn Night Mode off in the application.")
                public static let NightModeSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.NightMode.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Night Mode",
                    comment: "On the main menu, a string below the Tool submenu tiitle, indicating what kind of tools are available in that menu. This string is for the Night Mode tool.")
                public static let Print = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.Print.Title.v131",
                    tableName: "MainMenu",
                    value: "Print",
                    comment: "On the main menu, the title for the action that will take the user to the Print module in the application.")
                public static let PrintSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.Print.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Print",
                    comment: "On the main menu, a string below the Tool submenu tiitle, indicating what kind of tools are available in that menu. This string is for the Report Print tool.")
                public static let Share = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.Share.Title.v131",
                    tableName: "MainMenu",
                    value: "Share",
                    comment: "On the main menu, the title for the action that will take the user to the Share module in the application.")
                public static let ShareSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.Share.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Share",
                    comment: "On the main menu, a string below the Tool submenu tiitle, indicating what kind of tools are available in that menu. This string is for the Report Share tool.")
                public static let ReportBrokenSite = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.ReportBrokenSite.Title.v133",
                    tableName: "MainMenu",
                    value: "Report Broken Site…",
                    comment: "On the main menu, the title for the action that will take the user to the site where they can report a broken website to our web compatibility team.")
                public static let ReportBrokenSiteSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Tools.ReportBrokenSite.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Report",
                    comment: "On the main menu, a string below the Tool submenu tiitle, indicating what kind of tools are available in that menu. This string is for the Report Broken Site tool.")

                public struct AccessibilityLabels {
                    public static let Zoom = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.Zoom.Title.v132",
                        tableName: "MainMenu",
                        value: "Zoom (%@)",
                        comment: "On the main menu, in the tools submenu, the accessibility label for the menu component that indicates the current zoom level. %@ is the current zoom level percentage. ")
                    public static let ZoomSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.Zoom.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Zoom",
                        comment: "On the main menu, a string below the Tool submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Zoom tool and is indicating that under the Tools submenu, a Zoom (apply zoom on a page) action is available.")
                    public static let ReaderViewOn = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.ReaderView.On.Title.v132",
                        tableName: "MainMenu",
                        value: "Turn on Reader View",
                        comment: "On the main menu, the accessibility label for the action that will turn the reader view on for the current website.")
                    public static let ReaderViewOff = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.ReaderView.Off.Title.v132",
                        tableName: "MainMenu",
                        value: "Turn off Reader View",
                        comment: "On the main menu, the accessibility label for the action that will turn the reader view on for the current website.")
                    public static let ReaderViewSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.ReaderView.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Reader View",
                        comment: "On the main menu, a string below the Tool submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Reader View tool.")
                    public static let NightModeOn = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.NightMode.On.Title.v132",
                        tableName: "MainMenu",
                        value: "Turn on Night Mode",
                        comment: "On the main menu, the accessibility label for the action that will turn Night Mode on in the application.")
                    public static let NightModeOff = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.NightMode.Off.Title.v132",
                        tableName: "MainMenu",
                        value: "Turn off Night Mode",
                        comment: "On the main menu, the accessibility label for the action that will turn Night Mode off in the application.")
                    public static let NightModeSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.NightMode.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Night Mode",
                        comment: "On the main menu, a string below the Tool submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Night Mode tool.")
                    public static let Print = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.Print.Title.v132",
                        tableName: "MainMenu",
                        value: "Print",
                        comment: "On the main menu, the accessibility label for the action that will take the user to the Print module in the application.")
                    public static let PrintSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.Print.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Print",
                        comment: "On the main menu, a string below the Tool submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Report Print tool.")
                    public static let Share = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.Share.Title.v132",
                        tableName: "MainMenu",
                        value: "Share",
                        comment: "On the main menu, the accessibility label for the action (Share with others) that will take the user/open (to) the Share submenu.")
                    public static let ShareSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.Share.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Share",
                        comment: "On the main menu, a string below the Tool submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Share tool and is indicating that under the Tools submenu, a Share (to someone else) action is available.")
                    public static let ReportBrokenSite = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.ReportBrokenSite.Title.v132",
                        tableName: "MainMenu",
                        value: "Report Broken Site",
                        comment: "On the main menu, the accessibility label for the action that will take the user to the site where they can report a broken website to our web compatibility team.")
                    public static let ReportBrokenSiteSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Tools.AccessibilityLabels.ReportBrokenSite.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Report",
                        comment: "On the main menu, a string below the Tool submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Report Broken Site tool and is indicating that under the Tools submenu, a Report (Report Broken Site) action is available.")
                }
            }

            public struct Save {
                public static let BookmarkThisPage = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.BookmarkThisPage.Title.v131",
                    tableName: "MainMenu",
                    value: "Bookmark This Page",
                    comment: "On the main menu, in the Save submenu, the title for the menu component that allows a user to save a bookmark for this particular page..")
                public static let BookmarkThisPageSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.BookmarkThisPage.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Add Bookmark",
                    comment: "On the main menu, a string below the Save submenu title, indicating what kind of tools are available in that menu. This string is for the Bookmarks tool.")
                public static let EditBookmark = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.EditBookmark.Title.v131",
                    tableName: "MainMenu",
                    value: "Edit Bookmark",
                    comment: "On the main menu, in the Save submenu, the title for the menu component that allows a user to edit the bookmark for this particular page.")
                public static let AddToShortcuts = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.AddToShortcuts.Title.v131",
                    tableName: "MainMenu",
                    value: "Add to Shortcuts",
                    comment: "On the main menu, in the Save submenu, the title for the menu component that allows a user to add the current website to the shortcuts on the homepage.")
                public static let RemoveFromShortcuts = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.RemoveFromShortcuts.Title.v131",
                    tableName: "MainMenu",
                    value: "Remove from Shortcuts",
                    comment: "On the main menu, in the Save submenu, the title for the menu component that allows a user to remove the current website from the shortcuts on the homepage.")
                public static let AddToShortcutsSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.AddToShortcuts.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Shortcut",
                    comment: "On the main menu, a string below the Save submenu title, indicating what kind of tools are available in that menu. This string is for the Shortcuts tool.")
                public static let AddToHomeScreen = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.AddToHomeScreen.Title.v131",
                    tableName: "MainMenu",
                    value: "Add to Home Screen",
                    comment: "On the main menu, in the Save submenu, the title for the menu component that allows a user to add a website to the home screen.")
                public static let AddToHomeScreenSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.AddToHomeScreen.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Home",
                    comment: "On the main menu, a string below the Save submenu title, indicating what kind of tools are available in that menu. This string is for the Add to Homescreen tool.")
                public static let SaveToReadingList = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.SaveToReadingList.Title.v131",
                    tableName: "MainMenu",
                    value: "Save to Reading List",
                    comment: "On the main menu, in the Save submenu, the title for the menu component that allows the user to add this site to the reading list.")
                public static let RemoveFromReadingList = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.RemoveFromReadingList.Title.v131",
                    tableName: "MainMenu",
                    value: "Remove from Reading List",
                    comment: "On the main menu, in the Save submenu, the title for the menu component that allows the user to remove this site from the reading list.")
                public static let SaveToReadingListSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.SaveToReadingList.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "Reading List",
                    comment: "On the main menu, a string below the Save submenu title, indicating what kind of tools are available in that menu. This string is for the Reading List tool.")
                public static let SaveAsPDF = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.SaveAsPDF.Title.v131",
                    tableName: "MainMenu",
                    value: "Save as PDF",
                    comment: "On the main menu, in the Save submenu, the title for the menu component that allows the user to use the Save to PDF tool.")
                public static let SaveAsPDFSubtitle = MZLocalizedString(
                    key: "MainMenu.Submenus.Save.SaveAsPDF.Subtitle.v131",
                    tableName: "MainMenu",
                    value: "PDF",
                    comment: "On the main menu, a string below the Save submenu title, indicating what kind of tools are available in that menu. This string is for the Save as PDF tool.")

                public struct AccessibilityLabels {
                    public static let BookmarkThisPage = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.BookmarkThisPage.Title.v132",
                        tableName: "MainMenu",
                        value: "Bookmark This Page",
                        comment: "On the main menu, in the Save submenu, the accessibility label for the menu component that allows a user to save a bookmark for this particular page..")
                    public static let BookmarkThisPageSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.BookmarkThisPage.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Add Bookmark",
                        comment: "On the main menu, a string below the Save submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Bookmarks tool.")
                    public static let EditBookmark = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.EditBookmark.Title.v132",
                        tableName: "MainMenu",
                        value: "Edit Bookmark",
                        comment: "On the main menu, in the Save submenu, the accessibility label for the menu component that allows a user to edit the bookmark for this particular page.")
                    public static let AddToShortcuts = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.AddToShortcuts.Title.v132",
                        tableName: "MainMenu",
                        value: "Add to Shortcuts",
                        comment: "On the main menu, in the Save submenu, the accessibility label for the menu component that allows a user to add the current website to the shortcuts on the homepage.")
                    public static let RemoveFromShortcuts = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.RemoveFromShortcuts.Title.v132",
                        tableName: "MainMenu",
                        value: "Remove from Shortcuts",
                        comment: "On the main menu, in the Save submenu, the accessibility label for the menu component that allows a user to remove the current website from the shortcuts on the homepage.")
                    public static let AddToShortcutsSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.AddToShortcuts.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Shortcut",
                        comment: "On the main menu, a string below the Save submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Shortcuts tool.")
                    public static let AddToHomeScreen = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.AddToHomeScreen.Title.v132",
                        tableName: "MainMenu",
                        value: "Add to Home Screen",
                        comment: "On the main menu, in the Save submenu, the accessibility label for the menu component that allows a user to add a website to the iOS home screen.")
                    public static let AddToHomeScreenSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.AddToHomeScreen.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Home",
                        comment: "On the main menu, a string below the Save submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Add to Home screen tool for iOS Home screen.")
                    public static let SaveToReadingList = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.SaveToReadingList.Title.v132",
                        tableName: "MainMenu",
                        value: "Save to Reading List",
                        comment: "On the main menu, in the Save submenu, the accessibility label for the menu component that allows the user to add this site to the reading list.")
                    public static let RemoveFromReadingList = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.RemoveFromReadingList.Title.v132",
                        tableName: "MainMenu",
                        value: "Remove from Reading List",
                        comment: "On the main menu, in the Save submenu, the accessibility label for the menu component that allows the user to remove this site from the reading list.")
                    public static let SaveToReadingListSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.SaveToReadingList.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "Reading List",
                        comment: "On the main menu, a string below the Save submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Reading List tool.")
                    public static let SaveAsPDF = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.SaveAsPDF.Title.v132",
                        tableName: "MainMenu",
                        value: "Save as PDF",
                        comment: "On the main menu, in the Save submenu, the title for the menu component that allows the user to use the Save to PDF tool.")
                    public static let SaveAsPDFSubtitle = MZLocalizedString(
                        key: "MainMenu.Submenus.Save.AccessibilityLabels.SaveAsPDF.Subtitle.v132",
                        tableName: "MainMenu",
                        value: "PDF",
                        comment: "On the main menu, a string below the Save submenu accessibility label, indicating what kind of tools are available in that menu. This string is for the Save as PDF tool.")
                }
            }
        }
    }

    // MARK: - Unified Search
    public struct UnifiedSearch {
        public struct SearchEngineSelection {
            public static let TopTitle = MZLocalizedString(
                key: "UnifiedSearch.SearchEngineSelection.TopTitle.Title.v133",
                tableName: "SearchEngineSelection",
                value: "This time search in:",
                comment: "When the user taps the search engine icon in the toolbar, a sheet with a list of alternative search engines appears. This is the title for the sheet.")

            public static let SearchSettings = MZLocalizedString(
                key: "UnifiedSearch.SearchEngineSelection.SearchSettings.Title.v133",
                tableName: "SearchEngineSelection",
                value: "Search Settings",
                comment: "When the user taps the search engine icon in the toolbar, a sheet with a list of alternative search engines appears. This string is the label for the button at the bottom of the list. When this row is tapped, the app's search settings screen appears.")

            public struct AccessibilityLabels {
                public static let TopTitleLabel = MZLocalizedString(
                    key: "UnifiedSearch.SearchEngineSelection.AccessibilityLabels.TopTitle.Label.v133",
                    tableName: "SearchEngineSelection",
                    value: "This time search in:",
                    comment: "When the user taps the search engine icon in the toolbar, a sheet with a list of alternative search engines appears. This is the accessibility label for the title of that sheet.")

                public static let SearchSettingsLabel = MZLocalizedString(
                    key: "UnifiedSearch.SearchEngineSelection.AccessibilityLabels.SearchSettings.Label.v133",
                    tableName: "SearchEngineSelection",
                    value: "Search settings",
                    comment: "When the user taps the search engine icon in the toolbar, a sheet with a list of alternative search engines appears. This string is the label for the row at the bottom of the list. When this row is tapped, the app's search settings screen appears.")

                public static let SearchSettingsHint = MZLocalizedString(
                    key: "UnifiedSearch.SearchEngineSelection.AccessibilityLabels.SearchSettings.Hint.v133",
                    tableName: "SearchEngineSelection",
                    value: "Opens search settings",
                    comment: "When the user taps the search engine icon in the toolbar, a sheet with a list of alternative search engines appears. This is the accessibility hint for tapping the search settings row at the bottom of the list, which opens the app's search settings screen.")

                public static let CloseButtonLabel = MZLocalizedString(
                    key: "UnifiedSearch.SearchEngineSelection.AccessibilityLabels.CloseButton.Label.v133",
                    tableName: "SearchEngineSelection",
                    value: "Close",
                    comment: "When the user taps the search engine icon in the toolbar, a sheet with a list of alternative search engines appears. This is the accessibility label for the sheet's close button.")
            }
        }
    }

    // MARK: - Sent from Firefox / Share Link Experiment
    public struct SentFromFirefox {
        public struct SocialMediaApp {
            public static let WhatsApp = MZLocalizedString(
                key: "SentFromFirefox.SocialMediaApp.WhatsApp.Title.v134",
                tableName: "SocialMediaApp",
                value: "WhatsApp",
                comment: "The name of WhatsApp, a popular instant messaging and video calling app.")
        }

        public struct SocialShare {
            public static let ShareMessageA = MZLocalizedString(
                key: "SentFromFirefox.SocialShare.ShareMessageA.Title.v137",
                tableName: "SocialShare",
                value: "%1$@\n\nSent from %2$@ 🦊 Try the mobile browser: %3$@",
                comment: "When a user shares a link to social media, this is the shared text they'll see in the social media app. %1$@  is the shared website's URL. %2$@ is the app name (e.g. Firefox). %3$@ is the link to download the app. The '\n' symbols denote empty lines separating the first link parameter from the rest of the text. ")

            public static let ShareMessageB = MZLocalizedString(
                key: "SentFromFirefox.SocialShare.ShareMessageB.Title.v137",
                tableName: "SocialShare",
                value: "%1$@\n\nSent from %2$@ 🦊 %3$@",
                comment: "When a user shares a link to social media, this is the shared text they'll see in the social media app. %1$@  is the shared website's URL. %2$@ is the app name (e.g. Firefox). %3$@ is the link to download the app. The '\n' symbols denote empty lines separating the first link parameter from the rest of the text.")

            public static let SocialSettingsToggleTitle = MZLocalizedString(
                key: "SentFromFirefox.SocialShare.SettingsToggle.Title.v134",
                tableName: "SocialShare",
                value: "Include %1$@ Download Link on %2$@ Shares",
                comment: "On the Settings screen, this is the title text for a toggle which controls adding additional text to links shared to social media apps. %1$@ is the app name (e.g. Firefox). %2$@ is the social media app name (e.g. WhatsApp).")

            public static let SocialSettingsToggleSubtitle = MZLocalizedString(
                key: "SentFromFirefox.SocialShare.SettingsToggle.Subtitle.v134",
                tableName: "SocialShare",
                value: "Spread the word about %1$@ every time you share a link on %2$@.",
                comment: "On the Settings screen, this is the subtitle text for a toggle which controls adding additional text to links shared to social media apps. %1$@ is the app name (e.g. Firefox). %2$@ is the social media app name (e.g. WhatsApp).")
        }
    }

    // MARK: - LegacyAppMenu
    // These strings may still be in use, thus have not been moved to the `OldStrings` struct
    public struct LegacyAppMenu {
        public static let AppMenuReportSiteIssueTitleString = MZLocalizedString(
            key: "Menu.ReportSiteIssueAction.Title",
            tableName: "Menu",
            value: "Report Site Issue",
            comment: "Label for the button, displayed in the menu, used to report a compatibility issue with the current page.")
        public static let AppMenuSharePageTitleString = MZLocalizedString(
            key: "Menu.SharePageAction.Title",
            tableName: "Menu",
            value: "Share Page With…",
            comment: "Label for the button, displayed in the menu, used to open the share dialog.")
        public static let AppMenuCopyLinkTitleString = MZLocalizedString(
            key: "Menu.CopyLink.Title",
            tableName: "Menu",
            value: "Copy Link",
            comment: "Label for the button, displayed in the menu, used to copy the current page link to the clipboard.")
        public static let AppMenuFindInPageTitleString = MZLocalizedString(
            key: "Menu.FindInPageAction.Title",
            tableName: "Menu",
            value: "Find in Page",
            comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
        public static let AppMenuViewDesktopSiteTitleString = MZLocalizedString(
            key: "Menu.ViewDekstopSiteAction.Title",
            tableName: "Menu",
            value: "Request Desktop Site",
            comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
        public static let AppMenuViewMobileSiteTitleString = MZLocalizedString(
            key: "Menu.ViewMobileSiteAction.Title",
            tableName: "Menu",
            value: "Request Mobile Site",
            comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
        public static let AppMenuCloseAllTabsTitleString = MZLocalizedString(
            key: "Menu.CloseAllTabsAction.Title",
            tableName: "Menu",
            value: "Close All Tabs",
            comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")

        public static let AppMenuSettingsTitleString = MZLocalizedString(
            key: "Menu.OpenSettingsAction.Title",
            tableName: "Menu",
            value: "Settings",
            comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
        public static let AppMenuOpenHomePageTitleString = MZLocalizedString(
            key: "SettingsMenu.OpenHomePageAction.Title",
            tableName: "Menu",
            value: "Homepage",
            comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
        public static let AppMenuBookmarksTitleString = MZLocalizedString(
            key: "Menu.OpenBookmarksAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Bookmarks",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel.")
        public static let AppMenuReadingListTitleString = MZLocalizedString(
            key: "Menu.OpenReadingListAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Reading List",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel.")
        public static let AppMenuHistoryTitleString = MZLocalizedString(
            key: "Menu.OpenHistoryAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "History",
            comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel.")
        public static let AppMenuDownloadsTitleString = MZLocalizedString(
            key: "Menu.OpenDownloadsAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Downloads",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel.")
        public static let AppMenuSyncedTabsTitleString = MZLocalizedString(
            key: "Menu.OpenSyncedTabsAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Synced Tabs",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Synced Tabs home panel.")
        public static let AppMenuTurnOnNightMode = MZLocalizedString(
            key: "Menu.NightModeTurnOn.Label2",
            tableName: nil,
            value: "Turn on Night Mode",
            comment: "Label for the button, displayed in the menu, turns on night mode.")
        public static let AppMenuTurnOffNightMode = MZLocalizedString(
            key: "Menu.NightModeTurnOff.Label2",
            tableName: nil,
            value: "Turn off Night Mode",
            comment: "Label for the button, displayed in the menu, turns off night mode.")
        public static let AppMenuHistory = MZLocalizedString(
            key: "Menu.History.Label",
            tableName: nil,
            value: "History",
            comment: "Label for the button, displayed in the menu, takes you to History screen when pressed.")
        public static let AppMenuDownloads = MZLocalizedString(
            key: "Menu.Downloads.Label",
            tableName: nil,
            value: "Downloads",
            comment: "Label for the button, displayed in the menu, takes you to Downloads screen when pressed.")
        public static let AppMenuDownloadPDF = MZLocalizedString(
            key: "Menu.DownloadPDF.Label.v129",
            tableName: "Menu",
            value: "Download PDF",
            comment: "Label for the button, displayed in the menu, downloads a pdf when pressed.")
        public static let AppMenuDownloadPDFConfirmMessage = MZLocalizedString(
            key: "Menu.DownloadPDF.Confirm.v129",
            tableName: "Menu",
            value: "Successfully Downloaded PDF",
            comment: "Toast displayed to user after downlaod pdf was pressed.")
        public static let AppMenuPasswords = MZLocalizedString(
            key: "Menu.Passwords.Label",
            tableName: nil,
            value: "Passwords",
            comment: "Label for the button, displayed in the menu, takes you to passwords screen when pressed.")
        public static let AppMenuCopyURLConfirmMessage = MZLocalizedString(
            key: "Menu.CopyURL.Confirm",
            tableName: nil,
            value: "URL Copied To Clipboard",
            comment: "Toast displayed to user after copy url pressed.")
        public static let AppMenuTabSentConfirmMessage = MZLocalizedString(
            key: "Menu.TabSent.Confirm",
            tableName: nil,
            value: "Tab Sent",
            comment: "Toast displayed to the user after a tab has been sent successfully.")
        public static let WhatsNewString = MZLocalizedString(
            key: "Menu.WhatsNew.Title",
            tableName: nil,
            value: "What’s New",
            comment: "The title for the option to view the What's new page.")
        public static let CustomizeHomePage = MZLocalizedString(
            key: "Menu.CustomizeHomePage.v99",
            tableName: nil,
            value: "Customize Homepage",
            comment: "Label for the customize homepage button in the menu page. Pressing this button takes users to the settings options, where they can customize the Firefox Home page")
        public static let NewTab = MZLocalizedString(
            key: "Menu.NewTab.v99",
            tableName: nil,
            value: "New Tab",
            comment: "Label for the new tab button in the menu page. Pressing this button opens a new tab.")
        public static let NewPrivateTab = MZLocalizedString(
            key: "Menu.NewPrivateTab.Label",
            tableName: nil,
            value: "New Private Tab",
            comment: "Label for the new private tab button in the menu page. Pressing this button opens a new private tab.")
        public static let Help = MZLocalizedString(
            key: "Menu.Help.v99",
            tableName: nil,
            value: "Help",
            comment: "Label for the help button in the menu page. Pressing this button opens the support page https://support.mozilla.org/en-US/products/ios")
        public static let Share = MZLocalizedString(
            key: "Menu.Share.v99",
            tableName: nil,
            value: "Share",
            comment: "Label for the share button in the menu page. Pressing this button open the share menu to share the current website.")
        public static let SyncAndSaveData = MZLocalizedString(
            key: "Menu.SyncAndSaveData.v103",
            tableName: nil,
            value: "Sync and Save Data",
            comment: "Label for the Firefox Sync button in the menu page. Pressing this button open the sign in to Firefox page service to sync and save data.")

        // Shortcuts
        public static let AddToShortcuts = MZLocalizedString(
            key: "Menu.AddToShortcuts.v99",
            tableName: nil,
            value: "Add to Shortcuts",
            comment: "Label for the add to shortcuts button in the menu. Pressing this button pins the current website as a shortcut on the home page.")
        public static let RemoveFromShortcuts = MZLocalizedString(
            key: "Menu.RemovedFromShortcuts.v99",
            tableName: nil,
            value: "Remove from Shortcuts",
            comment: "Label for the remove from shortcuts button in the menu. Pressing this button removes the current website from the shortcut pins on the home page.")
        public static let AddPinToShortcutsConfirmMessage = MZLocalizedString(
            key: "Menu.AddPin.Confirm2",
            tableName: nil,
            value: "Added to Shortcuts",
            comment: "Toast displayed to the user after adding the item to the Shortcuts.")
        public static let RemovePinFromShortcutsConfirmMessage = MZLocalizedString(
            key: "Menu.RemovePin.Confirm2.v99",
            tableName: nil,
            value: "Removed from Shortcuts",
            comment: "Toast displayed to the user after removing the item to the Shortcuts.")

        // Bookmarks
        public static let Bookmarks = MZLocalizedString(
            key: "Menu.Bookmarks.Label",
            tableName: nil,
            value: "Bookmarks",
            comment: "Label for the button, displayed in the menu, takes you to bookmarks screen when pressed.")
        public static let AddBookmark = MZLocalizedString(
            key: "Menu.AddBookmark.Label.v99",
            tableName: nil,
            value: "Add",
            comment: "Label for the add bookmark button in the menu. Pressing this button bookmarks the current page. Please keep the text as short as possible for this label.")
        public static let AddBookmarkConfirmMessage = MZLocalizedString(
            key: "Menu.AddBookmark.Confirm",
            tableName: nil,
            value: "Bookmark Added",
            comment: "Toast displayed to the user after a bookmark has been added.")
        public static let RemoveBookmark = MZLocalizedString(
            key: "Menu.RemoveBookmark.Label.v99",
            tableName: nil,
            value: "Remove",
            comment: "Label for the remove bookmark button in the menu. Pressing this button remove the current page from the bookmarks. Please keep the text as short as possible for this label.")
        public static let RemoveBookmarkConfirmMessage = MZLocalizedString(
            key: "Menu.RemoveBookmark.Confirm",
            tableName: nil,
            value: "Bookmark Removed",
            comment: "Toast displayed to the user after a bookmark has been removed.")
        public static let EditBookmarkLabel = MZLocalizedString(
            key: "Menu.EditBookmark.Label.v135",
            tableName: "Menu",
            value: "Edit",
            comment: "Label for the edit bookmark button in the legacy menu. Pressing this button opens the bookmark editing screen for the current page's bookmark. Please keep the text as short as possible for this label.")

        // Reading list
        public static let ReadingList = MZLocalizedString(
            key: "Menu.ReadingList.Label",
            tableName: nil,
            value: "Reading List",
            comment: "Label for the button, displayed in the menu, takes you to Reading List screen when pressed.")
        public static let AddReadingList = MZLocalizedString(
            key: "Menu.AddReadingList.Label.v99",
            tableName: nil,
            value: "Add",
            comment: "Label for the add to reading list button in the menu. Pressing this button adds the current page to the reading list. Please keep the text as short as possible for this label.")
        public static let AddToReadingListConfirmMessage = MZLocalizedString(
            key: "Menu.AddToReadingList.Confirm",
            tableName: nil,
            value: "Added To Reading List",
            comment: "Toast displayed to the user after adding the item to their reading list.")
        public static let RemoveReadingList = MZLocalizedString(
            key: "Menu.RemoveReadingList.Label.v99",
            tableName: nil,
            value: "Remove",
            comment: "Label for the remove from reading list button in the menu. Pressing this button removes the current page from the reading list. Please keep the text as short as possible for this label.")
        public static let RemoveFromReadingListConfirmMessage = MZLocalizedString(
            key: "Menu.RemoveReadingList.Confirm.v99",
            tableName: nil,
            value: "Removed from Reading List",
            comment: "Toast displayed to confirm to the user that his reading list item was correctly removed.")

        // ZoomPageBar
        public static let ZoomPageTitle = MZLocalizedString(
            key: "Menu.ZoomPage.Title.v113",
            tableName: nil,
            value: "Zoom (%@)",
            comment: "Label for the zoom page button in the menu, used to show the Zoom Page bar. %@ shows the current zoom level in percent.")
        public static let ZoomPageCloseAccessibilityLabel = MZLocalizedString(
            key: "Menu.ZoomPage.Close.AccessibilityLabel.v113",
            tableName: "ZoomPageBar",
            value: "Close Zoom Panel",
            comment: "Accessibility label for closing the zoom panel in Zoom Page Bar")
        public static let ZoomPageIncreaseZoomAccessibilityLabel = MZLocalizedString(
            key: "Menu.ZoomPage.IncreaseZoom.AccessibilityLabel.v113",
            tableName: "ZoomPageBar",
            value: "Increase Zoom Level",
            comment: "Accessibility label for increasing the zoom level in Zoom Page Bar")
        public static let ZoomPageDecreaseZoomAccessibilityLabel = MZLocalizedString(
            key: "Menu.ZoomPage.DecreaseZoom.AccessibilityLabel.v113",
            tableName: "ZoomPageBar",
            value: "Decrease Zoom Level",
            comment: "Accessibility label for decreasing the zoom level in Zoom Page Bar")
        public static let ZoomPageCurrentZoomLevelAccessibilityLabel = MZLocalizedString(
            key: "Menu.ZoomPage.CurrentZoomLevel.AccessibilityLabel.v113",
            tableName: "ZoomPageBar",
            value: "Current Zoom Level: %@",
            comment: "Accessibility label for current zoom level in Zoom Page Bar. %@ represents the zoom level")

        // Toolbar
        public struct Toolbar {
            public static let MenuButtonAccessibilityLabel = MZLocalizedString(
                key: "Toolbar.Menu.AccessibilityLabel",
                tableName: nil,
                value: "Menu",
                comment: "Accessibility label for the Menu button.")
            public static let HomeMenuButtonAccessibilityLabel = MZLocalizedString(
                key: "Menu.Toolbar.Home.AccessibilityLabel.v99",
                tableName: nil,
                value: "Home",
                comment: "Accessibility label for the Home button on the toolbar. Pressing this button brings the user to the home page.")
            public static let BookmarksButtonAccessibilityLabel = MZLocalizedString(
                key: "Menu.Toolbar.Bookmarks.AccessibilityLabel.v99",
                tableName: nil,
                value: "Bookmarks",
                comment: "Accessibility label for the Bookmark button on the toolbar. Pressing this button opens the bookmarks menu")
            public static let TabTrayDeleteMenuButtonAccessibilityLabel = MZLocalizedString(
                key: "Toolbar.Menu.CloseAllTabs",
                tableName: nil,
                value: "Close All Tabs",
                comment: "Accessibility label for the Close All Tabs menu button.")
        }

        // 3D TouchActions
        public struct TouchActions {
            public static let SendToDeviceTitle = MZLocalizedString(
                key: "Send to Device",
                tableName: "3DTouchActions",
                value: nil,
                comment: "Label for preview action on Tab Tray Tab to send the current tab to another device")
            public static let SendLinkToDeviceTitle = MZLocalizedString(
                key: "Menu.SendLinkToDevice",
                tableName: "3DTouchActions",
                value: "Send Link to Device",
                comment: "Label for preview action on Tab Tray Tab to send the current link to another device")
        }
    }
}

// MARK: - Alert controller shown when tapping sms, email or app store links
extension String {
    public static let ExternalLinkAppStoreConfirmationTitle = MZLocalizedString(
        key: "ExternalLink.AppStore.ConfirmationTitle",
        tableName: nil,
        value: "Open this link in the App Store?",
        comment: "Question shown to user when tapping a link that opens the App Store app")
    public static let ExternalSmsLinkConfirmation = MZLocalizedString(
        key: "ExternalLink.ExternalSmsLinkConfirmation.v136",
        tableName: "ExternalLink",
        value: "Open sms in an external application?",
        comment: "Question shown to user when tapping an SMS link that opens the external app for those."
    )
    public static let ExternalMailLinkConfirmation = MZLocalizedString(
        key: "ExternalLink.ExternalMailLinkConfirmation.v136",
        tableName: "ExternalLink",
        value: "Open email in the default mail application?",
        comment: "Question shown to user when tapping a mail link that opens the external app for those."
    )
    public static let ExternalInvalidLinkMessage = MZLocalizedString(
        key: "ExternalLink.ExternalInvalidLinkMessage.v136",
        tableName: "ExternalLink",
        value: "The application required to open that link can’t be found.",
        comment: "A statement shown to user when tapping an external link and the link doesn't work."
    )
    public static let ExternalOpenMessage = MZLocalizedString(
        key: "ExternalLink.ExternalOpenMessage.v136",
        tableName: "ExternalLink",
        value: "Open",
        comment: "The call to action button for a user to open an external link."
    )
}

// MARK: Enhanced Tracking Protection/Unified Trust Panel
extension String {
    public struct Menu {
        public struct EnhancedTrackingProtection {
            public struct AccessibilityLabels {
                public static let CloseButton = MZLocalizedString(
                    key: "MainMenu.Account.AccessibilityLabels.CloseButton.v137",
                    tableName: "EnhancedTrackingProtection",
                    value: "Close",
                    comment: "The accessibility label for the close button in the EnhancedTrackingProtection screen header navigation view.")
                public static let BackButton = MZLocalizedString(
                    key: "MainMenu.Account.AccessibilityLabels.BackButton.v137",
                    tableName: "EnhancedTrackingProtection",
                    value: "Back",
                    comment: "The accessibility label for the back button in the EnhancedTrackingProtection screen header navigation view.")
            }

            public static let onTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.On.Title.v128",
                tableName: "EnhancedTrackingProtection",
                value: "%@ is on guard",
                comment: "Title for the enhanced tracking protection screen when the user has selected to be protected. %@ is the app name (e.g. Firefox).")

            public static let onHeader = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.On.Header.v128",
                tableName: "EnhancedTrackingProtection",
                value: "You’re protected. If we spot something, we’ll let you know.",
                comment: "Header for the enhanced tracking protection screen when the user has selected to be protected.")

            public static let offTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Off.Title.v128",
                tableName: "EnhancedTrackingProtection",
                value: "You turned off protections",
                comment: "Title for the enhanced tracking protection screen when the user has opted out of the feature.")

            public static let offHeader = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Off.Header.v128",
                tableName: "EnhancedTrackingProtection",
                value: "%@ is off-duty. We suggest turning protections back on.",
                comment: "Header for the enhanced tracking protection screen when the user has opted out of the feature. %@ is the app name (e.g. Firefox).")

            public static let onNotSecureTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.On.NotSecure.Title.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Be careful on this site",
                comment: "Title for the enhanced tracking protection screen when the user has selected to be protected but the connection is not secure.")

            public static let onNotSecureHeader = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.On.NotSecure.Header.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Your connection is not secure.",
                comment: "Header for the enhanced tracking protection screen when the user has selected to be protected but the connection is not secure.")

            public static let connectionVerifiedByLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.Verifier.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Verified by %@",
                comment: "Text to let users know the site verifier, where %@ represents the SSL certificate signer which is on the enhanced tracking protection screen after the user taps on the connection details.")

            public static let viewCertificatesButtonTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.ViewCertificatesTitle.v131",
                tableName: "EnhancedTrackingProtection",
                value: "View certificate",
                comment: "The title for the button that allows users to view certificates inside the enhanced tracking protection details screen.")

            public static let trackersBlockedLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.Trackers.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Trackers blocked: %@",
                comment: "Text to let users know how many trackers were blocked on the current website. %@ is the number of trackers blocked.")

            public static let noTrackersLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.NoTrackers.v131",
                tableName: "EnhancedTrackingProtection",
                value: "No trackers found",
                comment: "Text to let users know that no trackers were found on the current website.")

            public static let crossSiteTrackersBlockedLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.Trackers.CrossSite.v129",
                tableName: "EnhancedTrackingProtection",
                value: "Cross-site tracking cookies: %@",
                comment: "Text to let users know how many cross-site tracking cookies were blocked on the current website. %@ is the number of cookies of this type detected.")

            public static let socialMediaTrackersBlockedLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.Trackers.SocialMedia.v129",
                tableName: "EnhancedTrackingProtection",
                value: "Social media trackers: %@",
                comment: "Text to let users know how many social media trackers were blocked on the current website. %@ is the number of cookies of this type detected.")

            public static let fingerprinterBlockedLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.Trackers.Fingerprinter.v129",
                tableName: "EnhancedTrackingProtection",
                value: "Fingerprinters: %@",
                comment: "Text to let users know how many fingerprinters were blocked on the current website. %@ is the number of fingerprinters detected.")

            public static let analyticsTrackersBlockedLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.Trackers.Analytics.v132",
                tableName: "EnhancedTrackingProtection",
                value: "Tracking content: %@",
                comment: "Text to let users know how many analytics trackers were blocked on the current website. %@ is the number of cookies of this type detected.")

            public static let connectionSecureLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.ConnectionSecure.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Secure connection",
                comment: "Text to let users know that the current website is secure.")

            public static let connectionUnsecureLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Details.ConnectionUnsecure.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Connection not secure",
                comment: "Text to let users know that the current website is not secure.")

            public static let switchTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Switch.Title.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Enhanced Tracking Protection",
                comment: "Title for the switch to enable/disable enhanced tracking protection inside the menu.")

            public static let switchOnText = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.SwitchOn.Text.v128",
                tableName: "EnhancedTrackingProtection",
                value: "If something looks broken on this site, try turning it off.",
                comment: "A switch to disable enhanced tracking protection inside the menu.")

            public static let switchOffText = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.SwitchOff.Text.v129",
                tableName: "EnhancedTrackingProtection",
                value: "Protections are OFF. We suggest turning them back on.",
                comment: "A switch to disable enhanced tracking protection inside the menu.")

            public static let clearDataButtonTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.ClearData.ButtonTitle.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Clear cookies and site data",
                comment: "The title for the clear cookies and site data button inside the enhanced tracking protection screen.")

            public static let clearDataAlertTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.ClearData.AlertTitle.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Clear cookies and site data",
                comment: "The title for the clear cookies and site data alert inside the enhanced tracking protection screen.")

            public static let clearDataAlertText = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.ClearData.AlertText.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Removing cookies and site data for %@ might log you out of websites and clear shopping carts.",
                comment: "The text for the clear cookies and site data alert inside the enhanced tracking protection screen. %@ is the currently visited website.")

            public static let clearDataAlertButton = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.ClearData.AlertOkButton.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Clear",
                comment: "The text for the clear cookies and site data alert button inside the enhanced tracking protection screen.")

            public static let clearDataAlertCancelButton = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.ClearData.AlertCancelButton.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Cancel",
                comment: "The text for the clear cookies and site data alert button inside the enhanced tracking protection screen.")

            public static let clearDataToastMessage = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.ClearData.ToastMessage.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Cookies and site data removed",
                comment: "The text for the clear cookies and site data toast that appears when the user selects to clear the cookies")

            public static let privacySettingsTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.PrivacySettings.Title.v128",
                tableName: "EnhancedTrackingProtection",
                value: "Privacy settings",
                comment: "The title for the privacy settings button inside the enhanced tracking protection screen.")

            public static let certificatesTitle = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.Title.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Certificate",
                comment: "The title for the certificates screen inside the certificates screen.")

            public static let certificateSubjectName = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.SubjectName.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Subject Name",
                comment: "The title for the certificate subject name section inside the certificate screen.")

            public static let certificateCommonName = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.CommonName.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Common Name",
                comment: "The title for the certificate common name inside the certificate screen.")

            public static let certificateIssuerName = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.IssuerName.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Issuer Name",
                comment: "The title for the certificate issuer name section inside the certificate screen.")

            public static let certificateIssuerCountry = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.IssuerCountry.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Country",
                comment: "The title for the certificate issuer country inside the certificate screen.")

            public static let certificateIssuerOrganization = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.IssuerOrganization.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Organization",
                comment: "The title for the certificate issuer organization inside the certificate screen.")

            public static let certificateValidity = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.Validity.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Validity",
                comment: "The title for the certificate validity section inside the certificate screen.")

            public static let certificateValidityNotBefore = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.ValidityNotBefore.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Not Before",
                comment: "The title for the certificate validity not before date inside the certificate screen.")

            public static let certificateValidityNotAfter = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.ValidityNotAfter.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Not After",
                comment: "The title for the certificate validity not after date inside the certificate screen.")

            public static let certificateSubjectAltNames = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.SubjectAltNames.v131",
                tableName: "EnhancedTrackingProtection",
                value: "Subject Alt Names",
                comment: "The title for the certificate subject alt names section inside the certificate screen.")

            public static let certificateSubjectAltNamesDNSName = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.Certificates.SubjectAltNamesDNSName.v131",
                tableName: "EnhancedTrackingProtection",
                value: "DNS Name",
                comment: "The title for the certificate subject alt names DNS name inside the certificate screen.")

            public static let closeButtonAccessibilityLabel = MZLocalizedString(
                key: "Menu.EnhancedTrackingProtection.CloseButton.AccessibilityLabel.v132",
                tableName: "EnhancedTrackingProtection",
                value: "Close privacy and security menu",
                comment: "The accessibility label for the close button in the Enhanced Tracking protection menu.")
        }
    }
}

// MARK: - ContentBlocker/TrackingProtection string
extension String {
    public static let SettingsTrackingProtectionSectionName = MZLocalizedString(
        key: "Settings.TrackingProtection.SectionName",
        tableName: nil,
        value: "Tracking Protection",
        comment: "Row in top-level of settings that gets tapped to show the tracking protection settings detail view.")

    public static let TrackingProtectionEnableTitle = MZLocalizedString(
        key: "Settings.TrackingProtectionOption.NormalBrowsingLabelOn",
        tableName: nil,
        value: "Enhanced Tracking Protection",
        comment: "Settings option to specify that Tracking Protection is on")

    public static let TrackingProtectionOptionProtectionLevelTitle = MZLocalizedString(
        key: "Settings.TrackingProtection.ProtectionLevelTitle",
        tableName: nil,
        value: "Protection Level",
        comment: "Title for tracking protection options section where level can be selected.")
    public static let TrackingProtectionOptionBlockListLevelStandard = MZLocalizedString(
        key: "Settings.TrackingProtectionOption.BasicBlockList",
        tableName: nil,
        value: "Standard (default)",
        comment: "Tracking protection settings option for using the basic blocklist.")
    public static let TrackingProtectionOptionBlockListLevelStandardStatus = MZLocalizedString(
        key: "Settings.TrackingProtectionOption.BasicBlockList.Status",
        tableName: nil,
        value: "Standard",
        comment: "Tracking protection settings status showing the current option selected.")
    public static let TrackingProtectionOptionBlockListLevelStrict = MZLocalizedString(
        key: "Settings.TrackingProtectionOption.BlockListStrict",
        tableName: nil,
        value: "Strict",
        comment: "Tracking protection settings option for using the strict blocklist.")
    public static let TrackingProtectionReloadWithout = MZLocalizedString(
        key: "Menu.ReloadWithoutTrackingProtection.Title",
        tableName: nil,
        value: "Reload Without Tracking Protection",
        comment: "Label for the button, displayed in the menu, used to reload the current website without Tracking Protection")
    public static let TrackingProtectionReloadWith = MZLocalizedString(
        key: "Menu.ReloadWithTrackingProtection.Title",
        tableName: nil,
        value: "Reload With Tracking Protection",
        comment: "Label for the button, displayed in the menu, used to reload the current website with Tracking Protection enabled")

    public static let TrackingProtectionCellFooter = MZLocalizedString(
        key: "Settings.TrackingProtection.ProtectionCellFooter",
        tableName: nil,
        value: "Reduces targeted ads and helps stop advertisers from tracking your browsing.",
        comment: "Additional information about your Enhanced Tracking Protection")
    public static let TrackingProtectionStandardLevelDescription = MZLocalizedString(
        key: "Settings.TrackingProtection.ProtectionLevelStandard.Description",
        tableName: nil,
        value: "Allows some ad tracking so websites function properly.",
        comment: "Description for standard level tracker protection")
    public static let TrackingProtectionStrictLevelDescription = MZLocalizedString(
        key: "Settings.TrackingProtection.ProtectionLevelStrict.Description",
        tableName: nil,
        value: "Blocks more trackers, ads, and popups. Pages load faster, but some functionality may not work.",
        comment: "Description for strict level tracker protection")
    public static let TrackingProtectionLevelFooter = MZLocalizedString(
        key: "Settings.TrackingProtection.ProtectionLevel.Footer.Lock",
        tableName: nil,
        value: "If a site doesn’t work as expected, tap the lock in the address bar and turn off Enhanced Tracking Protection for that page.",
        comment: "Footer information for tracker protection level.")
    public static let TrackerProtectionLearnMore = MZLocalizedString(
        key: "Settings.TrackingProtection.LearnMore",
        tableName: nil,
        value: "Learn more",
        comment: "'Learn more' info link on the Tracking Protection settings screen.")
}

// MARK: - Tracking Protection menu
extension String {
    public static let ETPOn = MZLocalizedString(
        key: "Menu.EnhancedTrackingProtectionOn.Title",
        tableName: nil,
        value: "Protections are ON for this site",
        comment: "A switch to enable enhanced tracking protection inside the menu.")
    public static let ETPOff = MZLocalizedString(
        key: "Menu.EnhancedTrackingProtectionOff.Title",
        tableName: nil,
        value: "Protections are OFF for this site",
        comment: "A switch to disable enhanced tracking protection inside the menu.")

    public static let TPDetailsVerifiedBy = MZLocalizedString(
        key: "Menu.TrackingProtection.Details.Verifier",
        tableName: nil,
        value: "Verified by %@",
        comment: "String to let users know the site verifier, where %@ represents the SSL certificate signer.")

    // Category Titles
    public static let TPCryptominersBlocked = MZLocalizedString(
        key: "Menu.TrackingProtectionCryptominersBlocked.Title",
        tableName: nil,
        value: "Cryptominers",
        comment: "The title that shows the number of cryptomining scripts blocked")
    public static let TPFingerprintersBlocked = MZLocalizedString(
        key: "Menu.TrackingProtectionFingerprintersBlocked.Title",
        tableName: nil,
        value: "Fingerprinters",
        comment: "The title that shows the number of fingerprinting scripts blocked")
    public static let TPCrossSiteBlocked = MZLocalizedString(
        key: "Menu.TrackingProtectionCrossSiteTrackers.Title",
        tableName: nil,
        value: "Cross-Site Trackers",
        comment: "The title that shows the number of cross-site URLs blocked")
    public static let TPSocialBlocked = MZLocalizedString(
        key: "Menu.TrackingProtectionBlockedSocial.Title",
        tableName: nil,
        value: "Social Trackers",
        comment: "The title that shows the number of social URLs blocked")
    public static let TPContentBlocked = MZLocalizedString(
        key: "Menu.TrackingProtectionBlockedContent.Title",
        tableName: nil,
        value: "Tracking content",
        comment: "The title that shows the number of content cookies blocked")

    // Shortcut on bottom of TP page menu to get to settings.
    public static let TPProtectionSettings = MZLocalizedString(
        key: "Menu.TrackingProtection.ProtectionSettings.Title",
        tableName: nil,
        value: "Protection Settings",
        comment: "The title for tracking protection settings")

    // Settings info
    public static let TPAccessoryInfoBlocksTitle = MZLocalizedString(
        key: "Settings.TrackingProtection.Info.BlocksTitle",
        tableName: nil,
        value: "BLOCKS",
        comment: "The Title on info view which shows a list of all blocked websites")

    // Category descriptions
    public static let TPCategoryDescriptionSocial = MZLocalizedString(
        key: "Menu.TrackingProtectionDescription.SocialNetworksNew",
        tableName: nil,
        value: "Social networks place trackers on other websites to build a more complete and targeted profile of you. Blocking these trackers reduces how much social media companies can see what do you online.",
        comment: "Description of social network trackers.")
    public static let TPCategoryDescriptionCrossSite = MZLocalizedString(
        key: "Menu.TrackingProtectionDescription.CrossSiteNew",
        tableName: nil,
        value: "These cookies follow you from site to site to gather data about what you do online. They are set by third parties such as advertisers and analytics companies.",
        comment: "Description of cross-site trackers.")
    public static let TPCategoryDescriptionCryptominers = MZLocalizedString(
        key: "Menu.TrackingProtectionDescription.CryptominersNew",
        tableName: nil,
        value: "Cryptominers secretly use your system’s computing power to mine digital money. Cryptomining scripts drain your battery, slow down your computer, and can increase your energy bill.",
        comment: "Description of cryptominers.")
    public static let TPCategoryDescriptionFingerprinters = MZLocalizedString(
        key: "Menu.TrackingProtectionDescription.Fingerprinters",
        tableName: nil,
        value: "The settings on your browser and computer are unique. Fingerprinters collect a variety of these unique settings to create a profile of you, which can be used to track you as you browse.",
        comment: "Description of fingerprinters.")
    public static let TPCategoryDescriptionContentTrackers = MZLocalizedString(
        key: "Menu.TrackingProtectionDescription.ContentTrackers",
        tableName: nil,
        value: "Websites may load outside ads, videos, and other content that contains hidden trackers. Blocking this can make websites load faster, but some buttons, forms, and login fields, might not work.",
        comment: "Description of content trackers.")
}

// MARK: - Location bar long press menu
extension String {
    public static let PasteAndGoTitle = MZLocalizedString(
        key: "Menu.PasteAndGo.Title",
        tableName: nil,
        value: "Paste & Go",
        comment: "The title for the button that lets you paste and go to a URL")
    public static let PasteTitle = MZLocalizedString(
        key: "Menu.Paste.Title",
        tableName: nil,
        value: "Paste",
        comment: "The title for the button that lets you paste into the location bar")
    public static let CopyAddressTitle = MZLocalizedString(
        key: "Menu.Copy.Title",
        tableName: nil,
        value: "Copy Address",
        comment: "The title for the button that lets you copy the url from the location bar.")
}

// MARK: - Settings Home
extension String {
    public static let SendCrashReportsSettingTitle = MZLocalizedString(
        key: "Settings.CrashReports.Title.v135",
        tableName: "Settings",
        value: "Automatically Send Crash Reports",
        comment: "On the Settings screen, this is the title text for a toggle which controls automatically sending crash reports.")
    public static let SendCrashReportsSettingLinkV2 = MZLocalizedString(
        key: "Settings.CrashReports.Link.v136",
        tableName: "Settings",
        value: "Learn More",
        comment: "Title for a link that explains how Mozilla send crash reports.")
    public static let SendCrashReportsSettingMessageV2 = MZLocalizedString(
        key: "Settings.CrashReports.Message.v136",
        tableName: "Settings",
        value: "This helps us diagnose and fix issues with the browser.",
        comment: "On the Settings screen, this is the subtitle text for a toggle which controls automatically sending crash reports.")
    public static let SendDailyUsagePingSettingTitle = MZLocalizedString(
        key: "Settings.DailyUsagePing.Title.v135",
        tableName: "Settings",
        value: "Daily Usage Ping",
        comment: "On the Settings screen, this is the title text for a toggle which controls automatically sending daily usage ping.")
    public static let SendDailyUsagePingSettingMessage = MZLocalizedString(
        key: "Settings.DailyUsagePing.Message.v135",
        tableName: "Settings",
        value: "This helps %@ to estimate active users.",
        comment: "On the Settings screen, this is the subtitle text for a toggle which controls sending daily usage ping. %@ is the company name (e.g. Mozilla).")
    public static let SendDailyUsagePingSettingLinkV2 = MZLocalizedString(
        key: "Settings.DailyUsagePing.Link.v136",
        tableName: "Settings",
        value: "Learn More",
        comment: "Title for a link that explains how Mozilla send daily usage ping.")
    public static let SendTechnicalDataSettingTitleV2 = MZLocalizedString(
        key: "Settings.TechnicalData.Title.v136",
        tableName: "Settings",
        value: "Send Technical and Interaction Data",
        comment: "On the Settings screen, this is the title text for a toggle which controls sending technical and interaction data.")
    public static let SendTechnicalDataSettingLinkV2 = MZLocalizedString(
        key: "Settings.TechnicalData.Link.v136",
        tableName: "Settings",
        value: "Learn More",
        comment: "Title for a link that explains how Mozilla send technical and interaction data.")
    public static let SendTechnicalDataSettingMessageV2 = MZLocalizedString(
        key: "Settings.TechnicalData.Message.v136",
        tableName: "Settings",
        value: "Data about your device, hardware configuration, and usage helps us improve %@ features, performance and stability.",
        comment: "On the Settings screen, this is the subtitle text for a toggle which controls sending technical and interaction data. %@ is the app name (e.g. Firefox).")
    public static let StudiesSettingTitleV2 = MZLocalizedString(
        key: "Settings.Studies.Title.v136",
        tableName: "Settings",
        value: "Install and Run Studies",
        comment: "Label used as a toggle item in Settings. When this is off, the user is opting out of all studies.")
    public static let StudiesSettingLinkV2 = MZLocalizedString(
        key: "Settings.Studies.Link.v136",
        tableName: "Settings",
        value: "Learn More",
        comment: "Title for a link that explains what Mozilla means by Studies")
    public static let StudiesSettingMessageV2 = MZLocalizedString(
        key: "Settings.Studies.Message.v136",
        tableName: "Settings",
        value: "Try out features and ideas before they’re released to everyone.",
        comment: "A short description that explains that Mozilla is running studies")
    public static let SettingsSiriSectionName = MZLocalizedString(
        key: "Settings.Siri.SectionName",
        tableName: nil,
        value: "Siri Shortcuts",
        comment: "The option that takes you to the siri shortcuts settings page")
    public static let SettingsSiriSectionDescription = MZLocalizedString(
        key: "Settings.Siri.SectionDescription",
        tableName: nil,
        value: "Use Siri shortcuts to quickly open Firefox via Siri",
        comment: "The description that describes what siri shortcuts are")
    public static let SettingsSiriOpenURL = MZLocalizedString(
        key: "Settings.Siri.OpenTabShortcut",
        tableName: nil,
        value: "Open New Tab",
        comment: "The description of the open new tab siri shortcut")
}

// MARK: - Share extension
extension String {
    public static let SendToCancelButton = MZLocalizedString(
        key: "SendTo.Cancel.Button",
        tableName: nil,
        value: "Cancel",
        comment: "Button title for cancelling share screen")
    public static let SendToErrorOKButton = MZLocalizedString(
        key: "SendTo.Error.OK.Button",
        tableName: nil,
        value: "OK",
        comment: "OK button to dismiss the error prompt.")
    public static let SendToErrorTitle = MZLocalizedString(
        key: "SendTo.Error.Title",
        tableName: nil,
        value: "The link you are trying to share cannot be shared.",
        comment: "Title of error prompt displayed when an invalid URL is shared.")
    public static let SendToErrorMessage = MZLocalizedString(
        key: "SendTo.Error.Message",
        tableName: nil,
        value: "Only HTTP and HTTPS links can be shared.",
        comment: "Message in error prompt explaining why the URL is invalid.")
    public static let SendToCloseButton = MZLocalizedString(
        key: "SendTo.Close.Button",
        tableName: nil,
        value: "Close",
        comment: "Close button in top navigation bar")
    public static let SendToNotSignedInText = MZLocalizedString(
        key: "SendTo.NotSignedIn.Title.v119",
        tableName: "Share",
        value: "You are not signed in to your account.",
        comment: "This message appears when a user tries to use 'Send Link to Device' action while not logged in")
    public static let SendToNotSignedInMessage = MZLocalizedString(
        key: "SendTo.NotSignedIn.Message",
        tableName: nil,
        value: "Please open Firefox, go to Settings and sign in to continue.",
        comment: "See http://mzl.la/1ISlXnU")
    public static let SendToNoDevicesFound = MZLocalizedString(
        key: "SendTo.NoDevicesFound.Message.v119",
        tableName: "Share",
        value: "You don’t have any other devices connected to this account available to sync.",
        comment: "Error message shown in the remote tabs panel")
    public static let SendToTitle = MZLocalizedString(
        key: "SendTo.NavBar.Title",
        tableName: nil,
        value: "Send Tab",
        comment: "Title of the dialog that allows you to send a tab to a different device")
    public static let SendToSendButtonTitle = MZLocalizedString(
        key: "SendTo.SendAction.Text",
        tableName: nil,
        value: "Send",
        comment: "Navigation bar button to Send the current page to a device")
    public static let SendToDevicesListTitle = MZLocalizedString(
        key: "SendTo.DeviceList.Text",
        tableName: nil,
        value: "Available devices:",
        comment: "Header for the list of devices table")
    public static let ShareSendToDevice = String.LegacyAppMenu.TouchActions.SendToDeviceTitle

    // The above items are re-used strings from the old extension. New strings below.

    public static let ShareAddToReadingList = MZLocalizedString(
        key: "ShareExtension.AddToReadingListAction.Title",
        tableName: nil,
        value: "Add to Reading List",
        comment: "Action label on share extension to add page to the Firefox reading list.")
    public static let ShareAddToReadingListDone = MZLocalizedString(
        key: "ShareExtension.AddToReadingListActionDone.Title",
        tableName: nil,
        value: "Added to Reading List",
        comment: "Share extension label shown after user has performed 'Add to Reading List' action.")
    public static let ShareBookmarkThisPage = MZLocalizedString(
        key: "ShareExtension.BookmarkThisPageAction.Title",
        tableName: nil,
        value: "Bookmark This Page",
        comment: "Action label on share extension to bookmark the page in Firefox.")
    public static let ShareBookmarkThisPageDone = MZLocalizedString(
        key: "ShareExtension.BookmarkThisPageActionDone.Title",
        tableName: nil,
        value: "Bookmarked",
        comment: "Share extension label shown after user has performed 'Bookmark this Page' action.")

    public static let ShareOpenInFirefox = MZLocalizedString(
        key: "ShareExtension.OpenInFirefoxAction.Title",
        tableName: nil,
        value: "Open in Firefox",
        comment: "Action label on share extension to immediately open page in Firefox.")
    public static let ShareSearchInFirefox = MZLocalizedString(
        key: "ShareExtension.SeachInFirefoxAction.Title",
        tableName: nil,
        value: "Search in Firefox",
        comment: "Action label on share extension to search for the selected text in Firefox.")

    public static let ShareLoadInBackground = MZLocalizedString(
        key: "ShareExtension.LoadInBackgroundAction.Title",
        tableName: nil,
        value: "Load in Background",
        comment: "Action label on share extension to load the page in Firefox when user switches apps to bring it to foreground.")
    public static let ShareLoadInBackgroundDone = MZLocalizedString(
        key: "ShareExtension.LoadInBackgroundActionDone.Title",
        tableName: nil,
        value: "Loading in Firefox",
        comment: "Share extension label shown after user has performed 'Load in Background' action.")
}

extension String {
    public struct Shopping {
        public static let SheetHeaderTitle = MZLocalizedString(
            key: "Shopping.Sheet.Title.v120",
            tableName: "Shopping",
            value: "Review Checker",
            comment: "Label for the header of the Shopping Experience (Fakespot) sheet")
        public static let SheetHeaderBetaTitle = MZLocalizedString(
            key: "Shopping.Sheet.Beta.Title.v120",
            tableName: "Shopping",
            value: "BETA",
            comment: "Beta label for the header of the Shopping Experience (Fakespot) sheet")
        public static let CloseButtonAccessibilityLabel = MZLocalizedString(
            key: "Shopping.Sheet.Close.AccessibilityLabel.v121",
            tableName: "Shopping",
            value: "Close Review Checker",
            comment: "Accessibility label for close button that dismisses the Shopping Experience (Fakespot) sheet.")
        public static let ReliabilityCardTitle = MZLocalizedString(
            key: "Shopping.ReviewQuality.ReliabilityCardTitle.v120",
            tableName: "Shopping",
            value: "How reliable are these reviews?",
            comment: "Title of the reliability card displayed in the shopping review quality bottom sheet.")
        public static let ReliabilityRatingAB = MZLocalizedString(
            key: "Shopping.ReviewQuality.ReliabilityRating.AB.Description.v120",
            tableName: "Shopping",
            value: "Reliable reviews",
            comment: "Description of the reliability ratings for rating 'A' and 'B' displayed in the shopping review quality bottom sheet.")
        public static let ReliabilityRatingC = MZLocalizedString(
            key: "Shopping.ReviewQuality.ReliabilityRating.C.Description.v120",
            tableName: "Shopping",
            value: "Mix of reliable and unreliable reviews",
            comment: "Description of the reliability rating 'C' displayed in the shopping review quality bottom sheet.")
        public static let ReliabilityRatingDF = MZLocalizedString(
            key: "Shopping.ReviewQuality.ReliabilityRating.DF.Description.v120",
            tableName: "Shopping",
            value: "Unreliable reviews",
            comment: "Description of the reliability ratings for rating 'D' and 'F' displayed in the shopping review quality bottom sheet.")
        public static let ConfirmationCardTitle = MZLocalizedString(
            key: "Shopping.ConfirmationCard.Title.v120",
            tableName: "Shopping",
            value: "Analysis Is Up To Date",
            comment: "Title of the confirmation displayed in the shopping review quality bottom sheet.")
        public static let ConfirmationCardButtonText = MZLocalizedString(
            key: "Shopping.ConfirmationCard.Button.Text.v120",
            tableName: "Shopping",
            value: "Got It",
            comment: "Button text of the confirmation displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardTitle = MZLocalizedString(
            key: "Shopping.HighlightsCard.Title.v120",
            tableName: "Shopping",
            value: "Highlights from recent reviews",
            comment: "Title of the review highlights displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardMoreButtonTitle = MZLocalizedString(
            key: "Shopping.HighlightsCard.MoreButton.Title.v120",
            tableName: "Shopping",
            value: "Show More",
            comment: "Title of the button that shows more reviews in the review highlights displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardLessButtonTitle = MZLocalizedString(
            key: "Shopping.HighlightsCard.LessButton.Title.v120",
            tableName: "Shopping",
            value: "Show Less",
            comment: "Title of the button that shows less reviews in the review highlights displayed in the shopping review quality bottom sheet.")
        public static let AdjustedRatingTitle = MZLocalizedString(
            key: "Shopping.AdjustedRating.Title.v120",
            tableName: "Shopping",
            value: "Adjusted rating",
            comment: "Title of the adjusted rating card displayed in the shopping review quality bottom sheet.")
        public static let AdjustedRatingDescription = MZLocalizedString(
            key: "Shopping.AdjustedRating.Description.v121",
            tableName: "Shopping",
            value: "Based on reliable reviews",
            comment: "Description adjusted of the rating card displayed in the shopping review quality bottom sheet.")
        public static let AdjustedRatingStarsAccessibilityLabel = MZLocalizedString(
            key: "Shopping.AdjustedRating.StarsAccessibilityLabel.v120",
            tableName: "Shopping",
            value: "%@ out of 5 stars",
            comment: "Accessibility label, associated to adjusted rating stars. %@ is a decimal value from 0 to 5 that will only use a tenth (example: 3.5).")
        public static let HighlightsCardPriceTitle = MZLocalizedString(
            key: "Shopping.HighlightsCard.Price.Title.v120",
            tableName: "Shopping",
            value: "Price",
            comment: "Section title of the review highlights displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardQualityTitle = MZLocalizedString(
            key: "Shopping.HighlightsCard.Quality.Title.v120",
            tableName: "Shopping",
            value: "Quality",
            comment: "Section title of the review highlights displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardShippingTitle = MZLocalizedString(
            key: "Shopping.HighlightsCard.Shipping.Title.v120",
            tableName: "Shopping",
            value: "Shipping",
            comment: "Section title of the review highlights displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardCompetitivenessTitle = MZLocalizedString(
            key: "Shopping.HighlightsCard.Competitiveness.Title.v120",
            tableName: "Shopping",
            value: "Competitiveness",
            comment: "Section title of the review highlights displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardPackagingTitle = MZLocalizedString(
            key: "Shopping.HighlightsCard.Packaging.Title.v120",
            tableName: "Shopping",
            value: "Packaging",
            comment: "Section title of the review highlights displayed in the shopping review quality bottom sheet, specifically focusing on the quality, design, and condition of the product's packaging. This may include details about the box, protective materials, presentation, and overall packaging experience.")
        public static let SettingsCardLabelTitle = MZLocalizedString(
            key: "Shopping.SettingsCard.Label.Title.v120",
            tableName: "Shopping",
            value: "Settings",
            comment: "Title of the settings card displayed in the shopping review quality bottom sheet.")
        public static let SettingsCardRecommendedProductsLabel = MZLocalizedString(
            key: "Shopping.SettingsCard.RecommendedProducts.Label.v120",
            tableName: "Shopping",
            value: "Show products recommended by %@",
            comment: "Label of the switch from settings card displayed in the shopping review quality bottom sheet. %@ is the app name (e.g. Firefox).")
        public static let SettingsCardTurnOffButton = MZLocalizedString(
            key: "Shopping.SettingsCard.TurnOffButton.Title.v120",
            tableName: "Shopping",
            value: "Turn Off Review Checker",
            comment: "Label of the button from settings card displayed in the shopping review quality bottom sheet.")
        public static let SettingsCardGroupedRecommendedProductsAndSwitchAccessibilityLabel = MZLocalizedString(
            key: "Shopping.SettingsCard.Expand.GroupedRecommendedProductsAndSwitch.AccessibilityLabel.v123",
            tableName: "Shopping",
            value: "%1$@, switch button, %2$@.",
            comment: "Accessibility label for the recommended products label and switch, grouped together. %1$@ is the recommended products label, %2$@ is the state of the switch: On/Off.")
        public static let SettingsCardGroupedRecommendedProductsAndSwitchAccessibilityHint = MZLocalizedString(
            key: "Shopping.SettingsCard.Expand.GroupedRecommendedProductsAndSwitch.AccessibilityHint.v123",
            tableName: "Shopping",
            value: "Double tap to toggle setting.",
            comment: "Accessibility hint for the recommended products label and switch, grouped together. When the group is selected in VoiceOver mode, the hint is read to help the user understand what action can be performed.")
        public static let SettingsCardSwitchValueOnAccessibilityLabel = MZLocalizedString(
            key: "Shopping.SettingsCard.SwitchValueOn.AccessibilityLabel.v123",
            tableName: "Shopping",
            value: "On",
            comment: "Toggled On accessibility value, from Settings Card within the shopping product review bottom sheet.")
        public static let SettingsCardSwitchValueOffAccessibilityLabel = MZLocalizedString(
            key: "Shopping.SettingsCard.SwitchValueOff.AccessibilityLabel.v123",
            tableName: "Shopping",
            value: "Off",
            comment: "Toggled Off accessibility switch value from Settings Card within the shopping product review bottom sheet.")
        public static let SettingsCardExpandAccessibilityLabel = MZLocalizedString(
            key: "Shopping.SettingsCard.Expand.AccessibilityLabel.v120",
            tableName: "Shopping",
            value: "Expand Settings Card",
            comment: "Accessibility label for the down chevron icon used to expand or show the details of the Settings Card within the shopping product review bottom sheet.")
        public static let SettingsCardCollapseAccessibilityLabel = MZLocalizedString(
            key: "Shopping.SettingsCard.Collapse.AccessibilityLabel.v120",
            tableName: "Shopping",
            value: "Collapse Settings Card",
            comment: "Accessibility label for the up chevron icon used to collapse or minimize the Settings Card within the shopping product review bottom sheet.")
        public static let SettingsCardFooterAction = MZLocalizedString(
            key: "Shopping.SettingsCard.Footer.Action.v120",
            tableName: "Shopping",
            value: "Review Checker is powered by %1$@ by %2$@",
            comment: "Action title of the footer underneath the Settings Card displayed in the shopping review quality bottom sheet. %1$@ is the Fakespot, %2$@ is the company name (e.g. Mozilla).")
        public static let NoAnalysisCardHeadlineLabelTitle = MZLocalizedString(
            key: "Shopping.NoAnalysisCard.HeadlineLabel.Title.v120",
            tableName: "Shopping",
            value: "No info about these reviews yet",
            comment: "Title for card displayed when a shopping product has not been analysed yet.")
        public static let NoAnalysisCardBodyLabelTitle = MZLocalizedString(
            key: "Shopping.NoAnalysisCard.BodyLabel.Title.v120",
            tableName: "Shopping",
            value: "To know whether this product’s reviews are reliable, check the review quality. It only takes about 60 seconds.",
            comment: "Text for the body label, to check the reliability of a product.")
        public static let NoAnalysisCardAnalyzerButtonTitle = MZLocalizedString(
            key: "Shopping.NoAnalysisCard.AnalyzerButton.Title.v120",
            tableName: "Shopping",
            value: "Check Review Quality",
            comment: "Text for the analyzer button displayed when an analysis can be updated for a product.")
        public static let ReviewQualityCardLabelTitle = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.Label.Title.v120",
            tableName: "Shopping",
            value: "How we determine review quality",
            comment: "Title of the 'How we determine review quality' card displayed in the shopping review quality bottom sheet.")
        public static let ReviewQualityCardExpandAccessibilityLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.Expand.AccessibilityLabel.v120",
            tableName: "Shopping",
            value: "Expand How we determine review quality card",
            comment: "Accessibility label for the down chevron, from 'How we determine review quality' card displayed in the shopping review quality bottom sheet.")
        public static let ReviewQualityCardCollapseAccessibilityLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.Collapse.AccessibilityLabel.v120",
            tableName: "Shopping",
            value: "Collapse How we determine review quality Card",
            comment: "Accessibility label for the up chevron, from 'How we determine review quality' card displayed in the shopping review quality bottom sheet.")
        public static let ReviewQualityCardHeadlineLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.Headline.Label.v120",
            tableName: "Shopping",
            value: "We use AI technology from %1$@ by %2$@ to check the reliability of product reviews. This will only help you assess review quality, not product quality.",
            comment: "Label of the headline from How we determine review quality card displayed in the shopping review quality bottom sheet. %1$@ is the Fakespot and %2$@ is the company (e.g. Mozilla).")
        public static let ReviewQualityCardSubHeadlineLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.SubHeadline.Label.v120",
            tableName: "Shopping",
            value: "We assign each product’s reviews a *letter grade* from A to F.",
            comment: "Label of the sub headline from How we determine review quality card displayed in the shopping review quality bottom sheet. The *text inside asterisks* denotes part of the string to bold, please leave the text inside the '*' so that it is bolded correctly.")
        public static let ReviewQualityCardReliableReviewsLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.ReliableReviews.Label.v120",
            tableName: "Shopping",
            value: "Reliable reviews. We believe the reviews are likely from real customers who left honest, unbiased reviews.",
            comment: "Reliable reviews label from How we determine review quality card displayed in the shopping review quality bottom sheet.")
        public static let ReviewQualityCardMixedReviewsLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.MixedReviews.Label.v120",
            tableName: "Shopping",
            value: "We believe there’s a mix of reliable and unreliable reviews",
            comment: "Mixed reviews label from How we determine review quality card displayed in the shopping review quality bottom sheet.")
        public static let ReviewQualityCardUnreliableReviewsLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.UnreliableReviews.Label.v120",
            tableName: "Shopping",
            value: "Unreliable reviews. We believe the reviews are likely fake or from biased reviewers.",
            comment: "Unreliable reviews label from How we determine review quality card displayed in the shopping review quality bottom sheet.")
        public static let ReviewQualityCardAdjustedRatingLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.AdjustedRating.Label.v120",
            tableName: "Shopping",
            value: "The *adjusted rating* is based only on reviews we believe to be reliable.",
            comment: "Adjusted rating label from How we determine review quality card displayed in the shopping review quality bottom sheet. The *text inside asterisks* denotes part of the string to bold, please leave the text inside the '*' so that it is bolded correctly.")
        public static let ReviewQualityCardHighlightsLabel = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.Highlights.Label.v126",
            tableName: "Shopping",
            value: "*Highlights* are from %@ reviews within the last 80 days that we believe to be reliable.",
            comment: "Highlights label from How we determine review quality card displayed in the shopping review quality bottom sheet. %@ is the partner website the user is coming from. The *text inside asterisks* denotes part of the string to bold, please leave the text inside the '*' so that it is bolded correctly.")
        public static let ReviewQualityCardLearnMoreButtonTitle = MZLocalizedString(
            key: "Shopping.ReviewQualityCard.LearnMoreButton.Title.v120",
            tableName: "Shopping",
            value: "Learn more about how %@ determines review quality",
            comment: "The title of the learn more button from How we determine review quality card displayed in the shopping review quality bottom sheet. %@ is the Fakespot.")
        public static let ReliabilityScoreGradeA11yLabel = MZLocalizedString(
            key: "Shopping.ReliabilityScore.Grade.A11y.Label.v120",
            tableName: "Shopping",
            value: "Grade %@",
            comment: "Accessibility label for the Grade labels used in 'How we determine review quality' card and 'How reliable are these reviews' card displayed in the shopping review quality bottom sheet. %@ is a grade letter from A to F (e.g. A).")
        public static let OptInCardHeaderTitle = MZLocalizedString(
            key: "Shopping.OptInCard.HeaderLabel.Title.v120",
            tableName: "Shopping",
            value: "Try our trusted guide to product reviews",
            comment: "Label for the header of the Shopping Experience Opt In onboarding Card (Fakespot)")
        public static let OptInCardFirstParagraph = MZLocalizedString(
            key: "Shopping.OptInCard.FirstParagraph.Description.v120",
            tableName: "Shopping",
            value: "See how reliable product reviews are on %1$@ before you buy. Review Checker, an experimental feature from %2$@, is built right into the browser. It works on %3$@ and %4$@, too.",
            comment: "Label for the first paragraph of the Shopping Experience Opt In onboarding Card (Fakespot). %1$@ is the website the user is coming from when viewing this screen (default Amazon). %2$@ is the app name (e.g. Firefox). %3$@ and %4$@ are the other two websites that are currently supported (Amazon, Best Buy or Walmart) besides the one used for the first parameter.")
        public static let OptInCardFirstParagraphOneVendor = MZLocalizedString(
            key: "Shopping.OptInCard.FirstParagraph.AmazonOnly.Description.v122",
            tableName: "Shopping",
            value: "See how reliable product reviews are on %1$@ before you buy. Review Checker, an experimental feature from %2$@, is built right into the browser.",
            comment: "Label for the first paragraph of the Shopping Experience Opt In onboarding Card (Fakespot). %1$@ is the website the user is coming from when viewing this screen (default Amazon). %2$@ is the app name (e.g. Firefox). This string is almost identical with 'Shopping.OptInCard.FirstParagraph.Description', but without Best Buy and Walmart websites, which are not available in many locales.")
        public static let OptInCardSecondParagraph = MZLocalizedString(
            key: "Shopping.OptInCard.SecondParagraph.Description.v120",
            tableName: "Shopping",
            value: "Using the power of %1$@ by %2$@, we help you avoid biased and inauthentic reviews. Our AI model is always improving to protect you as you shop.",
            comment: "Label for the second paragraph of the Shopping Experience Opt In onboarding Card (Fakespot). %1$@ is the Fakespot, %2$@ is the company name (e.g. Mozilla).")
        public static let OptInCardLearnMoreButtonTitle = MZLocalizedString(
            key: "Shopping.OptInCard.LearnMoreButtonTitle.Title.v120",
            tableName: "Shopping",
            value: "Learn more",
            comment: "Label for the Learn more button in the Shopping Experience Opt In onboarding Card (Fakespot)")
        public static let OptInCardDisclaimerText = MZLocalizedString(
            key: "Shopping.OptInCard.Disclaimer.Text.v123",
            tableName: "Shopping",
            value: "By selecting “Yes, Try It” you agree to these items:",
            comment: "Text for the disclaimer that appears underneath the rating image of the Shopping Experience Opt In onboarding Card (Fakespot). After the colon, there will be two links, each on their own line. The first link is to a Privacy policy. The second link is to Terms of use.")
        public static let OptInCardPrivacyPolicy = MZLocalizedString(
            key: "Shopping.OptInCard.PrivacyPolicy.Button.Title.v123",
            tableName: "Shopping",
            value: "%@’s privacy notice",
            comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the Shopping Experience Opt In onboarding Card (Fakespot). %@ is the app name (e.g. Firefox).")
        public static let OptInCardTermsOfUse = MZLocalizedString(
            key: "Shopping.OptInCard.TermsOfUse.Button.Title.v123",
            tableName: "Shopping",
            value: "%@’s terms of use",
            comment: "Show Fakespot Terms of Use page in the Shopping Experience Opt In onboarding Card (Fakespot). %@ is the Fakespot name.")
        public static let OptInCardMainButtonTitle = MZLocalizedString(
            key: "Shopping.OptInCard.MainButton.Title.v120",
            tableName: "Shopping",
            value: "Yes, Try It",
            comment: "Text for the main button of the Shopping Experience Opt In onboarding Card (Fakespot)")
        public static let OptInCardSecondaryButtonTitle = MZLocalizedString(
            key: "Shopping.OptInCard.SecondaryButton.Title.v120",
            tableName: "Shopping",
            value: "Not now",
            comment: "Text for the secondary button of the Shopping Experience Opt In onboarding Card (Fakespot)")
        public static let WarningCardCheckNoConnectionTitle = MZLocalizedString(
            key: "Shopping.WarningCard.CheckNoConnection.Title.v120",
            tableName: "Shopping",
            value: "No Network Connection",
            comment: "Title for error card displayed to the user when the device is disconnected from the network.")
        public static let WarningCardCheckNoConnectionDescription = MZLocalizedString(
            key: "Shopping.WarningCard.CheckNoConnection.Description.v120",
            tableName: "Shopping",
            value: "Check your network connection and then try reloading the page.",
            comment: "Text for body of error card displayed to the user when the device is disconnected from the network.")
        public static let InfoCardNoInfoAvailableRightNowTitle = MZLocalizedString(
            key: "Shopping.InfoCard.NoInfoAvailableRightNow.Title.v120",
            tableName: "Shopping",
            value: "No Info Available Right Now",
            comment: "Title for info card when no information is available at the moment")
        public static let InfoCardNoInfoAvailableRightNowDescription = MZLocalizedString(
            key: "Shopping.InfoCard.NoInfoAvailableRightNow.Description.v120",
            tableName: "Shopping",
            value: "We’re working to resolve this issue. Please check back soon.",
            comment: "Description for info card when no information is available at the moment")
        public static let InfoCardFakespotDoesNotAnalyzeReviewsTitle = MZLocalizedString(
            key: "Shopping.InfoCard.FakespotDoesNotAnalyzeReviews.Title.v120",
            tableName: "Shopping",
            value: "Can’t Check These Reviews",
            comment: "Title for info card when Fakespot cannot analyze reviews for a certain product type")
        public static let InfoCardFakespotDoesNotAnalyzeReviewsDescription = MZLocalizedString(
            key: "Shopping.InfoCard.FakespotDoesNotAnalyzeReviews.Description.v120",
            tableName: "Shopping",
            value: "Unfortunately, we can’t check the review quality for certain types of products. For example, gift cards and streaming video, music, and games.",
            comment: "Title for info card when Fakespot cannot analyze reviews for a certain product type")
        public static let InfoCardNotEnoughReviewsTitle = MZLocalizedString(
            key: "Shopping.InfoCard.NotEnoughReviews.Title.v120",
            tableName: "Shopping",
            value: "Not Enough Reviews Yet",
            comment: "Title for info card when there are not enough reviews for a product")
        public static let InfoCardNotEnoughReviewsDescription = MZLocalizedString(
            key: "Shopping.InfoCard.NotEnoughReviews.Description.v120",
            tableName: "Shopping",
            value: "When this product has more reviews, we’ll be able to check their quality.",
            comment: "Description for info card when there are not enough reviews for a product")
        public static let InfoCardNeedsAnalysisTitle = MZLocalizedString(
            key: "Shopping.InfoCard.NeedsAnalysis.Title.v120",
            tableName: "Shopping",
            value: "New Info To Check",
            comment: "Title for info card when the product needs analysis")
        public static let InfoCardNeedsAnalysisPrimaryAction = MZLocalizedString(
            key: "Shopping.InfoCard.NeedsAnalysis.PrimaryAction.v120",
            tableName: "Shopping",
            value: "Check Now",
            comment: "Primary action title for info card when the product needs analysis")
        public static let InfoCardProgressAnalysisTitle = MZLocalizedString(
            key: "Shopping.InfoCard.ProgressAnalysis.Title.v123",
            tableName: "Shopping",
            value: "Checking review quality (%@)",
            comment: "Title for info card when the product is in analysis mode. %@ is the percentage of the analysis progress, ranging between 1 and 100.")
        public static let InfoCardProgressAnalysisDescription = MZLocalizedString(
            key: "Shopping.InfoCard.ProgressAnalysis.Description.v120",
            tableName: "Shopping",
            value: "This could take about 60 seconds.",
            comment: "Description for info card when the product is in analysis mode")
        public static let InfoCardProductNotInStockTitle = MZLocalizedString(
            key: "Shopping.InfoCard.ProductNotInStock.Title.v121",
            tableName: "Shopping",
            value: "Product Is Not Available",
            comment: "Title for the information card displayed by the review checker feature when the product the user is looking at is out of stock. This title is used for info card where the user can report if it's back in stock.")
        public static let InfoCardProductNotInStockDescription = MZLocalizedString(
            key: "Shopping.InfoCard.ProductNotInStock.Description.v121",
            tableName: "Shopping",
            value: "If you see this product is back in stock, report it and we’ll work on checking the reviews.",
            comment: "Description for the information card displayed by the review checker feature when the product the user is looking at is out of stock. This description is used for info card where the user can report if it's back in stock.")
        public static let InfoCardProductNotInStockPrimaryAction = MZLocalizedString(
            key: "Shopping.InfoCard.ProductNotInStock.PrimaryAction.v121",
            tableName: "Shopping",
            value: "Report Product Back in Stock",
            comment: "Primary action label for the information card displayed by the review checker feature when the product the user is looking at is out of stock. This primary action label is used for info card button where the user can report if it's back in stock.")
        public static let InfoCardReportSubmittedByCurrentUserTitle = MZLocalizedString(
            key: "Shopping.InfoCard.ReportSubmittedByCurrentUser.Title.v121",
            tableName: "Shopping",
            value: "Thanks for Reporting!",
            comment: "This title is displayed on the information card as a confirmation message after a user reports that a previously out-of-stock product is now available. It's meant to acknowledge the user's contribution and encourage community engagement by letting them know their report has been successfully submitted.")
        public static let InfoCardReportSubmittedByCurrentUserDescription = MZLocalizedString(
            key: "Shopping.InfoCard.ReportSubmittedByCurrentUser.Description.v121",
            tableName: "Shopping",
            value: "We should have info about this product’s reviews within 24 hours. Please check back.",
            comment: "This description appears beneath the confirmation title on the information card to inform the user that their report regarding the product stock status has been received and is being processed. It serves to set the expectation that the review information will be updated within 24 hours and invites the user to revisit the product page for updates.")
        public static let InfoCardInfoComingSoonTitle = MZLocalizedString(
            key: "Shopping.InfoCard.InfoComingSoon.Title.v121",
            tableName: "Shopping",
            value: "Info Coming Soon",
            comment: "Title for an information card that is displayed in the review checker section when certain details about a product or feature are not currently available but are expected to be provided soon. The message should imply that the user can look forward to receiving more information shortly.")
        public static let InfoCardInfoComingSoonDescription = MZLocalizedString(
            key: "Shopping.InfoCard.InfoComingSoon.Description.v121",
            tableName: "Shopping",
            value: "We should have info about this product’s reviews within 24 hours. Please check back.",
            comment: "Description text for an information card used in the review checker section. This message is displayed when the reviews for a product are not yet available but are expected to be provided within the next 24 hours. It serves to inform users of the short wait for reviews and encourages them to return soon for the updated information.")
        public static let AdCardTitleLabel = MZLocalizedString(
            key: "Shopping.AdCard.Title.v121",
            tableName: "Shopping",
            value: "More to consider",
            comment: "Title label for the Fakespot Ad card. This is displayed above a product image, suggested as an alternative to the product reviewed.")
        public static let AdCardFooterLabel = MZLocalizedString(
            key: "Shopping.AdCard.Footer.v121",
            tableName: "Shopping",
            value: "Ad by %@",
            comment: "Footer label from the Fakespot Ad card displayed for the related product we advertise. This is displayed below the ad card, suggested as an alternative to the product reviewed. %@ is the Fakespot.")
    }
}

// MARK: - Translation bar
extension String {
    public static let TranslateSnackBarPrompt = MZLocalizedString(
        key: "TranslationToastHandler.PromptTranslate.Title",
        tableName: nil,
        value: "This page appears to be in %1$@. Translate to %2$@ with %3$@?",
        comment: "Prompt for translation. %1$@ is the language the page is in. %2$@ is the name of our local language. %3$@ is the name of the service.")
    public static let TranslateSnackBarYes = MZLocalizedString(
        key: "TranslationToastHandler.PromptTranslate.OK",
        tableName: nil,
        value: "Yes",
        comment: "Button to allow the page to be translated to the user locale language")
    public static let TranslateSnackBarNo = MZLocalizedString(
        key: "TranslationToastHandler.PromptTranslate.Cancel",
        tableName: nil,
        value: "No",
        comment: "Button to disallow the page to be translated to the user locale language")
}

// MARK: - Display Theme
extension String {
    public static let SettingsDisplayThemeTitle = MZLocalizedString(
        key: "Settings.DisplayTheme.Title.v2",
        tableName: nil,
        value: "Theme",
        comment: "Title in main app settings for Theme settings")
    public static let SettingsAppearanceTitle = MZLocalizedString(
        key: "Settings.Appearance.Title.v137",
        tableName: nil,
        value: "Appearance",
        comment: "Title in main app settings for Appearance settings")
    public static let BrowserThemeSectionHeader = MZLocalizedString(
        key: "Settings.Appearance.BrowserTheme.SectionHeader.v137",
        tableName: nil,
        value: "Browser Theme",
        comment: "Browser theme settings section title in Appearance settings")
    public static let WebsiteAppearanceSectionHeader = MZLocalizedString(
        key: "Settings.Appearance.WebsiteAppearance.SectionHeader.v137",
        tableName: nil,
        value: "Website Appearance",
        comment: "Website Appearance settings section title in Appearance settings")
    public static let WebsiteDarkModeToggleTitle = MZLocalizedString(
        key: "Settings.Appearance.WebsiteDarkModeToggle.Title.v137",
        tableName: nil,
        value: "Website Dark Mode",
        comment: "Under Website Appearance section in Appearance menu, this is the title of the toggle to switch dark theme on/off.")
    public static let WebsiteDarkModeDescription = MZLocalizedString(
        key: "Settings.Appearance.WebsiteDarkMode.Description.v137",
        tableName: nil,
        value: "Gives websites a dark appearance. Some sites might not look right.",
        comment: "Under Website Appearance section in Appearance menu, this is the text under the toggle describing the dark mode feature.")
    public static let DisplayThemeBrightnessThresholdSectionHeader = MZLocalizedString(
        key: "Settings.DisplayTheme.BrightnessThreshold.SectionHeader",
        tableName: nil,
        value: "Threshold",
        comment: "Section header for brightness slider.")
    public static let DisplayThemeSectionFooter = MZLocalizedString(
        key: "Settings.DisplayTheme.SectionFooter",
        tableName: nil,
        value: "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes. The circle indicates your display’s current brightness.",
        comment: "Display (theme) settings footer describing how the brightness slider works.")
    public static let SystemThemeSectionHeader = MZLocalizedString(
        key: "Settings.DisplayTheme.SystemTheme.SectionHeader",
        tableName: nil,
        value: "System Theme",
        comment: "System theme settings section title")
    public static let SystemThemeSectionSwitchTitle = MZLocalizedString(
        key: "Settings.DisplayTheme.SystemTheme.SwitchTitle",
        tableName: nil,
        value: "Use System Light/Dark Mode",
        comment: "System theme settings switch to choose whether to use the same theme as the system")
    public static let ThemeSwitchModeSectionHeader = MZLocalizedString(
        key: "Settings.DisplayTheme.SwitchMode.SectionHeader",
        tableName: nil,
        value: "Switch Mode",
        comment: "Switch mode settings section title")
    public static let ThemePickerSectionHeader = MZLocalizedString(
        key: "Settings.DisplayTheme.ThemePicker.SectionHeader",
        tableName: nil,
        value: "Theme Picker",
        comment: "Theme picker settings section title")
    public static let DisplayThemeAutomaticSwitchTitle = MZLocalizedString(
        key: "Settings.DisplayTheme.SwitchTitle",
        tableName: nil,
        value: "Automatically",
        comment: "Display (theme) settings switch to choose whether to set the dark mode manually, or automatically based on the brightness slider.")
    public static let DisplayThemeAutomaticStatusLabel = MZLocalizedString(
        key: "Settings.DisplayTheme.StatusTitle",
        tableName: nil,
        value: "Automatic",
        comment: "Display (theme) settings label to show if automatically switch theme is enabled.")
    public static let DisplayThemeAutomaticSwitchSubtitle = MZLocalizedString(
        key: "Settings.DisplayTheme.SwitchSubtitle",
        tableName: nil,
        value: "Switch automatically based on screen brightness",
        comment: "Display (theme) settings switch subtitle, explaining the title 'Automatically'.")
    public static let DisplayThemeManualSwitchTitle = MZLocalizedString(
        key: "Settings.DisplayTheme.Manual.SwitchTitle",
        tableName: nil,
        value: "Manually",
        comment: "Display (theme) setting to choose the theme manually.")
    public static let DisplayThemeManualSwitchSubtitle = MZLocalizedString(
        key: "Settings.DisplayTheme.Manual.SwitchSubtitle",
        tableName: nil,
        value: "Pick which theme you want",
        comment: "Display (theme) settings switch subtitle, explaining the title 'Manually'.")
    public static let DisplayThemeManualStatusLabel = MZLocalizedString(
        key: "Settings.DisplayTheme.Manual.StatusLabel",
        tableName: nil,
        value: "Manual",
        comment: "Display (theme) settings label to show if manually switch theme is enabled.")
    public static let DisplayThemeOptionLight = MZLocalizedString(
        key: "Settings.DisplayTheme.OptionLight",
        tableName: nil,
        value: "Light",
        comment: "Option choice in display theme settings for light theme")
    public static let DisplayThemeOptionDark = MZLocalizedString(
        key: "Settings.DisplayTheme.OptionDark",
        tableName: nil,
        value: "Dark",
        comment: "Option choice in display theme settings for dark theme")
}

extension String {
    public static let AddTabAccessibilityLabel = MZLocalizedString(
        key: "TabTray.AddTab.Button",
        tableName: nil,
        value: "Add Tab",
        comment: "Accessibility label for the Add Tab button in the Tab Tray.")
}

// MARK: - Cover Sheet
extension String {
    // ETP Cover Sheet
    public static let CoverSheetETPTitle = MZLocalizedString(
        key: "CoverSheet.v24.ETP.Title",
        tableName: nil,
        value: "Protection Against Ad Tracking",
        comment: "Title for the new ETP mode i.e. standard vs strict")
    public static let CoverSheetETPDescription = MZLocalizedString(
        key: "CoverSheet.v24.ETP.Description",
        tableName: nil,
        value: "Built-in Enhanced Tracking Protection helps stop ads from following you around. Turn on Strict to block even more trackers, ads, and popups. ",
        comment: "Description for the new ETP mode i.e. standard vs strict")
    public static let CoverSheetETPSettingsButton = MZLocalizedString(
        key: "CoverSheet.v24.ETP.Settings.Button",
        tableName: nil,
        value: "Go to Settings",
        comment: "Text for the new ETP settings button")
}

// MARK: - FxA Signin screen
extension String {
    public static let FxASignin_Subtitle = MZLocalizedString(
        key: "fxa.signin.camera-signin",
        tableName: nil,
        value: "Sign In with Your Camera",
        comment: "FxA sign in view subtitle")
    public static let FxASignin_QRInstructions = MZLocalizedString(
        key: "fxa.signin.qr-link-instruction",
        tableName: nil,
        value: "On your computer open Firefox and go to firefox.com/pair",
        comment: "FxA sign in view qr code instructions")
    public static let FxASignin_QRScanSignin = MZLocalizedString(
        key: "fxa.signin.ready-to-scan",
        tableName: nil,
        value: "Ready to Scan",
        comment: "FxA sign in view qr code scan button")
    public static let FxASignin_EmailSignin = MZLocalizedString(
        key: "fxa.signin.use-email-instead",
        tableName: nil,
        value: "Use Email Instead",
        comment: "FxA sign in view email login button")
}

// MARK: - Today Widget Strings - [New Search - Private Search]
extension String {
    // Widget - Shared

    public static let QuickActionsGalleryTitle = MZLocalizedString(
        key: "TodayWidget.QuickActionsGalleryTitle",
        tableName: "Today",
        value: "Quick Actions",
        comment: "Quick Actions title when widget enters edit mode")
    public static let QuickActionsGalleryTitlev2 = MZLocalizedString(
        key: "TodayWidget.QuickActionsGalleryTitleV2",
        tableName: "Today",
        value: "Firefox Shortcuts",
        comment: "Firefox shortcuts title when widget enters edit mode. Do not translate the word Firefox.")

    // Quick Action - Medium Size Quick Action
    public static let GoToCopiedLinkLabel = MZLocalizedString(
        key: "TodayWidget.GoToCopiedLinkLabelV1",
        tableName: "Today",
        value: "Go to copied link",
        comment: "Go to link pasted on the clipboard")
    public static let GoToCopiedLinkLabelV2 = MZLocalizedString(
        key: "TodayWidget.GoToCopiedLinkLabelV2",
        tableName: "Today",
        value: "Go to\nCopied Link",
        comment: "Go to copied link")
    public static let ClosePrivateTab = MZLocalizedString(
        key: "TodayWidget.ClosePrivateTabsButton",
        tableName: "Today",
        value: "Close Private Tabs",
        comment: "Close Private Tabs button label")

    // Quick Action - Medium Size - Gallery View
    public static let FirefoxShortcutGalleryDescription = MZLocalizedString(
        key: "TodayWidget.FirefoxShortcutGalleryDescription",
        tableName: "Today",
        value: "Add Firefox shortcuts to your Home screen.",
        comment: "Description for medium size widget to add Firefox Shortcut to home screen")

    // Quick Action - Small Size Widget
    public static let SearchInPrivateTabLabelV2 = MZLocalizedString(
        key: "TodayWidget.SearchInPrivateTabLabelV2",
        tableName: "Today",
        value: "Search in\nPrivate Tab",
        comment: "Search in private tab")
    public static let SearchInFirefoxV2 = MZLocalizedString(
        key: "TodayWidget.SearchInFirefoxV2",
        tableName: "Today",
        value: "Search in\nFirefox",
        comment: "Search in Firefox. Do not translate the word Firefox")
    public static let ClosePrivateTabsLabelV2 = MZLocalizedString(
        key: "TodayWidget.ClosePrivateTabsLabelV2",
        tableName: "Today",
        value: "Close\nPrivate Tabs",
        comment: "Close Private Tabs")

    // Quick Action - Small Size - Gallery View
    public static let QuickActionGalleryDescription = MZLocalizedString(
        key: "TodayWidget.QuickActionGalleryDescription",
        tableName: "Today",
        value: "Add a Firefox shortcut to your Home screen. After adding the widget, touch and hold to edit it and select a different shortcut.",
        comment: "Description for small size widget to add it to home screen")

    // Top Sites - Medium Size - Gallery View
    public static let TopSitesGalleryTitle = MZLocalizedString(
        key: "TodayWidget.TopSitesGalleryTitle",
        tableName: "Today",
        value: "Top Sites",
        comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen")
    public static let TopSitesGalleryTitleV2 = MZLocalizedString(
        key: "TodayWidget.TopSitesGalleryTitleV2",
        tableName: "Today",
        value: "Website Shortcuts",
        comment: "Title for top sites widget to add Firefox top sites shotcuts to home screen")
    public static let TopSitesGalleryDescription = MZLocalizedString(
        key: "TodayWidget.TopSitesGalleryDescription",
        tableName: "Today",
        value: "Add shortcuts to frequently and recently visited sites.",
        comment: "Description for top sites widget to add Firefox top sites shotcuts to home screen")

    // Quick View Open Tabs - Medium Size Widget
    public static let MoreTabsLabel = MZLocalizedString(
        key: "TodayWidget.MoreTabsLabel",
        tableName: "Today",
        value: "+%d More…",
        comment: "%d represents number and it becomes something like +5 more where 5 is the number of open tabs in tab tray beyond what is displayed in the widget")
    public static let OpenFirefoxLabel = MZLocalizedString(
        key: "TodayWidget.OpenFirefoxLabel",
        tableName: "Today",
        value: "Open Firefox",
        comment: "Open Firefox when there are no tabs opened in tab tray i.e. Empty State")
    public static let NoOpenTabsLabel = MZLocalizedString(
        key: "TodayWidget.NoOpenTabsLabel",
        tableName: "Today",
        value: "No open tabs.",
        comment: "Label that is shown when there are no tabs opened in tab tray i.e. Empty State")

    // Quick View Open Tabs - Medium Size - Gallery View
    public static let QuickViewGalleryTitle = MZLocalizedString(
        key: "TodayWidget.QuickViewGalleryTitle",
        tableName: "Today",
        value: "Quick View",
        comment: "Title for Quick View widget in Gallery View where user can add it to home screen")
    public static let QuickViewGalleryDescriptionV2 = MZLocalizedString(
        key: "TodayWidget.QuickViewGalleryDescriptionV2",
        tableName: "Today",
        value: "Add shortcuts to your open tabs.",
        comment: "Description for Quick View widget in Gallery View where user can add it to home screen")
}

// MARK: - Default Browser
extension String {
    public static let DefaultBrowserMenuItem = MZLocalizedString(
        key: "Settings.DefaultBrowserMenuItem",
        tableName: "Default Browser",
        value: "Set as Default Browser",
        comment: "Menu option for setting Firefox as default browser.")
    public static let DefaultBrowserOnboardingScreenshot = MZLocalizedString(
        key: "DefaultBrowserOnboarding.Screenshot",
        tableName: "Default Browser",
        value: "Default Browser App",
        comment: "Text for the screenshot of the iOS system settings page for Firefox.")
    public static let DefaultBrowserOnboardingDescriptionStep1 = MZLocalizedString(
        key: "DefaultBrowserOnboarding.Description1",
        tableName: "Default Browser",
        value: "1. Go to Settings",
        comment: "Description for default browser onboarding card.")
    public static let DefaultBrowserOnboardingDescriptionStep2 = MZLocalizedString(
        key: "DefaultBrowserOnboarding.Description2",
        tableName: "Default Browser",
        value: "2. Tap Default Browser App",
        comment: "Description for default browser onboarding card.")
    public static let DefaultBrowserOnboardingDescriptionStep3 = MZLocalizedString(
        key: "DefaultBrowserOnboarding.Description3",
        tableName: "Default Browser",
        value: "3. Select Firefox",
        comment: "Description for default browser onboarding card.")
    public static let DefaultBrowserOnboardingButton = MZLocalizedString(
        key: "DefaultBrowserOnboarding.Button",
        tableName: "Default Browser",
        value: "Go to Settings",
        comment: "Button string to open settings that allows user to switch their default browser to Firefox.")
}

// MARK: - FxAWebViewController
extension String {
    public static let FxAWebContentAccessibilityLabel = MZLocalizedString(
        key: "Web content",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the main web content view")
}

// MARK: - QuickActions
extension String {
    public static let QuickActionsLastBookmarkTitle = MZLocalizedString(
        key: "Open Last Bookmark",
        tableName: "3DTouchActions",
        value: nil,
        comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch")
}

// MARK: - ClearPrivateDataAlert
extension String {
    public static let ClearPrivateDataAlertMessage = MZLocalizedString(
        key: "This action will clear all of your private data. It cannot be undone.",
        tableName: "ClearPrivateDataConfirm",
        value: nil,
        comment: "Description of the confirmation dialog shown when a user tries to clear their private data.")
    public static let ClearPrivateDataAlertCancel = MZLocalizedString(
        key: "Cancel",
        tableName: "ClearPrivateDataConfirm",
        value: nil,
        comment: "The cancel button when confirming clear private data.")
    public static let ClearPrivateDataAlertOk = MZLocalizedString(
        key: "OK",
        tableName: "ClearPrivateDataConfirm",
        value: nil,
        comment: "The button that clears private data.")
}

// MARK: - ClearWebsiteDataAlert
extension String {
    public static let ClearAllWebsiteDataAlertMessage = MZLocalizedString(
        key: "Settings.WebsiteData.ConfirmPrompt",
        tableName: nil,
        value: "This action will clear all of your website data. It cannot be undone.",
        comment: "Description of the confirmation dialog shown when a user tries to clear their private data.")
    public static let ClearSelectedWebsiteDataAlertMessage = MZLocalizedString(
        key: "Settings.WebsiteData.SelectedConfirmPrompt",
        tableName: nil,
        value: "This action will clear the selected items. It cannot be undone.",
        comment: "Description of the confirmation dialog shown when a user tries to clear some of their private data.")
    public static let ClearWebsiteDataAlertCancel = MZLocalizedString(
        key: "Cancel",
        tableName: "ClearPrivateDataConfirm",
        value: nil,
        comment: "The cancel button when confirming clear private data.")
    public static let ClearWebsiteDataAlertOk = MZLocalizedString(
        key: "OK",
        tableName: "ClearPrivateDataConfirm",
        value: nil,
        comment: "The button that clears private data.")
}

// MARK: - ClearSyncedHistoryAlert
extension String {
    public static let ClearSyncedHistoryAlertMessage = MZLocalizedString(
        key: "This action will clear all of your private data, including history from your synced devices.",
        tableName: "ClearHistoryConfirm",
        value: nil,
        comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.")
    public static let ClearSyncedHistoryAlertCancel = MZLocalizedString(
        key: "Cancel",
        tableName: "ClearHistoryConfirm",
        value: nil,
        comment: "The cancel button when confirming clear history.")
    public static let ClearSyncedHistoryAlertOk = MZLocalizedString(
        key: "OK",
        tableName: "ClearHistoryConfirm",
        value: nil,
        comment: "The confirmation button that clears history even when Sync is connected.")
}

// MARK: - DeleteLoginAlert
extension String {
    public static let DeleteLoginAlertTitle = MZLocalizedString(
        key: "DeleteLoginsAlert.Title.v122",
        tableName: "LoginManager",
        value: "Remove Password?",
        comment: "Title for the prompt that appears when the user deletes a login.")
    public static let DeleteLoginAlertSyncedMessage = MZLocalizedString(
        key: "DeleteLoginAlert.Message.Synced.v122",
        tableName: "LoginManager",
        value: "This will remove the password from all of your synced devices.",
        comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices")
    public static let DeleteLoginAlertLocalMessage = MZLocalizedString(
        key: "DeleteLoginAlert.Message.Local.v122",
        tableName: "LoginManager",
        value: "You cannot undo this action.",
        comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them, when they attempt to do so")
    public static let DeleteLoginAlertCancel = MZLocalizedString(
        key: "DeleteLoginAlert.DeleteButton.Cancel.v122",
        tableName: "LoginManager",
        value: "Cancel",
        comment: "Prompt option for cancelling out of deletion")
    public static let DeleteLoginAlertDelete = MZLocalizedString(
        key: "DeleteLoginAlert.DeleteButton.Title.v122",
        tableName: "LoginManager",
        value: "Remove",
        comment: "Label for the button used to delete the current login.")
}

// MARK: - Authenticator strings
extension String {
    public static let AuthenticatorCancel = MZLocalizedString(
        key: "Cancel",
        tableName: nil,
        value: nil,
        comment: "Label for Cancel button")
    public static let AuthenticatorLogin = MZLocalizedString(
        key: "Log in",
        tableName: nil,
        value: nil,
        comment: "Authentication prompt log in button")
    public static let AuthenticatorPromptTitle = MZLocalizedString(
        key: "Authentication required",
        tableName: nil,
        value: nil,
        comment: "Authentication prompt title")
    public static let AuthenticatorPromptRealmMessage = MZLocalizedString(
        key: "A username and password are being requested by %@. The site says: %@",
        tableName: nil,
        value: "A username and password are being requested by %1$@. The site says: %2$@",
        comment: "Authentication prompt message with a realm. %1$@ is the hostname, %2$@ is the realm string.")
    public static let AuthenticatorPromptEmptyRealmMessage = MZLocalizedString(
        key: "A username and password are being requested by %@.",
        tableName: nil,
        value: nil,
        comment: "Authentication prompt message with no realm. %@ is the hostname of the site.")
    public static let AuthenticatorUsernamePlaceholder = MZLocalizedString(
        key: "Username",
        tableName: nil,
        value: nil,
        comment: "Username textbox in Authentication prompt")
    public static let AuthenticatorPasswordPlaceholder = MZLocalizedString(
        key: "Password",
        tableName: nil,
        value: nil,
        comment: "Password textbox in Authentication prompt")
}

// MARK: - BrowserViewController
extension String {
    public static let ReaderModeAddPageGeneralErrorAccessibilityLabel = MZLocalizedString(
        key: "Could not add page to Reading list",
        tableName: nil,
        value: nil,
        comment: "Accessibility message e.g. spoken by VoiceOver after adding current webpage to the Reading List failed.")
    public static let ReaderModeAddPageSuccessAcessibilityLabel = MZLocalizedString(
        key: "Added page to Reading List",
        tableName: nil,
        value: nil,
        comment: "Accessibility message e.g. spoken by VoiceOver after the current page gets added to the Reading List using the Reader View button, e.g. by long-pressing it or by its accessibility custom action.")
    public static let ReaderModeAddPageMaybeExistsErrorAccessibilityLabel = MZLocalizedString(
        key: "Could not add page to Reading List. Maybe it’s already there?",
        tableName: nil,
        value: nil,
        comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures.")
    public static let WebViewAccessibilityLabel = MZLocalizedString(
        key: "Web content",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the main web content view")
}

// MARK: - Find in page
extension String {
    public static let FindInPagePreviousAccessibilityLabel = MZLocalizedString(
        key: "Previous in-page result",
        tableName: "FindInPage",
        value: nil,
        comment: "Accessibility label for previous result button in Find in Page Toolbar.")
    public static let FindInPageNextAccessibilityLabel = MZLocalizedString(
        key: "Next in-page result",
        tableName: "FindInPage",
        value: nil,
        comment: "Accessibility label for next result button in Find in Page Toolbar.")
    public static let FindInPageDoneAccessibilityLabel = MZLocalizedString(
        key: "Done",
        tableName: "FindInPage",
        value: nil,
        comment: "Done button in Find in Page Toolbar.")
}

// MARK: - Reader Mode Bar
extension String {
    public static let ReaderModeBarMarkAsRead = MZLocalizedString(
        key: "ReaderModeBar.MarkAsRead.v106",
        tableName: nil,
        value: "Mark as Read",
        comment: "Name for Mark as read button in reader mode")
    public static let ReaderModeBarMarkAsUnread = MZLocalizedString(
        key: "ReaderModeBar.MarkAsUnread.v106",
        tableName: nil,
        value: "Mark as Unread",
        comment: "Name for Mark as unread button in reader mode")
    public static let ReaderModeBarSettings = MZLocalizedString(
        key: "Display Settings",
        tableName: nil,
        value: nil,
        comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.")
    public static let ReaderModeBarAddToReadingList = MZLocalizedString(
        key: "Add to Reading List",
        tableName: nil,
        value: nil,
        comment: "Name for button adding current article to reading list in reader mode")
    public static let ReaderModeBarRemoveFromReadingList = MZLocalizedString(
        key: "Remove from Reading List",
        tableName: nil,
        value: nil,
        comment: "Name for button removing current article from reading list in reader mode")
}

// MARK: - SearchViewController
extension String {
    public static let SearchSettingsAccessibilityLabel = MZLocalizedString(
        key: "Search Settings",
        tableName: "Search",
        value: nil,
        comment: "Label for search settings button.")
    public static let SearchSearchEngineAccessibilityLabel = MZLocalizedString(
        key: "%@ search",
        tableName: "Search",
        value: nil,
        comment: "Label for search engine buttons. %@ is the name of the search engine.")
    public static let SearchSuggestionCellSwitchToTabLabel = MZLocalizedString(
        key: "Search.Awesomebar.SwitchToTab",
        tableName: nil,
        value: "Switch to tab",
        comment: "Search suggestion cell label that allows user to switch to tab which they searched for in url bar")
}

// MARK: - Tab Location View
extension String {
    public static let TabLocationURLPlaceholder = MZLocalizedString(
        key: "Search or enter address",
        tableName: nil,
        value: nil,
        comment: "The text shown in the URL bar on about:home")
    public static let TabLocationReaderModeAccessibilityLabel = MZLocalizedString(
        key: "Reader View",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the Reader View button")
    public static let TabLocationAddressBarAccessibilityLabel = MZLocalizedString(
        key: "Address.Bar.v99",
        tableName: nil,
        value: "Address Bar",
        comment: "Accessibility label for the Address Bar, where a user can enter the search they wish to make")
    public static let TabLocationReaderModeAddToReadingListAccessibilityLabel = MZLocalizedString(
        key: "Address.Bar.ReadingList.v106",
        tableName: nil,
        value: "Add to Reading List",
        comment: "Accessibility label for action adding current page to reading list.")
    public static let TabLocationReloadAccessibilityLabel = MZLocalizedString(
        key: "Reload page",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the reload button")
    public static let TabLocationReloadAccessibilityHint = MZLocalizedString(
        key: "Address.Bar.Reload.A11y.Hint.v124",
        tableName: "TabLocation",
        value: "Double tap and hold for more options",
        comment: "Accessibility hint for the reload button")
    public static let TabLocationShareAccessibilityLabel = MZLocalizedString(
        key: "TabLocation.Share.A11y.Label.v119",
        tableName: "TabLocation",
        value: "Share this page",
        comment: "Accessibility label for the share button in url bar")
    public static let TabLocationShoppingAccessibilityLabel = MZLocalizedString(
        key: "TabLocation.Shopping.A11y.Label.v120",
        tableName: "TabLocation",
        value: "Review Checker",
        comment: "Accessibility label for the shopping button in url bar")
    public static let TabLocationETPOnSecureAccessibilityLabel = MZLocalizedString(
        key: "TabLocation.ETP.On.Secure.A11y.Label.v119",
        tableName: "TabLocation",
        value: "Secure connection",
        comment: "Accessibility label for the security icon in url bar")
    public static let TabLocationETPOnNotSecureAccessibilityLabel = MZLocalizedString(
        key: "TabLocation.ETP.On.NotSecure.A11y.Label.v119",
        tableName: "TabLocation",
        value: "Connection not secure",
        comment: "Accessibility label for the security icon in url bar")
    public static let TabLocationETPOffNotSecureAccessibilityLabel = MZLocalizedString(
        key: "TabLocation.ETP.Off.NotSecure.A11y.Label.v119",
        tableName: "TabLocation",
        value: "Connection not secure. Enhanced Tracking Protection is off.",
        comment: "Accessibility label for the security icon in url bar")
    public static let TabLocationETPOffSecureAccessibilityLabel = MZLocalizedString(
        key: "TabLocation.ETP.Off.Secure.A11y.Label.v119",
        tableName: "TabLocation",
        value: "Secure connection. Enhanced Tracking Protection is off.",
        comment: "Accessibility label for the security icon in url bar")
    public static let TabLocationLockButtonLargeContentTitle = MZLocalizedString(
        key: "TabLocation.LockButton.LargeContentTitle.v122",
        tableName: "TabLocation",
        value: "Tracking Protection",
        comment: "Large content title for the lock button. This title is displayed when accessible font sizes are enabled")
    public static let TabLocationLockButtonAccessibilityLabel = MZLocalizedString(
        key: "TabLocation.LockButton.AccessibilityLabel.v122",
        tableName: "TabLocation",
        value: "Tracking Protection",
        comment: "Accessibility label for the lock / tracking protection button on the URL bar")
    public static let TabLocationShareButtonLargeContentTitle = MZLocalizedString(
        key: "TabLocation.ShareButton.AccessibilityLabel.v122",
        tableName: "TabLocation",
        value: "Share",
        comment: "Large content title for the share button. This title is displayed when using accessible font sizes is enabled")
    public static let TabsButtonShowTabsLargeContentTitle = MZLocalizedString(
        key: "TabsButton.Accessibility.LargeContentTitle.v122",
        tableName: "TabLocation",
        value: "Show Tabs: %@",
        comment: "Large content title for the tabs button. %@ is the number of open tabs or an infinity symbol. This title is displayed when using accessible font sizes is enabled.")
}

// MARK: - TabPeekViewController
extension String {
    public static let TabPeekAddToBookmarks = MZLocalizedString(
        key: "Add to Bookmarks",
        tableName: "3DTouchActions",
        value: nil,
        comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks")
    public static let TabPeekCopyUrl = MZLocalizedString(
        key: "Copy URL",
        tableName: "3DTouchActions",
        value: nil,
        comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard")
    public static let TabPeekCloseTab = MZLocalizedString(
        key: "Close Tab",
        tableName: "3DTouchActions",
        value: nil,
        comment: "Label for preview action on Tab Tray Tab to close the current tab")
}

// MARK: - Tab Toolbar
extension String {
    public static let TabToolbarDataClearanceAccessibilityLabel = MZLocalizedString(
        key: "TabToolbar.Accessibility.DataClearance.v122",
        tableName: "TabToolbar",
        value: "Data Clearance",
        comment: "Accessibility label for the tab toolbar fire button in private mode, used to provide users a way to end and delete their private session data.")
    public static let TabToolbarReloadAccessibilityLabel = MZLocalizedString(
        key: "Reload",
        tableName: nil,
        value: nil,
        comment: "Accessibility Label for the tab toolbar Reload button")
    public static let TabToolbarStopAccessibilityLabel = MZLocalizedString(
        key: "Stop",
        tableName: nil,
        value: nil,
        comment: "Accessibility Label for the tab toolbar Stop button")
    public static let TabToolbarSearchAccessibilityLabel = MZLocalizedString(
        key: "TabToolbar.Accessibility.Search.v106",
        tableName: nil,
        value: "Search",
        comment: "Accessibility Label for the tab toolbar Search button")
    public static let TabToolbarBackAccessibilityLabel = MZLocalizedString(
        key: "Back",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the Back button in the tab toolbar.")
    public static let TabToolbarForwardAccessibilityLabel = MZLocalizedString(
        key: "Forward",
        tableName: nil,
        value: nil,
        comment: "Accessibility Label for the tab toolbar Forward button")
    public static let TabToolbarHomeAccessibilityLabel = MZLocalizedString(
        key: "Home",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the tab toolbar indicating the Home button.")
    public static let TabToolbarNavigationToolbarAccessibilityLabel = MZLocalizedString(
        key: "Navigation Toolbar",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
}

// MARK: - Tab Tray v1
extension String {
    public static let TabTrayToggleAccessibilityLabel = MZLocalizedString(
        key: "PrivateBrowsing.Toggle.A11y.Label.v132",
        tableName: "PrivateBrowsing",
        value: "Private browsing",
        comment: "Accessibility label for toggling on/off private mode")
    public static let TabTrayToggleAccessibilityValueOn = MZLocalizedString(
        key: "On",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Toggled ON accessibility value")
    public static let TabTrayToggleAccessibilityValueOff = MZLocalizedString(
        key: "Off",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Toggled OFF accessibility value")
    public static let TabTrayViewAccessibilityLabel = MZLocalizedString(
        key: "Tabs Tray",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the Tabs Tray view.")
    public static let TabTrayNoTabsAccessibilityHint = MZLocalizedString(
        key: "No tabs",
        tableName: nil,
        value: nil,
        comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray")
    public static let TabTrayVisibleTabRangeAccessibilityHint = MZLocalizedString(
        key: "Tab %@ of %@",
        tableName: nil,
        value: "Tab %1$@ of %2$@",
        comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray (%1$@), along with the total number of tabs (%2$@). E.g. “Tab 2 of 5” says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
    public static let TabTrayVisiblePartialRangeAccessibilityHint = MZLocalizedString(
        key: "Tabs %@ to %@ of %@",
        tableName: nil,
        value: "Tabs %1$@ to %2$@ of %3$@",
        comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray (%1$@ to %2$@), along with the total number of tabs (%3$@). E.g. “Tabs 8 to 10 of 15” says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
    public static let TabTrayClosingTabAccessibilityMessage =  MZLocalizedString(
        key: "Closing tab",
        tableName: nil,
        value: nil,
        comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed.")
    public static let TabTrayCloseAllTabsPromptCancel = MZLocalizedString(
        key: "Cancel",
        tableName: nil,
        value: nil,
        comment: "Label for Cancel button")
    public static let TabTrayPrivateBrowsingTitle = MZLocalizedString(
        key: "Private Browsing",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Title displayed for when there are no open tabs while in private mode")
    public static let TabTrayPrivateBrowsingDescription =  MZLocalizedString(
        key: "Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Description text displayed when there are no open tabs while in private mode")
    public static let TabTrayAddTabAccessibilityLabel = MZLocalizedString(
        key: "Add Tab",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the Add Tab button in the Tab Tray.")
    public static let TabTrayCloseAccessibilityCustomAction = MZLocalizedString(
        key: "Close",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for action denoting closing a tab in tab list (tray)")
    public static let TabTraySwipeToCloseAccessibilityHint = MZLocalizedString(
        key: "Swipe right or left with three fingers to close the tab.",
        tableName: nil,
        value: nil,
        comment: "Accessibility hint for tab tray's displayed tab.")
    public static let TabTrayCurrentlySelectedTabAccessibilityLabel = MZLocalizedString(
        key: "TabTray.CurrentSelectedTab.A11Y",
        tableName: nil,
        value: "Currently selected tab.",
        comment: "Accessibility label for the currently selected tab.")
    public static let TabTrayOtherTabsSectionHeader = MZLocalizedString(
        key: "TabTray.Header.FilteredTabs.SectionHeader",
        tableName: nil,
        value: "Others",
        comment: "In the tab tray, when tab groups appear and there exist tabs that don't belong to any group, those tabs are listed under this header as “Others”.")
}

// MARK: - URL Bar
extension String {
    public static let URLBarLocationAccessibilityLabel = MZLocalizedString(
        key: "Address and Search",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
}

extension String {
    public struct Toolbars {
        public static let NewTabButton = MZLocalizedString(
            key: "Toolbar.NewTab.Button.v130",
            tableName: "Toolbar",
            value: "New Tab",
            comment: "Accessibility label for the new tab button that can be displayed in the navigation or address toolbar.")

        public static let TabsButtonAccessibilityLabel = MZLocalizedString(
            key: "Toolbar.Tabs.Button.A11y.Label.v135",
            tableName: "Toolbar",
            value: "Tabs open",
            comment: "Accessibility label for the tabs button in the toolbar, specifing the number of tabs open.")

        public static let TabsButtonLargeContentTitle = MZLocalizedString(
            key: "Toolbar.Tabs.Button.A11y.LargeContentTitle.v137",
            tableName: "Toolbar",
            value: "Tabs open: %@",
            comment: "Large content title for the tabs button in the toolbar, specifying the number of tabs open. %@ is the number of open tabs.")

        public static let TabsButtonOverflowLargeContentTitle = MZLocalizedString(
            key: "Toolbar.Tabs.Button.A11y.OverflowLargeContentTitle.v137",
            tableName: "Toolbar",
            value: "Tabs open: 99+",
            comment: "Large content title for the tabs button in the toolbar, specifying that more than 99 tabs are open.")

        public static let MenuButtonAccessibilityLabel = MZLocalizedString(
            key: "Toolbar.Menu.Button.A11y.Label.v135",
            tableName: "Toolbar",
            value: "Main Menu",
            comment: "Accessibility label for the Main Menu button in the toolbar, specifing that the button will open Main Menu")

        public struct TabToolbarLongPressActionsMenu {
            public static let CloseThisTabButton = MZLocalizedString(
                key: "Toolbar.Tab.CloseThisTab.Button.v130",
                tableName: "Toolbar",
                value: "Close This Tab",
                comment: "Label for button on action sheet, accessed via long pressing tab toolbar button, that closes the current tab when pressed"
            )
        }
    }

    public struct AddressToolbar {
        public static let LocationPlaceholder = MZLocalizedString(
            key: "AddressToolbar.Location.Placeholder.v128",
            tableName: "AddressToolbar",
            value: "Search or enter address",
            comment: "Placeholder for the address field in the address toolbar.")

        public static let SearchEngineA11yLabel = MZLocalizedString(
            key: "AddressToolbar.SearchEngine.A11y.Label.v128",
            tableName: "AddressToolbar",
            value: "Search Engine: %@",
            comment: "Accessibility label for the search engine icon in the address bar. %@ is the name of the search engine (e.g. Google).")

        public static let SearchEngineA11yHint = MZLocalizedString(
            key: "AddressToolbar.SearchEngine.A11y.Hint.v133",
            tableName: "AddressToolbar",
            value: "Opens search engine selection",
            comment: "When the user taps the search engine icon in the toolbar, a sheet with a list of alternative search engines appears. This is the accessibility hint describing what tapping the search engine icon does.")

        public static let PrivacyAndSecuritySettingsA11yLabel = MZLocalizedString(
            key: "AddressToolbar.PrivacyAndSecuriySettings.A11y.Label.v128",
            tableName: "AddressToolbar",
            value: "Privacy & Security Settings",
            comment: "Accessibility label for the lock icon button in the address field of the address toolbar, responsible with Privacy & Security Settings.")

        public static let CancelEditButtonLabel = MZLocalizedString(
            key: "AddressToolbar.CancelEdit.Label.v138",
            tableName: "AddressToolbar",
            value: "Cancel",
            comment: "Label for button in the address toolbar, that cancels editing the address field when tapped.")
    }
}

// MARK: - Error Pages
extension String {
    public static let ErrorPageTryAgain = MZLocalizedString(
        key: "Try again",
        tableName: "ErrorPages",
        value: nil,
        comment: "Shown in error pages on a button that will try to load the page again")
    public static let ErrorPageOpenInSafari = MZLocalizedString(
        key: "Open in Safari",
        tableName: "ErrorPages",
        value: nil,
        comment: "Shown in error pages for files that can't be shown and need to be downloaded.")
}

// MARK: - LibraryPanel
extension String {
    public static let LibraryPanelBookmarksAccessibilityLabel = MZLocalizedString(
        key: "LibraryPanel.Accessibility.Bookmarks.v106",
        tableName: nil,
        value: "Bookmarks",
        comment: "Panel accessibility label")
    public static let LibraryPanelHistoryAccessibilityLabel = MZLocalizedString(
        key: "LibraryPanel.Accessibility.History.v106",
        tableName: nil,
        value: "History",
        comment: "Panel accessibility label")
    public static let LibraryPanelReadingListAccessibilityLabel = MZLocalizedString(
        key: "Reading list",
        tableName: nil,
        value: nil,
        comment: "Panel accessibility label")
    public static let LibraryPanelDownloadsAccessibilityLabel = MZLocalizedString(
        key: "Downloads",
        tableName: nil,
        value: nil,
        comment: "Panel accessibility label")
}

// MARK: - ReaderPanel
extension String {
    public static let ReaderPanelRemove = MZLocalizedString(
        key: "Remove",
        tableName: nil,
        value: nil,
        comment: "Title for the button that removes a reading list item")
    public static let ReaderPanelMarkAsRead = MZLocalizedString(
        key: "Mark as Read",
        tableName: nil,
        value: nil,
        comment: "Title for the button that marks a reading list item as read")
    public static let ReaderPanelMarkAsUnread =  MZLocalizedString(
        key: "Mark as Unread",
        tableName: nil,
        value: nil,
        comment: "Title for the button that marks a reading list item as unread")
    public static let ReaderPanelUnreadAccessibilityLabel = MZLocalizedString(
        key: "unread",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for unread article in reading list. It's a past participle - functions as an adjective.")
    public static let ReaderPanelReadAccessibilityLabel = MZLocalizedString(
        key: "read",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for read article in reading list. It's a past participle - functions as an adjective.")
    public static let ReaderPanelWelcome = MZLocalizedString(
        key: "Welcome to your Reading List",
        tableName: nil,
        value: nil,
        comment: "See http://mzl.la/1LXbDOL")
    public static let ReaderPanelReadingModeDescription = MZLocalizedString(
        key: "Open articles in Reader View by tapping the book icon when it appears in the title bar.",
        tableName: nil,
        value: nil,
        comment: "See http://mzl.la/1LXbDOL")
    public static let ReaderPanelReadingListDescription = MZLocalizedString(
        key: "Save pages to your Reading List by tapping the book plus icon in the Reader View controls.",
        tableName: nil,
        value: nil,
        comment: "See http://mzl.la/1LXbDOL")
}

// MARK: - Remote Tabs Panel
extension String {
    public static let RemoteTabErrorNoTabs = MZLocalizedString(
        key: "You don’t have any tabs open in Firefox on your other devices.",
        tableName: nil,
        value: nil,
        comment: "Error message in the remote tabs panel")
    public static let RemoteTabErrorFailedToSync = MZLocalizedString(
        key: "There was a problem accessing tabs from your other devices. Try again in a few moments.",
        tableName: nil,
        value: nil,
        comment: "Error message in the remote tabs panel")
    public static let RemoteTabMobileAccessibilityLabel =  MZLocalizedString(
        key: "mobile device",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for Mobile Device image in remote tabs list")
    public static let RemoteTabCreateAccount = MZLocalizedString(
        key: "Create an account",
        tableName: nil,
        value: nil,
        comment: "See http://mzl.la/1Qtkf0j")
}

// MARK: - Login list
extension String {
    public static let LoginListDeselctAll = MZLocalizedString(
        key: "Deselect All",
        tableName: "LoginManager",
        value: nil,
        comment: "Label for the button used to deselect all logins.")
    public static let LoginListSelctAll = MZLocalizedString(
        key: "Select All",
        tableName: "LoginManager",
        value: nil,
        comment: "Label for the button used to select all logins.")
    public static let LoginListDelete = MZLocalizedString(
        key: "Delete",
        tableName: "LoginManager",
        value: nil,
        comment: "Label for the button used to delete the current login.")
    public static let LoginListDeleteToast = MZLocalizedString(
        key: "LoginList.DeleteToast.v135",
        tableName: "LoginManager",
        value: "Password removed",
        comment: "This message appears briefly as a notification (toast) to inform the user that a password has been successfully removed.")
}

// MARK: - Login Detail
extension String {
    public static let LoginDetailUsername = MZLocalizedString(
        key: "Username",
        tableName: "LoginManager",
        value: nil,
        comment: "Label displayed above the username row in Login Detail View.")
    public static let LoginDetailPassword = MZLocalizedString(
        key: "Password",
        tableName: "LoginManager",
        value: nil,
        comment: "Label displayed above the password row in Login Detail View.")
    public static let LoginDetailWebsite = MZLocalizedString(
        key: "Website",
        tableName: "LoginManager",
        value: nil,
        comment: "Label displayed above the website row in Login Detail View.")
    public static let LoginDetailCreatedAt =  MZLocalizedString(
        key: "Created %@",
        tableName: "LoginManager",
        value: nil,
        comment: "Label describing when the current login was created. %@ is the timestamp.")
    public static let LoginDetailModifiedAt = MZLocalizedString(
        key: "Modified %@",
        tableName: "LoginManager",
        value: nil,
        comment: "Label describing when the current login was last modified. %@ is the timestamp.")
    public static let LoginDetailDelete = MZLocalizedString(
        key: "Delete",
        tableName: "LoginManager",
        value: nil,
        comment: "Label for the button used to delete the current login.")
}

// MARK: - No Logins View
extension String {
    public static let NoLoginsFound = MZLocalizedString(
        key: "NoLoginsFound.Title.v122",
        tableName: "LoginManager",
        value: "No passwords found",
        comment: "Label displayed when no logins are found after searching.")
}

// MARK: - Reader Mode Handler
extension String {
    public static let ReaderModeHandlerLoadingContent = MZLocalizedString(
        key: "Loading content…",
        tableName: nil,
        value: nil,
        comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModeHandlerPageCantDisplay = MZLocalizedString(
        key: "The page could not be displayed in Reader View.",
        tableName: nil,
        value: nil,
        comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModeHandlerLoadOriginalPage = MZLocalizedString(
        key: "Load original page",
        tableName: nil,
        value: nil,
        comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModeHandlerError = MZLocalizedString(
        key: "There was an error converting the page",
        tableName: nil,
        value: nil,
        comment: "Error displayed when reader mode cannot be enabled")
}

// MARK: - ReaderModeStyle
extension String {
    public static let ReaderModeStyleBrightnessAccessibilityLabel = MZLocalizedString(
        key: "Brightness",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings")
    public static let ReaderModeStyleFontTypeAccessibilityLabel = MZLocalizedString(
        key: "Changes font type.",
        tableName: nil,
        value: nil,
        comment: "Accessibility hint for the font type buttons in reader mode display settings")
    public static let ReaderModeStyleSansSerifFontType = MZLocalizedString(
        key: "Sans-serif",
        tableName: nil,
        value: nil,
        comment: "Font type setting in the reading view settings")
    public static let ReaderModeStyleSerifFontType = MZLocalizedString(
        key: "Serif",
        tableName: nil,
        value: nil,
        comment: "Font type setting in the reading view settings")
    public static let ReaderModeStyleSmallerLabel = MZLocalizedString(
        key: "-",
        tableName: nil,
        value: nil,
        comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeStyleSmallerAccessibilityLabel = MZLocalizedString(
        key: "Decrease text size",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for button decreasing font size in display settings of reader mode")
    public static let ReaderModeStyleLargerLabel = MZLocalizedString(
        key: "+",
        tableName: nil,
        value: nil,
        comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeStyleLargerAccessibilityLabel = MZLocalizedString(
        key: "Increase text size",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for button increasing font size in display settings of reader mode")
    public static let ReaderModeStyleFontSize = MZLocalizedString(
        key: "Aa",
        tableName: nil,
        value: nil,
        comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeStyleChangeColorSchemeAccessibilityHint = MZLocalizedString(
        key: "Changes color theme.",
        tableName: nil,
        value: nil,
        comment: "Accessibility hint for the color theme setting buttons in reader mode display settings")
    public static let ReaderModeStyleLightLabel = MZLocalizedString(
        key: "Light",
        tableName: nil,
        value: nil,
        comment: "Light theme setting in Reading View settings")
    public static let ReaderModeStyleDarkLabel = MZLocalizedString(
        key: "Dark",
        tableName: nil,
        value: nil,
        comment: "Dark theme setting in Reading View settings")
    public static let ReaderModeStyleSepiaLabel = MZLocalizedString(
        key: "Sepia",
        tableName: nil,
        value: nil,
        comment: "Sepia theme setting in Reading View settings")
}

// MARK: - Empty Private tab view
extension String {
    public static let PrivateBrowsingLearnMore = MZLocalizedString(
        key: "Learn More",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Text button displayed when there are no tabs open while in private mode")
    public static let PrivateBrowsingTitle = MZLocalizedString(
        key: "Private Browsing",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Title displayed for when there are no open tabs while in private mode")
}

// MARK: - Advanced Account Setting
extension String {
    public static let AdvancedAccountUseStageServer = MZLocalizedString(
        key: "Use stage servers",
        tableName: nil,
        value: nil,
        comment: "Debug option")
}

// MARK: - App Settings
extension String {
    public static let AppSettingsLicenses = MZLocalizedString(
        key: "Licenses",
        tableName: nil,
        value: nil,
        comment: "Settings item that opens a tab containing the licenses. See http://mzl.la/1NSAWCG")
    public static let AppSettingsTermsOfUse = MZLocalizedString(
        key: "Settings.TermsOfUse.Title.v137",
        tableName: "Settings",
        value: "Terms of Use",
        comment: "Terms of Use settings section title")
    public static let AppSettingsShowTour = MZLocalizedString(
        key: "Show Tour",
        tableName: nil,
        value: nil,
        comment: "Show the on-boarding screen again from the settings")
    public static let AppSettingsSendFeedback = MZLocalizedString(
        key: "Send Feedback",
        tableName: nil,
        value: nil,
        comment: "Menu item in settings used to open input.mozilla.org where people can submit feedback")
    public static let AppSettingsHelp = MZLocalizedString(
        key: "Help",
        tableName: nil,
        value: nil,
        comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ")
    public static let AppSettingsSearch = MZLocalizedString(
        key: "Search",
        tableName: nil,
        value: nil,
        comment: "Open search section of settings")
    public static let AppSettingsPrivacyNotice = MZLocalizedString(
        key: "Settings.PrivacyNotice.Title.v137",
        tableName: "Settings",
        value: "Privacy Notice",
        comment: "Show Firefox Browser Privacy Notice page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/")
    public static let AppSettingsTitle = MZLocalizedString(
        key: "Settings",
        tableName: nil,
        value: nil,
        comment: "Title in the settings view controller title bar")
    public static let AppSettingsDone = MZLocalizedString(
        key: "Done",
        tableName: nil,
        value: nil,
        comment: "Done button on left side of the Settings view controller title bar")
    public static let AppSettingsPrivacyTitle = MZLocalizedString(
        key: "Privacy",
        tableName: nil,
        value: nil,
        comment: "Privacy section title")
    public static let AppSettingsBlockPopups = MZLocalizedString(
        key: "Block Pop-up Windows",
        tableName: nil,
        value: nil,
        comment: "Block pop-up windows setting")
    public static let AppSettingsClosePrivateTabsTitle = MZLocalizedString(
        key: "Close Private Tabs",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Setting for closing private tabs")
    public static let AppSettingsClosePrivateTabsDescription = MZLocalizedString(
        key: "When Leaving Private Browsing",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Will be displayed in Settings under 'Close Private Tabs'")
    public static let AppSettingsSupport = MZLocalizedString(
        key: "Support",
        tableName: nil,
        value: nil,
        comment: "Support section title")
    public static let AppSettingsAbout = MZLocalizedString(
        key: "About",
        tableName: nil,
        value: nil,
        comment: "About settings section title")
}

// MARK: - Clearables
extension String {
    // Removed Clearables as part of Bug 1226654, but keeping the string around.
    private static let removedSavedLoginsLabel = MZLocalizedString(
        key: "Saved Logins",
        tableName: "ClearPrivateData",
        value: nil,
        comment: "Settings item for clearing passwords and login data")

    public static let ClearableHistory = MZLocalizedString(
        key: "Browsing History",
        tableName: "ClearPrivateData",
        value: nil,
        comment: "Settings item for clearing browsing history")
    public static let ClearableCache = MZLocalizedString(
        key: "Cache",
        tableName: "ClearPrivateData",
        value: nil,
        comment: "Settings item for clearing the cache")
    public static let ClearableOfflineData = MZLocalizedString(
        key: "Offline Website Data",
        tableName: "ClearPrivateData",
        value: nil,
        comment: "Settings item for clearing website data")
    public static let ClearableCookies = MZLocalizedString(
        key: "Cookies",
        tableName: "ClearPrivateData",
        value: nil,
        comment: "Settings item for clearing cookies")
    public static let ClearableDownloads = MZLocalizedString(
        key: "Downloaded Files",
        tableName: "ClearPrivateData",
        value: nil,
        comment: "Settings item for deleting downloaded files")
    public static let ClearableSpotlight = MZLocalizedString(
        key: "Spotlight Index",
        tableName: "ClearPrivateData",
        value: nil,
        comment: "A settings item that allows a user to use Apple's “Spotlight Search” in Data Management's Website Data option to search for and select an item to delete.")
}

// MARK: - SearchEngine Picker
extension String {
    public static let SearchEnginePickerTitle = MZLocalizedString(
        key: "Default Search Engine",
        tableName: nil,
        value: nil,
        comment: "Title for default search engine picker.")
    public static let SearchEnginePickerCancel = MZLocalizedString(
        key: "Cancel",
        tableName: nil,
        value: nil,
        comment: "Label for Cancel button")
}

// MARK: - SettingsContent
extension String {
    public static let SettingsContentPageLoadError = MZLocalizedString(
        key: "Could not load page.",
        tableName: nil,
        value: nil,
        comment: "Error message that is shown in settings when there was a problem loading")
}

// MARK: - SearchInput
extension String {
    public static let SearchInputAccessibilityLabel = MZLocalizedString(
        key: "Search Input Field",
        tableName: "LoginManager",
        value: nil,
        comment: "Accessibility label for the search input field in the Logins list")
    public static let SearchInputTitle = MZLocalizedString(
        key: "SearchInput.Title.Search.v106",
        tableName: "LoginManager",
        value: "Search",
        comment: "Title for the search field at the top of the Logins list screen")
    public static let SearchInputClearAccessibilityLabel = MZLocalizedString(
        key: "Clear Search",
        tableName: "LoginManager",
        value: nil,
        comment: "Accessibility message e.g. spoken by VoiceOver after the user taps the close button in the search field to clear the search and exit search mode")
    public static let SearchInputEnterSearchMode = MZLocalizedString(
        key: "Enter Search Mode",
        tableName: "LoginManager",
        value: nil,
        comment: "Accessibility label for entering search mode for logins")
}

// MARK: - TabsButton
extension String {
    public static let TabsButtonShowTabsAccessibilityLabel = MZLocalizedString(
        key: "Show Tabs",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the tabs button in the (top) tab toolbar")
}

// MARK: - TabTrayButtons
extension String {
    public static let TabTrayButtonNewTabAccessibilityLabel = MZLocalizedString(
        key: "New Tab",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for the New Tab button in the tab toolbar.")
    public static let TabTrayButtonShowTabsAccessibilityLabel = MZLocalizedString(
        key: "TabTrayButtons.Accessibility.ShowTabs.v106",
        tableName: nil,
        value: "Show Tabs",
        comment: "Accessibility Label for the tabs button in the tab toolbar")
}

// MARK: - MenuHelper
extension String {
    public static let MenuHelperPasteAndGo = MZLocalizedString(
        key: "UIMenuItem.PasteGo",
        tableName: nil,
        value: "Paste & Go",
        comment: "The menu item that pastes the current contents of the clipboard into the URL bar and navigates to the page")
    public static let MenuHelperReveal = MZLocalizedString(
        key: "Reveal",
        tableName: "LoginManager",
        value: nil,
        comment: "Reveal password text selection menu item")
    public static let MenuHelperHide =  MZLocalizedString(
        key: "Hide",
        tableName: "LoginManager",
        value: nil,
        comment: "Hide password text selection menu item")
    public static let MenuHelperCopy = MZLocalizedString(
        key: "Copy",
        tableName: "LoginManager",
        value: nil,
        comment: "Copy password text selection menu item")
    public static let MenuHelperOpenAndFill = MZLocalizedString(
        key: "Open & Fill",
        tableName: "LoginManager",
        value: nil,
        comment: "Open and Fill website text selection menu item")
    public static let MenuHelperFindInPage = MZLocalizedString(
        key: "Find in Page",
        tableName: "FindInPage",
        value: nil,
        comment: "Text selection menu item")
    public static let MenuHelperSearchWithFirefox = MZLocalizedString(
        key: "UIMenuItem.SearchWithFirefox",
        tableName: nil,
        value: "Search with Firefox",
        comment: "Search in New Tab Text selection menu item")
}

// MARK: - DeviceInfo
extension String {
    public static let DeviceInfoClientNameDescription = MZLocalizedString(
        key: "%@ on %@",
        tableName: "Shared",
        value: "%1$@ on %2$@",
        comment: "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs. %1$@ is the app name, %2$@ is the device name.")
}

// MARK: - TimeConstants
extension String {
    public static let TimeConstantMoreThanAMonth = MZLocalizedString(
        key: "more than a month ago",
        tableName: nil,
        value: nil,
        comment: "Relative date for dates older than a month and less than two months.")
    public static let TimeConstantMoreThanAWeek = MZLocalizedString(
        key: "more than a week ago",
        tableName: nil,
        value: nil,
        comment: "Description for a date more than a week ago, but less than a month ago.")
    public static let TimeConstantYesterday = MZLocalizedString(
        key: "TimeConstants.Yesterday.v106",
        tableName: nil,
        value: "yesterday",
        comment: "Relative date for yesterday.")
    public static let TimeConstantThisWeek = MZLocalizedString(
        key: "this week",
        tableName: nil,
        value: nil,
        comment: "Relative date for date in past week.")
    public static let TimeConstantRelativeToday = MZLocalizedString(
        key: "today at %@",
        tableName: nil,
        value: nil,
        comment: "Relative date for date older than a minute. %@ is the time.")
    public static let TimeConstantJustNow = MZLocalizedString(
        key: "just now",
        tableName: nil,
        value: nil,
        comment: "Relative time for a tab that was visited within the last few moments.")
}

// MARK: - Default Suggested Site
extension String {
    public static let DefaultSuggestedFacebook = MZLocalizedString(
        key: "Facebook",
        tableName: nil,
        value: nil,
        comment: "Tile title for Facebook")
    public static let DefaultSuggestedYouTube = MZLocalizedString(
        key: "YouTube",
        tableName: nil,
        value: nil,
        comment: "Tile title for YouTube")
    public static let DefaultSuggestedAmazon = MZLocalizedString(
        key: "Amazon",
        tableName: nil,
        value: nil,
        comment: "Tile title for Amazon")
    public static let DefaultSuggestedWikipedia = MZLocalizedString(
        key: "Wikipedia",
        tableName: nil,
        value: nil,
        comment: "Tile title for Wikipedia")
    public static let DefaultSuggestedTwitter = MZLocalizedString(
        key: "Twitter",
        tableName: nil,
        value: nil,
        comment: "Tile title for Twitter")
    public static let DefaultSuggestedX = MZLocalizedString(
        key: "SuggestedSites.X.Title.v131",
        tableName: "SuggestedSites",
        value: "X",
        comment: "Title for X (formerly Twitter) tile in the suggested sites section of the homepage.")
}

// MARK: - Credential Provider
extension String {
    public static let LoginsWelcomeViewTitle2 = MZLocalizedString(
        key: "Logins.WelcomeView.Title2",
        tableName: nil,
        value: "AutoFill Firefox Passwords",
        comment: "Label displaying welcome view title")
    public static let LoginsWelcomeViewTagline = MZLocalizedString(
        key: "Logins.WelcomeView.Tagline",
        tableName: nil,
        value: "Take your passwords everywhere",
        comment: "Label displaying welcome view tagline under the title")
    public static let LoginsWelcomeTurnOnAutoFillButtonTitle = MZLocalizedString(
        key: "Logins.WelcomeView.TurnOnAutoFill",
        tableName: nil,
        value: "Turn on AutoFill",
        comment: "Title of the big blue button to enable AutoFill")
    public static let LoginsListSearchCancel = MZLocalizedString(
        key: "LoginsList.Search.Cancel",
        tableName: nil,
        value: "Cancel",
        comment: "Title for cancel button for user to stop searching for a particular login")
    public static let LoginsListSearchPlaceholderCredential = MZLocalizedString(
        key: "LoginsList.Search.Placeholder.v122",
        tableName: "CredentialProvider",
        value: "Search passwords",
        comment: "Placeholder text for search field in the credential provider list")
    public static let LoginsListSelectPasswordTitle = MZLocalizedString(
        key: "LoginsList.SelectPassword.Title",
        tableName: nil,
        value: "Select a password to fill",
        comment: "Label displaying select a password to fill instruction")
    public static let LoginsListNoMatchingResultTitle = MZLocalizedString(
        key: "LoginsList.NoMatchingResult.Title.v122",
        tableName: "CredentialProvider",
        value: "No passwords found",
        comment: "Label displayed when a user searches for an item, and no matches can be found against the search query")
    public static let LoginsListNoMatchingResultSubtitle = MZLocalizedString(
        key: "LoginsList.NoMatchingResult.Subtitle",
        tableName: nil,
        value: "There are no results matching your search.",
        comment: "Label that appears after the search if there are no logins matching the search")
    public static let LoginsListNoLoginsFoundTitle = MZLocalizedString(
        key: "LoginsList.NoLoginsFound.Title.v122",
        tableName: "CredentialProvider",
        value: "No passwords saved",
        comment: "Label shown when there are no logins saved in the passwords list")
    public static let LoginsListNoLoginsFoundDescription = MZLocalizedString(
        key: "LoginsList.NoLoginsFound.Description.v122",
        tableName: "CredentialProvider",
        value: "The passwords you save or sync to %@ will be listed here. All passwords you save are encrypted.",
        comment: "Label shown when there are no logins to list. %@ is the app name (e.g. Firefox).")
    public static let LoginsPasscodeRequirementWarning = MZLocalizedString(
        key: "Logins.PasscodeRequirement.Warning",
        tableName: nil,
        value: "To use the AutoFill feature for Firefox, you must have a device passcode enabled.",
        comment: "Warning message shown when you try to enable or use native AutoFill without a device passcode setup")
    public static let CredentialProviderRetryAlertTitle = MZLocalizedString(
        key: "CredentialProvider.RetryAllert.Title.v137",
        tableName: "CredentialProvider",
        value: "Autofill Error",
        comment: "Title label displayed for an alert when the password autofill fails and needs user interaction.")
    public static let CredentialProviderRetryAlertMessage = MZLocalizedString(
        key: "CredentialProvider.RetryAllert.Message.v137",
        tableName: "CredentialProvider",
        value: "There was an issue with autofill. Please try again.",
        comment: "Message label displayed for an alert when the password autofill fails and needs user interaction.")
    public static let CredentialProviderRetryAlertRetryActionTitle = MZLocalizedString(
        key: "CredentialProvider.RetryAllert.RetryAction.Title.v137",
        tableName: "CredentialProvider",
        value: "Retry",
        comment: "Title label displayed for the retry action in an alert when the password autofill fails and needs user interaction.")
    public static let CredentialProviderRetryAlertCancelActionTitle = MZLocalizedString(
        key: "CredentialProvider.RetryAllert.CancelAction.Title.v137",
        tableName: "CredentialProvider",
        value: "Cancel",
        comment: "Title label displayed for the cancel action in an alert when the password autofill fails and needs user interaction.")
}

// MARK: - Password autofill
extension String {
    public struct PasswordAutofill {
        public static let UseSavedPasswordFromKeyboard = MZLocalizedString(
            key: "PasswordAutofill.UseSavedPasswordFromKeyboard.v124",
            tableName: "PasswordAutofill",
            value: "Use saved password",
            comment: "Displayed inside the keyboard hint when a user is entering their login credentials and has at least one saved password. Indicates that there are stored passwords available for use in filling out the login form.")
        public static let UseSavedPasswordFromHeader = MZLocalizedString(
            key: "PasswordAutofill.UseSavedPasswordFromHeader.v124",
            tableName: "PasswordAutofill",
            value: "Use saved password?",
            comment: "This label is used in the password list screen header as a question, prompting the user if they want to use a saved password for logging in.")
        public static let LoginListCellNoUsername = MZLocalizedString(
            key: "PasswordAutofill.LoginListCellNoUsername.v129",
            tableName: "PasswordAutofill",
            value: "(no username)",
            comment: "This label is used in a cell found in the list of autofill login options in place of an actual username to denote that no username was saved for this login")
        public static let ManagePasswordsButton = MZLocalizedString(
            key: "PasswordAutofill.ManagePasswordsButton.v124",
            tableName: "PasswordAutofill",
            value: "Manage passwords",
            comment: "This label is used for a button in the password list screen allowing users to manage their saved passwords. It's meant to direct users to where they can add, remove, or edit their saved passwords.")
        public static let SignInWithSavedPassword = MZLocalizedString(
            key: "PasswordAutofill.SignInWithSavedPassword.v124",
            tableName: "PasswordAutofill",
            value: "You’ll sign into %@",
            comment: "This phrase is used as a subtitle in the header of password list screen, indicating to the user that they will be logging into a specific website (represented by %@) using a saved password. It's providing clarity on which website the saved credentials apply to.")
    }
}

// MARK: - Password generator
extension String {
    public struct PasswordGenerator {
        public static let Title = MZLocalizedString(
            key: "PasswordGenerator.Title.v132",
            tableName: "PasswordGenerator",
            value: "Use a strong password?",
            comment: "Title text displayed as part of a popup displayed when a user interacts with the password field in a signup form. A random password has been generated for the user -- clicking a button fills in the password of the signup form with this generated password.")
        public static let Description = MZLocalizedString(
            key: "PasswordGenerator.Description.v132",
            tableName: "PasswordGenerator",
            value: "Protect your account by using a strong, randomly generated password.",
            comment: "Text displayed when a user interacts with the password field in a signup form, as part of a popup. This popup allows the user to generate a password that they have the option to use when signing up for an account.")
        public static let UsePasswordButtonLabel = MZLocalizedString(
            key: "PasswordGenerator.UsePasswordButtonLabel.v132",
            tableName: "PasswordGenerator",
            value: "Use Password",
            comment: "Label of a button that is part of a popup displayed when a user interacts with the password field in a signup form. A random password has been generated for the user and clicking this button fills in the password field of the signup form with this generated password.")
        public static let A11yLabel = MZLocalizedString(
            key: "PasswordGenerator.A11yLabel.v132",
            tableName: "PasswordGenerator",
            value: "Password Generator",
            comment: "Accessibility label describing a feature that generates a password when the password field of a signup form is interacted with.")
        public static let CloseButtonA11yLabel = MZLocalizedString(
            key: "PasswordGenerator.CloseButtonA11ylabel.v132",
            tableName: "PasswordGenerator",
            value: "Close",
            comment: "Accessibility label describing the close button for the popup related to a feature that generates a password when the password field of a signup form is interacted with.")
        public static let RefreshPasswordButtonA11yLabel = MZLocalizedString(
            key: "PasswordGenerator.RefreshPasswordButtonA11yLabel.v132",
            tableName: "PasswordGenerator",
            value: "Generate a new strong password",
            comment: "Accessibility label describing a refresh password button belonging to a popup that generates a password when the password field of a signup form is interacted with.")
        public static let PasswordReadoutPrefaceA11y = MZLocalizedString(
            key: "PasswordGenerator.PasswordReadoutPrefaceA11y.v132",
            tableName: "PasswordGenerator",
            value: "Generated password: %@",
            comment: "Prefix to alert accessibility users that a generated password (represented by %@) will be read to them next.")
        public static let CopyPasswordButtonLabel = MZLocalizedString(
            key: "PasswordGenerator.CopyPasswordButtonLabel.v132",
            tableName: "PasswordGenerator",
            value: "Copy",
            comment: "When a user is in the process of creating an account, they have the option to generate a password. The user is capable of copying this password after long pressing the value of the password displayed to them. This string is the label of the copy button that appears after long pressing the password.")
        public static let KeyboardAccessoryButtonLabel = MZLocalizedString(
            key: "PasswordGenerator.KeyboardAccessoryButtonLabel.v132",
            tableName: "PasswordGenerator",
            value: "Use strong password",
            comment: "When a user is in the process of creating an account, they have the option to generate a password. The popup displaying the generated password to the user is available by clicking a keyboard accessory button with this label.")
    }
}

// MARK: - Live Activity
extension String {
    public struct LiveActivity {
        public struct Downloads {
            public static let FileNameText = MZLocalizedString(
                key: "LiveActivity.Downloads.FileNameText.v138",
                tableName: "LiveActivity",
                value: "Downloading “%@”",
                comment: "Displayed during a download in Live Activity or Dynamic Island. %@ is the name of the file being downloaded (e.g. Downloading “MyFile.pdf”).")
            public static let FileCountText = MZLocalizedString(
                key: "LiveActivity.Downloads.FileCountText.v138",
                tableName: "LiveActivity",
                value: "Downloading Files: %@",
                comment: "Displayed during a download in Live Activity or Dynamic Island. %@ is the number of files (e.g. Downloading Files: 2).")
            public static let FileProgressText = MZLocalizedString(
                key: "LiveActivity.Downloads.FileProgressText.v138",
                tableName: "LiveActivity",
                value: "%1$@ of %2$@",
                comment: "Displayed during a download in Live Activity or Dynamic Island to show the current progress of the file(s) download. %1$@ is the downloaded size, %2$@ is the total size of the file(s) (e.g. 10 MB of 200 MB).")
        }
    }
}

// MARK: - v35 Strings
extension String {
    public static let FirefoxHomeJumpBackInSectionTitle = MZLocalizedString(
        key: "ActivityStream.JumpBackIn.SectionTitle",
        tableName: nil,
        value: "Jump Back In",
        comment: "Title for the Jump Back In section. This section allows users to jump back in to a recently viewed tab")
    public static let TabsTrayInactiveTabsSectionTitle = MZLocalizedString(
        key: "TabTray.InactiveTabs.SectionTitle",
        tableName: nil,
        value: "Inactive Tabs",
        comment: "Title for the inactive tabs section. This section groups all tabs that haven't been used in a while.")
}

// MARK: - v36 Strings
extension String {
    public static let ProtectionStatusSecure = MZLocalizedString(
        key: "ProtectionStatus.Secure",
        tableName: nil,
        value: "Connection is secure",
        comment: "This is the value for a label that indicates if a user is on a secure https connection.")
    public static let ProtectionStatusNotSecure = MZLocalizedString(
        key: "ProtectionStatus.NotSecure",
        tableName: nil,
        value: "Connection is not secure",
        comment: "This is the value for a label that indicates if a user is on an unencrypted website.")
}

// MARK: - Strings to be removed
extension String {
    /// For more detailed information on how to use this struct, please see
    /// https://github.com/mozilla-mobile/firefox-ios/wiki/How-to-add-and-modify-Strings#oldstrings-struct
    struct OldStrings {
        struct v133 {
            public static let LocationA11yLabel = MZLocalizedString(
                key: "AddressToolbar.Location.A11y.Label.v128",
                tableName: "AddressToolbar",
                value: "Search or enter address",
                comment: "Accessibility label for the address field in the address toolbar.")
            public static let Tools = MZLocalizedString(
                key: "MainMenu.ToolsSection.AccessibilityLabels.Tools.v132",
                tableName: "MainMenu",
                value: "Tools",
                comment: "On the main menu, the accessibility label for the action that will take the user to the Tools submenu in the menu.")
            public static let Save = MZLocalizedString(
                key: "MainMenu.ToolsSection.AccessibilityLabels.Save.v132",
                tableName: "MainMenu",
                value: "Save",
                comment: "On the main menu, the accessibility label for the action that will take the user to the Save submenu in the menu. In the main menu, there is an option called Save that is taking the user to the Save submenu where user can share, bookmark the page and so on.")
        }
        struct v134 {
            public struct RestoreTabs {
                public static let Title = MZLocalizedString(
                    key: "Alerts.RestoreTabs.Title.v109.v2",
                    tableName: "Alerts",
                    value: "%@ crashed. Restore your tabs?",
                    comment: "The title of the restore tabs pop-up alert. This alert is displayed when opening up Firefox after it crashed. %@ is the name of the app (e.g. Firefox).")
                public static let Message = MZLocalizedString(
                    key: "Alerts.RestoreTabs.Message.v109",
                    tableName: "Alerts",
                    value: "Sorry about that. Restore tabs to pick up where you left off.",
                    comment: "The body of the restore tabs pop-up alert. This alert is displayed when opening up Firefox after it crashed.")
                public static let ButtonNo = MZLocalizedString(
                    key: "Alerts.RestoreTabs.Button.No.v109",
                    tableName: "Alerts",
                    value: "No",
                    comment: "The title for the negative action of the restore tabs pop-up alert. This alert is displayed when opening up Firefox after it crashed, and will reject the action of restoring tabs.")
                public static let ButtonYes = MZLocalizedString(
                    key: "Alerts.RestoreTabs.Button.Yes.v109",
                    tableName: "Alerts",
                    value: "Restore tabs",
                    comment: "The title for the affirmative action of the restore tabs pop-up alert. This alert is displayed when opening up Firefox after it crashed, and will restore existing tabs.")
            }
            public static let CrashOptInAlertTitle = MZLocalizedString(
                key: "Oops! Firefox crashed",
                tableName: nil,
                value: nil,
                comment: "Title for prompt displayed to user after the app crashes")
            public static let CrashOptInAlertMessage = MZLocalizedString(
                key: "Send a crash report so Mozilla can fix the problem?",
                tableName: nil,
                value: nil,
                comment: "Message displayed in the crash dialog above the buttons used to select when sending reports")
            public static let CrashOptInAlertSend = MZLocalizedString(
                key: "Send Report",
                tableName: nil,
                value: nil,
                comment: "Used as a button label for crash dialog prompt")
            public static let CrashOptInAlertAlwaysSend = MZLocalizedString(
                key: "Always Send",
                tableName: nil,
                value: nil,
                comment: "Used as a button label for crash dialog prompt")
            public static let CrashOptInAlertDontSend = MZLocalizedString(
                key: "Don’t Send",
                tableName: nil,
                value: nil,
                comment: "Used as a button label for crash dialog prompt")
        }
        struct v135 {
            public static let LearnMore = MZLocalizedString(
                key: "Onboarding.TermsOfService.PrivacyPreferences.LearnMore.v135",
                tableName: "Onboarding",
                value: "Learn more.",
                comment: "A text that indicate to the user, a link button is available to be clicked for reading more information about the option that is going to choose in Manage Privacy Preferences screen, where user can choose from the option to send data to Firefox or not.")
            public static let SendTechnicalDataSettingTitle = MZLocalizedString(
                key: "Settings.TechnicalData.Title.v135",
                tableName: "Settings",
                value: "Technical and Interaction Data",
                comment: "On the Settings screen, this is the title text for a toggle which controls sending technical and interaction data.")
            public static let SendTechnicalDataSettingLink = MZLocalizedString(
                key: "Settings.TechnicalData.Link.v135",
                tableName: "Settings",
                value: "Learn More.",
                comment: "Title for a link that explains how Mozilla send technical and interaction data.")
            public static let SendTechnicalDataSettingMessage = MZLocalizedString(
                key: "Settings.TechnicalData.Message.v135",
                tableName: "Settings",
                value: "%1$@ strives to only collect what we need to provide and improve %2$@ for everyone.",
                comment: "On the Settings screen, this is the subtitle text for a toggle which controls sending technical and interaction data. %1$@ is the company name (e.g. Mozilla), %2$@ is the app name (e.g. Firefox).")
            public static let SendDailyUsagePingSettingLink = MZLocalizedString(
                key: "Settings.DailyUsagePing.Link.v135",
                tableName: "Settings",
                value: "Learn More.",
                comment: "Title for a link that explains how Mozilla send daily usage ping.")
            public static let TermsOfServiceLink = MZLocalizedString(
                key: "Onboarding.TermsOfService.TermsOfServiceLink.v135",
                tableName: "Onboarding",
                value: "%@ Terms of Service.",
                comment: "Title for the Terms of Service button link, in the Terms of Service screen for redirecting the user to the Terms of Service page. %@ is the app name (e.g. Firefox).")
            public static let SendCrashReportsSettingMessage = MZLocalizedString(
                key: "Settings.CrashReports.Message.v135",
                tableName: "Settings",
                value: "Crash reports allow us to diagnose and fix issues with the browser.",
                comment: "On the Settings screen, this is the subtitle text for a toggle which controls automatically sending crash reports.")
            public static let AgreementButtonTitle = MZLocalizedString(
                key: "Onboarding.TermsOfService.AgreementButtonTitle.v135",
                tableName: "Onboarding",
                value: "Agree and continue",
                comment: "Title for the confirmation button for Terms of Service agreement, in the Terms of Service screen.")
            public static let SendUsageSettingTitle = MZLocalizedString(
                key: "Settings.SendUsage.Title",
                tableName: nil,
                value: "Send Usage Data",
                comment: "The title for the setting to send usage data.")
            public static let SendUsageSettingLink = MZLocalizedString(
                key: "Settings.SendUsage.Link",
                tableName: nil,
                value: "Learn More.",
                comment: "title for a link that explains how mozilla collects telemetry")
            public static let SendUsageSettingMessage = MZLocalizedString(
                key: "Settings.SendUsage.Message",
                tableName: nil,
                value: "Mozilla strives to only collect what we need to provide and improve Firefox for everyone.",
                comment: "A short description that explains why mozilla collects usage data.")
            public static let SettingsStudiesToggleTitle = MZLocalizedString(
                key: "Settings.Studies.Toggle.Title",
                tableName: nil,
                value: "Studies",
                comment: "Label used as a toggle item in Settings. When this is off, the user is opting out of all studies.")
            public static let SettingsStudiesToggleLink = MZLocalizedString(
                key: "Settings.Studies.Toggle.Link",
                tableName: nil,
                value: "Learn More.",
                comment: "Title for a link that explains what Mozilla means by Studies")
            public static let SettingsStudiesToggleMessage = MZLocalizedString(
                key: "Settings.Studies.Toggle.Message",
                tableName: nil,
                value: "Firefox may install and run studies from time to time.",
                comment: "A short description that explains that Mozilla is running studies")
            public static let SendCrashReportsSettingLink = MZLocalizedString(
                key: "Settings.CrashReports.Link.v135",
                tableName: "Settings",
                value: "Learn More.",
                comment: "Title for a link that explains how Mozilla send crash reports.")
        }
        struct v136 {
            public static let ExternalLinkGenericConfirmation = MZLocalizedString(
                key: "ExternalLink.AppStore.GenericConfirmationTitle",
                tableName: nil,
                value: "Open this link in external app?",
                comment: "Question shown to user when tapping an SMS or MailTo link that opens the external app for those.")
            public static let AppSettingsPrivacyPolicy = MZLocalizedString(
                key: "Privacy Policy",
                tableName: nil,
                value: nil,
                comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/")
            public static let AppSettingsYourRights = MZLocalizedString(
                key: "Your Rights",
                tableName: nil,
                value: nil,
                comment: "Your Rights settings section title")
        }
        struct v137 {
            public static let ShareMessageA = MZLocalizedString(
                key: "SentFromFirefox.SocialShare.ShareMessageA.Title.v134",
                tableName: "SocialShare",
                value: "%1$@ Sent from %2$@ 🦊 Try the mobile browser: %3$@",
                comment: "When a user shares a link to social media, this is the shared text they'll see in the social media app. %1$@  is the shared website's URL. %2$@ is the app name (e.g. Firefox). %3$@ is the link to download the app.")
            public static let ShareMessageB = MZLocalizedString(
                key: "SentFromFirefox.SocialShare.ShareMessageB.Title.v134",
                tableName: "SocialShare",
                value: "%1$@ Sent from %2$@ 🦊 %3$@",
                comment: "When a user shares a link to social media, this is the shared text they'll see in the social media app. %1$@  is the shared website's URL. %2$@ is the app name (e.g. Firefox). %3$@ is the link to download the app.")
            public static let TabsTitle = MZLocalizedString(
                key: "Settings.Tabs.Title",
                tableName: nil,
                value: "Tabs",
                comment: "In the settings menu, this is the title for the Tabs customization section option")
        }
        struct v138 {
            public static let ClearHistoryMenuTitle = MZLocalizedString(
                key: "LibraryPanel.History.ClearHistoryMenuTitle.v100",
                tableName: nil,
                value: "Removes history (including history synced from other devices), cookies and other browsing data.",
                comment: "Within the History Panel, users can open an action menu to clear recent history.")
            public static let ClearHistoryMenuOptionTheLastHour = MZLocalizedString(
                key: "HistoryPanel.ClearHistoryMenuOptionTheLastHour",
                tableName: nil,
                value: "The Last Hour",
                comment: "Button to perform action to clear history for the last hour")
            public static let ClearHistoryMenuOptionToday = MZLocalizedString(
                key: "HistoryPanel.ClearHistoryMenuOptionToday",
                tableName: nil,
                value: "Today",
                comment: "Button to perform action to clear history for today only")
            public static let ClearHistoryMenuOptionTodayAndYesterday = MZLocalizedString(
                key: "HistoryPanel.ClearHistoryMenuOptionTodayAndYesterday",
                tableName: nil,
                value: "Today and Yesterday",
                comment: "Button to perform action to clear history for yesterday and today")
            public static let ClearHistoryMenuOptionEverything = MZLocalizedString(
                key: "HistoryPanel.ClearHistoryMenuOptionEverything",
                tableName: nil,
                value: "Everything",
                comment: "Option title to clear all browsing history.")
            public static let Today = MZLocalizedString(
                key: "Today",
                tableName: nil,
                value: "Today",
                comment: "This label is meant to signify the section containing a group of items from the current day.")
            public static let Yesterday = MZLocalizedString(
                key: "Yesterday",
                tableName: nil,
                value: "Yesterday",
                comment: "This label is meant to signify the section containing a group of items from the past 24 hours.")
            public static let LastWeek = MZLocalizedString(
                key: "Last week",
                tableName: nil,
                value: "Last week",
                comment: "This label is meant to signify the section containing a group of items from the past seven days.")
            public static let LastMonth = MZLocalizedString(
                key: "Last month",
                tableName: nil,
                value: "Last month",
                comment: "This label is meant to signify the section containing a group of items from the past thirty days.")
        }
    }
}

// swiftlint:enable line_length
