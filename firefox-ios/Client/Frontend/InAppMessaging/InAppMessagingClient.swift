// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol InAppMessagingClientProtocol {
    func fetchManifest() async throws -> InAppMessagingManifest
}

final class InAppMessagingClient: InAppMessagingClientProtocol {
    private let manifestURL: URL
    private let urlSession: URLSessionProtocol
    private let logger: Logger

    init(
        manifestURL: URL,
        urlSession: URLSessionProtocol = URLSession.sharedMPTCP,
        logger: Logger = DefaultLogger.shared
    ) {
        self.manifestURL = manifestURL
        self.urlSession = urlSession
        self.logger = logger
    }

    func fetchManifest() async throws -> InAppMessagingManifest {
        let (data, response) = try await urlSession.data(from: manifestURL)

        guard validatedHTTPResponse(response, statusCode: 200..<300) != nil else {
            logger.log(
                "In-app messaging manifest fetch failed with invalid response",
                level: .warning,
                category: .lifecycle
            )
            throw InAppMessagingError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(InAppMessagingManifest.self, from: data)
    }
}

enum InAppMessagingError: Error {
    case invalidResponse
    case noMessagesAvailable
}
