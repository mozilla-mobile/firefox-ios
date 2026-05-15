// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest

@testable import Client

@MainActor
final class WorldCupCellFactoryTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: MockProfile())
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_makePages_whenNotMilestone2_returnsOnlyTimer() {
        var state = WorldCupSectionState(windowUUID: .XCTestDefaultUUID)
        state.isMilestone2 = false
        state.matches = [makeMatches()]

        let pages = WorldCupCellFactory.makePages(from: state)

        XCTAssertEqual(pages.count, 1)
        XCTAssertTrue(pages.first is WorldCupTimerView)
    }

    func test_makePages_whenMilestone2_withNoMatches_returnsOnlyTimer() {
        var state = WorldCupSectionState(windowUUID: .XCTestDefaultUUID)
        state.isMilestone2 = true
        state.matches = []

        let pages = WorldCupCellFactory.makePages(from: state)

        XCTAssertEqual(pages.count, 1)
        XCTAssertTrue(pages.first is WorldCupTimerView)
    }

    func test_makePages_whenMilestone2_withMatches_returnsTimerFollowedByMatchCards() {
        var state = WorldCupSectionState(windowUUID: .XCTestDefaultUUID)
        state.isMilestone2 = true
        state.matches = [makeMatches(), makeMatches()]

        let pages = WorldCupCellFactory.makePages(from: state)

        XCTAssertEqual(pages.count, 3)
        XCTAssertTrue(pages[0] is WorldCupTimerView)
        XCTAssertTrue(pages[1] is WorldCupMatchCardView)
        XCTAssertTrue(pages[2] is WorldCupMatchCardView)
    }

    func test_makePages_whenMilestone2_withApiErrorAndNoMatches_returnsOnlyErrorView() {
        var state = WorldCupSectionState(windowUUID: .XCTestDefaultUUID)
        state.isMilestone2 = true
        state.matches = []
        state.apiError = .network(reason: "offline")

        let pages = WorldCupCellFactory.makePages(from: state)

        XCTAssertEqual(pages.count, 1)
        XCTAssertTrue(pages[0] is WorldCupErrorView)
    }

    func test_makePages_whenMilestone2_withApiErrorAndMatches_returnsOnlyErrorView() {
        var state = WorldCupSectionState(windowUUID: .XCTestDefaultUUID)
        state.isMilestone2 = true
        state.matches = [makeMatches()]
        state.apiError = .other(code: 500, reason: "server error")

        let pages = WorldCupCellFactory.makePages(from: state)

        XCTAssertEqual(pages.count, 1)
        XCTAssertTrue(pages[0] is WorldCupErrorView)
    }

    func test_makePages_whenNotMilestone2_withApiError_returnsOnlyTimer() {
        var state = WorldCupSectionState(windowUUID: .XCTestDefaultUUID)
        state.isMilestone2 = false
        state.apiError = .network(reason: "offline")

        let pages = WorldCupCellFactory.makePages(from: state)

        XCTAssertEqual(pages.count, 1)
        XCTAssertTrue(pages.first is WorldCupTimerView)
    }

    private func makeMatches() -> WorldCupMatches {
        return WorldCupMatches(
            phaseTitle: "Group Stage",
            isLive: false,
            featuredMatch: [],
            upcomingMatches: []
        )
    }
}
