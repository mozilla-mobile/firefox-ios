// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperMetadataLoader {

    // MARK: - Properties
    enum WallpaperMetadataEndpoint: String {
        case v1
    }

    private let networkModule: WallpaperNetworking

    // MARK: - Initialization
    init(networkModule: WallpaperNetworking) {
        self.networkModule = networkModule
    }

    // MARK: - Interface

    /// Given a specified URL, it will attempt to reach out to the server, fetch the
    /// latest JSON, and return it as a `WallpaperMetadata` item
    func fetchMetadataWith(_ scheme: String) async throws -> WallpaperMetadata {
        guard let url = metadataPath(using: scheme) else { throw URLError(.badURL) }

        let (data, _) = try await networkModule.data(from: url)

        return try decodeMetadata(from: data)
    }

    // MARK: - Private methods

    /// Given some data, if that data is a valid JSON file, it attempts to decode it
    /// into a `WallpaperMetadata` object
    private func decodeMetadata(from data: Data) throws -> WallpaperMetadata {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        return try decoder.decode(WallpaperMetadata.self, from: data)
    }

    /// Builds the path to the metadata endpoint on the server
    private func metadataPath(using scheme: String) -> URL? {
        return URL(string: "\(scheme)/metadata/\(WallpaperMetadataEndpoint.v1.rawValue)/")
    }
}
