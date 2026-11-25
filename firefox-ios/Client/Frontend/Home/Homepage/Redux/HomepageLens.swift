// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// Computes the state that drives the BrowserViewController.
struct HomepageLens: StateLens {
    /// Main screen state
    let homepageState: HomepageState

    // MARK: - Lens initialization
    init(appState: AppState, uuid: WindowUUID) {
        let homepageState = appState.componentState(
            HomepageState.self,
            for: .homepage,
            window: uuid
        ) ?? HomepageState(windowUUID: uuid)

        self.init(homepageState: homepageState)
    }

    init(homepageState: HomepageState) {
        self.homepageState = homepageState
    }
}
