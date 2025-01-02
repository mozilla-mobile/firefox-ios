// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import Common
@testable import Client

class SnapshotBaseTests: XCTestCase {

    var profile: MockProfile!
    var themeManager: ThemeManager!
    private let allThemes: [ThemeConfiguration] = [
        ThemeConfiguration(theme: .light),
        ThemeConfiguration(theme: .dark)
    ]

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies(themeManager: EcosiaMockThemeManager())
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        themeManager = AppContainer.shared.resolve()
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
    }
}
