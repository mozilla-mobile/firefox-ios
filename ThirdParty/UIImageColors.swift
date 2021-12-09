//
//  UIImageColors.swift
//  https://github.com/jathu/UIImageColors
//
//  Created by Jathu Satkunarajah (@jathu) on 2015-06-11 - Toronto
//  Original Cocoa version by Panic Inc. - Portland
//

import UIKit

public struct UIImageColors {
    public var background: UIColor!
    public var primary: UIColor!
    public var secondary: UIColor!
    public var detail: UIColor!
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
            return [red,green,blue,alpha]
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

        if abs(bg[0] - fg[0]) > threshold || abs(bg[1] - fg[1]) > threshold || abs(bg[2] - fg[2]) > threshold {
            if abs(bg[0] - bg[1]) < 0.03 && abs(bg[0] - bg[2]) < 0.03 {
                if abs(fg[0] - fg[1]) < 0.03 && abs(fg[0] - fg[2]) < 0.03 {
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
        self.draw(in: CGRect(width: newSize.width, height: newSize.height))
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
    public func getColors(scaleDownSize: CGSize = .zero, completionHandler: @escaping (UIImageColors) -> Void) {
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
    public func getColors(scaleDownSize: CGSize = .zero) -> UIImageColors {

        var scaleDownSize = scaleDownSize

        if scaleDownSize == .zero {
            let ratio = self.size.width/self.size.height
            let r_width: CGFloat = 250
            scaleDownSize = CGSize(width: r_width, height: r_width/ratio)
        }

        var result = UIImageColors()

        let cgImage = self.resizeForUIImageColors(newSize: scaleDownSize).cgImage!
        let width: Int = cgImage.width
        let height: Int = cgImage.height

        let blackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let whiteColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

        let randomColorsThreshold = Int(CGFloat(height)*0.01)
        let sortedColorComparator: Comparator = { (main, other) -> ComparisonResult in
            let m = main as! PCCountedColor, o = other as! PCCountedColor
            if m.count < o.count {
                return .orderedDescending
            } else if m.count == o.count {
                return .orderedSame
            } else {
                return .orderedAscending
            }
        }

        guard let data = CFDataGetBytePtr(cgImage.dataProvider!.data) else {
            fatalError("UIImageColors.getColors failed: could not get cgImage data")
        }

        // Filter out and collect pixels from image
        let imageColors = NSCountedSet(capacity: width * height)

        for x in 0..<width {
            for y in 0..<height {
                let pixel: Int = ((width * y) + x) * 4
                // Only consider pixels with 50% opacity or higher
                if 127 <= data[pixel+3] {
                    imageColors.add(UIColor(
                        red: CGFloat(data[pixel+2])/255,
                        green: CGFloat(data[pixel+1])/255,
                        blue: CGFloat(data[pixel])/255,
                        alpha: 1.0
                    ))
                }
            }
        }

        // Get background color
        var enumerator = imageColors.objectEnumerator()
        var sortedColors = NSMutableArray(capacity: imageColors.count)
        while let kolor = enumerator.nextObject() as? UIColor {
            let colorCount = imageColors.count(for: kolor)
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
        result.background = proposedEdgeColor.color

        // Get foreground colors
        enumerator = imageColors.objectEnumerator()
        sortedColors.removeAllObjects()
        sortedColors = NSMutableArray(capacity: imageColors.count)
        let findDarkTextColor = !result.background.isDarkColor

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

            if result.primary == nil {
                if kolor.isContrastingColor(compareColor: result.background) {
                    result.primary = kolor
                }
            } else if result.secondary == nil {
                if !result.primary.isDistinct(compareColor: kolor) || !kolor.isContrastingColor(compareColor: result.background) {
                    continue
                }

                result.secondary = kolor
            } else if result.detail == nil {
                if !result.secondary.isDistinct(compareColor: kolor) || !result.primary.isDistinct(compareColor: kolor) || !kolor.isContrastingColor(compareColor: result.background) {
                    continue
                }

                result.detail = kolor
                break
            }
        }

        let isDarkBackgound = result.background.isDarkColor

        if result.primary == nil {
            result.primary = isDarkBackgound ? whiteColor:blackColor
        }

        if result.secondary == nil {
            result.secondary = isDarkBackgound ? whiteColor:blackColor
        }

        if result.detail == nil {
            result.detail = isDarkBackgound ? whiteColor:blackColor
        }

        return result
    }
    
    // Courtesy: https://www.hackingwithswift.com/example-code/media/how-to-read-the-average-color-of-a-uiimage-using-ciareaaverage
    public func averageColor(completion: @escaping (UIColor?) -> Void) {
        guard let inputImage = CIImage(image: self) else {
            completion(nil)
            return
        }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        // core image filter that resamples an image down to 1x1 pixels
        // so you can read the most dominant color in an imagage
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]), let outputImage = filter.outputImage else {
            completion(nil)
            return
        }

        // reads each of the color values into a UIColor, and sends it back
        var bitmap = [UInt8](repeating: 0, count: 4)
        guard let kCFNull = kCFNull else {
            completion(nil)
            return
        }

        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        completion(UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255))
    }
}
