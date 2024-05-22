// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ToolbarKit

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
            a11yId: "backButton",
            onSelected: {
                self.navigationToolbarDelegate?.backButtonTapped()
            })
        let forwardButton = ToolbarElement(
            iconName: "Forward",
            isEnabled: canGoForward,
            a11yLabel: "Navigate Forward",
            a11yId: "forwardButton",
            onSelected: {
                self.navigationToolbarDelegate?.forwardButtonTapped()
            })
        let reloadButton = ToolbarElement(
            iconName: isReloading ? StandardImageIdentifiers.Large.cross : StandardImageIdentifiers.Large.sync,
            isEnabled: isReloading,
            a11yLabel: isReloading ? "Stop loading website" : "Reload website",
            a11yId: isReloading ? "stopButton" : "reloadButton",
            onSelected: {
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
            a11yId: "appMenuButton",
            onSelected: {
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
    func addressToolbarContainerModel(url: String?) -> AddressToolbarContainerModel {
        let pageActions = [ToolbarElement(
            iconName: StandardImageIdentifiers.Large.qrCode,
            isEnabled: true,
            a11yLabel: "Read QR Code",
            a11yId: "qrCodeButton",
            onSelected: nil)]

        let browserActions = [ToolbarElement(
            iconName: StandardImageIdentifiers.Large.appMenu,
            isEnabled: true,
            a11yLabel: "Open Menu",
            a11yId: "appMenuButton",
            onSelected: {
                self.addressToolbarDelegate?.didTapMenu()
            })]

        let locationViewState = LocationViewState(
            clearButtonA11yId: "clearButton",
            clearButtonA11yLabel: "Clean",
            searchEngineImageViewA11yId: "searchEngine",
            searchEngineImageViewA11yLabel: "Search engine icon",
            urlTextFieldPlaceholder: "Search or enter address",
            urlTextFieldA11yId: "urlTextField",
            urlTextFieldA11yLabel: "Address Bar",
            searchEngineImageName: "bingSearchEngine",
            lockIconImageName: StandardImageIdentifiers.Medium.lock,
            url: url
        )

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
