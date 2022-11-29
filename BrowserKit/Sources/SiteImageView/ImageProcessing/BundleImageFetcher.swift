// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

protocol BundleImageFetcher {

    /// Fetches from the bundle
    /// - Parameter domain: The domain to fetch the image with from the bundle
    /// - Returns: The image or an error if it fails
    func getImageFromBundle(domain: String) -> Result<UIImage, ImageError>
}

// TODO:
// - Modify to be testable
// - Add unit tests

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
        var domain: String
    }

    private var bundledImages = [String: FormattedBundledImage]()

    // Any time a bundled image couldn't be retrieved for a domain, this will be saved here
    private var imagesErrors = [String: ImageError]()
    // In case no bundled images could be retrieved, this will be set
    private var emptyImagesError: ImageError?

    init() {
        bundledImages = retrieveBundledImages()
    }

    func getImageFromBundle(domain: String) -> Result<UIImage, ImageError> {
        if let bundledImage = bundledImages[domain],
           let image = UIImage(contentsOfFile: bundledImage.filePath) {
            let color = bundledImage.backgroundColor.cgColor.alpha < 0.01 ? UIColor.white : bundledImage.backgroundColor
            return .success(image.withBackgroundAndPadding(color: color))
        } else if let imageError = imagesErrors[domain] {
            return .failure(imageError)
        } else if let error = emptyImagesError {
            return .failure(error)
        }

        return .failure(ImageError.unableToGetFromBundle("Could not retrieve image from bundle with domain \(domain)"))
    }

    private var bundle: Bundle {
        var bundle = Bundle.main
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let otherBundle = Bundle(url: url) {
                bundle = otherBundle
            }
        }
        return bundle
    }

    private func retrieveBundledImages() -> [String: FormattedBundledImage] {
        guard let filePath = bundle.path(forResource: "top_sites", ofType: "json") else {
            emptyImagesError = ImageError.unableToGetFromBundle("No json resource could be retrieved")
            return [:]
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            return decode(from: data)

        } catch let error {
            emptyImagesError = ImageError.unableToGetFromBundle("Decoding from file failed due to: \(error)")
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

                icons[image.domain] = image
            }
            return icons

        } catch let error {
            emptyImagesError = ImageError.unableToGetFromBundle("Decoding BundledImage failed due to: \(error)")
            return icons
        }
    }

    private func format(image: BundledImage) -> FormattedBundledImage? {
        let path = image.image_url.replacingOccurrences(of: ".png", with: "")
        let url = image.domain
        let color = image.background_color
        let filePath = Bundle.main.path(forResource: "TopSites/" + path, ofType: "png")
        guard let filePath = filePath else {
            imagesErrors[url] = ImageError.unableToGetFromBundle("No filepath for image path: \(path)")
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
                                     domain: url)
    }
}

// MARK: - Extension UIImage
extension UIImage {
    func withBackgroundAndPadding(color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

        guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
        defer { UIGraphicsEndImageContext() }

        // Pad the image in a bit to make the favicons look better
        let newSize = CGSize(width: size.width - 20, height: size.height - 20)
        let rect = CGRect(origin: .zero, size: size)
        let imageRect = CGRect(origin: CGPoint(x: 10, y: 10), size: newSize)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(image, in: imageRect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
