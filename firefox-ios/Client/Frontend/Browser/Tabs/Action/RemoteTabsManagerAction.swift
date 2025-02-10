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

final class RemoteTabsAction: Action {
    var mostRecentSyncedTab: RemoteTabConfiguration?

    init(
        mostRecentSyncedTab: RemoteTabConfiguration? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.mostRecentSyncedTab = mostRecentSyncedTab
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}
enum RemoteTabsActionType: ActionType {
    case fetchRecentTab
}

enum RemoteTabsMiddlewareActionType: ActionType {
    case fetchedMostRecentSyncedTab
}
