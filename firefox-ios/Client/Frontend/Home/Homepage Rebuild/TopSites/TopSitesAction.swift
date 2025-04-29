// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Foundation
import Redux

struct TopSitesTelemetryConfig {
    let isZeroSearch: Bool
    let position: Int
    let topSiteConfiguration: TopSiteConfiguration
}

final class TopSitesAction: Action {
    let topSites: [TopSiteConfiguration]?
    let numberOfRows: Int?
    let isEnabled: Bool?
    let telemetryConfig: TopSitesTelemetryConfig?

    init(
        topSites: [TopSiteConfiguration]? = nil,
        numberOfRows: Int? = nil,
        isEnabled: Bool? = nil,
        telemetryConfig: TopSitesTelemetryConfig? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.isEnabled = isEnabled
        self.topSites = topSites
        self.numberOfRows = numberOfRows
        self.telemetryConfig = telemetryConfig
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum TopSitesActionType: ActionType {
    case updatedNumberOfRows
    case toggleShowSectionSetting
    case toggleShowSponsoredSettings
    case tapOnHomepageTopSitesCell
    case topSitesSeen
}

enum TopSitesMiddlewareActionType: ActionType {
    case retrievedUpdatedSites
}
