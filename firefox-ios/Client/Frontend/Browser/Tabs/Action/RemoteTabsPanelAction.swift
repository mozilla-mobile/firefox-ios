// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage

import struct MozillaAppServices.Device

/// Defines actions sent to Redux for Sync tab in tab tray
class RemoteTabsPanelAction: Action {
    let clientAndTabs: [ClientAndTabs]?
    let reason: RemoteTabsPanelEmptyStateReason?
    let url: URL?
    let targetDeviceId: String?
    let devices: [Device]?

    init(clientAndTabs: [ClientAndTabs]? = nil,
         reason: RemoteTabsPanelEmptyStateReason? = nil,
         url: URL? = nil,
         targetDeviceId: String? = nil,
         devices: [Device]? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.clientAndTabs = clientAndTabs
        self.reason = reason
        self.url = url
        self.targetDeviceId = targetDeviceId
        self.devices = devices
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum RemoteTabsPanelActionType: ActionType {
    case panelDidAppear
    case refreshTabs
    case refreshTabsWithCache
    case refreshDidBegin
    case refreshDidFail
    case refreshDidSucceed
    case closeTabCompatible
    case openSelectedURL
    case closeSelectedRemoteURL
    case undoCloseSelectedRemoteURL
    case flushTabCommands
    case remoteDevicesChanged
}
