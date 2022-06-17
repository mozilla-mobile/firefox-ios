// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

class ContextMenuHelperTests: XCTestCase {

    var profile: Profile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()

        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testHistoryHighlightsTelemetry() {
        let viewModel = HomepageViewModel(profile: profile,
                                             isPrivate: false)
        let helper = HomepageContextMenuHelper(viewModel: viewModel)

        helper.sendHistoryHighlightContextualTelemetry(type: .remove)

        testEventMetricRecordingSuccess(metric: GleanMetrics.FirefoxHomePage.historyHighlightsContext)
    }
}
