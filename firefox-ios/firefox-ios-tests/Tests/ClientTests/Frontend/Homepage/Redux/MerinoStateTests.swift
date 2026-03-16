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
        setupHomepageRedesignFeature(scrollDirection: .baseline, newsTransition: false)
        try await super.tearDown()
    }

    func test_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.merinoData, [])
        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, false)
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

    func test_initialState_withBaselineStoriesDirectionAndNewsTransitionDisabled_returnsExpectedState() {
        setupHomepageRedesignFeature(scrollDirection: .baseline, newsTransition: false)

        let initialState = createSubject()

        XCTAssertEqual(initialState.sectionHeaderState.style, .sectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.title, .FirefoxHomepage.Pocket.PopularTodaySectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, false)
    }

    func test_initialState_withBaselineStoriesDirectionAndNewsTransitionEnabled_returnsExpectedState() {
        setupHomepageRedesignFeature(scrollDirection: .baseline, newsTransition: true)

        let initialState = createSubject()

        XCTAssertEqual(initialState.sectionHeaderState.style, .sectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.title, .FirefoxHomepage.Pocket.NewsSectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, false)
    }

    func test_initialState_withHorizontalStoriesDirectionAndNewsTransitionDisabled_returnsExpectedState() {
        setupHomepageRedesignFeature(scrollDirection: .horizontal, newsTransition: false)

        let initialState = createSubject()

        XCTAssertEqual(initialState.sectionHeaderState.style, .sectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.title, .FirefoxHomepage.Pocket.PopularTodaySectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, true)
    }

    func test_initialState_withHorizontalStoriesDirectionAndNewsTransitionEnabled_returnsExpectedState() {
        setupHomepageRedesignFeature(scrollDirection: .horizontal, newsTransition: true)

        let initialState = createSubject()

        XCTAssertEqual(initialState.sectionHeaderState.style, .sectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.title, .FirefoxHomepage.Pocket.NewsSectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, true)
    }

    func test_initialState_withVerticalStoriesDirectionAndNewsTransitionDisabled_returnsExpectedState() {
        setupHomepageRedesignFeature(scrollDirection: .vertical, newsTransition: false)

        let initialState = createSubject()

        XCTAssertEqual(initialState.sectionHeaderState.style, .sectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.title, .FirefoxHomepage.Pocket.PopularTodaySectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, true)
    }

    func test_initialState_withVerticalStoriesDirectionAndNewsTransitionEnabled_returnsExpectedState() {
        setupHomepageRedesignFeature(scrollDirection: .vertical, newsTransition: true)

        let initialState = createSubject()

        XCTAssertEqual(initialState.sectionHeaderState.style, .newsAffordance)
        XCTAssertEqual(initialState.sectionHeaderState.title, .FirefoxHomepage.Pocket.NewsSectionTitle)
        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, true)
    }

    // MARK: - Private
    private func createSubject() -> MerinoState {
        return MerinoState(windowUUID: .XCTestDefaultUUID)
    }

    private func pocketReducer() -> Reducer<MerinoState> {
        return MerinoState.reducer
    }

    private func setupHomepageRedesignFeature(scrollDirection: ScrollDirection, newsTransition: Bool) {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(newsTransition: newsTransition, storiesScrollDirection: scrollDirection)
        }
    }
}
