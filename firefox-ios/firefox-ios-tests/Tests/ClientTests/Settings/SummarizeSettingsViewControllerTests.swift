// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Shared
import XCTest

@testable import Client

final class SummarizeSettingsViewControllerTests: XCTestCase {
    private var profile: Profile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.profile = MockProfile()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        self.profile = nil
        super.tearDown()
    }

    @MainActor
    func test_generateSettings_hasExpectedSections() {
        let subject = createSubject()
        let sections = subject.generateSettings()
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.title, nil)
        XCTAssertEqual(sections.first?.children.count, 1)
    }

    // MARK: - Helper
    private func createSubject() -> SummarizeSettingsViewController {
        let subject = SummarizeSettingsViewController(prefs: profile.prefs, windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
