// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class HomepageDiffableDataSourceTests: XCTestCase {
    var collectionView: UICollectionView?
    var diffableDataSource: HomepageDiffableDataSource?

    override func setUpWithError() throws {
        try super.setUpWithError()

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let collectionView = try XCTUnwrap(collectionView)
        diffableDataSource = HomepageDiffableDataSource(
            collectionView: collectionView
        ) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return UICollectionViewCell()
        }
    }

    override func tearDown() {
        diffableDataSource = nil
        collectionView = nil
        super.tearDown()
    }

    // MARK: - applyInitialSnapshot
    func test_updateSnapshot_hasCorrectData() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        dataSource.updateSnapshot(state: HomepageState(windowUUID: .XCTestDefaultUUID))

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfSections, 4)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.header, .topSites, .pocket(nil), .customizeHomepage])

        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .header).count, 1)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .pocket(nil)).count, 1)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .customizeHomepage).count, 1)
    }

    func test_updateSnapshot_withColorValueOnState() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)
        let wallpaperConfig = WallpaperConfiguration(
            landscapeImage: nil,
            portraitImage: nil,
            textColor: .systemCyan,
            cardColor: .black,
            logoTextColor: .blue
        )

        let state = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            WallpaperAction(
                wallpaperConfiguration: wallpaperConfig,
                windowUUID: .XCTestDefaultUUID,
                actionType: WallpaperMiddlewareActionType.wallpaperDidInitialize
            )
        )

        dataSource.updateSnapshot(state: state)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .pocket(.systemCyan)), 1)
    }
}
