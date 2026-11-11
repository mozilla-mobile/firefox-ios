// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct TabLossTelemetry {
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
        let extras = GleanMetrics.AppErrors.TabLossDetectedExtra(
            actual: Int32(details.actual),
            expected: Int32(details.expected),
            missing: Int32(details.missing),
            windows: Int32(details.windows)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.AppErrors.tabLossDetected, extras: extras)
    }

    func recordTabCountDiscrepancy(withDetails details: TabLossDiagnostic) {
        let extras = GleanMetrics.AppErrors.TabCountDiscrepancyExtra(
            actual: Int32(details.actual),
            expected: Int32(details.expected),
            missing: Int32(details.missing),
            windows: Int32(details.windows)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.AppErrors.tabCountDiscrepancy, extras: extras)
    }
}
