// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperMetadataLoader {

    // MARK: - Properties
    private let networkModule: WallpaperNetworking

    // MARK: - Initialization
    init(networkModule: WallpaperNetworking) {
        self.networkModule = networkModule
    }

    // MARK: - Interface

    /// Given a specified URL, it will attempt to reach out to the server, fetch the
    /// latest JSON, and return it as a `WallpaperMetadata` item
    func fetchMetadata(from url: URL) async throws -> WallpaperMetadata {
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
}
