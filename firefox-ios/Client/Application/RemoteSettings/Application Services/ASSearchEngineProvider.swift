// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Accounts
import Common
import Shared

final class ASSearchEngineProvider: SearchEngineProvider {
    let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           orderedEngineNames: [String]?,
                           completion: @escaping ([OpenSearchEngine]) -> Void) {
        // Note: this currently duplicates the logic from DefaultSearchEngineProvider.
        // Eventually that class will be removed once we switch fully to consolidated search.

        let locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)

        // First load the unordered engines, based on the current locale and language
        getUnorderedBundledEnginesFor(locale: locale,
                                      possibleLanguageIdentifier: locale.possibilitiesForLanguageIdentifier(),
                                      completion: { engineResults in
            let unorderedEngines = customEngines + engineResults

            guard let orderedEngineNames = orderedEngineNames else {
                // We haven't persisted the engine order, so return whatever order we got from disk.
                ensureMainThread {
                    completion(unorderedEngines)
                }

                return
            }

            // We have a persisted order of engines, so try to use that order.
            // We may have found engines that weren't persisted in the ordered list
            // (if the user changed locales or added a new engine); these engines
            // will be appended to the end of the list.
            let orderedEngines = unorderedEngines.sorted { engine1, engine2 in
                let index1 = orderedEngineNames.firstIndex(of: engine1.engineID)
                let index2 = orderedEngineNames.firstIndex(of: engine2.engineID)

                if index1 == nil && index2 == nil {
                    return engine1.shortName < engine2.shortName
                }

                // nil < N for all non-nil values of N.
                if index1 == nil || index2 == nil {
                    return index1 ?? -1 > index2 ?? -1
                }

                return index1! < index2!
            }

            ensureMainThread {
                completion(orderedEngines)
            }
        })
    }

    private func getUnorderedBundledEnginesFor(locale: Locale,
                                               possibleLanguageIdentifier: [String],
                                               completion: @escaping ([OpenSearchEngine]) -> Void ) {
        let profile: Profile = AppContainer.shared.resolve()
        guard let service = profile.remoteSettingsService else {
            logger.log("No service available for Remote Settings", level: .warning, category: .remoteSettings)
            completion([])
            return
        }

        let selector = ASSearchEngineSelector(service: service)
        // TODO: [FXIOS-11553] Confirm localization and region standards that the AS APIs are expecting
        let localeCode = locale.identifier
        let region: String = {
            let systemRegion: String?
            if #available(iOS 17, *) {
                systemRegion = (locale as NSLocale).regionCode
            } else {
                systemRegion = (locale as NSLocale).countryCode
            }
            return systemRegion ?? localeCode.components(separatedBy: "-").last ?? "US"
        }()

        let logger = self.logger
        selector.fetchSearchEngines(locale: localeCode, region: region) { (result, error) in
            guard error == nil else {
                logger.log("Error fetching search engines via App Services: \(error!)",
                           level: .warning,
                           category: .remoteSettings)
                completion([])
                return
            }
            guard let result, !result.engines.isEmpty else {
                logger.log("Search engine fetch returned empty results",
                           level: .warning,
                           category: .remoteSettings)
                completion([])
                return
            }

            // TODO: can we parallelize this? We need the search engines before we can use the icon data but the initial
            // icon fetch can be done concurrently with the search engine request
            let iconFetch = ASIconDataFetcher(service: service)

            iconFetch.populateEngineIconData(result.engines) { enginesAndIcons in
                var openSearchEngines: [OpenSearchEngine] = []
                for (engine, iconImage) in enginesAndIcons {
                    openSearchEngines.append(ASSearchEngineUtilities.convertASToOpenSearch(engine, image: iconImage))
                }
                completion(openSearchEngines)
            }
        }
    }
}

final class ASIconDataFetcher {
    let service: RemoteSettingsService
    let client: RemoteSettingsClient?
    let logger: Logger

    init(service: RemoteSettingsService, logger: Logger = DefaultLogger.shared) {
        self.service = service
        let collection: ASRemoteSettingsCollection = .searchEngineIcons
        self.client = collection.makeClient()
        self.logger = logger
    }

    func populateEngineIconData(_ engines: [SearchEngineDefinition],
                                completion: @escaping ([(SearchEngineDefinition, UIImage)]) -> Void) {
        // Reminder: client creation must happen before sync() or the sync won't pull data for that client's collection
        guard let client, let records = client.getRecords() else { completion([]); return }

        logger.log("Fetched \(records.count) search icon records", level: .info, category: .remoteSettings)
        let iconRecords = records.map { ASSearchEngineIconRecord(record: $0) }

        // This is an O(nm) loop but should generally be an extremely small collection
        // of search engines. For example for en-US we currently only get 7 records.
        let mapped = engines.map { engine in
            // TODO: engine matching must also support wildcards and pattern matches
            // Find the icon record that matches this engine
            var maybeIconImage: UIImage?
            let engineIdentifier = engine.identifier
            for iconRecord in iconRecords {
                // TODO: [FXIOS-11605] We may have multiple icon records that match a single engine for
                // the different icon types. This is still TBD from AS team. If needed, implemenent client-side
                // filtering here to select the best icon.
                let iconIdentifiers = iconRecord.engineIdentifiers
                if iconIdentifiers.contains(engineIdentifier) {
                    if let iconImage = fetchIcon(for: iconRecord) {
                        maybeIconImage = iconImage
                    }
                }
            }

            let iconImage = {
                guard let maybeIconImage else {
                    logger.log("No icon available for search engine.", level: .warning, category: .remoteSettings)
                    return UIImage() // TODO: How do we handle this? Default icon? Blank icon?
                }
                return maybeIconImage
            }()

            return (engine, iconImage)
        }

        completion(mapped)
    }

    private func fetchIcon(for iconRecord: ASSearchEngineIconRecord) -> UIImage? {
        guard let client else { return nil }
        do {
            let data = try client.getAttachment(record: iconRecord.backingRecord)
            if iconRecord.mimeType?.hasPrefix("image/svg") ?? false {
                // TODO: SVGs must be rendered via 3rd party lib
            } else {
                return UIImage(data: data)
            }
        } catch {
            logger.log("Error fetching engine icon attachment.", level: .warning, category: .remoteSettings)
        }
        return nil
    }
}

struct ASSearchEngineUtilities {
    static func convertASToOpenSearch(_ engine: SearchEngineDefinition, image: UIImage) -> OpenSearchEngine {
        let engineID = engine.identifier
        let name = engine.name
        let searchTemplate = convertASSearchURLToOpenSearchURL(engine.urls.search, for: engine) ?? ""
        let suggestTemplate = convertASSearchURLToOpenSearchURL(engine.urls.suggestions, for: engine) ?? ""
        let converted = OpenSearchEngine(engineID: engineID,
                                         shortName: name,
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
                // TODO: [FXIOS-11583] Special-case Bing and other overrides here
                value = engine.partnerCode
            } else {
                value = $0.value ?? ""
            }
            return URLQueryItem(name: $0.name, value: value)
        }
        // From API docs: "This may be skipped if `{searchTerm}` is included in the base."
        if let searchArg = searchURL.searchTermParamName, !searchURL.base.contains("{searchTerm}") {
            queryItems.append(URLQueryItem(name: searchArg, value: "{searchTerms}"))
        }
        components.queryItems = queryItems

        return components.url?.absoluteString.removingPercentEncoding
    }
}
