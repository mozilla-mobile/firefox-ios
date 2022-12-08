// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

///  Responsible for fetching data from the server.
class WallpaperDataService {
    // MARK: - Properties
    enum DataServiceError: Error {
        case noBundledURL
    }

    private let networking: WallpaperNetworking
    private let wallpaperURLScheme = "MozWallpaperURLScheme"

    // MARK: - Initializers
    init(with networkingModule: WallpaperNetworking) {
        self.networking = networkingModule
    }

    // MARK: - Methods

    /// Main interface for fetching metadata from the server
    func getMetadata() async throws -> WallpaperMetadata {
        let url = try WallpaperURLProvider().url(for: .metadata)
        let loader = WallpaperMetadataLoader(networkModule: networking)

        return try await loader.fetchMetadata(from: url)
    }

    /// Main interface for fetching images from the server
    func getImage(
        named imageName: String,
        withFolderName folderName: String
    ) async throws -> UIImage {
        let url = try WallpaperURLProvider().url(for: .image(named: imageName, withFolderName: folderName))
        let loader = WallpaperImageLoader(networkModule: networking)

        return try await loader.fetchImage(from: url)
    }
}
