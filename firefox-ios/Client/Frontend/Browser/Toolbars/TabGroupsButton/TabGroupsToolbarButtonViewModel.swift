// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct TabGroupsToolbarButtonViewModel: Equatable {
    let isActiveGroup: Bool
    let groupIcon: TabGroupIcon?
    let isEnabled: Bool
    let accessibilityLabel: String
}

@MainActor
extension TabGroupsToolbarButtonViewModel {
    static func configure(_ action: ToolbarActionConfiguration,
                          for windowUUID: WindowUUID,
                          normalTabIDs: [TabUUID]? = nil) -> ToolbarActionConfiguration {
        guard TabGroupsFeatureFlag.isEnabled,
              action.actionType == .tabs,
              action.badgeImageName == nil else { return action }
        let controller = TabGroupsSessionStore.controller(for: windowUUID)
        let state = controller.state
        guard let selectedGroupID = state.selectedGroupID,
              let group = state.groups.first(where: { $0.id == selectedGroupID }) else {
            guard !state.groups.isEmpty, action.numberOfTabs != nil else { return action }
            let liveTabIDs = normalTabIDs ?? {
                let windowManager: WindowManager = AppContainer.shared.resolve()
                return windowManager.windows[windowUUID]?.tabManager?.normalTabs.map(\.tabUUID)
            }()
            guard let liveTabIDs else { return action }
            var configured = action
            configured.numberOfTabs = controller.visibleTabIDs(normalTabIDs: liveTabIDs).count
            return configured
        }
        var configured = action
        configured.iconName = nil
        let liveTabIDs = normalTabIDs ?? controller.tabManager?.normalTabs.map(\.tabUUID)
        if let liveTabIDs {
            configured.numberOfTabs = controller.visibleTabIDs(normalTabIDs: liveTabIDs).count
        }
        let color = TabGroupColorPalette.adaptiveColor(for: group.color)
        configured.bottomLeadingBadgeImage = group.icon.badgeImage(color: color)
        configured.bottomLeadingBadgeShadowColor = color
        configured.a11yLabel = "\(group.title), \(String.TabGroups.Accessibility.MenuButton)"
        return configured
    }
}
