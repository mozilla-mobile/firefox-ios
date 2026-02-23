// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
class BrowserViewControllerConstraintTestsBase: XCTestCase {
    var profile: MockProfile!
    var tabManager: MockTabManager!

    override func setUp() async throws {
        try await super.setUp()
        tabManager = MockTabManager()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManager)
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        tabManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Subject Creation
    func createSubject(isFeatureFlagEnabled: Bool = false, isBottomSearchBar: Bool = true) -> BrowserViewController {
        // Setup feature flag to disabled by default and override only in the test that need it
        setupNimbusSnapKitRemovalTesting(isEnabled: isFeatureFlagEnabled)
        let subject = BrowserViewController(profile: profile,
                                            tabManager: tabManager)
        subject.isBottomSearchBar = isBottomSearchBar
        trackForMemoryLeaks(subject)

        // Trigger view loading and constraint setup
        // SnapKit constraints are created in updateViewConstraints(), so we need to explicitly trigger it
        subject.loadViewIfNeeded()
        subject.view.setNeedsUpdateConstraints()
        subject.view.updateConstraintsIfNeeded()
        subject.view.layoutIfNeeded()

        return subject
    }

    func setupNimbusSnapKitRemovalTesting(isEnabled: Bool) {
        FxNimbus.shared.features.snapkitRemovalRefactor.with { _, _ in
            return SnapkitRemovalRefactor(enabled: isEnabled)
        }
    }
}
