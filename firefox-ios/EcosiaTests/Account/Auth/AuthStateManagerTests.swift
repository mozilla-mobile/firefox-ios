// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation
import Common
@testable import Ecosia

final class AuthStateManagerTests: XCTestCase {

    var authStateManager: EcosiaBrowserWindowAuthManager!
    var testWindowUUID: WindowUUID!

    override func setUp() {
        super.setUp()
        authStateManager = EcosiaBrowserWindowAuthManager.shared
        testWindowUUID = WindowUUID.XCTestDefaultUUID

        // Clean state before each test
        authStateManager.clearAllStates()
    }

    override func tearDown() {
        authStateManager.clearAllStates()
        authStateManager = nil
        testWindowUUID = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Test that no state exists initially for our test window
        let authState = authStateManager.getAuthState(for: testWindowUUID)
        XCTAssertNil(authState)

        // Test that all states dictionary is empty
        let allStates = authStateManager.getAllAuthStates()
        XCTAssertTrue(allStates.isEmpty)
    }

    // MARK: - State Dispatch Tests

    func testDispatchAuthStateLoaded_createsNewState() {
        // Dispatch auth state loaded action
        let action = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Verify state was created
        let authState = authStateManager.getAuthState(for: testWindowUUID)
        XCTAssertNotNil(authState)
        XCTAssertEqual(authState?.windowUUID, testWindowUUID)
        XCTAssertTrue(authState?.isLoggedIn ?? false)
        XCTAssertTrue(authState?.authStateLoaded ?? false)
    }

    func testDispatchUserLoggedIn_updatesExistingState() {
        // Create initial state
        let initialAction = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID,
            isLoggedIn: false
        )
        authStateManager.dispatch(action: initialAction, for: testWindowUUID)

        // Dispatch login action
        let loginAction = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )
        authStateManager.dispatch(action: loginAction, for: testWindowUUID)

        // Verify state was updated
        let authState = authStateManager.getAuthState(for: testWindowUUID)
        XCTAssertTrue(authState?.isLoggedIn ?? false)
        XCTAssertTrue(authState?.authStateLoaded ?? false)
    }

    func testDispatchUserLoggedOut_updatesExistingState() {
        // Create initial logged in state
        let initialAction = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )
        authStateManager.dispatch(action: initialAction, for: testWindowUUID)

        // Dispatch logout action
        let logoutAction = AuthStateAction(
            type: .userLoggedOut,
            windowUUID: testWindowUUID,
            isLoggedIn: false
        )
        authStateManager.dispatch(action: logoutAction, for: testWindowUUID)

        // Verify state was updated
        let authState = authStateManager.getAuthState(for: testWindowUUID)
        XCTAssertFalse(authState?.isLoggedIn ?? true)
    }

    // MARK: - Notification Tests

    func testDispatch_postsNotification() {
        let expectation = XCTestExpectation(description: "Notification posted")

        let observer = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: authStateManager,
            queue: .main
        ) { notification in
            // Verify notification contains expected data
            let userInfo = notification.userInfo
            XCTAssertEqual(userInfo?["windowUUID"] as? WindowUUID, self.testWindowUUID)
            XCTAssertEqual(userInfo?["actionType"] as? EcosiaAuthActionType, .authStateLoaded)
            XCTAssertNotNil(userInfo?["authState"] as? AuthWindowState)

            expectation.fulfill()
        }

        // Dispatch action
        let action = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )
        authStateManager.dispatch(action: action, for: testWindowUUID)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Multi-Window Tests

    func testMultipleWindows_separateStates() {
        let window1 = WindowUUID()
        let window2 = WindowUUID()

        // Create different states for each window
        let action1 = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: window1,
            isLoggedIn: true
        )
        let action2 = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: window2,
            isLoggedIn: false
        )

        authStateManager.dispatch(action: action1, for: window1)
        authStateManager.dispatch(action: action2, for: window2)

        // Verify states are separate
        let state1 = authStateManager.getAuthState(for: window1)
        let state2 = authStateManager.getAuthState(for: window2)

        XCTAssertTrue(state1?.isLoggedIn ?? false)
        XCTAssertFalse(state2?.isLoggedIn ?? true)
        XCTAssertEqual(authStateManager.getAllAuthStates().count, 2)
    }

    // MARK: - State Cleanup Tests

    func testRemoveWindowState() {
        // Create state
        let action = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Verify state exists
        XCTAssertNotNil(authStateManager.getAuthState(for: testWindowUUID))

        // Remove state
        authStateManager.removeWindowState(for: testWindowUUID)

        // Verify state was removed
        XCTAssertNil(authStateManager.getAuthState(for: testWindowUUID))
    }

    func testClearAllStates() {
        // Create multiple states
        let window1 = WindowUUID()
        let window2 = WindowUUID()

        let action1 = AuthStateAction(type: .authStateLoaded, windowUUID: window1, isLoggedIn: true)
        let action2 = AuthStateAction(type: .authStateLoaded, windowUUID: window2, isLoggedIn: false)

        authStateManager.dispatch(action: action1, for: window1)
        authStateManager.dispatch(action: action2, for: window2)

        // Verify states exist
        XCTAssertEqual(authStateManager.getAllAuthStates().count, 2)

        // Clear all states
        authStateManager.clearAllStates()

        // Verify all states were cleared
        XCTAssertTrue(authStateManager.getAllAuthStates().isEmpty)
    }

    // MARK: - Integration with AuthStateManager.dispatchAuthState Tests

    func testDispatchAuthState_multipleBrowserWindows() {
        // Register multiple windows in the registry
        let window1 = WindowUUID()
        let window2 = WindowUUID()

        EcosiaAuthWindowRegistry.shared.registerWindow(window1)
        EcosiaAuthWindowRegistry.shared.registerWindow(window2)

        // Dispatch auth state to all windows
        authStateManager.dispatchAuthState(isLoggedIn: true, actionType: .userLoggedIn)

        // Verify both windows received the state
        let state1 = authStateManager.getAuthState(for: window1)
        let state2 = authStateManager.getAuthState(for: window2)

        XCTAssertTrue(state1?.isLoggedIn ?? false)
        XCTAssertTrue(state2?.isLoggedIn ?? false)

        // Cleanup
        EcosiaAuthWindowRegistry.shared.unregisterWindow(window1)
        EcosiaAuthWindowRegistry.shared.unregisterWindow(window2)
    }
}

// MARK: - Test Helpers

extension WindowUUID {
    static let XCTestDefaultUUID = WindowUUID()
}
