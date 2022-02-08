// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class WallpaperNetworkUtility: WallpaperFilePathProtocol, Loggable {
    
    private static let wallpaperURLScheme = "MozWallpaperURLScheme"
    
    init() { }
    
    public func downloadTaskFor(id: WallpaperImageResourceName) {
        downloadResourceFrom(urlPath: id.portraitPath, andLocalPath: id.portrait)
        downloadResourceFrom(urlPath: id.landscapePath, andLocalPath: id.landscape)
    }
    
    private func downloadResourceFrom(urlPath: String, andLocalPath localPath: String) {
        guard let url = buildURLWith(path: urlPath) else { return }
        
        let downloadTask = URLSession.shared.dataTask(with: url) { data, response, error in
            
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
            
            guard let data = data, let image = UIImage(data: data) else { return }
            
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
