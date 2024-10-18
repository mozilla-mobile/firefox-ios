// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import WebKit

@testable import Client

import struct MozillaAppServices.CreditCard

class MockBrowserCoordinator: BrowserNavigationHandler, ParentCoordinatorDelegate {
    var showSettingsCalled = 0
    var showFakespotCalled = 0
    var showCreditCardAutofillCalled = 0
    var showLoginAutofillCalled = 0
    var showRequiredPassCodeCalled = 0
    var showLibraryCalled = 0
    var showHomepanelSectionCalled = 0
    var showEnhancedTrackingProtectionCalled = 0
    var showShareExtensionCalled = 0
    var showTabTrayCalled = 0
    var showQrCodeCalled = 0
    var didFinishCalled = 0
    var showFakespotFlowAsModalCalled = 0
    var showFakespotFlowAsSidebarCalled = 0
    var showBackForwardListCalled = 0
    var showSearchEngineSelectionCalled = 0
    var dismissFakespotModalCalled = 0
    var dismissFakespotSidebarCalled = 0
    var updateFakespotSidebarCalled = 0
    var showMicrosurveyCalled = 0
    var showMainMenuCalled = 0
    var showPasswordGeneratorCalled = 0

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

    func showShareExtension(
        url: URL,
        sourceView: UIView,
        toastContainer: UIView,
        popoverArrowDirection: UIPopoverArrowDirection
    ) {
        showShareExtensionCalled += 1
    }

    func show(homepanelSection: Route.HomepanelSection) {
        showHomepanelSectionCalled += 1
    }

    func showFakespotFlow(productURL: URL) {
        showFakespotCalled += 1
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

    func showFakespotFlowAsModal(productURL: URL) {
        showFakespotFlowAsModalCalled += 1
    }

    func showMainMenu() {
        showMainMenuCalled += 1
    }

    func showFakespotFlowAsSidebar(productURL: URL,
                                   sidebarContainer: Client.SidebarEnabledViewProtocol,
                                   parentViewController: UIViewController) {
        showFakespotFlowAsSidebarCalled += 1
    }

    func showSearchEngineSelection(forSourceView sourceView: UIView) {
        showSearchEngineSelectionCalled += 1
    }

    func dismissFakespotModal(animated: Bool) {
        dismissFakespotModalCalled += 1
    }

    func dismissFakespotSidebar(sidebarContainer: Client.SidebarEnabledViewProtocol,
                                parentViewController: UIViewController) {
        dismissFakespotSidebarCalled += 1
    }

    func updateFakespotSidebar(productURL: URL,
                               sidebarContainer: SidebarEnabledViewProtocol,
                               parentViewController: UIViewController) {
        updateFakespotSidebarCalled += 1
    }

    func showMicrosurvey(model: MicrosurveyModel) {
        showMicrosurveyCalled += 1
    }

    func showPasswordGenerator(tab: Tab) {
        showPasswordGeneratorCalled += 1
    }
}
