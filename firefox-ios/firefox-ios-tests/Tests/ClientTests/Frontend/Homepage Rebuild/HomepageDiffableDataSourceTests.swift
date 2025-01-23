// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage

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
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        diffableDataSource = nil
        collectionView = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // MARK: - applyInitialSnapshot
    func test_updateSnapshot_hasCorrectData() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        dataSource.updateSnapshot(state: HomepageState(windowUUID: .XCTestDefaultUUID))

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfSections, 3)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.header, .messageCard, .customizeHomepage])

        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .header).count, 1)
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
            PocketAction(
                pocketStories: createStories(),
                windowUUID: .XCTestDefaultUUID,
                actionType: PocketMiddlewareActionType.retrievedUpdatedStories
            )
        )

        let updatedState = HomepageState.reducer(
            state,
            WallpaperAction(
                wallpaperConfiguration: wallpaperConfig,
                windowUUID: .XCTestDefaultUUID,
                actionType: WallpaperMiddlewareActionType.wallpaperDidInitialize
            )
        )

        dataSource.updateSnapshot(state: updatedState)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .pocket(.systemCyan)), 21)
    }

    func test_updateSnapshot_withValidState_returnTopSites() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                topSites: createSites(),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        let updatedState = HomepageState.reducer(
            state,
            TopSitesAction(
                numberOfRows: 2,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfRows
            )
        )

        let finalState = HomepageState.reducer(
            updatedState,
            TopSitesAction(
                numberOfTilesPerRow: 4,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfTilesPerRow
            )
        )

        dataSource.updateSnapshot(state: finalState)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .topSites(4)), 8)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.header, .messageCard, .topSites(4), .customizeHomepage])
    }

    func test_updateSnapshot_withValidState_returnPocketStories() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            PocketAction(
                pocketStories: createStories(),
                windowUUID: .XCTestDefaultUUID,
                actionType: PocketMiddlewareActionType.retrievedUpdatedStories
            )
        )

        dataSource.updateSnapshot(state: state)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .pocket(nil)), 21)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.header, .messageCard, .pocket(nil), .customizeHomepage])
    }

    private func createSites(count: Int = 30) -> [TopSiteState] {
        var sites = [TopSiteState]()
        (0..<count).forEach {
            let site = Site.createBasicSite(
                url: "www.url\($0).com",
                title: "Title \($0)"
            )
            sites.append(TopSiteState(site: site))
        }
        return sites
    }

    private func createStories(count: Int = 20) -> [PocketStoryState] {
        var feedStories = [PocketFeedStory]()
        (0..<count).forEach {
            let story: PocketFeedStory = .make(title: "feed \($0)")
            feedStories.append(story)
        }

        let stories = feedStories.compactMap {
            PocketStoryState(story: PocketStory(pocketFeedStory: $0))
        }
        return stories
    }
}
