// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common
import Kingfisher
import SwiftDraw

protocol ASSearchEngineIconDataFetcherProtocol {
    /// Accepts a list of Search Engines models and populates them with the correct
    /// icon data based on the Remote Settings `search-config-icon` records.
    /// - Parameters:
    ///   - engines: input engines that need icons.
    ///   - completion: a list of paired engines and their associated icons.
    func populateEngineIconData(_ engines: [SearchEngineDefinition],
                                completion: @escaping ([(SearchEngineDefinition, UIImage)]) -> Void)
}

/// Utility class for fetching search engine icon records from Remote Settings.
final class ASSearchEngineIconDataFetcher: ASSearchEngineIconDataFetcherProtocol {
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
                var matchFound = false
                for ident in iconIdentifiers {
                    if ident.hasSuffix("*") {
                        // Per AS schema:
                        // If an individual entry is suffixed with a star, matching is applied on a "starts with" basis.
                        let iconIdent = ident.dropLast()
                        if engineIdentifier.hasPrefix(iconIdent) {
                            matchFound = true
                        }
                    } else if ident == engineIdentifier {
                        matchFound = true
                    }
                    if matchFound { break }
                }
                if matchFound, let iconImage = fetchIcon(for: iconRecord) {
                    maybeIconImage = iconImage
                    break
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
                return SVG(data: data)?.rasterize()
            } else {
                return UIImage(data: data)
            }
        } catch {
            logger.log("Error fetching engine icon attachment.", level: .warning, category: .remoteSettings)
        }
        return nil
    }
}
