// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

class ContextMenuHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()

        Glean.shared.resetGlean(clearStores: true)
    }

    func testHistoryHighlightsTelemetry() {
        let profile = MockProfile()
        let viewModel = FirefoxHomeViewModel(profile: profile,
                                             isPrivate: false)
        let helper = FirefoxHomeContextMenuHelper(viewModel: viewModel)

        helper.sendHistoryHighlightContextualTelemetry(type: .remove)

        testEventMetricRecordingSuccess(metric: GleanMetrics.FirefoxHomePage.historyHighlightsContext)
    }
}
