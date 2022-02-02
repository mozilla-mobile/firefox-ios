// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// TODO: will move more things in there from the view during the next ticket.

class WallpaperSettingsViewModel {
    
    // MARK: - Internal definitions
    struct Constants {
        struct Strings {
            struct Toast {
                static let label: String = .Settings.Homepage.Wallpaper.WallpaperUpdatedToastLabel
                static let button: String = .Settings.Homepage.Wallpaper.WallpaperUpdatedToastButton
            }
        }
    }
    
    // MARK: - Variables
    var tabManager: TabManager
    var wallpaperManager: WallpaperManager
    
    init(with tabManager: TabManager,
         and wallpaperManager: WallpaperManager
    ) {
        self.tabManager = tabManager
        self.wallpaperManager = wallpaperManager
    }
}
