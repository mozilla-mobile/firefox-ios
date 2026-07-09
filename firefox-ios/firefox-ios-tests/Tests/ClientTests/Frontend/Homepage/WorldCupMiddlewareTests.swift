// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import TestKit
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

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

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_homepageInitialize_whenMilestone2_fetchesMatchesAndDispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(makeResponse(liveStatus: true)))
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertTrue(dispatched.shouldShowMilestone2)
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertEqual(apiClient.matchesFetchCount, 1)
        XCTAssertEqual(apiClient.liveFetchCount, 1)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - WorldCupActionType.didChangeHomepageSettings
    func test_didChangeHomepageSettings_whenFeatureAndSectionEnabled_startsFeed() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let feed = MockWorldCupFeed()
        let subject = createSubject(feed: feed)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.didChangeHomepageSettings
        )

        subject.worldCupProvider.legacyMiddleware(appState, action)

        XCTAssertEqual(feed.startCalled, 1)
        XCTAssertEqual(feed.stopCalled, 0)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didChangeHomepageSettings_whenSectionDisabled_stopsFeed() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = false
        mockWorldCupStore.isMilestone2 = true
        let feed = MockWorldCupFeed()
        let subject = createSubject(feed: feed)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.didChangeHomepageSettings
        )

        subject.worldCupProvider.legacyMiddleware(appState, action)

        XCTAssertEqual(feed.stopCalled, 1)
        XCTAssertEqual(feed.startCalled, 0)

        releaseMiddlewareProvidersFromMemory(subject)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(mockWorldCupStore.setIsHomepageSectionEnabledCalled, 1)
        XCTAssertEqual(mockWorldCupStore.lastSetIsHomepageSectionEnabledValue, false)
        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertFalse(dispatched.shouldShowHomepageWorldCupSection)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - HomepageMiddlewareActionType.didEnterBackground

    func test_didEnterBackground_stopsFeed() throws {
        let feed = MockWorldCupFeed()
        let subject = WorldCupMiddleware(worldCupStore: mockWorldCupStore, feed: feed)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.didEnterBackground
        )

        subject.worldCupProvider.legacyMiddleware(appState, action)

        XCTAssertEqual(feed.stopCalled, 1)
        XCTAssertEqual(feed.startCalled, 0)
        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didBecomeActive_whenMilestone2_startsFeed() throws {
        mockWorldCupStore.isMilestone2 = true
        let feed = MockWorldCupFeed()
        let subject = WorldCupMiddleware(worldCupStore: mockWorldCupStore, feed: feed)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.didBecomeActive
        )

        subject.worldCupProvider.legacyMiddleware(appState, action)

        XCTAssertEqual(feed.startCalled, 1)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didBecomeActive_whenFeatureDisabledAfterMilestone2_dispatchesHiddenSectionWithoutStartingFeed() throws {
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isFeatureEnabled = false
        mockWorldCupStore.isHomepageSectionEnabled = true
        let feed = MockWorldCupFeed()
        let subject = createSubject(feed: feed)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.didBecomeActive
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertFalse(dispatched.shouldShowHomepageWorldCupSection)
        XCTAssertTrue(dispatched.matches.isEmpty)
        XCTAssertEqual(feed.startCalled, 0)
        subject.worldCupProvider = { _, _ in }
    }

    // MARK: - WorldCupActionType.selectTeam

    func test_selectTeam_persistsTeamAndKicksOffFetch() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(makeResponse(liveStatus: true)))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.selectTeam,
            selectedCountryId: "ARG"
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 1)
        XCTAssertEqual(mockWorldCupStore.lastSetSelectedTeamCountryId, "ARG")
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertEqual(apiClient.matchesFetchCount, 1)
        XCTAssertEqual(apiClient.liveFetchCount, 1)

        releaseMiddlewareProvidersFromMemory(subject)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 1)
        XCTAssertNil(mockWorldCupStore.lastSetSelectedTeamCountryId)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - WorldCupActionType.retryMatchesFetch

    func test_retryMatchesFetch_whenMilestone2_fetchesAndDispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(makeResponse(liveStatus: true)))
        let subject = createSubject(apiClient: apiClient)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.retryMatchesFetch
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertNil(dispatched.apiError)
        XCTAssertEqual(apiClient.matchesFetchCount, 1)
        XCTAssertEqual(apiClient.liveFetchCount, 1)

        releaseMiddlewareProvidersFromMemory(subject)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertTrue(dispatched.matches.isEmpty)
        XCTAssertNotNil(dispatched.apiError)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - Live endpoint

    func test_homepageInitialize_whenLiveEndpointReportsMatchAsLive_marksCardLive() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "ARG"
        // Both endpoints report the match as live — that's how the real
        // server transitions: /matches' status_type flips to "live" at
        // kickoff, which is the trigger for the middleware to open the
        // /live stream in the first place.
        let liveMatch = makeMatch(id: 42, home: "ARG", away: "BRA", statusType: "live")
        let matchesResponse = WorldCupMatchesResponse(previous: nil, current: [liveMatch], next: nil)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertTrue(dispatched.matches.first?.isLive ?? false)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_homepageInitialize_whenLiveEndpointEmpty_cardIsNotLive_evenWhenCurrentPopulated() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "ARG"
        // statusType "live" on /matches is what causes the middleware to
        // open the /live stream — we need the stream to actually fire to
        // exercise the "empty response → no badge" path.
        let match = makeMatch(id: 42, home: "ARG", away: "BRA", statusType: "live")
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertFalse(dispatched.matches.first?.isLive ?? true)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    /// Merino keeps recently-final matches in the `/live` response for a tail
    /// window (~24h) so result tiles can show alongside live ones. The live
    /// badge must only stick for `statusType == "live"` entries.
    func test_homepageInitialize_whenLiveEndpointReportsMatchAsPast_doesNotMarkLive() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "ARG"
        let liveMatch = makeMatch(id: 42, home: "ARG", away: "BRA", statusType: "live")
        let pastMatch = makeMatch(id: 42, home: "ARG", away: "BRA", statusType: "past")
        let matchesResponse = WorldCupMatchesResponse(previous: nil, current: [liveMatch], next: nil)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertFalse(dispatched.matches.first?.isLive ?? true)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_homepageInitialize_whenLiveEndpointFails_stillReturnsMatchesAsNotLive() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "ARG"
        let match = makeMatch(id: 42, home: "ARG", away: "BRA", statusType: "live")
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertNil(dispatched.apiError)
        XCTAssertEqual(dispatched.matches.count, 1)
        XCTAssertFalse(dispatched.matches.first?.isLive ?? true)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    /// Smart-polling gate: when `/matches` shows nothing in its play window
    /// (no live `statusType`, no kickoff inside the [-15min, +120min] band),
    /// the middleware shouldn't open the `/live` stream at all.
    func test_homepageInitialize_whenNoMatchInPlayWindow_doesNotPollLive() throws {
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
        subject.worldCupProvider.legacyMiddleware(appState, action)
        wait(for: [expectation])

        XCTAssertEqual(apiClient.matchesFetchCount, 1)
        XCTAssertEqual(apiClient.liveFetchCount, 0)

        releaseMiddlewareProvidersFromMemory(subject)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 2)
        XCTAssertEqual(dispatched.matches[0].upcomingMatches.count, 2)
        XCTAssertTrue(dispatched.matches[0].featuredMatch.isEmpty)
        XCTAssertEqual(dispatched.matches[1].upcomingMatches.count, 1)
        XCTAssertTrue(dispatched.matches[1].featuredMatch.isEmpty)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - M3 elimination branching

    func test_homepageInitialize_whenSelectedTeamNotEliminated_dispatchesSingleTeamCard() throws {
        // M2-preserved behavior: when a team is picked and the only matches
        // in the response are group-stage, perStage produces one card
        // (the group card) with the M2 featured + upcoming-row layout.
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "BRA"
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "BRA", away: "ARG", date: "2026-06-12T18:00:00+00:00"),
                makeMatch(id: 2, home: "ENG", away: "BRA", date: "2026-06-15T21:00:00+00:00"),
                // Unrelated match — dropped by `filtered(toTeam:)`.
                makeMatch(id: 3, home: "FRA", away: "GER", date: "2026-06-12T15:00:00+00:00")
            ]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: [])),
            teamsResult: .success(makeTeamsResponse(eliminated: ["ARG"]))
        )
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let matchesExpectation = expectationForMatchesDispatch()
        let teamsExpectation = expectation(description: "loadTeams called")
        apiClient.loadTeamsCalled = teamsExpectation

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [matchesExpectation, teamsExpectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)
        // Both BRA fixtures live in this group card (one in featured slot,
        // the other in the upcoming row). FRA-GER was filtered out.
        let allShown = dispatched.matches[0].featuredMatch + dispatched.matches[0].upcomingMatches
        XCTAssertEqual(allShown.count, 2)
        XCTAssertEqual(apiClient.fetchTeamsCount, 1)
        XCTAssertNil(apiClient.lastTeamsTeam, "teams call should be unfiltered")
        XCTAssertNil(apiClient.lastMatchesTeam, "matches call should be unfiltered")

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_homepageInitialize_whenSelectedTeamAdvancesToKnockouts_addsKnockoutCard() throws {
        // M3 spec: once the team has a knockout fixture in the response,
        // we get a second card for it on top of the group-history card.
        // Default index lands on the latest stage (the R32 card).
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "CAN"
        // `now` pinned (dev timeline) after the group stage and before the R32
        // fixture so the result is deterministic and past the first kickoff.
        let response = WorldCupMatchesResponse(
            now: "2026-06-26T12:00:00+00:00",
            previous: [
                makeMatch(id: 1, home: "CAN", away: "BIH", date: "2026-06-12T19:00:00+00:00", stage: .groupStage),
                makeMatch(id: 2, home: "CAN", away: "QAT", date: "2026-06-18T22:00:00+00:00", stage: .groupStage),
                makeMatch(id: 3, home: "CHE", away: "CAN", date: "2026-06-24T19:00:00+00:00", stage: .groupStage)
            ],
            current: nil,
            next: [
                makeMatch(id: 4, home: "MEX", away: "CAN", date: "2026-06-28T13:00:00+00:00", stage: .roundOf32)
            ]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: [])),
            teamsResult: .success(makeTeamsResponse())
        )
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchCardCount(2)

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 2)
        XCTAssertEqual(dispatched.matches[1].phaseTitle,
                       String.WorldCup.HomepageWidget.RoundPhase.Round32Label)
        // Lands on the latest stage (R32, index 1), not the group card.
        XCTAssertEqual(dispatched.defaultMatchIndex, 1)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_homepageInitialize_whenSelectedTeamEliminated_fallsBackToFlattenedAllTeams() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "BRA"
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "ARG", away: "ENG", date: "2026-06-30T18:00:00+00:00", stage: .roundOf16),
                makeMatch(id: 2, home: "FRA", away: "GER", date: "2026-07-04T18:00:00+00:00", stage: .quarterFinals)
            ]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: [])),
            teamsResult: .success(makeTeamsResponse(eliminated: ["BRA"]))
        )
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        // Eliminated path requires waiting for the post-teams re-emit, so
        // expect at least two dispatches with non-empty matches.
        let expectation = expectationForMatchCardCount(2)

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 2)
        XCTAssertEqual(dispatched.matches[0].phaseTitle,
                       String.WorldCup.HomepageWidget.RoundPhase.Round16Label)
        XCTAssertEqual(dispatched.matches[1].phaseTitle,
                       String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_homepageInitialize_whenSelectedTeamNotInRoster_defaultsToSingleTeamCard() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "BRA"
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [makeMatch(id: 1, home: "BRA", away: "ARG")]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: [])),
            // Empty roster — covers the "team not in response" case as well
            // as the "teams hasn't loaded yet" case (same code path).
            teamsResult: .success(WorldCupTeamsResponse(teams: []))
        )
        let subject = createSubject(apiClient: apiClient)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = expectationForMatchesDispatch()

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 1)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - WorldCupActionType.worldCupDidStart

    func test_worldCupDidStart_dispatchesDidUpdateWithHasWorldCupStarted() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.hasWorldCupStarted = true
        let subject = createSubject(apiClient: nil)
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.worldCupDidStart
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        let actionType = try XCTUnwrap(dispatched.actionType as? WorldCupMiddlewareActionType)

        XCTAssertEqual(actionType, .didUpdate)
        XCTAssertTrue(dispatched.hasWorldCupStarted)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - Unhandled actions

    func test_unhandledAction_doesNotDispatch() {
        let subject = createSubject(apiClient: nil)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
        )

        subject.worldCupProvider.legacyMiddleware(appState, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(mockWorldCupStore.setIsHomepageSectionEnabledCalled, 0)
        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 0)

        releaseMiddlewareProvidersFromMemory(subject)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let card = try XCTUnwrap(dispatched.matches.first)
        XCTAssertEqual(card.featuredMatch.map(\.homeCode), ["BRA"])
        XCTAssertEqual(card.featuredMatch.first?.awayCode, "GER")
        XCTAssertEqual(card.upcomingMatches.map(\.homeCode), ["BRA"])
        XCTAssertEqual(card.upcomingMatches.first?.awayCode, "ARG")

        releaseMiddlewareProvidersFromMemory(subject)
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
        let liveMatch = makeMatch(id: 1,
                                  home: "BRA",
                                  away: "ARG",
                                  date: "2026-06-11T19:00:00+00:00",
                                  statusType: "live")
        let upcomingMatch = makeMatch(id: 2,
                                      home: "BRA",
                                      away: "GER",
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

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

        releaseMiddlewareProvidersFromMemory(subject)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let card = try XCTUnwrap(dispatched.matches.first)
        XCTAssertEqual(card.featuredMatch.count, 1)
        XCTAssertEqual(card.upcomingMatches.count, 1)

        releaseMiddlewareProvidersFromMemory(subject)
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        let card = try XCTUnwrap(dispatched.matches.first)
        XCTAssertEqual(card.featuredMatch.count, 1)
        XCTAssertEqual(card.upcomingMatches.count, 1)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_initialize_noTeam_dispatchesTimerAsDefaultPage() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = nil
        // `now` is before the first match kicks off → stay on the timer (page 0).
        let match1 = makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-10T18:00:00+00:00")
        let match2 = makeMatch(id: 2, home: "BRA", away: "GER", date: "2026-06-15T18:00:00+00:00")
        let response = WorldCupMatchesResponse(
            now: "2026-06-05T00:00:00+00:00",
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

        subject.worldCupProvider.legacyMiddleware(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.matches.count, 2)
        XCTAssertEqual(dispatched.defaultMatchIndex, 0)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - Confetti

    func test_didUpdate_whenSelectedTeamWinsMatchOnDefaultCard_setsConfettiAndPersistsSeen() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = "ARG"
        // now pinned past the match's featured + linger window so the won match
        // sits on the single (default-index 0) card.
        let response = WorldCupMatchesResponse(
            now: "2026-06-12T21:00:00+00:00",
            previous: nil,
            current: nil,
            next: [makeWinningMatch(id: 1, winner: "ARG", loser: "BRA", date: "2026-06-12T18:00:00+00:00")]
        )
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(response))
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        let expectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(appState, action)
        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.defaultMatchIndex, 0)
        XCTAssertTrue(dispatched.shouldShowConfetti)
        XCTAssertFalse(mockWorldCupStore.seenWinningMatchIDs.isEmpty)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didUpdate_whenWinningMatchIsNotOnDefaultCard_doesNotSetConfetti() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = "CAN"
        // Group match already won (past); the R32 fixture is still upcoming and
        // is the default card. The win is on card 0, default index is 1.
        let response = WorldCupMatchesResponse(
            now: "2026-06-26T12:00:00+00:00",
            previous: [
                makeWinningMatch(
                    id: 1,
                    winner: "CAN",
                    loser: "BIH",
                    date: "2026-06-12T19:00:00+00:00",
                    stage: .groupStage
                )
            ],
            current: nil,
            next: [
                makeMatch(
                    id: 2,
                    home: "MEX",
                    away: "CAN",
                    date: "2026-06-28T13:00:00+00:00",
                    stage: .roundOf32
                )
            ]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            teamsResult: .success(makeTeamsResponse())
        )
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        let expectation = expectationForMatchCardCount(2)
        subject.worldCupProvider.legacyMiddleware(appState, action)
        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertEqual(dispatched.defaultMatchIndex, 1)
        XCTAssertFalse(dispatched.shouldShowConfetti)
        // The win is still recorded as seen even though it didn't celebrate.
        XCTAssertFalse(mockWorldCupStore.seenWinningMatchIDs.isEmpty)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didUpdate_whenWinAlreadySeen_doesNotReCelebrateOnRefetch() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = "ARG"
        let response = WorldCupMatchesResponse(
            now: "2026-06-12T21:00:00+00:00",
            previous: nil,
            current: nil,
            next: [makeWinningMatch(id: 1, winner: "ARG", loser: "BRA", date: "2026-06-12T18:00:00+00:00")]
        )
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(response))
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)

        let firstExpectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(
            appState,
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        )
        wait(for: [firstExpectation])
        XCTAssertTrue(try XCTUnwrap(latestWorldCupAction()).shouldShowConfetti)

        // A second fetch re-emits the same won match. Because the win was
        // persisted as seen, it must not celebrate again — this is the
        // cross-launch correlation behavior.
        let secondExpectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(
            appState,
            WorldCupAction(windowUUID: .XCTestDefaultUUID, actionType: WorldCupActionType.retryMatchesFetch)
        )
        wait(for: [secondExpectation])

        XCTAssertFalse(try XCTUnwrap(latestWorldCupAction()).shouldShowConfetti)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didUpdate_whenNoTeam_andDefaultCardIsNotAFinal_doesNotSetConfetti() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = nil

        let response = WorldCupMatchesResponse(
            now: "2026-06-12T21:00:00+00:00",
            previous: nil,
            current: nil,
            next: [makeWinningMatch(id: 1, winner: "ARG", loser: "BRA", date: "2026-06-12T18:00:00+00:00")]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: []))
        )
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        let expectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(appState, action)
        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertFalse(dispatched.shouldShowConfetti)
        XCTAssertEqual(mockWorldCupStore.setSeenWinningMatchIDsCalled, 0)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didUpdate_whenNoTeam_andDefaultCardIsFinishedFinal_setsConfettiAndPersists() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = nil
        let response = WorldCupMatchesResponse(
            now: "2026-07-19T21:00:00+00:00",
            previous: nil,
            current: nil,
            next: [makeWinningMatch(
                id: 1,
                winner: "FRA",
                loser: "ARG",
                date: "2026-07-19T18:00:00+00:00",
                stage: .final
            )]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: []))
        )
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        let expectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(appState, action)
        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        // Page 0 is the countdown timer, so the final card sits at page 1.
        XCTAssertEqual(dispatched.defaultMatchIndex, 1)
        XCTAssertTrue(dispatched.shouldShowConfetti)
        XCTAssertFalse(mockWorldCupStore.seenWinningMatchIDs.isEmpty)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didUpdate_whenNoTeam_andDefaultCardIsFinishedBronzeFinal_setsConfetti() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = nil
        let response = WorldCupMatchesResponse(
            now: "2026-07-18T21:00:00+00:00",
            previous: nil,
            current: nil,
            next: [makeWinningMatch(
                id: 1,
                winner: "CRO",
                loser: "MAR",
                date: "2026-07-18T18:00:00+00:00",
                stage: .thirdPlace
            )]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: []))
        )
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        let expectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(appState, action)
        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertTrue(dispatched.shouldShowConfetti)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didUpdate_whenNoTeam_andFinalIsLiveNotEnded_doesNotSetConfetti() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = nil
        let final = makeMatch(
            id: 1,
            home: "FRA",
            away: "ARG",
            date: "2026-07-19T18:00:00+00:00",
            statusType: "live",
            stage: .final
        )
        let response = WorldCupMatchesResponse(
            now: "2026-07-19T18:30:00+00:00",
            previous: nil,
            current: [final],
            next: nil
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: [final]))
        )
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        let expectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(appState, action)
        wait(for: [expectation])

        let dispatched = try XCTUnwrap(latestWorldCupAction())
        XCTAssertFalse(dispatched.shouldShowConfetti)
        XCTAssertEqual(mockWorldCupStore.setSeenWinningMatchIDsCalled, 0)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_didUpdate_whenNoTeam_finalCelebratesOnceThenNotOnRefetch() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = nil
        let response = WorldCupMatchesResponse(
            now: "2026-07-19T21:00:00+00:00",
            previous: nil,
            current: nil,
            next: [makeWinningMatch(
                id: 1,
                winner: "FRA",
                loser: "ARG",
                date: "2026-07-19T18:00:00+00:00",
                stage: .final
            )]
        )
        let apiClient = MockWorldCupAPIClient(
            matchesResult: .success(response),
            liveResult: .success(WorldCupLiveResponse(matches: []))
        )
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)

        let firstExpectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(
            appState,
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        )
        wait(for: [firstExpectation])
        XCTAssertTrue(try XCTUnwrap(latestWorldCupAction()).shouldShowConfetti)

        let secondExpectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(
            appState,
            WorldCupAction(windowUUID: .XCTestDefaultUUID, actionType: WorldCupActionType.retryMatchesFetch)
        )
        wait(for: [secondExpectation])
        XCTAssertFalse(try XCTUnwrap(latestWorldCupAction()).shouldShowConfetti)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    func test_viewWillDisappear_suppressesConfettiWhileOffScreen() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.isCelebrationAnimationEnabled = true
        mockWorldCupStore.selectedTeam = "ARG"
        let response = WorldCupMatchesResponse(
            now: "2026-06-12T21:00:00+00:00",
            previous: nil,
            current: nil,
            next: [makeWinningMatch(id: 1, winner: "ARG", loser: "BRA", date: "2026-06-12T18:00:00+00:00")]
        )
        let apiClient = MockWorldCupAPIClient(matchesResult: .success(response))
        let subject = createSubject(apiClient: apiClient, usesDevServerTimeline: true)
        bringHomepageOnScreen(subject)
        subject.worldCupProvider.legacyMiddleware(
            appState,
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewWillDisappear)
        )

        let expectation = expectationForMatchesDispatch()
        subject.worldCupProvider.legacyMiddleware(
            appState,
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        )
        wait(for: [expectation])

        XCTAssertFalse(try XCTUnwrap(latestWorldCupAction()).shouldShowConfetti)
        XCTAssertEqual(mockWorldCupStore.setSeenWinningMatchIDsCalled, 0)

        releaseMiddlewareProvidersFromMemory(subject)
    }

    // MARK: - Helpers

    /// Builds a feed around the mock client (when provided) and hands both
    /// to the middleware. The mock's streams emit each result once and
    /// finish, so the feed sees exactly one matches and one live result
    /// per restart — no polling cadence to control here.
    private func createSubject(
        apiClient: WorldCupAPIClientProtocol?,
        usesDevServerTimeline: Bool = false
    ) -> WorldCupMiddleware {
        let store: MockWorldCupStore = mockWorldCupStore
        let feed = apiClient.map { client in
            WorldCupFeed(
                apiClient: client,
                store: store,
                usesDevServerTimeline: usesDevServerTimeline,
                selectedTeamProvider: { store.selectedTeam }
            )
        }
        let subject = WorldCupMiddleware(worldCupStore: store, feed: feed)
        trackForMemoryLeaks(subject)
        return subject
    }

    /// Our middleware providers always retain a strong reference to `self` for ease of use. Thus, `trackForMemoryLeaks` will
    /// fail in our unit tests due to a strong circular reference to the middleware retained by its provider closures. In
    /// practice, this is not a memory leak issue, as we permanently allocate and retain our middleware providers for the
    /// entire app lifecycle.
    ///
    /// As a work around for unit tests, we should release each middleware's provider closures from memory by assigning an
    /// empty closure, which does not strongly retain `self`.
    private func releaseMiddlewareProvidersFromMemory(_ subject: WorldCupMiddleware) {
        subject.worldCupProvider = emptyMiddlewareProviderFactory()
        subject.legacyProvider = emptyLegacyMiddlewareMethodFactory()
        subject.modernProvider = emptyMiddlewareMethodFactory()
    }

    /// Hands the middleware a `MockWorldCupFeed` so tests can assert on the
    /// feed lifecycle (start/stop) without driving the real network plumbing.
    private func createSubject(feed: MockWorldCupFeed) -> WorldCupMiddleware {
        let subject = WorldCupMiddleware(worldCupStore: mockWorldCupStore, feed: feed)
        trackForMemoryLeaks(subject)
        return subject
    }

    /// Dispatches `viewDidAppear` so the middleware treats the homepage as
    /// visible — the precondition for `resolveShouldShowConfetti` to run. Also
    /// re-dispatches the feed's latest snapshot, mirroring the real lifecycle.
    private func bringHomepageOnScreen(_ subject: WorldCupMiddleware) {
        subject.worldCupProvider.legacyMiddleware(
            appState,
            HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewDidAppear)
        )
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

    /// Fires once a dispatch lands whose `matches` array has at least
    /// `count` cards. Used by tests that need to wait past the initial
    /// optimistic snapshot for a re-emit triggered by the teams response
    /// landing (e.g. selected-team-eliminated path).
    private func expectationForMatchCardCount(_ count: Int) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "matches dispatch with \(count) cards")
        expectation.assertForOverFulfill = false
        mockStore.dispatchCalled = { [weak self] in
            guard let action = self?.latestWorldCupAction() else { return }
            if action.matches.count >= count { expectation.fulfill() }
        }
        return expectation
    }

    private func latestWorldCupAction() -> WorldCupAction? {
        mockStore.dispatchedActions.last as? WorldCupAction
    }

    /// `liveStatus: true` flags the match with `statusType == "live"`, which
    /// is what triggers the middleware to open the `/live` stream. Default
    /// is `"scheduled"` so callers that only care about the matches dispatch
    /// don't accidentally exercise the live-polling path.
    private func makeResponse(liveStatus: Bool = false) -> WorldCupMatchesResponse {
        return WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [makeMatch(id: 1,
                             home: "ARG",
                             away: "BRA",
                             statusType: liveStatus ? "live" : "scheduled")]
        )
    }

    /// Builds a teams roster where every team referenced by `makeMatch`
    /// is present; the `eliminated` set marks which keys come back with
    /// `eliminated == true`. Other teams are not-eliminated.
    private func makeTeamsResponse(eliminated: Set<String> = []) -> WorldCupTeamsResponse {
        let keys = ["BRA", "ARG", "ENG", "USA", "FRA", "GER"]
        return WorldCupTeamsResponse(teams: keys.map { key in
            WorldCupTeamsResponse.Team(
                key: key,
                globalTeamId: nil,
                name: key,
                region: nil,
                colors: nil,
                iconUrl: nil,
                group: "Group A",
                eliminated: eliminated.contains(key),
                standing: nil
            )
        })
    }

    /// A finished match (`statusType == "past"`) with a 2–1 result so
    /// `winnerTeam` resolves to `winner`. `winner` is placed at home.
    private func makeWinningMatch(id: Int,
                                  winner: String,
                                  loser: String,
                                  date: String = "2026-06-12T18:00:00+00:00",
                                  stage: WorldCupMatchesResponse.Match.Stage? = .groupStage)
    -> WorldCupMatchesResponse.Match {
        let homeTeam = WorldCupMatchesResponse.Team(
            key: winner, name: winner, iconUrl: nil, group: "Group A", eliminated: false
        )
        let awayTeam = WorldCupMatchesResponse.Team(
            key: loser, name: loser, iconUrl: nil, group: "Group A", eliminated: false
        )
        return WorldCupMatchesResponse.Match(
            date: date,
            globalEventId: id,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeScore: 2,
            awayScore: 1,
            statusType: "past",
            stage: stage
        )
    }

    private func makeMatch(id: Int,
                           home: String,
                           away: String,
                           date: String = "2026-06-12T18:00:00+00:00",
                           statusType: String = "scheduled",
                           stage: WorldCupMatchesResponse.Match.Stage? = .groupStage)
    -> WorldCupMatchesResponse.Match {
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
            statusType: statusType,
            stage: stage
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
