/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SearchEngine: NSObject, NSCoding {
    let name: String
    let image: UIImage?
    var isCustom = false

    private let searchTemplate: String
    private let suggestionsTemplate: String?
    private let SearchTermComponent = "{searchTerms}"
    fileprivate var suggestTemplate: String?

    fileprivate lazy var searchQueryComponentKey: String? = self.getQueryArgFromTemplate()

    init(name: String, image: UIImage?, searchTemplate: String, suggestionsTemplate: String?, isCustom: Bool = false) {
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

    func urlForSuggestions(_ query: String) -> URL? {
        // Escape the search template as well in case it contains not-safe characters like symbols
        let templateAllowedSet = NSMutableCharacterSet()
        templateAllowedSet.formUnion(with: .urlAllowed)
        // Allow brackets since we use them in our template as our insertion point
        templateAllowedSet.formUnion(with: CharacterSet(charactersIn: "{}"))

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard let suggestTemplate = suggestionsTemplate,
            let escaped = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
            let encodedSearchTemplate = suggestTemplate.addingPercentEncoding(withAllowedCharacters: templateAllowedSet as CharacterSet) else {
            debugPrint("Missing Suggestions")
                return nil
        }

        let urlString = encodedSearchTemplate
            .replacingOccurrences(of: SearchTermComponent, with: escaped, options: .literal, range: nil)
        return URL(string: urlString, invalidCharacters: false)
    }

    func urlForQuery(_ query: String) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard let escaped = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed) else {
            assertionFailure("Invalid search URL")
            return nil
        }

        guard let urlString = searchTemplate.replacingOccurrences(of: SearchTermComponent, with: escaped)
            .addingPercentEncoding(withAllowedCharacters: .urlAllowed) else {
            assertionFailure("Invalid search URL")
            return nil
        }

        return URL(string: urlString, invalidCharacters: false)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(image, forKey: "image")
        aCoder.encode(searchTemplate, forKey: "searchTemplate")
        aCoder.encode(suggestionsTemplate, forKey: "suggestionsTemplate")
    }

    func getNameOrCustom() -> String {
        return isCustom ? "custom" : name
    }

    private static func generateImage(name: String) -> UIImage {
        let faviconLetter = name.uppercased()[name.startIndex]

        let faviconLabel = SmartLabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        faviconLabel.backgroundColor = .purple80
        faviconLabel.text = String(faviconLetter)
        faviconLabel.textAlignment = .center
        faviconLabel.font = .body18Medium
        faviconLabel.textColor = UIColor.white
        let imageRenderer = UIGraphicsImageRenderer(size: faviconLabel.bounds.size)

        return imageRenderer.image(actions: { (context) in
            faviconLabel.layer.render(in: context.cgContext)
        })
    }

    /**
     * check that the URL host contains the name of the search engine somewhere inside it
     **/
    fileprivate func isSearchURLForEngine(_ url: URL?) -> Bool {
        guard let urlHost = url?.shortDisplayString,
            let queryEndIndex = searchTemplate.range(of: "?")?.lowerBound,
            let templateURL = URL(string: String(searchTemplate[..<queryEndIndex]), invalidCharacters: false)
        else { return false }
        return urlHost == templateURL.shortDisplayString
    }

    /**
     * Returns the query that was used to construct a given search URL
     **/
    func queryForSearchURL(_ url: URL?) -> String? {
        guard isSearchURLForEngine(url), let key = searchQueryComponentKey else { return nil }

        if let value = url?.getQuery()[key] {
            return value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
        } else {
            // If search term could not found in query, it may be exist inside fragment
            var components = URLComponents()
            components.query = url?.fragment?.removingPercentEncoding

            guard let value = components.url?.getQuery()[key] else { return nil }
            return value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
        }
    }

    /**
     * Returns the search suggestion URL for the given query.
     */
    func suggestURLForQuery(_ query: String) -> URL? {
        if let suggestTemplate = suggestTemplate {
            return getURLFromTemplate(suggestTemplate, query: query)
        }
        return nil
    }
    fileprivate func getURLFromTemplate(_ searchTemplate: String, query: String) -> URL? {
        if let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .searchTermsAllowed) {
            // Escape the search template as well in case it contains not-safe characters like symbols
            let templateAllowedSet = NSMutableCharacterSet()
            templateAllowedSet.formUnion(with: .urlAllowed)

            // Allow brackets since we use them in our template as our insertion point
            templateAllowedSet.formUnion(with: CharacterSet(charactersIn: "{}"))

            if let encodedSearchTemplate = searchTemplate.addingPercentEncoding(withAllowedCharacters: templateAllowedSet as CharacterSet) {
                let urlString = encodedSearchTemplate
                    .replacingOccurrences(of: SearchTermComponent, with: escapedQuery, options: .literal, range: nil)
                return URL(string: urlString)
            }
        }

        return nil
    }

    /**
     * Return the arg that we use for searching for this engine
     * Problem: the search terms may not be a query arg, they may be part of the URL - how to deal with this?
     **/
    fileprivate func getQueryArgFromTemplate() -> String? {
        // we have the replace the templates SearchTermComponent in order to make the template
        // a valid URL, otherwise we cannot do the conversion to NSURLComponents
        // and have to do flaky pattern matching instead.
        let placeholder = "PLACEHOLDER"
        let template = searchTemplate.replacingOccurrences(of: SearchTermComponent, with: placeholder)
        var components = URLComponents(string: template)

        if let retVal = extractQueryArg(in: components?.queryItems, for: placeholder) {
            return retVal
        } else {
            // Query arg may be exist inside fragment
            components = URLComponents()
            components?.query = URL(string: template, invalidCharacters: false)?.fragment
            return extractQueryArg(in: components?.queryItems, for: placeholder)
        }
    }

    fileprivate func extractQueryArg(in queryItems: [URLQueryItem]?, for placeholder: String) -> String? {
        let searchTerm = queryItems?.filter { item in
            return item.value == placeholder
        }
        return searchTerm?.first?.name
    }
}

extension CharacterSet {
    public static let searchTermsAllowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789*-_.")
}
