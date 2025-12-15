// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import MozillaAppServices
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

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.merinoData, [])
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
                merinoStories: stories,
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.merinoData.count, 3)
        XCTAssertEqual(newState.merinoData.compactMap { $0.title }, ["feed1", "feed2", "feed3"])
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

    func test_initialState_withShowDiscoverMoreButtonEnabled_showsHeaderButton() {
        setupNimbusShowDiscoverMoreButtonTesting(isEnabled: true)
        let initialState = createSubject()

        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, false)
    }

    func test_initialState_withShowDiscoverMoreButtonDisabled_hidesHeaderButton() {
        setupNimbusShowDiscoverMoreButtonTesting(isEnabled: false)
        let initialState = createSubject()

        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, true)
    }

    // MARK: - Private
    private func createSubject() -> MerinoState {
        return MerinoState(windowUUID: .XCTestDefaultUUID)
    }

    private func pocketReducer() -> Reducer<MerinoState> {
        return MerinoState.reducer
    }

    private func setupNimbusShowDiscoverMoreButtonTesting(isEnabled: Bool) {
        let discoverMoreConfiguration = DiscoverMoreConfiguration(discoverMoreV1Experience: false,
                                                                  showDiscoverMoreButton: isEnabled)
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(discoverMoreFeatureConfiguration: discoverMoreConfiguration)
        }
    }
}
