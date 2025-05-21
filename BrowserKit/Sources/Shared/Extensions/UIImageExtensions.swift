// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension CGRect {
    public init(width: CGFloat, height: CGFloat) {
        self.init(x: 0, y: 0, width: width, height: height)
    }

    public init(size: CGSize) {
        self.init(origin: .zero, size: size)
    }
}

extension Data {
    public var isGIF: Bool {
        return [0x47, 0x49, 0x46].elementsEqual(prefix(3))
    }
}

extension UIImage {
    public static func createWithColor(_ size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { (ctx) in
            color.setFill()
            ctx.fill(CGRect(size: size))
        }
    }

    public func createScaled(_ size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { (ctx) in
            draw(in: CGRect(size: size))
        }
    }

    public static func templateImageNamed(_ name: String) -> UIImage? {
        return UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
    }

    // Uses compositor blending to apply color to an image.
    public func tinted(withColor: UIColor) -> UIImage {
        let img2 = UIImage.createWithColor(size, color: withColor)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let result = renderer.image { ctx in
            img2.draw(in: rect, blendMode: .normal, alpha: 1)
            draw(in: rect, blendMode: .destinationIn, alpha: 1)
        }
        return result
    }

    // Percentage of pixels in an image that are completely transparent
    public var percentTransparent: CGFloat? {
        guard let cgImage = cgImage else { return nil }

        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        let imageSize = CGSize(width: imageWidth, height: imageHeight)

        let bytesPerPixel = 4 // 1 byte for each channel in a pixel
        let bitsPerChannel = 8 // 8 bits (1 byte) for each channel in RGBA which represents the 0-255 (2^8) value
        let bytesPerRow = imageWidth * bytesPerPixel

        let pixelCount = imageWidth * imageHeight
        var pixelData = [UInt8](repeating: 0, count: pixelCount * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: imageWidth,
            height: imageHeight,
            bitsPerComponent: bitsPerChannel,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))

        var transparentPixelCount = 0

        // Step by 4 since each pixel is 4 bytes
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let alpha = pixelData[i + 3] // Alpha channel is the last byte since we are using CGContext
            if alpha == 0 { // 0 = transparent, 255 = opaque
                transparentPixelCount += 1
            }
        }

        let percentageTransparent = CGFloat(transparentPixelCount) / CGFloat(pixelCount)

        return percentageTransparent * 100
    }
}
