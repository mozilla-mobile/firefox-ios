/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices
import XCTest

class FxAccountManagerTests: XCTestCase {
    func testStateTransitionsStart() {
        let state: AccountState = .start
        XCTAssertEqual(.start, FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchProfile(ignoreCache: false)))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .logout))
    }

    func testStateTransitionsNotAuthenticated() {
        let state: AccountState = .notAuthenticated
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchProfile(ignoreCache: false)))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))
    }

    func testStateTransitionsAuthenticatedNoProfile() {
        let state: AccountState = .authenticatedNoProfile
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertEqual(.authenticationProblem, FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .fetchProfile(ignoreCache: false)))
        XCTAssertEqual(.authenticatedWithProfile, FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))
    }

    func testStateTransitionsAuthenticatedWithProfile() {
        let state: AccountState = .authenticatedWithProfile
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertEqual(.authenticationProblem, FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertEqual(.authenticatedWithProfile, FxAccountManager.nextState(state: state, event: .fetchProfile(ignoreCache: false)))
        XCTAssertEqual(.authenticatedWithProfile, FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))
    }

    func testStateTransitionsAuthenticationProblem() {
        let state: AccountState = .authenticationProblem
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchProfile(ignoreCache: false)))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))
    }

    func testAccountNotFound() {
        let mgr = mockFxAManager()

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        let account = mgr.account as! MockFxAccount
        let constellation = mgr.constellation as! MockDeviceConstellation

        XCTAssertEqual(account.invocations, [])
        XCTAssertEqual(constellation.invocations, [])
    }

    func testAccountRestoration() {
        let mgr = mockFxAManager()
        let account = MockFxAccount()
        mgr.storedAccount = account

        expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Fetch devices is run async, so it could happen after getProfile, hence we don't do a strict
        // equality.
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.registerPersistCallback))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.ensureCapabilities))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.getProfile))

        let constellation = mgr.constellation as! MockDeviceConstellation
        XCTAssertEqual(constellation.invocations, [
            MockDeviceConstellation.MethodInvocation.ensureCapabilities,
            MockDeviceConstellation.MethodInvocation.refreshState,
        ])
    }

    func testAccountRestorationEnsureCapabilitiesNonAuthError() {
        class MockAccount: MockFxAccount {
            override func ensureCapabilities(supportedCapabilities _: [DeviceCapability]) throws {
                throw FxaError.Network(message: "The WiFi cable is detached.")
            }
        }
        let mgr = mockFxAManager()
        let account = MockAccount()
        mgr.storedAccount = account

        expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.registerPersistCallback))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.getProfile))

        let constellation = mgr.constellation as! MockDeviceConstellation
        XCTAssertEqual(constellation.invocations, [
            MockDeviceConstellation.MethodInvocation.ensureCapabilities,
            MockDeviceConstellation.MethodInvocation.refreshState,
        ])
    }

    func testAccountRestorationEnsureCapabilitiesAuthError() {
        class MockAccount: MockFxAccount {
            override func ensureCapabilities(supportedCapabilities _: [DeviceCapability]) throws {
                notifyAuthError()
                throw FxaError.Authentication(message: "Your token is expired yo.")
            }

            override func checkAuthorizationStatus() throws -> AuthorizationInfo {
                _ = try super.checkAuthorizationStatus()
                return AuthorizationInfo(active: false)
            }
        }
        let mgr = mockFxAManager()
        let account = MockAccount()
        mgr.storedAccount = account

        expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)
        expectation(forNotification: .accountAuthProblems, object: nil, handler: nil)

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertTrue(mgr.accountNeedsReauth())

        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.registerPersistCallback))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.getProfile))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.checkAuthorizationStatus))

        let constellation = mgr.constellation as! MockDeviceConstellation
        XCTAssertEqual(constellation.invocations, [
            MockDeviceConstellation.MethodInvocation.ensureCapabilities,
            MockDeviceConstellation.MethodInvocation.refreshState,
        ])
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

        let finishAuthDone = expectation(description: "finishAuthDone")
        mgr.finishAuthentication(authData: FxaAuthData(code: "bobo", state: "bobo", actionQueryParam: "email")) { result in
            if case .success = result {
                finishAuthDone.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)

        let account = mgr.account! as! MockFxAccount
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.registerPersistCallback))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.initializeDevice))
        XCTAssertTrue(account.invocations.contains(MockFxAccount.MethodInvocation.getProfile))

        let constellation = mgr.constellation as! MockDeviceConstellation
        XCTAssertEqual(constellation.invocations, [
            MockDeviceConstellation.MethodInvocation.initDevice,
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

        let finishAuthDone = expectation(description: "finishAuthDone")
        mgr.finishAuthentication(authData: FxaAuthData(code: "bobo", state: "NOTBOBO", actionQueryParam: "email")) { result in
            if case .failure = result {
                finishAuthDone.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
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
        mgr.storedAccount = account

        expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)

        let initDone = expectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertFalse(mgr.accountNeedsReauth())

        XCTAssertTrue(account.invocations.contains(MockAccount.MethodInvocation.checkAuthorizationStatus))
    }

    func testGetTokenServerEndpointURL() {
        class MockAccount: MockFxAccount {
            override func getTokenServerEndpointURL() throws -> URL {
                return URL(string: "https://token.services.mozilla.com/")!
            }
        }
        let mgr = mockFxAManager()
        let account = MockAccount()
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
