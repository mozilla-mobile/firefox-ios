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
    init(with networkingModule: WallpaperNetworking = WallpaperNetworkingModule()) {
        self.networking = networkingModule
    }

    // MARK: - Methods

    /// Main interface for fetching metadata from the server
    func getMetadata() async throws -> WallpaperMetadata {
        let scheme = try urlScheme()
        let loader = WallpaperMetadataLoader(networkModule: networking)

        return try await loader.fetchMetadataWith(scheme)
    }

    /// Main interface for fetching images from the server
    func getImageWith(path: String) async throws -> UIImage {
        let scheme = try urlScheme()
        let loader = WallpaperImageLoader(networkModule: networking)

        return try await loader.fetchImage(using: scheme, andPath: path)
    }

    /// Builds a URL for the server based on the specified environment.
    private func urlScheme() throws -> String {
        if AppConstants.isRunningTest { return "https://my.test.url" }

        let bundle = AppInfo.applicationBundle
        guard let appToken = bundle.object(forInfoDictionaryKey: wallpaperURLScheme) as? String,
              !appToken.isEmpty
        else { throw DataServiceError.noBundledURL }

        return appToken
    }
}
