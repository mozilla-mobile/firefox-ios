// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

class FirefoxHomeViewModelTests: XCTestCase {

    var reloadSectionCompleted: ((HomepageViewModelProtocol) -> Void)?

    // MARK: Number of sections
    func testNumberOfSection_withoutUpdatingData() {
        let profile = createProfile()

        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false)
        XCTAssertEqual(viewModel.shownSections.count, 2, "Has fx logo header and customize homepage sections")
    }

    func testNumberOfSection_withoutUpdatingData_withGoogleTopSite() {
        let profile = createProfile(hasGoogleTopSite: true)
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false)
        XCTAssertEqual(viewModel.shownSections.count, 3, "Has fx logo, topsites and customize home page sections")
    }

    func testNumberOfSection_updatingData_adds2Sections() throws {
        throw XCTSkip("Disabled until homepage's reload issue is solved")
//        let collectionView = UICollectionView(frame: CGRect.zero,
//                                              collectionViewLayout: UICollectionViewLayout())
//        let profile = createProfile()
//        let viewModel = HomepageViewModel(profile: profile,
//                                          isPrivate: false)
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
    }

    // MARK: Orders of sections
    func testSectionOrder_addingJumpBackIn() {
        let profile = createProfile()
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false)

        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.customizeHome)
    }

    func testSectionOrder_addingTwoSections() {
        let profile = createProfile()
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
        let profile = createProfile()
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
        let profile = createProfile()
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

    // Without fetching history from backend, we know we'll show top sites if Google top sites needs to show
    func createProfile(hasGoogleTopSite: Bool = false) -> Profile {
        let profile = MockProfile()
        profile.prefs.setBool(!hasGoogleTopSite, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        profile.prefs.setBool(!hasGoogleTopSite, forKey: PrefsKeys.GoogleTopSiteHideKey)

        return profile
    }

    func reloadSection(section: HomepageViewModelProtocol) {
        reloadSectionCompleted?(section)
    }
}
