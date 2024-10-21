// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

// Convenience protocol to have a blur on a collection view cell
// Currently used on the homepage cells
protocol Blurrable: UICollectionViewCell {
    var shouldApplyWallpaperBlur: Bool { get }
    func adjustBlur(theme: Theme)
}

extension Blurrable {
    var shouldApplyWallpaperBlur: Bool {
        return true
        // guard !UIAccessibility.isReduceTransparencyEnabled else { return false }

        // return WallpaperManager().currentWallpaper.type != .defaultWallpaper
    }
}
