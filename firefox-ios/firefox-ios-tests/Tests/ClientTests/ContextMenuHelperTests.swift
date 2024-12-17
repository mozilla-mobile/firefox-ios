// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Shared
import XCTest

@testable import Client

class ContextMenuHelperTests: XCTestCase {
    var profile: Profile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()

        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        DependencyHelperMock().bootstrapDependencies()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        AppContainer.shared.reset()
    }

    func testHistoryHighlightsTelemetry() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          theme: LightTheme())
        let helper = HomepageContextMenuHelper(viewModel: viewModel, toastContainer: UIView())

        helper.sendHistoryHighlightContextualTelemetry(type: .remove)

        testEventMetricRecordingSuccess(metric: GleanMetrics.FirefoxHomePage.historyHighlightsContext)
    }
}
