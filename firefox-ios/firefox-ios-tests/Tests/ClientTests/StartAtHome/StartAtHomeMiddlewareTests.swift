// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import XCTest

@testable import Client

final class StartAtHomeMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockProfile: MockProfile!
    private var mockTabManager: MockTabManager!
    private var mockWindowManager: MockWindowManager!
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var appState: AppState!
    /// 9 Sep 2001 8:00 pm GMT + 0
    let testDate = Date(timeIntervalSince1970: 1_000_065_600)

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        mockTabManager = MockTabManager()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: mockWindowManager)
        setupStore()
        appState = setupAppState()
    }

    override func tearDown() {
        mockProfile = nil
        mockWindowManager = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_didBrowserBecomeActiveAction_returnsFalseStartAtHomeCheck() throws {
        mockProfile.prefs.setString(StartAtHome.disabled.rawValue, forKey: PrefsKeys.FeatureFlags.StartAtHome)
        let subject = createSubject()
        let action = StartAtHomeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeActionType.didBrowserBecomeActive
        )

        let expectation = XCTestExpectation(description: "Start At Home action should be dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.startAtHomeProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? StartAtHomeAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? StartAtHomeMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted)
        XCTAssertEqual(actionCalled.shouldStartAtHome, false)
    }

    // MARK: - Helpers
    private func createSubject() -> StartAtHomeMiddleware {
        let mockDateProvider = MockDateProvider(
            fixedDate: Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: testDate
            )!
        )
        return StartAtHomeMiddleware(
            profile: mockProfile,
            windowManager: mockWindowManager,
            dateProvider: mockDateProvider)
    }

    // MARK: StoreTestUtility
    func setupAppState() -> Client.AppState {
        let appState = AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    )
                ]
            )
        )
        self.appState = appState
        return appState
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}

class MockDateProvider: DateProvider {
    private let fixedDate: Date
    init(fixedDate: Date) {
        self.fixedDate = fixedDate
    }
    func now() -> Date {
        return fixedDate
    }
}
