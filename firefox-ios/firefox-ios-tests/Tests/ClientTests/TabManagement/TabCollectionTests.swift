// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
final class TabCollectionTests: XCTestCase {
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
    }

    override func tearDown() async throws {
        profile = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testEmptyCollectionHasNoGroups() {
        let subject = TabCollection()

        XCTAssertTrue(subject.tabs.isEmpty)
        XCTAssertTrue(subject.groups.isEmpty)
        XCTAssertTrue(subject.normalTabs.isEmpty)
        XCTAssertTrue(subject.tabs(in: .private).isEmpty)
        XCTAssertTrue(subject.tabs(in: .custom(UUID())).isEmpty)
    }

    func testGroupsSeparateCustomIDsAndPreserveTabOrder() {
        let firstGroup = TabGroupMembership.custom(UUID())
        let secondGroup = TabGroupMembership.custom(UUID())
        let normal = makeTab()
        let first = makeTab(group: firstGroup)
        let privateTab = makeTab(group: .private)
        let second = makeTab(group: secondGroup)
        let third = makeTab(group: firstGroup)
        let tabs = [first, normal, privateTab, second, third]
        let subject = TabCollection(tabs: tabs)

        XCTAssertEqual(subject.tabs, tabs)
        XCTAssertEqual(subject.groups.count, 4)
        XCTAssertEqual(subject.tabs(in: .normal), [normal])
        XCTAssertEqual(subject.tabs(in: .private), [privateTab])
        XCTAssertEqual(subject.tabs(in: firstGroup), [first, third])
        XCTAssertEqual(subject.tabs(in: secondGroup), [second])
        XCTAssertEqual(subject.normalTabs, [first, normal, second, third])
    }

    func testAppendingTabRefreshesGroups() {
        let normal = makeTab()
        let subject = TabCollection(tabs: [normal])
        XCTAssertEqual(subject.tabs(in: .normal), [normal])
        let privateTab = makeTab(group: .private)
        let custom = makeTab(group: .custom(UUID()))

        subject.tabs.append(contentsOf: [privateTab, custom])

        XCTAssertEqual(subject.tabs(in: .private), [privateTab])
        XCTAssertEqual(subject.tabs(in: custom.group), [custom])
        XCTAssertEqual(subject.normalTabs, [normal, custom])
    }

    func testRemovingLastGroupMemberRemovesCachedGroup() {
        let custom = makeTab(group: .custom(UUID()))
        let normal = makeTab()
        let subject = TabCollection(tabs: [custom, normal])
        XCTAssertEqual(subject.tabs(in: custom.group), [custom])

        subject.tabs.removeFirst()

        XCTAssertNil(subject.groups[custom.group])
        XCTAssertTrue(subject.tabs(in: custom.group).isEmpty)
        XCTAssertEqual(subject.normalTabs, [normal])
    }

    func testReorderingTabsRefreshesGroupAndNormalOrder() {
        let group = TabGroupMembership.custom(UUID())
        let first = makeTab(group: group)
        let normal = makeTab()
        let second = makeTab(group: group)
        let subject = TabCollection(tabs: [first, normal, second])
        XCTAssertEqual(subject.tabs(in: group), [first, second])

        subject.tabs.swapAt(0, 2)

        XCTAssertEqual(subject.tabs(in: group), [second, first])
        XCTAssertEqual(subject.normalTabs, [second, normal, first])
    }

    func testReplacingTabsRefreshesAllGroups() {
        let normal = makeTab()
        let subject = TabCollection(tabs: [normal])
        XCTAssertEqual(subject.normalTabs, [normal])
        let privateTab = makeTab(group: .private)

        subject.tabs = [privateTab]

        XCTAssertNil(subject.groups[.normal])
        XCTAssertTrue(subject.normalTabs.isEmpty)
        XCTAssertEqual(subject.tabs(in: .private), [privateTab])

        subject.tabs.removeAll()

        XCTAssertTrue(subject.groups.isEmpty)
        XCTAssertTrue(subject.tabs(in: .private).isEmpty)
    }

    private func makeTab(group: TabGroupMembership = .normal) -> Tab {
        Tab(profile: profile, group: group, windowUUID: .XCTestDefaultUUID)
    }
}
