// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol AccountsServiceProtocol {
    func registerVisit(accessToken: String) async throws -> AccountVisitResponse
}

public final class AccountsService: AccountsServiceProtocol {

    enum Error: Swift.Error {
        case network
        case invalidResponse
        case decodingError(String)
        case authenticationRequired
        case unauthorized
    }

    private let client: HTTPClient
    private let authenticationService: EcosiaAuthenticationService

    public init(client: HTTPClient = URLSessionHTTPClient(),
                authenticationService: EcosiaAuthenticationService = EcosiaAuthenticationService.shared) {
        self.client = client
        self.authenticationService = authenticationService
    }

    public func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        do {
            return try await performVisitRequest(accessToken: accessToken)
        } catch Error.unauthorized {
            EcosiaLogger.auth.info("Access token expired, attempting to renew credentials")
            do {
                try await authenticationService.renewCredentialsIfNeeded()
            } catch {
                EcosiaLogger.auth.error("Failed to renew credentials: \(error)")
                throw Error.authenticationRequired
            }

            guard let refreshedToken = authenticationService.accessToken, !refreshedToken.isEmpty else {
                EcosiaLogger.auth.error("Renewed credentials do not expose an access token")
                throw Error.authenticationRequired
            }

            return try await performVisitRequest(accessToken: refreshedToken)
        }
    }

    private func performVisitRequest(accessToken: String) async throws -> AccountVisitResponse {
        let request = AccountVisitRequest(accessToken: accessToken)

        EcosiaLogger.network.info("Making accounts visit request to: \(request.baseURL.absoluteString)\(request.path)")

        let (data, response) = try await client.perform(request)

        guard let response else {
            EcosiaLogger.network.error("Accounts visit request failed: No response received")
            throw Error.network
        }

        EcosiaLogger.network.info("Accounts visit response: status=\(response.statusCode), dataSize=\(data.count) bytes")

        switch response.statusCode {
        case 200:
            break
        case 401:
            EcosiaLogger.network.error("Accounts visit request unauthorized (401): Invalid or expired access token")
            throw Error.unauthorized
        case 403:
            EcosiaLogger.network.error("Accounts visit request forbidden (403): Valid token but insufficient permissions - check scopes")
            throw Error.unauthorized // We can treat 403 same as 401 for now
        default:
            EcosiaLogger.network.error("Accounts visit request failed with status: \(response.statusCode)")
            throw Error.network
        }

        do {
            let decodedResponse = try JSONDecoder().decode(AccountVisitResponse.self, from: data)
            EcosiaLogger.network.info("Accounts visit successful: seeds=\(decodedResponse.seeds.totalAmount), seedsModified=\(decodedResponse.seeds.isModified), level=\(decodedResponse.growthPoints.level.number), levelUp=\(decodedResponse.didLevelUp)")
            return decodedResponse
        } catch {
            EcosiaLogger.network.error("Accounts visit response decoding failed: \(error.localizedDescription)")
            if let responseString = String(data: data, encoding: .utf8) {
                EcosiaLogger.network.debug("Raw response data: \(responseString)")
            }
            throw Error.decodingError(error.localizedDescription)
        }
    }
}
