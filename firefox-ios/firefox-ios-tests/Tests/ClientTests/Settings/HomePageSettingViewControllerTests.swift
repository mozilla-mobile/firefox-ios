// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class HomePageSettingViewControllerTests: XCTestCase {
    private var profile: Profile!
    private var wallpaperManager: WallpaperManagerMock!
    private var delegate: MockSettingsDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.profile = MockProfile()
        self.delegate = MockSettingsDelegate()
        self.wallpaperManager = WallpaperManagerMock()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        self.profile = nil
        self.delegate = nil
        super.tearDown()
    }

    func testHomePageSettingsLeaks_InitCall() throws {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    // MARK: - Helper
    private func createSubject() -> HomePageSettingViewController {
        let subject = HomePageSettingViewController(prefs: profile.prefs,
                                                    wallpaperManager: wallpaperManager,
                                                    settingsDelegate: delegate,
                                                    tabManager: MockTabManager())
        trackForMemoryLeaks(subject)
        return subject
    }
}
