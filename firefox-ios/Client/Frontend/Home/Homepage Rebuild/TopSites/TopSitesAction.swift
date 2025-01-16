// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Foundation
import Redux

final class TopSitesAction: Action {
    var topSites: [TopSiteState]?
    var numberOfRows: Int?
    var isEnabled: Bool?

    init(
        topSites: [TopSiteState]? = nil,
        numberOfRows: Int? = nil,
        isEnabled: Bool? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.isEnabled = isEnabled
        self.topSites = topSites
        self.numberOfRows = numberOfRows
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum TopSitesActionType: ActionType {
    case fetchTopSites
    case updatedNumberOfRows
    case toggleShowSectionSetting
    case toggleShowSponsoredSettings
}

enum TopSitesMiddlewareActionType: ActionType {
    case retrievedUpdatedSites
}
