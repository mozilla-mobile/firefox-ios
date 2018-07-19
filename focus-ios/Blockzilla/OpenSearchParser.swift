/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Fuzi

/**
 * OpenSearch XML parser.
 *
 * This parser accepts standards-compliant OpenSearch 1.1 XML documents in addition to
 * the Firefox-specific search plugin format.
 *
 * OpenSearch spec: http://www.opensearch.org/Specifications/OpenSearch/1.1
 */
class OpenSearchParser {
    private static let typeSearch = "text/html"
    private static let typeSuggest = "application/x-suggestions+json"

    private let pluginMode: Bool

    init(pluginMode: Bool) {
        self.pluginMode = pluginMode
    }

    func parse(file: URL) -> SearchEngine? {
        guard let data = try? Data(contentsOf: file) else {
            print("Invalid search file")
            return nil
        }

        guard let doc = try? XMLDocument(data: data),
              let rootElem = doc.root else {
            print("Invalid XML document")
            return nil
        }

        let shortNameElems = rootElem.children(tag: "ShortName")
        guard shortNameElems.count == 1 else {
            print("ShortName must appear exactly once")
            return nil
        }

        let shortName = shortNameElems.first!.stringValue
        guard !shortName.isEmpty else {
            print("ShortName must contain text")
            return nil
        }

        let urlElems = rootElem.children(tag: "Url")
        guard !urlElems.isEmpty else {
            print("Url must appear at least once")
            return nil
        }

        var searchTemplate: String?
        var suggestionsTemplate: String?

        for urlElem in urlElems {
            guard let type = urlElem.attributes["type"] else {
                print("Url element requires a type attribute", terminator: "\n")
                return nil
            }

            guard type == OpenSearchParser.typeSearch || type == OpenSearchParser.typeSuggest else {
                // Not a supported search type.
                continue
            }

            guard var template = urlElem.attributes["template"] else {
                print("Url element requires a template attribute", terminator: "\n")
                return nil
            }

            if pluginMode {
                let paramIndexers = urlElem.children(tag: "Param")

                if !paramIndexers.isEmpty {
                    let params: [String] = paramIndexers.compactMap { indexer in
                        guard let name = indexer.attr("name"), let value = indexer.attr("value") else {
                            print("Param element must have name and value attributes", terminator: "\n")
                            return nil
                        }

                        return "\(name)=\(value)"
                    }

                    template += "?" + params.joined(separator: "&")
                }
            }

            if type == OpenSearchParser.typeSearch {
                searchTemplate = template
            } else {
                suggestionsTemplate = template
            }
        }

        guard let template = searchTemplate else {
            print("Search engine must have a text/html type")
            return nil
        }

        let imageElems = rootElem.children(tag: "Image")
        let largestImage: (XMLElement?, Int) = imageElems.reduce((nil, 0)) { result, elem in
            // Only accept square images.
            guard let widthString = elem.attr("width"),
                  let heightString = elem.attr("height"),
                  let width = Int(widthString),
                  let height = Int(heightString),
                  width == height && width > result.1 else {
                return result
            }

            return (elem, width)
        }

        let image: UIImage?
        if let imageElem = largestImage.0,
           let imageURL = URL(string: imageElem.stringValue),
           let imageData = try? Data(contentsOf: imageURL),
           let uiImage = UIImage(data: imageData)
        {
            image = uiImage
        } else {
            print("Warning: Invalid search image data")
            image = nil
        }

        return SearchEngine(name: shortName, image: image, searchTemplate: template, suggestionsTemplate: suggestionsTemplate)
    }
}
