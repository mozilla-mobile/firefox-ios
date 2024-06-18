// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import ToolbarKit
import Redux
import Common

struct AddressToolbarModel {
    let navigationActions: [ToolbarActionState]?
    let pageActions: [ToolbarActionState]?
    let browserActions: [ToolbarActionState]?

    let displayTopBorder: Bool?
    let displayBottomBorder: Bool?

    let url: URL?

    init(navigationActions: [ToolbarActionState]? = nil,
         pageActions: [ToolbarActionState]? = nil,
         browserActions: [ToolbarActionState]? = nil,
         displayTopBorder: Bool? = nil,
         displayBottomBorder: Bool? = nil,
         url: URL? = nil) {
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.displayTopBorder = displayTopBorder
        self.displayBottomBorder = displayBottomBorder
        self.url = url
    }
}
