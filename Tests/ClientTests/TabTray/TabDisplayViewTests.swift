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

    func testAmountOfSections_ForRegularTabsWithInactiveTabs() {
        let subject = createSubject(isPrivateMode: false,
                                    emptyTabs: false,
                                    emptyInactiveTabs: false)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
    }

    func testAmountOfSections_ForRegularTabsWithoutInactiveTabs() {
        let subject = createSubject(isPrivateMode: false,
                                    emptyTabs: false,
                                    emptyInactiveTabs: true)

        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
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

    func testExpandedInactiveTabs_InitialState() {
        let subject = createSubject(isPrivateMode: false,
                                    emptyTabs: false,
                                    emptyInactiveTabs: false)
        XCTAssertTrue(subject.state.isInactiveTabsExpanded)
    }

    func testCollapsedInactiveTabs() {
        let subject = createSubject(isPrivateMode: false,
                                    emptyTabs: false,
                                    emptyInactiveTabs: false)
        subject.toggleInactiveTab()
        XCTAssertFalse(subject.state.isInactiveTabsExpanded)
    }

    // MARK: - Private
    private func createSubject(isPrivateMode: Bool,
                               emptyTabs: Bool,
                               emptyInactiveTabs: Bool,
                               file: StaticString = #file,
                               line: UInt = #line) -> TabDisplayView {
        let tabs: [String] = emptyTabs ? [String]() : ["Tab1", "Tab2"]
        let inactiveTabs: [String] = emptyInactiveTabs ? [String]() : ["Inactive1", "Inactive2"]
        let tatTrayState = TabTrayState(tabs: tabs,
                                        isPrivateMode: isPrivateMode,
                                        inactiveTabs: inactiveTabs)

        let subject = TabDisplayView(state: tatTrayState)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
