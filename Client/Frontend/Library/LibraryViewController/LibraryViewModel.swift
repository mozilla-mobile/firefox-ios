// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

class LibraryViewModel {

    let profile: Profile
    let tabManager: TabManager
    let panelDescriptors: [LibraryPanelDescriptor]

    fileprivate var panelState = LibraryPanelViewState()
    var currentPanelState: LibraryPanelMainState {
        get { return panelState.currentState }
        set { panelState.currentState = newValue }
    }

    init(withProfile profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
        self.panelDescriptors = LibraryPanels(profile: profile, tabManager: tabManager).enabledPanels
    }
}
