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

    func test_homepageInitialize_dispatchesDidUpdateWithStoreValues() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        mockWorldCupStore.isMilestone2 = true
        mockWorldCupStore.selectedTeam = "BRA"
        let subject = createSubject()
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
        XCTAssertEqual(dispatched.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(dispatched.shouldShowHomepageWorldCupSection)
        XCTAssertTrue(dispatched.shouldShowMilestone2)
        XCTAssertEqual(dispatched.selectedCountryId, "BRA")
    }

    func test_homepageInitialize_whenFeatureDisabled_dispatchesShouldShowFalse() throws {
        mockWorldCupStore.isFeatureEnabled = false
        mockWorldCupStore.isHomepageSectionEnabled = true
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)
        XCTAssertFalse(dispatched.shouldShowHomepageWorldCupSection)
    }

    // MARK: - WorldCupActionType.didChangeHomepageSettings

    func test_didChangeHomepageSettings_dispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = false
        let subject = createSubject()
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
    }

    // MARK: - WorldCupActionType.removeHomepageCard

    func test_removeHomepageCard_disablesSectionInStoreAndDispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        let subject = createSubject()
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
        // Section was just disabled, so `isFeatureEnabledAndSectionEnabled` should be false.
        XCTAssertFalse(dispatched.shouldShowHomepageWorldCupSection)
    }

    // MARK: - WorldCupActionType.selectTeam

    func test_selectTeam_withCountryId_persistsTeamAndDispatchesDidUpdate() throws {
        mockWorldCupStore.isFeatureEnabled = true
        mockWorldCupStore.isHomepageSectionEnabled = true
        let subject = createSubject()
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.selectTeam,
            selectedCountryId: "ARG"
        )

        let expectation = XCTestExpectation(description: "didUpdate dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.worldCupProvider(appState, action)

        wait(for: [expectation])
        
        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WorldCupAction)

        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 1)
        XCTAssertEqual(mockWorldCupStore.lastSetSelectedTeamCountryId, "ARG")
        XCTAssertEqual(dispatched.selectedCountryId, "ARG")
    }

    func test_selectTeam_withoutCountryId_doesNothing() {
        let subject = createSubject()
        let action = WorldCupAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WorldCupActionType.selectTeam,
            selectedCountryId: nil
        )

        subject.worldCupProvider(appState, action)

        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 0)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    // MARK: - Unhandled actions

    func test_unhandledAction_doesNotDispatch() {
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
        )

        subject.worldCupProvider(appState, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(mockWorldCupStore.setIsHomepageSectionEnabledCalled, 0)
        XCTAssertEqual(mockWorldCupStore.setSelectedTeamCalled, 0)
    }

    // MARK: - Helpers

    private func createSubject() -> WorldCupMiddleware {
        return WorldCupMiddleware(worldCupStore: mockWorldCupStore)
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
