// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol WallpaperDownloadProtocol {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: WallpaperDownloadProtocol {}

class WallpaperNetworkUtility: WallpaperFilePathProtocol, Loggable {
    
    // MARK: - Variables
    private static let wallpaperURLScheme = "MozWallpaperURLScheme"
    lazy var downloadProtocol: WallpaperDownloadProtocol = {
        return URLSession.shared
    }()
    
    // MARK: - Public interfaces
    public func downloadTaskFor(id: WallpaperImageResourceName) {
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
            
            if let error = error {
                self.browserLog.debug("Error fetching wallpaper: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                self.browserLog.debug("Wallpaper download - bad networking response: \(response.debugDescription)")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                self.browserLog.error("")
                return
            }
            
            let storageUtility = WallpaperStorageUtility()
            do {
                try storageUtility.store(image: image, forKey: localPath)
                
            } catch let error {
                self.browserLog.error("Error saving downloaded image - \(error.localizedDescription)")
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
        guard let appToken = bundle.object(forInfoDictionaryKey: WallpaperNetworkUtility.wallpaperURLScheme) as? String,
              !appToken.isEmpty
        else {
            browserLog.debug("Error fetching wallpapers: asset scheme not configured in Info.plist")
            return nil
        }
        
        return appToken
    }
}
