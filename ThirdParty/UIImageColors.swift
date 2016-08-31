//    UIImageColors.swift
//    https://github.com/jathu/UIImageColors
//
//    Created by Jathu Satkunarajah (@jathu) on 2015-06-11 - Toronto
//    Original Cocoa version by Panic Inc. - Portland
//
//    MIT License


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

extension UIColor {

    private var isDarkColor: Bool {
        let RGB = CGColorGetComponents(self.CGColor)
        return (0.2126 * RGB[0] + 0.7152 * RGB[1] + 0.0722 * RGB[2]) < 0.5
    }

    public var isBlackOrWhite: Bool {
        let RGB = CGColorGetComponents(self.CGColor)
        return (RGB[0] > 0.91 && RGB[1] > 0.91 && RGB[2] > 0.91) || (RGB[0] < 0.09 && RGB[1] < 0.09 && RGB[2] < 0.09)
    }

    public var isWhite: Bool {
        let RGB = CGColorGetComponents(self.CGColor)
        return (RGB[0] > 0.91 && RGB[1] > 0.91 && RGB[2] > 0.91)
    }

    private func isDistinct(compareColor: UIColor) -> Bool {
        let bg = CGColorGetComponents(self.CGColor)
        let fg = CGColorGetComponents(compareColor.CGColor)
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

    private func colorWithMinimumSaturation(minSaturation: CGFloat) -> UIColor {
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

    private func isContrastingColor(compareColor: UIColor) -> Bool {
        let bg = CGColorGetComponents(self.CGColor)
        let fg = CGColorGetComponents(compareColor.CGColor)

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

    private func resize(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    public func getColors(completionHandler: (UIImageColors) -> Void) {
        let ratio = self.size.width/self.size.height
        let r_width: CGFloat = 250

        self.getColors(CGSizeMake(r_width, r_width/ratio), completionHandler: completionHandler)
    }

    public func getColors(scaleDownSize: CGSize, completionHandler: (UIImageColors) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var result = UIImageColors()

            let cgImage = self.resize(scaleDownSize).CGImage
            let width = CGImageGetWidth(cgImage)
            let height = CGImageGetHeight(cgImage)

            let bytesPerPixel: Int = 4
            let bytesPerRow: Int = width * bytesPerPixel
            let bitsPerComponent: Int = 8
            let randomColorsThreshold = Int(CGFloat(height)*0.01)
            let sortedColorComparator: NSComparator = { (main, other) -> NSComparisonResult in
                let m = main as! PCCountedColor, o = other as! PCCountedColor
                if m.count < o.count {
                    return NSComparisonResult.OrderedDescending
                } else if m.count == o.count {
                    return NSComparisonResult.OrderedSame
                } else {
                    return NSComparisonResult.OrderedAscending
                }
            }
            let blackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            let whiteColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let raw = malloc(bytesPerRow * height)
            let bitmapInfo = CGImageAlphaInfo.PremultipliedFirst.rawValue
            let ctx = CGBitmapContextCreate(raw, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
            CGContextClearRect(ctx, CGRectMake(0, 0, CGFloat(width), CGFloat(height)))
            CGContextDrawImage(ctx, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), cgImage)
            let data = UnsafePointer<UInt8>(CGBitmapContextGetData(ctx))

            let leftEdgeColors = NSCountedSet(capacity: height)
            let imageColors = NSCountedSet(capacity: width * height)

            for x in 0..<width {
                for y in 0..<height {
                    let pixel = ((width * y) + x) * bytesPerPixel
                    let color = UIColor(
                        red: CGFloat(data[pixel+1])/255,
                        green: CGFloat(data[pixel+2])/255,
                        blue: CGFloat(data[pixel+3])/255,
                        alpha: 1
                    )

                    // A lot of albums have white or black edges from crops, so ignore the first few pixels
                    if 5 <= x && x <= 10 {
                        leftEdgeColors.addObject(color)
                    }

                    imageColors.addObject(color)
                }
            }

            // Get background color
            var enumerator = leftEdgeColors.objectEnumerator()
            var sortedColors = NSMutableArray(capacity: leftEdgeColors.count)
            while let kolor = enumerator.nextObject() as? UIColor {
                let colorCount = leftEdgeColors.countForObject(kolor)
                if randomColorsThreshold < colorCount  {
                    sortedColors.addObject(PCCountedColor(color: kolor, count: colorCount))
                }
            }
            sortedColors.sortUsingComparator(sortedColorComparator)

            var proposedEdgeColor: PCCountedColor
            if 0 < sortedColors.count {
                proposedEdgeColor = sortedColors.objectAtIndex(0) as! PCCountedColor
            } else {
                proposedEdgeColor = PCCountedColor(color: blackColor, count: 1)
            }

            if proposedEdgeColor.color.isBlackOrWhite && 0 < sortedColors.count {
                for i in 1..<sortedColors.count {
                    let nextProposedEdgeColor = sortedColors.objectAtIndex(i) as! PCCountedColor
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
                kolor = kolor.colorWithMinimumSaturation(0.15)
                if kolor.isDarkColor == findDarkTextColor {
                    let colorCount = imageColors.countForObject(kolor)
                    sortedColors.addObject(PCCountedColor(color: kolor, count: colorCount))
                }
            }
            sortedColors.sortUsingComparator(sortedColorComparator)

            for curContainer in sortedColors {
                let kolor = (curContainer as! PCCountedColor).color

                if result.primaryColor == nil {
                    if kolor.isContrastingColor(result.backgroundColor) {
                        result.primaryColor = kolor
                    }
                } else if result.secondaryColor == nil {
                    if !result.primaryColor.isDistinct(kolor) || !kolor.isContrastingColor(result.backgroundColor) {
                        continue
                    }

                    result.secondaryColor = kolor
                } else if result.detailColor == nil {
                    if !result.secondaryColor.isDistinct(kolor) || !result.primaryColor.isDistinct(kolor) || !kolor.isContrastingColor(result.backgroundColor) {
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
            
            // Release the allocated memory
            free(raw)
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(result)
            }
        }
    }
    
}