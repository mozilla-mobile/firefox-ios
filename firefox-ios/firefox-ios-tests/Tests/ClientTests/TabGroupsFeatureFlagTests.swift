// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TabGroupsFeatureFlagTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: makeProfile())
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.tabGroupsFeature.with { variables, prefs in
            TabGroupsFeature(variables, prefs)
        }
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testDefaultIsDisabled() {
        XCTAssertFalse(TabGroupsFeature().enabled)
    }

    func testNimbusValueControlsTabGroups() {
        setupNimbusTabGroupsTesting(isEnabled: false)
        XCTAssertFalse(TabGroupsFeatureFlag.isEnabled)

        setupNimbusTabGroupsTesting(isEnabled: true)
        XCTAssertTrue(TabGroupsFeatureFlag.isEnabled)

        setupNimbusTabGroupsTesting(isEnabled: false)
        XCTAssertFalse(TabGroupsFeatureFlag.isEnabled)
    }

    private func setupNimbusTabGroupsTesting(isEnabled: Bool) {
        FxNimbus.shared.features.tabGroupsFeature.with { _, _ in
            return TabGroupsFeature(enabled: isEnabled)
        }
    }
}
