// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol HTMLDataRequest {
    func fetchDataForURL(_ url: URL) async throws -> Data
}

struct DefaultHTMLDataRequest: HTMLDataRequest {
    enum RequestConstants {
        static let timeout: TimeInterval = 5

        // swiftlint:disable line_length
        static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"
        // swiftlint:enable line_length
    }

    func fetchDataForURL(_ url: URL) async throws -> Data {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["User-Agent": RequestConstants.userAgent]
        configuration.timeoutIntervalForRequest = RequestConstants.timeout
        configuration.multipathServiceType = .handover

        let urlSession = URLSession(configuration: configuration)

        return try await withCheckedThrowingContinuation { continuation in
            urlSession.dataTask(with: url) { data, _, error in
                guard let data = data,
                      error == nil
                else {
                    continuation.resume(throwing: SiteImageError.invalidHTML)
                    return
                }
                continuation.resume(returning: data)
            }.resume()
        }
    }
}
