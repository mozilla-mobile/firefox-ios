// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Generate a default letter image from the domain name
protocol LetterImageGenerator {
    /// Generates a letter image based on the first character in the domain name
    /// Runs main thread due to UILabel.initWithFrame(:)
    /// - Parameter domain: The string domain name
    /// - Returns: The generated letter image
    @MainActor
    func generateLetterImage(siteString: String) async throws -> UIImage
}

class DefaultLetterImageGenerator: LetterImageGenerator {
    private var logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    @MainActor
    func generateLetterImage(siteString: String) async throws -> UIImage {
        guard let letter: Character = siteString.first else {
            logger.log("No letter found for site, which should never happen",
                       level: .warning,
                       category: .images)
            throw SiteImageError.noLetterImage
        }
        let capitalizedLetter = letter.uppercased()

        let color = generateBackgroundColor(forSite: siteString)
        let image = generateImage(fromLetter: capitalizedLetter,
                                  color: color)
        return image
    }

    func generateImage(fromLetter letter: String, color: UIColor) -> UIImage {
        var image = UIImage()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        label.text = letter
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.medium)
        label.textColor = .white
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        let rect = CGRect(origin: .zero, size: label.bounds.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        label.layer.render(in: context)
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    private func generateBackgroundColor(forSite siteString: String) -> UIColor {
        let index = abs(stableHash(siteString)) % (defaultBackgroundColors.count - 1)
        let colorHex = defaultBackgroundColors[index]
        return UIColor(colorString: colorHex)
    }

    // A stable hash (unlike hashValue), from https://useyourloaf.com/blog/swift-hashable/
    private func stableHash(_ str: String) -> Int {
        let unicodeScalars = str.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }

    // Used as background color for generated letters
    private let defaultBackgroundColors = ["2e761a",
                                           "399320",
                                           "40a624",
                                           "57bd35",
                                           "70cf5b",
                                           "90e07f",
                                           "b1eea5",
                                           "881606",
                                           "aa1b08",
                                           "c21f09",
                                           "d92215",
                                           "ee4b36",
                                           "f67964",
                                           "ffa792",
                                           "025295",
                                           "0568ba",
                                           "0675d3",
                                           "0996f8",
                                           "2ea3ff",
                                           "61b4ff",
                                           "95cdff",
                                           "00736f",
                                           "01908b",
                                           "01a39d",
                                           "01bdad",
                                           "27d9d2",
                                           "58e7e6",
                                           "89f4f5",
                                           "c84510",
                                           "e35b0f",
                                           "f77100",
                                           "ff9216",
                                           "ffad2e",
                                           "ffc446",
                                           "ffdf81",
                                           "911a2e",
                                           "b7223b",
                                           "cf2743",
                                           "ea385e",
                                           "fa526e",
                                           "ff7a8d",
                                           "ffa7b3" ]
}

// MARK: - UIColor extension
extension UIColor {
    convenience init(rgb: Int) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8)  / 255.0,
            blue: CGFloat((rgb & 0x0000FF) >> 0)  / 255.0,
            alpha: 1)
    }

    convenience init(colorString: String) {
        var colorInt: UInt64 = 0
        Scanner(string: colorString).scanHexInt64(&colorInt)
        self.init(rgb: (Int) (colorInt))
    }
}
