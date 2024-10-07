// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import XCTest
import Common

@testable import Client
final class InactiveTabsManagerTests: XCTestCase {
    var profile: MockProfile!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    var twentyDaysOldTime: Date {
        let twentyDaysOld = Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date()
        return twentyDaysOld
    }

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

    func testEmptyInactiveTabs_ForRegularTabs() throws {
        let subject = createSubject()
        let tabs = createTabs(amountOfRegularTabs: 3)
        let inactiveTabs = subject.getInactiveTabs(tabs: tabs)
        XCTAssertEqual(inactiveTabs.count, 0)
    }

    func testEmptyInactiveTabs_ForPrivateTabs() throws {
        let subject = createSubject()
        let tabs = createTabs(amountOfPrivateTabs: 3)
        let inactiveTabs = subject.getInactiveTabs(tabs: tabs)
        XCTAssertEqual(inactiveTabs.count, 0)
    }

    func testEmptyInactiveTabs_ForRegularAndPrivateTabs() throws {
        let subject = createSubject()
        let tabs = createTabs(amountOfRegularTabs: 3,
                              amountOfPrivateTabs: 3)
        let inactiveTabs = subject.getInactiveTabs(tabs: tabs)
        XCTAssertEqual(inactiveTabs.count, 0)
    }

    func testGetInactiveTabs_WithInactiveTabs() throws {
        let subject = createSubject()
        let tabs = createTabs(amountOfRegularTabs: 3,
                              amountOfPrivateTabs: 3,
                              amountOfInactiveTabs: 3)
        let inactiveTabs = subject.getInactiveTabs(tabs: tabs)
        XCTAssertEqual(inactiveTabs.count, 3)
    }

    // MARK: - Private
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> InactiveTabsManager {
        let subject = InactiveTabsManager()
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createTabs(amountOfRegularTabs: Int = 0,
                            amountOfPrivateTabs: Int = 0,
                            amountOfInactiveTabs: Int = 0) -> [Tab] {
        var tabs = [Tab]()
        for _ in  0..<amountOfRegularTabs {
            let tab = Tab(profile: profile, windowUUID: windowUUID)
            tabs.append(tab)
        }

        for _ in  0..<amountOfPrivateTabs {
            let tab = Tab(profile: profile, isPrivate: true, windowUUID: windowUUID)
            tabs.append(tab)
        }

        for _ in 0..<amountOfInactiveTabs {
            let tab = Tab(profile: profile, windowUUID: windowUUID)
            if let lastExecutedDate = Calendar.current.add(numberOfDays: -15, to: Date()) {
                tab.lastExecutedTime = lastExecutedDate.toTimestamp()
            }
            tabs.append(tab)
        }

        return tabs
    }
}
