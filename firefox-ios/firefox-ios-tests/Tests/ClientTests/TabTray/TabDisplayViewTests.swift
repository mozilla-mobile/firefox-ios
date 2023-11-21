// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client
final class TabDisplayViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testNumberOfSections_ForRegularTabsWithInactiveTabs() {
        let subject = createSubject(isPrivateMode: false,
                                    emptyTabs: false,
                                    emptyInactiveTabs: false)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
    }

    func testNumberOfSections_ForRegularTabsWithoutInactiveTabs() {
        let subject = createSubject(isPrivateMode: false,
                                    emptyTabs: false,
                                    emptyInactiveTabs: true)

        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
    }

    func testNumberOfSections_PrivateTabsAndInactiveTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: false,
                                    emptyInactiveTabs: false)

        let numberOfSections = subject.collectionView.numberOfSections
        XCTAssertEqual(numberOfSections, 1)
    }

    func testNumberOfSections_PrivateTabsWithoutInactiveTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: false,
                                    emptyInactiveTabs: true)

        let numberOfSections = subject.collectionView.numberOfSections
        XCTAssertEqual(numberOfSections, 1)
    }

    func testNumberOfSections_PrivateTabsWithEmptyTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: true,
                                    emptyInactiveTabs: true)

        let numberOfSections = subject.collectionView.numberOfSections
        XCTAssertEqual(numberOfSections, 0)
    }

    func testAmountOfSections_ForPrivateTabsWithoutInactiveTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: false,
                                    emptyInactiveTabs: true)

        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
    }

    // This case is not possible adding the test to check the logic still
    func testAmountOfSections_ForPrivateTabsWithInactiveTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: false,
                                    emptyInactiveTabs: false)

        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
    }

    // MARK: - Private
    private func createSubject(isPrivateMode: Bool,
                               emptyTabs: Bool,
                               emptyInactiveTabs: Bool,
                               file: StaticString = #file,
                               line: UInt = #line) -> TabDisplayView {
        let tabs: [TabCellModel] = emptyTabs ? [TabCellModel]() : [TabCellModel.emptyTabState(title: "Tab1"),
                                                                   TabCellModel.emptyTabState(title: "Tab2")]
        let inactiveTabs: [String] = emptyInactiveTabs ? [String]() : ["Inactive1", "Inactive2"]
        let isInactiveTabsExpanded = !isPrivateMode && !inactiveTabs.isEmpty
        let tabState = TabsState(isPrivateMode: isPrivateMode,
                                 tabs: tabs,
                                 inactiveTabs: inactiveTabs,
                                 isInactiveTabsExpanded: isInactiveTabsExpanded)

        let subject = TabDisplayView(state: tabState)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
