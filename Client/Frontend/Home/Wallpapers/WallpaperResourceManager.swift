// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

private enum WallpaperResourceType {
    case bundled
    case downloaded
}

struct WallpaperImageSet {
    let portrait: UIImage?
    let landscape: UIImage?
}

struct WallpaperImageResourceName {
    private let folder: String
    let portrait: String
    let landscape: String
    
    var portraitPath: String {
        return "\(folder)/\(portrait)"
    }
    
    var landscapePath: String {
        return "\(folder)/\(landscape)"
    }
    
    init(folder: String, portrait: String, landscape: String) {
        self.folder = folder
        self.portrait = portrait
        self.landscape = landscape
    }
}

class WallpaperResourceManager {
    
    // MARK: - Resource verification
    func verifyResources(for specialWallpapers: [Wallpaper]) {
        specialWallpapers.forEach { wallpaper in
            if wallpaper.meetsDateAndLocaleCriteria && !verifyResourceExists(for: wallpaper) {
                let networkUtility = WallpaperNetworkUtility()
                networkUtility.downloadTaskFor(id: getResourceNames(for: wallpaper.name))
                
            } else if !wallpaper.meetsDateAndLocaleCriteria {
                deleteResources(for: wallpaper)
            }
            
        }
    }
    
    func verifyResourceExists(for wallpaper: Wallpaper) -> Bool {
        switch wallpaper.type {
        case .defaultBackground: return true
        case .themed(type: .firefox): return verify(.bundled, for: wallpaper)
        case .themed(type: .firefoxOverlay): return verify(.bundled, for: wallpaper)
        case .themed(type: .projectHouse): return verify(.downloaded, for: wallpaper)
        }
    }
    
    // MARK: - Resource retrieval
    
    func getImageSet(for wallpaper: Wallpaper) -> WallpaperImageSet {
        switch wallpaper.type {
        case .defaultBackground,
                .themed(type: .firefox),
                .themed(type: .firefoxOverlay):
            return getResourceOf(type: .bundled, for: wallpaper)
        case .themed(type: .projectHouse):
            return getResourceOf(type: .downloaded, for: wallpaper)
        }
    }
    
    private func getResourceOf(type: WallpaperResourceType, for wallpaper: Wallpaper) -> WallpaperImageSet {
        
        let imageName = getResourceNames(for: wallpaper.name)
        
        switch type {
        case .bundled:
            return WallpaperImageSet(portrait: UIImage(named: imageName.portrait),
                                     landscape: UIImage(named: imageName.landscape))
            
        case .downloaded:
            let storageUtility = WallpaperStorageUtility()
            
            return WallpaperImageSet(portrait: storageUtility.getImageResource(for: imageName.portrait),
                                     landscape: storageUtility.getImageResource(for: imageName.landscape))
        }
    }
    
    private func getResourceNames(for wallpaperName: String) -> WallpaperImageResourceName {
        var fileName = wallpaperName
        if UIDevice.current.userInterfaceIdiom == .pad { fileName += "_pad" }

        return WallpaperImageResourceName(folder: wallpaperName,
                                          portrait: fileName,
                                          landscape: fileName + "_ls")
    }
    
    // MARK: - Resource deletion
    private func deleteResources(for wallpaper: Wallpaper) {
        let storageManager = WallpaperStorageUtility()
        storageManager.deleteImageResource(named: wallpaper.name)
    }
    
    // MARK: - Verification
    private func verify(_ resourceType: WallpaperResourceType, for wallpaper: Wallpaper) -> Bool {
        let imageSet = getResourceOf(type: resourceType, for: wallpaper)
        guard imageSet.portrait != nil, imageSet.landscape != nil else { return false }

        return true
    }
}
