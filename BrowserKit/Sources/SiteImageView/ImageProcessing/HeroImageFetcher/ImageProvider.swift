// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// MARK: - NSItemProvider wrapper

/// Image provider wrapper around NSItemProvider from LPMetadataProvider
/// Used in HeroImageFetcher
protocol ImageProvider {
    func loadObject(ofClass: NSItemProviderReading.Type) async throws -> UIImage
}

extension NSItemProvider: ImageProvider {
    @MainActor
    func loadObject(ofClass aClass: NSItemProviderReading.Type) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            loadObject(ofClass: aClass) { image, error in
                guard error == nil else {
                    continuation.resume(
                        throwing: SiteImageError.unableToDownloadImage(error.debugDescription.description)
                    )
                    return
                }

                guard let image = image as? UIImage else {
                    continuation.resume(
                        throwing: SiteImageError.unableToDownloadImage("NSItemProviderReading not an image")
                    )
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }
}
