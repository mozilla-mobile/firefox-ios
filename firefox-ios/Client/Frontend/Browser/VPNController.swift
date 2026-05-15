// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Account
import Network
import WebEngine
import Foundation

@available(iOS 17.0, *)
@MainActor
final class VPNController: VPNControllerProtocol {
    private let logger: Logger
    private let accountManagerProvider: () -> FxAccountManager?
    private let guardian: VPNGuardian
    private let serverlist: VPNServerlist
    private let windowManager: WindowManager

    private(set) var isRunning = false

    init(
        logger: Logger = DefaultLogger.shared,
        accountManager: @escaping () -> FxAccountManager? = {
            RustFirefoxAccounts.shared.accountManager
        },
        rsService: RemoteSettingsService = (AppContainer.shared.resolve() as Profile).remoteSettingsService,
        clientConfig: VPNGuardian.Configuration = .prod,
        windowManager: WindowManager = AppContainer.shared.resolve()
    ) {
        self.logger = logger
        self.accountManagerProvider = accountManager
        self.guardian = VPNGuardian(
            authHeaderProvider: {
                let token = try await Self.mintFxAToken(accountManager: accountManager)
                return ["Authorization": "Bearer \(token)"]
            },
            configuration: clientConfig,
            logger: logger
        )
        self.serverlist = VPNServerlist(rsService: rsService, logger: logger)
        self.windowManager = windowManager
    }

    func start(privateOnly: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let pass = try await self.guardian.getPass()
                // TODO: If that fails with a 403, we must enroll the account into ff-vpn first.
                // let entitlement = try await self.guardian.activate()
                // self.logger.log("Entitlement: \(String(describing: entitlement))",
                //                level: .info,
                //                category: .sync)

                guard let server = self.serverlist.selectServer() else {
                    throw VPNError.noServerFound
                }

                self.logger.log(
                    "Got Guardian proxy pass — expires \(pass.expiresAt), usage \(String(describing: pass.usage)); server \(server.hostname):\(server.port) (\(server.city), \(server.countryCode))",
                    level: .info,
                    category: .sync
                )
                let config = self.toProxyConf(server: server, pass: pass)
                let scope: ProxyScope = privateOnly ? .private : .all
                await self.applyProxyAndRebuildWebViews(configs: [config], scope: scope)
                self.isRunning = true
                // TODO: Start a watcher to re-fetch and rotate the token before the lifetime ends.
                completion(.success(()))
            } catch {
                self.logger.log("VPN start failed: \(error)", level: .warning, category: .sync)
                completion(.failure(error))
            }
        }
    }

    func stop() {
        Task { [weak self] in
            guard let self else { return }
            await self.applyProxyAndRebuildWebViews(configs: [], scope: .all)
            self.isRunning = false
        }
    }

    private func applyProxyAndRebuildWebViews(configs: [ProxyConfiguration], scope: ProxyScope) async {
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations(
            configs,
            scope: scope
        )
        for tabManager in windowManager.allWindowTabManagers() {
            await tabManager.rebuildWebViewsForProxyChange()
        }
    }

    private func toProxyConf(server: VPNGuardian.Server, pass: VPNGuardian.ProxyPass) -> ProxyConfiguration {
        var components = URLComponents()
        components.scheme = "https"
        components.host = server.hostname
        components.port = Int(server.port)
        let endpoint = NWEndpoint.url(components.url!)
        let hop = ProxyConfiguration.RelayHop(
            http2RelayEndpoint: endpoint,
            // TODO: http3RelayEndpoint bricks it, we get quic errors, need to reach out to fstly
            tlsOptions: NWProtocolTLS.Options(),
            additionalHTTPHeaderFields: [
                "Proxy-Authorization": "Bearer \(pass.bearerToken)"
            ]
        )
        return ProxyConfiguration(relayHops: [hop])
    }

    private static func mintFxAToken(accountManager: () -> FxAccountManager?) async throws -> String {
        guard let acct = accountManager(), acct.hasAccount() else {
            throw VPNError.notSignedIn
        }
        let info: AccessTokenInfo = try await withCheckedThrowingContinuation { continuation in
            acct.getAccessToken(scope: OAuthScope.vpn, useCache: false) { result in
                switch result {
                case .success(let info): continuation.resume(returning: info)
                case .failure(let err): continuation.resume(throwing: err)
                }
            }
        }
        return info.token
    }
}
