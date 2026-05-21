// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Shared
import MLPAKit

public protocol LiteLLMCreating {
    func createAppAttestLiteLLM(using prefs: Prefs, serviceType: MLPAServiceType) -> LiteLLMClientProtocol?
}

public struct LiteLLMCreator: LiteLLMCreating {
    private let keyStore: AppAttestKeyIDStore
    public init(keyStore: AppAttestKeyIDStore = KeychainAppAttestKeyIDStore()) {
        self.keyStore = keyStore
    }

    public func createAppAttestLiteLLM(using prefs: Prefs, serviceType: MLPAServiceType) -> LiteLLMClientProtocol? {
        let mlpaEnvironmentKey = prefs.stringForKey(PrefsKeys.MLPASettings.mlpaEndpointEnvironment) ?? ""
        let mlpaEnvironment = MLPAEnvironment(rawValue: mlpaEnvironmentKey) ?? .prod

        print("🎯 [LiteLLMCreator] Creating client for environment: \(mlpaEnvironment.rawValue)")
        print("🎯 [LiteLLMCreator] Service type: \(serviceType.rawValue)")

        // Reset attestation key if environment has changed
        resetKeyIfEnvironmentChanged(prefs: prefs, currentEnvironment: mlpaEnvironment)

        guard let endPoint = MLPAConstants.completionsEndpoint(with: mlpaEnvironment),
              let client = try? AppAttestClient(
                remoteServer: MLPAAppAttestServer(with: mlpaEnvironment),
                keyStore: keyStore
              ) else {
            return nil
        }
        let authenticator = AppAttestRequestAuth(appAttestClient: client, serviceType: serviceType)
        return LiteLLMClient(authenticator: authenticator, baseURL: endPoint)
    }

    /// Resets the App Attest key if the MLPA environment has changed since last use.
    ///
    /// This ensures that when switching between environments (prod/staging/dev),
    /// the app will re-attest with the correct server.
    private func resetKeyIfEnvironmentChanged(prefs: Prefs, currentEnvironment: MLPAEnvironment) {
        let lastUsedEnv = prefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment)
        let currentEnvValue = currentEnvironment.rawValue

        print("🔑 [MLPA] Environment check - Last: \(lastUsedEnv ?? "none"), Current: \(currentEnvValue)")
        print("🔑 [MLPA] Key exists before check: \(keyStore.loadKeyID() != nil)")

        if let lastUsedEnv = lastUsedEnv, lastUsedEnv != currentEnvValue {
            // Environment changed - clear the attestation key to force re-attestation
            print("🔑 [MLPA] Environment changed! Clearing key...")
            try? keyStore.clearKeyID()
            print("🔑 [MLPA] Key exists after clear: \(keyStore.loadKeyID() != nil)")
        }

        // Update the last used environment
        prefs.setString(currentEnvValue, forKey: PrefsKeys.MLPASettings.lastUsedEnvironment)
    }
}
