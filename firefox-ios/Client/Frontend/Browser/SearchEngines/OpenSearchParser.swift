// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Fuzi

/// OpenSearch XML parser.
/// This parser accepts standards-compliant OpenSearch 1.1 XML documents in addition to
/// the Firefox-specific search plugin format.
///
/// OpenSearch spec: http://www.opensearch.org/Specifications/OpenSearch/1.1
class OpenSearchParser {
    private let pluginMode: Bool
    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let typeSearch = "text/html"
    private let typeSuggest = "application/x-suggestions+json"

    init(pluginMode: Bool, userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        self.pluginMode = pluginMode
        self.userInterfaceIdiom = userInterfaceIdiom
    }

    func parse(_ file: String, engineID: String) -> OpenSearchEngine? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            return nil
        }

        guard let indexer = try? XMLDocument(data: data),
            let docIndexer = indexer.root else {
                return nil
        }

        let shortNameIndexer = docIndexer.children(tag: "ShortName")
        if shortNameIndexer.count != 1 {
            return nil
        }

        let shortName = shortNameIndexer[0].stringValue
        if shortName.isEmpty {
            return nil
        }

        let urlIndexers = docIndexer.children(tag: "Url")
        if urlIndexers.isEmpty {
            return nil
        }

        var searchTemplate: String?
        var suggestTemplate: String?
        for urlIndexer in urlIndexers {
            let type = urlIndexer.attributes["type"]
            if type == nil {
                return nil
            }

            if type != typeSearch && type != typeSuggest {
                // Not a supported search type.
                continue
            }

            var template = urlIndexer.attributes["template"]
            if template == nil {
                return nil
            }

            if pluginMode {
                let paramIndexers = urlIndexer.children(tag: "Param")

                if !paramIndexers.isEmpty {
                    template! += "?"
                    var firstAdded = false
                    for paramIndexer in paramIndexers {
                        if firstAdded {
                            template! += "&"
                        } else {
                            firstAdded = true
                        }

                        let name = paramIndexer.attributes["name"]
                        var value = paramIndexer.attributes["value"]
                        if name == nil || value == nil {
                            return nil
                        }

                        // Ref: FXIOS-4547 required us to change partner code (pc) for Bing search on iPad 
                        if name == "pc", shortName == "Bing", userInterfaceIdiom == .pad {
                            value = "MOZL"
                        }

                        template! += name! + "=" + value!
                    }
                }
            }

            if type == typeSearch {
                searchTemplate = template
            } else {
                suggestTemplate = template
            }
        }

        guard let searchTemplate else {
            return nil
        }

        let imageIndexers = docIndexer.children(tag: "Image")
        var largestImage = 0
        var largestImageElement: XMLElement?

        // For now, just use the largest icon.
        for imageIndexer in imageIndexers {
            let imageWidth = Int(imageIndexer.attributes["width"] ?? "")
            let imageHeight = Int(imageIndexer.attributes["height"] ?? "")

            // Only accept square images.
            if imageWidth != imageHeight {
                continue
            }

            if let imageWidth = imageWidth {
                if imageWidth > largestImage {
                    largestImage = imageWidth
                    largestImageElement = imageIndexer
                }
            }
        }

        let uiImage: UIImage
        if let imageElement = largestImageElement,
            let imageURL = URL(string: imageElement.stringValue, invalidCharacters: false),
            let imageData = try? Data(contentsOf: imageURL),
            let image = UIImage(data: imageData) {
            uiImage = image
        } else {
            return nil
        }

        return OpenSearchEngine(
            engineID: engineID,
            shortName: shortName,
            image: uiImage,
            searchTemplate: searchTemplate,
            suggestTemplate: suggestTemplate,
            isCustomEngine: false
        )
    }
}
