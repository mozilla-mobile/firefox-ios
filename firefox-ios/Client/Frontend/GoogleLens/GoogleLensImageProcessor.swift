// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The result of preparing an image for upload to Google Lens: the JPEG-encoded
/// bytes and the pixel dimensions of the processed image.
struct ProcessedLensImage: Equatable {
    let jpegData: Data
    let dimensions: CGSize
}

protocol GoogleLensImageProcessing {
    /// Downscales and JPEG-encodes an image following Google Lens' recommended
    /// preprocessing. Returns `nil` if the image could not be encoded.
    func process(_ image: UIImage) -> ProcessedLensImage?
}

/// Applies Google Lens' recommended preprocessing: downscale the longest dimension
/// (preserving aspect ratio) and JPEG-encode the result.
struct GoogleLensImageProcessor: GoogleLensImageProcessing {
    private enum Constants {
        /// The longest side, in pixels, an image is downscaled to before upload.
        static let maxDimension: CGFloat = 1000
        /// JPEG compression quality
        static let compressionQuality: CGFloat = 0.4
    }

    func process(_ image: UIImage) -> ProcessedLensImage? {
        let targetSize = downscaledSize(for: image.size)
        let resized = resize(image, to: targetSize)
        guard let jpegData = resized.jpegData(compressionQuality: Constants.compressionQuality)
        else { return nil }
        return ProcessedLensImage(jpegData: jpegData, dimensions: targetSize)
    }

    /// Returns the largest size fitting within `maxDimension` on the longest side while
    /// preserving aspect ratio. Images already within the limit are left unchanged
    /// (we only downscale, never upscale).
    private func downscaledSize(for size: CGSize) -> CGSize {
        let longest = max(size.width, size.height)
        guard longest > Constants.maxDimension else { return size }
        let scale = Constants.maxDimension / longest
        return CGSize(width: (size.width * scale).rounded(),
                      height: (size.height * scale).rounded())
    }

    private func resize(_ image: UIImage, to size: CGSize) -> UIImage {
        // scale = 1 so the rendered pixel dimensions match `size` exactly, keeping the
        // dimensions we report to Lens consistent with the encoded bytes.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
