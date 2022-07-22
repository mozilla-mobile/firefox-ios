// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

///  Responsible for fetching data from the server.
class WallpaperDataService: Loggable {

    // MARK: - Properties
    enum URLType {
        case metadata
        case image
    }

    enum WallpaperDataServiceError: Error {
        case invalidURL
        case invalidResponse
        case badData
    }

    private let networking: Networking

    private let wallpaperURLScheme = "MozWallpaperURLScheme"

    init(with networkingModule: Networking = WallpaperNetworkingModule()) {
        self.networking = networkingModule
    }

    // MARK: - Methods
    func getMetadata() async throws -> WallpaperMetadata {
        guard let scheme = urlScheme() else {
            throw WallpaperDataServiceError.invalidURL
        }

        let loader = WallpaperMetadataLoader(networkModule: networking)

        return try await loader.loadMetadataWith(scheme)
    }

    private func urlScheme() -> String? {
        if AppConstants.isRunningTest { return "https://my.test.url" }

        let bundle = AppInfo.applicationBundle
        guard let appToken = bundle.object(forInfoDictionaryKey: wallpaperURLScheme) as? String,
              !appToken.isEmpty
        else {
            browserLog.debug("Error fetching wallpapers: asset scheme not configured in Info.plist")
            return nil
        }

        return appToken
    }

    // MARK: Helpers
    func stringWithImageSuffixAdded(to path: String) -> String {
        return "\(path).png"
    }
}
