// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperMetadataLoader {
    static let versionEndpoint = "v1"

    private let network: WallpaperNetworking

    init(networkModule: WallpaperNetworking) {
        self.network = networkModule
    }

    func fetchMetadataWith(_ scheme: String) async throws -> WallpaperMetadata {
        guard let url = metadataPath(using: scheme) else { throw URLError(.badURL) }

        let (data, _) = try await network.data(from: url)

        return try decodeMetadata(from: data)
    }

    private func decodeMetadata(from data: Data) throws -> WallpaperMetadata {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        return try decoder.decode(WallpaperMetadata.self, from: data)
    }

    private func metadataPath(using scheme: String) -> URL? {
        return URL(string: "\(scheme)/metadata/\(WallpaperMetadataLoader.versionEndpoint)")
    }
}
