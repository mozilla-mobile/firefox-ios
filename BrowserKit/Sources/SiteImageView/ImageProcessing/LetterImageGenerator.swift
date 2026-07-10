// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Generate a default letter image from the domain name
protocol LetterImageGenerator: Sendable {
    /// Generates a letter image based on the first character in the domain name
    /// Runs main thread due to UILabel.initWithFrame(:)
    /// - Parameter domain: The string domain name
    /// - Returns: The generated letter image
    @MainActor
    func generateLetterImage(siteString: String) async throws -> UIImage
}

final class DefaultLetterImageGenerator: LetterImageGenerator, @unchecked Sendable {
    private let logger: Logger
    private let themeManager: ThemeManager

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.themeManager = themeManager
        self.logger = logger
    }

    @MainActor
    func generateLetterImage(siteString: String) async throws -> UIImage {
        let capitalizedLetter = try generateLetter(fromSiteString: siteString)

        let colorSet = themeManager.windowNonspecificTheme().colors.faviconLetterColorSet
        let index = colorIndex(forSite: siteString, colorSet: colorSet)
        let image = generateImage(fromLetter: capitalizedLetter,
                                  color: colorSet.backgroundColors[index],
                                  letterColor: colorSet.letterColors[index])
        return image
    }

    internal func generateLetter(fromSiteString siteString: String) throws -> String {
        guard let letter: Character = siteString.first else {
            logger.log("No letter found for site, which should never happen",
                       level: .warning,
                       category: .images)
            throw SiteImageError.noLetterImage
        }

        return letter.uppercased()
    }

    @MainActor
    internal func generateImage(fromLetter letter: String, color: UIColor, letterColor: UIColor = .white) -> UIImage {
        var image = UIImage()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        label.text = letter
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.medium)
        label.textColor = letterColor
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

    internal func colorIndex(forSite siteString: String, colorSet: FaviconLetterColorSet) -> Int {
        return abs(stableHash(siteString)) % colorSet.backgroundColors.count
    }

    internal func generateBackgroundColor(forSite siteString: String, colorSet: FaviconLetterColorSet) -> UIColor {
        return colorSet.backgroundColors[colorIndex(forSite: siteString, colorSet: colorSet)]
    }

    // A stable hash (unlike hashValue), from https://useyourloaf.com/blog/swift-hashable/
    private func stableHash(_ str: String) -> Int {
        let unicodeScalars = str.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
}
