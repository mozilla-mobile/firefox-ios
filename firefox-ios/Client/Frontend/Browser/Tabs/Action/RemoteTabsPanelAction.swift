// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage

class RemoteTabsRefreshDidFailContext: ActionContext {
    let reason: RemoteTabsPanelEmptyStateReason
    init(reason: RemoteTabsPanelEmptyStateReason, windowUUID: WindowUUID) {
        self.reason = reason
        super.init(windowUUID: windowUUID)
    }
}

class RemoteTabsRefreshSuccessContext: ActionContext {
    let clientAndTabs: [ClientAndTabs]
    init(clientAndTabs: [ClientAndTabs], windowUUID: WindowUUID) {
        self.clientAndTabs = clientAndTabs
        super.init(windowUUID: windowUUID)
    }
}

class URLActionContext: ActionContext {
    let url: URL
    init(url: URL, windowUUID: WindowUUID) {
        self.url = url
        super.init(windowUUID: windowUUID)
    }
}

/// Defines actions sent to Redux for Sync tab in tab tray
enum RemoteTabsPanelAction: Action {
    case panelDidAppear(ActionContext)
    case refreshTabs(ActionContext)
    case refreshDidBegin(ActionContext)
    case refreshDidFail(RemoteTabsRefreshDidFailContext)
    case refreshDidSucceed(RemoteTabsRefreshSuccessContext)
    case openSelectedURL(URLActionContext)

    var windowUUID: UUID {
        switch self {
        case .panelDidAppear(let context),
                .refreshTabs(let context),
                .refreshDidBegin(let context),
                .refreshDidFail(let context as ActionContext),
                .refreshDidSucceed(let context as ActionContext),
                .openSelectedURL(let context as ActionContext):
            return context.windowUUID
        }
    }
}

struct RemoteTabsPanelCachedResults {
    let clientAndTabs: [ClientAndTabs]
    let isUpdating: Bool // Whether we are also fetching updates to cached tabs
}
