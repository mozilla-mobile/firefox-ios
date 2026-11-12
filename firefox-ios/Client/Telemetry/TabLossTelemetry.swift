// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol TabLossTelemetryRecording {
    func recordTabLossDetected(withDetails details: TabLossTelemetry.TabLossDiagnostic)
    func recordTabCountDiscrepancy(withDetails details: TabLossTelemetry.TabLossDiagnostic)
}

struct TabLossTelemetry: TabLossTelemetryRecording {
    private let gleanWrapper: GleanWrapper

    struct TabLossDiagnostic {
        var actual: Int
        var expected: Int
        var missing: Int
        var windows: Int

        var sentryExtras: [String: String] {
            [
                "actual": String(actual),
                "expected": String(expected),
                "missing": String(missing),
                "windows": String(windows)
            ]
        }
    }

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func recordTabLossDetected(withDetails details: TabLossDiagnostic) {
        // Int32(clamping:) ensures we don't crash on overflow values
        let extras = GleanMetrics.AppErrors.TabLossDetectedExtra(
            actual: Int32(clamping: details.actual),
            expected: Int32(clamping: details.expected),
            missing: Int32(clamping: details.missing),
            windows: Int32(clamping: details.windows)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.AppErrors.tabLossDetected, extras: extras)
    }

    func recordTabCountDiscrepancy(withDetails details: TabLossDiagnostic) {
        // Int32(clamping:) ensures we don't crash on overflow values
        let extras = GleanMetrics.AppErrors.TabCountDiscrepancyExtra(
            actual: Int32(clamping: details.actual),
            expected: Int32(clamping: details.expected),
            missing: Int32(clamping: details.missing),
            windows: Int32(clamping: details.windows)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.AppErrors.tabCountDiscrepancy, extras: extras)
    }
}
