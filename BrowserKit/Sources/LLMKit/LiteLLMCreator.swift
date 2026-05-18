// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Shared
import MLPAKit

public protocol LiteLLMCreating {
    func createAppAttestLiteLLM(using prefs: Prefs, serviceType: MLPAServiceType) -> LiteLLMClientProtocol?
}

public struct LiteLLMCreator: LiteLLMCreating {
    public init() { }

    public func createAppAttestLiteLLM(using prefs: Prefs, serviceType: MLPAServiceType) -> LiteLLMClientProtocol? {
        let mlpaEnvironmentKey = prefs.stringForKey(PrefsKeys.MLPASettings.mlpaEndpointEnvironment) ?? ""
        let mlpaEnvironment = MLPAEnvironment(rawValue: mlpaEnvironmentKey) ?? .prod
        guard let endPoint = MLPAConstants.completionsEndpoint(with: mlpaEnvironment),
              let client = try? AppAttestClient(remoteServer: MLPAAppAttestServer(with: mlpaEnvironment)) else {
            return nil
        }
        let authenticator = AppAttestRequestAuth(appAttestClient: client, serviceType: serviceType)
        return LiteLLMClient(authenticator: authenticator, baseURL: endPoint)
    }
}
