// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage

/// Defines actions sent to Redux for Sync tab in tab tray
class RemoteTabsPanelAction: Action {
    let clientAndTabs: [ClientAndTabs]?
    let reason: RemoteTabsPanelEmptyStateReason?
    let url: URL?

    init(clientAndTabs: [ClientAndTabs]? = nil,
         reason: RemoteTabsPanelEmptyStateReason? = nil,
         url: URL? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.clientAndTabs = clientAndTabs
        self.reason = reason
        self.url = url
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum RemoteTabsPanelActionType: ActionType {
    case panelDidAppear
    case refreshTabs
    case refreshDidBegin
    case refreshDidFail
    case refreshDidSucceed
    case openSelectedURL
}
