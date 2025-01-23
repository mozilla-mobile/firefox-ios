// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Kingfisher
import SwiftDraw

/// A Kingfisher image processor to parse SVG image data.
/// - Documentation: https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet#creating-your-own-processor
public struct SVGImageProcessor: ImageProcessor {
    // `identifier` should be the same for processors with the same properties/functionality
    // It will be used when storing and retrieving the image to/from cache.
    public var identifier: String = "com.mozilla.SVGImageProcessor"

    private let defaultFaviconSize = CGSize(width: 360, height: 360)

    // Convert input data/image to target image and return it.
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            // A previous processor already converted the image to an image object.
            // You can do whatever you want to apply to the image and return the result.
            return image
        case .data(let data):
            if let image = UIImage(data: data) {
                return image
            } else if let svgImage = SVG(data: data)?.rasterize(with: defaultFaviconSize) {
                return svgImage
            }
            return nil
        }
    }
}
