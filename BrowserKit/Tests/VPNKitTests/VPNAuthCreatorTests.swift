// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Shared
import TestKit
import XCTest

@testable import VPNKit

final class VPNAuthCreatorTests: XCTestCase {
    private let keyStore = MockAppAttestKeyIDStore()
    private let tokenStore = MockVPNTokenStore()
    private let prefs = MockProfilePrefs()

    // MARK: - Environment resolution

    func test_makeAuthService_defaultsToProd_whenNoEnvironmentSet() {
        let result = createSubject().makeAuthService(using: prefs)

        XCTAssertNotNil(result)
        XCTAssertEqual(
            prefs.stringForKey(PrefsKeys.VPNSettings.lastUsedEnvironment),
            VPNEnvironment.prod.rawValue,
            "An absent override is how the debug setting encodes production"
        )
    }

    func test_makeAuthService_usesStoredEnvironment() {
        prefs.setString(VPNEnvironment.stage.rawValue, forKey: PrefsKeys.VPNSettings.endpointEnvironment)

        let result = createSubject().makeAuthService(using: prefs)

        XCTAssertNotNil(result)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.VPNSettings.lastUsedEnvironment), VPNEnvironment.stage.rawValue)
    }

    func test_makeAuthService_defaultsToProd_whenEnvironmentUnrecognized() {
        prefs.setString("not-an-environment", forKey: PrefsKeys.VPNSettings.endpointEnvironment)

        let result = createSubject().makeAuthService(using: prefs)

        XCTAssertNotNil(result)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.VPNSettings.lastUsedEnvironment), VPNEnvironment.prod.rawValue)
    }

    // MARK: - Credential reset on environment change

    func test_makeAuthService_clearsKeyAndSession_whenEnvironmentChanged() throws {
        try keyStore.saveKeyID(AppAttestTestData.keyID)
        try tokenStore.save(session)
        prefs.setString(VPNEnvironment.stage.rawValue, forKey: PrefsKeys.VPNSettings.lastUsedEnvironment)

        _ = createSubject().makeAuthService(using: prefs)

        XCTAssertNil(keyStore.loadKeyID(), "Credentials are only valid against the environment that issued them")
        XCTAssertNil(tokenStore.load())
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.VPNSettings.lastUsedEnvironment), VPNEnvironment.prod.rawValue)
    }

    func test_makeAuthService_keepsCredentials_whenEnvironmentUnchanged() throws {
        try keyStore.saveKeyID(AppAttestTestData.keyID)
        try tokenStore.save(session)
        prefs.setString(VPNEnvironment.prod.rawValue, forKey: PrefsKeys.VPNSettings.lastUsedEnvironment)

        _ = createSubject().makeAuthService(using: prefs)

        XCTAssertEqual(keyStore.loadKeyID(), AppAttestTestData.keyID)
        XCTAssertEqual(tokenStore.load(), session)
    }

    func test_makeAuthService_keepsCredentials_onFirstRun() throws {
        try keyStore.saveKeyID(AppAttestTestData.keyID)

        _ = createSubject().makeAuthService(using: prefs)

        XCTAssertEqual(keyStore.loadKeyID(), AppAttestTestData.keyID, "Nothing recorded yet means nothing to invalidate")
    }

    // MARK: - Proxy token service

    func test_makeProxyTokenService_returnsService() {
        XCTAssertNotNil(createSubject().makeProxyTokenService(using: prefs))
    }

    func test_makeProxyTokenService_resetsCredentialsOnce_whenEnvironmentChanged() throws {
        try tokenStore.save(session)
        prefs.setString(VPNEnvironment.dev.rawValue, forKey: PrefsKeys.VPNSettings.lastUsedEnvironment)

        _ = createSubject().makeProxyTokenService(using: prefs)

        XCTAssertEqual(tokenStore.clearCallCount, 1, "Building both services must not clear the store twice")
    }

    // MARK: - Unsupported devices

    func test_makeAuthService_returnsNil_whenAppAttestUnsupported() {
        let subject = createSubject(appAttestService: MockAppAttestService(isSupported: false))

        XCTAssertNil(subject.makeAuthService(using: prefs))
        XCTAssertNil(subject.makeProxyTokenService(using: prefs))
    }

    // MARK: - Helpers

    private var session: VPNDeviceSession {
        VPNDeviceSession(
            deviceSessionJwt: "dsj",
            expiresAtMilliseconds: 32503680000000,
            renewAfterMilliseconds: 32503600000000
        )
    }

    private func createSubject(
        appAttestService: AppAttestServiceProtocol = MockAppAttestService(isSupported: true)
    ) -> VPNAuthCreator {
        return VPNAuthCreator(
            keyStore: keyStore,
            appAttestService: appAttestService,
            tokenStore: tokenStore,
            bundleIdentifier: "org.mozilla.ios.Test"
        )
    }
}
