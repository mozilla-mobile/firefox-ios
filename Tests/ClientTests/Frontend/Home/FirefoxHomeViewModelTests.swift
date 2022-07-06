// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class FirefoxHomeViewModelTests: XCTestCase {

    var reloadSectionCompleted: ((HomepageViewModelProtocol) -> Void)?

    // MARK: Number of sections
    func testNumberOfSection_withoutUpdatingData() {
        let profile = MockProfile()
        let viewModel = HomepageViewModel(profile: profile,
                                             isPrivate: false)
        XCTAssertEqual(viewModel.shownSections.count, 2)
    }

// TODO: Disabled until homepage's reload issue is solved next sprint.
//    func testNumberOfSection_updatingData_adds2Sections() {
//        let collectionView = UICollectionView(frame: CGRect.zero,
//                                              collectionViewLayout: UICollectionViewLayout())
//        let profile = MockProfile()
//        let viewModel = FirefoxHomeViewModel(profile: profile,
//                                             isPrivate: false)
//        viewModel.delegate = self
//        viewModel.updateData()
//
//        let expectation = expectation(description: "Wait for sections to be reloaded")
//        expectation.expectedFulfillmentCount = 2
//        reloadSectionCompleted = { section in
//            ensureMainThread {
//                viewModel.reloadSection(section, with: collectionView)
//                expectation.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1.0, handler: nil)
//
//        XCTAssertEqual(viewModel.shownSections.count, 4)
//    }

    // MARK: Orders of sections
    func testSectionOrder_addingJumpBackIn() {
        let profile = MockProfile()
        let viewModel = HomepageViewModel(profile: profile,
                                             isPrivate: false)

        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.customizeHome)
    }

    func testSectionOrder_addingTwoSections() {
        let profile = MockProfile()
        let viewModel = HomepageViewModel(profile: profile,
                                             isPrivate: false)

        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        viewModel.addShownSection(section: HomepageSectionType.pocket)
        XCTAssertEqual(viewModel.shownSections.count, 4)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.pocket)
        XCTAssertEqual(viewModel.shownSections[3], HomepageSectionType.customizeHome)
    }

    func testSectionOrder_addingAndRemovingSections() {
        let profile = MockProfile()
        let viewModel = HomepageViewModel(profile: profile,
                                             isPrivate: false)

        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        viewModel.addShownSection(section: HomepageSectionType.pocket)
        viewModel.removeShownSection(section: HomepageSectionType.customizeHome)
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.pocket)
    }

    func testSectionOrder_addingAndRemovingMoreSections() {
        let profile = MockProfile()
        let viewModel = HomepageViewModel(profile: profile,
                                             isPrivate: false)

        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        viewModel.addShownSection(section: HomepageSectionType.pocket)
        viewModel.addShownSection(section: HomepageSectionType.historyHighlights)
        viewModel.removeShownSection(section: HomepageSectionType.customizeHome)
        XCTAssertEqual(viewModel.shownSections.count, 4)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.historyHighlights)
        XCTAssertEqual(viewModel.shownSections[3], HomepageSectionType.pocket)

        viewModel.removeShownSection(section: HomepageSectionType.historyHighlights)

        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.pocket)
    }
}

// MARK: - FirefoxHomeViewModelDelegate
extension FirefoxHomeViewModelTests: HomepageViewModelDelegate {

    func reloadSection(section: HomepageViewModelProtocol) {
        reloadSectionCompleted?(section)
    }
}
