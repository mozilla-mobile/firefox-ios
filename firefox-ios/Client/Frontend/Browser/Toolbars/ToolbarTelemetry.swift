// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct ToolbarTelemetry {
    // Tap
    func qrCodeButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.QrScanButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.qrScanButtonTapped.record(isPrivateExtra)
    }

    func clearSearchButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.ClearSearchButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.clearSearchButtonTapped.record(isPrivateExtra)
    }

    func shareButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.ShareButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.shareButtonTapped.record(isPrivateExtra)
    }

    func refreshButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.RefreshButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.refreshButtonTapped.record(isPrivateExtra)
    }

    func readerModeButtonTapped(isPrivate: Bool, isEnabled: Bool) {
        let readerModeExtra = GleanMetrics.Toolbar.ReaderModeButtonTappedExtra(enabled: isPrivate,
                                                                               isPrivate: isEnabled)
        GleanMetrics.Toolbar.readerModeButtonTapped.record(readerModeExtra)
    }

    func siteInfoButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.SiteInfoButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.siteInfoButtonTapped.record(isPrivateExtra)
    }

    func backButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.BackButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.backButtonTapped.record(isPrivateExtra)
    }

    func forwardButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.ForwardButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.forwardButtonTapped.record(isPrivateExtra)
    }

    func homeButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.HomeButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.homeButtonTapped.record(isPrivateExtra)
    }

    func oneTapNewTabButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.OneTapNewTabButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.oneTapNewTabButtonTapped.record(isPrivateExtra)
    }

    func searchButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.SearchButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.searchButtonTapped.record(isPrivateExtra)
    }

    func tabTrayButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.TabTrayButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.tabTrayButtonTapped.record(isPrivateExtra)
    }

    func menuButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.AppMenuButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.appMenuButtonTapped.record(isPrivateExtra)
    }

    func dataClearanceButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.DataClearanceButtonTappedExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.dataClearanceButtonTapped.record(isPrivateExtra)
    }

    // Long Press
    func backButtonLongPressed(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.BackLongPressExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.backLongPress.record(isPrivateExtra)
    }

    func forwardButtonLongPressed(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.ForwardLongPressExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.forwardLongPress.record(isPrivateExtra)
    }

    func oneTapNewTabButtonLongPressed(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.OneTapNewTabLongPressExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.oneTapNewTabLongPress.record(isPrivateExtra)
    }

    func tabTrayButtonLongPressed(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.TabTrayLongPressExtra(isPrivate: isPrivate)
        GleanMetrics.Toolbar.tabTrayLongPress.record(isPrivateExtra)
    }
}
