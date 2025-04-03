// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct HomepageTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
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

    // MARK: - Customize Homepage
    func sendTapOnCustomizeHomepageTelemetry() {
        gleanWrapper.incrementCounter(for: GleanMetrics.FirefoxHomePage.customizeHomepageButton)
    }
}
