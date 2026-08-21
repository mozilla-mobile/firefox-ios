// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import DeviceCheck
import Foundation
import Shared

public protocol IPProtectionAuthCreating {
    func makeAuthService(using prefs: Prefs) -> IPProtectionAuthenticating?
    func makeProxyTokenService(using prefs: Prefs) -> IPProtectionProxyTokenFetching?
}

/// Assembles the IP Protection App Attest auth stack from `Prefs`.
public struct IPProtectionAuthCreator: IPProtectionAuthCreating {
    private let keyStore: AppAttestKeyIDStore
    private let appAttestService: AppAttestServiceProtocol
    private let tokenStore: IPProtectionTokenStore

    public init(
        keyStore: AppAttestKeyIDStore = KeychainAppAttestKeyIDStore(
            service: "org.mozilla.browserkit.ipprotection.appattest.keyid",
            account: "default"
        ),
        appAttestService: AppAttestServiceProtocol = DCAppAttestService.shared,
        tokenStore: IPProtectionTokenStore = KeychainIPProtectionTokenStore()
    ) {
        self.keyStore = keyStore
        self.appAttestService = appAttestService
        self.tokenStore = tokenStore
    }

    public func makeAuthService(using prefs: Prefs) -> IPProtectionAuthenticating? {
        let environment = resolveEnvironment(using: prefs)

        // One instance serves both the `AppAttestClient` transport and the refresh endpoint.
        let server = IPProtectionAppAttestServer(with: environment, tokenStore: tokenStore)

        guard let client = try? AppAttestClient(
            appAttestService: appAttestService,
            remoteServer: server,
            keyStore: keyStore
        ) else {
            return nil
        }
        return IPProtectionAuthService(
            appAttestClient: client,
            sessionRefresher: server,
            tokenStore: tokenStore
        )
    }

    public func makeProxyTokenService(using prefs: Prefs) -> IPProtectionProxyTokenFetching? {
        guard let authService = makeAuthService(using: prefs) else { return nil }
        return IPProtectionProxyTokenService(
            with: resolveEnvironment(using: prefs),
            authService: authService
        )
    }

    private func resolveEnvironment(using prefs: Prefs) -> IPProtectionEnvironment {
        let environmentKey = prefs.stringForKey(PrefsKeys.IPProtectionSettings.endpointEnvironment) ?? ""
        let environment = IPProtectionEnvironment(rawValue: environmentKey) ?? .prod
        resetKeyIfEnvironmentChanged(prefs: prefs, currentEnvironment: environment)
        return environment
    }

    /// Clears stored credentials when the environment changes, so the app re-attests against the
    /// correct server.
    private func resetKeyIfEnvironmentChanged(prefs: Prefs, currentEnvironment: IPProtectionEnvironment) {
        let lastUsedEnvironment = prefs.stringForKey(PrefsKeys.IPProtectionSettings.lastUsedEnvironment)
        let currentEnvironmentValue = currentEnvironment.rawValue

        if let lastUsedEnvironment, lastUsedEnvironment != currentEnvironmentValue {
            try? keyStore.clearKeyID()
            try? tokenStore.clear()
        }

        prefs.setString(currentEnvironmentValue, forKey: PrefsKeys.IPProtectionSettings.lastUsedEnvironment)
    }
}
