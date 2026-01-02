// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import MozillaAppServices

@testable import Client

@MainActor
final class HomepageDiffableDataSourceTests: XCTestCase {
    var collectionView: UICollectionView?
    var diffableDataSource: HomepageDiffableDataSource?

    override func setUp() async throws {
        try await super.setUp()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let collectionView = try XCTUnwrap(collectionView)
        diffableDataSource = HomepageDiffableDataSource(
            collectionView: collectionView
        ) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return UICollectionViewCell()
        }
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() async throws {
        diffableDataSource = nil
        collectionView = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - applyInitialSnapshot
    func test_updateSnapshot_hasCorrectData() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
        let dataSource = try XCTUnwrap(diffableDataSource)

        dataSource.updateSnapshot(
            state: HomepageState(windowUUID: .XCTestDefaultUUID),
            jumpBackInDisplayConfig: mockSectionConfig
        )

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfSections, 1)
        let expectedSections: [HomepageSection] = [
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .customizeHomepage).count, 1)
    }

    @MainActor
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
            MerinoAction(
                merinoStories: createStories(),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
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

        dataSource.updateSnapshot(
            state: updatedState,
            jumpBackInDisplayConfig: mockSectionConfig
        )

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .pocket(.systemCyan)), 20)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnTopSites() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
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

        dataSource.updateSnapshot(state: updatedState, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .topSites(nil, 4)), 8)
        let expectedSections: [HomepageSection] = [
            .topSites(nil, 4),
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnPocketStories() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            MerinoAction(
                merinoStories: createStories(),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .pocket(nil)), 20)
        let expectedSections: [HomepageSection] = [
            .pocket(nil),
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnMessageCard() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
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

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .messageCard), 1)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .messageCard).first, HomepageItem.messageCard(configuration))
        let expectedSections: [HomepageSection] = [
            .messageCard,
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnBookmarks() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
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

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .bookmarks(nil)), 1)
        let expectedSections: [HomepageSection] = [
            .bookmarks(nil),
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnJumpBackInSection() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TabManagerAction(
                recentTabs: [createTab(urlString: "www.mozilla.org")],
                windowUUID: .XCTestDefaultUUID,
                actionType: TabManagerMiddlewareActionType.fetchedRecentTabs
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .jumpBackIn(nil, mockSectionConfig)), 1)
        let expectedSections: [HomepageSection] = [
            .jumpBackIn(nil, mockSectionConfig),
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    func test_customizationSectionShown_returnsExpectedSections() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)

        let dataSource = try XCTUnwrap(diffableDataSource)
        let state = HomepageState(windowUUID: .XCTestDefaultUUID)
        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)
        let snapshot = dataSource.snapshot()
        let expectedSections: [HomepageSection] = [
            .customizeHomepage
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    func test_customizationSectionHidden_returnsExpectedSections() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: true)

        let dataSource = try XCTUnwrap(diffableDataSource)
        let state = HomepageState(windowUUID: .XCTestDefaultUUID)
        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)
        let snapshot = dataSource.snapshot()
        let expectedSections: [HomepageSection] = []
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnsPrivacyNoticeSection() throws {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            HomepageAction(
                shouldShowPrivacyNotice: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)
        let snapshot = dataSource.snapshot()
        let expectedSections: [HomepageSection] = [.privacyNotice, .customizeHomepage]
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

    private func createStories(count: Int = 20) -> [MerinoStoryConfiguration] {
        var feedStories = [RecommendationDataItem]()
        (0..<count).forEach {
            let story: RecommendationDataItem = .makeItem("feed \($0)")
            feedStories.append(story)
        }

        let stories = feedStories.compactMap {
            MerinoStoryConfiguration(story: MerinoStory(from: $0))
        }
        return stories
    }

    private var mockSectionConfig: JumpBackInSectionLayoutConfiguration {
        return JumpBackInSectionLayoutConfiguration(
            maxLocalTabsWhenSyncedTabExists: 1,
            maxLocalTabsWhenNoSyncedTab: 2,
            layoutType: .compact,
            hasSyncedTab: false
        )
    }

    @MainActor
    private func createTab(urlString: String) -> Tab {
        let tab = Tab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: urlString)!
        return tab
    }

    private func setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: Bool) {
        if !storiesRedesignEnabled {
            FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
                return HomepageRedesignFeature(
                    storiesRedesign: false,
                    storiesRedesignV2: false
                )
            }
        } else {
            FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
                return HomepageRedesignFeature(
                    storiesRedesign: true
                )
            }
        }
    }
}
