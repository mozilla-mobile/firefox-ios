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

struct TopSitesAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let topSites: [TopSiteConfiguration]?
    let numberOfRows: Int?
    let isEnabled: Bool?
    let shouldShowAddShortcutTile: Bool?
    let telemetryConfig: TopSitesTelemetryConfig?
    let shortcutPinnedSource: TopSitesShortcutPinnedSource?
    let shortcutUnpinnedSource: TopSitesShortcutUnpinnedSource?

    init(
        topSites: [TopSiteConfiguration]? = nil,
        numberOfRows: Int? = nil,
        isEnabled: Bool? = nil,
        shouldShowAddShortcutTile: Bool? = nil,
        telemetryConfig: TopSitesTelemetryConfig? = nil,
        shortcutPinnedSource: TopSitesShortcutPinnedSource? = nil,
        shortcutUnpinnedSource: TopSitesShortcutUnpinnedSource? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.isEnabled = isEnabled
        self.shouldShowAddShortcutTile = shouldShowAddShortcutTile
        self.topSites = topSites
        self.numberOfRows = numberOfRows
        self.telemetryConfig = telemetryConfig
        self.shortcutPinnedSource = shortcutPinnedSource
        self.shortcutUnpinnedSource = shortcutUnpinnedSource
    }
}

enum TopSitesActionType: ActionType {
    case updatedNumberOfRows
    case toggleShowSectionSetting
    case toggleShowSponsoredSettings
    case tapOnHomepageTopSitesCell
    case topSitesSeen
    case shortcutPinned
    case shortcutUnpinned
}

enum TopSitesMiddlewareActionType: ActionType {
    case retrievedUpdatedSites
}
