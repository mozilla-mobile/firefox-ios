// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Kingfisher
import UIKit

// MARK: - Kingfisher wrapper

/// Image cache wrapper around Kingfisher image cache
/// Used in SiteImageCache
protocol DefaultImageCache {
    func retrieveImage(forKey key: String) async -> Result<UIImage?, KingfisherError>

    func store(image: UIImage, forKey key: String) async -> Result<(), KingfisherError>
}

extension ImageCache: DefaultImageCache {

    func retrieveImage(forKey key: String) async -> Result<UIImage?, Kingfisher.KingfisherError> {
        await withCheckedContinuation { continuation in
            retrieveImage(forKey: key, completionHandler: { result in
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: .success(imageResult.image))
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            })
        }
    }

    func store(image: UIImage, forKey key: String) async -> Result<(), KingfisherError> {
        await withCheckedContinuation { continuation in
            store(image, forKey: key) { result in
                // memoryCacheResult never fails
                switch result.diskCacheResult {
                case .success:
                    continuation.resume(returning: .success(()))
                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
