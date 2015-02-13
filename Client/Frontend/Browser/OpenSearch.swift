/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let TypeSearch = "text/html"
private let TypeSuggest = "application/x-suggestions+json"

class OpenSearchEngine {
    let shortName: String
    let description: String?
    let image: UIImage?
    private let searchTemplate: String
    private let suggestTemplate: String?

    init(shortName: String, description: String?, image: UIImage?, searchTemplate: String, suggestTemplate: String?) {
        self.shortName = shortName
        self.description = description
        self.image = image
        self.searchTemplate = searchTemplate
        self.suggestTemplate = suggestTemplate
    }

    /**
     * Returns the search URL for the given query.
     */
    func searchURLForQuery(query: String) -> NSURL? {
        return getURLFromTemplate(searchTemplate, query: query)
    }

    /**
     * Returns the search suggestion URL for the given query.
     */
    func suggestURLForQuery(query: String) -> NSURL? {
        if let suggestTemplate = suggestTemplate {
            return getURLFromTemplate(suggestTemplate, query: query)
        }

        return nil
    }

    private func getURLFromTemplate(searchTemplate: String, query: String) -> NSURL? {
        if let escapedQuery = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
            let urlString = searchTemplate.stringByReplacingOccurrencesOfString("{searchTerms}", withString: escapedQuery, options: NSStringCompareOptions.LiteralSearch, range: nil)
            return NSURL(string: urlString)
        }

        return nil
    }
}

/**
 * OpenSearch XML parser.
 *
 * This parser accepts standards-compliant OpenSearch 1.1 XML documents in addition to
 * the Firefox-specific search plugin format.
 *
 * OpenSearch spec: http://www.opensearch.org/Specifications/OpenSearch/1.1
 */
class OpenSearchParser {
    private let pluginMode = false

    init(pluginMode: Bool) {
        self.pluginMode = pluginMode
    }

    func parse(file: String) -> OpenSearchEngine? {
        let data = NSData(contentsOfFile: file)

        if data == nil {
            println("Invalid search file")
            return nil
        }

        let rootName = pluginMode ? "SearchPlugin" : "OpenSearchDescription"
        let docIndexer: XMLIndexer! = SWXMLHash.parse(data!)[rootName][0]

        if docIndexer.element == nil {
            println("Invalid XML document")
            return nil
        }

        let shortNameIndexer = docIndexer["ShortName"]
        if shortNameIndexer.all.count != 1 {
            println("ShortName must appear exactly once")
            return nil
        }

        let shortName = shortNameIndexer.element?.text
        if shortName == nil {
            println("ShortName must contain text")
            return nil
        }

        let descriptionIndexer = docIndexer["Description"]
        if !pluginMode && descriptionIndexer.all.count != 1 {
            println("Description must appear exactly once")
            return nil
        }
        let description = descriptionIndexer.element?.text

        var urlIndexers = docIndexer["Url"].all
        if urlIndexers.isEmpty {
            println("Url must appear at least once")
            return nil
        }

        var searchTemplate: String!
        var suggestTemplate: String?
        for urlIndexer in urlIndexers {
            let type = urlIndexer.element?.attributes["type"]
            if type == nil {
                println("Url element requires a type attribute")
                return nil
            }

            if type != TypeSearch && type != TypeSuggest {
                // Not a supported search type.
                continue
            }

            var template = urlIndexer.element?.attributes["template"]
            if template == nil {
                println("Url element requires a template attribute")
                return nil
            }

            if pluginMode {
                var paramIndexers = urlIndexer["Param"].all

                if !paramIndexers.isEmpty {
                    template! += "?"
                    var firstAdded = false
                    for paramIndexer in paramIndexers {
                        if firstAdded {
                            template! += "&"
                        } else {
                            firstAdded = true
                        }

                        let name = paramIndexer.element?.attributes["name"]
                        let value = paramIndexer.element?.attributes["value"]
                        if name == nil || value == nil {
                            println("Param element must have name and value attributes")
                            return nil
                        }
                        template! += name! + "=" + value!
                    }
                }
            }

            if type == TypeSearch {
                searchTemplate = template
            } else {
                suggestTemplate = template
            }
        }

        if searchTemplate == nil {
            println("Search engine must have a text/html type")
            return nil
        }

        var uiImage: UIImage?
        var imageIndexers = docIndexer["Image"].all

        for imageIndexer in imageIndexers {
            // TODO: For now, we only look for 16x16 search icons.
            let imageWidth = imageIndexer.element?.attributes["width"]
            let imageHeight = imageIndexer.element?.attributes["height"]
            if imageWidth?.toInt() != 16 || imageHeight?.toInt() != 16 {
                continue
            }

            if imageIndexer.element?.text == nil {
                continue
            }

            let imageURL = NSURL(string: imageIndexer.element!.text!)
            if let imageURL = imageURL {
                let imageData = NSData(contentsOfURL: imageURL)
                if let imageData = imageData {
                    let image = UIImage(data: imageData)
                    if let image = image {
                        uiImage = image
                    } else {
                        println("Error: Invalid search image data")
                    }
                } else {
                    println("Error: Invalid search image data")
                }
            } else {
                println("Error: Invalid search image data")
            }
        }

        return OpenSearchEngine(shortName: shortName!, description: description, image: uiImage, searchTemplate: searchTemplate, suggestTemplate: suggestTemplate)
    }
}