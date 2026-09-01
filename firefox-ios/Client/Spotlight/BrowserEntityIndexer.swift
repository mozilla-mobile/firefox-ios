// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CoreSpotlight
import Foundation

/// Keeps the Spotlight index in sync with the browser items the app exposes as `BrowserEntity`.
protocol BrowserEntityIndexer: Sendable {
    /// Adds the entities to the Spotlight index, replacing the ones already indexed with the same identifier.
    func index(_ entities: [BrowserEntity]) async

    /// Removes the entities matching the identifiers from the Spotlight index.
    func remove(_ identifiers: [BrowserEntityID]) async
}

final class DefaultBrowserEntityIndexer: BrowserEntityIndexer {
    /// Open tabs are re-indexed as the user browses, so entries for pages a tab navigated away from are left to
    /// expire instead of being deleted by the app.
    private static let tabExpiration: TimeInterval = 30 * 24 * 60 * 60
    private static let domainIdentifier = "org.mozilla.ios.firefox.browserEntity"

    // TODO: FXIOS-14175 - CSSearchableIndex is not thread safe
    nonisolated(unsafe) private let searchableIndex: CSSearchableIndex
    private let logger: Logger

    init(searchableIndex: CSSearchableIndex = CSSearchableIndex.default(),
         logger: Logger = DefaultLogger.shared) {
        self.searchableIndex = searchableIndex
        self.logger = logger
    }

    func index(_ entities: [BrowserEntity]) async {
        guard #available(iOS 18.0, *), !entities.isEmpty else { return }

        let items = entities.map { entity in
            let attributeSet = entity.attributeSet
            attributeSet.associateAppEntity(entity)

            let item = CSSearchableItem(uniqueIdentifier: entity.id.rawValue,
                                        domainIdentifier: Self.domainIdentifier,
                                        attributeSet: attributeSet)
            item.expirationDate = Self.expirationDate(for: entity.type)
            return item
        }

        do {
            try await searchableIndex.indexSearchableItems(items)
        } catch {
            log(error, whileTryingTo: "index \(items.count) browser entities")
        }
    }

    func remove(_ identifiers: [BrowserEntityID]) async {
        guard !identifiers.isEmpty else { return }

        do {
            try await searchableIndex.deleteSearchableItems(withIdentifiers: identifiers.map { $0.rawValue })
        } catch {
            log(error, whileTryingTo: "remove \(identifiers.count) browser entities")
        }
    }

    private static func expirationDate(for type: BrowserEntityType) -> Date {
        switch type {
        case .tab: return Date(timeIntervalSinceNow: Self.tabExpiration)
        case .bookmark: return .distantFuture
        }
    }

    private func log(_ error: Error, whileTryingTo action: String) {
        logger.log("Spotlight failed to \(action)",
                   level: .warning,
                   category: .storage,
                   description: error.localizedDescription)
    }
}
