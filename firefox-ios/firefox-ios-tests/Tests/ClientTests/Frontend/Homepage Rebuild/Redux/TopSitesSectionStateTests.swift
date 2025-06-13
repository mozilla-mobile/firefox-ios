// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage
import XCTest

@testable import Client

final class TopsSitesSectionStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.topSitesData, [])
    }

    func test_retrievedUpdatedStoriesAction_returnsExpectedState() throws {
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

    func test_retrievedUpdatedStoriesAction_returnsDefaultState() throws {
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

    // MARK: numberOfTilesPerRow
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
