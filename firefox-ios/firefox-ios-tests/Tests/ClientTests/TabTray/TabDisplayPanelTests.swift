// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client
final class TabDisplayPanelTests: XCTestCase, StoreTestUtility {
    private var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    // MARK: - Redux
    func testUnsubscribeFromRedux_unsubscribesFromStore() {
        let subject = createSubject(isPrivateMode: false, emptyTabs: true)

        subject.unsubscribeFromRedux()

        XCTAssertEqual(mockStore.unsubscribeCallCount, 1)
    }

    // MARK: - StoreTestUtility
    func setupAppState() -> Client.AppState {
        return AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }

    @MainActor
    func testIsPrivateTabsEmpty() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: true)

        XCTAssertTrue(subject.tabsState.isPrivateTabsEmpty)
    }

    @MainActor
    func testIsPrivateTabsNotEmpty() {
        let subject = createSubject(isPrivateMode: true,
                                    emptyTabs: false)

        XCTAssertFalse(subject.tabsState.isPrivateTabsEmpty)
    }

    // MARK: - Private
    @MainActor
    private func createSubject(isPrivateMode: Bool,
                               emptyTabs: Bool,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabDisplayPanelViewController {
        let subjectState = createSubjectState(isPrivateMode: isPrivateMode,
                                              emptyTabs: emptyTabs)
        let delegate = MockTabDisplayViewDragAndDropInteraction()
        let subject = TabDisplayPanelViewController(isPrivateMode: isPrivateMode,
                                                    windowUUID: .XCTestDefaultUUID,
                                                    dragAndDropDelegate: delegate)
        subject.newState(state: subjectState)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createSubjectState(isPrivateMode: Bool,
                                    emptyTabs: Bool) -> TabsPanelState {
        let tabs = createTabs(emptyTabs)
        return TabsPanelState(windowUUID: .XCTestDefaultUUID, isPrivateMode: isPrivateMode)
            .copy(tabs: tabs)
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
