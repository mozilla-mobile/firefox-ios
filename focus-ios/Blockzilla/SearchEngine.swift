/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchEngine: NSObject, NSCoding {
    let name: String
    let image: UIImage?
    var isCustom: Bool = false

    private let searchTemplate: String
    private let suggestionsTemplate: String?

    init(name: String, image: UIImage?, searchTemplate: String, suggestionsTemplate: String?, isCustom:Bool = false) {
        self.name = name
        self.image = image ?? SearchEngine.generateImage(name: name)
        self.searchTemplate = searchTemplate
        self.suggestionsTemplate = suggestionsTemplate
        self.isCustom = isCustom
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let searchTemplate = aDecoder.decodeObject(forKey: "searchTemplate") as? String else {
                return nil
        }
        
        self.name = name
        self.searchTemplate = searchTemplate
        image = aDecoder.decodeObject(forKey: "image") as? UIImage
        suggestionsTemplate = aDecoder.decodeObject(forKey: "suggestionsTemplate") as? String
    }

    func urlForQuery(_ query: String) -> URL? {
        guard let escaped = query.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed) else {
            assertionFailure("Invalid search URL")
            return nil
        }

        let localeString = NSLocale.current.identifier
        guard let urlString = searchTemplate.replacingOccurrences(of: "{searchTerms}", with: escaped)
            .replacingOccurrences(of: "{moz:locale}", with: localeString)
            .addingPercentEncoding(withAllowedCharacters: .urlAllowed) else
        {
            assertionFailure("Invalid search URL")
            return nil
        }

        return URL(string: urlString)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(image, forKey: "image")
        aCoder.encode(searchTemplate, forKey: "searchTemplate")
        aCoder.encode(suggestionsTemplate, forKey: "suggestionsTemplate")
    }
    
    private static func generateImage(name: String) -> UIImage {
        let faviconLetter = name.uppercased()[name.startIndex]
        
        var faviconImage = UIImage()

        let faviconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        faviconLabel.backgroundColor = UIColor(rgb: 0xededf0)
        faviconLabel.text = String(faviconLetter)
        faviconLabel.textAlignment = .center
        faviconLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
        faviconLabel.textColor = UIColor.black
        UIGraphicsBeginImageContextWithOptions(faviconLabel.bounds.size, false, 0.0)
        faviconLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        faviconImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return faviconImage
    }
}
