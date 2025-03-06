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

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        mockGleanWrapper = nil
        resetStore()
        super.tearDown()
    }

    func test_tapOnCustomizeHomepageAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.settings(.homePage)),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnCustomizeHomepage
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents?[0] as? CounterMetricType)
        let expectedMetricType = type(of: GleanMetrics.FirefoxHomePage.customizeHomepageButton)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    // MARK: - Helpers
    private func createSubject() -> HomepageMiddleware {
        return HomepageMiddleware(
            homepageTelemetry: HomepageTelemetry(
                gleanWrapper: mockGleanWrapper
            )
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
