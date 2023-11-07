// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class LibraryViewModel {
    let profile: Profile
    let tabManager: TabManager
    let panelDescriptors: [LibraryPanelDescriptor]
    var selectedPanel: LibraryPanelType?

    var segmentedControlItems: [UIImage] {
        [UIImage(named: StandardImageIdentifiers.Large.bookmarkTrayFill) ?? UIImage(),
         UIImage(named: StandardImageIdentifiers.Large.history) ?? UIImage(),
         UIImage(named: StandardImageIdentifiers.Large.download) ?? UIImage(),
         UIImage(named: ImageIdentifiers.libraryReadingList) ?? UIImage()]
    }

    init(withProfile profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
        self.panelDescriptors = LibraryPanelHelper(profile: profile, tabManager: tabManager).enabledPanels
    }

    func resetHistoryPanelPagination() {
        // Reset history panel pagination to get latest history visit
        if let historyPanel = panelDescriptors.first(where: { $0.panelType == .history }),
           let vcPanel = historyPanel.viewController as? HistoryPanel {
            vcPanel.viewModel.shouldResetHistory = true
        }
    }
}
