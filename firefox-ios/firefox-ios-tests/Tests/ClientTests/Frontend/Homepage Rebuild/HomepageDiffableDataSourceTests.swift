// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import MozillaAppServices

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

        dataSource.updateSnapshot(state: HomepageState(windowUUID: .XCTestDefaultUUID), numberOfCellsPerRow: 4)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfSections, 3)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.header, .jumpBackIn(nil), .customizeHomepage])

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

        dataSource.updateSnapshot(state: updatedState, numberOfCellsPerRow: 4)

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

        dataSource.updateSnapshot(state: updatedState, numberOfCellsPerRow: 4)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .topSites(4)), 8)
        let expectedSections: [HomepageSection] = [
            .header,
            .topSites(4),
            .jumpBackIn(nil),
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
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

        dataSource.updateSnapshot(state: state, numberOfCellsPerRow: 4)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .pocket(nil)), 21)
        let expectedSections: [HomepageSection] = [
            .header,
            .jumpBackIn(nil),
            .pocket(nil),
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    func test_updateSnapshot_withValidState_returnMessageCard() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)
        let configuration = MessageCardConfiguration(
            title: "Example Title",
            description: "Example Description",
            buttonLabel: "Example Button"
        )

        let state = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            MessageCardAction(
                messageCardConfiguration: configuration,
                windowUUID: .XCTestDefaultUUID,
                actionType: MessageCardMiddlewareActionType.initialize
            )
        )

        dataSource.updateSnapshot(state: state, numberOfCellsPerRow: 4)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .messageCard), 1)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .messageCard).first, HomepageItem.messageCard(configuration))
        let expectedSections: [HomepageSection] = [
            .header,
            .messageCard,
            .jumpBackIn(nil),
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    func test_updateSnapshot_withValidState_returnBookmarks() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            BookmarksAction(
                bookmarks: [BookmarkConfiguration(
                    site: Site.createBasicSite(
                        url: "www.mozilla.org",
                        title: "Title 1",
                        isBookmarked: true
                    )
                )],
                windowUUID: .XCTestDefaultUUID,
                actionType: BookmarksMiddlewareActionType.initialize
            )
        )

        dataSource.updateSnapshot(state: state, numberOfCellsPerRow: 4)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .bookmarks(nil)), 1)
        let expectedSections: [HomepageSection] = [
            .header,
            .jumpBackIn(nil),
            .bookmarks(nil),
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    private func createSites(count: Int = 30) -> [TopSiteConfiguration] {
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

    private func createStories(count: Int = 20) -> [PocketStoryConfiguration] {
        var feedStories = [PocketFeedStory]()
        (0..<count).forEach {
            let story: PocketFeedStory = .make(title: "feed \($0)")
            feedStories.append(story)
        }

        let stories = feedStories.compactMap {
            PocketStoryConfiguration(story: PocketStory(pocketFeedStory: $0))
        }
        return stories
    }
}
