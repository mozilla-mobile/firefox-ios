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

    private(set) var isRunning = false

    init(
        logger: Logger = DefaultLogger.shared,
        accountManager: @escaping () -> FxAccountManager? = {
            RustFirefoxAccounts.shared.accountManager
        },
        clientConfig: VPNGuardian.Configuration = .prod
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
    }

    func start(privateOnly: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let pass = try await self.getPass()
                let server = Server(
                    hostname: "muc139.m1.fastly-masque.net",
                    port: 2499,
                    city: "MUC",
                    countryCode: "DE"
                )
                self.logger.log(
                    "Got Guardian proxy pass — expires \(pass.expiresAt), usage \(String(describing: pass.usage)); server \(server.hostname):\(server.port) (\(server.city), \(server.countryCode))",
                    level: .info,
                    category: .sync
                )
                let config = self.toProxyConf(server: server, pass: pass)
                let scope: ProxyScope = privateOnly ? .private : .all
                /**
                TODO: Ask the ios team for help here.
                 It seems webkit keeps a Connection Pool alive. So i.e if you load google.com, set the proxy and reload,
                 you might still have a connection to that server, and it will be re-used for the http request. Might need to invalidate it.
                 */
                DefaultWKEngineConfigurationProvider.applyProxyConfigurations([config], scope: scope)
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
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations([], scope: .all)
        isRunning = false
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
