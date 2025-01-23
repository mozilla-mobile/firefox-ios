// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client
final class TabDisplayPanelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testExpandedInactiveTabs_InitialState() {
        let subject = createSubject(isPrivateMode: false,
                                    emptyTabs: false,
                                    emptyInactiveTabs: false)

        XCTAssertTrue(subject.tabsState.isInactiveTabsExpanded)
    }

    func testIsPrivateTabsEmpty() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: true,
                                    emptyInactiveTabs: true)

        XCTAssertTrue(subject.tabsState.isPrivateTabsEmpty)
    }

    func testIsPrivateTabsNotEmpty() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: false,
                                    emptyInactiveTabs: true)

        XCTAssertFalse(subject.tabsState.isPrivateTabsEmpty)
    }

    // MARK: - Private
    private func createSubject(isPrivateMode: Bool,
                               emptyTabs: Bool,
                               emptyInactiveTabs: Bool,
                               file: StaticString = #file,
                               line: UInt = #line) -> TabDisplayPanelViewController {
        let subjectState = createSubjectState(isPrivateMode: isPrivateMode,
                                              emptyTabs: emptyTabs,
                                              emptyInactiveTabs: emptyInactiveTabs)
        let subject = TabDisplayPanelViewController(isPrivateMode: isPrivateMode, windowUUID: .XCTestDefaultUUID)
        subject.newState(state: subjectState)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createSubjectState(isPrivateMode: Bool,
                                    emptyTabs: Bool,
                                    emptyInactiveTabs: Bool) -> TabsPanelState {
        let tabs = createTabs(emptyTabs)
        var inactiveTabs = [InactiveTabsModel]()
        if !emptyInactiveTabs {
            let uuid = "UUID"
            for index in 0...2 {
                let inactiveTabModel = InactiveTabsModel(tabUUID: uuid,
                                                         title: "InactiveTab\(index)",
                                                         url: nil)
                inactiveTabs.append(inactiveTabModel)
            }
        }
        let isInactiveTabsExpanded = !isPrivateMode && !inactiveTabs.isEmpty
        return TabsPanelState(windowUUID: .XCTestDefaultUUID,
                              isPrivateMode: isPrivateMode,
                              tabs: tabs,
                              inactiveTabs: inactiveTabs,
                              isInactiveTabsExpanded: isInactiveTabsExpanded)
    }

    private func createTabs(_ emptyTabs: Bool) -> [TabModel] {
        guard !emptyTabs else { return [TabModel]() }

        var tabs = [TabModel]()
        for index in 0...2 {
            let tabModel = TabModel.emptyState(tabUUID: "UUID", title: "Tab \(index)")
            tabs.append(tabModel)
        }
        return tabs
    }
}
