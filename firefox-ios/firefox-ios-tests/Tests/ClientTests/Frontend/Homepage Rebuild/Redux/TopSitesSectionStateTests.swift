// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage
import XCTest

@testable import Client

final class TopsSitesSectionStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.topSitesData, [])
    }

    func test_retrievedUpdatedStoriesAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = topSiteReducer()

        let exampleTopSite = TopSiteState(site: Site(url: "https://www.example.com", title: "hello", bookmarked: false, guid: nil))

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
}
