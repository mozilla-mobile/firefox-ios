// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared
@testable import Client

class HomeLogoHeaderViewModelTests: XCTestCase, FeatureFlaggable {
    private var profile: MockProfile!
    private var tabManager: MockTabManager!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        tabManager = MockTabManager()
        featureFlags.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testDefaultHomepageViewModelProtocolValues() {
        let subject = createSubject()
        XCTAssertEqual(subject.sectionType, .homepageHeader)
        XCTAssertEqual(subject.headerViewModel, LabelButtonHeaderViewModel.emptyHeader)
        XCTAssertEqual(subject.numberOfItemsInSection(), 1)
        XCTAssertTrue(subject.isEnabled)
    }
}

extension HomeLogoHeaderViewModelTests {
    func createSubject(file: StaticString = #file, line: UInt = #line) -> HomepageHeaderViewModel {
        let subject = HomepageHeaderViewModel(profile: profile, theme: LightTheme(), tabManager: tabManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

extension LabelButtonHeaderViewModel: @retroactive Equatable {
    public static func == (lhs: LabelButtonHeaderViewModel, rhs: LabelButtonHeaderViewModel) -> Bool {
        return lhs.title == rhs.title && lhs.isButtonHidden == rhs.isButtonHidden
    }
}
