// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import UIKit
import XCTest

@testable import Client

final class MerinoStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.merinoData.stories, nil)
        XCTAssertEqual(MerinoState.Constants.sectionHeaderConfiguration.isButtonHidden, true)
    }

    @MainActor
    func test_retrievedUpdatedStoriesAction_sortsStoriesByRank() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()
        let stories = [
            createStoryConfiguration(title: "feed2", rank: 2),
            createStoryConfiguration(title: "feed0", rank: 0),
            createStoryConfiguration(title: "feed1", rank: 1),
        ]

        let newState = reducer(
            initialState,
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(stories: stories),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.merinoData.stories?.count, 3)
        XCTAssertEqual(
            newState.merinoData.stories?.compactMap { $0.title },
            ["feed0", "feed1", "feed2"]
        )
    }

    @MainActor
    func test_toggleShowSectionSetting_withToggleOn_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let newState = reducer(
            initialState,
            MerinoAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldShowSection)
    }

    @MainActor
    func test_toggleShowSectionSetting_withToggleOff_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let newState = reducer(
            initialState,
            MerinoAction(
                isEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.shouldShowSection)
    }

    @MainActor
    func test_retrievedUpdatedStoriesAction_sortsCategoriesAndRecommendationsByRank() {
        let categories = [
            createCategory(
                feedID: "technology",
                title: "Technology",
                rank: 2,
                recommendations: [
                    createStoryConfiguration(title: "technology1", rank: 1),
                    createStoryConfiguration(title: "technology0", rank: 0),
                ]
            ),
            createCategory(
                feedID: "science",
                title: "Science",
                rank: 1,
                recommendations: [
                    createStoryConfiguration(title: "science2", rank: 2),
                    createStoryConfiguration(title: "science0", rank: 0),
                    createStoryConfiguration(title: "science1", rank: 1),
                ]
            ),
        ]
        let state = pocketReducer()(
            createSubject(),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: categories),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertEqual(state.merinoData.categories?.map(\.feedID), ["science", "technology"])
        XCTAssertEqual(state.availableCategories.map(\.feedID), ["science", "technology"])
        XCTAssertEqual(
            state.merinoData.categories?.first?.recommendations.map(\.title),
            ["science0", "science1", "science2"]
        )
        XCTAssertEqual(
            state.merinoData.categories?.last?.recommendations.map(\.title),
            ["technology0", "technology1"]
        )
    }

    @MainActor
    func test_availableCategories_filtersCategoriesWithoutRecommendations() {
        let categories = createTestCategories() + [
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "empty",
                    recommendations: [],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Empty",
                    subtitle: nil,
                    receivedFeedRank: 0
                )
            ),
        ]
        let state = pocketReducer()(
            createSubject(),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: categories),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertEqual(state.availableCategories.map(\.feedID), ["science", "technology"])
    }

    @MainActor
    func test_visibleStories_withNoSelectedCategory_flattensAllCategoryRecommendations() {
        let state = pocketReducer()(
            createSubject(),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: createTestCategories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertEqual(
            state.visibleStories(selectedNewsfeedCategoryID: nil).map(\.title),
            ["science1", "science2", "technology1"]
        )
    }

    @MainActor
    func test_visibleStories_withSelectedCategory_returnsOnlySelectedCategoryStories() {
        let state = pocketReducer()(
            createSubject(),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: createTestCategories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertEqual(
            state.visibleStories(selectedNewsfeedCategoryID: "technology").map(\.title),
            ["technology1"]
        )
    }

    @MainActor
    func test_visibleStories_withEmptyCategories_returnsFlatStories() {
        let stories = [
            createStoryConfiguration(title: "story1"),
            createStoryConfiguration(title: "story2"),
        ]
        let categories = [
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "empty",
                    recommendations: [],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Empty",
                    subtitle: nil,
                    receivedFeedRank: 0
                )
            ),
        ]
        let state = pocketReducer()(
            createSubject(),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(stories: stories, categories: categories),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertEqual(
            state.visibleStories(selectedNewsfeedCategoryID: nil).map(\.title),
            ["story1", "story2"]
        )
    }

    @MainActor
    func test_handleMerinoStoriesAction_withCategories_setsHasMerinoResponseContentTrue() {
        let state = pocketReducer()(
            createSubject(),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: createTestCategories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertTrue(state.hasMerinoResponseContent)
        XCTAssertTrue(state.shouldShowSection)
    }

    @MainActor
    func test_handleMerinoStoriesAction_withEmptyCategoriesAndNoStories_setsHasMerinoResponseContentFalse() {
        let categories = [
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "empty",
                    recommendations: [],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Empty",
                    subtitle: nil,
                    receivedFeedRank: 0
                )
            ),
        ]
        let state = pocketReducer()(
            createSubject(),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(stories: [], categories: categories),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertFalse(state.hasMerinoResponseContent)
        XCTAssertFalse(state.shouldShowSection)
    }

    func test_initialState_returnsExpectedSectionHeaderConfiguration() {
        XCTAssertEqual(MerinoState.Constants.sectionHeaderConfiguration.style, .newsAffordance)
        XCTAssertEqual(MerinoState.Constants.sectionHeaderConfiguration.isButtonHidden, true)
    }

    // MARK: - Private
    private func createSubject() -> MerinoState {
        return MerinoState(windowUUID: .XCTestDefaultUUID)
    }

    private func pocketReducer() -> Reducer<MerinoState> {
        return MerinoState.reducer
    }

    private func createTestCategories() -> [MerinoCategoryConfiguration] {
        [
            createCategory(
                feedID: "technology",
                title: "Technology",
                rank: 2,
                recommendations: [
                    createStoryConfiguration(title: "technology1", rank: 0),
                ]
            ),
            createCategory(
                feedID: "science",
                title: "Science",
                rank: 1,
                recommendations: [
                    createStoryConfiguration(title: "science2", rank: 1),
                    createStoryConfiguration(title: "science1", rank: 0),
                ]
            ),
        ]
    }

    private func createCategory(
        feedID: String,
        title: String,
        rank: Int,
        recommendations: [MerinoStoryConfiguration]
    ) -> MerinoCategoryConfiguration {
        return MerinoCategoryConfiguration(
            category: MerinoCategory(
                feedID: feedID,
                recommendations: recommendations,
                isBlocked: false,
                isFollowed: false,
                title: title,
                subtitle: nil,
                receivedFeedRank: rank
            )
        )
    }

    private func createStoryConfiguration(title: String, rank: Int = 0) -> MerinoStoryConfiguration {
        return MerinoStoryConfiguration(
            story: MerinoStory(
                corpusItemId: title,
                scheduledCorpusItemId: title,
                url: nil,
                title: title,
                excerpt: "Excerpt \(title)",
                topic: nil,
                publisher: "Publisher \(title)",
                isTimeSensitive: false,
                imageURL: nil,
                iconURL: nil,
                tileId: nil,
                receivedRank: rank
            )
        )
    }
}
