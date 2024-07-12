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

    let borderPosition: AddressToolbarBorderPosition?
    let url: URL?
    let lockIconImageName: String?
    let isEditing: Bool?

    init(navigationActions: [ToolbarActionState]? = nil,
         pageActions: [ToolbarActionState]? = nil,
         browserActions: [ToolbarActionState]? = nil,
         borderPosition: AddressToolbarBorderPosition? = nil,
         url: URL? = nil,
         lockIconImageName: String? = nil,
         isEditing: Bool? = nil) {
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.borderPosition = borderPosition
        self.url = url
        self.lockIconImageName = lockIconImageName
        self.isEditing = isEditing
    }
}
