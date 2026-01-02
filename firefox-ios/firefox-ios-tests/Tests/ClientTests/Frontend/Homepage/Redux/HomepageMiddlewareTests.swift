// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class HomepageMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockGleanWrapper: MockGleanWrapper!
    var mockStore: MockStoreForMiddleware<AppState>!
    var mockNotificationCenter: MockNotificationCenter!

    override func setUp() async throws {
        try await super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        mockNotificationCenter = MockNotificationCenter()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        mockGleanWrapper = nil
        mockNotificationCenter = nil
        resetStore()
        try await super.tearDown()
    }

    func test_init_setsUpNotifications() {
        _ = createSubject()

        XCTAssertEqual(mockNotificationCenter?.addObserverCallCount, 8)
        XCTAssertEqual(mockNotificationCenter?.observers, [UIApplication.didBecomeActiveNotification,
                                                           .FirefoxAccountChanged,
                                                           .PrivateDataClearedHistory,
                                                           .ProfileDidFinishSyncing,
                                                           .TopSitesUpdated,
                                                           .DefaultSearchEngineUpdated,
                                                           .BookmarksUpdated,
                                                           .RustPlacesOpened
        ])
    }

    func test_viewWillAppearAction_doesNotSendTelemetryData() throws {
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.viewWillAppear
        )

        subject.homepageProvider(AppState(), action)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 0)
        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
    }

    func test_viewDidAppearAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.viewDidAppear
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.Homepage.viewed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_shouldShowImpressionTriggeredAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.Homepage.viewed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tapOnCustomizeHomepageAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.settings(.homePage)),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnCustomizeHomepageButton
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "customize_homepage_button")
        XCTAssertEqual(savedExtras.section, "customize_homepage")
    }

    func test_tapOnBookmarksShowMoreButtonAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.link),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnBookmarksShowMoreButton
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "bookmarks_show_all_button")
        XCTAssertEqual(savedExtras.section, "bookmarks")
    }

    func test_tapOnJumpBackInShowAllButtonAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.tabTray(.tabs)),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnJumpBackInShowAllButton
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "jump_back_in_show_all_button")
        XCTAssertEqual(savedExtras.section, "jump_back_in")
    }

    func test_tapOnJumpBackInSyncedShowAllButtonAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.tabTray(.syncedTabs)),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnJumpBackInShowAllButton
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "synced_show_all_button")
        XCTAssertEqual(savedExtras.section, "jump_back_in")
    }

    func test_didSelectItemAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = HomepageAction(
            telemetryExtras: HomepageTelemetryExtras(itemType: .topSite, topSitesTelemetryConfig: nil),
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.didSelectItem
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "top_site")
        XCTAssertEqual(savedExtras.section, "top_sites")
    }

    func test_sectionSeenAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = HomepageAction(
            telemetryExtras: HomepageTelemetryExtras(itemType: .topSite, topSitesTelemetryConfig: nil),
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.sectionSeen
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>)
        let expectedMetricType = type(of: GleanMetrics.Homepage.sectionViewed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.incrementLabeledCounterCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(mockGleanWrapper?.savedLabel as? String, "top_sites")
    }

    // MARK: - Search Bar
    func test_initializeAction_configuresSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: true)
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, true)
    }

    func test_initializeAction_doesNotConfigureSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: false)
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, false)
    }

    func test_viewWillTransitionAction_configuresSearchBar() throws {
        let subject = createSubject()
        setupNimbusSearchBarTesting(isEnabled: true)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.viewWillTransition
        )

        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, true)
    }

    func test_viewWillTransitionAction_doesNotConfigureSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: false)
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.viewWillTransition
        )

        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, false)
    }

    func test_toolbarCancelEditAction_configuresSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: true)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.cancelEdit
        )

        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, true)
    }

    func test_toolbarCancelEditAction_doesNotConfigureSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: false)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ToolbarActionType.cancelEdit
        )
        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, false)
    }

    func test_navigateBackAction_configuresSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: true)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.navigateBack
        )

        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, true)
    }

    func test_navigateBackAction_doesNotConfigureSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: false)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.navigateBack
        )
        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, false)
    }

    func test_didCloseTabAction_configuresSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: true)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.didCloseTabFromToolbar
        )

        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, true)
    }

    func test_didCloseTabAction_doesNotConfigureSearchBar() throws {
        setupNimbusSearchBarTesting(isEnabled: false)
        let subject = createSubject()
        let action = ToolbarAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.didCloseTabFromToolbar
        )
        let dispatchExpectation = XCTestExpectation(description: "Search bar configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSearchBarAction, configuredSearchBarActionCount) = try getActionInfo(for: .configuredSearchBar)

        let configuredSearchBarActionType = try XCTUnwrap(
            configuredSearchBarAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredSearchBarActionCount, 1)
        XCTAssertEqual(configuredSearchBarActionType, .configuredSearchBar)
        XCTAssertEqual(configuredSearchBarAction.isSearchBarEnabled, false)
    }

    // MARK: - Spacer
    func test_initializeAction_configuresSpacer() throws {
        setupNimbusStoriesRedesignTesting(isEnabled: true)
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )
        let dispatchExpectation = XCTestExpectation(description: "Spacer configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSpacerAction, configuredSpacerActionCount) = try getActionInfo(for: .configuredSpacer)
        let configuredSpacerActionType = try XCTUnwrap(configuredSpacerAction.actionType as? HomepageMiddlewareActionType)

        XCTAssertEqual(configuredSpacerActionCount, 1)
        XCTAssertEqual(configuredSpacerActionType, .configuredSpacer)
        XCTAssertEqual(configuredSpacerAction.shouldShowSpacer, true)
    }

    func test_initializeAction_doesNotConfigureSpacer() throws {
        setupNimbusStoriesRedesignTesting(isEnabled: false)
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )
        let dispatchExpectation = XCTestExpectation(description: "Spacer configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredSpacerAction, configuredSpacerActionCount) = try getActionInfo(for: .configuredSpacer)
        let configuredSpacerActionType = try XCTUnwrap(configuredSpacerAction.actionType as? HomepageMiddlewareActionType)

        XCTAssertEqual(configuredSpacerActionCount, 1)
        XCTAssertEqual(configuredSpacerActionType, .configuredSpacer)
        XCTAssertEqual(configuredSpacerAction.shouldShowSpacer, false)
    }

    func test_initializeAction_dispatchesConfiguresPrivacyNotice_withTrueValue() throws {
        let mockPrivacyNoticeHelper = MockPrivacyNoticeHelper()
        mockPrivacyNoticeHelper.shouldShowResult = true
        let subject = createSubject(privacyNoticeHelper: mockPrivacyNoticeHelper)

        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let dispatchExpectation = XCTestExpectation(description: "Privacy notice configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredPrivacyNoticeAction, configuredPrivacyNoticeActionCount) = try getActionInfo(
            for: .configuredPrivacyNotice
        )

        let configuredPrivacyNoticeActionType = try XCTUnwrap(
            configuredPrivacyNoticeAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredPrivacyNoticeActionCount, 1)
        XCTAssertEqual(configuredPrivacyNoticeActionType, .configuredPrivacyNotice)
        XCTAssertEqual(configuredPrivacyNoticeAction.shouldShowPrivacyNotice, mockPrivacyNoticeHelper.shouldShowResult)
    }

    func test_initializeAction_dispatchesConfiguresPrivacyNotice_withFalseValue() throws {
        let mockPrivacyNoticeHelper = MockPrivacyNoticeHelper()
        mockPrivacyNoticeHelper.shouldShowResult = false
        let subject = createSubject(privacyNoticeHelper: mockPrivacyNoticeHelper)

        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let dispatchExpectation = XCTestExpectation(description: "Privacy notice configured middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.homepageProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (configuredPrivacyNoticeAction, configuredPrivacyNoticeActionCount) = try getActionInfo(
            for: .configuredPrivacyNotice
        )

        let configuredPrivacyNoticeActionType = try XCTUnwrap(
            configuredPrivacyNoticeAction.actionType as? HomepageMiddlewareActionType
        )

        XCTAssertEqual(configuredPrivacyNoticeActionCount, 1)
        XCTAssertEqual(configuredPrivacyNoticeActionType, .configuredPrivacyNotice)
        XCTAssertEqual(configuredPrivacyNoticeAction.shouldShowPrivacyNotice, mockPrivacyNoticeHelper.shouldShowResult)
    }

    // MARK: - Helpers
    private func createSubject(privacyNoticeHelper: PrivacyNoticeHelperProtocol? = nil) -> HomepageMiddleware {
        return HomepageMiddleware(
            homepageTelemetry: HomepageTelemetry(
                gleanWrapper: mockGleanWrapper
            ),
            privacyNoticeHelper: privacyNoticeHelper,
            notificationCenter: mockNotificationCenter
        )
    }

    private func setupNimbusSearchBarTesting(isEnabled: Bool) {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(searchBar: isEnabled)
        }
    }

    private func setupNimbusStoriesRedesignTesting(isEnabled: Bool) {
        if !isEnabled {
            FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
                return HomepageRedesignFeature(
                    storiesRedesign: false,
                    storiesRedesignV2: false
                )
            }
        } else {
            FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
                return HomepageRedesignFeature(
                    storiesRedesign: true
                )
            }
        }
    }

    private func getActionInfo(for actionType: HomepageMiddlewareActionType)
    throws -> (HomepageAction, Int) {
        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [HomepageAction])

        let action = try XCTUnwrap(actionsCalled.first(where: {
            $0.actionType as? HomepageMiddlewareActionType == actionType
        }))

        let actionCount = actionsCalled.filter {
            ($0.actionType as? HomepageMiddlewareActionType) == actionType
        }.count

        return (action, actionCount)
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
