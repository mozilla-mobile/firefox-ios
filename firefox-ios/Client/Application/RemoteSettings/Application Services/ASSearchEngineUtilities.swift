// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

/// General purpose utilities for translating between Remote Settings models and our
/// existing OpenSearch model objects.
struct ASSearchEngineUtilities {
    static func convertASToOpenSearch(_ engine: SearchEngineDefinition, image: UIImage) -> OpenSearchEngine {
        let engineID = engine.identifier
        let name = engine.name
        let telemetrySuffix = engine.telemetrySuffix
        let searchTemplate = convertASSearchURLToOpenSearchURL(engine.urls.search, for: engine) ?? ""
        let suggestTemplate = convertASSearchURLToOpenSearchURL(engine.urls.suggestions, for: engine) ?? ""
        let converted = OpenSearchEngine(engineID: engineID,
                                         shortName: name,
                                         telemetrySuffix: telemetrySuffix,
                                         image: image,
                                         searchTemplate: searchTemplate,
                                         suggestTemplate: suggestTemplate,
                                         isCustomEngine: false)
        return converted
    }

    static func convertASSearchURLToOpenSearchURL(_ searchURL: SearchEngineUrl?,
                                                  for engine: SearchEngineDefinition) -> String? {
        guard let searchURL else { return nil }
        guard var components = URLComponents(string: searchURL.base) else { return nil }
        var queryItems: [URLQueryItem] = searchURL.params.compactMap {
            // From AS team:
            // "If the enterpriseValue is specified, the parameter can be ignored for mobile and not added to
            // the URL. If the experimentConfig is specified, and there is an active experiment which specifies
            // a parameter of the same name, then the value of the parameter should be set to be the value from the
            // experiment. If there's no matching experiment, the parameter is not added to the URL."
            if $0.enterpriseValue != nil { return nil }
            // For now, we are not supporting this on iOS. See above.
            if $0.experimentConfig != nil { return nil }

            let value: String
            if $0.value == "{partnerCode}" {
                value = engine.partnerCode
            } else {
                value = $0.value ?? ""
            }
            return URLQueryItem(name: $0.name, value: value)
        }
        // From API docs: "This may be skipped if `{searchTerm}` is included in the base."
        // Note: there is a typo in the docs, the value is searchTerms (plural).
        if let searchArg = searchURL.searchTermParamName, !searchURL.base.contains("{searchTerms}") {
            queryItems.append(URLQueryItem(name: searchArg, value: "{searchTerms}"))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url?.absoluteString.removingPercentEncoding
    }
}
