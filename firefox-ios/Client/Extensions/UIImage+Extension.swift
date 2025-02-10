// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIImage {
    func overlayWith(image: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: size.height), false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        image.draw(CGRect(origin: CGPoint.zero, size: image.frame.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }

    func overlayWith(image: UIImage,
                     modifier: CGFloat = 0.35,
                     origin: CGPoint = CGPoint(x: 15, y: 16)) -> UIImage {
        let newSize = CGSize(width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        image.draw(in: CGRect(origin: origin,
                              size: CGSize(width: size.width * modifier,
                                           height: size.height * modifier)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }

    /// Tries to load an `UIImage` from the content of a gif in the main `Bundle`
    ///
    /// The `frameDuration` it's set to 0.1 seconds as default but may be adjusted depending on the loaded gif.
    static func gifFromBundle(named name: String, frameDuration: CGFloat = 0.1) -> UIImage? {
        guard let gifPath = Bundle.main.path(forResource: name, ofType: "gif"),
              let gifData = NSData(contentsOfFile: gifPath) as Data?,
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return nil
        }

        var frames: [UIImage] = []
        let frameCount = CGImageSourceGetCount(source)

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                frames.append(UIImage(cgImage: cgImage))
            }
        }

        return UIImage.animatedImage(with: frames, duration: Double(frameCount) * frameDuration)
    }

    /// Computes the average color of the image using a CIAreaAverage filter.
    /// The filter returns a 1x1 pixel image representing the average of all pixel colors.
    /// This method renders that pixel into a bitmap and converts it into a UIColor.
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }

        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        // Set up the CIAreaAverage filter with the input image and its extent.
        // The filter will compute the average color over the specified area.
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(extentVector, forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()

        // Render the 1x1 output image into the bitmap.
        // This extracts the RGBA values of the computed average color.
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
    }
}
