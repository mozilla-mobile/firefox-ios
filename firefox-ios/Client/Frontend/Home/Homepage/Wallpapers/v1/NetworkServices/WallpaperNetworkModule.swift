// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class WallpaperNetworkingModule: WallpaperNetworking {
    private var urlSession: URLSessionProtocol
    private var logger: Logger

    init(
        with urlSession: URLSessionProtocol = URLSession.sharedMPTCP,
        logger: Logger = DefaultLogger.shared
    ) {
        self.urlSession = urlSession
        self.logger = logger
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        do {
            logger.log(
                "Attempting to fetch wallpaper data",
                level: .debug,
                category: .wallpaper
            )
            let (data, response) = try await urlSession.data(from: url)

            guard let response = validatedHTTPResponse(
                response,
                statusCode: 200..<300
            ) else { throw URLError(.badServerResponse) }

            guard !data.isEmpty else { throw WallpaperServiceError.dataUnavailable }

            logger.log(
                "Wallpaper data fetched successfully",
                level: .debug,
                category: .wallpaper
            )

            return (data, response)
        } catch {
            throw error
        }
    }
}
