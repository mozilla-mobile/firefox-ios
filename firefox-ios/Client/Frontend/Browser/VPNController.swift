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
    enum VPNClientConfiguration {
        case prod
        case staging

        var guardianBaseURL: URL {
            switch self {
            case .prod, .staging: return URL(string: "https://vpn.mozilla.org")!
            }
        }
    }

    struct ProxyPass {
        let bearerToken: String
        let notBefore: Date
        let expiresAt: Date
        let rotationTime: Date
        let usage: ProxyUsage?
    }

    struct ProxyUsage {
        let max: Int64
        let remaining: Int64
        let reset: Date
    }

    struct Server {
        let hostname: String
        let port: UInt16
        let city: String
        let countryCode: String
    }

    private static let rotateBeforeExpiry: TimeInterval = 120

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
                    "Got Guardian proxy pass — expires \(pass.expiresAt), rotate at \(pass.rotationTime), usage \(String(describing: pass.usage)); server \(server.hostname):\(server.port) (\(server.city), \(server.countryCode))",
                    level: .info,
                    category: .sync
                )
                let config = self.toProxyConf(server: server, pass: pass)
                let scope: ProxyScope = privateOnly ? .private : .all
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
        cachedToken = nil
        isRunning = false
    }

    // MARK: - Proxy configuration

    private func toProxyConf(server: Server, pass: ProxyPass) -> ProxyConfiguration {
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

    // MARK: - Guardian proxy pass

    private func getPass() async throws -> ProxyPass {
        guard let acct = accountManagerProvider(), acct.hasAccount() else {
            throw VPNError.notSignedIn
        }
        let fxaToken = try await mintFxAToken(account: acct)
        return try await fetchProxyPass(fxaToken: fxaToken)
    }

    private func mintFxAToken(account: FxAccountManager) async throws -> String {
        let info: AccessTokenInfo = try await withCheckedThrowingContinuation { continuation in
            account.getAccessToken(scope: OAuthScope.vpn, useCache: false) { result in
                switch result {
                case .success(let info): continuation.resume(returning: info)
                case .failure(let err): continuation.resume(throwing: err)
                }
            }
        }
        cachedToken = info
        return info.token
    }

    private func fetchProxyPass(fxaToken: String) async throws -> ProxyPass {
        let url = clientConfig.guardianBaseURL.appendingPathComponent("api/v1/fpn/token")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(fxaToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VPNError.guardianBodyInvalid
        }
        guard http.statusCode == 200 else {
            throw VPNError.guardianHTTP(status: http.statusCode)
        }

        struct TokenResponse: Decodable { let token: String }
        let parsed: TokenResponse
        do {
            parsed = try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw VPNError.guardianBodyInvalid
        }

        let claims = try Self.decodeJWTClaims(parsed.token)
        let nbf = Date(timeIntervalSince1970: claims.nbf)
        let exp = Date(timeIntervalSince1970: claims.exp)
        let rotation = exp.addingTimeInterval(-Self.rotateBeforeExpiry)
        let usage = Self.parseUsage(headers: http.allHeaderFields)

        return ProxyPass(
            bearerToken: parsed.token,
            notBefore: nbf,
            expiresAt: exp,
            rotationTime: rotation,
            usage: usage
        )
    }

    private struct JWTClaims: Decodable {
        let nbf: TimeInterval
        let exp: TimeInterval
    }

    private static func decodeJWTClaims(_ jwt: String) throws -> JWTClaims {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { throw VPNError.guardianBodyInvalid }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard let data = Data(base64Encoded: payload) else { throw VPNError.guardianBodyInvalid }
        do {
            return try JSONDecoder().decode(JWTClaims.self, from: data)
        } catch {
            throw VPNError.guardianBodyInvalid
        }
    }

    private static func parseUsage(headers: [AnyHashable: Any]) -> ProxyUsage? {
        func header(_ name: String) -> String? {
            headers.first { ($0.key as? String)?.caseInsensitiveCompare(name) == .orderedSame }?.value as? String
        }
        guard let limit = header("X-Quota-Limit").flatMap(Int64.init),
              let remaining = header("X-Quota-Remaining").flatMap(Int64.init),
              let resetStr = header("X-Quota-Reset"),
              let reset = ISO8601DateFormatter().date(from: resetStr)
        else { return nil }
        return ProxyUsage(max: limit, remaining: remaining, reset: reset)
    }
}
