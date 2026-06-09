/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices
import XCTest

class FxAccountManagerTests: XCTestCase {
    func testAccountNotFound() {
        let mgr = mockFxAManager()

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        let account = mgr.account as! MockFxAccount
        let constellation = mgr.constellation as! MockDeviceConstellation

        XCTAssertFalse(mgr.hasAccount())
        XCTAssertEqual(mgr.state, .disconnected)
        // processEvent should be called, but no device/profile calls
        XCTAssertTrue(account.invocations.contains(.processEvent))
        XCTAssertFalse(account.invocations.contains(.getProfile))
        XCTAssertEqual(constellation.invocations, [])
    }

    func testAccountRestoration() {
        let mgr = mockFxAManager()
        let account = MockFxAccount()
        account.initializeResult = .connected
        mgr.storedAccount = account

        expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertTrue(mgr.hasAccount())
        XCTAssertEqual(mgr.state, .connected)
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.registerPersistCallback))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.getProfile))

        let constellation = mgr.constellation as! MockDeviceConstellation
        // initDevice/ensureCapabilities are now handled by the Rust state machine internally;
        // only refreshState is called from postAuthenticated on the iOS side.
        XCTAssertEqual(constellation.invocations, [
            MockDeviceConstellation.MethodInvocation.refreshState,
        ])
    }

    func testAccountRestorationWithAuthIssues() {
        let mgr = mockFxAManager()
        let account = MockFxAccount()
        account.initializeResult = .authIssues
        mgr.storedAccount = account

        expectation(forNotification: .accountAuthProblems, object: nil, handler: nil)

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertTrue(mgr.accountNeedsReauth())
        XCTAssertEqual(mgr.state, .authIssues)
    }

    func testNewAccountLogIn() {
        let mgr = mockFxAManager()
        let beginAuthDone = expectation(description: "beginAuthDone")
        nonisolated(unsafe) var authURL: String?
        mgr.initialize { _ in
            mgr.beginAuthentication(entrypoint: "test_new_account_log_in") { url in
                authURL = try! url.get().absoluteString
                beginAuthDone.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(authURL, "https://foo.bar/oauth?state=bobo")

        expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)

        let finishAuthDone = expectation(description: "finishAuthDone")
        mgr.finishAuthentication(authData: FxaAuthData(code: "bobo", state: "bobo", actionQueryParam: "email")) { result in
            if case .success = result {
                finishAuthDone.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertTrue(mgr.hasAccount())
        XCTAssertEqual(mgr.state, .connected)

        let account = mgr.account! as! MockFxAccount
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.registerPersistCallback))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.getProfile))

        let constellation = mgr.constellation as! MockDeviceConstellation
        // initDevice is now handled by the Rust state machine internally;
        // only refreshState is called from postAuthenticated on the iOS side.
        XCTAssertEqual(constellation.invocations, [
            MockDeviceConstellation.MethodInvocation.refreshState,
        ])
    }

    func testAuthStateVerification() {
        let mgr = mockFxAManager()
        let beginAuthDone = expectation(description: "beginAuthDone")
        nonisolated(unsafe) var authURL: String?
        mgr.initialize { _ in
            mgr.beginAuthentication(entrypoint: "test_auth_state_verification") { url in
                authURL = try! url.get().absoluteString
                beginAuthDone.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(authURL, "https://foo.bar/oauth?state=bobo")

        // The mock simulates Rust's OAuth state validation: wrong state → disconnected.
        // finishAuthentication returns .failure when the FSM lands in a non-connected state.
        let finishAuthDone = expectation(description: "finishAuthDone")
        mgr.finishAuthentication(authData: FxaAuthData(code: "bobo", state: "NOTBOBO", actionQueryParam: "email")) { result in
            if case .failure = result {
                finishAuthDone.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)

        // State should be disconnected since wrong OAuth state was provided
        XCTAssertEqual(mgr.state, .disconnected)
        XCTAssertFalse(mgr.hasAccount())
    }

    func testProfileRecoverableAuthError() {
        class MockAccount: MockFxAccount {
            var profileCallCount = 0
            override func getProfile(ignoreCache: Bool) throws -> Profile {
                let profile = try super.getProfile(ignoreCache: ignoreCache)
                profileCallCount += 1
                if profileCallCount == 1 {
                    notifyAuthError()
                    throw FxaError.Authentication(message: "Uh oh.")
                } else {
                    return profile
                }
            }
        }
        let mgr = mockFxAManager()
        let account = MockAccount()
        account.initializeResult = .connected
        mgr.storedAccount = account

        // accountAuthenticated fires twice: once from the initial .initialize path, and again
        // after the auth error is recovered via .checkAuthorizationStatus.
        let authExpectation = expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        authExpectation.expectedFulfillmentCount = 2
        // accountProfileUpdate fires once: the first getProfile call throws (no notification posted),
        // and only the second successful call fires it.
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertFalse(mgr.accountNeedsReauth())

        // Read invocations through the same serial queue used for writes to avoid
        // a potential memory visibility issue on the main test thread.
        var hasCheckAuthStatus = false
        queue.sync { hasCheckAuthStatus = account.invocations.contains(.checkAuthorizationStatus) }
        XCTAssertTrue(hasCheckAuthStatus)
    }

    func testReLoginAfterLogout() {
        // Regression test: after logout, onDisconnected() creates a fresh account.
        // That account must be re-initialized so that beginAuthentication works again.
        let mgr = mockFxAManager()

        let initDone = expectation(description: "initDone")
        mgr.initialize { _ in initDone.fulfill() }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(mgr.state, .disconnected)

        // Simulate logout
        let logoutDone = expectation(description: "logoutDone")
        expectation(forNotification: .accountLoggedOut, object: nil, handler: nil)
        mgr.logout { _ in logoutDone.fulfill() }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(mgr.state, .disconnected)

        // After logout, sign in must still work (account was re-initialized by onDisconnected)
        let beginAuthDone = expectation(description: "beginAuthDone")
        nonisolated(unsafe) var authURL: String?
        mgr.beginAuthentication(entrypoint: "test_re_login_after_logout") { url in
            authURL = try? url.get().absoluteString
            beginAuthDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(authURL, "https://foo.bar/oauth?state=bobo",
                       "beginAuthentication must succeed after logout — onDisconnected must re-initialize the account")
    }

    func testGetTokenServerEndpointURL() {
        class MockAccount: MockFxAccount {
            override func getTokenServerEndpointURL() throws -> URL {
                return URL(string: "https://token.services.mozilla.com/")!
            }
        }
        let mgr = mockFxAManager()
        let account = MockAccount()
        account.initializeResult = .connected
        mgr.storedAccount = account

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        let tokenServerURLCorrect = expectation(description: "Server URL is correct")
        mgr.getTokenServerEndpointURL { url in
            XCTAssertEqual(
                try! url.get().absoluteString,
                "https://token.services.mozilla.com/1.0/sync/1.5"
            )
            tokenServerURLCorrect.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
