// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class FirefoxHomeViewModelTests: XCTestCase {

    var reloadSectionCompleted: ((FXHomeViewModelProtocol) -> Void)?

    // MARK: Number of sections
    func testNumberOfSection_withoutUpdatingData() {
        let profile = MockProfile()
        let viewModel = FirefoxHomeViewModel(profile: profile,
                                             isPrivate: false)
        XCTAssertEqual(viewModel.shownSections.count, 2)
    }

    func testNumberOfSection_updatingData_adds2Sections() {
        let collectionView = UICollectionView(frame: CGRect.zero,
                                              collectionViewLayout: UICollectionViewLayout())
        let profile = MockProfile()
        let viewModel = FirefoxHomeViewModel(profile: profile,
                                             isPrivate: false)
        viewModel.delegate = self
        viewModel.updateData()

        let expectation = expectation(description: "Wait for sections to be reloaded")
        expectation.expectedFulfillmentCount = 2
        reloadSectionCompleted = { section in
            ensureMainThread {
                viewModel.reloadSection(section, with: collectionView)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(viewModel.shownSections.count, 4)
    }

    // MARK: Orders of sections
    func testSectionOrder_addingJumpBackIn() {
        let profile = MockProfile()
        let viewModel = FirefoxHomeViewModel(profile: profile,
                                             isPrivate: false)

        viewModel.addShownSection(section: FirefoxHomeSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], FirefoxHomeSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], FirefoxHomeSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], FirefoxHomeSectionType.customizeHome)
    }

    func testSectionOrder_addingTwoSections() {
        let profile = MockProfile()
        let viewModel = FirefoxHomeViewModel(profile: profile,
                                             isPrivate: false)

        viewModel.addShownSection(section: FirefoxHomeSectionType.jumpBackIn)
        viewModel.addShownSection(section: FirefoxHomeSectionType.pocket)
        XCTAssertEqual(viewModel.shownSections.count, 4)
        XCTAssertEqual(viewModel.shownSections[0], FirefoxHomeSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], FirefoxHomeSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], FirefoxHomeSectionType.pocket)
        XCTAssertEqual(viewModel.shownSections[3], FirefoxHomeSectionType.customizeHome)
    }

    func testSectionOrder_addingAndRemovingSections() {
        let profile = MockProfile()
        let viewModel = FirefoxHomeViewModel(profile: profile,
                                             isPrivate: false)

        viewModel.addShownSection(section: FirefoxHomeSectionType.jumpBackIn)
        viewModel.addShownSection(section: FirefoxHomeSectionType.pocket)
        viewModel.removeShownSection(section: FirefoxHomeSectionType.customizeHome)
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], FirefoxHomeSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], FirefoxHomeSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], FirefoxHomeSectionType.pocket)
    }

    func testSectionOrder_addingAndRemovingMoreSections() {
        let profile = MockProfile()
        let viewModel = FirefoxHomeViewModel(profile: profile,
                                             isPrivate: false)

        viewModel.addShownSection(section: FirefoxHomeSectionType.jumpBackIn)
        viewModel.addShownSection(section: FirefoxHomeSectionType.pocket)
        viewModel.addShownSection(section: FirefoxHomeSectionType.historyHighlights)
        viewModel.removeShownSection(section: FirefoxHomeSectionType.customizeHome)
        XCTAssertEqual(viewModel.shownSections.count, 4)
        XCTAssertEqual(viewModel.shownSections[0], FirefoxHomeSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], FirefoxHomeSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], FirefoxHomeSectionType.historyHighlights)
        XCTAssertEqual(viewModel.shownSections[3], FirefoxHomeSectionType.pocket)

        viewModel.removeShownSection(section: FirefoxHomeSectionType.historyHighlights)

        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], FirefoxHomeSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], FirefoxHomeSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], FirefoxHomeSectionType.pocket)
    }
}

// MARK: - FirefoxHomeViewModelDelegate
extension FirefoxHomeViewModelTests: FirefoxHomeViewModelDelegate {

    func reloadSection(section: FXHomeViewModelProtocol) {
        reloadSectionCompleted?(section)
    }
}
