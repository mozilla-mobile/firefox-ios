// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage
import XCTest

@testable import Client

final class TopsSitesSectionStateTests: XCTestCase {
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
        XCTAssertEqual(initialState.topSitesData, [])
        XCTAssertEqual(initialState.sectionHeaderState.isButtonHidden, false)
        XCTAssertFalse(initialState.shouldShowSectionHeader)
    }

    @MainActor
    func test_retrievedUpdatedSitesAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = topSiteReducer()

        let exampleTopSite = TopSiteConfiguration(
            site: Site.createBasicSite(
                url: "https://www.example.com",
                title: "hello",
                isBookmarked: false
            )
        )

        let newState = reducer(
            initialState,
            TopSitesAction(
                topSites: [exampleTopSite],
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.topSitesData.count, 1)
        XCTAssertEqual(newState.topSitesData.compactMap { $0.title }, ["hello"])
    }

    @MainActor
    func test_retrievedUpdatedSitesAction_withMoreSitesThanVisibleCount_showsSectionHeader() {
        let initialState = createSubject()
        let reducer = topSiteReducer()
        let visibleTopSites = initialState.numberOfRows * initialState.numberOfTilesPerRow

        let newState = reducer(
            initialState,
            TopSitesAction(
                topSites: createSites(count: visibleTopSites + 1),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        XCTAssertTrue(newState.shouldShowSectionHeader)
    }

    @MainActor
    func test_retrievedUpdatedSitesAction_withVisibleSitesOnly_hidesSectionHeader() {
        let initialState = createSubject()
        let reducer = topSiteReducer()
        let visibleTopSites = initialState.numberOfRows * initialState.numberOfTilesPerRow

        let newState = reducer(
            initialState,
            TopSitesAction(
                topSites: createSites(count: visibleTopSites),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        XCTAssertFalse(newState.shouldShowSectionHeader)
    }

    @MainActor
    func test_retrievedUpdatedSitesAction_returnsDefaultState() throws {
        let initialState = createSubject()
        let reducer = topSiteReducer()

        let newState = reducer(
            initialState,
            TopSitesAction(
                topSites: nil,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)

        XCTAssertEqual(newState, defaultState(with: initialState))
        XCTAssertEqual(newState.topSitesData.count, 0)
        XCTAssertEqual(newState.topSitesData.compactMap { $0.title }, [])
    }

    @MainActor
    func test_updatedNumberOfRows_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = topSiteReducer()

        let newState = reducer(
            initialState,
            TopSitesAction(
                numberOfRows: 4,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfRows
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.numberOfRows, 4)
    }

    @MainActor
    func test_updatedNumberOfRows_recalculatesSectionHeaderVisibility() {
        let initialState = createSubject()
        let reducer = topSiteReducer()
        let overflowingTopSitesCount = initialState.numberOfRows * initialState.numberOfTilesPerRow + 1
        let rowsToFitAllSites =
            (overflowingTopSitesCount + initialState.numberOfTilesPerRow - 1) / initialState.numberOfTilesPerRow

        let stateWithOverflowingTopSites = reducer(
            initialState,
            TopSitesAction(
                topSites: createSites(count: overflowingTopSitesCount),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        let newState = reducer(
            stateWithOverflowingTopSites,
            TopSitesAction(
                numberOfRows: rowsToFitAllSites,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.updatedNumberOfRows
            )
        )

        XCTAssertFalse(newState.shouldShowSectionHeader)
    }

    @MainActor
    func test_toggleShowSectionSetting_withToggleOn_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = topSiteReducer()

        let newState = reducer(
            initialState,
            TopSitesAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldShowSection)
    }

    @MainActor
    func test_toggleShowSectionSetting_preservesSectionHeaderVisibility() {
        let initialState = createSubject()
        let reducer = topSiteReducer()
        let overflowingTopSitesCount = initialState.numberOfRows * initialState.numberOfTilesPerRow + 1

        let stateWithHeader = reducer(
            initialState,
            TopSitesAction(
                topSites: createSites(count: overflowingTopSitesCount),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        let newState = reducer(
            stateWithHeader,
            TopSitesAction(
                isEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesActionType.toggleShowSectionSetting
            )
        )

        XCTAssertTrue(stateWithHeader.shouldShowSectionHeader)
        XCTAssertTrue(newState.shouldShowSectionHeader)
    }

    // MARK: numberOfTilesPerRow
    @MainActor
    func test_viewWillTransition_numberOfTilesPerRow_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = topSiteReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                numberOfTopSitesPerRow: 8,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.viewWillTransition
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.numberOfTilesPerRow, 8)
    }

    @MainActor
    func test_viewWillTransition_recalculatesSectionHeaderVisibility() {
        let initialState = createSubject()
        let reducer = topSiteReducer()
        let overflowingTopSitesCount = initialState.numberOfRows * initialState.numberOfTilesPerRow + 1
        let tilesPerRowToFitAllSites = (overflowingTopSitesCount + initialState.numberOfRows - 1) / initialState.numberOfRows

        let stateWithOverflowingTopSites = reducer(
            initialState,
            TopSitesAction(
                topSites: createSites(count: overflowingTopSitesCount),
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        let newState = reducer(
            stateWithOverflowingTopSites,
            HomepageAction(
                numberOfTopSitesPerRow: tilesPerRowToFitAllSites,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.viewWillTransition
            )
        )

        XCTAssertTrue(stateWithOverflowingTopSites.shouldShowSectionHeader)
        XCTAssertFalse(newState.shouldShowSectionHeader)
    }

    @MainActor
    func test_viewDidLayoutSubviews_numberOfTilesPerRow_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = topSiteReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                numberOfTopSitesPerRow: 8,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.viewDidLayoutSubviews
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.numberOfTilesPerRow, 8)
    }

    @MainActor
    func test_initialize_numberOfTilesPerRow_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = topSiteReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                numberOfTopSitesPerRow: 8,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.numberOfTilesPerRow, 8)
    }

    // MARK: - Private
    private func createSubject() -> TopSitesSectionState {
        return TopSitesSectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func topSiteReducer() -> Reducer<TopSitesSectionState> {
        return TopSitesSectionState.reducer
    }

    private func defaultState(with state: TopSitesSectionState) -> TopSitesSectionState {
        return TopSitesSectionState.defaultState(from: state)
    }

    private func createSites(count: Int = 30) -> [TopSiteConfiguration] {
        var sites = [TopSiteConfiguration]()
        (0..<count).forEach {
            let site = Site.createBasicSite(url: "www.url\($0).com",
                                            title: "Title \($0)")
            sites.append(TopSiteConfiguration(site: site))
        }
        return sites
    }
}
