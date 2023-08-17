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
///   - lastUsedInVersion: Whenever we remove or modify a string, we keep the translated version of that string a bit longer to ensure the last version it was
///   used in will be release in the App Store before we remove the string from the l10n repository
private func MZLocalizedString(
    key: String,
    tableName: String?,
    value: String?,
    comment: String,
    lastUsedInVersion: Int? = nil
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
        public struct RestoreTabs {
            public static let Title = MZLocalizedString(
                key: "Alerts.RestoreTabs.Title.v109.v2",
                tableName: "Alerts",
                value: "%@ crashed. Restore your tabs?",
                comment: "The title of the restore tabs pop-up alert. This alert shows when opening up Firefox after it crashed. The placeholder will be the Firefox name.")
            public static let Message = MZLocalizedString(
                key: "Alerts.RestoreTabs.Message.v109",
                tableName: "Alerts",
                value: "Sorry about that. Restore tabs to pick up where you left off.",
                comment: "The body of the restore tabs pop-up alert. This alert shows when opening up Firefox after it crashed.")
            public static let ButtonNo = MZLocalizedString(
                key: "Alerts.RestoreTabs.Button.No.v109",
                tableName: "Alerts",
                value: "No",
                comment: "The title for the negative action of the restore tabs pop-up alert. This alert shows when opening up Firefox after it crashed, and will reject the action of restoring tabs.")
            public static let ButtonYes = MZLocalizedString(
                key: "Alerts.RestoreTabs.Button.Yes.v109",
                tableName: "Alerts",
                value: "Restore tabs",
                comment: "The title for the affirmative action of the restore tabs pop-up alert. This alert shows when opening up Firefox after it crashed, and will restore existing tabs.")
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
                key: "Biometry.Screen.UniversalAuthenticationReasonV2.v116",
                tableName: "BiometricAuthentication",
                value: "Authenticate to access your saved logins and encrypted cards.",
                comment: "Biometric authentication is when the system prompts users for Face ID or fingerprint before accessing protected information. This string asks the user to enter their device passcode to access the protected screen for logins and encrypted cards.")
        }
    }
}

// MARK: - Bookmarks Menu
extension String {
    public struct Bookmarks {
        public struct Menu {
            public static let DesktopBookmarks = MZLocalizedString(
                key: "Bookmarks.Menu.DesktopBookmarks",
                tableName: nil,
                value: "Desktop Bookmarks",
                comment: "A label indicating all bookmarks grouped under the category 'Desktop Bookmarks'.")
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
        }
    }
}

// MARK: - Credit card
extension String {
    public struct CreditCard {
        // Settings / Empty State / Keyboard input accessory view
        public struct Settings {
            public static let EmptyListTitle = MZLocalizedString(
                key: "CreditCard.Settings.EmptyListTitle.v112",
                tableName: "Settings",
                value: "Save Credit Cards to %@",
                comment: "Title label for when there are no credit cards shown in credit card list in autofill settings screen. %@ is the product name and should not be altered.")
            public static let EmptyListDescription = MZLocalizedString(
                key: "CreditCard.Settings.EmptyListDescription.v112",
                tableName: "Settings",
                value: "Save your card information securely to check out faster next time.",
                comment: "Description label for when there are no credit cards shown in credit card list in autofill settings screen.")
            public static let RememberThisCard = MZLocalizedString(
                key: "CreditCard.Settings.RememberThisCard.v112",
                tableName: "Settings",
                value: "Remember this card?",
                comment: "When a user is in the process or has finished making a purchase with a card not saved in Firefox's list of stored cards, we ask the user if they would like to save this card for future purchases. This string is a title string of the overall message that asks the user if they would like Firefox to remember the card that is being used.")
            public static let Yes = MZLocalizedString(
                key: "CreditCard.Settings.Yes.v112",
                tableName: "Settings",
                value: "Yes",
                comment: "When a user is in the process or has finished making a purchase with a card not saved in Firefox's list of stored cards, we ask the user if they would like to save this card for future purchases. This string asks users to confirm if they would like Firefox to remember the card that is being used.")
            public static let NotNow = MZLocalizedString(
                key: "CreditCard.Settings.NotNow.v112",
                tableName: "Settings",
                value: "Not now",
                comment: "When a user is in the process or has finished making a purchase with a card not saved in Firefox's list of stored cards, we ask the user if they would like to save this card for future purchases. This string indicates to users that they can deny Firefox from remembering the card that is being used.")
            public static let UpdateThisCard = MZLocalizedString(
                key: "CreditCard.Settings.UpdateThisCard.v112",
                tableName: "Settings",
                value: "Update this card?",
                comment: "When a user is in the process or has finished making a purchase with a remembered card, and if the credit card information doesn't match the contents of the stored information of that card, we show this string. We ask this user if they would like Firefox update the staled information of that credit card.")
            public static let ManageCards = MZLocalizedString(
                key: "CreditCards.Settings.ManageCards.v112",
                tableName: "Settings",
                value: "Manage cards",
                comment: "When a user is in the process or has finished making a purchase, and has at least one card saved, we show this tappable string. This indicates to users that they can navigate to their list of stored credit cards in the app's credit card list screen.")
            public static let UseASavedCard = MZLocalizedString(
                key: "CreditCards.Settings.UseASavedCard.v112",
                tableName: "Settings",
                value: "Use a saved card?",
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
                comment: "Accessibility label for a credit card list item in autofill settings screen. The first parameter is the credit card issuer (e.g. Visa). The second parameter is is the name of the credit card holder. The third parameter is the last 4 digits of the credit card. The fourth parameter is the card's expiration date.")
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
                key: "CreditCard.EditCard.AddCreditCardTitle.v113",
                tableName: "EditCard",
                value: "Add Credit Card",
                comment: "Title label for the view where user can add their credit card info")
            public static let EditCreditCardTitle = MZLocalizedString(
                key: "CreditCard.EditCard.EditCreditCardTitle.v113",
                tableName: "Edit Card",
                value: "Edit Credit Card",
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
                key: "CreditCard.EditCard.ToggleToAllowAutofillTitle.v112",
                tableName: "EditCard",
                value: "Save and Autofill Cards",
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
                key: "CreditCard.RememberCard.MainTitle.v115",
                tableName: "RememberCard",
                value: "Remember this card?",
                comment: "This value is used as the title for the remember credit card page")
            public static let Header = MZLocalizedString(
                key: "CreditCard.RememberCard.Header.v115",
                tableName: "RememberCard",
                value: "Save your card information securely with %@ to check out faster next time.",
                comment: "This value is used as the header for the remember card page. The placeholder is for the app name.")
            public static let MainButtonTitle = MZLocalizedString(
                key: "CreditCard.RememberCard.MainButtonTitle.v115",
                tableName: "RememberCard",
                value: "Yes",
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
                key: "CreditCard.UpdateCard.MainTitle.v115",
                tableName: "UpdateCard",
                value: "Update this card?",
                comment: "This value is used as the title for the update card page")
            public static let ManageCardsButtonTitle = MZLocalizedString(
                key: "CreditCard.UpdateCard.ManageCardsButtonTitle.v115",
                tableName: "UpdateCard",
                value: "Manage cards",
                comment: "This value is used as the title for the Manage Cards button from the update credit card page")
            public static let MainButtonTitle = MZLocalizedString(
                key: "CreditCard.UpdateCard.YesButtonTitle.v115",
                tableName: "UpdateCard",
                value: "Yes",
                comment: "This value is used as the title for the button in the update credit card page")
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
                key: "CreditCard.SelectCreditCard.MainTitle.v116",
                tableName: "SelectCreditCard",
                value: "Use a saved card?",
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
                key: "CreditCard.SnackBar.UpdatedCardLabel.v112",
                tableName: "SnackBar",
                value: "Card Information updated",
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
                key: "CreditCard.SnackBar.RemoveCardTitle.v112",
                tableName: "Alert",
                value: "Remove This Card?",
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
                comment: "Button text to dismiss the dialog box that gets presented as a confirmation to to remove card and cancel the the operation.")

            public static let RemovedCardLabel = MZLocalizedString(
                key: "CreditCard.SnackBar.RemovedCardButton.v112",
                tableName: "Alert",
                value: "Remove",
                comment: "Button text to dismiss the dialog box that gets presented as a confirmation to to remove card and perform the operation of removing the credit card.")
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
                    comment: "Title for small home tab banner shown that allows the user to switch their default browser to Firefox.")
                public static let HomeTabBannerDescription = MZLocalizedString(
                    key: "DefaultBrowserCard.Description",
                    tableName: "Default Browser",
                    value: "Set links from websites, emails, and Messages to open automatically in Firefox.",
                    comment: "Description for small home tab banner shown that allows the user to switch their default browser to Firefox.")
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
                    comment: "Title for small home tab banner shown that allows the user to switch their default browser to Firefox.")
                public static let PeaceOfMindDescription = MZLocalizedString(
                    key: "DefaultBrowserCard.PeaceOfMind.Description.v108",
                    tableName: "Default Browser",
                    value: "Firefox blocks 3,000+ trackers per user each month on average. Make us your default browser for privacy peace of mind.",
                    comment: "Description for small home tab banner shown that allows the user to switch their default browser to Firefox.")
                public static let BetterInternetTitle = MZLocalizedString(
                    key: "DefaultBrowserCard.BetterInternet.Title.v108",
                    tableName: "Default Browser",
                    value: "Default to a Better Internet",
                    comment: "Title for small home tab banner shown that allows the user to switch their default browser to Firefox.")
                public static let BetterInternetDescription = MZLocalizedString(
                    key: "DefaultBrowserCard.BetterInternet.Description.v108",
                    tableName: "Default Browser",
                    value: "Making Firefox your default browser is a vote for an open, accessible internet.",
                    comment: "Description for small home tab banner shown that allows the user to switch their default browser to Firefox.")
                public static let NextLevelTitle = MZLocalizedString(
                    key: "DefaultBrowserCard.NextLevel.Title.v108",
                    tableName: "Default Browser",
                    value: "Elevate Everyday Browsing",
                    comment: "Title for small home tab banner shown that allows the user to switch their default browser to Firefox.")
                public static let NextLevelDescription = MZLocalizedString(
                    key: "DefaultBrowserCard.NextLevel.Description.v108",
                    tableName: "Default Browser",
                    value: "Choose Firefox as your default browser to make speed, safety, and privacy automatic.",
                    comment: "Description for small home tab banner shown that allows the user to switch their default browser to Firefox.")
            }
        }

        public struct JumpBackIn {
            public static let GroupSiteCount = MZLocalizedString(
                key: "ActivityStream.JumpBackIn.TabGroup.SiteCount",
                tableName: nil,
                value: "Tabs: %d",
                comment: "On the Firefox homepage in the Jump Back In section, if a Tab group item - a collection of grouped tabs from a related search - exists underneath the search term for the tab group, there will be a subtitle with a number for how many tabs are in that group. The placeholder is for a number. It will read 'Tabs: 5' or similar.")
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
                    value: "Powered by %@. Part of the %@ family.",
                    comment: "This is the title of the Pocket footer on Firefox Homepage. The first placeholder is for the Pocket app name and the second placeholder for the app name")
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
            public static let Older = MZLocalizedString(
                key: "LibraryPanel.Section.Older",
                tableName: nil,
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
            public static let ClearHistoryMenuTitle = MZLocalizedString(
                key: "LibraryPanel.History.ClearHistoryMenuTitle.v100",
                tableName: nil,
                value: "Removes history (including history synced from other devices), cookies and other browsing data.",
                comment: "Within the History Panel, users can open an action menu to clear recent history.")
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
        }

        public struct ReadingList { }

        public struct Downloads { }
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
                comment: "Title for the wallpaper onboarding page in our Onboarding screens. This describes to the user that they can choose different wallpapers. Placeholder is for app name.")
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
            public static let Title = MZLocalizedString(
                key: "Onboarding.Welcome.Title.v114",
                tableName: "Onboarding",
                value: "Welcome to an independent internet",
                comment: "String used to describes the title of what Firefox is on the welcome onboarding page for current version in our Onboarding screens.")
            public static let Description = MZLocalizedString(
                key: "Onboarding.Welcome.Description.v114",
                tableName: "Onboarding",
                value: "%@ puts people over profits and defends your privacy as you browse.",
                comment: "String used to describes the description of what Firefox is on the welcome onboarding page for current version in our Onboarding screens. Placeholder is for the app name.")
            public static let TitleTreatmentA = MZLocalizedString(
                key: "Onboarding.Welcome.Title.TreatementA.v114",
                tableName: "Onboarding",
                value: "Make %@ your go-to browser",
                comment: "String used to describes the title of what Firefox is on the welcome onboarding page for current version in our Onboarding screens. Placeholder is for the app name.")
            public static let DescriptionTreatementA = MZLocalizedString(
                key: "Onboarding.Welcome.Description.TreatementA.v114",
                tableName: "Onboarding",
                value: "%@ puts people over profits and defends your privacy as you browse.",
                comment: "String used to describes the description of what Firefox is on the welcome onboarding page for current version in our Onboarding screens. Placeholder is for the app name.")
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
                key: "Onboarding.Sync.Title.v114",
                tableName: "Onboarding",
                value: "Hop from phone to laptop and back",
                comment: "String used to describes the title of what Firefox is on the Sync onboarding page for current version in our Onboarding screens.")
            public static let Description = MZLocalizedString(
                key: "Onboarding.Sync.Description.v114",
                tableName: "Onboarding",
                value: "Grab tabs and passwords from your other devices to pick up where you left off.",
                comment: "String used to describes the description of what Firefox is on the Sync onboarding page for current version in our Onboarding screens.")
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
                key: "Onboarding.Notification.Title.v114",
                tableName: "Onboarding",
                value: "Notifications help you do more with %@",
                comment: "String used to describe the title of the notification onboarding page in our Onboarding screens. Placeholder is for the app name.")
            public static let Description = MZLocalizedString(
                key: "Onboarding.Notification.Description.v114",
                tableName: "Onboarding",
                value: "Send tabs between your devices and get tips about how to get the most out of %@.",
                comment: "String used to describe the description of the notification onboarding page in our Onboarding screens. Placeholder is for the app name.")
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
                comment: "The third label on the Default Browser Popup, which is a card with instructions telling the user how to set Firefox as their default browser. Placeholder is the app name. The *text inside asterisks* denotes part of the string to bold, please leave the text inside the '*' so that it is bolded correctly.")
            public static let ButtonTitle = MZLocalizedString(
                key: "DefaultBrowserPopup.ButtonTitle.v114",
                tableName: "Onboarding",
                value: "Go to Settings",
                comment: "The title of the button on the Default Browser Popup, which is a card with instructions telling the user how to set Firefox as their default browser.")
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
                comment: "Description string used to to sign in to sync in the Upgrade screens. This screen is shown after user upgrades Firefox version.")
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
            comment: "On the Research Survey popup, the text that explains what the screen is about. Placeholder is for the app name.")
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
        public static let EngineSectionTitle = MZLocalizedString(
            key: "Search.EngineSection.Title.v108",
            tableName: "SearchHeaderTitle",
            value: "%@ search",
            comment: "When making a new search from the awesome bar, search results appear as the user write new letters in their search. Different sections with results from the selected search engine will appear. This string will be used as a header to separate the selected engine search results from current search query.")
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

        public struct SectionTitles {
            public static let TabsTitle = MZLocalizedString(
                key: "Settings.Tabs.Title",
                tableName: nil,
                value: "Tabs",
                comment: "In the settings menu, this is the title for the Tabs customization section option")
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
                    comment: "In the settings menu, in the Firefox homepage customization section, this is the subtitle for the option that allows users to turn the Pocket Recommendations section on the Firefox homepage on or off. The placeholder is the pocket app name.")
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
                comment: "This is the description for the setting that toggles Tips and Features feature in the settings menu under the Notifications section. The placeholder will be replaced with the app name."
            )
            public static let TurnOnNotificationsTitle = MZLocalizedString(
                key: "Settings.Notifications.TurnOnNotificationsTitle.v112",
                tableName: "Settings",
                value: "Turn on Notifications",
                comment: "This is the title informing the user needs to turn on notifications in iOS Settings."
            )
            public static let TurnOnNotificationsMessage = MZLocalizedString(
                key: "Settings.Notifications.TurnOnNotificationsMessage.v112",
                tableName: "Settings",
                value: "Go to your device Settings to turn on notifications in %@",
                comment: "This is the title informing the user needs to turn on notifications in iOS Settings. The placeholder will be replaced with the app name."
            )
            public static let systemNotificationsDisabledMessage = MZLocalizedString(
                key: "Settings.Notifications.SystemNotificationsDisabledMessage.v112",
                tableName: "Settings",
                value: "You turned off all %@ notifications. Turn them on by going to device Settings > Notifications > %@",
                comment: "This is the footer title informing the user needs to turn on notifications in iOS Settings. Both placeholders will be replaced with the app name."
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
                comment: "When the user closes tabs in the tab tray, a popup will appear informing them how many tabs were closed. This is the text for the popup. The placeholder is the number of tabs")
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
                key: "TabsTray.SyncTabs.SyncTabsButton.Title.v109",
                tableName: "TabsTray",
                value: "Sync Tabs",
                comment: "Button label to sync tabs in your Firefox Account")

            public static let SyncTabsDisabled = MZLocalizedString(
                key: "TabsTray.Sync.SyncTabsDisabled.v116",
                tableName: "TabsTray",
                value: "Turn on tab syncing to view a list of tabs from your other devices.",
                comment: "Users can disable syncing tabs from other devices. In the Sync Tabs panel of the Tab Tray, we inform the user tab syncing can be switched back on to view those tabs.")
        }
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
        comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// MARK: - Activity Stream
extension String {
    public static let ASShortcutsTitle =  MZLocalizedString(
        key: "ActivityStream.Shortcuts.SectionTitle",
        tableName: nil,
        value: "Shortcuts",
        comment: "Section title label for Shortcuts")
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
        comment: "Button in Data Management that clears private data for the selected items. Parameter is the number of items to be cleared")
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
        key: "Settings.AutofillCreditCard.Title.v112",
        tableName: nil,
        value: "Autofill Credit Cards",
        comment: "Label used as an item in Settings screen. When touched, it will take user to credit card settings page to that will allows to add or modify saved credit cards to allow for autofill in a webpage.")
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
        comment: "Warning text on the certificate error page")
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
        key: "LoginsHelper.SaveLogin.Button",
        tableName: nil,
        value: "Save Login",
        comment: "Button to save the user's password")
    public static let LoginsHelperDontSaveButtonTitle = MZLocalizedString(
        key: "LoginsHelper.DontSave.Button",
        tableName: nil,
        value: "Don’t Save",
        comment: "Button to not save the user's password")
    public static let LoginsHelperUpdateButtonTitle = MZLocalizedString(
        key: "LoginsHelper.Update.Button",
        tableName: nil,
        value: "Update",
        comment: "Button to update the user's password")
    public static let LoginsHelperDontUpdateButtonTitle = MZLocalizedString(
        key: "LoginsHelper.DontUpdate.Button",
        tableName: nil,
        value: "Don’t Update",
        comment: "Button to not update the user's password")
}

// MARK: - Downloads Panel
extension String {
    public static let DownloadsPanelEmptyStateTitle = MZLocalizedString(
        key: "DownloadsPanel.EmptyState.Title",
        tableName: nil,
        value: "Downloaded files will show up here.",
        comment: "Title for the Downloads Panel empty state.")
    public static let DownloadsPanelDeleteTitle = MZLocalizedString(
        key: "DownloadsPanel.Delete.Title",
        tableName: nil,
        value: "Delete",
        comment: "Action button for deleting downloaded files in the Downloads panel.")
    public static let DownloadsPanelShareTitle = MZLocalizedString(
        key: "DownloadsPanel.Share.Title",
        tableName: nil,
        value: "Share",
        comment: "Action button for sharing downloaded files in the Downloads panel.")
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

// MARK: - Clear recent history action menu
extension String {
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
        key: "Logins",
        tableName: nil,
        value: nil,
        comment: "Toggle logins syncing setting")
    public static let FirefoxSyncCreditCardsEngine = MZLocalizedString(
        key: "FirefoxSync.CreditCardsEngine.v115",
        tableName: "FirefoxSync",
        value: "Credit Cards",
        comment: "Toggle for credit cards syncing setting")
}

// MARK: - Firefox Logins
extension String {
    // Prompts
    public static let SaveLoginUsernamePrompt = MZLocalizedString(
        key: "LoginsHelper.PromptSaveLogin.Title",
        tableName: nil,
        value: "Save login %@ for %@?",
        comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.")
    public static let SaveLoginPrompt = MZLocalizedString(
        key: "LoginsHelper.PromptSavePassword.Title",
        tableName: nil,
        value: "Save password for %@?",
        comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.")
    public static let UpdateLoginUsernamePrompt = MZLocalizedString(
        key: "LoginsHelper.PromptUpdateLogin.Title.TwoArg",
        tableName: nil,
        value: "Update login %@ for %@?",
        comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
    public static let UpdateLoginPrompt = MZLocalizedString(
        key: "LoginsHelper.PromptUpdateLogin.Title.OneArg",
        tableName: nil,
        value: "Update login for %@?",
        comment: "Prompt for updating a login. The first parameter is the hostname for which the password will be updated for.")

    // Setting
    public static let SettingToShowLoginsInAppMenu = MZLocalizedString(
        key: "Settings.ShowLoginsInAppMenu.Title",
        tableName: nil,
        value: "Show in Application Menu",
        comment: "Setting to show Logins & Passwords quick access in the application menu")

    // List view
    public static let LoginsListTitle = MZLocalizedString(
        key: "LoginsList.Title",
        tableName: nil,
        value: "SAVED LOGINS",
        comment: "Title for the list of logins")
    public static let LoginsListSearchPlaceholder = MZLocalizedString(
        key: "LoginsList.LoginsListSearchPlaceholder",
        tableName: nil,
        value: "Filter",
        comment: "Placeholder test for search box in logins list view.")

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
        key: "Logins.DevicePasscodeRequired.Message",
        tableName: nil,
        value: "To save and autofill logins and passwords, enable Face ID, Touch ID or a device passcode.",
        comment: "Message shown when you enter Logins & Passwords without having a device passcode set.")
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
        key: "FxA.FirefoxAccount",
        tableName: nil,
        value: "Firefox Account",
        comment: "Settings section title for Firefox Account")
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
        key: "Settings.FxA.Title",
        tableName: nil,
        value: "Firefox Account",
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
    public static let SettingsAdvancedAccountCustomFxAContentServerURI = "Custom Firefox Account Content Server URI"
    public static let SettingsAdvancedAccountUseCustomFxAContentServerURITitle = "Use Custom FxA Content Server"
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
    public static let BookmarksFolderTitleMobile = MZLocalizedString(
        key: "Mobile Bookmarks",
        tableName: "Storage",
        value: nil,
        comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
    public static let BookmarksFolderTitleMenu = MZLocalizedString(
        key: "Bookmarks Menu",
        tableName: "Storage",
        value: nil,
        comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
    public static let BookmarksFolderTitleToolbar = MZLocalizedString(
        key: "Bookmarks Toolbar",
        tableName: "Storage",
        value: nil,
        comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
    public static let BookmarksFolderTitleUnsorted = MZLocalizedString(
        key: "Unsorted Bookmarks",
        tableName: "Storage",
        value: nil,
        comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")
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
        key: "Settings.OfferClipboardBar.Status",
        tableName: nil,
        value: "When Opening Firefox",
        comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
}

// MARK: - Link Previews
extension String {
    public static let SettingsShowLinkPreviewsTitle = MZLocalizedString(
        key: "Settings.ShowLinkPreviews.Title",
        tableName: nil,
        value: "Show Link Previews",
        comment: "Title of setting to enable link previews when long-pressing links.")
    public static let SettingsShowLinkPreviewsStatus = MZLocalizedString(
        key: "Settings.ShowLinkPreviews.Status",
        tableName: nil,
        value: "When Long-pressing Links",
        comment: "Description displayed under the ”Show Link Previews” option")
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
        comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.")
    public static let DownloadProgressToastDescriptionText = MZLocalizedString(
        key: "Downloads.Toast.Progress.DescriptionText",
        tableName: nil,
        value: "%1$@/%2$@",
        comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).")
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = MZLocalizedString(
        key: "Downloads.Toast.MultipleFilesAndProgress.DescriptionText",
        tableName: nil,
        value: "%1$@ %2$@",
        comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.")
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
}

// MARK: - Engagement notification
extension String {
    public struct EngagementNotification {
        public static let Title = MZLocalizedString(
            key: "Engagement.Notification.Title.v112",
            tableName: "EngagementNotification",
            value: "Start your first search",
            comment: "Title of notification send to user after inactivity to encourage them to use the search feature.")
        public static let Body = MZLocalizedString(
            key: "Engagement.Notification.Body.v112",
            tableName: "EngagementNotification",
            value: "Find something nearby. Or discover something fun.",
            comment: "Body of notification send to user after inactivity to encourage them to use the search feature.")

        public static let TitleTreatmentA = MZLocalizedString(
            key: "Engagement.Notification.Treatment.A.Title.v114",
            tableName: "EngagementNotification",
            value: "Browse without a trace",
            comment: "Title of notification send to user after inactivity to encourage them to use the private browsing feature.")
        public static let BodyTreatmentA = MZLocalizedString(
            key: "Engagement.Notification.Treatment.A.Body.v114",
            tableName: "EngagementNotification",
            value: "Private browsing in %@ doesn’t save your info and blocks hidden trackers.",
            comment: "Body of notification send to user after inactivity to encourage them to use the private browsing feature. Placeholder is app name.")

        public static let TitleTreatmentB = MZLocalizedString(
            key: "Engagement.Notification.Treatment.B.Title.v114",
            tableName: "EngagementNotification",
            value: "Try private browsing",
            comment: "Title of notification send to user after inactivity to encourage them to use the private browsing feature.")
        public static let BodyTreatmentB = MZLocalizedString(
            key: "Engagement.Notification.Treatment.B.Body.v114",
            tableName: "EngagementNotification",
            value: "Browse with no saved cookies or history in %@.",
            comment: "Body of notification send to user after inactivity to encourage them to use the private browsing feature. Placeholder is the app name.")
    }
}

// MARK: - Notification
extension String {
    public struct Notification {
        public static let FallbackTitle = MZLocalizedString(
            key: "Notification.Fallback.Title.v113",
            tableName: "Notification",
            value: "%@ Tip",
            comment: "Fallback Title of notification if no notification title was configured. The notification is an advise to the user. The argument is the app name.")
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
}

// MARK: - App menu
extension String {
    /// Identifiers of all new strings should begin with `Menu.`
    public struct AppMenu {
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
        public static let AppMenuSettingsTitleString = MZLocalizedString(
            key: "Menu.OpenSettingsAction.Title",
            tableName: "Menu",
            value: "Settings",
            comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
        public static let AppMenuCloseAllTabsTitleString = MZLocalizedString(
            key: "Menu.CloseAllTabsAction.Title",
            tableName: "Menu",
            value: "Close All Tabs",
            comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
        public static let AppMenuOpenHomePageTitleString = MZLocalizedString(
            key: "SettingsMenu.OpenHomePageAction.Title",
            tableName: "Menu",
            value: "Homepage",
            comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
        public static let AppMenuBookmarksTitleString = MZLocalizedString(
            key: "Menu.OpenBookmarksAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Bookmarks",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel. Please keep as short as possible, <15 chars of space available.")
        public static let AppMenuReadingListTitleString = MZLocalizedString(
            key: "Menu.OpenReadingListAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Reading List",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel. Please keep as short as possible, <15 chars of space available.")
        public static let AppMenuHistoryTitleString = MZLocalizedString(
            key: "Menu.OpenHistoryAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "History",
            comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel. Please keep as short as possible, <15 chars of space available.")
        public static let AppMenuDownloadsTitleString = MZLocalizedString(
            key: "Menu.OpenDownloadsAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Downloads",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel. Please keep as short as possible, <15 chars of space available.")
        public static let AppMenuSyncedTabsTitleString = MZLocalizedString(
            key: "Menu.OpenSyncedTabsAction.AccessibilityLabel.v2",
            tableName: "Menu",
            value: "Synced Tabs",
            comment: "Accessibility label for the button, displayed in the menu, used to open the Synced Tabs home panel. Please keep as short as possible, <15 chars of space available.")
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
            comment: "Label for the button, displayed in the menu, takes you to to History screen when pressed.")
        public static let AppMenuDownloads = MZLocalizedString(
            key: "Menu.Downloads.Label",
            tableName: nil,
            value: "Downloads",
            comment: "Label for the button, displayed in the menu, takes you to to Downloads screen when pressed.")
        public static let AppMenuPasswords = MZLocalizedString(
            key: "Menu.Passwords.Label",
            tableName: nil,
            value: "Passwords",
            comment: "Label for the button, displayed in the menu, takes you to to passwords screen when pressed.")
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
            comment: "Label for the button, displayed in the menu, takes you to to bookmarks screen when pressed.")
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

        // Reading list
        public static let ReadingList = MZLocalizedString(
            key: "Menu.ReadingList.Label",
            tableName: nil,
            value: "Reading List",
            comment: "Label for the button, displayed in the menu, takes you to to Reading List screen when pressed.")
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
            comment: "Label for the zoom page button in the menu, used to show the Zoom Page bar. The placeholder shows the current zoom level in percent.")
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
            comment: "Accessibility label for current zoom level in Zoom Page Bar. The placeholder represents the zoom level")

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

// MARK: - Snackbar shown when tapping app store link
extension String {
    public static let ExternalLinkAppStoreConfirmationTitle = MZLocalizedString(
        key: "ExternalLink.AppStore.ConfirmationTitle",
        tableName: nil,
        value: "Open this link in the App Store?",
        comment: "Question shown to user when tapping a link that opens the App Store app")
    public static let ExternalLinkGenericConfirmation = MZLocalizedString(
        key: "ExternalLink.AppStore.GenericConfirmationTitle",
        tableName: nil,
        value: "Open this link in external app?",
        comment: "Question shown to user when tapping an SMS or MailTo link that opens the external app for those.")
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
        comment: "String to let users know the site verifier, where the placeholder represents the SSL certificate signer.")

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

// MARK: - Nimbus settings
extension String {
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
        key: "SendTo.NotSignedIn.Title",
        tableName: nil,
        value: "You are not signed in to your Firefox Account.",
        comment: "See http://mzl.la/1ISlXnU")
    public static let SendToNotSignedInMessage = MZLocalizedString(
        key: "SendTo.NotSignedIn.Message",
        tableName: nil,
        value: "Please open Firefox, go to Settings and sign in to continue.",
        comment: "See http://mzl.la/1ISlXnU")
    public static let SendToNoDevicesFound = MZLocalizedString(
        key: "SendTo.NoDevicesFound.Message",
        tableName: nil,
        value: "You don’t have any other devices connected to this Firefox Account available to sync.",
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
    public static let ShareSendToDevice = String.AppMenu.TouchActions.SendToDeviceTitle

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
            key: "", // Shopping.Sheet.Title.v118
            tableName: "Shopping",
            value: "Review quality check",
            comment: "Label for the header of the Shopping Experience (Fakespot) sheet")
        public static let ReliabilityCardTitle = MZLocalizedString(
            key: "", // Shopping.ReviewQuality.ReliabilityCardTitle.v118
            tableName: "Shopping",
            value: "How reliable are these reviews?",
            comment: "Title of the reliability card displayed in the shopping review quality bottom sheet.")
        public static let ReliabilityRatingAB = MZLocalizedString(
            key: "", // Shopping.ReviewQuality.ReliabilityRating.AB.Description.v118
            tableName: "Shopping",
            value: "Reliable reviews",
            comment: "Description of the reliability ratings for rating 'A' and 'B' displayed in the shopping review quality bottom sheet.")
        public static let ReliabilityRatingC = MZLocalizedString(
            key: "", // Shopping.ReviewQuality.ReliabilityRating.C.Description.v118
            tableName: "Shopping",
            value: "Only some reliable reviews",
            comment: "Description of the reliability rating 'C' displayed in the shopping review quality bottom sheet.")
        public static let ReliabilityRatingDF = MZLocalizedString(
            key: "", // Shopping.ReviewQuality.ReliabilityRating.DF.Description.v118
            tableName: "Shopping",
            value: "Unreliable reviews",
            comment: "Description of the reliability ratings for rating 'D' and 'F' displayed in the shopping review quality bottom sheet.")
        public static let ErrorCardTitle = MZLocalizedString(
            key: "", // Shopping.ErrorCard.Title.v118
            tableName: "Shopping",
            value: "Something Went Wrong",
            comment: "Title of the error displayed in the shopping review quality bottom sheet.")
        public static let ErrorCardDescription = MZLocalizedString(
            key: "", // Shopping.ErrorCard.Description.v118
            tableName: "Shopping",
            value: "Couldn’t load information. Please try again.",
            comment: "Description of the error displayed in the shopping review quality bottom sheet.")
        public static let ErrorCardButtonText = MZLocalizedString(
            key: "", // Shopping.ErrorCard.Button.Text.v118
            tableName: "Shopping",
            value: "Try Again",
            comment: "Button text of the error displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardFooterText = MZLocalizedString(
            key: "", // Shopping.HighlightsCard.Footer.Text.v118
            tableName: "Shopping",
            value: "Summarized using information provided by Fakespot.com.",
            comment: "Footer text of the review highlights displayed in the shopping review quality bottom sheet.")
        public static let HighlightsCardFooterButtonText = MZLocalizedString(
            key: "", // Shopping.HighlightsCard.Footer.Button.Text.v118
            tableName: "Shopping",
            value: "View full analysis",
            comment: "Footer button text of the review highlights displayed in the shopping review quality bottom sheet.")
    }
}

// MARK: - Translation bar
extension String {
    public static let TranslateSnackBarPrompt = MZLocalizedString(
        key: "TranslationToastHandler.PromptTranslate.Title",
        tableName: nil,
        value: "This page appears to be in %1$@. Translate to %2$@ with %3$@?",
        comment: "Prompt for translation. The first parameter is the language the page is in. The second parameter is the name of our local language. The third is the name of the service.")
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

// MARK: - CrashOptInAlert
extension String {
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
        key: "Are you sure?",
        tableName: "LoginManager",
        value: nil,
        comment: "Prompt title when deleting logins")
    public static let DeleteLoginAlertSyncedMessage = MZLocalizedString(
        key: "Logins will be removed from all connected devices.",
        tableName: "LoginManager",
        value: nil,
        comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices")
    public static let DeleteLoginAlertLocalMessage = MZLocalizedString(
        key: "Logins will be permanently removed.",
        tableName: "LoginManager",
        value: nil,
        comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them")
    public static let DeleteLoginAlertCancel = MZLocalizedString(
        key: "Cancel",
        tableName: "LoginManager",
        value: nil,
        comment: "Prompt option for cancelling out of deletion")
    public static let DeleteLoginAlertDelete = MZLocalizedString(
        key: "Delete",
        tableName: "LoginManager",
        value: nil,
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
        value: nil,
        comment: "Authentication prompt message with a realm. First parameter is the hostname. Second is the realm string")
    public static let AuthenticatorPromptEmptyRealmMessage = MZLocalizedString(
        key: "A username and password are being requested by %@.",
        tableName: nil,
        value: nil,
        comment: "Authentication prompt message with no realm. Parameter is the hostname of the site")
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
        comment: "Label for search engine buttons. The argument corresponds to the name of the search engine.")
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
    public static let TabPeekPreviewAccessibilityLabel = MZLocalizedString(
        key: "Preview of %@",
        tableName: "3DTouchActions",
        value: nil,
        comment: "Accessibility label, associated to the 3D Touch action on the current tab in the tab tray, used to display a larger preview of the tab.")
}

// MARK: - Tab Toolbar
extension String {
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
        key: "Private Mode",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Accessibility label for toggling on/off private mode")
    public static let TabTrayToggleAccessibilityHint = MZLocalizedString(
        key: "Turns private mode on or off",
        tableName: "PrivateBrowsing",
        value: nil,
        comment: "Accessiblity hint for toggling on/off private mode")
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
        value: nil,
        comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
    public static let TabTrayVisiblePartialRangeAccessibilityHint = MZLocalizedString(
        key: "Tabs %@ to %@ of %@",
        tableName: nil,
        value: nil,
        comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
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
        comment: "In the tab tray, when tab groups appear and there exist tabs that don't belong to any group, those tabs are listed under this header as \"Others\"")
}

// MARK: - URL Bar
extension String {
    public static let URLBarLocationAccessibilityLabel = MZLocalizedString(
        key: "Address and Search",
        tableName: nil,
        value: nil,
        comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
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
        comment: "Label describing when the current login was created with the timestamp as the parameter.")
    public static let LoginDetailModifiedAt = MZLocalizedString(
        key: "Modified %@",
        tableName: "LoginManager",
        value: nil,
        comment: "Label describing when the current login was last modified with the timestamp as the parameter.")
    public static let LoginDetailDelete = MZLocalizedString(
        key: "Delete",
        tableName: "LoginManager",
        value: nil,
        comment: "Label for the button used to delete the current login.")
}

// MARK: - No Logins View
extension String {
    public static let NoLoginsFound = MZLocalizedString(
        key: "No logins found",
        tableName: "LoginManager",
        value: nil,
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
    public static let AppSettingsYourRights = MZLocalizedString(
        key: "Your Rights",
        tableName: nil,
        value: nil,
        comment: "Your Rights settings section title")
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
    public static let AppSettingsPrivacyPolicy = MZLocalizedString(
        key: "Privacy Policy",
        tableName: nil,
        value: nil,
        comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/")
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
        comment: "A settings item that allows a user to use Apple's \"Spotlight Search\" in Data Management's Website Data option to search for and select an item to delete.")
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

// MARK: - SearchSettings
extension String {
    public static let SearchSettingsTitle = MZLocalizedString(
        key: "SearchSettings.Title.Search.v106",
        tableName: nil,
        value: "Search",
        comment: "Navigation title for search settings.")
    public static let SearchSettingsDefaultSearchEngineAccessibilityLabel = MZLocalizedString(
        key: "SearchSettings.Accessibility.DefaultSearchEngine.v106",
        tableName: nil,
        value: "Default Search Engine",
        comment: "Accessibility label for default search engine setting.")
    public static let SearchSettingsShowSearchSuggestions = MZLocalizedString(
        key: "Show Search Suggestions",
        tableName: nil,
        value: nil,
        comment: "Label for show search suggestions setting.")
    public static let SearchSettingsDefaultSearchEngineTitle = MZLocalizedString(
        key: "SearchSettings.Title.DefaultSearchEngine.v106",
        tableName: nil,
        value: "Default Search Engine",
        comment: "Title for default search engine settings section.")
    public static let SearchSettingsQuickSearchEnginesTitle = MZLocalizedString(
        key: "Quick-Search Engines",
        tableName: nil,
        value: nil,
        comment: "Title for quick-search engines settings section.")
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
        value: nil,
        comment: "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs. The first argument is the app name. The second argument is the device name.")
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
        comment: "Relative date for date older than a minute.")
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
        key: "LoginsList.Search.Placeholder",
        tableName: nil,
        value: "Search logins",
        comment: "Placeholder text for search field")
    public static let LoginsListSelectPasswordTitle = MZLocalizedString(
        key: "LoginsList.SelectPassword.Title",
        tableName: nil,
        value: "Select a password to fill",
        comment: "Label displaying select a password to fill instruction")
    public static let LoginsListNoMatchingResultTitle = MZLocalizedString(
        key: "LoginsList.NoMatchingResult.Title",
        tableName: nil,
        value: "No matching logins",
        comment: "Label displayed when a user searches and no matches can be found against the search query")
    public static let LoginsListNoMatchingResultSubtitle = MZLocalizedString(
        key: "LoginsList.NoMatchingResult.Subtitle",
        tableName: nil,
        value: "There are no results matching your search.",
        comment: "Label that appears after the search if there are no logins matching the search")
    public static let LoginsListNoLoginsFoundTitle = MZLocalizedString(
        key: "LoginsList.NoLoginsFound.Title",
        tableName: nil,
        value: "No logins found",
        comment: "Label shown when there are no logins saved")
    public static let LoginsListNoLoginsFoundDescription = MZLocalizedString(
        key: "LoginsList.NoLoginsFound.Description",
        tableName: nil,
        value: "Saved logins will show up here. If you saved your logins to Firefox on a different device, sign in to your Firefox Account.",
        comment: "Label shown when there are no logins to list")
    public static let LoginsPasscodeRequirementWarning = MZLocalizedString(
        key: "Logins.PasscodeRequirement.Warning",
        tableName: nil,
        value: "To use the AutoFill feature for Firefox, you must have a device passcode enabled.",
        comment: "Warning message shown when you try to enable or use native AutoFill without a device passcode setup")
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
// swiftlint:enable line_length
