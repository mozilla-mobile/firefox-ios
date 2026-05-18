// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import XCTest

@testable import Client

@MainActor
final class WorldCupMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockWorldCupStore: MockWorldCupStore!
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()
        mockWorldCupStore = MockWorldCupStore()
        setupStore()
        appState = setupAppState()
    }

    override func tearDown() async throws {
        mockWorldCupStore = nil
        appState = nil
        resetStore()
        try await super.tearDown()
    }

    // MARK: - HomepageActionType.initialize

    func test_homepageInitialize_whenNotMilestone2_dispatchesDidUpdateWithEmptyMatches() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = false
        mockWorldCupStore.selectedTeam = "BRA"
        let apiClient = MockWorldCupAPIClient(result: .success(makeResponse()))
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertTrue(dispatched.shouldShowHomepageWorldCupSection)
        XCTAssertFalse(dispatched.shouldShowMilestone2)
        XCTAssertEqual(dispatched.selectedCountryId, "BRA")
        XCTAssertTrue(dispatched.matches.isEmpty)
        XCTAssertEqual(apiClient.fetchCount, 0)
        subject.worldCupProvider = { _, _ in }
    }

    func test_homepageInitialize_whenMilestone2_fetchesMatchesAndDispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(result: .success(makeResponse()))
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched after fetch")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertTrue(dispatched.shouldShowMilestone2)
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertEqual(apiClient.lastQuery, .matches)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - WorldCupActionType.didChangeHomepageSettings

    func test_didChangeHomepageSettings_dispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = false
        let apiClient = MockWorldCupAPIClient(result: .success(makeResponse()))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.didChangeHomepageSettings
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertFalse(dispatched.shouldShowHomepageWorldCupSection)
        XCTAssertEqual(mockWorldCupStore.setIsHomepageSectionEnabledCalled, 0)
        XCTAssertEqual(apiClient.fetchCount, 0)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - WorldCupActionType.removeHomepageCard

    func test_removeHomepageCard_disablesSectionInStoreAndDispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        let subject = createSubject(apiClient: nil)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.removeHomepageCard
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(mockWorldCupStore.setIsHomepageSectionEnabledCalled, 1)
        XCTAssertEqual(mockWorldCupStore.lastSetIsHomepageSectionEnabledValue, false)
        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertFalse(dispatched.shouldShowHomepageWorldCupSection)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - WorldCupActionType.selectTeam

    func test_selectTeam_persistsTeamAndKicksOffFetch() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(result: .success(makeResponse()))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.selectTeam,
            selectedCountryId: "ARG"
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched after fetch")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 1)
        XCTAssertEqual(mockWorldCupStore.lastSetSelectedTeamCountryId, "ARG")
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertEqual(apiClient.lastQuery, .matches)
        subject.worldCupProvider = { _, _ in }
    }

    func test_selectTeam_withNilCountryId_clearsTeam() throws {
        mockWorldCupStore.isMilestone2 = false
        let subject = createSubject(apiClient: nil)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.selectTeam,
            selectedCountryId: nil
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 1)
        XCTAssertNil(mockWorldCupStore.lastSetSelectedTeamCountryId)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - WorldCupActionType.retryMatchesFetch

    func test_retryMatchesFetch_whenMilestone2_fetchesAndDispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(result: .success(makeResponse()))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.retryMatchesFetch
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched after retry fetch")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertNil(dispatched.apiError)
        XCTAssertEqual(apiClient.lastQuery, .matches)
        subject.worldCupProvider = { _, _ in }
    }

    func test_retryMatchesFetch_whenFetchFails_dispatchesDidUpdateWithApiError() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(result: .failure(MockWorldCupClientError.network))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.retryMatchesFetch
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched after failed retry")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        XCTAssertTrue(dispatched.matches.isEmpty)
        XCTAssertNotNil(dispatched.apiError)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - Unhandled actions

    func test_unhandledAction_doesNotDispatch() {
        let subject = createSubject(apiClient: nil)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
        )

        subject.worldCupProvider(appState, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(mockWorldCupStore.setIsHomepageSectionEnabledCalled, 0)
        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 0)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - Helpers

    private func createSubject(apiClient: WorldCupAPIClientProtocol?) -> WorldCupMiddleware {
        let subject = WorldCupMiddleware(worldCupStore: mockWorldCupStore, apiClient: apiClient)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func makeResponse() -> WorldCupMatchesResponse {
        let homeTeam = WorldCupMatchesResponse.Team(
            key: "ARG", name: "Argentina", iconUrl: nil, group: "Group A", eliminated: false
        )
        let awayTeam = WorldCupMatchesResponse.Team(
            key: "BRA", name: "Brazil", iconUrl: nil, group: "Group A", eliminated: false
        )
        let match = WorldCupMatchesResponse.Match(
            date: "2026-06-12T18:00:00+00:00",
            globalEventId: 1,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            period: nil,
            homeScore: nil,
            awayScore: nil,
            homeExtra: nil,
            awayExtra: nil,
            homePenalty: nil,
            awayPenalty: nil,
            clock: nil,
            statusType: "scheduled"
        )
        return WorldCupMatchesResponse(previous: nil, current: nil, next: [match])
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        let state = AppState()
        self.appState = state
        return state
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
