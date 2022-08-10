// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class FirefoxHomeViewModelTests: XCTestCase {

    var reloadSectionCompleted: ((HomepageViewModelProtocol) -> Void)?
    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        // Clean user defaults to avoid having flaky test changing the section count
        // because message card reach max amount of impressions
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        reloadSectionCompleted = nil
    }

    // MARK: Number of sections
    func testNumberOfSection_withoutUpdatingData() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          urlBar: URLBarView(profile: profile))
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.messageCard)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.customizeHome)
    }

    func testNumberOfSection_updatingData_adds2Sections() throws {
        throw XCTSkip("Disabled until homepage's reload issue is solved")
//        let collectionView = UICollectionView(frame: CGRect.zero,
//                                              collectionViewLayout: UICollectionViewLayout())
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
    }

    // MARK: Orders of sections
    func testSectionOrder_addingJumpBackIn() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          urlBar: URLBarView(profile: profile))

        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        viewModel.removeShownSection(section: .messageCard)
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.customizeHome)
    }

    func testMessageOrder_AfterMessageDismiss() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          urlBar: URLBarView(profile: profile))

        viewModel.messageCardViewModel.handleMessageDismiss()
        viewModel.reloadView()
        XCTAssertEqual(viewModel.shownSections.count, 2)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.customizeHome)
    }

    func testSectionOrder_addingTwoSections() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          urlBar: URLBarView(profile: profile))

        viewModel.removeShownSection(section: .messageCard)
        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        viewModel.addShownSection(section: HomepageSectionType.pocket)

        XCTAssertEqual(viewModel.shownSections.count, 4)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.pocket)
        XCTAssertEqual(viewModel.shownSections[3], HomepageSectionType.customizeHome)
    }

    func testSectionOrder_addingAndRemovingSections() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          urlBar: URLBarView(profile: profile))

        viewModel.removeShownSection(section: HomepageSectionType.messageCard)
        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        viewModel.addShownSection(section: HomepageSectionType.pocket)
        viewModel.removeShownSection(section: HomepageSectionType.customizeHome)
        XCTAssertEqual(viewModel.shownSections.count, 3)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.jumpBackIn)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.pocket)
    }

    func testSectionOrder_addingAndRemovingMoreSections() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          urlBar: URLBarView(profile: profile))

        viewModel.addShownSection(section: HomepageSectionType.jumpBackIn)
        viewModel.addShownSection(section: HomepageSectionType.pocket)
        viewModel.addShownSection(section: HomepageSectionType.historyHighlights)
        viewModel.removeShownSection(section: HomepageSectionType.messageCard)
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
    func reloadView() {}
}
