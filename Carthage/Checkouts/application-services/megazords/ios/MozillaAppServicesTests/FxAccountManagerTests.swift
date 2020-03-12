/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

@testable import MozillaAppServices

class FxAccountManagerTests: XCTestCase {
    func testStateTransitionsStart() {
        let state: AccountState = .start
        XCTAssertEqual(.start, FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))

        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticateViaMigration(sessionToken: "foo", kSync: "bar", kXCS: "bobo")))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticatedViaMigration))
        XCTAssertEqual(.canAutoretryMigration, FxAccountManager.nextState(state: state, event: .inFlightMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigrationLater))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigration))
    }

    func testStateTransitionsNotAuthenticated() {
        let state: AccountState = .notAuthenticated
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))

        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .authenticateViaMigration(sessionToken: "foo", kSync: "bar", kXCS: "bobo")))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .authenticatedViaMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .inFlightMigration))
        XCTAssertEqual(.canAutoretryMigration, FxAccountManager.nextState(state: state, event: .retryMigrationLater))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigration))
    }

    func testStateTransitionsAuthenticatedNoProfile() {
        let state: AccountState = .authenticatedNoProfile
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertEqual(.authenticationProblem, FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .fetchProfile))
        XCTAssertEqual(.authenticatedWithProfile, FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))

        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticateViaMigration(sessionToken: "foo", kSync: "bar", kXCS: "bobo")))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticatedViaMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .inFlightMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigrationLater))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigration))
    }

    func testStateTransitionsAuthenticatedWithProfile() {
        let state: AccountState = .authenticatedWithProfile
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertEqual(.authenticationProblem, FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))

        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticateViaMigration(sessionToken: "foo", kSync: "bar", kXCS: "bobo")))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticatedViaMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .inFlightMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigrationLater))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigration))
    }

    func testStateTransitionsAuthenticationProblem() {
        let state: AccountState = .authenticationProblem
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))

        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticateViaMigration(sessionToken: "foo", kSync: "bar", kXCS: "bobo")))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticatedViaMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .inFlightMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigrationLater))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .retryMigration))
    }

    func testStateTransitionscanAutoretryMigration() {
        let state: AccountState = .canAutoretryMigration
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .initialize))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountNotFound))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .accountRestored))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticated(authData: FxaAuthData(code: "foo", state: "bar", actionQueryParam: "bobo"))))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticationError))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .fetchedProfile))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .failedToFetchProfile))
        XCTAssertEqual(.notAuthenticated, FxAccountManager.nextState(state: state, event: .logout))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .recoveredFromAuthenticationProblem))

        XCTAssertNil(FxAccountManager.nextState(state: state, event: .authenticateViaMigration(sessionToken: "foo", kSync: "bar", kXCS: "bobo")))
        XCTAssertEqual(.authenticatedNoProfile, FxAccountManager.nextState(state: state, event: .authenticatedViaMigration))
        XCTAssertNil(FxAccountManager.nextState(state: state, event: .inFlightMigration))
        XCTAssertEqual(.canAutoretryMigration, FxAccountManager.nextState(state: state, event: .retryMigrationLater))
        XCTAssertEqual(.canAutoretryMigration, FxAccountManager.nextState(state: state, event: .retryMigration))
    }

    func testAccountNotFound() {
        let mgr = mockFxAManager()

        let initDone = XCTestExpectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        wait(for: [initDone], timeout: 5)

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

        let initDone = XCTestExpectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        wait(for: [initDone], timeout: 5)
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
                throw FirefoxAccountError.network(message: "The WiFi cable is detached.")
            }
        }
        let mgr = mockFxAManager()
        let account = MockAccount()
        mgr.storedAccount = account

        expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)

        let initDone = XCTestExpectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        wait(for: [initDone], timeout: 5)
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
                throw FirefoxAccountError.unauthorized(message: "Your token is expired yo.")
            }

            override func checkAuthorizationStatus() throws -> IntrospectInfo {
                _ = try super.checkAuthorizationStatus()
                return IntrospectInfo(active: false, tokenType: "refresh_token")
            }
        }
        let mgr = mockFxAManager()
        let account = MockAccount()
        mgr.storedAccount = account

        expectation(forNotification: .accountAuthenticated, object: nil, handler: nil)
        expectation(forNotification: .accountProfileUpdate, object: nil, handler: nil)
        expectation(forNotification: .accountAuthProblems, object: nil, handler: nil)

        let initDone = XCTestExpectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        wait(for: [initDone], timeout: 5)
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
        let beginAuthDone = XCTestExpectation(description: "beginAuthDone")
        var authURL: String?
        mgr.initialize { _ in
            mgr.beginAuthentication { url in
                authURL = try! url.get().absoluteString
                beginAuthDone.fulfill()
            }
        }
        wait(for: [beginAuthDone], timeout: 5)
        XCTAssertEqual(authURL, "https://foo.bar/oauth?state=bobo")

        let finishAuthDone = XCTestExpectation(description: "finishAuthDone")
        mgr.finishAuthentication(authData: FxaAuthData(code: "bobo", state: "bobo", actionQueryParam: "email")) { result in
            if case .success = result {
                finishAuthDone.fulfill()
            }
        }
        wait(for: [finishAuthDone], timeout: 5)

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
        let beginAuthDone = XCTestExpectation(description: "beginAuthDone")
        var authURL: String?
        mgr.initialize { _ in
            mgr.beginAuthentication { url in
                authURL = try! url.get().absoluteString
                beginAuthDone.fulfill()
            }
        }
        wait(for: [beginAuthDone], timeout: 5)
        XCTAssertEqual(authURL, "https://foo.bar/oauth?state=bobo")

        let finishAuthDone = XCTestExpectation(description: "finishAuthDone")
        mgr.finishAuthentication(authData: FxaAuthData(code: "bobo", state: "NOTBOBO", actionQueryParam: "email")) { result in
            if case .failure = result {
                finishAuthDone.fulfill()
            }
        }
        wait(for: [finishAuthDone], timeout: 5)
    }

    func testProfileRecoverableAuthError() {
        class MockAccount: MockFxAccount {
            var profileCallCount = 0
            override func getProfile() throws -> Profile {
                let profile = try super.getProfile()
                profileCallCount += 1
                if profileCallCount == 1 {
                    notifyAuthError()
                    throw FirefoxAccountError.unauthorized(message: "Uh oh.")
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

        let initDone = XCTestExpectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        wait(for: [initDone], timeout: 5)
        waitForExpectations(timeout: 10, handler: nil)

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

        let initDone = XCTestExpectation(description: "Initialization done")
        mgr.initialize { _ in
            initDone.fulfill()
        }
        wait(for: [initDone], timeout: 10)

        let url = try! mgr.getTokenServerEndpointURL().get()
        XCTAssertEqual(
            url.absoluteString,
            "https://token.services.mozilla.com/1.0/sync/1.5"
        )
    }
}
