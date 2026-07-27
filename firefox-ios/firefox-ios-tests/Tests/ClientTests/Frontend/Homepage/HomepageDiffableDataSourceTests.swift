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
    private var profile: MockProfile!
    private var mockNimbusLayer: MockNimbusFeatureFlagLayer!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        mockNimbusLayer = MockNimbusFeatureFlagLayer()
        let featureFlagProvider = FeatureFlagsProvider(prefs: profile.prefs, backendLayer: mockNimbusLayer)
        let userFeaturePreferences = UserFeaturePreferenceManager(prefs: profile.prefs, backendLayer: mockNimbusLayer)

        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: profile,
            injectedFeatureFlagProvider: featureFlagProvider,
            injectedUserFeaturePreferences: userFeaturePreferences
        )

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let collectionView = try XCTUnwrap(collectionView)
        diffableDataSource = HomepageDiffableDataSource(
            collectionView: collectionView
        ) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return UICollectionViewCell()
        }
    }

    override func tearDown() async throws {
        diffableDataSource = nil
        collectionView = nil
        profile = nil
        mockNimbusLayer = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - applyInitialSnapshot
    func test_updateSnapshot_hasCorrectData() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        dataSource.updateSnapshot(
            state: HomepageState(windowUUID: .XCTestDefaultUUID),
            jumpBackInDisplayConfig: mockSectionConfig
        )

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfSections, 2)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.header, .spacer])
        XCTAssertEqual(snapshot.numberOfItems(inSection: .header), 1)
        XCTAssertEqual(snapshot.numberOfItems(inSection: .spacer), 1)
    }

    @MainActor
    func test_updateSnapshot_withWorldCupSectionEnabled_includesWorldCupSection() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: true
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfSections, 3)
        XCTAssertEqual(snapshot.sectionIdentifiers, [.header, .worldcup, .spacer])
        XCTAssertEqual(snapshot.numberOfItems(inSection: .header), 1)
        XCTAssertEqual(snapshot.numberOfItems(inSection: .worldcup), 1)
        XCTAssertEqual(snapshot.numberOfItems(inSection: .spacer), 1)
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

        let state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(stories: createStories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        let updatedState = HomepageState.reducer.legacyReducer(
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
        XCTAssertEqual(
            snapshot.itemIdentifiers(inSection: .header).first,
            HomepageItem.header(updatedState.headerState, .blue, false)
        )
        XCTAssertEqual(snapshot.numberOfItems(inSection: .pocket(.systemCyan)), 20)
        let expectedSections: [HomepageSection] = [
            .header,
            .spacer,
            .pocket(.systemCyan)
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withOverflowingTopSites_returnTopSitesWithHeader() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                topSites: createSites(),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        let updatedState = HomepageState.reducer.legacyReducer(
            state,
            TopSitesAction(
                numberOfRows: 2,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfRows
            )
        )

        dataSource.updateSnapshot(state: updatedState, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        let numberOfTilesPerRow = updatedState.topSitesState.numberOfTilesPerRow
        let displayedTopSitesCount = updatedState.topSitesState.numberOfRows * numberOfTilesPerRow
        XCTAssertEqual(snapshot.numberOfItems(inSection: .topSites(nil, numberOfTilesPerRow, true)), displayedTopSitesCount)
        let expectedSections: [HomepageSection] = [
            .header,
            .topSites(nil, numberOfTilesPerRow, true),
            .spacer
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withTopSitesWithinVisibleCount_returnTopSitesWithoutHeader() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)
        let numberOfRows = 2

        let stateWithRows = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                numberOfRows: numberOfRows,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfRows
            )
        )
        let topSitesCount = numberOfRows * stateWithRows.topSitesState.numberOfTilesPerRow

        let updatedState = HomepageState.reducer.legacyReducer(
            stateWithRows,
            TopSitesAction(
                topSites: createSites(count: topSitesCount),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        dataSource.updateSnapshot(state: updatedState, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        let numberOfTilesPerRow = updatedState.topSitesState.numberOfTilesPerRow
        XCTAssertEqual(snapshot.numberOfItems(inSection: .topSites(nil, numberOfTilesPerRow, false)), topSitesCount)
        let expectedSections: [HomepageSection] = [
            .header,
            .topSites(nil, numberOfTilesPerRow, false),
            .spacer
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withAddShortcutTileFlagEnabled_appendsTileWhenThereIsRoom() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let stateWithRows = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                numberOfRows: 1,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfRows
            )
        )
        let numberOfTilesPerRow = stateWithRows.topSitesState.numberOfTilesPerRow

        let updatedState = HomepageState.reducer.legacyReducer(
            stateWithRows,
            TopSitesAction(
                topSites: createSites(count: numberOfTilesPerRow - 1),
                shouldShowAddShortcutTile: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        dataSource.updateSnapshot(state: updatedState, jumpBackInDisplayConfig: mockSectionConfig)

        let section = HomepageSection.topSites(nil, numberOfTilesPerRow, false)
        let items = dataSource.snapshot().itemIdentifiers(inSection: section)
        XCTAssertEqual(items.count, numberOfTilesPerRow)
        let expectedTopSiteTitles = (0..<max(numberOfTilesPerRow - 1, 0)).map { "Title \($0)" }
        XCTAssertEqual(topSiteTitles(from: items), expectedTopSiteTitles)
        guard case .addShortcutTile = items.last else {
            return XCTFail("Expected Add Shortcut tile to be the last shortcut item")
        }
    }

    @MainActor
    func test_updateSnapshot_withAddShortcutTileFlagEnabled_displacesTileWhenShortcutsFillVisibleSlots() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let stateWithRows = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                numberOfRows: 1,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfRows
            )
        )
        let numberOfTilesPerRow = stateWithRows.topSitesState.numberOfTilesPerRow

        let updatedState = HomepageState.reducer.legacyReducer(
            stateWithRows,
            TopSitesAction(
                topSites: createSites(count: numberOfTilesPerRow),
                shouldShowAddShortcutTile: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        dataSource.updateSnapshot(state: updatedState, jumpBackInDisplayConfig: mockSectionConfig)

        let section = HomepageSection.topSites(nil, numberOfTilesPerRow, true)
        let items = dataSource.snapshot().itemIdentifiers(inSection: section)
        XCTAssertEqual(items.count, numberOfTilesPerRow)
        XCTAssertEqual(topSiteTitles(from: items), (0..<numberOfTilesPerRow).map { "Title \($0)" })
        XCTAssertFalse(items.contains { item in
            guard case .addShortcutTile = item else { return false }
            return true
        })
    }

    @MainActor
    func test_updateSnapshot_withAddShortcutTileFlagEnabledAndNoTopSites_showsAddShortcutTile() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        var state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                topSites: [],
                shouldShowAddShortcutTile: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )
        state = HomepageState.reducer.legacyReducer(
            state,
            TopSitesAction(
                numberOfRows: 1,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfRows
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let section = HomepageSection.topSites(nil, state.topSitesState.numberOfTilesPerRow, false)
        let items = dataSource.snapshot().itemIdentifiers(inSection: section)
        XCTAssertEqual(items.count, 1)
        guard case .addShortcutTile = items.first else {
            return XCTFail("Expected Add Shortcut tile to be the only shortcut item")
        }
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnPocketStories() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(stories: createStories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .pocket(nil)), 20)
        let expectedSections: [HomepageSection] = [
            .header,
            .spacer,
            .pocket(nil)
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withCategorizedStoriesAndNoSelection_returnsFlattenedStories() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: createCategories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        let items = snapshot.itemIdentifiers(inSection: .pocket(nil))

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(merinoTitles(from: items), ["science 1", "science 2", "technology 1"])
    }

    @MainActor
    func test_updateSnapshot_withCategorizedStoriesAndSelectedCategory_returnsSelectedCategoryStories() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let categorizedState = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: createCategories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        dataSource.updateSnapshot(
            state: categorizedState,
            selectedNewsfeedCategoryID: "technology",
            jumpBackInDisplayConfig: mockSectionConfig
        )

        let snapshot = dataSource.snapshot()
        let items = snapshot.itemIdentifiers(inSection: .pocket(nil))

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(merinoTitles(from: items), ["technology 1"])
    }

    @MainActor
    func test_updateSnapshot_withCategorizedStoriesAndMissingSelectedCategory_omitsPocketSection() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let categorizedState = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: createCategories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        dataSource.updateSnapshot(
            state: categorizedState,
            selectedNewsfeedCategoryID: "missing-category",
            jumpBackInDisplayConfig: mockSectionConfig
        )

        let snapshot = dataSource.snapshot()

        XCTAssertFalse(snapshot.sectionIdentifiers.contains(.pocket(nil)))
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnMessageCard() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)
        let configuration = MessageCardConfiguration(
            title: "Example Title",
            description: "Example Description",
            buttonLabel: "Example Button"
        )

        let state = HomepageState.reducer.legacyReducer(
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
            .header,
            .messageCard,
            .spacer
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnBookmarks() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        var state = HomepageState.reducer.legacyReducer(
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

        // Enable the bookmarks section of the homepage since it's off by default
        state = HomepageState.reducer.legacyReducer(
            state,
            BookmarksAction(isEnabled: true,
                            windowUUID: .XCTestDefaultUUID,
                            actionType: BookmarksActionType.toggleShowSectionSetting)
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .bookmarks(nil)), 1)
        let expectedSections: [HomepageSection] = [
            .header,
            .bookmarks(nil),
            .spacer
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnJumpBackInSection() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        var state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TabManagerAction(
                recentTabs: [createTab(urlString: "www.mozilla.org")],
                windowUUID: .XCTestDefaultUUID,
                actionType: TabManagerMiddlewareActionType.fetchedRecentTabs
            )
        )

        // Enable the bookmarks section of the homepage since it's off by default
        state = HomepageState.reducer.legacyReducer(
            state,
            JumpBackInAction(isEnabled: true,
                             windowUUID: .XCTestDefaultUUID,
                             actionType: JumpBackInActionType.toggleShowSectionSetting)
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .jumpBackIn(nil, mockSectionConfig)), 1)
        let expectedSections: [HomepageSection] = [
            .header,
            .jumpBackIn(nil, mockSectionConfig),
            .spacer
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withTrackerBlockerModuleEnabled_returnTrackerBlockerModuleSection() throws {
        setFeatureFlag(.homepageTrackerBlockerModule, isEnabled: true)
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TrackerBlockerModuleAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: TrackerBlockerModuleActionType.toggleShowSectionSetting
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .trackerBlockerModule), 1)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .trackerBlockerModule).first, .trackerBlockerModule(0))
        let expectedSections: [HomepageSection] = [
            .header,
            .trackerBlockerModule,
            .spacer
        ]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withShortcutsWorldCupTrackerBlockerAndJumpBackIn_ordersTrackerBlockerAfterWorldCup() throws {
        setFeatureFlag(.homepageTrackerBlockerModule, isEnabled: true)
        let dataSource = try XCTUnwrap(diffableDataSource)

        var state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            TopSitesAction(
                topSites: createSites(),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )
        state = HomepageState.reducer.legacyReducer(
            state,
            TrackerBlockerModuleAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: TrackerBlockerModuleActionType.toggleShowSectionSetting
            )
        )
        state = HomepageState.reducer.legacyReducer(
            state,
            TabManagerAction(
                recentTabs: [createTab(urlString: "www.mozilla.org")],
                windowUUID: .XCTestDefaultUUID,
                actionType: TabManagerMiddlewareActionType.fetchedRecentTabs
            )
        )
        state = HomepageState.reducer.legacyReducer(
            state,
            JumpBackInAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: JumpBackInActionType.toggleShowSectionSetting
            )
        )
        state = HomepageState.reducer.legacyReducer(
            state,
            WorldCupAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: true
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)

        let expectedSections: [HomepageSection] = [
            .header,
            .topSites(nil, state.topSitesState.numberOfTilesPerRow, true),
            .worldcup,
            .trackerBlockerModule,
            .jumpBackIn(nil, mockSectionConfig),
            .spacer
        ]
        XCTAssertEqual(dataSource.snapshot().sectionIdentifiers, expectedSections)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnsPrivacyNoticeSection() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = HomepageState.reducer.legacyReducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
            )
        )

        dataSource.updateSnapshot(state: state, jumpBackInDisplayConfig: mockSectionConfig)
        let snapshot = dataSource.snapshot()
        let expectedSections: [HomepageSection] = [
            .header,
            .privacyNotice,
            .spacer
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

    private func createCategories() -> [MerinoCategoryConfiguration] {
        [
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "technology",
                    recommendations: [createStory(title: "technology 1")],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Technology",
                    subtitle: nil,
                    receivedFeedRank: 2
                )
            ),
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "science",
                    recommendations: [createStory(title: "science 1"), createStory(title: "science 2")],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Science",
                    subtitle: nil,
                    receivedFeedRank: 1
                )
            ),
        ]
    }

    private func createStory(title: String) -> MerinoStoryConfiguration {
        return MerinoStoryConfiguration(story: MerinoStory(from: .makeItem(title)))
    }

    private func merinoTitles(from items: [HomepageItem]) -> [String] {
        items.compactMap {
            guard case .merino(let story, _) = $0 else { return nil }
            return story.title
        }
    }

    private func topSiteTitles(from items: [HomepageItem]) -> [String] {
        items.compactMap {
            guard case .topSite(let topSite, _) = $0 else { return nil }
            return topSite.title
        }
    }

    private var mockSectionConfig: JumpBackInSectionLayoutConfiguration {
        return JumpBackInSectionLayoutConfiguration(
            maxLocalTabsWhenSyncedTabExists: 1,
            maxLocalTabsWhenNoSyncedTab: 2,
            layoutType: .compact,
            hasSyncedTab: false
        )
    }

    private func setFeatureFlag(_ flag: FeatureFlagID, isEnabled: Bool) {
        if isEnabled {
            mockNimbusLayer.enabledFlags.insert(flag)
        } else {
            mockNimbusLayer.enabledFlags.remove(flag)
        }
    }

    @MainActor
    private func createTab(urlString: String) -> Tab {
        let tab = Tab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: urlString)!
        return tab
    }
}
