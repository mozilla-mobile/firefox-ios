/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
#if canImport(UIKit)
    import UIKit
#endif

public extension Array where Element == Bundle {
    /// Search through the resource bundles looking for an image of the given name.
    ///
    /// If no image is found in any of the `resourceBundles`, then the `nil` is returned.
    func getImage(named name: String) -> UIImage? {
        for bundle in self {
            if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
                image.accessibilityIdentifier = name
                return image
            }
        }
        return nil
    }

    /// Search through the resource bundles looking for an image of the given name.
    ///
    /// If no image is found in any of the `resourceBundles`, then a fatal error is
    /// thrown. This method is only intended for use with hard coded default images
    /// when other images have been omitted or are missing.
    ///
    /// The two ways of fixing this would be to provide the image as its named in the `.fml.yaml`
    /// file or to change the name of the image in the FML file.
    func getImageNotNull(named name: String) -> UIImage {
        guard let image = getImage(named: name) else {
            fatalError(
                "An image named \"\(name)\" has been named in a `.fml.yaml` file, but is missing from the asset bundle")
        }
        return image
    }

    /// Search through the resource bundles looking for localized strings with the given name.
    /// If the `name` contains exactly one slash, it is split up and the first part of the string is used
    /// as the `tableName` and the second the `key` in localized string lookup.
    /// If no string is found in any of the `resourceBundles`, then the `name` is passed back unmodified.
    func getString(named name: String) -> String? {
        let parts = name.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true).map { String($0) }
        let key: String
        let tableName: String?
        switch parts.count {
        case 2:
            tableName = parts[0]
            key = parts[1]
        default:
            tableName = nil
            key = name
        }

        for bundle in self {
            let value = bundle.localizedString(forKey: key, value: nil, table: tableName)
            if value != key {
                return value
            }
        }
        return nil
    }
}

public extension Bundle {
    /// Loads the language bundle from this one.
    /// If `language` is `nil`, then look for the development region language.
    /// If no bundle for the language exists, then return `nil`.
    func fallbackTranslationBundle(language: String? = nil) -> Bundle? {
        #if canImport(UIKit)
            if let lang = language ?? infoDictionary?["CFBundleDevelopmentRegion"] as? String,
               let path = path(forResource: lang, ofType: "lproj")
            {
                return Bundle(path: path)
            }
        #endif
        return nil
    }
}

public extension UIImage {
    /// The ``accessibilityIdentifier``, or "unknown-image" if not found.
    ///
    /// The ``accessibilityIdentifier`` is set when images are loaded via Nimbus, so this
    /// really to make the compiler happy with the generated code.
    var encodableImageName: String {
        accessibilityIdentifier ?? "unknown-image"
    }
}
