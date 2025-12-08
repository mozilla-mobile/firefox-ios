// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import Storage
import XCTest

@testable import Client

final class MerinoMiddlewareTests: XCTestCase, StoreTestUtility {
    let merinoManager = MockMerinoManager()
    var mockGleanWrapper: MockGleanWrapper!
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        mockGleanWrapper = nil
        resetStore()
        try await super.tearDown()
    }

    func test_initializeHomepageAction_getPocketData() throws {
        let subject = createSubject(merinoManager: merinoManager)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        let expectation = XCTestExpectation(description: "Homepage action initialize dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.pocketSectionProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MerinoAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MerinoMiddlewareActionType)

        XCTAssertEqual(actionType, MerinoMiddlewareActionType.retrievedUpdatedHomepageStories)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionCalled.merinoStories?.count, 3)
        XCTAssertEqual(merinoManager.getMerinoItemsCalled, 1)
    }

    func test_enterForegroundAction_getPocketData() throws {
        let subject = createSubject(merinoManager: merinoManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.enteredForeground
        )

        let expectation = XCTestExpectation(description: "Homepage action entered foreground dispatched")
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.pocketSectionProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MerinoAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MerinoMiddlewareActionType)

        XCTAssertEqual(actionType, MerinoMiddlewareActionType.retrievedUpdatedHomepageStories)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertTrue(mockStore.dispatchedActions.first is MerinoAction)
        XCTAssertEqual(actionCalled.merinoStories?.count, 3)
        XCTAssertEqual(merinoManager.getMerinoItemsCalled, 1)
    }

    func test_toggleShowSectionSetting_getPocketData() throws {
        let subject = createSubject(merinoManager: merinoManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MerinoActionType.toggleShowSectionSetting
        )

        let expectation = XCTestExpectation(description: "Pocket action toggled show section setting dispatched")
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.pocketSectionProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MerinoAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MerinoMiddlewareActionType)

        XCTAssertEqual(actionType, MerinoMiddlewareActionType.retrievedUpdatedHomepageStories)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertTrue(mockStore.dispatchedActions.first is MerinoAction)
        XCTAssertEqual(actionCalled.merinoStories?.count, 3)
        XCTAssertEqual(merinoManager.getMerinoItemsCalled, 1)
    }

    func test_initializeStoriesFeed_getPocketData() throws {
        let subject = createSubject(merinoManager: merinoManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StoriesFeedActionType.initialize
        )

        let expectation = XCTestExpectation(description: "Stories feed action initialize dispatched")
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.pocketSectionProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MerinoAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MerinoMiddlewareActionType)

        XCTAssertEqual(actionType, MerinoMiddlewareActionType.retrievedUpdatedStoriesFeedStories)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertTrue(mockStore.dispatchedActions.first is MerinoAction)
        XCTAssertEqual(actionCalled.merinoStories?.count, 3)
        XCTAssertEqual(merinoManager.getMerinoItemsCalled, 1)
    }

    func test_tapOnHomepagePocketCellAction_sendTelemetryData() throws {
        let subject = createSubject(merinoManager: merinoManager)
        let config = OpenPocketTelemetryConfig(isZeroSearch: false, position: 0)
        let action = MerinoAction(
            telemetryConfig: config,
            windowUUID: .XCTestDefaultUUID,
            actionType: MerinoActionType.tapOnHomepageMerinoCell
        )
        subject.pocketSectionProvider(AppState(), action)

        let firstSavedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>
        )
        let expectedFirstMetricType = type(of: GleanMetrics.Pocket.openStoryOrigin)
        let firstResultMetricType = type(of: firstSavedMetric)
        let debugMessage = TelemetryDebugMessage(
            expectedMetric: expectedFirstMetricType,
            resultMetric: firstResultMetricType
        )

        let secondSavedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>)
        let expectedSecondMetricType = type(of: GleanMetrics.Pocket.openStoryPosition)
        let secondResultMetricType = type(of: secondSavedMetric)
        let secondDebugMessage = TelemetryDebugMessage(
            expectedMetric: expectedSecondMetricType,
            resultMetric: secondResultMetricType
        )

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 2)
        XCTAssertEqual(mockGleanWrapper.incrementLabeledCounterCalled, 2)
        XCTAssert(firstResultMetricType == expectedFirstMetricType, debugMessage.text)
        XCTAssert(secondResultMetricType == expectedSecondMetricType, secondDebugMessage.text)
    }

    func test_tapOnHomepagePocketCell_doesNotSendTelemetryData() throws {
        let subject = createSubject(merinoManager: merinoManager)
        let action = MerinoAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MerinoActionType.tapOnHomepageMerinoCell
        )
        subject.pocketSectionProvider(AppState(), action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordLabelCalled, 0)
    }

    func test_viewedSectionAction_sendTelemetryData() throws {
        let subject = createSubject(merinoManager: merinoManager)
        let action = MerinoAction(windowUUID: .XCTestDefaultUUID, actionType: MerinoActionType.viewedSection)

        subject.pocketSectionProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? CounterMetricType)
        let expectedMetricType = type(of: GleanMetrics.Pocket.sectionImpressions)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tappedOnOpenNewPrivateTabAction_sendTelemetryData() throws {
        let subject = createSubject(merinoManager: merinoManager)

        let merinoItem = createMerinoItem()
        guard case let .merino(state) = merinoItem else { return }
        let action = ContextMenuAction(
            menuType: MenuType(homepageItem: merinoItem),
            site: Site.createBasicSite(url: state.url?.absoluteString ?? "", title: state.title),
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnOpenNewPrivateTab
        )

        subject.pocketSectionProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.Pocket.openInPrivateTab)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tappedOnOpenNewPrivateTabAction_doesNotSendTelemetryData() {
        let subject = createSubject(merinoManager: merinoManager)

        let topSiteItem = createTopSiteItem()
        guard case let .topSite(state, nil) = topSiteItem else { return }
        let action = ContextMenuAction(
            menuType: MenuType(homepageItem: topSiteItem),
            site: state.site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnOpenNewPrivateTab
        )
        subject.pocketSectionProvider(AppState(), action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
    }

    // MARK: - Helpers
    private func createSubject(merinoManager: MockMerinoManager) -> MerinoMiddleware {
        return MerinoMiddleware(
            merinoManager: merinoManager,
            homepageTelemetry: HomepageTelemetry(
                gleanWrapper: mockGleanWrapper
            )
        )
    }

    private func createMerinoItem() -> HomepageItem {
        return .merino(
            MerinoStoryConfiguration(
                story: MerinoStory(
                    corpusItemId: "",
                    scheduledCorpusItemId: "",
                    url: URL("www.example.com/1234")!,
                    title: "Site 0",
                    excerpt: "example description",
                    topic: nil,
                    publisher: "",
                    isTimeSensitive: false,
                    imageURL: URL("www.example.com/image")!,
                    iconURL: nil,
                    tileId: 0,
                    receivedRank: 0
                )
            )
        )
    }

    private func createTopSiteItem() -> HomepageItem {
        return .topSite(
            TopSiteConfiguration(
                site: Site.createBasicSite(url: "www.example.com/1234", title: "Site 0")
            ), nil
        )
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .homepage(
                        HomepageState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
