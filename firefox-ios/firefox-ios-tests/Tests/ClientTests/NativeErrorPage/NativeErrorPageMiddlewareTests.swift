// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class NativeErrorPageMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockTabManager: MockTabManager!
    private var mockWindowManager: MockWindowManager!
    private var mockLogger: MockLogger!
    private var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockTabManager = MockTabManager()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )
        mockLogger = MockLogger()
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: mockWindowManager)
        setupStore()
    }

    override func tearDown() async throws {
        mockTabManager = nil
        mockWindowManager = nil
        mockLogger = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    // MARK: - handleBypassCertificateWarning Tests

    func testBypassCertificateWarning_withNoSelectedTab_returnsEarly() {
        let subject = createSubject()
        mockTabManager.selectedTab = nil

        let action = NativeErrorPageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: NativeErrorPageActionType.bypassCertificateWarning
        )

        subject.nativeErrorPageProvider(mockStore.state, action)

        XCTAssertEqual(mockLogger.savedLevel, .warning)
        XCTAssertEqual(mockLogger.savedCategory, .certificate)
    }

    func testBypassCertificateWarning_withNoStoredError_returnsEarly() {
        let subject = createSubject()

        let action = NativeErrorPageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: NativeErrorPageActionType.bypassCertificateWarning
        )

        subject.nativeErrorPageProvider(mockStore.state, action)

        XCTAssertEqual(mockLogger.savedLevel, .warning)
        XCTAssertEqual(mockLogger.savedCategory, .certificate)
    }

    // MARK: - Helpers

    private func createSubject() -> NativeErrorPageMiddleware {
        return NativeErrorPageMiddleware(windowManager: mockWindowManager, logger: mockLogger)
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(windowUUID: .XCTestDefaultUUID)
                    )
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
