// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

enum GeneralBrowserAction: Action {
    case showToast(ToastTypeContext)

    var windowUUID: UUID {
        switch self {
        case .showToast(let context as ActionContext):
            return context.windowUUID
        }
    }
}
