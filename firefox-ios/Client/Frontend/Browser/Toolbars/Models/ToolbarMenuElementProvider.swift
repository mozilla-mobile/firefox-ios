// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit

@MainActor
struct ToolbarMenuElementProvider {
    static func menuElements(
        for action: ToolbarActionConfiguration,
        windowUUID: WindowUUID
    ) -> [ToolbarMenuElement] {
        switch action.actionType {
        case .googleLens:
            return GoogleLensMenuElementProvider.menuElements(windowUUID: windowUUID)
        default:
            return []
        }
    }
}
