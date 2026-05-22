// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import DeviceCheck
import Shared
import MLPAKit

public protocol LiteLLMCreating {
    func createAppAttestLiteLLM(
        using prefs: Prefs,
        serviceType: MLPAServiceType,
        bundleIdentifier: String
    ) -> LiteLLMClientProtocol?
}

public extension LiteLLMCreating {
    func createAppAttestLiteLLM(
        using prefs: Prefs,
        serviceType: MLPAServiceType,
        bundleIdentifier: String = AppInfo.bundleIdentifier
    ) -> LiteLLMClientProtocol? {
        createAppAttestLiteLLM(using: prefs, serviceType: serviceType, bundleIdentifier: bundleIdentifier)
    }
}

public struct LiteLLMCreator: LiteLLMCreating {
    private let keyStore: AppAttestKeyIDStore
    private let appAttestService: AppAttestServiceProtocol

    public init(
        keyStore: AppAttestKeyIDStore = KeychainAppAttestKeyIDStore(),
        appAttestService: AppAttestServiceProtocol = DCAppAttestService.shared
    ) {
        self.keyStore = keyStore
        self.appAttestService = appAttestService
    }

    public func createAppAttestLiteLLM(
        using prefs: Prefs,
        serviceType: MLPAServiceType,
        bundleIdentifier: String
    ) -> LiteLLMClientProtocol? {
        let mlpaEnvironmentKey = prefs.stringForKey(PrefsKeys.MLPASettings.mlpaEndpointEnvironment) ?? ""
        let mlpaEnvironment = MLPAEnvironment(rawValue: mlpaEnvironmentKey) ?? .prod

        // Reset attestation key if environment has changed
        resetKeyIfEnvironmentChanged(prefs: prefs, currentEnvironment: mlpaEnvironment)

        guard let endPoint = MLPAConstants.completionsEndpoint(with: mlpaEnvironment),
              let client = try? AppAttestClient(
                appAttestService: appAttestService,
                remoteServer: MLPAAppAttestServer(with: mlpaEnvironment, bundleIdentifier: bundleIdentifier),
                keyStore: keyStore
              ) else {
            return nil
        }
        let authenticator = AppAttestRequestAuth(
            appAttestClient: client,
            bundleIdentifier: bundleIdentifier,
            serviceType: serviceType
        )
        return LiteLLMClient(authenticator: authenticator, baseURL: endPoint)
    }

    /// Resets the App Attest key if the MLPA environment has changed since last use.
    ///
    /// This ensures that when switching between environments (prod/staging/dev),
    /// the app will re-attest with the correct server.
    private func resetKeyIfEnvironmentChanged(prefs: Prefs, currentEnvironment: MLPAEnvironment) {
        let lastUsedEnvironment = prefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment)
        let currentEnvironmentValue = currentEnvironment.rawValue

        if let lastUsedEnvironment, lastUsedEnvironment != currentEnvironmentValue {
            try? keyStore.clearKeyID()
        }

        prefs.setString(currentEnvironmentValue, forKey: PrefsKeys.MLPASettings.lastUsedEnvironment)
    }
}
