// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest

@testable import Client

@MainActor
final class TabGroupsFeatureFlagTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        AppContainer.shared.reset()
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.tabGroupsFeature.with { variables, prefs in
            TabGroupsFeature(variables, prefs)
        }
        AppContainer.shared.reset()
        try await super.tearDown()
    }

    func testDefaultIsDisabled() {
        XCTAssertFalse(TabGroupsFeature().enabled)
    }

    func testNimbusChangesAreReadWithoutCaching() {
        let provider = FeatureFlagsProvider(prefs: MockProfilePrefs())
        AppContainer.shared.register(service: provider as FeatureFlagProviding)
        AppContainer.shared.bootstrap()

        FxNimbus.shared.features.tabGroupsFeature.with { _, _ in TabGroupsFeature(enabled: false) }
        XCTAssertFalse(TabGroupsFeatureFlag.isEnabled)

        FxNimbus.shared.features.tabGroupsFeature.with { _, _ in TabGroupsFeature(enabled: true) }
        XCTAssertTrue(TabGroupsFeatureFlag.isEnabled)

        FxNimbus.shared.features.tabGroupsFeature.with { _, _ in TabGroupsFeature(enabled: false) }
        XCTAssertFalse(TabGroupsFeatureFlag.isEnabled)
    }

    func testDebugOverrideCanEnableTheFeature() throws {
        let prefs = MockProfilePrefs()
        let provider = FeatureFlagsProvider(prefs: prefs)
        FxNimbus.shared.features.tabGroupsFeature.with { _, _ in TabGroupsFeature(enabled: false) }

        provider.setDebugOverride(.tabGroups, to: true)

        XCTAssertEqual(prefs.boolForKey(try XCTUnwrap(FeatureFlagID.tabGroups.debugKey)), true)
        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        XCTAssertTrue(provider.isEnabled(.tabGroups))
        #else
        XCTAssertFalse(provider.isEnabled(.tabGroups))
        #endif
    }

    func testDebugOverrideCanDisableTheFeature() throws {
        let prefs = MockProfilePrefs()
        let provider = FeatureFlagsProvider(prefs: prefs)
        FxNimbus.shared.features.tabGroupsFeature.with { _, _ in TabGroupsFeature(enabled: true) }

        provider.setDebugOverride(.tabGroups, to: false)

        XCTAssertEqual(prefs.boolForKey(try XCTUnwrap(FeatureFlagID.tabGroups.debugKey)), false)
        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        XCTAssertFalse(provider.isEnabled(.tabGroups))
        #else
        XCTAssertTrue(provider.isEnabled(.tabGroups))
        #endif
    }
}
