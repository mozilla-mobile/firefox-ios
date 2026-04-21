// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct HomepageTabState: Equatable {
    var scrollOffsetY: CGFloat?
    var selectedNewsfeedCategoryID: String?
}

protocol HomepageTabStateStoring: AnyObject {
    func state(for tabUUID: TabUUID) -> HomepageTabState
    func updateState(for tabUUID: TabUUID, _ update: (inout HomepageTabState) -> Void)
    func removeState(for tabUUID: TabUUID)
}

/// Stores homepage UI state keyed by `TabUUID` so it can be restored while
/// the shared homepage controller is reused across tabs.
final class HomepageTabStateStore: HomepageTabStateStoring {
    private var states: [TabUUID: HomepageTabState] = [:]

    func state(for tabUUID: TabUUID) -> HomepageTabState {
        return states[tabUUID] ?? HomepageTabState()
    }

    func updateState(for tabUUID: TabUUID, _ update: (inout HomepageTabState) -> Void) {
        var state = states[tabUUID] ?? HomepageTabState()
        update(&state)
        states[tabUUID] = state
    }

    func removeState(for tabUUID: TabUUID) {
        states.removeValue(forKey: tabUUID)
    }
}
