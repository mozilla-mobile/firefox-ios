//
//  UIImageColors.swift
//  https://github.com/jathu/UIImageColors
//
//  Created by Jathu Satkunarajah (@jathu) on 2015-06-11 - Toronto
//  Original Cocoa version by Panic Inc. - Portland
//

import UIKit

public struct UIImageColors {
    public var backgroundColor: UIColor!
    public var primaryColor: UIColor!
    public var secondaryColor: UIColor!
    public var detailColor: UIColor!
}

class PCCountedColor {
    let color: UIColor
    let count: Int

    init(color: UIColor, count: Int) {
        self.color = color
        self.count = count
    }
}

extension CGColor {
    var components: [CGFloat] {
        get {
            var red = CGFloat()
            var green = CGFloat()
            var blue = CGFloat()
            var alpha = CGFloat()
            UIColor(cgColor: self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [red, green, blue, alpha]
        }
    }
}

extension UIColor {

    var isDarkColor: Bool {
        let RGB = self.cgColor.components
        return (0.2126 * RGB[0] + 0.7152 * RGB[1] + 0.0722 * RGB[2]) < 0.5
    }

    var isBlackOrWhite: Bool {
        let RGB = self.cgColor.components
        return (RGB[0] > 0.91 && RGB[1] > 0.91 && RGB[2] > 0.91) || (RGB[0] < 0.09 && RGB[1] < 0.09 && RGB[2] < 0.09)
    }

    func isDistinct(compareColor: UIColor) -> Bool {
        let bg = self.cgColor.components
        let fg = compareColor.cgColor.components
        let threshold: CGFloat = 0.25

        if fabs(bg[0] - fg[0]) > threshold || fabs(bg[1] - fg[1]) > threshold || fabs(bg[2] - fg[2]) > threshold {
            if fabs(bg[0] - bg[1]) < 0.03 && fabs(bg[0] - bg[2]) < 0.03 {
                if fabs(fg[0] - fg[1]) < 0.03 && fabs(fg[0] - fg[2]) < 0.03 {
                    return false
                }
            }
            return true
        }
        return false
    }

    func colorWithMinimumSaturation(minSaturation: CGFloat) -> UIColor {
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        if saturation < minSaturation {
            return UIColor(hue: hue, saturation: minSaturation, brightness: brightness, alpha: alpha)
        } else {
            return self
        }
    }

    func isContrastingColor(compareColor: UIColor) -> Bool {
        let bg = self.cgColor.components
        let fg = compareColor.cgColor.components

        let bgLum = 0.2126 * bg[0] + 0.7152 * bg[1] + 0.0722 * bg[2]
        let fgLum = 0.2126 * fg[0] + 0.7152 * fg[1] + 0.0722 * fg[2]

        let bgGreater = bgLum > fgLum
        let nom = bgGreater ? bgLum : fgLum
        let denom = bgGreater ? fgLum : bgLum
        let contrast = (nom + 0.05) / (denom + 0.05)
        return 1.6 < contrast
    }

}

extension UIImage {
    private func resizeForUIImageColors(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer {
            UIGraphicsEndImageContext()
        }
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else {
            fatalError("UIImageColors.resizeForUIImageColors failed: UIGraphicsGetImageFromCurrentImageContext returned nil")
        }

        return result
    }

    /**
     Get `UIImageColors` from the image asynchronously (in background thread).
     Discussion: Use smaller sizes for better performance at the cost of quality colors. Use larger sizes for better color sampling and quality at the cost of performance.

     - parameter scaleDownSize:     Downscale size of image for sampling, if `CGSize.zero` is provided, the sample image is rescaled to a width of 250px and the aspect ratio height.
     - parameter completionHandler: `UIImageColors` for this image.
     */
    public func getColors(scaleDownSize: CGSize = CGSize.zero, completionHandler: @escaping (UIImageColors) -> Void) {
        DispatchQueue.global().async {
            let result = self.getColors(scaleDownSize: scaleDownSize)

            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }

    /**
     Get `UIImageColors` from the image synchronously (in main thread).
     Discussion: Use smaller sizes for better performance at the cost of quality colors. Use larger sizes for better color sampling and quality at the cost of performance.

     - parameter scaleDownSize: Downscale size of image for sampling, if `CGSize.zero` is provided, the sample image is rescaled to a width of 250px and the aspect ratio height.

     - returns: `UIImageColors` for this image.
     */
    public func getColors(scaleDownSize: CGSize = CGSize.zero) -> UIImageColors {

        var scaleDownSize = scaleDownSize

        if scaleDownSize == CGSize.zero {
            let ratio = self.size.width/self.size.height
            let r_width: CGFloat = 250
            scaleDownSize = CGSize(width: r_width, height: r_width/ratio)
        }

        var result = UIImageColors()

        let cgImage = self.resizeForUIImageColors(newSize: scaleDownSize).cgImage!
        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel: Int = 4
        let bytesPerRow: Int = width * bytesPerPixel
        let bitsPerComponent: Int = 8
        let randomColorsThreshold = Int(CGFloat(height)*0.01)
        let sortedColorComparator: Comparator = { (main, other) -> ComparisonResult in
            let m = main as! PCCountedColor, o = other as! PCCountedColor
            if m.count < o.count {
                return ComparisonResult.orderedDescending
            } else if m.count == o.count {
                return ComparisonResult.orderedSame
            } else {
                return ComparisonResult.orderedAscending
            }
        }
        let blackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let whiteColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let raw = malloc(bytesPerRow * height)
        defer {
            free(raw)
        }
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(data: raw, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            fatalError("UIImageColors.getColors failed: could not create CGBitmapContext")
        }
        let drawingRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        ctx.draw(cgImage, in: drawingRect)

        let data = ctx.data?.assumingMemoryBound(to: UInt8.self)

        let leftEdgeColors = NSCountedSet(capacity: height)
        let imageColors = NSCountedSet(capacity: width * height)

        for x in 0..<width {
            for y in 0..<height {
                let pixel = ((width * y) + x) * bytesPerPixel
                let color = UIColor(
                    red: CGFloat((data?[pixel+1])!)/255,
                    green: CGFloat((data?[pixel+2])!)/255,
                    blue: CGFloat((data?[pixel+3])!)/255,
                    alpha: 1
                )

                // A lot of images have white or black edges from crops, so ignore the first few pixels
                if 5 <= x && x <= 10 {
                    leftEdgeColors.add(color)
                }

                imageColors.add(color)
            }
        }

        // Get background color
        var enumerator = leftEdgeColors.objectEnumerator()
        var sortedColors = NSMutableArray(capacity: leftEdgeColors.count)
        while let kolor = enumerator.nextObject() as? UIColor {
            let colorCount = leftEdgeColors.count(for: kolor)
            if randomColorsThreshold < colorCount {
                sortedColors.add(PCCountedColor(color: kolor, count: colorCount))
            }
        }
        sortedColors.sort(comparator: sortedColorComparator)

        var proposedEdgeColor: PCCountedColor
        if 0 < sortedColors.count {
            proposedEdgeColor = sortedColors.object(at: 0) as! PCCountedColor
        } else {
            proposedEdgeColor = PCCountedColor(color: blackColor, count: 1)
        }

        if proposedEdgeColor.color.isBlackOrWhite && 0 < sortedColors.count {
            for i in 1..<sortedColors.count {
                let nextProposedEdgeColor = sortedColors.object(at: i) as! PCCountedColor
                if (CGFloat(nextProposedEdgeColor.count)/CGFloat(proposedEdgeColor.count)) > 0.3 {
                    if !nextProposedEdgeColor.color.isBlackOrWhite {
                        proposedEdgeColor = nextProposedEdgeColor
                        break
                    }
                } else {
                    break
                }
            }
        }
        result.backgroundColor = proposedEdgeColor.color

        // Get foreground colors
        enumerator = imageColors.objectEnumerator()
        sortedColors.removeAllObjects()
        sortedColors = NSMutableArray(capacity: imageColors.count)
        let findDarkTextColor = !result.backgroundColor.isDarkColor

        while var kolor = enumerator.nextObject() as? UIColor {
            kolor = kolor.colorWithMinimumSaturation(minSaturation: 0.15)
            if kolor.isDarkColor == findDarkTextColor {
                let colorCount = imageColors.count(for: kolor)
                sortedColors.add(PCCountedColor(color: kolor, count: colorCount))
            }
        }
        sortedColors.sort(comparator: sortedColorComparator)

        for curContainer in sortedColors {
            let kolor = (curContainer as! PCCountedColor).color

            if result.primaryColor == nil {
                if kolor.isContrastingColor(compareColor: result.backgroundColor) {
                    result.primaryColor = kolor
                }
            } else if result.secondaryColor == nil {
                if !result.primaryColor.isDistinct(compareColor: kolor) || !kolor.isContrastingColor(compareColor: result.backgroundColor) {
                    continue
                }

                result.secondaryColor = kolor
            } else if result.detailColor == nil {
                if !result.secondaryColor.isDistinct(compareColor: kolor) || !result.primaryColor.isDistinct(compareColor: kolor) || !kolor.isContrastingColor(compareColor: result.backgroundColor) {
                    continue
                }

                result.detailColor = kolor
                break
            }
        }

        let isDarkBackgound = result.backgroundColor.isDarkColor

        if result.primaryColor == nil {
            result.primaryColor = isDarkBackgound ? whiteColor:blackColor
        }

        if result.secondaryColor == nil {
            result.secondaryColor = isDarkBackgound ? whiteColor:blackColor
        }

        if result.detailColor == nil {
            result.detailColor = isDarkBackgound ? whiteColor:blackColor
        }

        return result
    }
}
