// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage

struct RemoteTabConfiguration {
    let client: RemoteClient
    let tab: RemoteTab
}

struct RemoteTabsAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let mostRecentSyncedTab: RemoteTabConfiguration?

    init(
        mostRecentSyncedTab: RemoteTabConfiguration? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.mostRecentSyncedTab = mostRecentSyncedTab
    }
}

enum RemoteTabsActionType: ActionType {
    case fetchRecentTab
}

enum RemoteTabsMiddlewareActionType: ActionType {
    case fetchedMostRecentSyncedTab
}
