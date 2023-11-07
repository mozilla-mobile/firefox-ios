// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum TabTrayLayoutType: Equatable {
    case regular // iPad
    case compact // iPhone
}

struct TabTrayState {
    var isPrivateMode: Bool
    var tabViewState: TabViewState
    var remoteTabsState: RemoteTabsPanelState?
    var selectedPanel: TabTrayPanelType?

    var layout: TabTrayLayoutType = .compact
    var normalTabsCount: String
    var navigationTitle: String

    var isSyncTabsPanel: Bool {
        return selectedPanel == .syncedTabs
    }

    // For test and mock purposes will be deleted once Redux is integrated
    static func getMockState(isPrivateMode: Bool) -> TabTrayState {
        let tabViewState = TabViewState.getMockState(isPrivateMode: isPrivateMode)
        return TabTrayState(isPrivateMode: isPrivateMode,
                            tabViewState: tabViewState,
                            remoteTabsState: nil,
                            normalTabsCount: "2",
                            navigationTitle: "")
    }
}
