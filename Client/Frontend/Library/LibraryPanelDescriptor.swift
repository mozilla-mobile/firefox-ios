// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Data for identifying and constructing a LibraryPanel.
class LibraryPanelDescriptor {
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let panelType: LibraryPanelType

    init(accessibilityLabel: String,
         accessibilityIdentifier: String,
         panelType: LibraryPanelType) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.panelType = panelType
    }
}
