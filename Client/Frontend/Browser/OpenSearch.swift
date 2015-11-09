/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SWXMLHash

private let TypeSearch = "text/html"
private let TypeSuggest = "application/x-suggestions+json"
private let SearchTermsAllowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789*-_."

class OpenSearchEngine {
    static let PreferredIconSize = 30

    let shortName: String
    let description: String?
    let image: UIImage?
    private let searchTemplate: String
    private let suggestTemplate: String?

    private let SearchTermComponent = "{searchTerms}"

    private lazy var searchQueryComponentKey: String? = self.getQueryArgFromTemplate()

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
     * Return the arg that we use for searching for this engine
     * Problem: the search terms may not be a query arg, they may be part of the URL - how to deal with this?
     **/
    private func getQueryArgFromTemplate() -> String? {
        // we have the replace the templates SearchTermComponent in order to make the template
        // a valid URL, otherwise we cannot do the conversion to NSURLComponents
        // and have to do flaky pattern matching instead.
        let placeholder = "PLACEHOLDER"
        let template = searchTemplate.stringByReplacingOccurrencesOfString(SearchTermComponent, withString: placeholder)
        let components = NSURLComponents(string: template)
        let searchTerm = components?.queryItems?.filter { item in
            return item.value == placeholder
        }
        guard let term = searchTerm where !term.isEmpty  else { return nil }
        return term[0].name
    }

    /**
     * check that the URL host contains the name of the search engine somewhere inside it
     **/
    private func isSearchURLForEngine(url: NSURL?) -> Bool {
        guard let urlHost = url?.host,
            let queryEndIndex = searchTemplate.rangeOfString("?")?.startIndex,
            let templateURL = NSURL(string: searchTemplate.substringToIndex(queryEndIndex)),
            let templateURLHost = templateURL.host else { return false }
        return urlHost.localizedCaseInsensitiveContainsString(templateURLHost)
    }

    /**
     * Returns the query that was used to construct a given search URL
     **/
    func queryForSearchURL(url: NSURL?) -> String? {
        if isSearchURLForEngine(url) {
            if let key = searchQueryComponentKey,
                let value = url?.getQuery()[key] {
                return value.stringByReplacingOccurrencesOfString("+", withString: " ").stringByRemovingPercentEncoding
            }
        }
        return nil
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
        let allowedCharacters = NSCharacterSet(charactersInString: SearchTermsAllowedCharacters)
        if let escapedQuery = query.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters) {
            // Escape the search template as well in case it contains not-safe characters like symbols
            let templateAllowedSet = NSMutableCharacterSet()
            templateAllowedSet.formUnionWithCharacterSet(NSCharacterSet.URLAllowedCharacterSet())

            // Allow brackets since we use them in our template as our insertion point
            templateAllowedSet.formUnionWithCharacterSet(NSCharacterSet(charactersInString: "{}"))

            if let encodedSearchTemplate = searchTemplate.stringByAddingPercentEncodingWithAllowedCharacters(templateAllowedSet) {
                let urlString = encodedSearchTemplate.stringByReplacingOccurrencesOfString(SearchTermComponent, withString: escapedQuery, options: NSStringCompareOptions.LiteralSearch, range: nil)
                return NSURL(string: urlString)
            }
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
    private let pluginMode: Bool

    init(pluginMode: Bool) {
        self.pluginMode = pluginMode
    }

    func parse(file: String) -> OpenSearchEngine? {
        let data = NSData(contentsOfFile: file)

        if data == nil {
            print("Invalid search file")
            return nil
        }

        let rootName = pluginMode ? "SearchPlugin" : "OpenSearchDescription"
        let docIndexer: XMLIndexer! = SWXMLHash.parse(data!)[rootName][0]

        if docIndexer.element == nil {
            print("Invalid XML document")
            return nil
        }

        let shortNameIndexer = docIndexer["ShortName"]
        if shortNameIndexer.all.count != 1 {
            print("ShortName must appear exactly once")
            return nil
        }

        let shortName = shortNameIndexer.element?.text
        if shortName == nil {
            print("ShortName must contain text")
            return nil
        }

        let descriptionIndexer = docIndexer["Description"]
        if !pluginMode && descriptionIndexer.all.count != 1 {
            print("Description must appear exactly once")
            return nil
        }
        let description = descriptionIndexer.element?.text

        let urlIndexers = docIndexer["Url"].all
        if urlIndexers.isEmpty {
            print("Url must appear at least once")
            return nil
        }

        var searchTemplate: String!
        var suggestTemplate: String?
        for urlIndexer in urlIndexers {
            let type = urlIndexer.element?.attributes["type"]
            if type == nil {
                print("Url element requires a type attribute", terminator: "\n")
                return nil
            }

            if type != TypeSearch && type != TypeSuggest {
                // Not a supported search type.
                continue
            }

            var template = urlIndexer.element?.attributes["template"]
            if template == nil {
                print("Url element requires a template attribute", terminator: "\n")
                return nil
            }

            if pluginMode {
                let paramIndexers = urlIndexer["Param"].all

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
                            print("Param element must have name and value attributes", terminator: "\n")
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
            print("Search engine must have a text/html type")
            return nil
        }

        let imageIndexers = docIndexer["Image"].all
        var largestImage = 0
        var largestImageElement: XMLElement?

        // TODO: For now, just use the largest icon.
        for imageIndexer in imageIndexers {
            let imageWidth = Int(imageIndexer.element?.attributes["width"] ?? "")
            let imageHeight = Int(imageIndexer.element?.attributes["height"] ?? "")

            // Only accept square images.
            if imageWidth != imageHeight {
                continue
            }

            if let imageWidth = imageWidth {
                if imageWidth > largestImage {
                    if imageIndexer.element?.text != nil {
                        largestImage = imageWidth
                        largestImageElement = imageIndexer.element
                    }
                }
            }
        }

        var uiImage: UIImage?

        if let imageElement = largestImageElement,
               imageURL = NSURL(string: imageElement.text!),
               imageData = NSData(contentsOfURL: imageURL),
               image = UIImage(data: imageData) {
            uiImage = image
        } else {
            print("Error: Invalid search image data")
        }

        return OpenSearchEngine(shortName: shortName!, description: description, image: uiImage, searchTemplate: searchTemplate, suggestTemplate: suggestTemplate)
    }
}