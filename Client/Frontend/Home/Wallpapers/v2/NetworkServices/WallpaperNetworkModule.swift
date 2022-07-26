// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class WallpaperNetworkingModule: WallpaperNetworking {

    /// A basic async/await wrapper
    func data(from url: URL) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let response = response as? HTTPURLResponse,
                      (200...299).contains(response.statusCode)
                else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                guard let data = data,
                      !data.isEmpty
                else {
                    continuation.resume(throwing: WallpaperServiceError.dataUnavailable)
                    return
                }

                continuation.resume(returning: (data, response))

            }.resume()
        }
    }
}
