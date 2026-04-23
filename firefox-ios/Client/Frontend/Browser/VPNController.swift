// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Account
import Network
import WebEngine
import Foundation

@MainActor
final class VPNController: VPNControllerProtocol {
    enum VPNClientConfiguration {
        case prod
        case staging
    }

    enum VPNError: Error {
        case unsupportedOS
        case notSignedIn
    }

    private let logger: Logger
    private let accountManagerProvider: () -> FxAccountManager?
    private let clientConfig: VPNClientConfiguration

    private(set) var isRunning = false
    private var cachedToken: AccessTokenInfo?

    init(
        logger: Logger = DefaultLogger.shared,
        accountManager: @escaping () -> FxAccountManager? = {
            RustFirefoxAccounts.shared.accountManager
        },
        clientConfig: VPNClientConfiguration = .prod
    ) {
        self.logger = logger
        self.accountManagerProvider = accountManager
        self.clientConfig = clientConfig
    }

    func start(privateOnly: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        guard #available(iOS 17.0, *) else {
            completion(.failure(VPNError.unsupportedOS))
            return
        }
        guard let acct = accountManagerProvider(), acct.hasAccount() else {
            completion(.failure(VPNError.notSignedIn))
            return
        }
        acct.getAccessToken(scope: OAuthScope.vpn, useCache: false) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.logger.log("VPN token mint failed: \(error)", level: .warning, category: .sync)
                completion(.failure(error))
            case .success(let tokenInfo):
                self.cachedToken = tokenInfo
                if #available(iOS 17.0, *) {
                    let configs = self.buildProxyConfigurations(token: tokenInfo.token)
                    let scope: ProxyScope = privateOnly ? .private : .all
                    DefaultWKEngineConfigurationProvider.applyProxyConfigurations(configs, scope: scope)
                }
                self.isRunning = true
                completion(.success(()))
            }
        }
    }

    func stop() {
        if #available(iOS 17.0, *) {
            DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], scope: .all)
        }
        cachedToken = nil
        isRunning = false
    }

    // Confirm exact proxy endpoint + auth scheme with the Mozilla VPN team before filling this in.
    @available(iOS 17.0, *)
    private func buildProxyConfigurations(token: String) -> [ProxyConfiguration] {
        return []
    }
}
