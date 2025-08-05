// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

// Convenience protocol to have a blur on a collection view cell
// Currently used on the homepage cells
protocol Blurrable: UICollectionViewCell {
    @MainActor
    var shouldApplyWallpaperBlur: Bool { get }
    @MainActor
    func adjustBlur(theme: Theme)
}

extension Blurrable {
    @MainActor
    var shouldApplyWallpaperBlur: Bool {
        guard !UIAccessibility.isReduceTransparencyEnabled else { return false }

        return WallpaperManager().currentWallpaper.hasImage
    }
}
