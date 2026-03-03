// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import WebKit
import SummarizeKit

import struct MozillaAppServices.CreditCard
import enum MozillaAppServices.VisitType

protocol BrowserNavigationHandler: AnyObject, QRCodeNavigationHandler {
    /// Asks to show a settings page, can be a general settings page or a child page
    /// - Parameter settings: The settings route we're trying to get to
    /// - Parameter onDismiss: An optional closure that is executed when the settings page is dismissed.
    /// This closure takes no parameters and returns no value.
    @MainActor
    func show(settings: Route.SettingsSection, onDismiss: (() -> Void)?)

    /// Asks to show a enhancedTrackingProtection page, can be a general
    /// enhancedTrackingProtection page or a child page
    @MainActor
    func showEnhancedTrackingProtection(sourceView: UIView)

    /// Shows the specified section of the home panel.
    ///
    /// - Parameter homepanelSection: The section to be displayed.
    @MainActor
    func show(homepanelSection: Route.HomepanelSection)

    /// Shows the share sheet.
    ///
    /// - Parameter shareType: The content to be shared.
    /// - Parameter shareMessage: An optional plain text message to be shared.
    /// - Parameter sourceView: The reference view to show the popoverViewController.
    /// - Parameter sourceRect: An optional rect to use for ipad popover presentation.
    /// - Parameter toastContainer: The view in which is displayed the toast results from actions in the share extension.
    /// - Parameter popoverArrowDirection: The arrow direction for the view controller presented as popover.
    @MainActor
    func showShareSheet(shareType: ShareType,
                        shareMessage: ShareMessage?,
                        sourceView: UIView,
                        sourceRect: CGRect?,
                        toastContainer: UIView,
                        popoverArrowDirection: UIPopoverArrowDirection)

    /// Shows a CreditCardAutofill view to select credit cards in order to autofill cards forms.
    @MainActor
    func showCreditCardAutofill(creditCard: CreditCard?,
                                decryptedCard: UnencryptedCreditCardFields?,
                                viewType state: CreditCardBottomSheetState,
                                frame: WKFrameInfo?,
                                alertContainer: UIView)

    /// Displays an autofill interface for saved logins, allowing the user to select from stored login credentials
    /// to autofill login forms on the specified web page.
    @MainActor
    func showSavedLoginAutofill(tabURL: URL, currentRequestId: String, field: FocusFieldType)

    /// Shows an AddressAutofill view for selecting addresses in order to autofill forms.
    @MainActor
    func showAddressAutofill(frame: WKFrameInfo?)

    /// Shows authentication view controller to authorize access to sensitive data.
    @MainActor
    func showRequiredPassCode()

    /// Shows the Tab Tray View Controller.
    @MainActor
    func showTabTray(selectedPanel: TabTrayPanelType)

    /// Shows the Back Forward List View Controller.
    @MainActor
    func showBackForwardList()

    @MainActor
    func showMicrosurvey(model: MicrosurveyModel)

    @MainActor
    func showPasswordGenerator(tab: Tab, frame: WKFrameInfo)

    @MainActor
    func showPasswordGenerator(tab: Tab, frameContext: PasswordGeneratorFrameContext)

    /// Shows the app menu
    @MainActor
    func showMainMenu()

    /// Shows the toolbar's search engine selection bottom sheet (iPhone) or popup (iPad)
    @MainActor
    func showSearchEngineSelection(forSourceView sourceView: UIView)

    /// Navigates from home page to a new link
    @MainActor
    func navigateFromHomePanel(to url: URL, visitType: VisitType, isGoogleTopSite: Bool)

    /// Navigates to our custom context menu (Photon Action Sheet)
    @MainActor
    func showContextMenu(for configuration: ContextMenuConfiguration)

    /// Navigates to the edit bookmark view
    @MainActor
    func showEditBookmark(parentFolder: FxBookmarkNode, bookmark: FxBookmarkNode)

    @MainActor
    func openInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool)

    /// Shows the Document loading view on screen
    @MainActor
    func showDocumentLoading()

    /// Removes the Document loading view from screen
    @MainActor
    func removeDocumentLoading()

    @MainActor
    func showSummarizePanel(_ trigger: SummarizerTrigger, config: SummarizerConfig?)

    @MainActor
    func showShortcutsLibrary()

    @MainActor
    func showStoriesFeed()

    @MainActor
    func showStoriesWebView(url: URL?)

    @MainActor
    func showPrivacyNoticeLink(url: URL)

    @MainActor
    func showTermsOfUse(context: TriggerContext)

    @MainActor
    func showCertificatesFromErrorPage(errorPageURL: URL, originalURL: URL, title: String)

    @MainActor
    func openLearnMoreFromNativeErrorPage(url: URL)

    @MainActor
    func popToBVC()
}

extension BrowserNavigationHandler {
    @MainActor
    func show(settings: Route.SettingsSection) {
        show(settings: settings, onDismiss: nil)
    }
}
