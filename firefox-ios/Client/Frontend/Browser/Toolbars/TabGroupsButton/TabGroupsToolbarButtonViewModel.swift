// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

@MainActor
enum TabGroupsToolbarButtonViewModel {
    static func configure(_ action: ToolbarActionConfiguration,
                          for windowUUID: WindowUUID,
                          normalTabIDs: [TabUUID]? = nil) -> ToolbarActionConfiguration {
        guard TabGroupsFeatureFlag.isEnabled,
              action.actionType == .tabs,
              action.badgeImageName == nil else { return action }
        let controller = TabGroupsSessionStore.controller(for: windowUUID)
        let state = controller.state
        guard !state.groups.isEmpty else { return action }
        let group = state.groups.first { $0.id == state.selectedGroupID }
        let liveTabIDs = normalTabIDs ?? controller.tabManager?.normalTabs.map(\.tabUUID)
        var configured = action
        if let liveTabIDs, group != nil || action.numberOfTabs != nil {
            let count = controller.visibleTabIDs(normalTabIDs: liveTabIDs).count
            configured.numberOfTabs = count
            configured.largeContentTitle = count > 99
                ? .Toolbars.TabsButtonOverflowLargeContentTitle
                : String(format: .Toolbars.TabsButtonLargeContentTitle, NSNumber(value: count))
        }
        guard let group else { return configured }
        configured.iconName = nil
        let color = group.color.uiColor
        configured.bottomLeadingBadgeImage = group.icon.badgeImage(color: color)
        configured.bottomLeadingBadgeShadowColor = color
        return configured
    }
}
