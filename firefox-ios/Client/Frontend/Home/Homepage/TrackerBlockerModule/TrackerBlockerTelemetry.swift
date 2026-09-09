// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct TrackerBlockerTelemetry {
    /// The digit-count boundaries the lifetime total is reported in: 4 figures (1,000) up to 8 (10,000,000
    /// and above). Totals below the lower bound are not banded at all.
    static let lowestReportableFigures = 4
    private static let highestReportableFigures = 8

    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// The band `count` falls in, or `nil` when it is below the lowest reportable boundary. Counts above the
    /// highest boundary report as that boundary.
    static func reportableFigures(for count: Int) -> Int? {
        guard count > 0 else { return nil }
        let figures = String(count).count
        guard figures >= lowestReportableFigures else { return nil }
        return min(figures, highestReportableFigures)
    }

    /// - Parameters:
    ///   - presentation: which of the sheet's three states it opened in.
    ///   - lifetimeCount: the lifetime blocked total at the moment the sheet opened, banded before it is
    ///     recorded. Totals below the lowest band are recorded without the `figures` extra.
    func dashboardViewed(presentation: TrackerBlockerSheetState.Presentation, lifetimeCount: Int) {
        let extra = GleanMetrics.TrackerBlocker.DashboardViewedExtra(
            dashboardState: Self.dashboardState(for: presentation),
            figures: Self.reportableFigures(for: lifetimeCount).map { Int32($0) }
        )
        gleanWrapper.recordEvent(
            for: GleanMetrics.TrackerBlocker.dashboardViewed,
            extras: extra
        )
    }

    private static func dashboardState(for presentation: TrackerBlockerSheetState.Presentation) -> String {
        switch presentation {
        case .empty: return "empty"
        case .weeklyReset: return "weekly_reset"
        case .filled: return "populated"
        }
    }

    func lifetimeThresholdReached(figures: Int) {
        let extra = GleanMetrics.TrackerBlocker.LifetimeThresholdReachedExtra(figures: Int32(figures))
        gleanWrapper.recordEvent(
            for: GleanMetrics.TrackerBlocker.lifetimeThresholdReached,
            extras: extra
        )
    }
}
