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
    /// Whether the address bar is minimized
    let isAddressBarMinimized: Bool

    // MARK: - Lens initialization
    init(appState: AppState, uuid: WindowUUID) {
        // On launch, theres a chance one or both of BrowserViewControllerState and HomepageState may not yet have been
        // created and added to the global Redux store.
        let browserViewControllerState = appState.componentState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: uuid
        ) ?? BrowserViewControllerState(windowUUID: uuid)

        let homepageStateSearchBarState = appState.componentState(
            HomepageState.self,
            for: .homepage,
            window: uuid
        )?.searchBarState ?? SearchBarState(windowUUID: uuid)

        let isAddressBarMinimized = appState.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: uuid
        )?.isAddressBarMinimized ?? false

        self.init(browserViewControllerState: browserViewControllerState,
                  homepageSearchBarState: homepageStateSearchBarState,
                  isAddressBarMinimized: isAddressBarMinimized)
    }

    init(browserViewControllerState: BrowserViewControllerState,
         homepageSearchBarState: SearchBarState,
         isAddressBarMinimized: Bool = false) {
        self.browserViewControllerState = browserViewControllerState
        self.homepageSearchBarState = homepageSearchBarState
        self.isAddressBarMinimized = isAddressBarMinimized
    }
}
