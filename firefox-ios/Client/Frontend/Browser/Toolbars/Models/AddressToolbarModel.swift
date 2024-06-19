// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import ToolbarKit

struct AddressToolbarModel {
    let navigationActions: [ToolbarActionState]
    let pageActions: [ToolbarActionState]
    let browserActions: [ToolbarActionState]

    let displayTopBorder: Bool
    let displayBottomBorder: Bool

    let url: URL?
}
