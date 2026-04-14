// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import MozillaAppServices
import UIKit
import XCTest

@testable import Client

final class MerinoStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
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
    func test_retrievedUpdatedStoriesAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let feedStories: [RecommendationDataItem] = [
            .makeItem("feed1"),
            .makeItem("feed2"),
            .makeItem("feed3"),
        ]

        let stories = feedStories.compactMap {
            MerinoStoryConfiguration(story: MerinoStory(from: $0))
        }

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
        XCTAssertEqual(newState.merinoData.stories?.compactMap { $0.title }, ["feed1", "feed2", "feed3"])
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
    func test_categorySelected_withSpecificCategory_updatesSelectedCategoryID() {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let newState = reducer(
            initialState,
            MerinoAction(
                selectedCategoryID: "technology",
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoActionType.categorySelected
            )
        )

        XCTAssertEqual(newState.selectedCategoryID, "technology")
    }

    @MainActor
    func test_categorySelected_withNilCategory_clearsSelectedCategoryID() {
        let initialState = pocketReducer()(
            createSubject(),
            MerinoAction(
                selectedCategoryID: "technology",
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoActionType.categorySelected
            )
        )

        let newState = pocketReducer()(
            initialState,
            MerinoAction(
                selectedCategoryID: nil,
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoActionType.categorySelected
            )
        )

        XCTAssertNil(newState.selectedCategoryID)
    }

    @MainActor
    func test_availableCategories_returnsCategoriesSortedByRank() {
        let categories = [
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "technology",
                    recommendations: [],
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
                    recommendations: [],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Science",
                    subtitle: nil,
                    receivedFeedRank: 1
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

        XCTAssertEqual(state.visibleStories.map(\.title), ["science1", "science2", "technology1"])
    }

    @MainActor
    func test_visibleStories_withSelectedCategory_returnsOnlySelectedCategoryStories() {
        let reducer = pocketReducer()
        let categorizedState = reducer(
            createSubject(),
            MerinoAction(
                merinoStoryResponse: MerinoStoryResponse(categories: createTestCategories()),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )
        let selectedState = reducer(
            categorizedState,
            MerinoAction(
                selectedCategoryID: "technology",
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoActionType.categorySelected
            )
        )

        XCTAssertEqual(selectedState.visibleStories.map(\.title), ["technology1"])
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
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "technology",
                    recommendations: [
                        createStoryConfiguration(title: "technology1"),
                    ],
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
                    recommendations: [
                        createStoryConfiguration(title: "science1"),
                        createStoryConfiguration(title: "science2"),
                    ],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Science",
                    subtitle: nil,
                    receivedFeedRank: 1
                )
            ),
        ]
    }

    private func createStoryConfiguration(title: String) -> MerinoStoryConfiguration {
        MerinoStoryConfiguration(story: MerinoStory(from: .makeItem(title)))
    }

    private func setupHomepageRedesignFeature(scrollDirection: ScrollDirection) {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(storiesScrollDirection: scrollDirection)
        }
    }
}
