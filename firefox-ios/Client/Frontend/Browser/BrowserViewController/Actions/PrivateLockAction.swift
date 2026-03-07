// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

enum PrivateLockActionType: ActionType {
    case requestAuth(String)
    case setPrivateContext
    case setTrayDisplayContext
    case setTrayDisplayContextAndPanelType
    case didEnterBackground
    case willEnterForeground
    case lockPrivateTabsSettingsDidChange
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
    case setPrivateLockState
    case changedTabTrayPanelType
    case setTrayDisplayContext
}

struct PrivateLockMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let privateLockState: BrowserViewControllerState.PrivateLockDomainState?
    let trayPanelType: TabTrayPanelType?
    let trayDisplayContext: BrowserViewControllerState.TrayDisplayContext?
    let privateLockEnabled: Bool?
    
    init(windowUUID: WindowUUID,
         actionType: ActionType,
         privatePanelLockState: BrowserViewControllerState.PrivateLockDomainState? = nil,
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
