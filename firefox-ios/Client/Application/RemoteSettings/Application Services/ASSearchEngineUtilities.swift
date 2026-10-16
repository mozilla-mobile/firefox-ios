// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

/// General purpose utilities for translating between Remote Settings models and our
/// existing OpenSearch model objects.
struct ASSearchEngineUtilities {
    /// How `{partnerCode}` param is handled when converting a URL template.
    enum PartnerCodeInsertion {
        /// Insert the value as-is (v2 behavior, no change).
        case value(String)
        /// Insert the value or omit param entirely when `nil`.
        case valueOrOmit(String?)
        /// Keep `{partnerCode}` placeholder so it can be resolved later for a search access point.
        case keepPlaceholder
    }

    static func convertASToOpenSearch(_ engine: SearchEngineDefinition, image: UIImage) -> OpenSearchEngine {
        let engineID = engine.identifier
        let name = engine.name
        let telemetrySuffix = engine.telemetrySuffix
        let searchTemplate = convertASSearchURLToOpenSearchURL(engine.urls.search, for: engine) ?? ""
        let suggestTemplate = convertASSearchURLToOpenSearchURL(engine.urls.suggestions, for: engine) ?? ""
        let trendingTemplate = convertASSearchURLToOpenSearchURL(engine.urls.trending, for: engine) ?? ""
        let converted = OpenSearchEngine(engineID: engineID,
                                         shortName: name,
                                         telemetrySuffix: telemetrySuffix,
                                         image: image,
                                         searchTemplate: searchTemplate,
                                         suggestTemplate: suggestTemplate,
                                         trendingTemplate: trendingTemplate,
                                         isCustomEngine: false)
        return converted
    }

    /// Converts a v3 search config engine. The search template keeps the `{partnerCode}` placeholder, which is
    /// resolved per SAP when a search is performed. Suggestion & trending are not tied to an access point, so they use
    /// the `default` access point's partner code.
    static func convertASToOpenSearch(_ engine: SearchEngineDefinitionV3, image: UIImage) -> OpenSearchEngine {
        let partners = convertPartners(engine.partner)
        let defaultPartnerCode = SearchPartnerResolver.resolve(engineIdentifier: engine.identifier,
                                                               partners: partners,
                                                               accessPoint: .default).partnerCode
        let searchTemplate = convertASSearchURLToOpenSearchURL(engine.urls.search,
                                                               partnerCode: .keepPlaceholder) ?? ""
        let suggestTemplate = convertASSearchURLToOpenSearchURL(engine.urls.suggestions,
                                                                partnerCode: .valueOrOmit(defaultPartnerCode)) ?? ""
        let trendingTemplate = convertASSearchURLToOpenSearchURL(engine.urls.trending,
                                                                 partnerCode: .valueOrOmit(defaultPartnerCode)) ?? ""
        return OpenSearchEngine(engineID: engine.identifier,
                                shortName: engine.name,
                                telemetrySuffix: partners?[SearchAccessPoint.default.rawValue]?.telemetrySuffix,
                                image: image,
                                searchTemplate: searchTemplate,
                                suggestTemplate: suggestTemplate,
                                trendingTemplate: trendingTemplate,
                                isCustomEngine: false,
                                partners: partners)
    }

    static func convertPartners(_ partners: [String: SearchEnginePartnerDetails]?) -> [String: SearchEnginePartner]? {
        return partners?.mapValues { SearchEnginePartner(code: $0.code, telemetrySuffix: $0.telemetrySuffix) }
    }

    static func convertASSearchURLToOpenSearchURL(
        _ searchURL: SearchEngineUrl?,
        for engine: SearchEngineDefinition,
        with localeProvider: LocaleProvider = SystemLocaleProvider()
    ) -> String? {
        return convertASSearchURLToOpenSearchURL(searchURL,
                                                 partnerCode: .value(engine.partnerCode),
                                                 with: localeProvider)
    }

    static func convertASSearchURLToOpenSearchURL(
        _ searchURL: SearchEngineUrl?,
        partnerCode: PartnerCodeInsertion,
        with localeProvider: LocaleProvider = SystemLocaleProvider()
    ) -> String? {
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
            if $0.value == OpenSearchEngine.partnerCodeComponent {
                switch partnerCode {
                case .value(let code):
                    value = code
                case .valueOrOmit(let code):
                    guard let code, !code.isEmpty else { return nil }
                    value = code
                case .keepPlaceholder:
                    value = OpenSearchEngine.partnerCodeComponent
                }
            } else if $0.value == "{acceptLanguages}" {
                value = localeCode(from: localeProvider)
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

    static func localeCode(from locale: LocaleProvider) -> String {
        // Per updated discussions with AS team, for now we are using the `preferredLanguages`
        // codes for the locale parameter as long as it's available

        let languages = locale.preferredLanguages
        if let langCode = languages.first {
            return langCode
        } else {
            // Per feedback from AS team, we want to pass in the 2-component BCP 47 code. In some
            // rare cases this may include a script with the region, if so we remove that.
            // See also: Locale+possibilitiesForLanguageIdentifier.swift
            let identifier = locale.current.identifier
            let components = identifier.components(separatedBy: "-")
            if components.count == 3, let first = components.first, let last = components.last {
                return "\(first)-\(last)"
            }
            return identifier
        }
    }
}
