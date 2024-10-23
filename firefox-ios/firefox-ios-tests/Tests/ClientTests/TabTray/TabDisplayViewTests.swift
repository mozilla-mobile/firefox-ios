// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client
final class TabDisplayViewTests: XCTestCase {
    var tabDisplayView: TabDisplayView?
    var diffableDataSource: TabDisplayDiffableDataSource?

    override func tearDown() {
        diffableDataSource = nil
        tabDisplayView = nil
        super.tearDown()
    }

    // TODO: Add Tests Using Diffable Datasource

    func testNumberOfSections_ForRegularTabsWithInactiveTabs() {
        let subject = createSubject(isPrivateMode: false,
                                    numberInactiveTabs: 2,
                                    numberActiveTabs: 5)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 5)
    }

    func testNumberOfSections_ForRegularTabsWithoutInactiveTabs() {
        let subject = createSubject(isPrivateMode: false,
                                    numberInactiveTabs: 0,
                                    numberActiveTabs: 2)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 2)
    }

    func testNumberOfSections_PrivateTabsAndInactiveTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberInactiveTabs: 4,
                                    numberActiveTabs: 2)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 4)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 2)

//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: false)
//
//        let numberOfSections = subject.collectionView.numberOfSections
//        XCTAssertEqual(numberOfSections, 2)
    }

    func testNumberOfSections_PrivateTabsWithoutInactiveTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberInactiveTabs: 0,
                                    numberActiveTabs: 9)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 9)

//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: true)
//
//        let numberOfSections = subject.collectionView.numberOfSections
//        XCTAssertEqual(numberOfSections, 2)
    }

    func testNumberOfSections_PrivateTabsWithEmptyTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberInactiveTabs: 0,
                                    numberActiveTabs: 0)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 0)

//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: true,
//                                    emptyInactiveTabs: true)
//
//        let numberOfSections = subject.collectionView.numberOfSections
//        XCTAssertEqual(numberOfSections, 2)
    }

    func testAmountOfSections_ForPrivateTabsWithoutInactiveTabs() {
        let subject = createSubject(isPrivateMode: true,
                                    numberInactiveTabs: 0,
                                    numberActiveTabs: 4)

        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 0), 0)
        XCTAssertEqual(subject.collectionView.numberOfItems(inSection: 1), 4)

//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: true)
//
//        XCTAssertEqual(subject.collectionView.numberOfSections, 2)
    }

//    func testAmountOfSections_ForPrivateTabsWithInactiveTabs() {
//        let subject = createSubject(isPrivateMode: true,
//                                    emptyTabs: false,
//                                    emptyInactiveTabs: false)
//
//        XCTAssertEqual(subject.collectionView.numberOfSections, 1)
//    }

    // MARK: - Private
    private func createSubject(isPrivateMode: Bool,
                               numberInactiveTabs: Int,
                               numberActiveTabs: Int,
                               file: StaticString = #file,
                               line: UInt = #line) -> TabDisplayView {
        let tabs = createTabs(numberOfTabs: numberActiveTabs)

        let inactiveTabs = createInactiveTabs(numberOfTabs: numberInactiveTabs)
        let isInactiveTabsExpanded = !isPrivateMode && !inactiveTabs.isEmpty

        let tabState = TabsPanelState(windowUUID: .XCTestDefaultUUID,
                                      isPrivateMode: isPrivateMode,
                                      tabs: tabs,
                                      inactiveTabs: inactiveTabs,
                                      isInactiveTabsExpanded: isInactiveTabsExpanded)

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

    private func createInactiveTabs(numberOfTabs: Int) -> [InactiveTabsModel] {
        guard numberOfTabs != 0 else { return [InactiveTabsModel]() }

        var inactiveTabs = [InactiveTabsModel]()
        let tabUUID = "UUID"
        for index in 0..<numberOfTabs {
            let inactiveTabModel = InactiveTabsModel(id: tabUUID,
                                                     tabUUID: tabUUID,
                                                     title: "InactiveTab\(index)",
                                                     url: nil)
            inactiveTabs.append(inactiveTabModel)
        }
        return inactiveTabs
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
