// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

protocol BundleImageFetcher {

    /// Fetches from the bundle
    /// - Parameter domain: The domain to fetch the image with from the bundle
    /// - Returns: The image or throw an error if it fails
    func getImageFromBundle(domain: String) throws -> UIImage
}

class DefaultBundleImageFetcher: BundleImageFetcher {

    private struct BundledImage: Codable {
        var title: String
        var url: String?
        var image_url: String
        var background_color: String
        var domain: String
    }

    private struct FormattedBundledImage {
        var backgroundColor: UIColor
        var filePath: String
        var title: String
    }

    private let bundleDataProvider: BundleDataProvider
    private var bundledImages = [String: FormattedBundledImage]()

    // Any time a bundled image couldn't be retrieved for a domain, it will be saved here
    private var imagesErrors = [String: BundleError]()
    // In case no bundled images could be retrieved, this will be set
    private var generalBundleError: BundleError?

    init(bundleDataProvider: BundleDataProvider = DefaultBundleDataProvider()) {
        self.bundleDataProvider = bundleDataProvider
        bundledImages = retrieveBundledImages()
    }

    func getImageFromBundle(domain: String) throws -> UIImage {
        if let bundledImage = bundledImages[domain],
           let image = bundleDataProvider.getBundleImage(from: bundledImage.filePath) {
            let color = bundledImage.backgroundColor.cgColor.alpha < 0.01 ? UIColor.white : bundledImage.backgroundColor
            return withBackgroundAndPadding(image: image, color: color)
        } else if let imageError = imagesErrors[domain] {
            throw imageError
        } else if let error = generalBundleError {
            throw error
        }
        throw BundleError.noImage("Image with domain \(domain) isn't in bundle")
    }

    private func retrieveBundledImages() -> [String: FormattedBundledImage] {
        do {
            let data = try bundleDataProvider.getBundleData()
            return decode(from: data)
        } catch let error {
            generalBundleError = BundleError.noBundleRetrieved("Decoding from file failed due to: \(error)")
            return [:]
        }
    }

    private func decode(from data: Data) -> [String: FormattedBundledImage] {
        let decoder = JSONDecoder()
        var icons = [String: FormattedBundledImage]()

        do {
            let decodedImages = try decoder.decode([BundledImage].self, from: data)
            for decodedImage in decodedImages {
                guard let image = format(image: decodedImage) else {
                    continue
                }

                icons[image.title] = image
            }

            if icons.isEmpty {
                generalBundleError = BundleError.noBundleRetrieved("Bundle was empty")
            }

            return icons
        } catch {
            let message = "Decoding BundledImage failed due to: \(error.localizedDescription.debugDescription)"
            generalBundleError = BundleError.noBundleRetrieved(message)
            return icons
        }
    }

    private func format(image: BundledImage) -> FormattedBundledImage? {
        let path = image.image_url.replacingOccurrences(of: ".png", with: "")
        let title = image.title
        let color = image.background_color
        let filePath = bundleDataProvider.getPath(from: path)
        guard let filePath = filePath else {
            imagesErrors[title] = BundleError.imageFormatting("No filepath for image path: \(path)")
            return nil
        }

        var backgroundColor: UIColor
        if color == "#fff" || color == "#FFF" {
            backgroundColor = UIColor.clear
        } else {
            backgroundColor = UIColor(colorString: color.replacingOccurrences(of: "#", with: ""))
        }

        return FormattedBundledImage(backgroundColor: backgroundColor,
                                     filePath: filePath,
                                     title: title)
    }

    private func withBackgroundAndPadding(image: UIImage, color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, opaque, image.scale)

        guard let ctx = UIGraphicsGetCurrentContext(), let cgImage = image.cgImage else { return image }
        defer { UIGraphicsEndImageContext() }

        // Pad the image in a bit to make the favicons look better
        let newSize = CGSize(width: image.size.width - 20, height: image.size.height - 20)
        let rect = CGRect(origin: .zero, size: image.size)
        let imageRect = CGRect(origin: CGPoint(x: 10, y: 10), size: newSize)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: image.size.height))
        ctx.draw(cgImage, in: imageRect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}
