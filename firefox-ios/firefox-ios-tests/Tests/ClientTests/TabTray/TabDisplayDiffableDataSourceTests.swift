// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class TabDisplayDiffableDataSourceTests: XCTestCase {
    var diffableDataSource: TabDisplayDiffableDataSource?

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        diffableDataSource = nil
        try await super.tearDown()
    }

    func testNumberOfSections_ForRegularTabs() {
        let subject = createSubject(isPrivateMode: false,
                                    numberActiveTabs: 2)

        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 2)
    }

    func testNumberOfSections_PrivateTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberActiveTabs: 9)

        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 9)
    }

    func testNumberOfSections_PrivateTabsWithEmptyTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberActiveTabs: 0)

        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 0)
    }

    func testUpdateSnapshot_withChangedTabContent_stillResolvesAllItems() {
        let subject = createSubject(isPrivateMode: false, numberActiveTabs: 3)

        // Same UUID with changed content shares a hash with the original item
        // (TabModel hashes only its UUID), so diffing must rely on equality.
        var tabs = createTabs(numberOfTabs: 3)
        let updatedTab = TabModel.emptyState(tabUUID: "tab-1", title: "Updated Title")
        tabs[1] = updatedTab
        let updatedState = TabsPanelState(windowUUID: .XCTestDefaultUUID, isPrivateMode: false)
            .copy(tabs: tabs)

        diffableDataSource?.updateSnapshot(state: updatedState)

        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 3)
        XCTAssertNotNil(diffableDataSource?.indexPath(for: .tab(updatedTab)))
    }

    // MARK: - Private
    private func createSubject(isPrivateMode: Bool,
                               numberActiveTabs: Int,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabDisplayView {
        let tabs = createTabs(numberOfTabs: numberActiveTabs)
        let tabState = TabsPanelState(windowUUID: .XCTestDefaultUUID, isPrivateMode: isPrivateMode)
            .copy(tabs: tabs)

        let subject = TabDisplayView(panelType: isPrivateMode ? .privateTabs : .tabs,
                                     state: tabState,
                                     windowUUID: .XCTestDefaultUUID)

        let tabCollectionView = subject.collectionView

        diffableDataSource = TabDisplayDiffableDataSource(
            collectionView: tabCollectionView
        ) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return UICollectionViewCell()
        }

        diffableDataSource?.updateSnapshot(state: tabState)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createTabs(numberOfTabs: Int) -> [TabModel] {
        guard numberOfTabs != 0 else { return [TabModel]() }

        var tabs = [TabModel]()
        for index in 0..<numberOfTabs {
            let tabModel = TabModel.emptyState(tabUUID: "tab-\(index)", title: "Tab \(index)")
            tabs.append(tabModel)
        }
        return tabs
    }
}
