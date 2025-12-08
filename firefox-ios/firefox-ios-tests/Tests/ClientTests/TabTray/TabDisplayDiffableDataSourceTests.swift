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

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 2)
    }

    func testNumberOfSections_PrivateTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberActiveTabs: 9)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 9)
    }

    func testNumberOfSections_PrivateTabsWithEmptyTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberActiveTabs: 0)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 0)
    }

    func testAmountOfSections_ForPrivateTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberActiveTabs: 4)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 4)
    }

    // MARK: - Private
    private func createSubject(isPrivateMode: Bool,
                               numberActiveTabs: Int,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabDisplayView {
        let tabs = createTabs(numberOfTabs: numberActiveTabs)
        let tabState = TabsPanelState(windowUUID: .XCTestDefaultUUID,
                                      isPrivateMode: isPrivateMode,
                                      tabs: tabs)

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
            let tabModel = TabModel.emptyState(tabUUID: "", title: "Tab \(index)")
            tabs.append(tabModel)
        }
        return tabs
    }
}
