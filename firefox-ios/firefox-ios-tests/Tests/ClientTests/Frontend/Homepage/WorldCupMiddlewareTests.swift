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
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(makeResponse()))
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
        XCTAssertEqual(apiClient.matchesFetchCount, 0)
        subject.worldCupProvider = { _, _ in }
    }

    func test_homepageInitialize_whenMilestone2_fetchesMatchesAndDispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(makeResponse()))
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertTrue(dispatched.shouldShowMilestone2)
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertEqual(apiClient.matchesFetchCount, 1)
        XCTAssertEqual(apiClient.liveFetchCount, 1)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - WorldCupActionType.didChangeHomepageSettings

    func test_didChangeHomepageSettings_dispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = false
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(makeResponse()))
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
        XCTAssertEqual(apiClient.matchesFetchCount, 0)
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
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(makeResponse()))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.selectTeam,
            selectedCountryId: "ARG"
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 1)
        XCTAssertEqual(mockWorldCupStore.lastSetSelectedTeamCountryId, "ARG")
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertEqual(apiClient.matchesFetchCount, 1)
        XCTAssertEqual(apiClient.liveFetchCount, 1)
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
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(makeResponse()))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.retryMatchesFetch
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertNil(dispatched.apiError)
        XCTAssertEqual(apiClient.matchesFetchCount, 1)
        XCTAssertEqual(apiClient.liveFetchCount, 1)
        subject.worldCupProvider = { _, _ in }
    }

    func test_retryMatchesFetch_whenFetchFails_dispatchesDidUpdateWithApiError() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(matchesResult: .failure(MockWorldCupClientError.network))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.retryMatchesFetch
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched after failed retry")
        mockStore.dispatchCalled = { [weak self] in
            guard let action = self?.latestWorldCupAction(), action.apiError != nil else { return }
            expectation.fulfill()
        }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertTrue(dispatched.matches.isEmpty)
        XCTAssertNotNil(dispatched.apiError)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - Live endpoint

    func test_homepageInitialize_whenLiveEndpointReportsMatchAsLive_marksCardLive() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "ARG"
        let scheduledMatch = makeMatch(id: 42, home: "ARG", away: "BRA")
        let liveMatch = makeMatch(id: 42, home: "ARG", away: "BRA", statusType: "live")
        let matchesResponse = WorldCupMatchesResponse(previous: nil, current: [scheduledMatch], next: nil)
        let liveResponse = WorldCupLiveResponse(matches: [liveMatch])
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(matchesResponse),
            liveResult: .success(liveResponse)
        )
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = XCTestExpectation(description: "matches eventually marked live")
        mockStore.dispatchCalled = { [weak self] in
            guard let action = self?.latestWorldCupAction(),
                  action.matches.first?.isLive == true else { return }
            expectation.fulfill()
        }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertTrue(dispatched.matches.first?.isLive ?? false)
        subject.worldCupProvider = { _, _ in }
    }

    func test_homepageInitialize_whenLiveEndpointEmpty_cardIsNotLive_evenWhenCurrentPopulated() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "ARG"
        let match = makeMatch(id: 42, home: "ARG", away: "BRA")
        let matchesResponse = WorldCupMatchesResponse(previous: nil, current: [match], next: nil)
        let liveResponse = WorldCupLiveResponse(matches: [])
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(matchesResponse),
            liveResult: .success(liveResponse)
        )
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertFalse(dispatched.matches.first?.isLive ?? true)
        subject.worldCupProvider = { _, _ in }
    }

    /// Merino keeps recently-final matches in the `/live` response for a tail
    /// window (~24h) so result tiles can show alongside live ones. The live
    /// badge must only stick for `statusType == "live"` entries.
    func test_homepageInitialize_whenLiveEndpointReportsMatchAsPast_doesNotMarkLive() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "ARG"
        let scheduledMatch = makeMatch(id: 42, home: "ARG", away: "BRA")
        let pastMatch = makeMatch(id: 42, home: "ARG", away: "BRA", statusType: "past")
        let matchesResponse = WorldCupMatchesResponse(previous: nil, current: [scheduledMatch], next: nil)
        let liveResponse = WorldCupLiveResponse(matches: [pastMatch])
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(matchesResponse),
            liveResult: .success(liveResponse)
        )
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertFalse(dispatched.matches.first?.isLive ?? true)
        subject.worldCupProvider = { _, _ in }
    }

    func test_homepageInitialize_whenLiveEndpointFails_stillReturnsMatchesAsNotLive() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "ARG"
        let match = makeMatch(id: 42, home: "ARG", away: "BRA")
        let matchesResponse = WorldCupMatchesResponse(previous: nil, current: [match], next: nil)
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(matchesResponse),
            liveResult: .failure(MockWorldCupClientError.network)
        )
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertNil(dispatched.apiError)
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertFalse(dispatched.matches.first?.isLive ?? true)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - Flattened grouping (no team selected)

    func test_homepageInitialize_whenNoTeamSelected_groupsMatchesByDayIntoCards() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = nil
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-12T18:00:00+00:00"),
                makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-06-12T21:00:00+00:00"),
                makeMatch(id: 3, home: "FRA", away: "GER", date: "2026-06-13T15:00:00+00:00")
            ]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: []))
        )
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 2)
        XCTAssertEqual(dispatched.matches[0].upcomingMatches.count, 2)
        XCTAssertTrue(dispatched.matches[0].featuredMatch.isEmpty)
        XCTAssertEqual(dispatched.matches[1].upcomingMatches.count, 1)
        XCTAssertTrue(dispatched.matches[1].featuredMatch.isEmpty)
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

    // MARK: - Dev server timeline

    func test_initialize_whenDevTimelineEnabledAndServerNowAdvanced_bucketsAsPast() throws {
        // Dev server clock is well past both matches, both outside the 2h
        // featured window. With no upcoming match left, the most recent past
        // becomes the hero and older matches drop to the row.
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "BRA"
        let match1 = makeMatch(id: 1, home: "BRA", away: "ARG", date: "2026-06-12T18:00:00+00:00")
        let match2 = makeMatch(id: 2, home: "BRA", away: "GER", date: "2026-06-15T18:00:00+00:00")
        let response = WorldCupMatchesResponse(
            now: "2026-07-01T00:00:00+00:00",
            previous: nil,
            current: nil,
            next: [match1, match2]
        )
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(response))
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let card = try XCTUnwrap(dispatched.matches.first)
        XCTAssertEqual(card.featuredMatch.map(\.homeCode), ["BRA"])
        XCTAssertEqual(card.featuredMatch.first?.awayCode, "GER")
        XCTAssertEqual(card.upcomingMatches.map(\.homeCode), ["BRA"])
        XCTAssertEqual(card.upcomingMatches.first?.awayCode, "ARG")
        subject.worldCupProvider = { _, _ in }
    }

    func test_initialize_acceptsFractionalSecondsInServerNow() throws {
        // The dev mock emits `state.clock.toISOString()` which includes ms,
        // e.g. "2026-06-11T19:30:00.000Z". Without fractional-seconds support
        // in `parseDate`, this falls back to `Date()` and the dev timeline
        // silently breaks — that's why the hero stuck on the first match.
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "BRA"
        let liveMatch = makeMatch(id: 1, home: "BRA", away: "ARG",
                                  date: "2026-06-11T19:00:00+00:00",
                                  statusType: "live")
        let upcomingMatch = makeMatch(id: 2, home: "BRA", away: "GER",
                                      date: "2026-06-19T18:00:00+00:00")
        let response = WorldCupMatchesResponse(
            now: "2026-06-11T19:30:00.000Z",
            previous: nil,
            current: [liveMatch],
            next: [upcomingMatch]
        )
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(response))
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let card = try XCTUnwrap(dispatched.matches.first)
        // now=19:30 is 30 min after kickoff (19:00) → match is in the 2h
        // featured window and becomes the hero. Upcoming match drops to the
        // row. If the fractional-seconds parse failed, `now` would silently
        // fall back to `Date()` (May 18) and the upcoming match would land
        // in the hero slot instead.
        XCTAssertEqual(card.featuredMatch.map(\.homeCode), ["BRA"])
        XCTAssertEqual(card.featuredMatch.first?.awayCode, "ARG")
        XCTAssertEqual(card.upcomingMatches.first?.awayCode, "GER")
        subject.worldCupProvider = { _, _ in }
    }

    func test_initialize_whenDevTimelineDisabled_ignoresResponseNow() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "BRA"
        let match1 = makeMatch(id: 1, home: "BRA", away: "ARG", date: "2026-06-12T18:00:00+00:00")
        let match2 = makeMatch(id: 2, home: "BRA", away: "GER", date: "2026-06-15T18:00:00+00:00")
        let response = WorldCupMatchesResponse(
            now: "2026-07-01T00:00:00+00:00",
            previous: nil,
            current: nil,
            next: [match1, match2]
        )
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(response))
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: false)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let card = try XCTUnwrap(dispatched.matches.first)
        XCTAssertEqual(card.featuredMatch.count, 1)
        XCTAssertEqual(card.upcomingMatches.count, 1)
        subject.worldCupProvider = { _, _ in }
    }

    func test_initialize_whenDevTimelineEnabledButServerNowMalformed_fallsBackToDate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "BRA"
        let match1 = makeMatch(id: 1, home: "BRA", away: "ARG", date: "2026-06-12T18:00:00+00:00")
        let match2 = makeMatch(id: 2, home: "BRA", away: "GER", date: "2026-06-15T18:00:00+00:00")
        let response = WorldCupMatchesResponse(
            now: "not-a-date",
            previous: nil,
            current: nil,
            next: [match1, match2]
        )
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(response))
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let card = try XCTUnwrap(dispatched.matches.first)
        XCTAssertEqual(card.featuredMatch.count, 1)
        XCTAssertEqual(card.upcomingMatches.count, 1)
        subject.worldCupProvider = { _, _ in }
    }

    func test_initialize_noTeam_whenDevTimelineEnabled_defaultIndexUsesServerNow() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = nil
        let match1 = makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-10T18:00:00+00:00")
        let match2 = makeMatch(id: 2, home: "BRA", away: "GER", date: "2026-06-15T18:00:00+00:00")
        let response = WorldCupMatchesResponse(
            now: "2026-06-12T00:00:00+00:00",
            previous: nil,
            current: nil,
            next: [match1, match2]
        )
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(response))
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 2)
        XCTAssertEqual(dispatched.defaultMatchIndex, 1)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - Helpers

    /// The injected `MockWorldCupAPIClient` emits each stream once and
    /// finishes, so the middleware sees exactly one matches and one live
    /// result per restart — no polling cadence to control here.
    private func createSubject(
        apiClient: WorldCupAPIClientProtocol?,
        usesDevServerTimeline: Bool = false
    ) -> WorldCupMiddleware {
        let subject = WorldCupMiddleware(
            worldCupStore: mockWorldCupStore,
            apiClient: apiClient,
            usesDevServerTimeline: usesDevServerTimeline,
            notificationCenter: NotificationCenter.default
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    /// Fires when at least one matches dispatch has landed (apiError nil and
    /// matches non-empty). Live re-dispatches are tolerated — the test reads
    /// `latestWorldCupAction()` to get the final state.
    private func expectationForMatchesDispatch() -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "matches didUpdate dispatched")
        expectation.assertForOverFulfill = false
        mockStore.dispatchCalled = { [weak self] in
            guard let action = self?.latestWorldCupAction() else { return }
            if !action.matches.isEmpty || action.apiError != nil {
                expectation.fulfill()
            }
        }
        return expectation
    }

    private func latestWorldCupAction() -> WorldCupAction? {
        mockStore.dispatchedActions.last as? WorldCupAction
    }

    private func makeResponse() -> WorldCupMatchesResponse {
        return WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [makeMatch(id: 1, home: "ARG", away: "BRA")]
        )
    }

    private func makeMatch(id: Int,
                           home: String,
                           away: String,
                           date: String = "2026-06-12T18:00:00+00:00",
                           statusType: String = "scheduled") -> WorldCupMatchesResponse.Match {
        let homeTeam = WorldCupMatchesResponse.Team(
            key: home, name: home, iconUrl: nil, group: "Group A", eliminated: false
        )
        let awayTeam = WorldCupMatchesResponse.Team(
            key: away, name: away, iconUrl: nil, group: "Group A", eliminated: false
        )
        return WorldCupMatchesResponse.Match(
            date: date,
            globalEventId: id,
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
            statusType: statusType
        )
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
