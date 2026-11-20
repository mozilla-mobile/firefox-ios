// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

@MainActor
enum TabGroupsSessionStore {
    private static var controllers = [WindowUUID: TabGroupsController]()

    static func controller(for windowUUID: WindowUUID, tabManager: TabManager? = nil) -> TabGroupsController {
        if tabManager == nil, let controller = controllers[windowUUID], controller.tabManager != nil {
            return controller
        }
        let windows: WindowManager = AppContainer.shared.resolve()
        let manager = tabManager ?? windows.windows[windowUUID]?.tabManager
        let groups: TabGroupManager = manager?.tabGroupManager ?? AppContainer.shared.resolve()
        if let controller = controllers[windowUUID], controller.groupManager === groups {
            if let manager { controller.tabManager = manager }
            return controller
        }
        let controller = TabGroupsController(groupManager: groups, windowUUID: windowUUID, tabManager: manager)
        controllers[windowUUID] = controller
        return controller
    }

    static func removeController(for windowUUID: WindowUUID) {
        controllers[windowUUID] = nil
    }

    static func visibleNormalTabs(_ normalTabs: [Tab], for windowUUID: WindowUUID) -> [Tab] {
        guard TabGroupsFeatureFlag.isEnabled else { return normalTabs }
        let visibleIDs = Set(controller(for: windowUUID).visibleTabIDs(normalTabIDs: normalTabs.map(\.tabUUID)))
        return normalTabs.filter { visibleIDs.contains($0.tabUUID) }
    }
}
