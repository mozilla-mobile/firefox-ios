// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

/// Interaction telemetry for the "Report a Website Issue" flow. The report contents
/// travel separately, in the `broken-site-report` ping recorded by `WebCompatReportRecorder`.
struct WebCompatReporterTelemetry {
    /// Raw values match desktop's `webcompatreporting.opened.source`.
    enum Source: String {
        case hamburgerMenu
    }

    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func opened(source: Source) {
        let extra = GleanMetrics.BrokenSiteReportInteractions.OpenedExtra(source: source.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.BrokenSiteReportInteractions.opened, extras: extra)
    }

    func reasonSelected(category: WebCompatIssueCategory) {
        let extra = GleanMetrics.BrokenSiteReportInteractions.ReasonSelectedExtra(reason: category.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.BrokenSiteReportInteractions.reasonSelected, extras: extra)
    }

    func previewed() {
        gleanWrapper.recordEvent(for: GleanMetrics.BrokenSiteReportInteractions.previewed)
    }

    func cancelled() {
        gleanWrapper.recordEvent(for: GleanMetrics.BrokenSiteReportInteractions.cancelled)
    }

    func created(withBlockedTrackers: Bool, withScreenshot: Bool) {
        let extra = GleanMetrics.BrokenSiteReportInteractions.CreatedExtra(
            hasBlockedTrackersList: withBlockedTrackers,
            hasScreenshot: withScreenshot
        )
        gleanWrapper.recordEvent(for: GleanMetrics.BrokenSiteReportInteractions.created, extras: extra)
    }

    func learnMoreTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.BrokenSiteReportInteractions.learnMoreTapped)
    }
}
