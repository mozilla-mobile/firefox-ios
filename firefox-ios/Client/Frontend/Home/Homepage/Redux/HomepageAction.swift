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

struct HomepageAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let isSearchBarEnabled: Bool?
    let shouldShowPrivacyNotice: Bool?
    let shouldShowSpacer: Bool?
    let showiPadSetup: Bool?
    let numberOfTopSitesPerRow: Int?
    let telemetryExtras: HomepageTelemetryExtras?
    let isZeroSearch: Bool?
    let availableContentHeight: CGFloat?

    init(
        isSearchBarEnabled: Bool? = nil,
        shouldShowPrivacyNotice: Bool? = nil,
        shouldShowSpacer: Bool? = nil,
        numberOfTopSitesPerRow: Int? = nil,
        showiPadSetup: Bool? = nil,
        telemetryExtras: HomepageTelemetryExtras? = nil,
        isZeroSearch: Bool? = nil,
        availableContentHeight: CGFloat? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.isSearchBarEnabled = isSearchBarEnabled
        self.shouldShowPrivacyNotice = shouldShowPrivacyNotice
        self.shouldShowSpacer = shouldShowSpacer
        self.numberOfTopSitesPerRow = numberOfTopSitesPerRow
        self.showiPadSetup = showiPadSetup
        self.telemetryExtras = telemetryExtras
        self.isZeroSearch = isZeroSearch
        self.availableContentHeight = availableContentHeight
    }
}

enum HomepageActionType: ActionType {
    case initialize
    case traitCollectionDidChange
    case viewWillTransition
    case viewWillAppear
    case viewDidAppear
    case viewDidLayoutSubviews
    case didSelectItem
    case embeddedHomepage
    case sectionSeen
    case availableContentHeightDidChange
    case privacyNoticeCloseButtonTapped
}

enum HomepageMiddlewareActionType: ActionType {
    case topSitesUpdated
    case jumpBackInLocalTabsUpdated
    case jumpBackInRemoteTabsUpdated
    case bookmarksUpdated
    case enteredForeground
    case configuredPrivacyNotice
    case configuredSearchBar
    case configuredSpacer
}
