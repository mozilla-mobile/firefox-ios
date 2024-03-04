// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

class GeneralBrowserContext: ActionContext {
    let selectedTabURL: URL?
    let isPrivateBrowsing: Bool
    init(selectedTabURL: URL?,
         isPrivateBrowsing: Bool,
         windowUUID: WindowUUID) {
        self.selectedTabURL = selectedTabURL
        self.isPrivateBrowsing = isPrivateBrowsing
        super.init(windowUUID: windowUUID)
    }
}

enum GeneralBrowserAction: Action {
    case showToast(ToastTypeContext)
    case showOverlay(KeyboardContext)
    case updateSelectedTab(GeneralBrowserContext)

    var windowUUID: UUID {
        switch self {
        case .showToast(let context as ActionContext):
            return context.windowUUID
        case .showOverlay(let context as ActionContext):
            return context.windowUUID
        case .updateSelectedTab(let context as ActionContext):
            return context.windowUUID
        }
    }
}
