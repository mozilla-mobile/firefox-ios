// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import ToolbarKit

class RootViewControllerModel {
    // By default the state is set to reload. We save the state to avoid setting the toolbar
    // button multiple times when a page load is in progress
    private var isReloading = false
    private var canGoBack: Bool = false
    private var canGoForward: Bool = false

    var navigationToolbarDelegate: ToolbarDelegate?

    // MARK: - Navigation toolbar
    var navigationToolbarContainerModel: NavigationToolbarContainerModel {
        let backButton = ToolbarElement(
            iconName: "Back",
            isEnabled: canGoBack,
            a11yLabel: "Navigate Back",
            a11yId: "backButton",
            onSelected: {
                self.navigationToolbarDelegate?.backButtonClicked()
            })
        let forwardButton = ToolbarElement(
            iconName: "Forward",
            isEnabled: canGoForward,
            a11yLabel: "Navigate Forward",
            a11yId: "forwardButton",
            onSelected: {
                self.navigationToolbarDelegate?.forwardButtonClicked()
            })
        let reloadButton = ToolbarElement(
            iconName: isReloading ? "Stop" : "Reload",
            isEnabled: isReloading,
            a11yLabel: isReloading ? "Stop loading website" : "Reload website",
            a11yId: isReloading ? "stopButton" : "reloadButton",
            onSelected: {
                if self.isReloading {
                    self.navigationToolbarDelegate?.stopButtonClicked()
                } else {
                    self.navigationToolbarDelegate?.reloadButtonClicked()
                }
            })
        let actions = [backButton, forwardButton, reloadButton]

        return NavigationToolbarContainerModel(actions: actions)
    }

    func updateReloadStopButton(loading: Bool) {
        guard loading != isReloading else { return }
        self.isReloading = loading
    }

    func updateBackForwardButtons(canGoBack: Bool, canGoForward: Bool) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }

}
