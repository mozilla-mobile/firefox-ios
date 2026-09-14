// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Kingfisher
import UIKit

// MARK: - Kingfisher wrapper

/// Image cache wrapper around Kingfisher image cache. Used in SiteImageCache.
/// Note: Kingfisher is designed to be thread safe.
protocol DefaultImageCache: Sendable {
    func retrieve(forKey key: String) async throws -> UIImage?

    /// Synchronous, memory-only lookup. Returns `nil` when the image is absent or only on disk.
    func retrieveFromMemory(forKey key: String) -> UIImage?

    func store(image: UIImage, forKey key: String)

    func clear()
}

extension ImageCache: DefaultImageCache {
    func retrieve(forKey key: String) async throws -> UIImage? {
        return try await Kingfisher.ImageCache.default.retrieveImage(forKey: key).image
    }

    func retrieveFromMemory(forKey key: String) -> UIImage? {
        return Kingfisher.ImageCache.default.retrieveImageInMemoryCache(forKey: key)
    }

    func store(image: UIImage, forKey key: String) {
        self.store(image, forKey: key)
    }

    func clear() {
        clearMemoryCache()
        clearDiskCache()
    }
}
