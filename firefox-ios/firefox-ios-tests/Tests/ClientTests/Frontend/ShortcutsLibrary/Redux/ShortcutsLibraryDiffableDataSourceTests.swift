// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage

@testable import Client

@MainActor
final class ShortcutsLibraryDiffableDataSourceTests: XCTestCase {
    var collectionView: UICollectionView?
    var diffableDataSource: ShortcutsLibraryDiffableDataSource?

    override func setUp() async throws {
        try await super.setUp()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let collectionView = try XCTUnwrap(collectionView)
        diffableDataSource = ShortcutsLibraryDiffableDataSource(
            collectionView: collectionView
        ) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return UICollectionViewCell()
        }
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        diffableDataSource = nil
        collectionView = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_updateSnapshot_initialSnapshotHasNoData() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        dataSource.updateSnapshot(state: ShortcutsLibraryState(windowUUID: .XCTestDefaultUUID))

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfSections, 0)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnsShortcuts() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = ShortcutsLibraryState.reducer(
            ShortcutsLibraryState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                topSites: createSites(count: 10),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        dataSource.updateSnapshot(state: state)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .shortcuts), 10)
        let expectedSections: [ShortcutsLibraryDiffableDataSource.Section] = [.shortcuts]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnsMaxShortcuts() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = ShortcutsLibraryState.reducer(
            ShortcutsLibraryState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                topSites: createSites(count: 20),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        dataSource.updateSnapshot(state: state)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .shortcuts), 16)
        let expectedSections: [ShortcutsLibraryDiffableDataSource.Section] = [.shortcuts]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    private func createSites(count: Int) -> [TopSiteConfiguration] {
        var sites = [TopSiteConfiguration]()
        (0..<count).forEach {
            let site = Site.createBasicSite(
                url: "www.url\($0).com",
                title: "Title \($0)"
            )
            sites.append(TopSiteConfiguration(site: site))
        }
        return sites
    }
}
