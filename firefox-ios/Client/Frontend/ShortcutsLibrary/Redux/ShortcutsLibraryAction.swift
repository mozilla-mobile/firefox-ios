// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct ShortcutsLibraryAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let topSites: [TopSiteConfiguration]?
    let tab: Tab?

    init(
        topSites: [TopSiteConfiguration]? = nil,
        tab: Tab? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.topSites = topSites
        self.tab = tab
    }
}

enum ShortcutsLibraryActionType: ActionType {
    case initialize
    case switchTabToastButtonTapped
    case tapOnShortcutCell
    case viewDidAppear
    case viewDidDisappear
}

enum ShortcutsLibraryMiddlewareActionType: ActionType {
    case impressionTelemetryRecorded
}
