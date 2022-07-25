// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperImageLoader {

    enum ImageLoaderError: Error {
        case badData
    }

    // MARK: - Properties
    private let network: WallpaperNetworking

    // MARK: - Initializers
    init(networkModule: WallpaperNetworking) {
        self.network = networkModule
    }

    // MARK: - Methods
    func fetchImage(
        using scheme: String,
        andPath path: String
    ) async throws -> UIImage {
        guard let url = formatImageURLWith(scheme: scheme, andPath: path) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await network.data(from: url)

        guard let image = UIImage(data: data) else {
            throw ImageLoaderError.badData
        }

        return image
    }

    private func formatImageURLWith(scheme: String, andPath path: String) -> URL? {
        return URL(string: "\(scheme)\(path).png")
    }
}
