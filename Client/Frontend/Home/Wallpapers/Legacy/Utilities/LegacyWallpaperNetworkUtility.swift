// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol LegacyWallpaperDownloadProtocol {
    func dataTask(with url: URL,
                  completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void)
    -> URLSessionDataTask
}

extension URLSession: LegacyWallpaperDownloadProtocol {}

class LegacyWallpaperNetworkUtility: LegacyWallpaperFilePathProtocol {
    // MARK: - Variables
    private static let wallpaperURLScheme = "MozWallpaperURLScheme"
    lazy var downloadProtocol: LegacyWallpaperDownloadProtocol = {
        return URLSession.shared
    }()

    // MARK: - Public interfaces
    public func downloadTaskFor(id: LegacyWallpaperImageResourceName) {
        // Prioritize downloading the image matching the current orientation
        if UIDevice.current.orientation.isLandscape {
            downloadResourceFrom(urlPath: id.landscapePath, andLocalPath: id.landscape)
            downloadResourceFrom(urlPath: id.portraitPath, andLocalPath: id.portrait)
        } else {
            downloadResourceFrom(urlPath: id.portraitPath, andLocalPath: id.portrait)
            downloadResourceFrom(urlPath: id.landscapePath, andLocalPath: id.landscape)
        }
    }

    // MARK: - Private methods
    private func downloadResourceFrom(urlPath: String, andLocalPath localPath: String) {
        guard let url = buildURLWith(path: urlPath) else { return }

        downloadProtocol.dataTask(with: url) { data, response, error in
            if error != nil {
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                return
            }

            let storageUtility = LegacyWallpaperStorageUtility()
            do {
                try storageUtility.store(image: image, forKey: localPath)
            } catch {
                // Do nothing
            }
        }.resume()
    }

    private func buildURLWith(path: String) -> URL? {
        guard let scheme = urlScheme() else { return nil }
        let urlString = scheme + "\(path).png"

        return URL(string: urlString)
    }

    private func urlScheme() -> String? {
        let bundle = AppInfo.applicationBundle
        guard let appToken = bundle.object(forInfoDictionaryKey: LegacyWallpaperNetworkUtility.wallpaperURLScheme) as? String,
              !appToken.isEmpty
        else {
            return nil
        }

        return appToken
    }
}
