// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct ToolbarTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    // Tap
    func qrCodeButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.QrScanButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.qrScanButtonTapped, extras: isPrivateExtra)
    }

    func clearSearchButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.ClearSearchButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.clearSearchButtonTapped, extras: isPrivateExtra)
    }

    func shareButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.ShareButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.shareButtonTapped, extras: isPrivateExtra)
    }

    func refreshButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.RefreshButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.refreshButtonTapped, extras: isPrivateExtra)
    }

    func readerModeButtonTapped(isPrivate: Bool, isEnabled: Bool) {
        let readerModeExtra = GleanMetrics.Toolbar.ReaderModeButtonTappedExtra(enabled: isPrivate,
                                                                               isPrivate: isEnabled)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.readerModeButtonTapped, extras: readerModeExtra)
    }

    func siteInfoButtonTapped(isPrivate: Bool) {
        let extra = GleanMetrics.Toolbar.SiteInfoButtonTappedExtra(isPrivate: isPrivate,
                                                                   isToolbar: true)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.siteInfoButtonTapped, extras: extra)
    }

    func backButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.BackButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.backButtonTapped, extras: isPrivateExtra)
    }

    func forwardButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.ForwardButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.forwardButtonTapped, extras: isPrivateExtra)
    }

    func homeButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.HomeButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.homeButtonTapped, extras: isPrivateExtra)
    }

    func oneTapNewTabButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.OneTapNewTabButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.oneTapNewTabButtonTapped, extras: isPrivateExtra)
    }

    func searchButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.SearchButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.searchButtonTapped, extras: isPrivateExtra)
    }

    func tabTrayButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.TabTrayButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.tabTrayButtonTapped, extras: isPrivateExtra)
    }

    func menuButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.AppMenuButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.appMenuButtonTapped, extras: isPrivateExtra)
    }

    func dataClearanceButtonTapped(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.DataClearanceButtonTappedExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.dataClearanceButtonTapped, extras: isPrivateExtra)
    }

    // Long Press
    func backButtonLongPressed(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.BackLongPressExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.backLongPress, extras: isPrivateExtra)
    }

    func forwardButtonLongPressed(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.ForwardLongPressExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.forwardLongPress, extras: isPrivateExtra)
    }

    func oneTapNewTabButtonLongPressed(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.OneTapNewTabLongPressExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.oneTapNewTabLongPress, extras: isPrivateExtra)
    }

    func tabTrayButtonLongPressed(isPrivate: Bool) {
        let isPrivateExtra = GleanMetrics.Toolbar.TabTrayLongPressExtra(isPrivate: isPrivate)
        gleanWrapper.recordEvent(for: GleanMetrics.Toolbar.tabTrayLongPress, extras: isPrivateExtra)
    }

    // Other
    func dragInteractionStarted() {
        gleanWrapper.recordEvent(for: GleanMetrics.Awesomebar.dragLocationBar)
    }
}
