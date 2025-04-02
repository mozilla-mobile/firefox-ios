// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class OpenSearchEngine: NSObject, NSSecureCoding {
    static var supportsSecureCoding = true

    struct UX {
        static let preferredIconSize = 30
    }

    let shortName: String
    let engineID: String
    let image: UIImage
    let isCustomEngine: Bool
    let searchTemplate: String

    private let suggestTemplate: String?
    private let searchTermComponent = "{searchTerms}"
    private lazy var searchQueryComponentKey: String? = self.getQueryArgFromTemplate()
    private let googleEngineID = "google-b-1-m"

    var headerSearchTitle: String {
        guard engineID != googleEngineID else {
            return .Search.GoogleEngineSectionTitle
        }

        return String(format: .Search.EngineSectionTitle, shortName)
    }

    enum CodingKeys: String, CodingKey {
        case isCustomEngine
        case searchTemplate
        case shortName
        case image
        case engineID
    }

    override var debugDescription: String {
        let className = String(describing: type(of: self))
        let memAddr = Unmanaged.passUnretained(self).toOpaque()
        return "<\(className): \(memAddr)> Name: '\(shortName)' ID: '\(engineID)' Custom: \(isCustomEngine)"
    }

    init(engineID: String,
         shortName: String,
         image: UIImage,
         searchTemplate: String,
         suggestTemplate: String?,
         isCustomEngine: Bool) {
        self.shortName = shortName
        self.image = image
        self.searchTemplate = searchTemplate
        self.suggestTemplate = suggestTemplate
        self.isCustomEngine = isCustomEngine
        self.engineID = engineID
    }

    // MARK: - NSCoding

    required init?(coder aDecoder: NSCoder) {
        // NOTE: As per NSSecureCoding documentation, we must securely decode objects using `decodeObject(of:forKey:)` (or
        // use the correct typed methods). Do not use `decodeObject` and then `as?` to convert to the desired type.
        let isCustomEngine = aDecoder.decodeBool(forKey: CodingKeys.isCustomEngine.rawValue)
        guard let searchTemplate = aDecoder.decodeObject(of: NSString.self, forKey: CodingKeys.searchTemplate.rawValue),
              let shortName = aDecoder.decodeObject(of: NSString.self, forKey: CodingKeys.shortName.rawValue),
              let image = aDecoder.decodeObject(of: UIImage.self, forKey: CodingKeys.image.rawValue) else {
            assertionFailure()
            return nil
        }

        assert(image.size != CGSize.zero, "Decoded images should not be empty")
        self.searchTemplate = searchTemplate as String
        self.shortName = shortName as String
        self.isCustomEngine = isCustomEngine
        self.image = image
        self.engineID = (aDecoder.decodeObject(forKey: CodingKeys.engineID.rawValue) as? String) ??
        Self.generateCustomEngineID()
        self.suggestTemplate = nil
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(searchTemplate, forKey: CodingKeys.searchTemplate.rawValue)
        aCoder.encode(shortName, forKey: CodingKeys.shortName.rawValue)
        aCoder.encode(isCustomEngine, forKey: CodingKeys.isCustomEngine.rawValue)
        aCoder.encode(engineID, forKey: CodingKeys.engineID.rawValue)

        // Images loaded from the BrowserKit bundle will not directly contain image data to encode. Here we force the UIImage
        // to contain PNG data prior to encoding (especially for when writing to a file). [FXIOS-10216]
        // More discussion here: https://stackoverflow.com/a/7962295
        let imageWithData = UIImage(data: image.pngData() ?? Data())
        assert(imageWithData != nil, "Image data should never be nil, even for assets that originate from the bundle")
        aCoder.encode(imageWithData, forKey: CodingKeys.image.rawValue)
    }

    // MARK: - Public

    /// Returns the search URL for the given query.
    func searchURLForQuery(_ query: String) -> URL? {
        return getURLFromTemplate(searchTemplate, query: query)
    }

    /// Returns the search suggestion URL for the given query.
    func suggestURLForQuery(_ query: String) -> URL? {
        if let suggestTemplate = suggestTemplate {
            return getURLFromTemplate(suggestTemplate, query: query)
        }
        return nil
    }

    /// Returns the query that was used to construct a given search URL
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

    // MARK: - Private

    /// Return the arg that we use for searching for this engine
    /// Problem: the search terms may not be a query arg, they may be part of the URL - how to deal with this?
    private func getQueryArgFromTemplate() -> String? {
        // we have the replace the templates SearchTermComponent in order to make the template
        // a valid URL, otherwise we cannot do the conversion to NSURLComponents
        // and have to do flaky pattern matching instead.
        let placeholder = "PLACEHOLDER"
        let template = searchTemplate.replacingOccurrences(of: searchTermComponent, with: placeholder)
        var components = URLComponents(string: template)

        if let retVal = extractQueryArg(in: components?.queryItems, for: placeholder) {
            return retVal
        } else {
            // Query arg may be exist inside fragment
            components = URLComponents()
            components?.query = URL(string: template)?.fragment
            return extractQueryArg(in: components?.queryItems, for: placeholder)
        }
    }

    private func extractQueryArg(in queryItems: [URLQueryItem]?, for placeholder: String) -> String? {
        let searchTerm = queryItems?.filter { item in
            return item.value == placeholder
        }
        return searchTerm?.first?.name
    }

    /// Check that the URL host contains the name of the search engine somewhere inside it
    private func isSearchURLForEngine(_ url: URL?) -> Bool {
        guard let urlHost = url?.shortDisplayString,
              let queryEndIndex = searchTemplate.range(of: "?")?.lowerBound,
              let templateURL = URL(string: String(searchTemplate[..<queryEndIndex]), invalidCharacters: false)
        else { return false }
        return urlHost == templateURL.shortDisplayString
    }

    private func getURLFromTemplate(_ searchTemplate: String, query: String) -> URL? {
        if let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .SearchTermsAllowed) {
            // Escape the search template as well in case it contains not-safe characters like symbols
            let templateAllowedSet = NSMutableCharacterSet()
            templateAllowedSet.formUnion(with: .URLAllowed)

            // Allow brackets since we use them in our template as our insertion point
            templateAllowedSet.formUnion(with: CharacterSet(charactersIn: "{}"))

            if let encodedSearchTemplate = searchTemplate.addingPercentEncoding(
                withAllowedCharacters: templateAllowedSet as CharacterSet
            ) {
                let urlString = encodedSearchTemplate
                    .replacingOccurrences(of: searchTermComponent, with: escapedQuery, options: .literal, range: nil)
                return URL(string: urlString, invalidCharacters: false)
            }
        }

        return nil
    }

    /// Helper method for Redux state.
    func generateModel() -> SearchEngineModel {
        return SearchEngineModel(name: self.shortName, image: self.image)
    }

    static func generateCustomEngineID() -> String {
        return "Custom-" + UUID().uuidString
    }
}
