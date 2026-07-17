// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

struct WorldCupTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func closeCountdownWidgetButtonTapped() {
       gleanWrapper.recordEvent(for: GleanMetrics.WorldCupCountdownWidget.closeButton)
    }

    func viewScheduleTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupCountdownWidget.viewSchedule)
    }

    func countrySelected(fifaCode: String) {
        let extra = GleanMetrics.WorldCupWidget.CountrySelectedExtra(fifaCode: fifaCode)
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.countrySelected, extras: extra)
    }

    func countryDeselected() {
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.countryDeselected)
    }

    func widgetDismissed() {
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.widgetDismissed)
    }

    func errorRefreshButtonTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.errorRefreshButton)
    }

    func matchClicked(match: String) {
        let extra = GleanMetrics.WorldCupWidget.MatchClickedExtra(match: match)
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.matchClicked, extras: extra)
    }

    func countrySelectorDisplayed() {
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.countrySelectorDisplayed)
    }

    func wallpaperButtonTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.wallpaperButton)
    }

    func shareButtonTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.shareButton)
    }

    func cardSwiped(view: String, isImpression: Bool) {
        let extra = GleanMetrics.WorldCupWidget.CardSwipedExtra(isImpression: isImpression, view: view)
        gleanWrapper.recordEvent(for: GleanMetrics.WorldCupWidget.cardSwiped, extras: extra)
    }
}
