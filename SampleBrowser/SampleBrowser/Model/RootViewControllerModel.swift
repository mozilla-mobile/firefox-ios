// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import ToolbarKit
import UIKit

class RootViewControllerModel {
    // By default the state is set to reload. We save the state to avoid setting the toolbar
    // button multiple times when a page load is in progress
    private var isReloading = false
    private var canGoBack = false
    private var canGoForward = false

    var navigationToolbarDelegate: NavigationToolbarDelegate?
    var addressToolbarDelegate: AddressToolbarContainerDelegate?

    // MARK: - Navigation toolbar
    var navigationToolbarContainerModel: NavigationToolbarContainerModel {
        let backButton = ToolbarElement(
            iconName: "Back",
            isEnabled: canGoBack,
            a11yLabel: "Navigate Back",
            a11yHint: nil,
            a11yId: "backButton",
            hasLongPressAction: false,
            onSelected: { _ in
                self.navigationToolbarDelegate?.backButtonTapped()
            })
        let forwardButton = ToolbarElement(
            iconName: "Forward",
            isEnabled: canGoForward,
            a11yLabel: "Navigate Forward",
            a11yHint: nil,
            a11yId: "forwardButton",
            hasLongPressAction: false,
            onSelected: { _ in
                self.navigationToolbarDelegate?.forwardButtonTapped()
            })
        let reloadButton = ToolbarElement(
            iconName: isReloading ? StandardImageIdentifiers.Large.cross : StandardImageIdentifiers.Large.sync,
            isEnabled: isReloading,
            a11yLabel: isReloading ? "Stop loading website" : "Reload website",
            a11yHint: nil,
            a11yId: isReloading ? "stopButton" : "reloadButton",
            hasLongPressAction: false,
            onSelected: { _ in
                if self.isReloading {
                    self.navigationToolbarDelegate?.stopButtonTapped()
                } else {
                    self.navigationToolbarDelegate?.reloadButtonTapped()
                }
            })
        let menuButton = ToolbarElement(
            iconName: StandardImageIdentifiers.Large.appMenu,
            isEnabled: true,
            a11yLabel: "Open Menu",
            a11yHint: nil,
            a11yId: "appMenuButton",
            hasLongPressAction: false,
            onSelected: { _ in
                self.navigationToolbarDelegate?.menuButtonTapped()
            })
        let actions = [backButton, forwardButton, reloadButton, menuButton]

        return NavigationToolbarContainerModel(toolbarPosition: .top, actions: actions)
    }

    func updateReloadStopButton(loading: Bool) {
        guard loading != isReloading else { return }
        self.isReloading = loading
    }

    func updateBackForwardButtons(canGoBack: Bool, canGoForward: Bool) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }

    // MARK: - Address toolbar
    func addressToolbarContainerModel(url: URL?) -> AddressToolbarContainerModel {
        let pageActions = [ToolbarElement(
            iconName: StandardImageIdentifiers.Large.qrCode,
            isEnabled: true,
            a11yLabel: "Read QR Code",
            a11yHint: nil,
            a11yId: "qrCodeButton",
            hasLongPressAction: false,
            onSelected: nil)]

        let browserActions = [ToolbarElement(
            iconName: StandardImageIdentifiers.Large.appMenu,
            isEnabled: true,
            a11yLabel: "Open Menu",
            a11yHint: nil,
            a11yId: "appMenuButton",
            hasLongPressAction: false,
            onSelected: { _ in
                self.addressToolbarDelegate?.didTapMenu()
            })]

        let locationViewState = LocationViewState(
            searchEngineImageViewA11yId: "searchEngine",
            searchEngineImageViewA11yLabel: "Search engine icon",
            lockIconButtonA11yId: "lockButton",
            lockIconButtonA11yLabel: "Tracking Protection",
            urlTextFieldPlaceholder: "Search or enter address",
            urlTextFieldA11yId: "urlTextField",
            searchEngineImage: UIImage(named: "bingSearchEngine"),
            lockIconImageName: StandardImageIdentifiers.Large.lock,
            url: url,
            droppableUrl: nil,
            searchTerm: nil,
            isEditing: false,
            isScrollingDuringEdit: false,
            shouldSelectSearchTerm: false)

        // FXIOS-8947: Use scroll position
        return AddressToolbarContainerModel(
            toolbarPosition: .top,
            scrollY: 0,
            isPrivate: false,
            locationViewState: locationViewState,
            navigationActions: [],
            pageActions: pageActions,
            browserActions: browserActions)
    }
}
