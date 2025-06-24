// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import WebKit

@testable import Client

import struct MozillaAppServices.CreditCard
import enum MozillaAppServices.VisitType

class MockBrowserCoordinator: BrowserNavigationHandler,
                              BrowserDelegate,
                              ParentCoordinatorDelegate {
    var showSettingsCalled = 0
    var showCreditCardAutofillCalled = 0
    var showLoginAutofillCalled = 0
    var showRequiredPassCodeCalled = 0
    var showLibraryCalled = 0
    var showHomepanelSectionCalled = 0
    var showEnhancedTrackingProtectionCalled = 0
    var showShareSheetCalled = 0
    var showTabTrayCalled = 0
    var showQrCodeCalled = 0
    var didFinishCalled = 0
    var showBackForwardListCalled = 0
    var showSearchEngineSelectionCalled = 0
    var showMicrosurveyCalled = 0
    var showMainMenuCalled = 0
    var showPasswordGeneratorCalled = 0
    var navigateFromHomePanelCalled = 0
    var showContextMenuCalled = 0
    var showEditBookmarkCalled = 0
    var openInNewTabCalled = 0
    var showDocumentLoadingCalled = 0
    var removeDocumentLoadingCalled = 0
    var showHomepageCalled = 0
    var showLegacyHomepageCalled = 0
    var browserHasLoadedCalled = 0
    var homepageScreenshotToolCalled = 0
    var showNativeErrorPageCalled = 0
    var showPrivateHomepageCalled = 0
    var showWebViewCalled = 0
    var setHomepageVisibilityCalled = 0

    func show(settings: Client.Route.SettingsSection, onDismiss: (() -> Void)?) {
        showSettingsCalled += 1
    }

    func showRequiredPassCode() {
        showRequiredPassCodeCalled += 1
    }

    func showCreditCardAutofill(
        creditCard: CreditCard?,
        decryptedCard: UnencryptedCreditCardFields?,
        viewType state: CreditCardBottomSheetState,
        frame: WKFrameInfo?,
        alertContainer: UIView
    ) {
        showCreditCardAutofillCalled += 1
    }

    func showSavedLoginAutofill(tabURL: URL, currentRequestId: String, field: FocusFieldType) {
        showLoginAutofillCalled += 1
    }

    func showAddressAutofill(
        frame: WKFrameInfo?
    ) {
        showCreditCardAutofillCalled += 1
    }

    func showShareSheet(shareType: ShareType,
                        shareMessage: ShareMessage?,
                        sourceView: UIView,
                        sourceRect: CGRect?,
                        toastContainer: UIView,
                        popoverArrowDirection: UIPopoverArrowDirection) {
        showShareSheetCalled += 1
    }

    func show(homepanelSection: Route.HomepanelSection) {
        showHomepanelSectionCalled += 1
    }

    func showEnhancedTrackingProtection(sourceView: UIView) {
        showEnhancedTrackingProtectionCalled += 1
    }

    func showTabTray(selectedPanel: TabTrayPanelType) {
        showTabTrayCalled += 1
    }

    func showQRCode() {
        showQrCodeCalled += 1
    }

    func showBackForwardList() {
        showBackForwardListCalled += 1
    }

    func didFinish(from childCoordinator: Coordinator) {
        didFinishCalled += 1
    }

    func showMainMenu() {
        showMainMenuCalled += 1
    }

    func showSearchEngineSelection(forSourceView sourceView: UIView) {
        showSearchEngineSelectionCalled += 1
    }

    func navigateFromHomePanel(to url: URL, visitType: VisitType, isGoogleTopSite: Bool) {
        navigateFromHomePanelCalled += 1
    }

    func showContextMenu(for configuration: ContextMenuConfiguration) {
        showContextMenuCalled += 1
    }

    func showMicrosurvey(model: MicrosurveyModel) {
        showMicrosurveyCalled += 1
    }

    func showPasswordGenerator(tab: Tab, frame: WKFrameInfo) {
        showPasswordGeneratorCalled += 1
    }

    func showEditBookmark(parentFolder: FxBookmarkNode, bookmark: FxBookmarkNode) {
        showEditBookmarkCalled += 1
    }

    func openInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool) {
        openInNewTabCalled += 1
    }

    func showDocumentLoading() {
        showDocumentLoadingCalled += 1
    }

    func removeDocumentLoading() {
        removeDocumentLoadingCalled += 1
    }

    // MARK: - BrowserDelegate

    func show(webView: WKWebView) {
        showWebViewCalled += 1
    }

    func showLegacyHomepage(
        inline: Bool,
        toastContainer: UIView,
        homepanelDelegate: any Client.HomePanelDelegate,
        libraryPanelDelegate: any Client.LibraryPanelDelegate,
        statusBarScrollDelegate: any Client.StatusBarScrollDelegate,
        overlayManager: any Client.OverlayModeManager
    ) {
        showLegacyHomepageCalled += 1
    }

    func showHomepage(
        overlayManager: any Client.OverlayModeManager,
        isZeroSearch: Bool,
        statusBarScrollDelegate: any Client.StatusBarScrollDelegate,
        toastContainer: UIView
    ) {
        showHomepageCalled += 1
    }

    func homepageScreenshotTool() -> (any Client.Screenshotable)? {
        homepageScreenshotToolCalled += 1
        return nil
    }

    func setHomepageVisibility(isVisible: Bool) {
        setHomepageVisibilityCalled += 1
    }

    func showPrivateHomepage(overlayManager: any Client.OverlayModeManager) {
        showPrivateHomepageCalled += 1
    }

    func browserHasLoaded() {
        browserHasLoadedCalled += 1
    }

    func showNativeErrorPage(overlayManager: any Client.OverlayModeManager) {
        showNativeErrorPageCalled += 1
    }
}
