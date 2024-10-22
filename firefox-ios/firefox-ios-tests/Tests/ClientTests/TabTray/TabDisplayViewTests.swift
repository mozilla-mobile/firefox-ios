// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client
final class TabDisplayViewTests: XCTestCase {
    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        profile = nil
    }

    // TODO: Add Tests Using Diffable Datasource

//    func testNumberOfSections_ForRegularTabsWithInactiveTabs() {
//        let subject = createSubject(isPrivateMode: false,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: false)
//
//        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
//    }
//
//    func testNumberOfSections_ForRegularTabsWithoutInactiveTabs() {
//        let subject = createSubject(isPrivateMode: false,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: true)
//
//        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
//    }
//
//    func testNumberOfSections_PrivateTabsAndInactiveTabs() {
//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: false)
//
//        let numberOfSections = subject.collectionView.numberOfSections
//        XCTAssertEqual(numberOfSections, 1)
//    }
//
//    func testNumberOfSections_PrivateTabsWithoutInactiveTabs() {
//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: true)
//
//        let numberOfSections = subject.collectionView.numberOfSections
//        XCTAssertEqual(numberOfSections, 1)
//    }
//
//    func testNumberOfSections_PrivateTabsWithEmptyTabs() {
//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: true,
//                                    emptyInactiveTabs: true)
//
//        let numberOfSections = subject.collectionView.numberOfSections
//        XCTAssertEqual(numberOfSections, 0)
//    }
//
//    func testAmountOfSections_ForPrivateTabsWithoutInactiveTabs() {
//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: true)
//
//        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
//    }
//
//    // This case is not possible adding the test to check the logic still
//    func testAmountOfSections_ForPrivateTabsWithInactiveTabs() {
//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: false)
//
//        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
//    }
//
//    func testNumberOfItemsSection_ForRegularTabsWithInactiveTabs() {
//        let subject = createSubject(isPrivateMode: false,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: false)
//
//        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 2)
//        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 3)
//    }
//
//    // MARK: - Private
//    private func createSubject(isPrivateMode: Bool,
//                               emptyTabs: Bool,
//                               emptyInactiveTabs: Bool,
//                               file: StaticString = #file,
//                               line: UInt = #line) -> TabDisplayView {
//        let tabs = createTabs(emptyTabs)
//        var inactiveTabs = [InactiveTabsModel]()
//        let tabUUID = "UUID"
//        if !emptyInactiveTabs {
//            for index in 0..<2 {
//                let inactiveTabModel = InactiveTabsModel(id: tabUUID,
//                                                         tabUUID: tabUUID,
//                                                         title: "InactiveTab\(index)",
//                                                         url: nil)
//                inactiveTabs.append(inactiveTabModel)
//            }
//        }
//        let isInactiveTabsExpanded = !isPrivateMode && !inactiveTabs.isEmpty
//        let tabState = TabsPanelState(windowUUID: .XCTestDefaultUUID,
//                                      isPrivateMode: isPrivateMode,
//                                      tabs: tabs,
//                                      inactiveTabs: inactiveTabs,
//                                      isInactiveTabsExpanded: isInactiveTabsExpanded)
//
//        let subject = TabDisplayView(panelType: isPrivateMode ? .privateTabs : .tabs,
//                                     state: tabState,
//                                     windowUUID: .XCTestDefaultUUID)
//        trackForMemoryLeaks(subject, file: file, line: line)
//        return subject
//    }
//
//    private func createTabs(_ emptyTabs: Bool) -> [TabModel] {
//        guard !emptyTabs else { return [TabModel]() }
//
//        var tabs = [TabModel]()
//        for index in 0...2 {
//            let tabModel = TabModel.emptyState(tabUUID: "", title: "Tab \(index)")
//            tabs.append(tabModel)
//        }
//        return tabs
//    }
}
