// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

import XCTest

@testable import Client

final class BrowsingSettingsViewControllerTests: XCTestCase {
    private var profile: Profile!
    private var delegate: MockSettingsDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.profile = MockProfile()
        self.delegate = MockSettingsDelegate()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        self.profile = nil
        self.delegate = nil
    }

    func testHomePageSettingsLeaks_InitCall() throws {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    // MARK: - Helper
    private func createSubject() -> BrowsingSettingsViewController {
        let subject = BrowsingSettingsViewController(profile: profile,
                                                     windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
