// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - APNConsentListItem

/// Structure representing an item in the APN consent list.
struct APNConsentListItem {
    let image: UIImage? = .templateImageNamed("stroke")?.tinted(withColor: .legacyTheme.ecosia.secondaryIcon)
    let title: String
}
