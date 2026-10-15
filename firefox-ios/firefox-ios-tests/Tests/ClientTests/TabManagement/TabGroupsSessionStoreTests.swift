// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TabGroupsSessionStoreTests: TabManagerTestsBase {
    @MainActor
    func testWindowsShareGroupsButKeepIndependentSelection() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let firstManager = createSubject(groupManager: groups)
        let secondManager = createSubject(windowUUID: UUID(), groupManager: groups)
        defer {
            TabGroupsSessionStore.removeController(for: firstManager.windowUUID)
            TabGroupsSessionStore.removeController(for: secondManager.windowUUID)
        }
        let first = TabGroupsSessionStore.controller(for: firstManager.windowUUID, tabManager: firstManager)
        let second = TabGroupsSessionStore.controller(for: secondManager.windowUUID, tabManager: secondManager)
        let id = try XCTUnwrap(first.createGroup(name: "Work", normalTabIDs: []))
        XCTAssertTrue(first === TabGroupsSessionStore.controller(for: firstManager.windowUUID))
        XCTAssertEqual(first.state.groups, second.state.groups)
        XCTAssertEqual(first.state.selectedGroupID, id)
        XCTAssertNil(second.state.selectedGroupID)
    }

    @MainActor
    func testRemovingWindowOnlyDiscardsSelection() async throws {
        let groups = TabGroupManager(storage: mockGroupStorage)
        try await groups.restore()
        let manager = createSubject(groupManager: groups)
        defer { TabGroupsSessionStore.removeController(for: manager.windowUUID) }
        let previous = TabGroupsSessionStore.controller(for: manager.windowUUID, tabManager: manager)
        let id = try XCTUnwrap(previous.createGroup(name: "Work", normalTabIDs: []))
        manager.prepareForWindowClose()
        TabGroupsSessionStore.removeController(for: manager.windowUUID)
        let replacement = TabGroupsSessionStore.controller(for: manager.windowUUID, tabManager: manager)
        XCTAssertFalse(previous === replacement)
        XCTAssertEqual(replacement.state.groups.map(\.id), [id])
        XCTAssertNil(replacement.state.selectedGroupID)
    }
}
