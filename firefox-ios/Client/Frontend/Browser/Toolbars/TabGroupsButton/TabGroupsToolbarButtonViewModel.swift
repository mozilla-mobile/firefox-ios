// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

struct TabGroupsToolbarButtonViewModel: Equatable {
    let isActiveGroup: Bool
    let groupEmoji: String?
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
        configured.actionLabel = group.emoji ?? "🗂️"
        configured.iconName = nil
        configured.numberOfTabs = nil
        configured.badgeImageName = nil
        configured.maskImageName = nil
        configured.isSelected = true
        configured.cacheId = "tabGroupsToolbar.button"
        configured.a11yLabel = "\(group.title) Tab Group"
        return configured
    }
}
