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

    fileprivate var isDarkColor: Bool {
        guard let RGB = self.cgColor.components else {
            return false
        }
        
        let r = 0.2126 * RGB[0]
        let g = 0.7152 * RGB[1]
        let b = 0.0722 * RGB[2]
        return r + g + b < 0.5
    }

    public var isBlackOrWhite: Bool {
        let RGB = self.cgColor.components
        return (RGB![0] > 0.91 && RGB![1] > 0.91 && RGB![2] > 0.91) || (RGB![0] < 0.09 && RGB![1] < 0.09 && RGB![2] < 0.09)
    }

    fileprivate func isDistinct(_ compareColor: UIColor) -> Bool {
        let bg = self.cgColor.components
        let fg = compareColor.cgColor.components
        let threshold: CGFloat = 0.25

        if fabs((bg?[0])! - (fg?[0])!) > threshold || fabs((bg?[1])! - (fg?[1])!) > threshold || fabs((bg?[2])! - (fg?[2])!) > threshold {
            if fabs((bg?[0])! - (bg?[1])!) < 0.03 && fabs((bg?[0])! - (bg?[2])!) < 0.03 {
                if fabs((fg?[0])! - (fg?[1])!) < 0.03 && fabs((fg?[0])! - (fg?[2])!) < 0.03 {
                    return false
                }
            }
            return true
        }
        return false
    }

    fileprivate func colorWithMinimumSaturation(_ minSaturation: CGFloat) -> UIColor {
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

    fileprivate func isContrastingColor(_ compareColor: UIColor) -> Bool {
        guard let bg = self.cgColor.components, let fg = compareColor.cgColor.components else {
            return false
        }

        let bgLumR = 0.2126 * bg[0]
        let bgLumG = 0.7152 * bg[1]
        let bgLumB = 0.0722 * bg[2]
        let bgLum = bgLumR + bgLumG + bgLumB


        let fgLumR = 0.2126 * fg[0]
        let fgLumG = 0.7152 * fg[1]
        let fgLumB = 0.0722 * fg[2]
        let fgLum = fgLumR + fgLumG + fgLumB

        let bgGreater = bgLum > fgLum
        let nom = bgGreater ? bgLum : fgLum
        let denom = bgGreater ? fgLum : bgLum
        let contrast = (nom + 0.05) / (denom + 0.05)
        return 1.6 < contrast
    }

}

extension UIImage {

    fileprivate func resize(_ newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }

    public func getColors(_ completionHandler: @escaping (UIImageColors) -> Void) {
        let ratio = self.size.width/self.size.height
        let r_width: CGFloat = 250

        self.getColors(CGSize(width: r_width, height: r_width/ratio), completionHandler: completionHandler)
    }

    public func getColors(_ scaleDownSize: CGSize, completionHandler: @escaping (UIImageColors) -> Void) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            var result = UIImageColors()

            let cgImage = self.resize(scaleDownSize).cgImage!
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
            let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
            let ctx = CGContext(data: raw, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
            ctx.clear(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            let data = UnsafePointer<UInt8>(ctx.data)

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
                if randomColorsThreshold < colorCount  {
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
                kolor = kolor.colorWithMinimumSaturation(0.15)
                if kolor.isDarkColor == findDarkTextColor {
                    let colorCount = imageColors.count(for: kolor)
                    sortedColors.add(PCCountedColor(color: kolor, count: colorCount))
                }
            }
            sortedColors.sort(comparator: sortedColorComparator)

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
            
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
    }
    
}
