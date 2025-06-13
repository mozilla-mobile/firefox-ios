// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct HomepageTelemetry {
    enum ItemType: String {
        case topSite = "top_site"
        case jumpBackInTab = "jump_back_in_tab"
        case jumpBackInSyncedTab = "jump_back_in_synced_tab"
        case jumpBackInTabShowAll = "jump_back_in_show_all_button"
        case jumpBackInSyncedTabShowAll = "synced_show_all_button"
        case bookmark = "bookmark"
        case bookmarkShowAll = "bookmarks_show_all_button"
        case story = "story"
        case customizeHomepage = "customize_homepage_button"

        var sectionName: String {
            switch self {
            case .topSite:
                return "top_sites"
            case .jumpBackInTab, .jumpBackInSyncedTab, .jumpBackInTabShowAll, .jumpBackInSyncedTabShowAll:
                return "jump_back_in"
            case .bookmark, .bookmarkShowAll:
                return "bookmarks"
            case .story:
                return "stories"
            case .customizeHomepage:
                return "customize_homepage"
            }
        }
    }

    private let gleanWrapper: GleanWrapper
    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    // MARK: - General
    func sendHomepageImpressionEvent() {
        gleanWrapper.recordEvent(for: GleanMetrics.Homepage.viewed)
    }

    func sendItemTappedTelemetryEvent(for itemType: ItemType) {
        let itemNameExtra = GleanMetrics.Homepage.ItemTappedExtra(section: itemType.sectionName, type: itemType.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.Homepage.itemTapped, extras: itemNameExtra)
    }

    func sendSectionLabeledCounter(for itemType: ItemType) {
        gleanWrapper.recordLabel(for: GleanMetrics.Homepage.sectionViewed, label: itemType.sectionName)
    }

    // MARK: - Top Sites
    enum ContextMenuTelemetryActionType: String {
        case remove, unpin, pin, settings, sponsoredSupport
    }

    func sendOpenInPrivateTabEventForTopSites() {
        gleanWrapper.recordEvent(for: GleanMetrics.TopSites.openInPrivateTab)
    }

    func sendContextMenuOpenedEventForTopSites(for type: ContextMenuTelemetryActionType) {
        gleanWrapper.recordEvent(
            for: GleanMetrics.TopSites.contextualMenu,
            extras: GleanMetrics.TopSites.ContextualMenuExtra(type: type.rawValue)
        )
    }

    func sendTopSitesPressedEvent(position: Int, tileType: String, isZeroSearch: Bool) {
        let originExtra: TelemetryWrapper.EventValue = isZeroSearch ? .fxHomepageOriginZeroSearch : .fxHomepageOriginOther
        gleanWrapper.recordLabel(
            for: GleanMetrics.TopSites.pressedTileOrigin,
            label: originExtra.rawValue
        )
        gleanWrapper.recordEvent(
            for: GleanMetrics.TopSites.tilePressed,
            extras: GleanMetrics.TopSites.TilePressedExtra(position: "\(position)", tileType: tileType)
        )
    }

    // MARK: - Pocket
    func sendTapOnPocketStoryCounter(position: Int, isZeroSearch: Bool) {
        let originExtra: TelemetryWrapper.EventValue = isZeroSearch ? .fxHomepageOriginZeroSearch : .fxHomepageOriginOther
        gleanWrapper.recordLabel(for: GleanMetrics.Pocket.openStoryOrigin, label: originExtra.rawValue)
        gleanWrapper.recordLabel(for: GleanMetrics.Pocket.openStoryPosition, label: "position-\(position)")
    }

    func sendPocketSectionCounter() {
        gleanWrapper.incrementCounter(for: GleanMetrics.Pocket.sectionImpressions)
    }

    func sendOpenInPrivateTabEventForPocket() {
        gleanWrapper.recordEvent(for: GleanMetrics.Pocket.openInPrivateTab)
    }
}
