// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class LibraryViewModel {
    let profile: Profile
    let panelDescriptors: [LibraryPanelDescriptor]
    var selectedPanel: LibraryPanelType?

    var segmentedControlItems: [UIImage] {
        /* Ecosia: Update images and positions
        [UIImage(named: StandardImageIdentifiers.Large.bookmarkTrayFill) ?? UIImage(),
         UIImage(named: StandardImageIdentifiers.Large.history) ?? UIImage(),
         UIImage(named: StandardImageIdentifiers.Large.download) ?? UIImage(),
         UIImage(named: StandardImageIdentifiers.Large.readingList) ?? UIImage()]
         */
        [
            UIImage(named: "libraryFavorites"),
            UIImage(named: "libraryHistory"),
            UIImage(named: "libraryReading"),
            UIImage(named: "libraryDownloads")
        ].compactMap({ $0 })
    }

    init(withProfile profile: Profile) {
        self.profile = profile
        self.panelDescriptors = LibraryPanelHelper(profile: profile).enabledPanels
    }
}
