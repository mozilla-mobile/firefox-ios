// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import AppAttestKit
import Common
import DeviceCheck
import Shared
import MLPAKit

public protocol LiteLLMCreating {
    func createAppAttestLiteLLM(
        using prefs: Prefs,
        serviceType: MLPAServiceType
    ) -> LiteLLMClientProtocol?
}

public struct LiteLLMCreator: LiteLLMCreating {
    private let keyStore: AppAttestKeyIDStore
    private let appAttestService: AppAttestServiceProtocol
    private let bundleIdentifier: String

    public init(
        keyStore: AppAttestKeyIDStore = KeychainAppAttestKeyIDStore(),
        appAttestService: AppAttestServiceProtocol = DCAppAttestService.shared,
        bundleIdentifier: String = AppInfo.bundleIdentifier
    ) {
        self.keyStore = keyStore
        self.appAttestService = appAttestService
        self.bundleIdentifier = bundleIdentifier
    }

    public func createAppAttestLiteLLM(
        using prefs: Prefs,
        serviceType: MLPAServiceType
    ) -> LiteLLMClientProtocol? {
        let mlpaEnvironmentKey = prefs.stringForKey(PrefsKeys.MLPASettings.mlpaEndpointEnvironment) ?? ""
        let mlpaEnvironment = MLPAEnvironment(rawValue: mlpaEnvironmentKey) ?? .prod

        // Reset attestation key if environment has changed, so the app re-attests with the
        // correct server
        prefs.resetIfEnvironmentChanged(
            mlpaEnvironment.rawValue,
            forKey: PrefsKeys.MLPASettings.lastUsedEnvironment
        ) {
            try? keyStore.clearKeyID()
        }

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
}
