// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

class LibraryViewModel {

    let profile: Profile
    let tabManager: TabManager
    let panelDescriptors: [LibraryPanelDescriptor]
    var selectedPanel: LibraryPanelType?
    var currentPanelState: LibraryPanelMainState {
        guard let panel = getCurrentPanel() else {
            return .bookmarks(state: .mainView)
        }

        return panel.state
    }

    var segmentedControlItems: [UIImage] {
        [UIImage(named: ImageIdentifiers.libraryBookmars) ?? UIImage(),
         UIImage(named: ImageIdentifiers.libraryHistory) ?? UIImage(),
         UIImage(named: ImageIdentifiers.libraryDownloads) ?? UIImage(),
         UIImage(named: ImageIdentifiers.libraryReadingList) ?? UIImage()]
    }

    init(withProfile profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
        self.panelDescriptors = LibraryPanels(profile: profile, tabManager: tabManager).enabledPanels
    }

    func getCurrentPanel() -> LibraryPanel? {
        guard let index = selectedPanel?.rawValue else { return nil }

        return panelDescriptors[index].viewController as? LibraryPanel
    }
}
