// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol WallpaperMetadataTrackerProtocol {
    var shouldCheckForNewMetadata: Bool { get }
}

/// Responsible for tracking whether or not the wallpaper system should perform
/// a variety of checks, such as whether it should fetch data from the server.
class WallpaperMetadataTracker: WallpaperMetadataTrackerProtocol {
    typealias prefsKey = PrefsKeys.Wallpapers.MetadataLastCheckDate

    // MARK: - Properties
    public var shouldCheckForNewMetadata: Bool {
        guard let existingDate = userDefaults.object(forKey: prefsKey)
        return  false
    }

    private let userDefaults: UserDefaultsInterface

    // MARK: - Initializers
    init(with userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    deinit {

    }

    // MARK: - Public interface

    // MARK: - Private methods
}
