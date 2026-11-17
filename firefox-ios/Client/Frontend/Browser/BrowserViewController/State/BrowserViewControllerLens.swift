// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// Computes the state that drives the BrowserViewController.
struct BrowserViewControllerLens: StateLens {
    /// Main screen state
    let browserViewControllerState: BrowserViewControllerState
    /// State regarding the homepage's embedded search bar
    let homepageSearchBarState: SearchBarState

    // MARK: - Lens initialization
    init(appState: AppState, uuid: WindowUUID) {
        guard let browserViewControllerState = appState.componentState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        guard let homepageState = appState.componentState(
            HomepageState.self,
            for: .homepage,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(browserViewControllerState: browserViewControllerState,
                  homepageSearchBarState: homepageState.searchBarState)
    }

    private init(windowUUID: WindowUUID) {
        self.init(
            browserViewControllerState: BrowserViewControllerState(windowUUID: windowUUID),
            homepageSearchBarState: SearchBarState(windowUUID: windowUUID)
        )
    }

    private init(browserViewControllerState: BrowserViewControllerState,
                 homepageSearchBarState: SearchBarState) {
        self.browserViewControllerState = browserViewControllerState
        self.homepageSearchBarState = homepageSearchBarState
    }
}
