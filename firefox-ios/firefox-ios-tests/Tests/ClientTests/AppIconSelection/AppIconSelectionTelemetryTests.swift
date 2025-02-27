// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class AppIconSelectionTelemetryTests: XCTestCase {
    // For telemetry extras
    let nameIdentifierKey = "name"

    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    func testSelectedIcon() throws {
        let subject = createSubject()
        let appIcon = AppIcon.darkPurple

        subject.selectedIcon(appIcon: appIcon)

        testEventMetricRecordingSuccess(metric: GleanMetrics.SettingsAppIcon.selected)

        let resultValue = try XCTUnwrap(GleanMetrics.SettingsAppIcon.selected.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[nameIdentifierKey], appIcon.displayName)
    }

    func createSubject() -> AppIconSelectionTelemetry {
        return AppIconSelectionTelemetry()
    }
}
