// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import SDWebImage

// TODO: This file and all its methods should be removed once we are ready to remove SDWebImage from our app
struct SDWebImageCacheKey {
    public static let hasClearedCacheKey = "HasClearedCacheKey"
}

extension SDImageCache {

    func clearDiskCache(completion: @escaping (Bool) -> Void) {
        let defaults = UserDefaults.standard
        let hasClearedDiskCache = defaults.bool(forKey: SDWebImageCacheKey.hasClearedCacheKey)
        guard !hasClearedDiskCache else {
            completion(false)
            return
        }

        SDImageCache.shared.clear(with: .disk) {
            // Send glean telemetry when cache is cleared
            TelemetryWrapper.recordEvent(category: .information, method: .delete, object: .clearSDWebImageCache)

            // Set the userdefaults value so we don't clear disk cache again once cleared
            defaults.set(true, forKey: SDWebImageCacheKey.hasClearedCacheKey)

            completion(true)
        }
    }
}
