// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class HomeLogoHeaderViewModelTests: XCTestCase, FeatureFlaggable {
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        featureFlags.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testDefaultHomepageViewModelProtocolValues() {
        let sut = createSut()
        XCTAssertEqual(sut.sectionType, .logoHeader)
        XCTAssertEqual(sut.headerViewModel, LabelButtonHeaderViewModel.emptyHeader)
        XCTAssertEqual(sut.numberOfItemsInSection(), 1)
        XCTAssertTrue(sut.isEnabled)
    }

    func testConfigureOnTapAction() throws {
        let sut = createSut()

        let cellBeforeConfig = HomeLogoHeaderCell(frame: CGRect.zero)
        XCTAssertNil(cellBeforeConfig.logoButton.touchUpAction)

        sut.onTapAction = { _ in }
        let cellAfterConfig = try XCTUnwrap(sut.configure(HomeLogoHeaderCell(frame: CGRect.zero),
                                                          at: IndexPath()) as? HomeLogoHeaderCell)
        XCTAssertNotNil(cellAfterConfig.logoButton.touchUpAction)
    }
}

extension HomeLogoHeaderViewModelTests {

    func createSut(file: StaticString = #file, line: UInt = #line) -> HomeLogoHeaderViewModel {
        let sut = HomeLogoHeaderViewModel(profile: profile)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}

extension LabelButtonHeaderViewModel: Equatable {
    public static func == (lhs: LabelButtonHeaderViewModel, rhs: LabelButtonHeaderViewModel) -> Bool {
        return lhs.title == rhs.title && lhs.isButtonHidden == rhs.isButtonHidden
    }
}
