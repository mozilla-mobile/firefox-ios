// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

enum PrivateLockActionType: ActionType {
    case privateAuthRequested(String)
    case didChangeTrayDisplayContext
    case didChangeTrayPresentation
    case didEnterBackground
    case willEnterForeground
    case didChangePrivateTabsLockSetting
}

struct PrivateLockAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let trayDisplayContext: BrowserViewControllerState.TrayDisplayContext?
    let trayPanelType: TabTrayPanelType?

    init(windowUUID: WindowUUID,
         actionType: ActionType,
         trayDisplayContext: BrowserViewControllerState.TrayDisplayContext? = nil,
         trayPanelType: TabTrayPanelType? = nil) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.trayDisplayContext = trayDisplayContext
        self.trayPanelType = trayPanelType
    }
}

enum PrivateLockMiddlewareActionType: ActionType {
    case didChangePrivateLockState
    case didChangeTabTrayPanelType
    case didChangeTrayDisplayContext
}

struct PrivateLockMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let privateLockState: PrivateLockDomainState?
    let trayPanelType: TabTrayPanelType?
    let trayDisplayContext: BrowserViewControllerState.TrayDisplayContext?
    let privateLockEnabled: Bool?

    init(windowUUID: WindowUUID,
         actionType: ActionType,
         privatePanelLockState: PrivateLockDomainState? = nil,
         trayPanelType: TabTrayPanelType? = nil,
         trayDisplayContext: BrowserViewControllerState.TrayDisplayContext? = nil,
         privateLockEnabled: Bool? = nil) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.privateLockState = privatePanelLockState
        self.trayPanelType = trayPanelType
        self.trayDisplayContext = trayDisplayContext
        self.privateLockEnabled = privateLockEnabled
    }
}
