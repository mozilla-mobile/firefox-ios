// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Foundation
import Redux

final class TopSitesAction: Action {
    var topSites: [TopSiteState]?

    init(
        topSites: [TopSiteState]? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.topSites = topSites
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum TopSitesActionType: ActionType {
    case fetchTopSites
}

enum TopSitesMiddlewareActionType: ActionType {
    case retrievedUpdatedSites
}
