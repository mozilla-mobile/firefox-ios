// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

/// Extras are optionals since we pass in `item.telemetryItemType` as `itemType`
/// and not all items will have telemetry extras (i.e. `header`)
/// Only sponsored sites telemetry are using `topSitesTelemetryConfig`
struct HomepageTelemetryExtras {
    let itemType: HomepageTelemetry.ItemType?
    let topSitesTelemetryConfig: TopSitesTelemetryConfig?
}

final class HomepageAction: Action {
    let showiPadSetup: Bool?
    let numberOfTopSitesPerRow: Int?
    let telemetryExtras: HomepageTelemetryExtras?
    let isZeroSearch: Bool?

    init(
        numberOfTopSitesPerRow: Int? = nil,
        showiPadSetup: Bool? = nil,
        telemetryExtras: HomepageTelemetryExtras? = nil,
        isZeroSearch: Bool? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.numberOfTopSitesPerRow = numberOfTopSitesPerRow
        self.showiPadSetup = showiPadSetup
        self.telemetryExtras = telemetryExtras
        self.isZeroSearch = isZeroSearch
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum HomepageActionType: ActionType {
    case initialize
    case traitCollectionDidChange
    case viewWillTransition
    case viewWillAppear
    case didSelectItem
    case embeddedHomepage
    case sectionSeen
}

enum HomepageMiddlewareActionType: ActionType {
    case topSitesUpdated
    case jumpBackInLocalTabsUpdated
    case jumpBackInRemoteTabsUpdated
    case bookmarksUpdated
    case enteredForeground
}
