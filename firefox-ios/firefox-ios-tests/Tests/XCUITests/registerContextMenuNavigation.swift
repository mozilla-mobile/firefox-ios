// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerContextMenuNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(HistoryPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
    }

    map.addScreenState(BookmarksPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
    }
    map.addScreenState(TopSitesPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = dismissContextMenuAction(app: app)
    }
}
