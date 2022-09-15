// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-4882
// This will be removed when the theme system pass on the homepage will happen
// and apply theme will be done from the `reloadAll` call. This is a temporary
// fix for the problem until then.
class BlurrableCollectionViewCell: UICollectionViewCell {
    var shouldApplyWallpaperBlur: Bool {
        guard !UIAccessibility.isReduceTransparencyEnabled else { return false }

        return WallpaperManager().currentWallpaper.type != .defaultWallpaper
    }
}
