// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

import class MozillaAppServices.FxAccountManager
import enum MozillaAppServices.OAuthScope

@MainActor
protocol FxAOAuthAuthenticating: AnyObject {
    func beginAuthentication(entrypoint: String,
                             scopes: [String],
                             completionHandler: @escaping @MainActor @Sendable (Result<URL, Error>) -> Void
    )
}

extension FxAccountManager: FxAOAuthAuthenticating {}

enum FxAPairingOAuthHandlerError: Error, Sendable {
    case failedToStart
}

@MainActor
final class FxAPairingOAuthHandler {
    static let errorMessage = "Failed to begin a pairing OAuth flow"

    private static let entrypoint = "webchannel-pairing"
    private static let scopes = [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session]
    private static let parameterNames = ["state", "scope", "code_challenge", "code_challenge_method", "keys_jwk"]

    private let authenticatorProvider: () -> FxAOAuthAuthenticating?
    private let logger: Logger

    init(authenticatorProvider: @escaping () -> FxAOAuthAuthenticating?,
         logger: Logger = DefaultLogger.shared) {
        self.authenticatorProvider = authenticatorProvider
        self.logger = logger
    }

    func start(
        completion: @escaping @MainActor @Sendable (Result<[String: String], FxAPairingOAuthHandlerError>) -> Void
    ) {
        guard let authenticator = authenticatorProvider() else {
            completion(.failure(.failedToStart))
            return
        }

        authenticator.beginAuthentication(
            entrypoint: Self.entrypoint,
            scopes: Self.scopes
        ) { [weak self] result in
            // The page is waiting on this reply, so a deallocated handler must still resolve it.
            guard let self else {
                completion(.failure(.failedToStart))
                return
            }

            switch result {
            case .success(let url):
                guard let parameters = parameters(from: url) else {
                    completion(.failure(.failedToStart))
                    return
                }
                completion(.success(parameters))
            case .failure(let error):
                logger.log("Failed to begin a pairing OAuth flow: \(error.localizedDescription)",
                           level: .warning,
                           category: .sync)
                completion(.failure(.failedToStart))
            }
        }
    }

    func parameters(from url: URL) -> [String: String]? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        var parameters = [String: String]()

        for name in Self.parameterNames {
            guard let value = components.queryItems?.first(where: { $0.name == name })?.value else {
                logger.log("Pairing OAuth URL is missing the \(name) parameter", level: .warning, category: .sync)
                return nil
            }
            parameters[name] = value
        }

        return parameters
    }
}
