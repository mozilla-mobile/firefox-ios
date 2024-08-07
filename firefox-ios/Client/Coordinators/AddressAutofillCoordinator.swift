// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import ComponentLibrary
import WebKit

/// Coordinator responsible for managing the address autofill functionality, presenting it within a bottom sheet.
class AddressAutofillCoordinator: BaseCoordinator {
    // MARK: - Properties

    typealias BottomSheetCardParentCoordinator = BrowserNavigationHandler & ParentCoordinatorDelegate
    private let profile: Profile
    private let themeManager: ThemeManager
    private let tabManager: TabManager
    private weak var parentCoordinator: BottomSheetCardParentCoordinator?
    private var windowUUID: WindowUUID { return tabManager.windowUUID }

    // MARK: - Initializers

    /// Initializes an AddressAutofillCoordinator with the provided parameters.
    /// - Parameters:
    ///   - profile: The user's profile associated with the autofill.
    ///   - router: The router used for navigation.
    ///   - parentCoordinator: The parent coordinator.
    ///   - themeManager: The theme manager.
    ///   - tabManager: The tab manager.
    init(
        profile: Profile,
        router: Router,
        parentCoordinator: BottomSheetCardParentCoordinator?,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        tabManager: TabManager
    ) {
        self.profile = profile
        self.themeManager = themeManager
        self.tabManager = tabManager
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - Methods

    /// Shows the address autofill functionality within a bottom sheet.
    /// - Parameter frame: The WKFrameInfo object representing the web view frame.
    func showAddressAutofill(frame: WKFrameInfo?) {
        let bottomSheetViewModel = BottomSheetViewModel(
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.Autofill.addressCloseButton
        )

        let viewModel = AddressListViewModel(
            windowUUID: tabManager.windowUUID,
            addressProvider: profile.autofill
        )

        viewModel.addressSelectionCallback = { [weak self] selectedAddress in
            // Perform actions with the selected address, such as injecting it into the form
            guard let self = self else { return }
            guard let currentTab = self.tabManager.selectedTab else {
                self.parentCoordinator?.didFinish(from: self)
                return
            }

            FormAutofillHelper.injectAddressInfo(logger: self.logger,
                                                 address: selectedAddress,
                                                 tab: currentTab,
                                                 frame: frame) { error in
                guard let error = error else {
                    return
                }
                self.logger.log("Address bottom sheet injection \(error)",
                                level: .debug,
                                category: .autofill)
                self.parentCoordinator?.didFinish(from: self)
            }
        }
        viewModel.manageAddressesInfoAction = { [weak self] in
            guard let self else { return }
            parentCoordinator?.show(settings: .addresses, onDismiss: {})
            parentCoordinator?.didFinish(from: self)
        }
        let bottomSheetView = AddressAutoFillBottomSheetView(windowUUID: tabManager.windowUUID,
                                                             addressListViewModel: viewModel)
        let hostingController = SelfSizingHostingController(rootView: bottomSheetView)
        hostingController.controllerWillDismiss = {
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .close,
                object: .addressAutofillPromptDismissed
            )
        }
        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: hostingController,
            windowUUID: tabManager.windowUUID)
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .addressAutofillPromptExpanded
        )
        router.present(bottomSheetVC)
    }
}
