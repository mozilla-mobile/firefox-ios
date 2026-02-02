// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

enum UserDataDeletionError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
}

struct DeleteUserRequest: Encodable {
    let contextID: String

    enum CodingKeys: String, CodingKey {
        case contextID = "context_id"
    }
}

struct UnifiedAdsUserDataRemover: FeatureFlaggable {
    private static let prodResourceEndpoint = "https://ads.mozilla.org/v1/delete_user"
    private static let stagingResourceEndpoint = "https://ads.allizom.org/v1/delete_user"

    private let logger: Logger
    private let session: URLSessionProtocol

    init(session: URLSessionProtocol = NetworkUtils.defaultURLSession(),
         logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        self.session = session
    }

    func deleteUserData(contextID: String) async throws {
        guard let resourceEndpoint else {
            logger.log("Resource endpoint wasn't valid", level: .debug, category: .homepage)
            throw UserDataDeletionError.invalidURL
        }

        var request = URLRequest(url: resourceEndpoint)
        request.httpMethod = HTTPMethod.delete.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = DeleteUserRequest(contextID: contextID)
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await session.data(from: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.log("Didn't receive a proper http response", level: .debug, category: .homepage)
            throw UserDataDeletionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            logger.log("Didn't successfully delete user data", level: .warning, category: .homepage)
            throw UserDataDeletionError.serverError(statusCode: httpResponse.statusCode)
        }

        logger.log("Successfully deleted user data", level: .info, category: .homepage)
    }

    private var resourceEndpoint: URL? {
        if featureFlags.isCoreFeatureEnabled(.useStagingUnifiedAdsAPI) {
            return URL(string: UnifiedAdsUserDataRemover.stagingResourceEndpoint)
        }
        return URL(string: UnifiedAdsUserDataRemover.prodResourceEndpoint)
    }
}
