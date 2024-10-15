// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Kingfisher
import UIKit

// MARK: - Kingfisher wrapper

/// Image cache wrapper around Kingfisher image cache
/// Used in SiteImageCache
protocol DefaultImageCache {
    func retrieve(forKey key: String) async throws -> UIImage?

    func store(image: UIImage, forKey key: String)

    func clear()
}

extension ImageCache: DefaultImageCache {
    func retrieve(forKey key: String) async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            retrieveImage(forKey: key) { result in
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: imageResult.image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func store(image: UIImage, forKey key: String) {
        self.store(image, forKey: key)
    }

    func clear() {
        clearMemoryCache()
        clearDiskCache()
    }
}
