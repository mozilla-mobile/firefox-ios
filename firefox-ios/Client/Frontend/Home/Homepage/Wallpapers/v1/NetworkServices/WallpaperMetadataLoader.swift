// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperMetadataLoader: WallpaperMetadataCodableProtocol {
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
}
