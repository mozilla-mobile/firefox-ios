// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

class TabPeekModelContext: ActionContext {
    let tabPeekModel: TabPeekModel
    init(tabPeekModel: TabPeekModel, windowUUID: WindowUUID) {
        self.tabPeekModel = tabPeekModel
        super.init(windowUUID: windowUUID)
    }
}

enum TabPeekAction: Action {
    // MARK: - View Actions
    case didLoadTabPeek(TabUUIDContext)
    case addToBookmarks(TabUUIDContext)
    case sendToDevice(TabUUIDContext)
    case copyURL(TabUUIDContext)
    case closeTab(TabUUIDContext)

    // MARK: - Middleware Actions
    case loadTabPeek(TabPeekModelContext)

    var windowUUID: UUID {
        switch self {
        case .didLoadTabPeek(let context as ActionContext),
                .addToBookmarks(let context as ActionContext),
                .sendToDevice(let context as ActionContext),
                .copyURL(let context as ActionContext),
                .closeTab(let context as ActionContext),
                .loadTabPeek(let context as ActionContext):
            return context.windowUUID
        }
    }
}
