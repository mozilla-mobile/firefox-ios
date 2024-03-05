/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public class FaviIconGenerator {
    private let cachedImages = NSCache<NSString, UIImage>()

    private init() {}
    public static let shared = FaviIconGenerator()

    public func faviconImage(capitalLetter: String, textColor: UIColor? = nil, backgroundColor: UIColor? = nil) -> UIImage? {
        if let image = cachedImages.object(forKey: capitalLetter as NSString) {
            return image
        }

        let faviconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        faviconLabel.text = capitalLetter
        faviconLabel.textAlignment = .center
        faviconLabel.font = UIFont.systemFont(ofSize: 40, weight: .regular)
        textColor.map { faviconLabel.textColor = $0 }
        backgroundColor.map { faviconLabel.backgroundColor = $0 }

        UIGraphicsBeginImageContextWithOptions(faviconLabel.bounds.size, false, 0.0)
        defer {
            UIGraphicsEndImageContext()
        }
        UIGraphicsGetCurrentContext().map(faviconLabel.layer.render(in:))

        let image = UIGraphicsGetImageFromCurrentImageContext()
        if let image = image { self.cachedImages.setObject(image, forKey: capitalLetter as NSString) }
        return image
    }
}
